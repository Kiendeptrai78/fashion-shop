import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/screens/reels/velora_review_video_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stock clips use original audio instead of the VELORA music mix', () {
    const mixed = 'https://res.cloudinary.com/lbbgn51d/video/upload/velora-product-videos/mixed.mp4';
    const original = 'https://cdn.pixabay.com/video/original.mp4';
    final product = ProductModel.empty()..videos = [mixed]
      ..videoSources = [{'url': mixed, 'originalUrl': original, 'provider': 'Pixabay',
        'author': 'OriginalCreator', 'audioCredit': 'VELORA Original - synthesized instrumental'}];
    expect(VeloraReviewVideoCatalog.videosForProduct(product), [original]);
    expect(VeloraReviewVideoCatalog.metadataForUrl(original, product).creatorName, 'OriginalCreator');
    product.videoSources!.first['audioCredit'] = '';
    expect(VeloraReviewVideoCatalog.videosForProduct(product), [mixed]);
  });

  test('entertainment keeps the real author independently of the suggested shoe', () {
    final clip = VeloraReviewVideoCatalog.metadataForUrl('https://cdn.pixabay.com/video/city.mp4',
      ProductModel.empty(), sourceOverride: {'provider': 'Pixabay', 'author': 'CityCreator'});
    expect(clip.creatorName, 'CityCreator');
    expect(clip.creatorHandle, 'Pixabay');
  });

  test('a legacy music mix without an original source is skipped', () {
    final product = ProductModel.empty()..videos = [
      'https://res.cloudinary.com/lbbgn51d/video/upload/velora-product-videos/pixabay-running-10809-audio-v1.mp4',
    ];
    expect(VeloraReviewVideoCatalog.videosForProduct(product), isEmpty);
  });
  test('products without assigned videos get no synthetic fallback clips', () {
    expect(VeloraReviewVideoCatalog.videosForProduct(ProductModel.empty()), isEmpty);
  });
  test('legacy stock/test videos are excluded and imported metadata round trips', () {
    const url = 'https://cdn.pixabay.com/video/real.mp4';
    final product = ProductModel.empty()..videos = ['https://assets.mixkit.co/videos/old.mp4', url]
      ..videoSources = [{'url': url, 'provider': 'Pixabay', 'author': 'RealCreator',
        'sourceUrl': 'https://pixabay.com/videos/id-4/'}];
    final restored = ProductModel.fromJson(product.toJson(), id: 'shoe');
    expect(VeloraReviewVideoCatalog.videosForProduct(restored), [url]);
    final metadata = VeloraReviewVideoCatalog.metadataForUrl(url, restored);
    expect(metadata.creatorName, 'RealCreator');
    expect(metadata.creatorHandle, 'Pixabay');
    expect(metadata.reviewQuoteVi, contains('Video cảm hứng'));
  });
  test('an uploaded clip is not assigned a fake customer identity', () {
    final metadata = VeloraReviewVideoCatalog.metadataForUrl('https://shop.example/shoe.mp4', ProductModel.empty());
    expect(metadata.creatorName, 'VELORA');
    expect(metadata.reviewTag, 'Video cửa hàng');
  });
}
