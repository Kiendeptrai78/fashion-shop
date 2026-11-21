import test from 'node:test';
import assert from 'node:assert/strict';
import {orderNotice, productNotice, messageFor} from './messages.mjs';
test('order notices identify the exact order and never disclose addresses', () => {
  const notice = orderNotice({id:'order-a',status:'OrderStatus.pending',address:{phone:'private'}}, 'doc');
  assert.equal(notice.id, 'order-order-a-pending');
  assert.equal(notice.targetId, 'order-a');
  assert(!JSON.stringify(notice).includes('private'));
  assert.notEqual(orderNotice({id:'order-a',status:'OrderStatus.shipped'}, 'doc').id, notice.id);
});
test('new-product notice is restricted to its actual category and stock', () => {
  assert.equal(productNotice({Title:'Shoe',Stock:0,CategoryId:'running'}, 'p'), null);
  const notice = productNotice({Title:'Shoe',Stock:3,CategoryId:'running'}, 'p');
  assert.equal(notice.categoryId, 'running');
  assert.equal(notice.targetId, 'p');
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
