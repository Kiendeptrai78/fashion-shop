import test from 'node:test';
import assert from 'node:assert/strict';
import {encodeFields, decodeFields} from './firestore-rest.mjs';
import {unreviewedProducts, scheduleReviewReminder, processReviewReminders} from './review-reminders.mjs';
import {processInbox} from './worker.mjs';

const root = 'projects/demo/databases/(default)/documents';
const orderPath = `${root}/Users/u/Orders/order`;
const doc = (name, data) => ({name, fields: encodeFields(data)});
const received = (reviewed = []) => ({id: 'order', status: 'OrderStatus.received',
  items: [{productId: 'a'}, {productId: 'a'}, {productId: 'b'}], reviewedProductIds: reviewed});
class Api {
  root = root; docs = new Map(); patches = [];
  async create(name, data) {
    if (!this.docs.has(name)) this.docs.set(name, doc(name, data));
    return this.docs.get(name);
  }
  async get(name) { return this.docs.get(name) ?? null; }
  async patch(original, data) {
    const result = {name: original.name, fields: {...original.fields, ...encodeFields(data)}};
    this.docs.set(original.name, result);this.patches.push(data);return result;
  }
  async claim(original) {
    const data = decodeFields(original.fields);
    return data.notificationPending || data.pushPending ? original : null;
  }
  async query(collection, field, value) {
    return [...this.docs.values()].filter(doc => doc.name.split('/').at(-2) === collection &&
      decodeFields(doc.fields).dueAt && Date.parse(decodeFields(doc.fields).dueAt) <= value.getTime());
  }
}

test('delivered orders schedule exactly one reminder at 24 hours; retries keep the original due time', async () => {
  const api = new Api();const now = Date.parse('2026-11-26T00:00:00Z');
  const order = doc(orderPath, received());
  await scheduleReviewReminder(api, order, now);
  await scheduleReviewReminder(api, order, now + 3600000);
  assert.equal(api.docs.size, 1);
  assert.equal(decodeFields([...api.docs.values()][0].fields).dueAt, '2026-11-27T00:00:00.000Z');
});

test('cancelled or fully reviewed orders do not create reminder jobs', async () => {
  const api = new Api();
  await scheduleReviewReminder(api, doc(orderPath, received(['a', 'b'])));
  await scheduleReviewReminder(api, doc(orderPath, {...received(), status: 'OrderStatus.cancelled'}));
  assert.equal(api.docs.size, 0);
  assert.deepEqual(unreviewedProducts(received(['a'])), ['b']);
});

test('a due reminder rechecks the order and sends just once for unreviewed products', async () => {
  const api = new Api(), now = Date.parse('2026-11-26T00:00:00Z');
  const order = doc(orderPath, received(['a'])); api.docs.set(orderPath, order);
  await scheduleReviewReminder(api, order, now);
  const sent = [];
  const deliver = async (api, project, parent, notice) => {sent.push(notice);return true;};
  await processReviewReminders(api, 'demo', deliver, {}, now + 23 * 3600000);
  assert.equal(sent.length, 0);
  await processReviewReminders(api, 'demo', deliver, {}, now + 25 * 3600000);
  await processReviewReminders(api, 'demo', deliver, {}, now + 26 * 3600000);
  assert.equal(sent.length, 1);
  assert.equal(sent[0].kind, 'review_reminder');
  assert.equal(sent[0].targetId, 'order');
  assert(sent[0].titleVi.includes('1.000 xu'));
});

test('reviewing all products or cancelling before the due time suppresses the reminder', async () => {
  for (const updated of [received(['a', 'b']), {...received(), status: 'OrderStatus.cancelled'}]) {
    const api = new Api(), now = Date.now();
    await scheduleReviewReminder(api, doc(orderPath, received()), now);
    api.docs.set(orderPath, doc(orderPath, updated));
    await processReviewReminders(api, 'demo', () => assert.fail('Should not send'), {}, now + 25 * 3600000);
    assert(api.patches.some(data => data.notificationPending === false));
  }
});

test('a reminder already in the notification queue is suppressed after the customer reviews', async () => {
  const api = new Api();api.docs.set(orderPath, doc(orderPath, received(['a', 'b'])));
  api.send = () => assert.fail('Should not send');
  await processInbox(api, 'demo', doc(`${root}/Users/u/Notifications/reminder`, {
    kind: 'review_reminder', reviewOrderPath: orderPath, pushPending: true, titleVi: 'Nhắc đánh giá',
  }), [], {accepted: 0});
  assert(api.patches.some(data => data.pushSkippedReason === 'review_completed' && data.pushPending === false));
});
