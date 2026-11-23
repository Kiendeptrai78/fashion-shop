import {initializeApp, applicationDefault} from 'firebase-admin/app';
import {getFirestore, FieldValue, Timestamp} from 'firebase-admin/firestore';
import {getMessaging} from 'firebase-admin/messaging';
import {orderNotice, productNotice, inboxNotice, messageFor, topicMessageFor} from './messages.mjs';

initializeApp({credential: applicationDefault()});
const db = getFirestore();
const messaging = getMessaging();
const active = new Set();
// Use once when enabling push for an existing store, to avoid replaying its old inbox.
const newOnly = process.argv.includes('--new-only');
const previousQueue = new Set();
const userStops = new Map();
const trackedUserIds = new Set();

async function sendToDevices(notice, devices, fallbackUid = '') {
  let sentAny = false;
  for (const language of ['vi', 'en']) {
    const selected = devices.filter(
      doc =>
        doc.data().enabled === true &&
        doc.data().token &&
        (doc.data().language === 'en' ? 'en' : 'vi') === language,
    );
    for (let start = 0; start < selected.length; start += 500) {
      const chunk = selected.slice(start, start + 500);
      const result = await messaging.sendEachForMulticast(
        messageFor(notice, language, chunk.map(d => d.data().token)),
      );
      sentAny = true;
      const errorCodes = {};
      for (const response of result.responses) {
        if (!response.success) {
          const code = response.error?.code ?? 'unknown';
          errorCodes[code] = (errorCodes[code] ?? 0) + 1;
        }
      }
      console.info(
        'FCM result:',
        JSON.stringify({
          id: notice.id,
          kind: notice.kind,
          accepted: result.successCount,
          failed: result.failureCount,
          errorCodes,
        }),
      );
      for (let i = 0; i < result.responses.length; i++) {
        const response = result.responses[i];
        if (response.success) continue;
        const invalid = [
          'messaging/registration-token-not-registered',
          'messaging/invalid-registration-token',
        ].includes(response.error?.code);
        if (invalid) await chunk[i].ref.delete();
        else throw new Error(`FCM delivery failed (${response.error?.code ?? 'unknown'}); retrying later`);
      }
    }
  }
  if (!sentAny && fallbackUid) {
    const messageId = await messaging.send(topicMessageFor(notice, 'vi', `user_${fallbackUid}`));
    console.info('FCM topic fallback sent:', JSON.stringify({id: notice.id, topic: `user_${fallbackUid}`, messageId}));
  }
}

async function deliver(uid, notice, devices) {
  const ref = db.collection('Users').doc(uid).collection('Notifications').doc(notice.id);
  const existing = await ref.get();
  if (existing.data()?.pushComplete === true) return;
  if (!existing.exists) await ref.set({...notice, read: false, createdAt: FieldValue.serverTimestamp()});
  await sendToDevices(notice, devices, uid);
  await ref.update({pushComplete: true, pushPending: false});
}

async function processInboxNotification(doc) {
  if (active.has(doc.ref.path)) return;
  active.add(doc.ref.path);
  try {
    const data = await db.runTransaction(async transaction => {
      const snapshot = await transaction.get(doc.ref);
      const current = snapshot.data();
      if (
        !current?.pushPending ||
        current.pushComplete === true ||
        (current.notificationLeaseUntil?.toMillis() ?? 0) > Date.now()
      ) {
        return null;
      }
      transaction.update(doc.ref, {notificationLeaseUntil: Timestamp.fromMillis(Date.now() + 60000)});
      return current;
    });
    if (!data) return;
    const notice = inboxNotice(data, doc.id);
    if (notice) {
      const user = doc.ref.parent.parent;
      const devices = await user.collection('Devices').get();
      await sendToDevices(notice, devices.docs, user.id);
    }
    await doc.ref.update({
      pushPending: false,
      pushComplete: true,
      notificationLeaseUntil: FieldValue.delete(),
    });
  } catch (error) {
    console.error('Inbox push pending:', doc.ref.path, error.code ?? error.message);
  } finally {
    active.delete(doc.ref.path);
  }
}

