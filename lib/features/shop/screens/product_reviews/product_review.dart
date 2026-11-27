import 'package:fashion_business_app/common/widgets/glass/shop_overlays.dart';
import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/common/widgets/list_tiles/loyalty_coins_tile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/tabs/shop_filter_tab.dart';
import 'package:fashion_business_app/data/repositories/reviews/review_repository.dart';
import 'package:fashion_business_app/data/services/image_storage_service.dart';
import 'package:fashion_business_app/features/shop/models/product_review_model.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

class ProductReview extends StatefulWidget {
  const ProductReview({
    super.key,
    this.productId,
    this.productTitle,
    this.purchaseOrderId,
    this.loadReviews,
    this.loadEligibility,
  });

  final String? productId, productTitle, purchaseOrderId;
  final Future<List<ProductReviewEntry>> Function()? loadReviews;
  final Future<ReviewEligibility> Function()? loadEligibility;

  @override
  State<ProductReview> createState() => _ProductReviewState();
}

class _ProductReviewState extends State<ProductReview> {
  late Future<List<ProductReviewEntry>> _reviews;
  final PageController _carouselCtrl = PageController(viewportFraction: 0.9);
  int _star = 0;
  bool _onlyWithMedia = false;
  bool _openingReview = false;
  bool _submittedReview = false;

  @override
  void initState() {
    super.initState();
    _reviews = _load();
  }

  @override
  void dispose() {
    _carouselCtrl.dispose();
    super.dispose();
  }

