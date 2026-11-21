import {initializeApp, applicationDefault} from 'firebase-admin/app';
import {getFirestore, FieldValue, Timestamp} from 'firebase-admin/firestore';
import {getMessaging} from 'firebase-admin/messaging';
import {orderNotice, productNotice, messageFor} from './messages.mjs';

initializeApp({credential: applicationDefault()});
const db = getFirestore();
const messaging = getMessaging();
const active = new Set();

async function deliver(uid, notice, devices) {
  const ref = db.collection('Users').doc(uid).collection('Notifications').doc(notice.id);
  const existing = await ref.get();
  if (existing.data()?.pushComplete === true) return;
  if (!existing.exists) await ref.set({...notice, read: false, createdAt: FieldValue.serverTimestamp()});
  for (const language of ['vi', 'en']) {
    const selected = devices.filter(doc => doc.data().enabled === true && doc.data().token &&
      (doc.data().language === 'en' ? 'en' : 'vi') === language);
    for (let start = 0; start < selected.length; start += 500) {
      const chunk = selected.slice(start, start + 500);
      const result = await messaging.sendEachForMulticast(messageFor(notice, language, chunk.map(d => d.data().token)));
      for (let i = 0; i < result.responses.length; i++) {
        const response = result.responses[i];
        if (response.success) continue;
        const invalid = ['messaging/registration-token-not-registered', 'messaging/invalid-registration-token']
          .includes(response.error?.code);
        if (invalid) await chunk[i].ref.delete();
        else throw new Error('FCM delivery failed; retrying later');
      }
    }
  }
  await ref.update({pushComplete: true});
}

async function processDocument(doc, kind) {
  if (active.has(doc.ref.path)) return;
  active.add(doc.ref.path);
  try {
    const data = await db.runTransaction(async transaction => {
      const snapshot = await transaction.get(doc.ref);
      const current = snapshot.data();
      if (!current?.notificationPending || (current.notificationLeaseUntil?.toMillis() ?? 0) > Date.now()) return null;
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
        const devices = await db.collectionGroup('Devices').where('categoryIds', 'array-contains', notice.categoryId).get();
        const users = new Map();
        for (const device of devices.docs) {
          if (device.data().enabled !== true) continue;
          const uid = device.ref.parent.parent.id;
          if (!users.has(uid)) users.set(uid, []);
          users.get(uid).push(device);
        }
        for (const [uid, matches] of users) await deliver(uid, notice, matches);
      }
    }
    await db.runTransaction(async transaction => {
      const current = (await transaction.get(doc.ref)).data();
      if (!current) return;
      // A later admin status change must remain queued for the next notification.
      transaction.update(doc.ref, {notificationPending: kind === 'order' && current.status !== data.status,
        notificationLeaseUntil: FieldValue.delete()});
    });
  } catch (error) {
    console.error('Notification delivery pending:', doc.ref.path, error.code ?? error.message);
  } finally { active.delete(doc.ref.path); }
}

const queries = [
  [db.collectionGroup('Orders').where('notificationPending', '==', true), 'order'],
  [db.collection('Products').where('notificationPending', '==', true), 'product'],
];
const stops = queries.map(([query, kind]) => query.onSnapshot(snapshot => {
  for (const change of snapshot.docChanges()) if (change.type !== 'removed') processDocument(change.doc, kind);
}, error => console.error('Notification listener:', kind, error.code)));
// Recover transient failures and leases left by a stopped worker.
const recovery = setInterval(async () => {
  for (const [query, kind] of queries) {
    try { for (const doc of (await query.get()).docs) await processDocument(doc, kind); }
    catch (error) { console.error('Notification recovery:', error.code); }
  }
}, 65000);
for (const signal of ['SIGINT', 'SIGTERM']) process.on(signal, () => {
  clearInterval(recovery); stops.forEach(stop => stop()); process.exit(0);
});
