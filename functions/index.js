import {createHash} from 'node:crypto';
import {initializeApp} from 'firebase-admin/app';
import {getFirestore, FieldValue} from 'firebase-admin/firestore';
import {getMessaging} from 'firebase-admin/messaging';
import {onDocumentWritten} from 'firebase-functions/v2/firestore';
import {setGlobalOptions, logger} from 'firebase-functions/v2';

initializeApp();
setGlobalOptions({maxInstances: 10});

const db = getFirestore();
const messaging = getMessaging();

/* ------------------------------ Message helpers ------------------------------ */

function itemsSummary(order, english = false) {
  const titles = (Array.isArray(order.items) ? order.items : [])
    .map(item => String(item?.title ?? '').trim())
    .filter(Boolean);
  if (titles.length === 0) return '';
  if (titles.length === 1) return titles[0].slice(0, 60);
  const rest = titles.length - 1;
  return english
    ? `${titles[0].slice(0, 45)} and ${rest} more ${rest === 1 ? 'item' : 'items'}`
    : `${titles[0].slice(0, 45)} và ${rest} sản phẩm khác`;
}

function orderNotice(order, documentId) {
  const status = String(order.status ?? '').split('.').pop();
  const vi = itemsSummary(order, false);
  const en = itemsSummary(order, true);
  const states = {
    pending: [vi ? `Đơn hàng ${vi} của bạn đã được tiếp nhận` : 'Đã nhận đơn hàng',
      en ? `Your order for ${en} has been received` : 'Order received'],
    processing: [vi ? `Đơn hàng ${vi} của bạn đang được chuẩn bị` : 'Đơn hàng đang được chuẩn bị',
      en ? `Your order for ${en} is being prepared` : 'Preparing your order'],
    shipped: [vi ? `Đơn hàng ${vi} của bạn đang trên đường giao` : 'Đơn hàng đang giao',
      en ? `Your order for ${en} is on the way` : 'Your order is on the way'],
    received: [vi ? `Đơn hàng ${vi} của bạn đã giao thành công` : 'Đơn hàng đã hoàn tất',
      en ? `Your order for ${en} has been delivered` : 'Order completed'],
    cancelled: [vi ? `Đơn hàng ${vi} của bạn đã bị hủy` : 'Đơn hàng đã hủy',
      en ? `Your order for ${en} was cancelled` : 'Order cancelled'],
  };
  const title = states[status];
  if (!title) return null;
  const id = String(order.id || documentId);
  return {
    id: `order-${id}-${status}`,
    kind: 'order',
    targetId: id,
    titleVi: title[0],
    titleEn: title[1],
    bodyVi: 'Xem thông tin mới nhất trong Đơn hàng của tôi.',
    bodyEn: 'View the latest details in My Orders.',
  };
}

function productNotice(product, documentId) {
  if (!product.CategoryId || !product.Title || Number(product.Stock ?? 0) <= 0) return null;
  return {
    id: `product-${documentId}`,
    kind: 'product',
    targetId: documentId,
    titleVi: 'Đôi giày mới dành cho bạn',
    titleEn: 'A new pair for you',
    bodyVi: `${String(product.Title).slice(0, 100)} vừa có trong danh mục bạn quan tâm.`,
    bodyEn: `${String(product.Title).slice(0, 100)} just arrived in a collection you follow.`,
    ...(product.Thumbnail ? {imageUrl: String(product.Thumbnail)} : {}),
  };
}

function buildMessage(data, docId, language, tokens) {
  const vi = language !== 'en';
  const id = String(data.id || docId);
  const title = String((vi ? data.titleVi : data.titleEn) ?? data.titleVi ?? data.titleEn ?? '').slice(0, 120);
  const body = String((vi ? data.bodyVi : data.bodyEn) ?? data.bodyVi ?? data.bodyEn ?? '').slice(0, 240);
  const collapse = createHash('sha256').update(id).digest('hex').slice(0, 32);
  return {
    tokens,
    notification: {title, body},
    data: {
      notificationId: id,
      kind: String(data.kind || 'promo'),
      targetId: String(data.targetId || ''),
    },
    android: {
      priority: 'high',
      collapseKey: collapse,
      notification: {channelId: 'velora_firebase_push', tag: collapse, sound: 'default'},
    },
    apns: {
      headers: {'apns-collapse-id': collapse, 'apns-priority': '10'},
      payload: {aps: {sound: 'default', 'mutable-content': 1}},
    },
  };
}

/* ------------------------------ Delivery core ------------------------------- */

