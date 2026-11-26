import {createHash} from 'node:crypto';
import {decodeFields} from './firestore-rest.mjs';

export function unreviewedProducts(order) {
  if (String(order?.status ?? '').split('.').pop() !== 'received') return [];
  const reviewed = new Set(order.reviewedProductIds ?? []);
  return [...new Set((order.items ?? []).map(item => item.productId).filter(Boolean))]
    .filter(id => !reviewed.has(id));
}

export async function scheduleReviewReminder(api, order, now = Date.now()) {
  const data = decodeFields(order.fields);
  if (!unreviewedProducts(data).length) return;
  const id = createHash('sha256').update(order.name).digest('hex');
  // Create-only: retries or later edits never postpone the reminder.
  await api.create(`${api.root}/ReviewReminders/${id}`, {orderPath: order.name,
    dueAt: new Date(now + 24 * 60 * 60 * 1000), notificationPending: true});
}

export function reminderNotice(order, orderPath) {
  const id = String(order.id || orderPath.split('/').pop());
  return {id: `review-reminder-${id}`, kind: 'review_reminder', targetId: id,
    reviewOrderPath: orderPath,
    titleVi: 'Đánh giá đôi giày, nhận 1.000 xu', titleEn: 'Review your pair, earn 1,000 coins',
    bodyVi: 'Bạn còn sản phẩm chưa đánh giá trong đơn đã nhận. Chia sẻ trải nghiệm để nhận 1.000 xu (1.000đ) cho mỗi sản phẩm, một lần duy nhất.',
    bodyEn: 'You have unreviewed items in a delivered order. Share your experience to earn 1,000 coins (1,000₫) per item, once only.'};
}

export async function processReviewReminders(api, projectId, deliver, stats, now = Date.now()) {
  const jobs = await api.query('ReviewReminders', 'dueAt', new Date(now), api.root, false, 20, 'LESS_THAN_OR_EQUAL');
  for (const original of jobs) {
    const job = await api.claim(original, 'notificationPending');
    if (!job) continue;
    const {orderPath} = decodeFields(job.fields);
    const parent = orderPath?.match(/^(projects\/[^/]+\/databases\/[^/]+\/documents\/Users\/[^/]+)\/Orders\/[^/]+$/)?.[1];
    if (!parent) throw new Error('Invalid review reminder order path');
    const order = await api.get(orderPath);
    const data = decodeFields(order?.fields);
    if (unreviewedProducts(data).length) {
      if (!await deliver(api, projectId, parent, reminderNotice(data, orderPath), undefined, stats)) continue;
    }
    // Keep the job as an audit record, but remove it from the due-time query.
    await api.patch(job, {notificationPending: false, dueAt: null, completedAt: new Date(now)});
  }
}
