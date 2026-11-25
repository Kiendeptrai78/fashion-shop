class ProductReviewEntry {
  const ProductReviewEntry({
    required this.id,
    this.userId = '',
    required this.authorName,
    required this.rating,
    required this.text,
    this.createdAt,
    this.adminReply,
    this.adminReplyAt,
    this.imageUrls = const [],
    this.videoUrls = const [],
    this.verifiedPurchase = false,
  });

  final String id, userId, authorName, text;
  final int rating;
  final DateTime? createdAt;
  final String? adminReply;
  final DateTime? adminReplyAt;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final bool verifiedPurchase;

  String get effectiveUserId =>
      userId.trim().isNotEmpty ? userId.trim() : id.split('_').first;

  bool get hasAdminReply => (adminReply ?? '').trim().isNotEmpty;
  bool get hasMedia => imageUrls.isNotEmpty || videoUrls.isNotEmpty;

  /// Ensures a 1-2★ review never displays a stale 5★ thank-you reply if a user
  /// previously overwrote their review doc before multi-review support.
  static String? sanitizeAdminReplyForRating({
    required String? rawReply,
    required int rating,
    required String authorName,
    String productTitle = 'sản phẩm VELORA',
  }) {
    final trimmed = rawReply?.trim() ?? '';
    if (trimmed.isEmpty) return rawReply;
    final safeName = authorName.trim().isEmpty ? 'bạn' : authorName.trim();
    final safeProd =
        productTitle.trim().isEmpty ? 'sản phẩm VELORA' : productTitle.trim();

    if (rating <= 2 &&
        (trimmed.contains('5★') ||
            trimmed.contains('4★') ||
            trimmed.toLowerCase().contains('rất vui khi bạn hài lòng'))) {
      return 'VELORA thành thật xin lỗi $safeName vì trải nghiệm chưa trọn vẹn ($rating★) với $safeProd. Đội ngũ CSKH VELORA đã ghi nhận phản ánh và sẽ liên hệ hỗ trợ kiểm tra, đổi mới đúng size / mẫu chuẩn cho bạn hoàn toàn miễn phí ngay hôm nay!';
    }
    if (rating == 3 &&
        (trimmed.contains('5★') ||
            trimmed.toLowerCase().contains('rất vui khi bạn hài lòng'))) {
      return 'Cảm ơn $safeName đã chia sẻ trải nghiệm ($rating★) về $safeProd. VELORA đã ghi nhận góp ý của bạn để cải thiện chất lượng sản phẩm và dịch vụ tốt hơn nữa!';
    }
    return trimmed;
  }
}

class ProductReviewSummary {
  ProductReviewSummary(List<ProductReviewEntry> reviews)
      : count = reviews.length,
        average = reviews.isEmpty
            ? 0
            : reviews.fold<int>(0, (sum, review) => sum + review.rating) /
                reviews.length,
        stars = {
          for (var star = 1; star <= 5; star++)
            star: reviews.where((review) => review.rating == star).length
        };
  final int count;
  final double average;
  final Map<int, int> stars;
}
