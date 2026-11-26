import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/data/repositories/orders/orders_repository.dart';
import 'package:fashion_business_app/data/repositories/products/product_reposotory.dart';
import 'package:fashion_business_app/features/personalization/models_shopper_preferences.dart';
import 'package:fashion_business_app/features/personalization/screens/account/coupons_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/account/notifications_screen.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/features/shop/screens/order/order_detail.dart';
import 'package:fashion_business_app/features/shop/screens/order/return_request_screen.dart';
import 'package:fashion_business_app/features/shop/screens/product_details/product_details.dart';
import 'package:fashion_business_app/features/shop/screens/product_reviews/product_review.dart';
import 'package:fashion_business_app/features/shop/screens/support_chat/velora_support_chat_screen.dart';
import 'package:fashion_business_app/utils/local_storage/local_utility.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:get/get.dart';

class AccountActivity extends GetxController {
  AccountActivity(this.uid);
  final String uid;
  static AccountActivity? get current =>
      Get.isRegistered<AccountActivity>() ? Get.find<AccountActivity>() : null;

  final counts = <String, int>{}.obs;
  final addressCount = 0.obs;
  final chatUnread = 0.obs;
  final inbox = <Map<String, dynamic>>[].obs;
  final pushEnabled = false.obs;
  final pushError = ''.obs;
  final fcmToken = ''.obs;

  bool _handledInitialPush = false;
  final _subscriptions = <StreamSubscription>[];
  final _db = FirebaseFirestore.instance;

  int get orderCount => counts.values.fold(0, (sum, count) => sum + count);
  int get activeOrders =>
      (counts['pending'] ?? 0) +
      (counts['processing'] ?? 0) +
      (counts['shipped'] ?? 0);
  int get unread => inbox.where((notice) => notice['read'] != true).length;

  static bool isHiddenFromBell(Map<String, dynamic> data, String docId) {
    final kind = (data['kind'] ?? '').toString().trim().toLowerCase();
    return data['hiddenFromBell'] == true ||
        kind == 'support_chat' ||
        docId.startsWith('chat-');
  }

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

    _subscriptions.add(
      user.collection('Addresses').snapshots().listen((snapshot) {
        addressCount.value = snapshot.size;
      }, onError: (_) {}),
    );

    _subscriptions.add(
      _db.collection('SupportChats').doc(uid).snapshots().listen((snapshot) {
        final data = snapshot.data();
        chatUnread.value = (data?['unreadByCustomer'] as num? ?? 0).toInt();
      }, onError: (_) {}),
    );

    // Pure Firebase Firestore notifications stream (excludes private CSKH chat)
    _subscriptions.add(
      user
          .collection('Notifications')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots()
          .listen((snapshot) {
        final items = snapshot.docs
            .where((doc) => !isHiddenFromBell(doc.data(), doc.id))
            .map((doc) => {...doc.data(), 'documentId': doc.id})
            .toList();
        inbox.assignAll(items);
      }, onError: (_) {}),
    );

    syncFavoriteCategories(ShopperPreferences.load().categoryIds);

