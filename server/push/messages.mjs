import {createHash} from 'node:crypto';
export function orderNotice(order, documentId) {
  const status = String(order.status ?? '').split('.').pop();
  const states = {
    pending: ['Đã nhận đơn hàng', 'Order received'],
    processing: ['Đơn hàng đang được chuẩn bị', 'Preparing your order'],
    shipped: ['Đơn hàng đang giao', 'Your order is on the way'],
    received: ['Đơn hàng đã hoàn tất', 'Order completed'],
    cancelled: ['Đơn hàng đã hủy', 'Order cancelled'],
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
export function messageFor(notice, language, tokens) {
  const vi = language !== 'en';
  const collapse = createHash('sha256').update(notice.id).digest('hex').slice(0, 32);
  return {tokens, notification: {title: vi ? notice.titleVi : notice.titleEn,
    body: vi ? notice.bodyVi : notice.bodyEn},
    data: {notificationId: notice.id, kind: notice.kind, targetId: notice.targetId},
    android: {collapseKey: collapse, notification: {tag: collapse}},
    apns: {headers: {'apns-collapse-id': collapse}, payload: {aps: {sound: 'default'}}}};
}
