import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class LoyaltyCoins {
  LoyaltyCoins({FirebaseFirestore? db, String? userId})
      : _db = db ?? FirebaseFirestore.instance,
        _uid = userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
  final FirebaseFirestore _db;
  final String _uid;
  static const reviewReward = 1000;
  DocumentReference<Map<String, dynamic>> get _user {
    if (_uid.isEmpty) throw StateError('Vui lòng đăng nhập để sử dụng xu.');
    return _db.collection('Users').doc(_uid);
  }
  DocumentReference<Map<String, dynamic>> get _wallet => _user.collection('Wallet').doc('coins');
  Stream<int> watchBalance() => _wallet.snapshots().map((doc) =>
      (doc.data()?['balance'] as num? ?? 0).toInt());

  static int redeemable(int balance, double payableUsd) =>
      min(max(0, balance), max(0, (payableUsd * usdToVnd).round()));

  /// Older reviews already link to an order, but did not mark that order reviewed.
  Future<void> backfillReviewedProducts(List<QueryDocumentSnapshot<Map<String, dynamic>>> orders) async {
    final candidates = orders.where((doc) => !doc.data().containsKey('reviewedProductIds') &&
      (doc.data()['status'] ?? '').toString().split('.').last == 'received').toList();
    final ids = <String>{
      for (final order in candidates)
        for (final item in order.data()['items'] as List? ?? [])
          if (item is Map && item['productId'] is String) item['productId'] as String,
    };
    for (final productId in ids) {
      final reviews = await _db.collection('Products').doc(productId).collection('Reviews')
          .where('userId', isEqualTo: _uid).get();
      for (final order in candidates) {
        if (reviews.docs.any((review) {
          final linked = review.data()['purchaseOrderId'];
          return linked is String && linked.isNotEmpty && (linked == order.id || linked == order.data()['id']);
        })) {
          await order.reference.update({'reviewedProductIds': FieldValue.arrayUnion([productId])});
        }
      }
    }
    for (final order in candidates) {
      await order.reference.update({'reviewedProductIds': FieldValue.arrayUnion(<String>[])});
    }
  }

  /// The review, completed-review marker and first reward commit together.
  Future<int> saveReview({required String productId, required String reviewId,
    required Map<String, dynamic> data, String? orderDocumentId,
    bool previouslyReviewed = false}) async {
    final review = _db.collection('Products').doc(productId).collection('Reviews').doc(reviewId);
    if (orderDocumentId == null) {
      throw StateError('Bạn cần nhận sản phẩm trước khi đánh giá.');
    }
    final order = _user.collection('Orders').doc(orderDocumentId);
    final reward = order.collection('ReviewRewards').doc(productId);
    return _db.runTransaction<int>((tx) async {
      final orderData = (await tx.get(order)).data();
      final rewardDoc = await tx.get(reward);
      final wallet = (await tx.get(_wallet)).data();
      if (orderData == null ||
          (orderData['status'] ?? '').toString().split('.').last != 'received' ||
          !(orderData['items'] as List? ?? []).any((item) => item is Map && item['productId'] == productId)) {
        throw StateError('Chỉ đơn đã giao thành công mới được đánh giá mua hàng.');
      }
      final reviewed = List<String>.from(orderData['reviewedProductIds'] as List? ?? []);
      if (rewardDoc.exists || reviewed.contains(productId) || previouslyReviewed) {
        throw StateError('Bạn đã đánh giá sản phẩm trong đơn này. Mỗi sản phẩm chỉ được đánh giá một lần.');
      }
      const amount = reviewReward;
      tx.set(review, {...data, 'verifiedPurchase': true, 'purchaseOrderId': orderDocumentId});
      tx.update(order, {'reviewedProductIds': FieldValue.arrayUnion([productId])});
      if (!rewardDoc.exists) {
        tx.set(reward, {'amount': amount, 'reviewId': reviewId, 'createdAt': FieldValue.serverTimestamp()});
      }
      if (amount > 0) {
        tx.set(_wallet, {'balance': (wallet?['balance'] as num? ?? 0).toInt() + amount,
          'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      }
      return amount;
    });
  }

  /// Saving the order and spending coins share one transaction and stable order ID.
  Future<void> placeOrder({required String orderId, required Map<String, dynamic> data,
    required int coins, required Map<String, dynamic> notification}) async {
    if (coins < 0) throw ArgumentError.value(coins);
    final order = _user.collection('Orders').doc(orderId);
    await _db.runTransaction((tx) async {
      final existing = await tx.get(order);
      final wallet = coins > 0 ? (await tx.get(_wallet)).data() : null;
      if (existing.exists) return;
      final balance = (wallet?['balance'] as num? ?? 0).toInt();
      if (coins > balance) throw StateError('Số dư xu đã thay đổi. Vui lòng kiểm tra lại thanh toán.');
      final total = (data['totalAmount'] as num).toDouble();
      if (total < 0) throw StateError('Tổng thanh toán không hợp lệ.');
      tx.set(order, {...data, 'coinsUsed': coins, 'coinDiscountVnd': coins});
      tx.set(_user.collection('Notifications').doc('order-$orderId-pending'), notification);
      if (coins > 0) {
        tx.set(_wallet, {'balance': balance - coins, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));
      }
    });
  }

  /// Called in the same transaction as cancellation, including repeat attempts.
  static Future<void> refundInTransaction(Transaction tx,
    DocumentReference<Map<String, dynamic>> order, Map<String, dynamic> data) async {
    final coins = (data['coinsUsed'] as num? ?? 0).toInt();
    if (coins <= 0 || data['coinsRefunded'] == true) return;
    final wallet = order.parent.parent!.collection('Wallet').doc('coins');
    final balance = ((await tx.get(wallet)).data()?['balance'] as num? ?? 0).toInt();
    tx.set(wallet, {'balance': balance + coins, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true));
    tx.update(order, {'coinsRefunded': true});
  }
}
