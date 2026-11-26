import test from 'node:test';
import assert from 'node:assert/strict';
import {pendingWatch} from './pending-watch.mjs';
const doc = id => ({ref: {path: `Users/u/Notifications/${id}`}});
const snapshot = changes => ({docs: changes.filter(c => c.type !== 'removed').map(c => c.doc),
  size: changes.filter(c => c.type !== 'removed').length, docChanges: () => changes});
test('first activation defers history, then sends newly queued and changed entries', () => {
  const deferred = new Set(), sent = [];
  const watch = pendingWatch('inbox', true, deferred, d => sent.push(d.ref.path));
  watch(snapshot([{type:'added',doc:doc('old')}]));
  assert.equal(sent.length, 0);
  assert(deferred.has(doc('old').ref.path));
  watch(snapshot([{type:'added',doc:doc('new')},{type:'modified',doc:doc('old')}]));
  assert.deepEqual(sent, [doc('new').ref.path,doc('old').ref.path]);
  assert.equal(deferred.size,0);
});
test('normal startup processes backlog and removed entries are never sent', () => {
  const deferred = new Set(), sent = [];
  const watch = pendingWatch('order', false, deferred, (d,kind) => sent.push(kind));
  watch(snapshot([{type:'added',doc:doc('old')}]));
  watch(snapshot([{type:'removed',doc:doc('old')}]));
  assert.deepEqual(sent,['order']);
});
test('a cleared historical entry is released from the recovery exclusion', () => {
  const deferred = new Set();
  const watch = pendingWatch('inbox', true, deferred, () => assert.fail('removed entry sent'));
  watch(snapshot([{type:'added',doc:doc('old')}]));
  watch(snapshot([{type:'removed',doc:doc('old')}]));
  assert.equal(deferred.size,0);
});

test('service restart skips fixed old history but processes events queued during downtime', () => {
  const excluded = new Set([doc('old').ref.path]);
  const deferred = new Set(), sent = [];
  const watch = pendingWatch('inbox', false, deferred, d => sent.push(d.ref.path), excluded);
  watch(snapshot([{type:'added',doc:doc('old')},{type:'added',doc:doc('during-downtime')}]));
  assert.deepEqual(sent, [doc('during-downtime').ref.path]);
  assert(deferred.has(doc('old').ref.path));
  watch(snapshot([{type:'modified',doc:doc('old')}]));
  assert.deepEqual(sent, [doc('during-downtime').ref.path,doc('old').ref.path]);
  assert.equal(deferred.size, 0);
});
