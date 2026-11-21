# Push worker (no Cloud Functions deployment)

This Node.js process uses Firestore listeners and Firebase Admin Messaging. It can
run on an existing computer/server; it does not enable Firebase billing or buy
hosting. Firestore reads, listener reconnects and sends remain subject to the
project's quotas. Keep the process running for immediate delivery; recovery checks
run every 65 seconds. It sends only queued new products/orders, never broadcasts
the existing catalog at startup.

## Configuration still required

1. Review and deploy the private Devices/Notifications rules below. Remove any
   broad `allow read, write: if true` overlapping these paths: Firestore allow
   rules are additive. Preserve/test the app's existing product, order, profile
   and address rules. The snippets below are NOT a replacement ruleset.
2. Obtain a Firebase Admin service-account credential for this project through the
   project owner. Store it outside this repo. Never put it in Dart, app assets,
   source control or tool output. Use least-privilege server credentials.
3. Install dependencies and run on the trusted host:

```sh
cd server/push
npm install
export GOOGLE_APPLICATION_CREDENTIALS=/absolute/private/path/service-account.json
npm start
```

4. iOS: enable Push Notifications on the real app's Apple App ID/provisioning,
   add the Push Notifications capability/aps-environment entitlement in Xcode,
   and upload the owner's APNs authentication key in Firebase Messaging settings.
   No APNs key has been created or uploaded by this change. Verify on a supported
   device; a simulator without an APNs token cannot finish FCM registration.
5. Only after rules, worker and APNs (for iOS) are ready, build with
   `--dart-define=PUSH_BACKEND_READY=true`. In Notifications, tap Enable
   notifications. The app asks OS permission and registers only that account's
   device token, selected category IDs and language; age is never uploaded.

## Private Firestore paths

Integrate inside the existing database `match /databases/{database}/documents`:

```text
match /Users/{uid}/Devices/{device} {
  allow read, delete: if request.auth != null && request.auth.uid == uid;
  allow create, update: if request.auth != null && request.auth.uid == uid
    && request.resource.data.keys().hasOnly(['token','categoryIds','language','enabled','updatedAt'])
    && request.resource.data.token is string
    && request.resource.data.categoryIds is list
    && request.resource.data.categoryIds.size() <= 20
    && request.resource.data.language in ['vi','en']
    && request.resource.data.enabled is bool;
}
match /Users/{uid}/Notifications/{notice} {
  allow read: if request.auth != null && request.auth.uid == uid;
  allow update: if request.auth != null && request.auth.uid == uid
    && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['read'])
    && request.resource.data.read is bool;
  // Checkout's atomic batch creates its own pending-order inbox entry only.
  allow create: if request.auth != null && request.auth.uid == uid
    && request.resource.data.kind == 'order'
    && request.resource.data.targetId is string
    && notice == 'order-' + request.resource.data.targetId + '-pending'
    && request.resource.data.read == false
    && existsAfter(/databases/$(database)/documents/Users/$(uid)/Orders/$(request.resource.data.targetId));
}
```

The Admin worker bypasses client rules and owns pushComplete/category-product
inbox entries. Do not grant client access to other users' tokens. Configure and
review the existing order-write rules so users cannot alter other accounts or
forge paid orders. The current wallet/coupon system remains local test data.

## Admin integration contract

- Product create: `Products/{id}` includes `Title`, positive `Stock`, `CategoryId`,
  `createdAt` server timestamp and `notificationPending: true`. Updates/deletes
  do not broadcast a new-product notification. The Flutter repository already
  writes these fields for creates. The future admin must enforce its own auth.
- Order create/status update: `Users/{uid}/Orders/{id}` sets
  `notificationPending: true`. The worker delivers the exact saved order status.
- Devices are matched against their saved category IDs. Changing preferences
  refreshes the registered device; users who have not enabled notifications are
  never included. Invalid registration tokens are removed.
- Persistent inbox IDs and OS collapse IDs deduplicate retries. Transport failure
  retries can still be delivered more than once: FCM is not an exactly-once queue.

Run `npm test` for pure message/routing tests. This repo does not contain live
server credentials, deployed rules or APNs credentials; live delivery has not
been claimed or tested until these setup steps are completed.

If Firestore requests collection-group indexes, enable a collection-group single
field index for `Orders.notificationPending` (ascending) and
`Devices.categoryIds` (array contains). The project's existing collection-scope
indexes alone do not replace collection-group indexes. Enable the Firebase Cloud
Messaging HTTP v1 API for the server project if it is not already enabled.
Official client/APNs setup: https://firebase.google.com/docs/cloud-messaging/flutter/get-started
