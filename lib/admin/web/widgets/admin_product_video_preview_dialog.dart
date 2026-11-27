import 'package:fashion_business_app/common/widgets/videos/video_seek_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/data/admin_web_models.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/screens/reels/velora_review_video_catalog.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

Future<void> showAdminProductAndVideoPreviewDialog(
  BuildContext context, {
  required AdminWebController controller,
  required ProductModel product,
  String? initialVideoUrl,
  String? initialImageUrl,
  AdminVideoCommentRecord? videoComment,
  AdminReviewRecord? reviewRecord,
  String? customerActionSummary,
  VoidCallback? onOpenPushSimilar,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogCtx) => _AdminProductVideoPreviewDialog(
      controller: controller,
      product: product,
      initialVideoUrl: initialVideoUrl,
      initialImageUrl: initialImageUrl,
      videoComment: videoComment,
      reviewRecord: reviewRecord,
      customerActionSummary: customerActionSummary,
      onOpenPushSimilar: onOpenPushSimilar,
    ),
  );
}

class _MediaSlot {
  const _MediaSlot({
    required this.label,
    required this.url,
    required this.isVideo,
    this.isCustomerMedia = false,
  });

  final String label;
  final String url;
  final bool isVideo;
  final bool isCustomerMedia;
}

class _AdminProductVideoPreviewDialog extends StatefulWidget {
  const _AdminProductVideoPreviewDialog({
    required this.controller,
    required this.product,
    this.initialVideoUrl,
    this.initialImageUrl,
    this.videoComment,
    this.reviewRecord,
    this.customerActionSummary,
    this.onOpenPushSimilar,
  });

  final AdminWebController controller;
  final ProductModel product;
  final String? initialVideoUrl;
  final String? initialImageUrl;
  final AdminVideoCommentRecord? videoComment;
  final AdminReviewRecord? reviewRecord;
  final String? customerActionSummary;
  final VoidCallback? onOpenPushSimilar;

  @override
  State<_AdminProductVideoPreviewDialog> createState() =>
      _AdminProductVideoPreviewDialogState();
}