async function processDocument(doc, kind) {
  if (kind === 'inbox') return processInboxNotification(doc);
  if (active.has(doc.ref.path)) return;
  active.add(doc.ref.path);
  try {
    const data = await db.runTransaction(async transaction => {
      const snapshot = await transaction.get(doc.ref);
      const current = snapshot.data();
      if (!current?.notificationPending || (current.notificationLeaseUntil?.toMillis() ?? 0) > Date.now()) {
        return null;
      }
      transaction.update(doc.ref, {notificationLeaseUntil: Timestamp.fromMillis(Date.now() + 60000)});
      return current;
    });
    if (!data) return;
    if (kind === 'order') {
      const user = doc.ref.parent.parent;
      const devices = await user.collection('Devices').get();
      await deliver(user.id, orderNotice(data, doc.id), devices.docs);
    } else {
      const notice = productNotice(data, doc.id);
      if (notice) {
        for (const uid of trackedUserIds) {
          const devSnap = await db.collection('Users').doc(uid).collection('Devices').get();
          const matches = devSnap.docs.filter(d => {
            const dData = d.data();
            return (
              dData.enabled === true &&
              Array.isArray(dData.categoryIds) &&
              dData.categoryIds.includes(notice.categoryId)
            );
          });
          if (matches.length > 0) await deliver(uid, notice, matches);
        }
      }
    }
    await db.runTransaction(async transaction => {
      const current = (await transaction.get(doc.ref)).data();
      if (!current) return;
      // A later admin status change must remain queued for the next notification.
      transaction.update(doc.ref, {
        notificationPending: kind === 'order' && current.status !== data.status,
        notificationLeaseUntil: FieldValue.delete(),
      });
    });
  } catch (error) {
    console.error('Notification delivery pending:', doc.ref.path, error.code ?? error.message);
  } finally {
    active.delete(doc.ref.path);
  }
}

// Per-user subcollection listeners work out-of-the-box without requiring
// manual Firestore collection-group single-field indexes.
function watchUser(uid) {
  if (userStops.has(uid)) return;
  trackedUserIds.add(uid);
  const userRef = db.collection('Users').doc(uid);

  const stopNotifs = userRef
    .collection('Notifications')
    .where('pushPending', '==', true)
    .onSnapshot(
      snapshot => {
        for (const change of snapshot.docChanges()) {
          if (change.type !== 'removed') processDocument(change.doc, 'inbox');
        }
      },
      error => console.error('Notification listener (inbox):', uid, error.code ?? error.message),
    );

  const stopOrders = userRef
    .collection('Orders')
    .where('notificationPending', '==', true)
    .onSnapshot(
      snapshot => {
        for (const change of snapshot.docChanges()) {
          if (change.type !== 'removed') processDocument(change.doc, 'order');
        }
      },
      error => console.error('Notification listener (order):', uid, error.code ?? error.message),
    );

  userStops.set(uid, () => {
    stopNotifs();
    stopOrders();
  });
}

function unwatchUser(uid) {
  trackedUserIds.delete(uid);
  const stop = userStops.get(uid);
  if (stop) {
    stop();
    userStops.delete(uid);
  }
}

const stopUsers = db.collection('Users').onSnapshot(
  snapshot => {
    for (const change of snapshot.docChanges()) {
      if (change.type === 'removed') unwatchUser(change.doc.id);
      else watchUser(change.doc.id);
    }
    console.info(`VELORA Push Worker active • watching ${trackedUserIds.size} user(s)`);
  },
  error => console.error('Users listener error:', error.code ?? error.message),
);

const stopProducts = db
  .collection('Products')
  .where('notificationPending', '==', true)
  .onSnapshot(
    snapshot => {
      for (const change of snapshot.docChanges()) {
        if (change.type !== 'removed') processDocument(change.doc, 'product');
      }
    },
    error => console.error('Notification listener (product):', error.code ?? error.message),
  );

// Recover transient failures and leases left by a stopped worker.
const recovery = setInterval(async () => {
  try {
    const prodSnap = await db.collection('Products').where('notificationPending', '==', true).get();
    for (const doc of prodSnap.docs) await processDocument(doc, 'product');
    for (const uid of trackedUserIds) {
      const userRef = db.collection('Users').doc(uid);
      const notifSnap = await userRef.collection('Notifications').where('pushPending', '==', true).get();
      for (const doc of notifSnap.docs) await processDocument(doc, 'inbox');
      const orderSnap = await userRef.collection('Orders').where('notificationPending', '==', true).get();
      for (const doc of orderSnap.docs) await processDocument(doc, 'order');
    }
  } catch (error) {
    console.error('Notification recovery:', error.code ?? error.message);
  }
}, 65000);

for (const signal of ['SIGINT', 'SIGTERM']) {
  process.on(signal, () => {
    clearInterval(recovery);
    stopUsers();
    stopProducts();
    for (const stop of userStops.values()) stop();
    userStops.clear();
    process.exit(0);
  });
}
