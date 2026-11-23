import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/product/cart/cart_menu_icon.dart';
import 'package:fashion_business_app/common/widgets/product/favourite_icon/favourite_icon.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/images_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/variation_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/screens/product_details/widgets/product_attributes.dart';
import 'package:fashion_business_app/features/shop/screens/product_reviews/product_review.dart';
import 'package:fashion_business_app/features/shop/screens/reels/velora_reels_screen.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:video_player/video_player.dart';

import 'widgets/bottom_add_to_cart_widget.dart';
import 'widgets/product_detail_image_slider.dart';
import 'widgets/product_meta_data.dart';
import 'widgets/similar_products.dart';

class ProductDetail extends StatefulWidget {
  const ProductDetail({super.key, required this.product});

  final ProductModel product;

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  late ProductModel product;
  final _scroll = ScrollController();
  final _optionsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    product = widget.product;
    if (!Get.isRegistered<ImageController>()) {
      Get.put(ImageController());
    }
    if (!Get.isRegistered<VariationController>()) {
      Get.put(VariationController());
    }
    // Defer reactive GetX Rx mutations until after the current frame build
    // so navigating from VeloraReelsScreen or another ProductDetail never
    // triggers "setState() or markNeedsBuild() called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _selectProduct();
    });
  }

  void _selectProduct() {
    final imgCtrl = Get.isRegistered<ImageController>()
        ? ImageController.instance
        : Get.put(ImageController());
    imgCtrl.selectedProductImage.value = product.thumbnail;
    final variations = Get.isRegistered<VariationController>()
        ? VariationController.instance
        : Get.put(VariationController());
    variations.resetSelectedAttribute();
    final cart = CartController.instance;
    cart.updateAlreadyAddedProductCount(product);
    if (cart.productQuantityInCart.value < 1) {
      cart.productQuantityInCart.value = 1;
    }
    final colors = product.productAttributes
        ?.where((a) => a.name == 'Color')
        .firstOrNull
        ?.values;
    if (colors != null && colors.isNotEmpty) {
      variations.onAttributeSelected(product, 'Color', colors.first);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _openSimilar(ProductModel selected) {
    setState(() => product = selected);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _selectProduct();
    });
    _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF1A2721) : const Color(0xFFF6F8F4);
    final border =
        dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5EAE2);

    return Scaffold(
      appBar: TAppbar(
        showBackArrow: true,
        title: const Text(
          'VELORA',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
          ),
        ),
        actions: [
          TFavouriteIcon(productId: product.id),
          const TCartCounterIcon(),
        ],
      ),
      bottomNavigationBar: TBottomAddToCart(
        product: product,
        onSelectOptions: () {
          final options = _optionsKey.currentContext;
          if (options != null) {
            Scrollable.ensureVisible(
              options,
              duration: const Duration(milliseconds: 250),
              alignment: 0.1,
            );
          }
        },
      ),
      body: SingleChildScrollView(
        controller: _scroll,
        child: Column(
          children: [
            TProductImageSlider(product: product),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TProductMetaData(product: product),
                  const SizedBox(height: 18),
                  // Trust assurances strip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _assurance(
                            context,
                            Iconsax.verify,
                            'Verified genuine',
                          ),
                        ),
                        Expanded(
                          child: _assurance(
                            context,
                            Iconsax.truck_fast,
                            'Fast delivery',
                          ),
                        ),
                        Expanded(
                          child: _assurance(
                            context,
                            Iconsax.refresh_circle,
                            'Easy returns',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(height: 1),
                  ),
                  if (product.productType == ProductType.variable.toString())
                    KeyedSubtree(
                      key: _optionsKey,
                      child: TProductAttribute(product: product),
                    ),
                  const SizedBox(height: 24),

                  // Inline Horizontal Scrollable Promo Videos (views directly on ProductDetail!)
                  _ProductInlineVideosStrip(
                    key: ValueKey('videos_${product.id}'),
                    product: product,
                  ),

                  const SizedBox(height: 20),
                  Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 16),
                      initiallyExpanded: true,
                      title: const ShopText(
                        'About this pair',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ShopText(
                            product.description ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (product.categoryName.isNotEmpty)
                        _detailChip(
                          context,
                          'Collection',
                          product.categoryName,
                          surface,
                          border,
                        ),
                      if ((product.productAttributes
                                  ?.where((a) => a.name == 'Size')
                                  .firstOrNull
                                  ?.values ??
                              [])
                          .isNotEmpty)
                        _detailChip(context, 'Sizing', 'EU', surface, border),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Material(
                    color: surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: dark
                              ? const Color(0xFF283A2E)
                              : const Color(0xFFE7F0EA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFD99A1E),
                          size: 22,
                        ),
                      ),
                      title: const ShopText(
                        'Customer reviews',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: const ShopText(
                        'See how this pair feels in everyday life.',
                        style: TextStyle(fontSize: 12.5),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Get.to(
                        () => ProductReview(
                          productId: product.id,
                          productTitle: product.title,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SimilarProducts(
                    key: ValueKey(product.id),
                    product: product,
                    onOpen: _openSimilar,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _assurance(BuildContext context, IconData icon, String label) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
        ),
        const SizedBox(height: 5),
        ShopText(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _detailChip(
    BuildContext context,
    String label,
    String value,
    Color bg,
    Color border,
  ) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ShopText(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 3),
            ShopText(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      );
}

class _ProductInlineVideosStrip extends StatelessWidget {
  const _ProductInlineVideosStrip({super.key, required this.product});

  final ProductModel product;

  static const Map<String, List<String>> _fallbackVideos = {
    'running-category': [
      'https://res.cloudinary.com/lbbgn51d/video/upload/v1795247608/velora-reels-v2/velora_reel_running_v2.mp4',
      'https://res.cloudinary.com/lbbgn51d/video/upload/v1795247611/velora-reels-v2/velora_reel_stride_v2.mp4',
    ],
    'lifestyle-category': [
      'https://res.cloudinary.com/lbbgn51d/video/upload/v1795247614/velora-reels-v2/velora_reel_lifestyle_v2.mp4',
      'https://res.cloudinary.com/lbbgn51d/video/upload/v1795247608/velora-reels-v2/velora_reel_running_v2.mp4',
    ],
    'training-category': [
      'https://res.cloudinary.com/lbbgn51d/video/upload/v1795247616/velora-reels-v2/velora_reel_training_v2.mp4',
      'https://res.cloudinary.com/lbbgn51d/video/upload/v1795247608/velora-reels-v2/velora_reel_running_v2.mp4',
    ],
    'basketball-category': [
      'https://res.cloudinary.com/lbbgn51d/video/upload/v1795247618/velora-reels-v2/velora_reel_basketball_v2.mp4',
      'https://res.cloudinary.com/lbbgn51d/video/upload/v1795247616/velora-reels-v2/velora_reel_training_v2.mp4',
    ],
    'trail-category': [
      'https://res.cloudinary.com/lbbgn51d/video/upload/v1795247621/velora-reels-v2/velora_reel_trail_v2.mp4',
      'https://res.cloudinary.com/lbbgn51d/video/upload/v1795247608/velora-reels-v2/velora_reel_running_v2.mp4',
    ],
  };

  List<String> _resolveVideos() {
    final explicit = (product.videos ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (explicit.isNotEmpty) return explicit;
    return _fallbackVideos[product.categoryId] ??
        _fallbackVideos['running-category']!;
  }

  @override
  Widget build(BuildContext context) {
    final videos = _resolveVideos();
    if (videos.isEmpty) return const SizedBox.shrink();
    final isVi = Localizations.localeOf(context).languageCode != 'en';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.play_circle_fill_rounded,
              color: Color(0xFF173E32),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isVi
                    ? 'Video thực tế sản phẩm (${videos.length} video)'
                    : 'Product lookbook videos (${videos.length})',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => Get.to(
                () => VeloraReelsScreen(
                  initialProduct: product,
                  showBackButton: true,
                ),
              ),
              icon: const Icon(Icons.fullscreen_rounded, size: 18),
              label: const ShopText(
                'Full screen',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 310,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: videos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return _InlinePromoVideoCard(
                key: ValueKey('${product.id}_inline_vid_$index'),
                product: product,
                videoUrl: videos[index],
                index: index,
                total: videos.length,
                autoPlay: index == 0,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InlinePromoVideoCard extends StatefulWidget {
  const _InlinePromoVideoCard({
    super.key,
    required this.product,
    required this.videoUrl,
    required this.index,
    required this.total,
    required this.autoPlay,
  });

  final ProductModel product;
  final String videoUrl;
  final int index;
  final int total;
  final bool autoPlay;

  @override
  State<_InlinePromoVideoCard> createState() => _InlinePromoVideoCardState();
}

class _InlinePromoVideoCardState extends State<_InlinePromoVideoCard> {
  VideoPlayerController? _ctrl;
  bool _ready = false;
  bool _playing = false;
  bool _muted = true;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      _ctrl = c;
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      if (widget.autoPlay) {
        await c.play();
        _playing = true;
      }
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _ready = false);
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final c = _ctrl;
    if (c == null || !_ready) return;
    setState(() {
      if (c.value.isPlaying) {
        c.pause();
        _playing = false;
      } else {
        c.play();
        _playing = true;
      }
    });
  }

  void _toggleMute() {
    final c = _ctrl;
    if (c == null || !_ready) return;
    setState(() {
      _muted = !_muted;
      c.setVolume(_muted ? 0 : 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 195,
      height: 310,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0B221B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF173E32).withValues(alpha: 0.28),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Video Player or sneaker studio thumbnail while loading
          GestureDetector(
            onTap: _togglePlay,
            child: _ready && _ctrl != null
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _ctrl!.value.size.width,
                      height: _ctrl!.value.size.height,
                      child: VideoPlayer(_ctrl!),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        colors: [Color(0xFF1E5242), Color(0xFF0A1E17)],
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: CachedNetworkImage(
                      imageUrl: widget.product.thumbnail,
                      fit: BoxFit.contain,
                    ),
                  ),
          ),

          // 2. Top badge (Video 1/2 + Mute button)
          Positioned(
            left: 10,
            right: 10,
            top: 10,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _playing
                            ? Icons.fiber_manual_record_rounded
                            : Icons.play_arrow_rounded,
                        size: 11,
                        color: const Color(0xFFDDEABB),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Video ${widget.index + 1}/${widget.total}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Center play button when paused
          if (!_playing)
            Center(
              child: GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFDDEABB)),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFFDDEABB),
                    size: 28,
                  ),
                ),
              ),
            ),

          // 4. Bottom bar to open full-screen Reels with Like & Comment
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: GestureDetector(
              onTap: () {
                _ctrl?.pause();
                setState(() => _playing = false);
                Get.to(
                  () => VeloraReelsScreen(
                    initialProduct: widget.product,
                    showBackButton: true,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF14352B).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFDDEABB).withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFFF4D6D),
                      size: 13,
                    ),
                    SizedBox(width: 5),
                    Expanded(
                      child: ShopText(
                        'Like & Comment',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.open_in_full_rounded,
                      color: Color(0xFFDDEABB),
                      size: 13,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
