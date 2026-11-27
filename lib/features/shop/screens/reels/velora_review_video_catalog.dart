import 'package:fashion_business_app/features/shop/models/product_model.dart';

class VeloraReviewClip {
  const VeloraReviewClip({required this.url, required this.creatorName,
    required this.creatorHandle, required this.creatorInitials, required this.reviewTag,
    required this.reviewQuoteVi, required this.reviewQuoteEn, required this.presetLabel});
  final String url, creatorName, creatorHandle, creatorInitials, reviewTag;
  final String reviewQuoteVi, reviewQuoteEn, presetLabel;
}

/// Only explicitly assigned videos. Stock footage is inspiration, not a customer review.
class VeloraReviewVideoCatalog {
  VeloraReviewVideoCatalog._();
  static bool isLegacyAiVideoUrl(String url) {
    final value = url.toLowerCase();
    return value.contains('assets.mixkit.co/') || value.contains('velora-reels-v2/') ||
      value.contains('y7nancfcenukj5xudnhh') ||
      (value.contains('res.cloudinary.com/lbbgn51d/video/upload/') &&
        !value.contains('/velora-product-videos/'));
  }
  static List<String> videosForProduct(ProductModel product, {int fallbackCount = 2}) =>
      (product.videos ?? const <String>[]).map((url) => url.trim())
        .where((url) => url.isNotEmpty && !isLegacyAiVideoUrl(url))
        .map((url) => originalVideoUrl(url, product))
        .where((url) => !(url.contains('/velora-product-videos/pixabay-') &&
            url.contains('-audio-v1'))).toSet().toList();

  static String originalVideoUrl(String url, ProductModel product) {
    final source = (product.videoSources ?? []).where((source) => source['url'] == url).firstOrNull;
    final original = (source?['originalUrl'] ?? '').toString();
    if ((source?['audioCredit'] ?? '').toString().startsWith('VELORA Original') &&
        Uri.tryParse(original)?.host == 'cdn.pixabay.com') {
      return original;
    }
    return url;
  }

  static VeloraReviewClip metadataForUrl(String url, ProductModel product,
      {Map<String, dynamic>? sourceOverride}) {
    final source = sourceOverride ?? (product.videoSources ?? [])
        .where((source) => source['url'] == url || source['originalUrl'] == url).firstOrNull;
    final provider = (source?['provider'] ?? '').toString();
    final author = (source?['author'] ?? '').toString().trim();
    final stock = provider == 'Pixabay' || provider == 'Pexels' || provider == 'Blender Open Movies';
    final name = author.isNotEmpty ? author : 'VELORA';
    return VeloraReviewClip(url: url, creatorName: name,
      creatorHandle: stock ? provider : 'VELORA',
      creatorInitials: name.substring(0, 1).toUpperCase(),
      reviewTag: stock ? 'Video cảm hứng' : 'Video cửa hàng',
      presetLabel: stock ? '$provider · $name' : 'Video sản phẩm',
      reviewQuoteVi: stock ? 'Video cảm hứng. Khám phá sản phẩm gợi ý từ VELORA bên dưới.'
          : 'Khám phá thông tin sản phẩm và chọn đôi giày phù hợp với bạn.',
      reviewQuoteEn: stock ? 'Style inspiration. Explore the suggested VELORA product below.'
          : 'Explore the product details and find your next pair.');
  }
}