class _AdminProductVideoPreviewDialogState
    extends State<_AdminProductVideoPreviewDialog> {
  final List<_MediaSlot> _mediaSlots = [];
  int _selectedIndex = 0;

  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;
  bool _videoMuted = false;
  bool _videoError = false;

  late final TextEditingController _replyCtrl;
  bool _sendingReply = false;

  @override
  void initState() {
    super.initState();
    _buildMediaSlots();
    _initReplyController();
    _activateSlot(_selectedIndex);
  }

  void _initReplyController() {
    if (widget.videoComment != null) {
      final cm = widget.videoComment!;
      final autoText =
          widget.controller.automation.value.renderVideoCommentReply(
        authorName: cm.authorName,
        productTitle: widget.product.title,
        categoryName: widget.product.categoryName,
      );
      _replyCtrl = TextEditingController(
        text: cm.hasAdminReply ? cm.adminReply : autoText,
      );
    } else if (widget.reviewRecord != null) {
      final r = widget.reviewRecord!;
      final autoText = widget.controller.automation.value.renderAutoReply(
        authorName: r.review.authorName,
        productTitle: widget.product.title,
        rating: r.review.rating,
      );
      _replyCtrl = TextEditingController(
        text: r.review.hasAdminReply ? r.review.adminReply : autoText,
      );
    } else {
      _replyCtrl = TextEditingController();
    }
  }

  void _buildMediaSlots() {
    final p = widget.product;
    final seenUrls = <String>{};

    // 1. If opened from a specific video comment with a videoUrl, put it first
    final initVid = widget.initialVideoUrl?.trim() ?? '';
    if (initVid.isNotEmpty) {
      seenUrls.add(initVid);
      _mediaSlots.add(
        _MediaSlot(
          label: '🎬 Video khách đang xem',
          url: initVid,
          isVideo: true,
        ),
      );
    }

    // 2. If opened from a review that has customer review videos or images
    if (widget.reviewRecord != null) {
      final rev = widget.reviewRecord!.review;
      for (var i = 0; i < rev.videoUrls.length; i++) {
        final u = rev.videoUrls[i].trim();
        if (u.isEmpty || seenUrls.contains(u)) continue;
        seenUrls.add(u);
        _mediaSlots.add(
          _MediaSlot(
            label: '📹 Video khách quay #${i + 1}',
            url: u,
            isVideo: true,
            isCustomerMedia: true,
          ),
        );
      }
      for (var i = 0; i < rev.imageUrls.length; i++) {
        final u = rev.imageUrls[i].trim();
        if (u.isEmpty || seenUrls.contains(u)) continue;
        seenUrls.add(u);
        _mediaSlots.add(
          _MediaSlot(
            label: '📸 Ảnh khách chụp #${i + 1}',
            url: u,
            isVideo: false,
            isCustomerMedia: true,
          ),
        );
      }
    }

    // 3. Explicitly assigned product videos and source metadata
    final prodVideos = VeloraReviewVideoCatalog.videosForProduct(p, fallbackCount: 2);
    for (var i = 0; i < prodVideos.length; i++) {
      final u = prodVideos[i].trim();
      if (u.isEmpty || seenUrls.contains(u)) continue;
      seenUrls.add(u);
      final meta = VeloraReviewVideoCatalog.metadataForUrl(u, p);
      _mediaSlots.add(
        _MediaSlot(
          label: '🎬 Video #${i + 1} · ${meta.creatorHandle}',
          url: u,
          isVideo: true,
        ),
      );
    }

    // 4. Product thumbnail & gallery images
    if (p.thumbnail.trim().isNotEmpty && !seenUrls.contains(p.thumbnail.trim())) {
      seenUrls.add(p.thumbnail.trim());
      _mediaSlots.add(
        _MediaSlot(
          label: '👟 Ảnh chính đôi giày',
          url: p.thumbnail.trim(),
          isVideo: false,
        ),
      );
    }
    final imgs = p.images ?? const <String>[];
    for (var i = 0; i < imgs.length; i++) {
      final u = imgs[i].trim();
      if (u.isEmpty || seenUrls.contains(u)) continue;
      seenUrls.add(u);
      _mediaSlots.add(
        _MediaSlot(
          label: '👟 Ảnh góc #${i + 1}',
          url: u,
          isVideo: false,
        ),
      );
    }

    // Select specific initial image or video if requested
    if (widget.initialImageUrl != null &&
        widget.initialImageUrl!.trim().isNotEmpty) {
      final idx = _mediaSlots
          .indexWhere((s) => s.url == widget.initialImageUrl!.trim());
      if (idx >= 0) _selectedIndex = idx;
    } else if (initVid.isNotEmpty) {
      final idx = _mediaSlots.indexWhere((s) => s.url == initVid);
      if (idx >= 0) _selectedIndex = idx;
    }
  }

  Future<void> _activateSlot(int index) async {
    if (_mediaSlots.isEmpty) return;
    final safeIdx = index.clamp(0, _mediaSlots.length - 1);
    setState(() {
      _selectedIndex = safeIdx;
      _videoReady = false;
      _videoError = false;
    });

    final old = _videoCtrl;
    _videoCtrl = null;
    await old?.dispose();

    final slot = _mediaSlots[safeIdx];
    if (!slot.isVideo) return;

    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(slot.url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false));
      _videoCtrl = ctrl;
      await ctrl.initialize();
      await ctrl.setLooping(true);
      await ctrl.setVolume(_videoMuted ? 0 : 1);
      await ctrl.play();
      if (mounted) {
        setState(() => _videoReady = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _videoError = true);
      }
    }
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final c = widget.controller;
    final effectivePrice = p.salePrice > 0 ? p.salePrice : p.price;
    final activeSlot =
        _mediaSlots.isNotEmpty ? _mediaSlots[_selectedIndex] : null;

    // Extract available sizes & colors from productAttributes
    final sizes = <String>[];
    final colors = <String>[];
    for (final attr in p.productAttributes ?? const []) {
      final name = (attr.name ?? '').toLowerCase();
      if (name.contains('size') || name.contains('kích')) {
        sizes.addAll(attr.values ?? const []);
      } else if (name.contains('color') || name.contains('màu')) {
        colors.addAll(attr.values ?? const []);
      }
    }

    return Dialog(
      backgroundColor: AdminColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 780),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AdminColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AdminColors.sageSoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Iconsax.video_play,
                      color: AdminColors.forest,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              p.title,
                              softWrap: true,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AdminColors.ink,
                              ),
                            ),
                            AdminBadge(
                              label: c.localizeCategory(p.categoryName),
                              color: AdminColors.forest,
                              bgColor: AdminColors.sageSoft,
                            ),
                            AdminBadge(
                              label: p.isFeatured == true
                                  ? '★ Đang ghim trên Nổi bật'
                                  : 'Kho sản phẩm',
                              color: p.isFeatured == true
                                  ? AdminColors.amber
                                  : AdminColors.inkSecondary,
                              bgColor: p.isFeatured == true
                                  ? AdminColors.amberBg
                                  : AdminColors.surfaceMuted,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.videoComment != null
                              ? 'Đang xem Video & Đôi giày từ bình luận của khách hàng ${widget.videoComment!.authorName}'
                              : widget.reviewRecord != null
                                  ? 'Đang xem Đôi giày & Media đánh giá ${widget.reviewRecord!.review.rating}★ của ${widget.reviewRecord!.review.authorName}'
                                  : 'Xem trực tiếp Video quảng cáo (.mp4), hình ảnh & thông số đôi giày',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AdminColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            // Body: 2 columns (Left: Video/Image Player, Right: Shoe Specs & Comment/Review Reply)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT COLUMN: Video & Image Studio Viewer
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A1E17),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AdminColors.border),
                              ),
                              child: activeSlot == null
                                  ? const Center(
                                      child: Text(
                                        'Không có media',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    )
                                  : activeSlot.isVideo
                                      ? _buildVideoPlayerArea(activeSlot)
                                      : _buildImagePreviewArea(activeSlot.url),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Media slot switcher pills (Wrap so no text or chip is ever clipped!)
                          if (_mediaSlots.length > 1)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(_mediaSlots.length, (i) {
                                final slot = _mediaSlots[i];
                                final selected = i == _selectedIndex;
                                final activeBg = slot.isCustomerMedia
                                    ? AdminColors.violet
                                    : AdminColors.forest;
                                final idleBg = slot.isCustomerMedia
                                    ? AdminColors.violetBg
                                    : AdminColors.surfaceMuted;
                                final idleFg = slot.isCustomerMedia
                                    ? AdminColors.violet
                                    : AdminColors.ink;
                                return InkWell(
                                  onTap: () => _activateSlot(i),
                                  borderRadius: BorderRadius.circular(10),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected ? activeBg : idleBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: selected
                                            ? activeBg
                                            : AdminColors.borderStrong,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (selected) ...[
                                          const Icon(
                                            Icons.check_rounded,
                                            size: 13,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          slot.label,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                selected ? Colors.white : idleFg,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 22),

                    // RIGHT COLUMN: Sneaker Details + Customer Comment / Review Action
                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Sneaker Overview Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AdminColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AdminColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          width: 64,
                                          height: 64,
                                          color: Colors.white,
                                          child: p.thumbnail.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: p.thumbnail,
                                                  fit: BoxFit.contain,
                                                )
                                              : const Icon(Iconsax.image),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.title,
                                              style: const TextStyle(
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w800,
                                                color: AdminColors.ink,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  c.formatMoney(effectivePrice),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                    color: AdminColors.forest,
                                                  ),
                                                ),
                                                if (p.salePrice > 0 &&
                                                    p.salePrice < p.price) ...[
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    c.formatMoney(p.price),
                                                    style: const TextStyle(
                                                      fontSize: 12.5,
                                                      color:
                                                          AdminColors.inkMuted,
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(width: 12),
                                                AdminBadge(
                                                  label:
                                                      'Tồn kho: ${p.stock} đôi',
                                                  color: p.stock > 10
                                                      ? AdminColors.emerald
                                                      : AdminColors.amber,
                                                  bgColor: p.stock > 10
                                                      ? AdminColors.emeraldBg
                                                      : AdminColors.amberBg,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if ((p.description ?? '')
                                      .trim()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      p.description!.trim(),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AdminColors.inkSecondary,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                  if (sizes.isNotEmpty ||
                                      colors.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        if (sizes.isNotEmpty)
                                          AdminBadge(
                                            label:
                                                'Size EU: ${sizes.join(", ")}',
                                            color: AdminColors.sky,
                                            bgColor: AdminColors.skyBg,
                                          ),
                                        if (colors.isNotEmpty)
                                          AdminBadge(
                                            label:
                                                'Phối màu: ${colors.join(", ")}',
                                            color: AdminColors.violet,
                                            bgColor: AdminColors.violetBg,
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 2. If opened from a Video Comment
                            if (widget.videoComment != null)
                              _buildVideoCommentContextSection(
                                  widget.videoComment!),

                            // 3. If opened from a Product Review
                            if (widget.reviewRecord != null)
                              _buildReviewContextSection(widget.reviewRecord!),

                            // 4. If opened from a Customer Like / Interest row
                            if (widget.customerActionSummary != null &&
                                widget.videoComment == null &&
                                widget.reviewRecord == null)
                              _buildCustomerLikeContextSection(
                                  widget.customerActionSummary!),

                            // 5. If opened directly on a Product, show its recent Video Comments & Reviews
                            if (widget.videoComment == null &&
                                widget.reviewRecord == null) ...[
                              const SizedBox(height: 14),
                              _buildProductActivitySummarySection(p),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayerArea(_MediaSlot slot) {
    if (_videoError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.video_slash, color: Colors.white54, size: 38),
              const SizedBox(height: 10),
              Text(
                'Đang hiển thị ảnh sản phẩm (Video: ${slot.url})',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              if (widget.product.thumbnail.isNotEmpty)
                SizedBox(
                  height: 180,
                  child: CachedNetworkImage(
                    imageUrl: widget.product.thumbnail,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (!_videoReady || _videoCtrl == null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (widget.product.thumbnail.isNotEmpty)
            Center(
              child: Opacity(
                opacity: 0.45,
                child: CachedNetworkImage(
                  imageUrl: widget.product.thumbnail,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AdminColors.sage),
                SizedBox(height: 12),
                Text(
                  'Đang tải video...',
                  style: TextStyle(color: Colors.white, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final ctrl = _videoCtrl!;
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio:
                ctrl.value.aspectRatio > 0 ? ctrl.value.aspectRatio : (9 / 16),
            child: VideoPlayer(ctrl),
          ),
        ),
        // Top label badge
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              slot.label,
              style: const TextStyle(
                color: AdminColors.sage,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        // Bottom controls bar
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() {
                      if (ctrl.value.isPlaying) {
                        ctrl.pause();
                      } else {
                        ctrl.play();
                      }
                    });
                  },
                  icon: Icon(
                    ctrl.value.isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                Expanded(
                  child: VideoSeekBar(controller: ctrl),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() {
                      _videoMuted = !_videoMuted;
                      ctrl.setVolume(_videoMuted ? 0 : 1);
                    });
                  },
                  icon: Icon(
                    _videoMuted ? Iconsax.volume_cross : Iconsax.volume_high,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreviewArea(String imageUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => const Icon(
                  Iconsax.image,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCommentContextSection(AdminVideoCommentRecord cm) {
    final c = widget.controller;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.message_text_1,
                  size: 18, color: AdminColors.forest),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bình luận của ${cm.authorName} trên video này',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.ink,
                  ),
                ),
              ),
              if (cm.createdAt != null)
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(cm.createdAt!),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AdminColors.inkMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdminColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '"${cm.text}"',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AdminColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phản hồi của Admin VELORA:',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              TextButton.icon(
                onPressed: () {
                  _replyCtrl.text =
                      c.automation.value.renderVideoCommentReply(
                    authorName: cm.authorName,
                    productTitle: widget.product.title,
                    categoryName: widget.product.categoryName,
                  );
                },
                icon: const Icon(Iconsax.magicpen, size: 14),
                label: const Text(
                  'Điền mẫu tự động',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          TextField(
            controller: _replyCtrl,
            maxLines: 3,
            decoration: adminInputDecoration(
              label: 'Nội dung trả lời bình luận video',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AdminPrimaryButton(
                label: 'Gửi phản hồi bình luận',
                icon: Iconsax.send_1,
                loading: _sendingReply,
                onPressed: () async {
                  if (_replyCtrl.text.trim().isEmpty) return;
                  setState(() => _sendingReply = true);
                  final ok = await c.replyToVideoComment(
                    cm,
                    _replyCtrl.text.trim(),
                  );
                  if (!mounted) return;
                  setState(() => _sendingReply = false);
                  if (ok) Navigator.of(context).pop();
                },
              ),
              if (widget.onOpenPushSimilar != null)
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onOpenPushSimilar!();
                  },
                  icon: const Icon(Iconsax.send_2, size: 15),
                  label: const Text('🎯 Tung sản phẩm tương tự cho khách này'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewContextSection(AdminReviewRecord rec) {
    final c = widget.controller;
    final r = rec.review;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Đánh giá của ${r.authorName}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AdminColors.ink,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < r.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AdminColors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdminColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '"${r.text}"',
              style: const TextStyle(
                fontSize: 13.5,
                color: AdminColors.ink,
              ),
            ),
          ),
          if (r.hasMedia) ...[
            const SizedBox(height: 10),
            const Text(
              'Bấm vào ảnh / video khách đính kèm ở thanh bên trái để phóng to hoặc phát trực tiếp.',
              style: TextStyle(
                fontSize: 11.5,
                color: AdminColors.violet,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phản hồi đánh giá từ VELORA:',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              TextButton.icon(
                onPressed: () {
                  _replyCtrl.text = c.automation.value.renderAutoReply(
                    authorName: r.authorName,
                    productTitle: widget.product.title,
                    rating: r.rating,
                  );
                },
                icon: const Icon(Iconsax.magicpen, size: 14),
                label: Text(
                  'Điền mẫu tự động (${r.rating}★)',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          TextField(
            controller: _replyCtrl,
            maxLines: 3,
            decoration: adminInputDecoration(
              label: 'Nội dung phản hồi đánh giá',
            ),
          ),
          const SizedBox(height: 12),
          AdminPrimaryButton(
            label: 'Lưu & Gửi phản hồi đánh giá',
            icon: Iconsax.send_2,
            loading: _sendingReply,
            onPressed: () async {
              if (_replyCtrl.text.trim().isEmpty) return;
              setState(() => _sendingReply = true);
              final ok = await c.replyToReview(rec, _replyCtrl.text.trim());
              if (!mounted) return;
              setState(() => _sendingReply = false);
              if (ok) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerLikeContextSection(String summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.roseBg.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.rose.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite_rounded, color: AdminColors.rose, size: 18),
              SizedBox(width: 8),
              Text(
                'Hoạt động tương tác của khách hàng',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AdminColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: const TextStyle(
              fontSize: 13,
              color: AdminColors.ink,
            ),
          ),
          if (widget.onOpenPushSimilar != null) ...[
            const SizedBox(height: 12),
            AdminPrimaryButton(
              label: '🎯 Chọn & Tung sản phẩm tương tự cho khách này',
              icon: Iconsax.send_2,
              onPressed: () {
                Navigator.of(context).pop();
                widget.onOpenPushSimilar!();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductActivitySummarySection(ProductModel p) {
    final c = widget.controller;
    final pComments =
        c.videoComments.where((cm) => cm.productId == p.id).toList();
    final pReviews = c.reviews.where((r) => r.productId == p.id).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.video_play,
                  size: 17, color: AdminColors.forest),
              const SizedBox(width: 8),
              Text(
                'Tương tác trên Video & Đánh giá (${pComments.length} bình luận • ${pReviews.length} đánh giá)',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AdminColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (pComments.isEmpty && pReviews.isEmpty)
            const Text(
              'Sản phẩm này hiện có video quảng cáo sẵn sàng trên tab Nổi bật. Khi khách thả tim, bình luận hoặc đánh giá, nội dung sẽ hiển thị tại đây.',
              style: TextStyle(
                fontSize: 12.5,
                color: AdminColors.inkSecondary,
                height: 1.4,
              ),
            )
          else ...[
            for (final cm in pComments.take(3))
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AdminColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '💬 ${cm.authorName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        AdminBadge(
                          label:
                              cm.hasAdminReply ? '✓ Đã trả lời' : 'Chờ trả lời',
                          color: cm.hasAdminReply
                              ? AdminColors.emerald
                              : AdminColors.amber,
                          bgColor: cm.hasAdminReply
                              ? AdminColors.emeraldBg
                              : AdminColors.amberBg,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${cm.text}"',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            for (final rv in pReviews.take(3))
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AdminColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '⭐ ${rv.review.authorName} (${rv.review.rating}★)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        AdminBadge(
                          label: rv.review.hasAdminReply
                              ? '✓ Đã phản hồi'
                              : 'Chờ phản hồi',
                          color: rv.review.hasAdminReply
                              ? AdminColors.emerald
                              : AdminColors.amber,
                          bgColor: rv.review.hasAdminReply
                              ? AdminColors.emeraldBg
                              : AdminColors.amberBg,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${rv.review.text}"',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
