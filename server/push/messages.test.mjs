import test from 'node:test';
import assert from 'node:assert/strict';
import {orderNotice, productNotice, inboxNotice, messageFor} from './messages.mjs';
test('order notices identify product names and never disclose addresses', () => {
  const notice = orderNotice({
    id: 'order-a',
    status: 'OrderStatus.pending',
    address: {phone: 'private'},
    items: [{title: 'Air Force 1'}],
  }, 'doc');
  assert.equal(notice.id, 'order-order-a-pending');
  assert.equal(notice.targetId, 'order-a');
  assert(notice.titleVi.includes('Air Force 1'));
  assert(!notice.titleVi.includes('order-a'));
  assert(!JSON.stringify(notice).includes('private'));
  assert.notEqual(orderNotice({id:'order-a',status:'OrderStatus.shipped'}, 'doc').id, notice.id);
});
test('new-product notice is restricted to its actual category and stock', () => {
  assert.equal(productNotice({Title:'Shoe',Stock:0,CategoryId:'running'}, 'p'), null);
  const notice = productNotice({Title:'Shoe',Stock:3,CategoryId:'running'}, 'p');
  assert.equal(notice.categoryId, 'running');
  assert.equal(notice.targetId, 'p');
});
test('inbox notices handle review replies, vouchers and admin promos', () => {
  const voucher = inboxNotice({
    kind: 'voucher',
    targetId: 'VELORA20',
    titleVi: 'Mã giảm giá mới: VELORA20',
    bodyVi: 'Giảm 20% toàn cửa hàng',
  }, 'voucher-VELORA20');
  assert.equal(voucher.kind, 'voucher');
  assert.equal(voucher.targetId, 'VELORA20');
  assert.equal(voucher.titleEn, 'Mã giảm giá mới: VELORA20');

  const reply = inboxNotice({
    kind: 'review',
    targetId: 'p1',
    titleVi: 'VELORA đã phản hồi đánh giá của bạn',
    titleEn: 'VELORA replied to your review',
    bodyVi: 'Cảm ơn bạn!',
    bodyEn: 'Thank you!',
  }, 'review-reply-p1');
  const payload = messageFor(reply, 'en', ['tok']);
  assert.equal(payload.notification.title, 'VELORA replied to your review');
  assert.equal(payload.data.kind, 'review');
  assert.equal(payload.data.targetId, 'p1');
});
test('FCM payload has matching locale and stable collapse IDs', () => {
  const notice = orderNotice({id:'a',status:'OrderStatus.pending'}, 'doc');
  const vi = messageFor(notice, 'vi', ['token']);
  const en = messageFor(notice, 'en', ['token']);
  assert.equal(vi.notification.title, 'Đã nhận đơn hàng');
  assert.equal(en.notification.title, 'Order received');
  assert.equal(vi.apns.headers['apns-collapse-id'], en.apns.headers['apns-collapse-id']);
  assert(vi.apns.headers['apns-collapse-id'].length <= 64);
});
