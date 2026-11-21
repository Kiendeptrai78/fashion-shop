import 'package:fashion_business_app/features/personalization/screens/account/notifications_screen.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:get/get.dart';
import 'package:fashion_business_app/features/personalization/models_shopper_preferences.dart';
import 'package:fashion_business_app/utils/local_storage/local_utility.dart';

class AccountActivity extends GetxController {
  AccountActivity(this.uid);
  final String uid;
  static AccountActivity? get current => Get.isRegistered<AccountActivity>() ? Get.find<AccountActivity>() : null;
  final counts = <String, int>{}.obs;
  final addressCount = 0.obs;
  final inbox = <Map<String, dynamic>>[].obs;
  final pushEnabled = false.obs;
  final pushError = ''.obs;
  bool _handledInitialPush = false;
  final _subscriptions = <StreamSubscription>[];
  final _db = FirebaseFirestore.instance;
  int get orderCount => counts.values.fold(0, (sum, count) => sum + count);
  int get activeOrders => (counts['pending'] ?? 0) + (counts['processing'] ?? 0) + (counts['shipped'] ?? 0);
  int get unread => inbox.where((notice) => notice['read'] != true).length;

  @override
  void onInit() {
    super.onInit();
    final user = _db.collection('Users').doc(uid);
    _subscriptions.add(user.collection('Orders').snapshots().listen((snapshot) {
      final next = <String, int>{};
      for (final doc in snapshot.docs) {
        final state = (doc.data()['status'] ?? '').toString().split('.').last;
        next[state] = (next[state] ?? 0) + 1;
      }
      counts.assignAll(next);
    }, onError: (_) {}));
    _subscriptions.add(user.collection('Addresses').snapshots().listen((snapshot) {
      addressCount.value = snapshot.size;
    }, onError: (_) {}));
    _subscriptions.add(user.collection('Notifications').orderBy('createdAt', descending: true).limit(100)
        .snapshots().listen((snapshot) {
      inbox.assignAll(snapshot.docs.map((doc) => {...doc.data(), 'documentId': doc.id}));
    }, onError: (_) {}));
    if (const bool.fromEnvironment('PUSH_BACKEND_READY')) {
      _subscriptions.add(FirebaseMessaging.onMessage.listen((message) {
        final notice = message.notification;
        if (notice != null) Get.snackbar(notice.title ?? '', notice.body ?? '',
            snackPosition: SnackPosition.TOP, onTap: (_) => Get.to(() => const NotificationsScreen()));
      }));
      _subscriptions.add(FirebaseMessaging.onMessageOpenedApp.listen((_) => Get.to(() => const NotificationsScreen())));
      _subscriptions.add(FirebaseMessaging.instance.onTokenRefresh.listen((_) => syncPush()));
      if (TLocalStorage.instance().readData<bool>('push_enabled_v1') == true) syncPush();
    }
  }

  Future<void> handleInitialPush() async {
    if (_handledInitialPush || !const bool.fromEnvironment('PUSH_BACKEND_READY')) return;
    _handledInitialPush = true;
    if (await FirebaseMessaging.instance.getInitialMessage() != null) Get.to(() => const NotificationsScreen());
  }

  Future<void> enablePush() async {
    pushError.value = '';
    if (!const bool.fromEnvironment('PUSH_BACKEND_READY')) {
      pushError.value = 'Push notifications are not configured yet.';
      return;
    }
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        pushError.value = 'Notifications are disabled in device settings.';
        return;
      }
      await TLocalStorage.instance().saveData('push_enabled_v1', true);
      await syncPush();
    } catch (_) { pushError.value = 'Notifications are not available on this device yet.'; }
  }

  Future<void> syncPush() async {
    if (!const bool.fromEnvironment('PUSH_BACKEND_READY')) return;
    if (TLocalStorage.instance().readData<bool>('push_enabled_v1') != true) return;
    try {
      final messaging = FirebaseMessaging.instance;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS && await messaging.getAPNSToken() == null) {
        pushError.value = 'Notifications are not available on this device yet.';
        return;
      }
      final token = await messaging.getToken();
      if (token == null) return;
      final installation = TLocalStorage.instance().readData<String>('push_device_id_v1')
          ?? DateTime.now().microsecondsSinceEpoch.toString();
      await TLocalStorage.instance().saveData('push_device_id_v1', installation);
      await _db.collection('Users').doc(uid).collection('Devices').doc(installation).set({
        'token': token, 'categoryIds': ShopperPreferences.load().categoryIds,
        'language': Get.locale?.languageCode ?? 'vi', 'enabled': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
      pushEnabled.value = true;
      pushError.value = '';
    } catch (_) { pushError.value = 'Notifications are not available on this device yet.'; }
  }

  Future<void> markRead(String id) => _db.collection('Users').doc(uid).collection('Notifications')
      .doc(id).update({'read': true});

  Future<void> markAllRead() async {
    final collection = _db.collection('Users').doc(uid).collection('Notifications');
    while (true) {
      final unread = await collection.where('read', isEqualTo: false).limit(400).get();
      if (unread.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in unread.docs) { batch.update(doc.reference, {'read': true}); }
      await batch.commit();
    }
  }

  Future<void> disconnect() async {
    final id = TLocalStorage.instance().readData<String>('push_device_id_v1');
    if (id != null && const bool.fromEnvironment('PUSH_BACKEND_READY')) {
      try {
        await _db.collection('Users').doc(uid).collection('Devices').doc(id).delete().timeout(const Duration(seconds: 3));
        await FirebaseMessaging.instance.deleteToken().timeout(const Duration(seconds: 3));
      } catch (_) { /* Sign out remains available without a network connection. */ }
    }
    for (final subscription in _subscriptions) { await subscription.cancel(); }
    _subscriptions.clear();
  }

  @override
  void onClose() {
    for (final subscription in _subscriptions) { subscription.cancel(); }
    super.onClose();
  }
}
