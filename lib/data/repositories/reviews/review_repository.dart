import 'package:fashion_business_app/features/personalization/services/loyalty_coins.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/features/personalization/controllers/user_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_review_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ReviewEligibility {
  const ReviewEligibility({this.orderDocumentId, this.message = ''});
  final String? orderDocumentId;
  final String message;
  bool get allowed => orderDocumentId != null;
}

class ReviewRepository {
  ReviewRepository({FirebaseFirestore? db, String? userId})
      : _db = db ?? FirebaseFirestore.instance, _userId = userId;
  final FirebaseFirestore _db;
  final String? _userId;

  Future<ReviewEligibility> eligibility(String productId, {String? orderId}) async {
    final uid = _userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return const ReviewEligibility(message: 'Vui lòng đăng nhập để đánh giá.');
    }
    final orders = await _db.collection('Users').doc(uid).collection('Orders').get();
    final purchases = orders.docs.where((doc) {
      final data = doc.data();
      return (orderId == null || doc.id == orderId || data['id'] == orderId) &&
          (data['status'] ?? '').toString().split('.').last == 'received' &&
          (data['items'] as List? ?? []).any((item) => item is Map && item['productId'] == productId);
    }).toList();
    if (purchases.isEmpty) {
      return const ReviewEligibility(message: 'Bạn cần nhận sản phẩm trước khi đánh giá.');
    }
    final prior = await _db.collection('Products').doc(productId).collection('Reviews')
        .where('userId', isEqualTo: uid).get();
    for (final purchase in purchases) {
      final reviewed = List<String>.from(purchase.data()['reviewedProductIds'] as List? ?? []);
      final oldReview = prior.docs.any((review) => review.data()['purchaseOrderId'] == purchase.id ||
          (purchase.data()['id'] != null && review.data()['purchaseOrderId'] == purchase.data()['id']));
      if (reviewed.contains(productId) || oldReview) continue;
      final reward = await purchase.reference.collection('ReviewRewards').doc(productId).get();
      if (!reward.exists) return ReviewEligibility(orderDocumentId: purchase.id);
    }
    return const ReviewEligibility(message: 'Bạn đã đánh giá sản phẩm trong đơn này. Mỗi sản phẩm chỉ được đánh giá một lần.');
  }

  Future<List<ProductReviewEntry>> fetchRecent(String productId) async {
    String productTitle = 'sản phẩm VELORA';
    try {
      final pDoc = await _db.collection('Products').doc(productId).get();
      final t = (pDoc.data()?['Title'] as String?)?.trim();
      if (t != null && t.isNotEmpty) productTitle = t;
    } catch (_) {}

    final snapshot = await _db
        .collection('Products')
        .doc(productId)
        .collection('Reviews')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    final entries = <ProductReviewEntry>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final rating = (data['rating'] as num? ?? 0).toInt();
      if (rating < 1 || rating > 5) continue;
      final authorName = data['authorName'] as String? ?? 'Khách hàng';
      final rawReply = (data['adminReply'] as String?)?.trim();
      final sanitizedReply = ProductReviewEntry.sanitizeAdminReplyForRating(
        rawReply: rawReply,
        rating: rating,
        authorName: authorName,
        productTitle: productTitle,
      );

      // Self-heal stale reply in Firestore if detected
      if (rawReply != null &&
          sanitizedReply != null &&
          rawReply != sanitizedReply) {
        _db
            .collection('Products')
            .doc(productId)
            .collection('Reviews')
            .doc(doc.id)
            .update({'adminReply': sanitizedReply}).catchError((_) {});
      }

      entries.add(
        ProductReviewEntry(
          id: doc.id,
          userId: (data['userId'] as String?) ?? doc.id.split('_').first,
          authorName: authorName,
          rating: rating,
          text: data['text'] as String? ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
          adminReply: sanitizedReply,
          adminReplyAt: (data['adminReplyAt'] as Timestamp?)?.toDate(),
          imageUrls: List<String>.from(data['imageUrls'] as List? ?? const []),
          videoUrls: List<String>.from(data['videoUrls'] as List? ?? const []),
          verifiedPurchase: data['verifiedPurchase'] == true ||
              (data['purchaseOrderId'] as String? ?? '').isNotEmpty,
        ),
      );
    }
    return entries;
  }

  Future<int> save(
    String productId,
    int rating,
    String text, {
    String? purchaseOrderId,
    List<String> imageUrls = const [],
    List<String> videoUrls = const [],
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Vui lòng đăng nhập để gửi đánh giá.');
    if (rating < 1 ||
        rating > 5 ||
        (text.trim().length < 5 && imageUrls.isEmpty && videoUrls.isEmpty) ||
        text.trim().length > 1000) {
      throw StateError(
          'Vui lòng chọn số sao và nhập cảm nhận (hoặc đính kèm ảnh/video).');
    }

    final permission = await eligibility(productId, orderId: purchaseOrderId);
    if (!permission.allowed) throw StateError(permission.message);

    final name = Get.isRegistered<UserController>() &&
            UserController.instance.user.value.fullName.trim().isNotEmpty
        ? UserController.instance.user.value.fullName.trim()
        : (user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : (user.email?.split('@').first ?? 'Khách hàng VELORA'));

    // Check AdminAutomation settings to auto-generate the exact star-matched reply
    String autoAdminReply = '';
    try {
      String productTitle = 'sản phẩm VELORA';
      final pDoc = await _db.collection('Products').doc(productId).get();
      final pTitle = (pDoc.data()?['Title'] as String?)?.trim();
      if (pTitle != null && pTitle.isNotEmpty) {
        productTitle = pTitle;
      }

      final autoDoc =
          await _db.collection('Settings').doc('AdminAutomation').get();
      final autoData = autoDoc.data() ?? const <String, dynamic>{};
      final autoEnabled = autoData['autoReviewReply'] != false;
      if (autoEnabled) {
        final tplHigh = (autoData['replyTemplateHigh'] as String?)?.trim() ??
            'Cảm ơn {name} đã tin tưởng và đánh giá {stars}★ cho {product}! VELORA rất vui khi bạn hài lòng — hẹn gặp lại bạn ở những bộ sưu tập tiếp theo nhé!';
        final tplMid = (autoData['replyTemplateMid'] as String?)?.trim() ??
            'Cảm ơn {name} đã chia sẻ trải nghiệm về {product}. VELORA đã ghi nhận góp ý của bạn để cải thiện chất lượng và dịch vụ tốt hơn nữa!';
        final tplLow = (autoData['replyTemplateLow'] as String?)?.trim() ??
            'VELORA thành thật xin lỗi {name} vì trải nghiệm chưa trọn vẹn với {product}. Đội ngũ CSKH sẽ liên hệ hỗ trợ kiểm tra và đổi trả tốt nhất cho bạn ngay!';

        final chosenTemplate = rating >= 4
            ? tplHigh
            : (rating == 3 ? tplMid : tplLow);
        autoAdminReply = chosenTemplate
            .replaceAll('{name}', name)
            .replaceAll('{product}', productTitle)
            .replaceAll('{stars}', '$rating');
      }
    } catch (_) {}

    final ref = _db.collection('Products').doc(productId).collection('Reviews').doc();
    return LoyaltyCoins().saveReview(productId: productId, reviewId: ref.id,
      orderDocumentId: permission.orderDocumentId, data: {
      'userId': user.uid,
      'authorName': name,
      'rating': rating,
      'text': text.trim(),
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'verifiedPurchase': true,
      'purchaseOrderId': permission.orderDocumentId,
      if (autoAdminReply.isNotEmpty) ...{
        'adminReply': autoAdminReply,
        'adminReplyAt': FieldValue.serverTimestamp(),
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