    if (!kIsWeb) {
      _subscriptions.add(
        FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessage),
      );
      _subscriptions.add(
        FirebaseMessaging.instance.onTokenRefresh.listen((_) => syncPush()),
      );
      _initFirebaseMessaging();
    }
  }

  Future<void> _initFirebaseMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;
      var settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      if (granted) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        await syncPush();
      } else {
        pushEnabled.value = false;
      }
    } catch (_) {
      pushEnabled.value = false;
      pushError.value = 'Chưa kết nối được dịch vụ thông báo. Vui lòng thử lại.';
    }
  }

  Future<void> _handleRemoteMessage(RemoteMessage message) async {
    final data = message.data;
    final notifId = (data['notificationId'] ?? '').toString().trim();
    if (notifId.isNotEmpty) {
      try {
        await markRead(notifId);
      } catch (_) {}
    }

    final kind = (data['kind'] ?? '').toString().trim();
    final targetId = (data['targetId'] ?? '').toString().trim();

    if ((kind == 'order' || kind == 'review_reminder') && targetId.isNotEmpty) {
      try {
        final orders = await OrderRepository().fetchUserOrders();
        final match = orders.where((o) => o.id == targetId).firstOrNull;
        if (match != null) {
          Get.to(() => OrderDetail(order: match));
          return;
        }
      } catch (_) {}
    } else if (kind == 'support_chat') {
      Get.to(() => const VeloraSupportChatScreen());
      return;
    } else if (kind == 'return') {
      Get.to(
        () => MyReturnRequestsScreen(
          highlightRequestId: targetId.isNotEmpty ? targetId : null,
        ),
      );
      return;
    } else if (kind == 'product' && targetId.isNotEmpty) {
      try {
        final product =
            await ProductRepository.instance.fetchProductById(targetId);
        if (product != null) {
          Get.to(() => ProductDetail(product: product));
          return;
        }
      } catch (_) {}
    } else if (kind == 'voucher') {
      if (Get.isRegistered<CustomerBenefits>()) {
        await CustomerBenefits.instance.initialize();
      }
      Get.to(() => CouponsScreen(initialCouponCode: targetId));
      return;
    } else if (kind == 'review' && targetId.isNotEmpty) {
      Get.to(() => ProductReview(productId: targetId));
      return;
    }

    Get.to(() => const NotificationsScreen());
  }

  Future<void> syncFavoriteCategories(List<String> categoryIds) async {
    try {
      await _db.collection('Users').doc(uid).set({
        'FavoriteCategoryIds': categoryIds.toSet().toList(),
      }, SetOptions(merge: true));
      if (!kIsWeb && pushEnabled.value) {
        final messaging = FirebaseMessaging.instance;
        for (final catId in categoryIds.toSet()) {
          final safeTopic =
              'category_${catId.replaceAll(RegExp(r'[^a-zA-Z0-9\-_.~%]'), '_')}';
          try {
            await messaging.subscribeToTopic(safeTopic);
          } catch (_) {}
        }
      }
    } catch (_) {
      // Non-blocking preference sync.
    }
  }

  Future<void> handleInitialPush() async {
    if (_handledInitialPush || kIsWeb) return;
    _handledInitialPush = true;
    try {
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        await _handleRemoteMessage(initialMessage);
      }
    } catch (_) {}
  }

  Future<void> enablePush() async {
    pushError.value = '';
    if (kIsWeb) {
      pushError.value = 'Thông báo đẩy chỉ hỗ trợ trên ứng dụng di động.';
      return;
    }
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        pushEnabled.value = false;
        pushError.value =
            'Quyền thông báo đang bị tắt trong Cài đặt thiết bị. Hãy bật trong Cài đặt → VELORA → Thông báo.';
        return;
      }
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      await syncPush();
    } catch (_) {
      pushEnabled.value = false;
      pushError.value = 'Chưa bật được thông báo trên thiết bị này.';
    }
  }

  Future<String?> _waitForApnsToken(FirebaseMessaging messaging) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      final apns = await messaging.getAPNSToken();
      if (apns != null && apns.isNotEmpty) return apns;
      await Future<void>.delayed(const Duration(milliseconds: 750));
    }
    return null;
  }

  Future<void> syncPush() async {
    if (kIsWeb) return;
    pushEnabled.value = false;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.setAutoInitEnabled(true);
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _waitForApnsToken(messaging);
        if (apnsToken == null) {
          pushError.value = 'Chưa kết nối được dịch vụ thông báo của Apple. Vui lòng mở lại ứng dụng và thử lại.';
          return;
        }
      }

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        pushError.value = 'Chưa đăng ký được thông báo trên thiết bị này. Vui lòng thử lại.';
        return;
      }
      fcmToken.value = token;

      // Subscribe to Firebase Messaging topics for broadcast & user-targeted pushes
      try {
        await messaging.subscribeToTopic('all_customers');
        await messaging.subscribeToTopic('user_$uid');
        for (final catId in ShopperPreferences.load().categoryIds.toSet()) {
          final safeTopic =
              'category_${catId.replaceAll(RegExp(r'[^a-zA-Z0-9\-_.~%]'), '_')}';
          await messaging.subscribeToTopic(safeTopic);
        }
      } catch (_) {}

      final installation =
          TLocalStorage.instance().readData<String>('push_device_id_v1') ??
              DateTime.now().microsecondsSinceEpoch.toString();
      await TLocalStorage.instance().saveData('push_device_id_v1', installation);

      final platform =
          defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
      await _db
          .collection('Users')
          .doc(uid)
          .collection('Devices')
          .doc(installation)
          .set({
        'token': token,
        'platform': platform,
        'categoryIds': ShopperPreferences.load().categoryIds,
        'language': Get.locale?.languageCode ?? 'vi',
        'enabled': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _db.collection('Users').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));

      pushEnabled.value = true;
      pushError.value = '';
    } catch (_) {
      pushError.value = 'Chưa hoàn tất đăng ký thông báo. Vui lòng kiểm tra kết nối và thử lại.';
    }
  }

  Future<void> markRead(String id) => _db
      .collection('Users')
      .doc(uid)
      .collection('Notifications')
      .doc(id)
      .update({'read': true});

  Future<void> markAllRead() async {
    final collection =
        _db.collection('Users').doc(uid).collection('Notifications');
    while (true) {
      final unreadDocs =
          await collection.where('read', isEqualTo: false).limit(400).get();
      if (unreadDocs.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in unreadDocs.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    }
  }

  Future<void> disconnect() async {
    final id = TLocalStorage.instance().readData<String>('push_device_id_v1');
    if (!kIsWeb) {
      try {
        final messaging = FirebaseMessaging.instance;
        await messaging
            .unsubscribeFromTopic('user_$uid')
            .timeout(const Duration(seconds: 3));
        if (fcmToken.value.isNotEmpty) {
          await _db.collection('Users').doc(uid).set({
            'fcmTokens': FieldValue.arrayRemove([fcmToken.value]),
          }, SetOptions(merge: true)).timeout(const Duration(seconds: 3));
        }
        if (id != null) {
          await _db
              .collection('Users')
              .doc(uid)
              .collection('Devices')
              .doc(id)
              .delete()
              .timeout(const Duration(seconds: 3));
        }
        await messaging.deleteToken().timeout(const Duration(seconds: 3));
      } catch (_) {
        // Sign out remains available without a network connection.
      }
    }
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void onClose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.onClose();
  }
}