async function sendToUser(uid, data, docId) {
  const devicesSnap = await db.collection('Users').doc(uid).collection('Devices').get();
  const devices = devicesSnap.docs.filter(d => d.data().enabled === true && d.data().token);
  let accepted = 0;
  let failed = 0;

  for (const language of ['vi', 'en']) {
    const group = devices.filter(d => (d.data().language === 'en' ? 'en' : 'vi') === language);
    for (let i = 0; i < group.length; i += 500) {
      const chunk = group.slice(i, i + 500);
      const res = await messaging.sendEachForMulticast(
        buildMessage(data, docId, language, chunk.map(d => d.data().token)),
      );
      accepted += res.successCount;
      failed += res.failureCount;
      await Promise.all(res.responses.map(async (r, idx) => {
        if (r.success) return;
        const code = r.error?.code ?? 'unknown';
        logger.warn('FCM token error', {uid, code});
        if (['messaging/registration-token-not-registered',
          'messaging/invalid-registration-token'].includes(code)) {
          await chunk[idx].ref.delete().catch(() => {});
        }
      }));
    }
  }

  // Fallback to the per-user topic when the user has no registered device doc yet.
  if (devices.length === 0) {
    const msg = buildMessage(data, docId, 'vi', []);
    delete msg.tokens;
    await messaging.send({...msg, topic: `user_${uid}`}).catch(e =>
      logger.warn('Topic fallback failed', {uid, code: e.code}));
  }
  logger.info('Push delivered', {uid, id: docId, kind: data.kind, accepted, failed});
}

/* -------------------------------- Triggers ---------------------------------- */

/**
 * Single delivery path: every Users/{uid}/Notifications doc written with
 * pushPending == true is pushed exactly once via FCM (iOS APNs + Android).
 * Covers order status, CSKH chat, vouchers/deals, reviews, returns, video replies.
 */
export const pushOnNotification = onDocumentWritten(
  'Users/{uid}/Notifications/{notifId}',
  async event => {
    const after = event.data?.after;
    if (!after?.exists) return;
    const data = after.data();
    if (data.pushPending !== true || data.pushComplete === true) return;

    // Claim atomically so concurrent invocations never double-send.
    const claimed = await db.runTransaction(async tx => {
      const snap = await tx.get(after.ref);
      const cur = snap.data();
      if (!cur || cur.pushPending !== true || cur.pushComplete === true) return false;
      tx.update(after.ref, {pushPending: false, pushSendingAt: FieldValue.serverTimestamp()});
      return true;
    });
    if (!claimed) return;

    try {
      await sendToUser(event.params.uid, data, event.params.notifId);
      await after.ref.update({pushComplete: true, pushSendingAt: FieldValue.delete()});
    } catch (error) {
      logger.error('Push failed', {path: after.ref.path, error: error.message});
      await after.ref.update({pushPending: true, pushSendingAt: FieldValue.delete()}).catch(() => {});
    }
  },
);

/**
 * Order status changed (notificationPending == true): make sure the matching
 * inbox notification exists — pushOnNotification then sends it.
 */
export const pushOnOrderStatus = onDocumentWritten(
  'Users/{uid}/Orders/{orderId}',
  async event => {
    const after = event.data?.after;
    if (!after?.exists) return;
    const order = after.data();
    if (order.notificationPending !== true) return;

    const notice = orderNotice(order, event.params.orderId);
    if (notice) {
      const ref = db.collection('Users').doc(event.params.uid)
        .collection('Notifications').doc(notice.id);
      const firstItemImage = Array.isArray(order.items) ? order.items[0]?.image : '';
      try {
        await ref.create({
          ...notice,
          ...(firstItemImage ? {imageUrl: String(firstItemImage)} : {}),
          read: false,
          pushPending: true,
          createdAt: FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Already created by Admin Web / checkout → that doc is pushed instead.
      }
    }
    await after.ref.update({notificationPending: false}).catch(() => {});
  },
);

/**
 * New product with notificationPending == true: create an inbox notification
 * for every user whose enabled device follows that category.
 */
export const pushOnNewProduct = onDocumentWritten(
  'Products/{productId}',
  async event => {
    const after = event.data?.after;
    if (!after?.exists) return;
    const product = after.data();
    if (product.notificationPending !== true) return;
    await after.ref.update({notificationPending: false});

    const notice = productNotice(product, event.params.productId);
    if (!notice) return;

    const users = await db.collection('Users').select().get();
    for (const user of users.docs) {
      const devices = await user.ref.collection('Devices').get();
      const follows = devices.docs.some(d =>
        d.data().enabled === true &&
        Array.isArray(d.data().categoryIds) &&
        d.data().categoryIds.includes(product.CategoryId));
      if (!follows) continue;
      await user.ref.collection('Notifications').doc(notice.id).create({
        ...notice,
        categoryId: product.CategoryId,
        read: false,
        pushPending: true,
        createdAt: FieldValue.serverTimestamp(),
      }).catch(() => {});
    }
  },
);