  Future<List<ProductReviewEntry>> _load() =>
      widget.loadReviews?.call() ??
      (widget.productId == null
          ? Future.value([])
          : ReviewRepository().fetchRecent(widget.productId!));

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _reviews = next;
    });
    try {
      await next;
    } catch (_) {}
  }

  Future<void> _write() async {
    if (_openingReview || _submittedReview) return;
    setState(() => _openingReview = true);
    try {
      final permission = await (widget.loadEligibility?.call() ?? ReviewRepository()
          .eligibility(widget.productId!, orderId: widget.purchaseOrderId));
      if (!mounted) return;
      if (!permission.allowed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(permission.message)));
        return;
      }
      setState(() => _openingReview = false);
      final saved = await showShopBottomSheet<bool>(
        context: context, isScrollControlled: true, useSafeArea: true,
        builder: (_) => _WriteReview(productId: widget.productId!, purchaseOrderId: permission.orderDocumentId),
      );
      if (saved == true && mounted) {
        setState(() => _submittedReview = true);
        _refresh();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Chưa kiểm tra được quyền đánh giá. Vui lòng thử lại.')));
      }
    } finally {
      if (mounted) setState(() => _openingReview = false);
    }
  }

  void _openMediaViewer(List<String> images, List<String> videos, int initialIndex) {
    showDialog<void>(
      context: context,
      builder: (_) => _ReviewMediaViewerDialog(
        imageUrls: images,
        videoUrls: videos,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const TAppbar(
        showBackArrow: true,
        title: ShopText(
          'Customer reviews',
          style: shopAppbarTitleStyle,
        ),
      ),
      body: FutureBuilder<List<ProductReviewEntry>>(
        future: _reviews,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ShopText('Couldn’t load reviews.'),
                  TextButton(onPressed: _refresh, child: const ShopText('Try again')),
                ],
              ),
            );
          }
          final reviews = snapshot.data ?? [];
          final summary = ProductReviewSummary(reviews);
          final filtered = reviews.where((review) {
            if (_star != 0 && review.rating != _star) return false;
            if (_onlyWithMedia && !review.hasMedia) return false;
            return true;
          }).toList();
          final mediaReviewsCount = reviews.where((r) => r.hasMedia).length;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: shopAppbarContentPadding(context, EdgeInsets.all(20)),
              children: [
                if (widget.productTitle != null)
                  Text(
                    widget.productTitle!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                const SizedBox(height: 8),
                const ShopText(
                  'Trải nghiệm thực tế, hình ảnh & video quay trực tiếp từ khách hàng VELORA.',
                  style: TextStyle(height: 1.5),
                ),
                const SizedBox(height: 22),
                if (reviews.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.average.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 48,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _stars(summary.average),
                          const SizedBox(height: 8),
                          ShopText(
                            '${summary.count} recent reviews',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: [
                            for (var star = 5; star >= 1; star--)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Text('$star', style: theme.textTheme.labelSmall),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          minHeight: 5,
                                          value: summary.stars[star]! / summary.count,
                                          color: theme.colorScheme.primary,
                                          backgroundColor:
                                              theme.colorScheme.primary.withValues(alpha: 0.08),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${summary.stars[star]}',
                                        style: theme.textTheme.labelSmall),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 34),
                  ShopFilterTabs(tabs: [
                      for (final star in [0, 5, 4, 3, 2, 1])
                        ShopFilterTab(
                          label: star == 0 ? 'All' : '$star ★',
                          count: star == 0 ? summary.count : summary.stars[star]!,
                          selected: _star == star,
                          onTap: () => setState(() {
                            _star = star;
                            if (star == 0) _onlyWithMedia = false;
                          }),
                        ),
                  ]),
                  if (mediaReviewsCount > 0)
                    Align(alignment: Alignment.centerLeft, child:
                        FilterChip(
                          selected: _onlyWithMedia,
                          onSelected: (v) => setState(() => _onlyWithMedia = v),
                          label: Text('Có Ảnh/Video ($mediaReviewsCount)'),
                        )),
                  if (filtered.any((r) => r.hasMedia)) ...[
                    const SizedBox(height: 18),
                    const Text(
                      'Ảnh & Video thực tế từ khách hàng',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Builder(builder: (_) {
                      final mediaSlots = <({
                        ProductReviewEntry review,
                        String url,
                        bool isVideo,
                        int mediaIdx,
                      })>[];
                      for (final r in filtered.where((e) => e.hasMedia)) {
                        for (var i = 0; i < r.imageUrls.length; i++) {
                          mediaSlots.add((
                            review: r,
                            url: r.imageUrls[i],
                            isVideo: false,
                            mediaIdx: i,
                          ));
                        }
                        for (var i = 0; i < r.videoUrls.length; i++) {
                          mediaSlots.add((
                            review: r,
                            url: r.videoUrls[i],
                            isVideo: true,
                            mediaIdx: r.imageUrls.length + i,
                          ));
                        }
                      }
                      return SizedBox(
                        height: 86,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: mediaSlots.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            final slot = mediaSlots[i];
                            return GestureDetector(
                              onTap: () => _openMediaViewer(
                                slot.review.imageUrls,
                                slot.review.videoUrls,
                                slot.mediaIdx,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: SizedBox(
                                  width: 86,
                                  height: 86,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (slot.isVideo)
                                        Container(
                                          color: const Color(0xFF14352B),
                                          child: const Center(
                                            child: Icon(
                                              Icons.play_circle_fill_rounded,
                                              color: Color(0xFFDDEABB),
                                              size: 30,
                                            ),
                                          ),
                                        )
                                      else
                                        CachedNetworkImage(
                                          imageUrl: slot.url,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) =>
                                              const Icon(Icons
                                                  .broken_image_outlined),
                                        ),
                                      Positioned(
                                        left: 6,
                                        bottom: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.65),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${slot.review.rating}★',
                                            style: const TextStyle(
                                              color: Color(0xFFFFD166),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 18),
                ],
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Column(
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 52,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 18),
                        ShopText(
                          widget.productId == null
                              ? 'Choose a pair to see its reviews.'
                              : reviews.isEmpty
                                  ? 'Be the first to share your experience.'
                                  : 'No reviews with this rating yet.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Hãy bấm nút bên dưới để viết đánh giá, chụp ảnh hoặc quay video thực tế đôi giày của bạn!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                for (final review in filtered)
                  Builder(builder: (_) {
                    final isLowRating = review.rating <= 2;
                    final isMidRating = review.rating == 3;
                    final starColor = isLowRating
                        ? const Color(0xFFDC2626)
                        : (isMidRating
                            ? const Color(0xFFD97706)
                            : const Color(0xFF16A34A));
                    final starBg = isLowRating
                        ? const Color(0xFFFFE4E6)
                        : (isMidRating
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFDCFCE7));
                    final starLabel = isLowRating
                        ? 'Cần hỗ trợ (${review.rating}★)'
                        : (isMidRating
                            ? 'Bình thường (3★)'
                            : 'Hài lòng (${review.rating}★)');
                    final effectiveReply =
                        ProductReviewEntry.sanitizeAdminReplyForRating(
                      rawReply: review.adminReply,
                      rating: review.rating,
                      authorName: review.authorName,
                      productTitle: widget.productTitle ?? 'sản phẩm VELORA',
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: ShopGlassDecoration(
                        color: isDark ? const Color(0xFF16231D) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFE2E8E4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 19,
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                child: Text(
                                  review.authorName.trim().isEmpty
                                      ? 'K'
                                      : review.authorName.characters.first
                                          .toUpperCase(),
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: ShopText(
                                            review.authorName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14.5,
                                            ),
                                          ),
                                        ),
                                        if (review.verifiedPurchase) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.verified_rounded,
                                                  size: 11,
                                                  color: Color(0xFF15803D),
                                                ),
                                                SizedBox(width: 3),
                                                Text(
                                                  'Đã mua hàng',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF15803D),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    if (review.createdAt != null)
                                      Text(
                                        DateFormat.yMMMd(
                                          Localizations.localeOf(context)
                                              .languageCode,
                                        ).format(review.createdAt!),
                                        style: theme.textTheme.labelSmall,
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: starBg,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  starLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: starColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _stars(review.rating.toDouble()),
                          const SizedBox(height: 8),
                          Text(
                            review.text,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.55,
                              fontSize: 14,
                            ),
                          ),

                          // Swipeable review photos & videos strip
                          if (review.hasMedia) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 92,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: review.imageUrls.length +
                                    review.videoUrls.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (_, idx) {
                                  final isVideo =
                                      idx >= review.imageUrls.length;
                                  final url = isVideo
                                      ? review.videoUrls[
                                          idx - review.imageUrls.length]
                                      : review.imageUrls[idx];
                                  return GestureDetector(
                                    onTap: () => _openMediaViewer(
                                      review.imageUrls,
                                      review.videoUrls,
                                      idx,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        width: 92,
                                        height: 92,
                                        color: Colors.black12,
                                        child: isVideo
                                            ? Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  Container(
                                                    color:
                                                        const Color(0xFF14352B),
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons
                                                            .play_circle_fill_rounded,
                                                        color:
                                                            Color(0xFFDDEABB),
                                                        size: 36,
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    left: 6,
                                                    bottom: 6,
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black54,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: const Text(
                                                        'VIDEO',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : CachedNetworkImage(
                                                imageUrl: url,
                                                fit: BoxFit.cover,
                                                errorWidget: (_, __, ___) =>
                                                    const Icon(Icons
                                                        .broken_image_outlined),
                                              ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],

                          // Modern Official VELORA CSKH Reply Card
                          if (effectiveReply != null &&
                              effectiveReply.trim().isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              decoration: ShopGlassDecoration(
                                color: isLowRating
                                    ? (isDark
                                        ? const Color(0xFF2A1C1E)
                                        : const Color(0xFFFFF8F6))
                                    : (isDark
                                        ? const Color(0xFF1B2E26)
                                        : const Color(0xFFF3F8F5)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border(
                                  left: BorderSide(
                                    color: isLowRating
                                        ? const Color(0xFFE11D48)
                                        : const Color(0xFF173E32),
                                    width: 4,
                                  ),
                                ),
                              ),
                              padding:
                                  const EdgeInsets.fromLTRB(14, 12, 14, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isLowRating
                                              ? const Color(0xFFE11D48)
                                              : const Color(0xFF173E32),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'V',
                                          style: TextStyle(
                                            color: Color(0xFFDDEABB),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          isLowRating
                                              ? 'VELORA CSKH • Hỗ trợ đổi trả & bảo hành'
                                              : 'Phản hồi từ VELORA Official',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: isLowRating
                                                ? const Color(0xFFBE123C)
                                                : (isDark
                                                    ? const Color(0xFFDDEABB)
                                                    : const Color(0xFF173E32)),
                                          ),
                                        ),
                                      ),
                                      if (review.adminReplyAt != null)
                                        Text(
                                          DateFormat.yMMMd(
                                            Localizations.localeOf(context)
                                                .languageCode,
                                          ).format(review.adminReplyAt!),
                                          style: theme.textTheme.labelSmall,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    effectiveReply,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: widget.productId == null
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_submittedReview)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: ShopGlassDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const GoldCoinIcon(size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              Localizations.localeOf(context).languageCode ==
                                      'en'
                                  ? 'First review of delivered pair earns +1,000 coins'
                                  : 'Đánh giá lần đầu đơn đã nhận tích ngay +1.000 xu',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _openingReview || _submittedReview ? null : _write,
                      icon: const Icon(Iconsax.camera, size: 18),
                      label: _submittedReview
                          ? Text(
                              Localizations.localeOf(context).languageCode ==
                                      'en'
                                  ? 'Reviewed'
                                  : 'Đã đánh giá',
                            )
                          : _openingReview
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const ShopText('Write a review'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _stars(double rating) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var star = 1; star <= 5; star++)
            Icon(
              rating >= star
                  ? Icons.star_rounded
                  : rating >= star - 0.5
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded,
              size: 17,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      );
}

class ReviewRewardNotice extends StatelessWidget {
  const ReviewRewardNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: ShopGlassDecoration(
        color: dark ? const Color(0xFF19251F) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          const GoldCoinIcon(size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn
                      ? 'Complete review for +1,000 coins'
                      : 'Hoàn tất đánh giá nhận +1.000 xu',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEn
                      ? 'Save 1,000 ₫ on your next order · 1 reward per item'
                      : 'Giảm trực tiếp 1.000 ₫ cho đơn sau · Tính thưởng 1 lần/SP',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: dark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isEn ? '+1,000' : '+1.000 xu',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WriteReview extends StatefulWidget {
  const _WriteReview({required this.productId, this.purchaseOrderId});
  final String productId;
  final String? purchaseOrderId;
  @override
  State<_WriteReview> createState() => _WriteReviewState();
}

class _WriteReviewState extends State<_WriteReview> {
  final _text = TextEditingController();
  final _picker = ImagePicker();
  final _storage = ImageStorageService(
    cloudName: 'lbbgn51d',
    uploadPreset: 'fashion_shop',
  );

  int _rating = 5;
  bool _saving = false;
  bool _uploadingMedia = false;
  String? _error;
  final List<String> _imageUrls = [];
  final List<String> _videoUrls = [];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() {
      _uploadingMedia = true;
      _error = null;
    });
    try {
      XFile? file;
      try {
        file = await _picker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1600,
        );
      } catch (_) {
        // Fallback to gallery on simulator if camera is unavailable
        if (source == ImageSource.camera) {
          file = await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
            maxWidth: 1600,
          );
        }
      }
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final url = await _storage.uploadImageData(
        'Reviews/Images',
        bytes,
        file.name.isNotEmpty ? file.name : 'review_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      if (mounted) setState(() => _imageUrls.add(url));
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Không thể tải ảnh lên: $e');
      }
    } finally {
      if (mounted) setState(() => _uploadingMedia = false);
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    setState(() {
      _uploadingMedia = true;
      _error = null;
    });
    try {
      XFile? file;
      try {
        file = await _picker.pickVideo(
          source: source,
          maxDuration: const Duration(seconds: 45),
        );
      } catch (_) {
        // Fallback to gallery on simulator if camera is unavailable
        if (source == ImageSource.camera) {
          file = await _picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(seconds: 45),
          );
        }
      }
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final url = await _storage.uploadVideoData(
        'Reviews/Videos',
        bytes,
        file.name.isNotEmpty ? file.name : 'review_vid_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      if (mounted) setState(() => _videoUrls.add(url));
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Không thể tải video lên: $e');
      }
    } finally {
      if (mounted) setState(() => _uploadingMedia = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final reward = await ReviewRepository().save(
        widget.productId,
        _rating,
        _text.text,
        purchaseOrderId: widget.purchaseOrderId,
        imageUrls: _imageUrls,
        videoUrls: _videoUrls,
      );
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        final isEn = Localizations.localeOf(context).languageCode == 'en';
        Navigator.pop(context, true);
        messenger.showSnackBar(SnackBar(content: Text(reward > 0
          ? (isEn ? 'Review saved · +1,000 coins (1,000₫)' : 'Đã gửi đánh giá · +1.000 xu (1.000đ)')
          : (isEn ? 'Review saved' : 'Đã gửi đánh giá'))));
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is StateError
              ? error.message.toString()
              : 'Không thể lưu đánh giá. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _ratingSentiment(int r) {
    switch (r) {
      case 5:
        return 'Rất hài lòng';
      case 4:
        return 'Hài lòng';
      case 3:
        return 'Bình thường';
      case 2:
        return 'Chưa ưng ý';
      default:
        return 'Không hài lòng';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Viết đánh giá sản phẩm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                ShopGlassIconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icons.close_rounded,
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 10),
            const ReviewRewardNotice(),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: ShopGlassDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  for (var star = 1; star <= 5; star++)
                    GestureDetector(
                      onTap:
                          _saving ? null : () => setState(() => _rating = star),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          star <= _rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 30,
                          color: star <= _rating
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    '$_rating/5 · ${_ratingSentiment(_rating)}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _text,
              minLines: 3,
              maxLines: 5,
              maxLength: 1000,
              enabled: !_saving,
              decoration: const InputDecoration(
                hintText:
                    'Chia sẻ cảm giác mang, độ êm, form size và chất lượng đôi giày VELORA...',
              ),
            ),
            const SizedBox(height: 8),

            // Clean 2x2 aligned media buttons
            const Text(
              'Hình ảnh & Video thực tế (tùy chọn)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploadingMedia || _saving
                        ? null
                        : () => _pickPhoto(ImageSource.camera),
                    icon: const Icon(Iconsax.camera, size: 16),
                    label:
                        const Text('Chụp ảnh', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploadingMedia || _saving
                        ? null
                        : () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Iconsax.gallery, size: 16),
                    label:
                        const Text('Chọn ảnh', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploadingMedia || _saving
                        ? null
                        : () => _pickVideo(ImageSource.camera),
                    icon: const Icon(Iconsax.video, size: 16),
                    label: const Text(
                      'Quay video',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploadingMedia || _saving
                        ? null
                        : () => _pickVideo(ImageSource.gallery),
                    icon: const Icon(Iconsax.video_play, size: 16),
                    label: const Text(
                      'Chọn video',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_uploadingMedia) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Đang tải ảnh / video lên...',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ],
              ),
            ],

            if (_imageUrls.isNotEmpty || _videoUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 86,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < _imageUrls.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: _imageUrls[i],
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _imageUrls.removeAt(i)),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.black87,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (var i = 0; i < _videoUrls.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Stack(
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                color: const Color(0xFF173E32),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.videocam_rounded,
                                    color: Color(0xFFDDEABB),
                                    size: 28,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'VIDEO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _videoUrls.removeAt(i)),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.black87,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 12.5),
                ),
              ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving || _uploadingMedia || _rating == 0 ? null : _save,
                child: Text(_saving ? 'Đang gửi đánh giá...' : 'Đăng đánh giá'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewMediaViewerDialog extends StatefulWidget {
  const _ReviewMediaViewerDialog({
    required this.imageUrls,
    required this.videoUrls,
    required this.initialIndex,
  });

  final List<String> imageUrls;
  final List<String> videoUrls;
  final int initialIndex;

  @override
  State<_ReviewMediaViewerDialog> createState() => _ReviewMediaViewerDialogState();
}

class _ReviewMediaViewerDialogState extends State<_ReviewMediaViewerDialog> {
  late final PageController _pageCtrl = PageController(initialPage: widget.initialIndex);
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.imageUrls.length + widget.videoUrls.length;
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: total,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, idx) {
              final isVideo = idx >= widget.imageUrls.length;
              final url = isVideo
                  ? widget.videoUrls[idx - widget.imageUrls.length]
                  : widget.imageUrls[idx];
              if (isVideo) {
                return _InlineReviewVideoPlayer(videoUrl: url);
              }
              return InteractiveViewer(
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_index + 1} / $total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  ShopGlassIconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icons.close_rounded,
                    iconColor: Colors.white,
                    iconSize: 28,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineReviewVideoPlayer extends StatefulWidget {
  const _InlineReviewVideoPlayer({required this.videoUrl});
  final String videoUrl;

  @override
  State<_InlineReviewVideoPlayer> createState() => _InlineReviewVideoPlayerState();
}

class _InlineReviewVideoPlayerState extends State<_InlineReviewVideoPlayer> {
  VideoPlayerController? _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      _ctrl = c;
      await c.initialize();
      await c.setLooping(true);
      await c.play();
      if (mounted) setState(() => _ready = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _ctrl == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFDDEABB)),
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: _ctrl!.value.aspectRatio,
        child: VideoPlayer(_ctrl!),
      ),
    );
  }
}
