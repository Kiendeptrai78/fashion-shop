import test from 'node:test';
import assert from 'node:assert/strict';
import {FirebaseRest, encodeFields, decodeFields, BudgetExceeded} from './firestore-rest.mjs';
import {processInbox, drain} from './worker.mjs';

const root = 'projects/demo/databases/(default)/documents';
const parent = `${root}/Users/u`;
const document = (path, data) => ({name: `${root}/${path}`, updateTime: '2026-11-26T00:00:00Z', fields: encodeFields(data)});
const queued = () => document('Users/u/Notifications/n', {
  pushPending: true, kind: 'order', titleVi: 'Đơn hàng đã nhận', titleEn: 'Order received', targetId: 'o',
});

class FakeApi {
  root = root; calls = 0; sent = []; writes = [];
  docs = new Map();
  devices = [document('Users/u/Devices/d', {enabled: true, token: 'private-token', language: 'vi'})];
  async claim(doc, flag) {
    const data = decodeFields(doc.fields);
    if (!data[flag] || data.pushComplete || Date.parse(data.notificationLeaseUntil ?? '') > Date.now()) return null;
    return this.patch(doc, {notificationLeaseUntil: new Date(Date.now() + 90000)});
  }
  async patch(doc, data) {
    const result = {...doc, fields: {...doc.fields, ...encodeFields(data)}};
    this.writes.push({name: doc.name, data}); this.docs.set(doc.name, result); return result;
  }
  async query(collection) {
    if (collection === 'Devices') return this.devices;
    return [...this.docs.values()].filter(doc => doc.name.split('/').at(-2) === collection);
  }
  async get(name) { return this.docs.get(name) ?? null; }
  async create(name, data) {
    const doc = {name, fields: encodeFields(data)}; this.docs.set(name, doc); return doc;
  }
  async send(project, message) { this.sent.push(message); }
}

test('REST values preserve timestamps, numbers, nested data and arrays', () => {
  const value = {date: new Date('2026-11-26T00:00:00Z'), enabled: true, stock: 4,
    price: 1.25, attrs: {Size: '41'}, tags: ['running'], empty: null};
  const encoded = encodeFields(value);
  assert.equal(encoded.date.timestampValue, value.date.toISOString());
  assert.deepEqual(decodeFields(encoded), {...value, date: value.date.toISOString()});
});

test('claim uses version precondition and stores a Firestore timestamp lease', async () => {
  const requests = [];
  const api = new FirebaseRest('demo', 'secret', async (url, options) => {
    requests.push(JSON.parse(options.body));
    return Response.json({writeResults: [{updateTime: 'new-version'}]});
  });
  const doc = queued();
  const result = await api.claim(doc, 'pushPending');
  assert.equal(result.updateTime, 'new-version');
  assert.equal(requests[0].writes[0].currentDocument.updateTime, doc.updateTime);
  assert(requests[0].writes[0].update.fields.notificationLeaseUntil.timestampValue);
});

test('private inbox sends the correct FCM REST payload and marks delivered only after acceptance', async () => {
  const api = new FakeApi(), stats = {accepted: 0};
  await processInbox(api, 'demo', queued(), undefined, stats);
  assert.equal(stats.accepted, 1);
  assert.equal(api.sent[0].token, 'private-token');
  assert.equal(api.sent[0].notification.title, 'Đơn hàng đã nhận');
  assert.equal(api.sent[0].android.notification.channel_id, 'velora_firebase_push');
  assert.equal(api.sent[0].android.collapse_key, api.sent[0].apns.headers['apns-collapse-id']);
  assert.equal(api.writes.at(-1).data.pushComplete, true);
  assert(!('tokens' in api.sent[0]));
});

test('FCM failure leaves the notification queued for the next cron', async () => {
  const api = new FakeApi();
  api.send = async () => { throw new Error('Network unavailable'); };
  await assert.rejects(processInbox(api, 'demo', queued(), undefined, {accepted: 0}));
  assert(api.writes.every(write => write.data.pushComplete !== true));
});

