import {createHash} from 'node:crypto';
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
export function orderNotice(order, documentId) {
  const status = String(order.status ?? '').split('.').pop();
  const viItem = itemsSummary(order, false);
  const enItem = itemsSummary(order, true);
  const states = {
    pending: [
      viItem ? `Đơn hàng ${viItem} của bạn đã được tiếp nhận` : 'Đã nhận đơn hàng',
      enItem ? `Your order for ${enItem} has been received` : 'Order received',
    ],
    processing: [
      viItem ? `Đơn hàng ${viItem} của bạn đang được chuẩn bị` : 'Đơn hàng đang được chuẩn bị',
      enItem ? `Your order for ${enItem} is being prepared` : 'Preparing your order',
    ],
    shipped: [
      viItem ? `Đơn hàng ${viItem} của bạn đang trên đường giao` : 'Đơn hàng đang giao',
      enItem ? `Your order for ${enItem} is on the way` : 'Your order is on the way',
    ],
    received: [
      viItem ? `Đơn hàng ${viItem} của bạn đã giao thành công` : 'Đơn hàng đã hoàn tất',
      enItem ? `Your order for ${enItem} has been delivered` : 'Order completed',
    ],
    cancelled: [
      viItem ? `Đơn hàng ${viItem} của bạn đã bị hủy` : 'Đơn hàng đã hủy',
      enItem ? `Your order for ${enItem} was cancelled` : 'Order cancelled',
    ],
  };
  const title = states[status];
  if (!title) throw new Error('Unsupported order status');
  const id = String(order.id || documentId);
  return {id: `order-${id}-${status}`, kind: 'order', targetId: id,
    titleVi: title[0], titleEn: title[1],
    bodyVi: 'Xem thông tin mới nhất trong Đơn hàng của tôi.',
    bodyEn: 'View the latest details in My Orders.'};
}
export function productNotice(product, documentId) {
  if (!product.CategoryId || !product.Title || Number(product.Stock ?? 0) <= 0) return null;
  return {id: `product-${documentId}`, kind: 'product', targetId: documentId,
    categoryId: product.CategoryId,
    titleVi: 'Đôi giày mới dành cho bạn', titleEn: 'A new pair for you',
    bodyVi: `${String(product.Title).slice(0, 100)} vừa có trong danh mục bạn quan tâm.`,
    bodyEn: `${String(product.Title).slice(0, 100)} just arrived in a collection you follow.`};
}
export function inboxNotice(data, documentId) {
  const titleVi = String(data.titleVi ?? data.titleEn ?? '').trim();
  const titleEn = String(data.titleEn ?? data.titleVi ?? '').trim();
  if (!titleVi && !titleEn) return null;
  return {
    id: String(data.id || documentId),
    kind: String(data.kind || 'promo'),
    targetId: String(data.targetId || ''),
    titleVi: titleVi.slice(0, 120),
    titleEn: titleEn.slice(0, 120),
    bodyVi: String(data.bodyVi ?? data.bodyEn ?? '').trim().slice(0, 240),
    bodyEn: String(data.bodyEn ?? data.bodyVi ?? '').trim().slice(0, 240),
  };
}
export function messageFor(notice, language, tokens) {
  const vi = language !== 'en';
  const collapse = createHash('sha256').update(notice.id).digest('hex').slice(0, 32);
  return {tokens, notification: {title: vi ? notice.titleVi : notice.titleEn,
    body: vi ? notice.bodyVi : notice.bodyEn},
    data: {notificationId: notice.id, kind: notice.kind, targetId: notice.targetId},
    android: {collapseKey: collapse, notification: {tag: collapse}},
    apns: {headers: {'apns-collapse-id': collapse}, payload: {aps: {sound: 'default'}}}};
}
