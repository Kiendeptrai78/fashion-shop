import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/features/personalization/controllers/user_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_review_model.dart';

class ReviewRepository {
  final _db = FirebaseFirestore.instance;

  Future<List<ProductReviewEntry>> fetchRecent(String productId) async {
    final snapshot = await _db.collection('Products').doc(productId).collection('Reviews')
        .orderBy('createdAt', descending: true).limit(50).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ProductReviewEntry(id: doc.id, authorName: data['authorName'] as String? ?? 'Customer',
          rating: (data['rating'] as num? ?? 0).toInt(), text: data['text'] as String? ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate());
    }).where((review) => review.rating >= 1 && review.rating <= 5).toList();
  }

  Future<void> save(String productId, int rating, String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to write a review.');
    if (rating < 1 || rating > 5 || text.trim().length < 10 || text.trim().length > 1000) {
      throw StateError('Choose a rating and write at least 10 characters.');
    }
    final orders = await _db.collection('Users').doc(user.uid).collection('Orders')
        .where('status', isEqualTo: 'OrderStatus.received').get();
    final purchase = orders.docs.where((doc) => (doc.data()['items'] as List? ?? [])
        .any((item) => item is Map && item['productId'] == productId)).firstOrNull;
    if (purchase == null) throw StateError('You can review this pair after receiving your order.');
    final ref = _db.collection('Products').doc(productId).collection('Reviews').doc(user.uid);
    final existing = await ref.get();
    final name = Get.isRegistered<UserController>() ? UserController.instance.user.value.fullName.trim() : '';
    await ref.set({
      'authorName': name.isNotEmpty ? name : 'Customer', 'rating': rating, 'text': text.trim(),
      'purchaseOrderId': purchase.id,
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