test('no devices and invalid tokens never complete an undelivered notification', async () => {
  for (const invalid of [false, true]) {
    const api = new FakeApi();
    if (invalid) api.send = async () => { throw Object.assign(new Error(), {code: 'UNREGISTERED'}); };
    else api.devices = [];
    await processInbox(api, 'demo', queued(), undefined, {accepted: 0});
    assert(api.writes.every(write => write.data.pushComplete !== true));
    if (invalid) assert(api.writes.some(write => write.data.enabled === false));
  }
});

test('completed messages and active leases are not sent twice', async () => {
  const api = new FakeApi();
  for (const extra of [{pushComplete: true}, {notificationLeaseUntil: new Date(Date.now() + 60000)}]) {
    const doc = queued(); doc.fields = {...doc.fields, ...encodeFields(extra)};
    await processInbox(api, 'demo', doc, undefined, {accepted: 0});
  }
  assert.equal(api.sent.length, 0);
});

test('order and inbox sources share the same notice ID so cron does not send twice', async () => {
  const api = new FakeApi();
  const id = 'order-o-pending';
  api.docs.set(`${parent}/Notifications/${id}`, document(`Users/u/Notifications/${id}`, {
    pushPending: true, titleVi: 'Đơn của bạn', kind: 'order', targetId: 'o',
  }));
  const order = document('Users/u/Orders/o', {id: 'o', status: 'OrderStatus.pending', notificationPending: true});
  api.docs.set(order.name, order);
  const result = await drain(api, 'demo');
  assert.equal(result.accepted, 1);
  assert.equal(api.sent.length, 1);
  assert.equal(decodeFields(api.docs.get(order.name).fields).notificationPending, false);
});

test('product announcements only target enabled devices in the matching category', async () => {
  const api = new FakeApi();
  const product = document('Products/shoe', {Title: 'New pair', Stock: 2, CategoryId: 'running', notificationPending: true});
  api.docs.set(product.name, product);
  api.devices.push(document('Users/disabled/Devices/d', {enabled: false, token: 'disabled'}));
  const result = await drain(api, 'demo');
  assert.equal(result.accepted, 1);
  assert.equal(api.sent[0].token, 'private-token');
  assert.equal(api.sent[0].data.targetId, 'shoe');
});

test('API budget stops safely rather than dropping pending work', async () => {
  const api = new FirebaseRest('demo', 'secret', async () => Response.json({}));
  api.calls = 40;
  await assert.rejects(api.get('doc'), BudgetExceeded);
});

test('product device query uses ARRAY_CONTAINS rather than comparing an array with a string', async () => {
  let query;
  const api = new FirebaseRest('demo', 'secret', async (url, options) => {
    query = JSON.parse(options.body).structuredQuery;
    return Response.json([]);
  });
  await api.query('Devices', 'categoryIds', 'running', api.root, true, 100, 'ARRAY_CONTAINS');
  assert.equal(query.where.fieldFilter.op, 'ARRAY_CONTAINS');
  assert.equal(query.from[0].allDescendants, true);
});

test('concurrent document update rejects a claim without overwriting the new version', async () => {
  const api = new FirebaseRest('demo', 'secret', async () =>
    Response.json({error: {status: 'FAILED_PRECONDITION'}}, {status: 412}));
  assert.equal(await api.claim(queued(), 'pushPending'), null);
});

test('Firestore streaming error arrays preserve their status code', async () => {
  const api = new FirebaseRest('demo', 'secret', async () =>
    Response.json([{error: {status: 'FAILED_PRECONDITION'}}], {status: 400}));
  await assert.rejects(api.query('Notifications', 'pushPending', true),
    error => error.code === 'FAILED_PRECONDITION');
});

test('runtime fetch is not invoked with the API client as its receiver', async () => {
  const original = globalThis.fetch;
  const api = new FirebaseRest('demo', 'secret');
  globalThis.fetch = function () {
    assert.notEqual(this, api, 'Cloudflare native fetch rejects an API-object receiver');
    return Promise.resolve(Response.json([]));
  };
  try { assert.deepEqual(await api.query('Notifications', 'pushPending', true), []); }
  finally { globalThis.fetch = original; }
});
