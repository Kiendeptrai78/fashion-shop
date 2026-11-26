import {inboxNotice, orderNotice, productNotice, messageFor} from '../messages.mjs';
import {FirebaseRest, decodeFields, BudgetExceeded} from './firestore-rest.mjs';
import {accessToken} from './oauth.mjs';
import {scheduleReviewReminder, processReviewReminders, unreviewedProducts} from './review-reminders.mjs';

function userParent(name) {
  return name.match(/^(projects\/[^/]+\/databases\/[^/]+\/documents\/Users\/[^/]+)\//)?.[1];
}
function deviceMessage(notice, device) {
  const {tokens, ...message} = messageFor(notice, device.language === 'en' ? 'en' : 'vi', []);
  message.android.collapse_key = message.android.collapseKey;
  delete message.android.collapseKey;
  message.android.notification.channel_id = message.android.notification.channelId;
  delete message.android.notification.channelId;
  return {...message, token: device.token};
}

export async function processInbox(api, projectId, original, devices, stats) {
  const doc = await api.claim(original, 'pushPending');
  if (!doc) return;
  const data = decodeFields(doc.fields);
  if (data.kind === 'review_reminder') {
    const parent = userParent(doc.name);
    if (!data.reviewOrderPath?.startsWith(`${parent}/Orders/`)) throw new Error('Invalid review reminder');
    const order = await api.get(data.reviewOrderPath);
    if (!unreviewedProducts(decodeFields(order?.fields)).length) {
      await api.patch(doc, {pushPending: false, pushSkippedReason: 'review_completed', notificationLeaseUntil: null});
      return;
    }
  }
  const notice = inboxNotice(data, doc.name.split('/').pop());
  if (!notice) throw new Error('Queued notification has no title');
  const parent = userParent(doc.name);
  if (!parent) throw new Error('Notification is outside Users');
  const registered = devices ?? await api.query('Devices', 'enabled', true, parent);
  const eligible = registered.filter(device => decodeFields(device.fields).token);
  // Keep queued if no valid device. Never broadcast private notices to public topics.
  if (!eligible.length) return;
  let accepted = 0;
  for (const device of eligible) {
    const value = decodeFields(device.fields);
    try { await api.send(projectId, deviceMessage(notice, value)); stats.accepted++; accepted++; }
    catch (error) {
      if (error.code === 'UNREGISTERED') {
        await api.patch(device, {enabled: false});
        continue;
      }
      throw error;
    }
  }
  if (!accepted) return;
  await api.patch(doc, {pushPending: false, pushComplete: true, notificationLeaseUntil: null});
}

async function deliver(api, projectId, parent, notice, devices, stats) {
  const name = `${parent}/Notifications/${notice.id}`;
  let inbox = await api.get(name);
  if (decodeFields(inbox?.fields).pushComplete) return true;
  if (!inbox) inbox = await api.create(name, {...notice, read: false, pushPending: true,
    createdAt: new Date()});
  await processInbox(api, projectId, inbox, devices, stats);
  // Confirm delivery rather than dropping the source job after an active lease/no device.
  const result = decodeFields((await api.get(name))?.fields);
  return result.pushComplete === true || result.pushSkippedReason === 'review_completed';
}

async function processSource(api, projectId, original, kind, stats) {
  const doc = await api.claim(original, 'notificationPending');
  if (!doc) return;
  const data = decodeFields(doc.fields);
  const id = doc.name.split('/').pop();
  if (kind === 'order') {
    const parent = userParent(doc.name);
    if (!parent) throw new Error('Order is outside Users');
    const notice = orderNotice(data, id);
    if (!await deliver(api, projectId, parent, notice, undefined, stats)) return;
    await scheduleReviewReminder(api, doc);
  } else {
    const notice = productNotice(data, id);
    if (notice) {
      const devices = await api.query('Devices', 'categoryIds', notice.categoryId, api.root, true, 100, 'ARRAY_CONTAINS');
      const users = new Map();
      for (const device of devices) {
        const value = decodeFields(device.fields), parent = userParent(device.name);
        if (!parent || value.enabled !== true || !value.token) continue;
        if (!users.has(parent)) users.set(parent, []);
        users.get(parent).push(device);
      }
      for (const [parent, selected] of users) {
        if (!await deliver(api, projectId, parent, notice, selected, stats)) return;
      }
    }
  }
  // Exact version precondition preserves an admin status change during delivery.
  await api.patch(doc, {notificationPending: false, notificationLeaseUntil: null});
}

export async function drain(api, projectId) {
  const stats = {accepted: 0, errors: 0, calls: 0};
  for (const [collection, field, kind, group] of [
    ['Notifications', 'pushPending', 'inbox', true],
    ['Orders', 'notificationPending', 'order', true],
    ['Products', 'notificationPending', 'product', false],
  ]) {
    try {
      const docs = await api.query(collection, field, true, api.root, group);
      for (const doc of docs) {
        try {
          if (kind === 'inbox') await processInbox(api, projectId, doc, undefined, stats);
          else await processSource(api, projectId, doc, kind, stats);
        } catch (error) {
          if (error instanceof BudgetExceeded) throw error;
          stats.errors++;
          // Never log tokens, message contents, user IDs or addresses.
          console.error('Push job deferred', kind, error.code ?? error.status ?? error.name);
        }
      }
    } catch (error) {
      if (error instanceof BudgetExceeded) break;
      stats.errors++;
      console.error('Push query failed', kind, error.code ?? error.status ?? error.name,
        error instanceof TypeError ? error.message : '');
    }
  }
  try { await processReviewReminders(api, projectId, deliver, stats); }
  catch (error) {
    if (!(error instanceof BudgetExceeded)) {
      stats.errors++;
      console.error('Review reminder deferred', error.code ?? error.status ?? error.name);
    }
  }
  stats.calls = api.calls;
  return stats;
}

export default {
  // No public endpoint can trigger sends or read private data.
  fetch() { return new Response('VELORA Push Worker', {status: 200}); },
  async scheduled(event, env) {
    if (env.PUSH_ENABLED !== 'true') { console.info('Push paused'); return; }
    const token = await accessToken(env.FIREBASE_SERVICE_ACCOUNT);
    const api = new FirebaseRest(env.FIREBASE_PROJECT_ID, token);
    console.info('Push cron', JSON.stringify(await drain(api, env.FIREBASE_PROJECT_ID)));
  },
};
