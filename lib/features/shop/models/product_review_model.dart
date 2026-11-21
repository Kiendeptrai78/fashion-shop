class ProductReviewEntry {
  const ProductReviewEntry({required this.id, required this.authorName,
    required this.rating, required this.text, this.createdAt});
  final String id, authorName, text;
  final int rating;
  final DateTime? createdAt;
}

class ProductReviewSummary {
  ProductReviewSummary(List<ProductReviewEntry> reviews)
      : count = reviews.length,
        average = reviews.isEmpty ? 0 : reviews.fold<int>(0, (sum, review) => sum + review.rating) / reviews.length,
        stars = {for (var star = 1; star <= 5; star++) star: reviews.where((review) => review.rating == star).length};
  final int count;
  final double average;
  final Map<int, int> stars;
}
