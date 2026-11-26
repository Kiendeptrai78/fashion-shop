# Push worker (no Cloud Functions deployment)

For cloud delivery independent of this Mac, see [Cloudflare worker](cloudflare/README.md).
The local launchd service described below is a fallback and must remain disabled
while the cloud worker is enabled.

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

4. iOS: `com.phx.velora.shop` is registered under the PHX team. The Firebase
   Development APNs key is configured for this bundle ID. Production is still
   separate and must be configured before using a production-signed app. Check
   the signed app's `aps-environment`, rather than inferring it from a build folder
   name. Verify receipt on the actual device.
5. Run this worker with credentials before testing order/Admin push delivery.
   Firestore inbox documents and `pushPending` flags do not send FCM by themselves.
   The current app registers for messaging after login; Notifications offers a
   retry when registration fails. No `PUSH_BACKEND_READY` build flag is used by
   the current client. Device registration stores the token, platform, selected
   category IDs and language; age is never uploaded.

## Private Firestore paths

Integrate inside the existing database `match /databases/{database}/documents`:

```text
match /Users/{uid}/Devices/{device} {
  allow read, delete: if request.auth != null && request.auth.uid == uid;
  allow create, update: if request.auth != null && request.auth.uid == uid
    && request.resource.data.keys().hasOnly(['token','platform','categoryIds','language','enabled','updatedAt'])
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

The root `firestore.indexes.json` defines collection-group single-field indexes
for `Orders.notificationPending` and `Notifications.pushPending` (ascending),
and `Devices.categoryIds` (array contains). Deploy only these indexes with
`firebase deploy --only firestore:indexes --project fashion-business-app`. The project's existing collection-scope
indexes alone do not replace collection-group indexes. Enable the Firebase Cloud
Messaging HTTP v1 API for the server project if it is not already enabled.
Official client/APNs setup: https://firebase.google.com/docs/cloud-messaging/flutter/get-started

For the first local activation of an existing store, use `npm start -- --new-only`
to leave already-queued historical notifications untouched and watch new events.
Later changes to an existing queued order/inbox entry are still processed. Normal
`npm start` also processes the backlog. Keep the worker running for delivery.

## Installed macOS background service

This development machine has a per-user `launchd` service named
`com.velora.push-worker`, with `RunAtLoad`, `KeepAlive` and a 15-second restart
throttle. It runs after user login independently of terminal/chat sessions.
The runtime and private credentials are installed outside the repository at
`~/Library/Application Support/VELORA/push`; logs are in `~/Library/Logs/VELORA`.
The LaunchAgent configuration is `~/Library/LaunchAgents/com.velora.push-worker.plist`.

```sh
launchctl print gui/$(id -u)/com.velora.push-worker
tail -50 "$HOME/Library/Logs/VELORA/push-worker.log"
tail -50 "$HOME/Library/Logs/VELORA/push-worker-error.log"
```

`PUSH_STARTUP_EXCLUSIONS` points to a private JSON array of document paths queued
before service installation. It is a fixed first-install snapshot, not recreated
on each boot. Subsequent notifications queued during downtime are processed on
restart. An excluded historical document can still be processed if modified after
startup. Do not use `--new-only` for this installed service: that flag defers every
startup backlog, including events queued while the service was offline.

Changes to the repository's worker files must also be copied to the installed
runtime before restarting the service. Keep credentials and the history snapshot
intact. There must be only one active local worker.

This is a local development service: the Mac must be awake, connected to the
internet and the user logged in. It cannot send while the Mac is asleep, shut
down or logged out. Production push independent of this machine requires deploying
the worker on an always-running server; Firebase Admin credentials must remain
on that server, outside the mobile app.
