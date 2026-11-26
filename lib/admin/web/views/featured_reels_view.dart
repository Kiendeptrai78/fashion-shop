import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/data/admin_web_models.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:fashion_business_app/admin/web/widgets/admin_product_video_preview_dialog.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/screens/reels/velora_review_video_catalog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class AdminFeaturedReelsView extends StatefulWidget {
  const AdminFeaturedReelsView({super.key, required this.controller});

  final AdminWebController controller;

  @override
  State<AdminFeaturedReelsView> createState() => _AdminFeaturedReelsViewState();
}

class _AdminFeaturedReelsViewState extends State<AdminFeaturedReelsView> {
  int _activeTab = 0; // 0: Sản phẩm & Video Nổi bật | 1: Bình luận Video | 2: Khách Thả tim & Tung giày tương tự
  String _search = '';
  bool _onlyFeatured = true;
  String _commentFilter = 'all'; // 'all' | 'pending' | 'replied'

  AdminWebController get c => widget.controller;

  List<({String label, String url})> get _studioPresetVideos =>
      VeloraReviewVideoCatalog.adminPresetVideos;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final allProducts = c.products.toList();
      final featuredProducts =
          allProducts.where((p) => p.isFeatured == true).toList();
      final totalVideosCount = allProducts.fold<int>(
        0,
        (sum, p) => sum + (p.videos?.length ?? 0),
      );
      final allComments = c.videoComments.toList();
      final pendingComments =
          allComments.where((cm) => !cm.hasAdminReply).length;
      final videoInterests = c.userInterests.toList();
      final autoCfg = c.automation.value;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSectionToolbar(
              title: c.tr('Video Nổi bật', 'Featured Videos'),
              actions: [
                _SecondaryBtn(
                  label: c.tr('Mẫu tự động', 'Auto Config'),
                  icon: Iconsax.setting_2,
                  onPressed: () => _openAutomationTemplatesModal(context),
                ),
                _SecondaryBtn(
                  label: c.tr('Trả lời tự động', 'Auto Reply'),
                  icon: Iconsax.tick_circle,
                  onPressed: () async {
                    await c.autoReplyAllUnrepliedVideoComments();
                    await c.autoPushSimilarProductsForAllVideoInteractions();
                  },
                ),
                AdminPrimaryButton(
                  label: c.tr('Gắn video', 'Add Video'),
                  icon: Iconsax.video_add,
                  onPressed: () => _openAssignVideoModal(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // KPI summary row
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth >= 1050
                    ? 4
                    : (constraints.maxWidth >= 640 ? 2 : 1);
                return GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 2.35,
                  children: [
                    AdminStatCard(
                      title: 'Đang ghim',
                      value: '${featuredProducts.length} mẫu',
                      subtitle: 'Tổng ${allProducts.length} sản phẩm',
                      icon: Iconsax.video_square,
                      accentColor: AdminColors.forest,
                      accentBg: AdminColors.sageSoft,
                    ),
                    AdminStatCard(
                      title: 'Tổng video',
                      value: '$totalVideosCount video',
                      subtitle: autoCfg.autoVideoCommentReply
                          ? 'Tự động trả lời: Bật'
                          : 'Tự động trả lời: Tắt',
                      icon: Iconsax.video_play,
                      accentColor: AdminColors.sky,
                      accentBg: AdminColors.skyBg,
                    ),
                    AdminStatCard(
                      title: 'Bình luận',
                      value: '${allComments.length}',
                      subtitle: pendingComments > 0
                          ? '$pendingComments chờ trả lời'
                          : 'Đã trả lời hết',
                      icon: Iconsax.message_text_1,
                      accentColor: AdminColors.amber,
                      accentBg: AdminColors.amberBg,
                    ),
                    AdminStatCard(
                      title: 'Lượt quan tâm',
                      value: '${videoInterests.length} khách',
                      subtitle: autoCfg.autoVideoSimilarPush
                          ? 'Gợi ý tự động: Bật'
                          : 'Gợi ý tự động: Tắt',
                      icon: Iconsax.heart,
                      accentColor: AdminColors.rose,
                      accentBg: AdminColors.roseBg,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Colorless underline sub-tab bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _SubTabButton(
                      label: 'Video đang ghim (${featuredProducts.length})',
                      selected: _activeTab == 0,
                      onTap: () => setState(() => _activeTab = 0),
                    ),
                    _SubTabButton(
                      label: 'Bình luận (${allComments.length})',
                      badge:
                          pendingComments > 0 ? '$pendingComments' : null,
                      selected: _activeTab == 1,
                      onTap: () => setState(() => _activeTab = 1),
                    ),
                    _SubTabButton(
                      label: 'Khách quan tâm (${videoInterests.length})',
                      selected: _activeTab == 2,
                      onTap: () => setState(() => _activeTab = 2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_activeTab == 0) _buildFeaturedProductsTab(allProducts),
            if (_activeTab == 1) _buildVideoCommentsTab(allComments),
            if (_activeTab == 2)
              _buildInterestedUsersTab(videoInterests, allComments, allProducts),
          ],
        ),
      );
    });
  }

  // ===========================================================================
  // TAB 0: SẢN PHẨM & VIDEO QUẢNG CÁO TRÊN TAB NỔI BẬT
  // ===========================================================================
  Widget _buildFeaturedProductsTab(List<ProductModel> allProducts) {
    final q = _search.trim().toLowerCase();
    final filtered = allProducts.where((p) {
      if (_onlyFeatured && p.isFeatured != true) return false;
      if (q.isEmpty) return true;
      return p.title.toLowerCase().contains(q) ||
          p.categoryName.toLowerCase().contains(q) ||
          p.id.toLowerCase().contains(q);
    }).toList();

    return AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                AdminSearchField(
                  width: 340,
                  hint: 'Tìm theo tên giày hoặc danh mục...',
                  onChanged: (v) => setState(() => _search = v),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(
                        'Đang ghim trên Nổi bật (${allProducts.where((p) => p.isFeatured == true).length})',
                      ),
                      selected: _onlyFeatured,
                      onSelected: (_) => setState(() => _onlyFeatured = true),
                    ),
                    ChoiceChip(
                      label: Text(
                        'Tất cả kho sản phẩm (${allProducts.length})',
                      ),
                      selected: !_onlyFeatured,
                      onSelected: (_) => setState(() => _onlyFeatured = false),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AdminColors.border),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(36),
              child: AdminEmptyState(
                icon: Iconsax.video_slash,
                title: 'Không tìm thấy sản phẩm phù hợp',
                subtitle:
                    'Nhấn "+ Thêm Video cho Sản phẩm" để chọn sản phẩm và gắn video quảng cáo lên tab Nổi bật.',
                action: AdminPrimaryButton(
                  label: '+ Thêm Video cho Sản phẩm',
                  icon: Iconsax.video_add,
                  onPressed: () => _openAssignVideoModal(context),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.take(40).length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AdminColors.border),
              itemBuilder: (context, index) {
                final p = filtered[index];
                final videos = p.videos ?? const <String>[];
                final isFeat = p.isFeatured == true;
                final commentCount = c.videoComments
                    .where((cm) => cm.productId == p.id)
                    .length;

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => showAdminProductAndVideoPreviewDialog(
                          context,
                          controller: c,
                          product: p,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 54,
                                height: 54,
                                color: AdminColors.surfaceMuted,
                                child: p.thumbnail.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: p.thumbnail,
                                        fit: BoxFit.contain,
                                      )
                                    : const Icon(Iconsax.image,
                                        color: AdminColors.inkMuted),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 3,
                        child: InkWell(
                          onTap: () => showAdminProductAndVideoPreviewDialog(
                            context,
                            controller: c,
                            product: p,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      p.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AdminColors.ink,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AdminBadge(
                                    label: c.localizeCategory(p.categoryName),
                                    color: AdminColors.forest,
                                    bgColor: AdminColors.sageSoft,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Giá bán: ${c.formatMoney(p.salePrice > 0 ? p.salePrice : p.price)} • Tồn kho: ${p.stock} đôi • 💬 $commentCount bình luận video',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AdminColors.inkSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            InkWell(
                              onTap: () => showAdminProductAndVideoPreviewDialog(
                                context,
                                controller: c,
                                product: p,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: videos.isNotEmpty
                                      ? AdminColors.skyBg
                                      : AdminColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: videos.isNotEmpty
                                        ? AdminColors.sky.withValues(alpha: 0.35)
                                        : AdminColors.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.play_circle_fill_rounded,
                                      size: 15,
                                      color: videos.isNotEmpty
                                          ? AdminColors.sky
                                          : AdminColors.inkMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '▶️ Xem ${videos.length} video & giày',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: videos.isNotEmpty
                                            ? AdminColors.sky
                                            : AdminColors.inkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Switch hiển thị trên tab Nổi bật
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: isFeat,
                            activeTrackColor: AdminColors.forest,
                            onChanged: (val) =>
                                c.toggleProductFeatured(p, val),
                          ),
                          Text(
                            isFeat ? 'Đang Nổi bật' : 'Ẩn khỏi feed chung',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isFeat
                                  ? AdminColors.forest
                                  : AdminColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      _SecondaryBtn(
                        label: '+ Thêm / Sửa Video',
                        icon: Iconsax.video_add,
                        onPressed: () =>
                            _openAssignVideoModal(context, initialProduct: p),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: QUẢN LÝ & TRẢ LỜI BÌNH LUẬN VIDEO (TỰ ĐỘNG + NHẬP TAY)
  // ===========================================================================
  Widget _buildVideoCommentsTab(List<AdminVideoCommentRecord> allComments) {
    final filtered = allComments.where((cm) {
      if (_commentFilter == 'pending' && cm.hasAdminReply) return false;
      if (_commentFilter == 'replied' && !cm.hasAdminReply) return false;
      return true;
    }).toList();

    return AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text('Tất cả (${allComments.length})'),
                      selected: _commentFilter == 'all',
                      onSelected: (_) =>
                          setState(() => _commentFilter = 'all'),
                    ),
                    ChoiceChip(
                      label: Text(
                        'Chờ trả lời (${allComments.where((e) => !e.hasAdminReply).length})',
                      ),
                      selected: _commentFilter == 'pending',
                      onSelected: (_) =>
                          setState(() => _commentFilter = 'pending'),
                    ),
                    ChoiceChip(
                      label: Text(
                        'Đã phản hồi (${allComments.where((e) => e.hasAdminReply).length})',
                      ),
                      selected: _commentFilter == 'replied',
                      onSelected: (_) =>
                          setState(() => _commentFilter = 'replied'),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  children: [
                    _SecondaryBtn(
                      label: 'Chỉnh sửa mẫu trả lời tự động',
                      icon: Iconsax.edit_2,
                      onPressed: () => _openAutomationTemplatesModal(context),
                    ),
                    AdminPrimaryButton(
                      label: '⚡ Tự động trả lời tất cả bình luận chờ',
                      icon: Iconsax.flash_1,
                      onPressed: c.autoReplyAllUnrepliedVideoComments,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AdminColors.border),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(36),
              child: AdminEmptyState(
                icon: Iconsax.message_text,
                title: 'Chưa có bình luận video nào trong bộ lọc này',
                subtitle:
                    'Khi khách hàng bình luận trên tab Nổi bật của ứng dụng, bình luận sẽ đồng bộ tức thì tại đây để tự động hoặc tự nhập phản hồi.',
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AdminColors.border),
              itemBuilder: (context, index) {
                final cm = filtered[index];
                final watchedProduct = c.products
                    .firstWhereOrNull((p) => p.id == cm.productId);

                void openPreview() {
                  if (watchedProduct == null) return;
                  showAdminProductAndVideoPreviewDialog(
                    context,
                    controller: c,
                    product: watchedProduct,
                    initialVideoUrl: cm.videoUrl,
                    videoComment: cm,
                    onOpenPushSimilar: cm.userId.isNotEmpty
                        ? () => _openPushSimilarProductsModal(
                              context,
                              userId: cm.userId,
                              userName: cm.authorName,
                              watchedProduct: watchedProduct,
                            )
                        : null,
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Clickable Shoe & Video Thumbnail with Play badge
                          InkWell(
                            onTap: openPreview,
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    color: AdminColors.surfaceMuted,
                                    child: (watchedProduct?.thumbnail ??
                                                cm.productThumbnail)
                                            .isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl:
                                                watchedProduct?.thumbnail ??
                                                    cm.productThumbnail,
                                            fit: BoxFit.contain,
                                          )
                                        : const Icon(Iconsax.video_play,
                                            color: AdminColors.forest),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.62),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: AdminColors.sage,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: InkWell(
                              onTap: openPreview,
                              borderRadius: BorderRadius.circular(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        cm.authorName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                          color: AdminColors.ink,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      AdminBadge(
                                        label: cm.hasAdminReply
                                            ? '✓ Đã phản hồi'
                                            : '⏳ Chờ phản hồi',
                                        color: cm.hasAdminReply
                                            ? AdminColors.emerald
                                            : AdminColors.amber,
                                        bgColor: cm.hasAdminReply
                                            ? AdminColors.emeraldBg
                                            : AdminColors.amberBg,
                                      ),
                                      const SizedBox(width: 8),
                                      if (cm.createdAt != null)
                                        Text(
                                          DateFormat('dd/MM/yyyy HH:mm')
                                              .format(cm.createdAt!),
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AdminColors.inkMuted,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 9, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AdminColors.skyBg,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.play_circle_fill_rounded,
                                              size: 13,
                                              color: AdminColors.sky,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              'Bấm xem Video & Giày: ${cm.productTitle}',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                color: AdminColors.sky,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        'Danh mục: ${c.localizeCategory(cm.categoryName)}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AdminColors.inkSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (watchedProduct != null)
                                        Text(
                                          '• Giá: ${c.formatMoney(watchedProduct.salePrice > 0 ? watchedProduct.salePrice : watchedProduct.price)}',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AdminColors.forest,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (watchedProduct != null)
                                _SecondaryBtn(
                                  label: '▶️ Xem Video & Đôi giày',
                                  icon: Iconsax.video_play,
                                  onPressed: openPreview,
                                ),
                              _SecondaryBtn(
                                label: '⚡ Trả lời tự động',
                                icon: Iconsax.flash_1,
                                onPressed: () =>
                                    c.autoReplySingleVideoComment(cm),
                              ),
                              _SecondaryBtn(
                                label: cm.hasAdminReply
                                    ? 'Sửa phản hồi'
                                    : '✍️ Nhập tay',
                                icon: Iconsax.edit,
                                onPressed: () =>
                                    _openManualCommentReplyModal(context, cm),
                              ),
                              if (watchedProduct != null &&
                                  cm.userId.isNotEmpty)
                                AdminPrimaryButton(
                                  label: '🎯 Tung giày tương tự',
                                  icon: Iconsax.send_2,
                                  onPressed: () =>
                                      _openPushSimilarProductsModal(
                                    context,
                                    userId: cm.userId,
                                    userName: cm.authorName,
                                    watchedProduct: watchedProduct,
                                  ),
                                ),
                            ],
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
                            fontSize: 13,
                            color: AdminColors.ink,
                          ),
                        ),
                      ),
                      if (cm.hasAdminReply) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AdminColors.sageSoft,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AdminColors.forest.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: AdminColors.forest,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Phản hồi của VELORA: ${cm.adminReply}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AdminColors.forestDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: KHÁCH THẢ TIM / QUAN TÂM VIDEO & TUNG SẢN PHẨM TƯƠNG TỰ
  // ===========================================================================
  Widget _buildInterestedUsersTab(
    List<AdminUserInterest> interests,
    List<AdminVideoCommentRecord> comments,
    List<ProductModel> allProducts,
  ) {
    final rows = <({
      String userId,
      String userName,
      String userEmail,
      String actionSummary,
      ProductModel watchedProduct,
      DateTime? updatedAt,
    })>[];
    final seenUsers = <String>{};

    for (final it in interests) {
      if (it.userId.isEmpty) continue;
      ProductModel? watched;
      if (it.lastProductId.isNotEmpty) {
        watched = allProducts.firstWhereOrNull((p) => p.id == it.lastProductId);
      }
      if (watched == null && it.interestedCategoryIds.isNotEmpty) {
        final cid = it.interestedCategoryIds.first;
        watched = allProducts.firstWhereOrNull((p) => p.categoryId == cid);
      }
      watched ??= allProducts.firstOrNull;
      if (watched == null) continue;
      seenUsers.add(it.userId);
      rows.add((
        userId: it.userId,
        userName: it.userName,
        userEmail: it.userEmail,
        actionSummary: it.lastQuery.isNotEmpty
            ? it.lastQuery
            : '❤️ Thả tim & xem video ${watched.title}',
        watchedProduct: watched,
        updatedAt: it.updatedAt,
      ));
    }

    for (final cm in comments) {
      if (cm.userId.isEmpty || seenUsers.contains(cm.userId)) continue;
      final watched =
          allProducts.firstWhereOrNull((p) => p.id == cm.productId) ??
              allProducts.firstOrNull;
      if (watched == null) continue;
      seenUsers.add(cm.userId);
      rows.add((
        userId: cm.userId,
        userName: cm.authorName,
        userEmail: '',
        actionSummary: '💬 Bình luận video ${watched.title}: "${cm.text}"',
        watchedProduct: watched,
        updatedAt: cm.createdAt,
      ));
    }

    return AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Danh sách Khách Thả tim (❤️) & Bình luận (💬) trên tab Nổi bật',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.ink,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Bấm "⚡ Auto đẩy 3 giày tương tự" hoặc "🎯 Tự chọn nhiều sản phẩm tương tự" để mở khóa riêng trên tab Nổi bật của khách đó.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AdminColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  children: [
                    _SecondaryBtn(
                      label: 'Chỉnh sửa mẫu thông báo tự động',
                      icon: Iconsax.edit_2,
                      onPressed: () => _openAutomationTemplatesModal(context),
                    ),
                    AdminPrimaryButton(
                      label:
                          '⚡ Auto đẩy giày tương tự cho tất cả (${rows.length})',
                      icon: Iconsax.flash_1,
                      onPressed:
                          c.autoPushSimilarProductsForAllVideoInteractions,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AdminColors.border),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(36),
              child: AdminEmptyState(
                icon: Iconsax.heart,
                title: 'Chưa ghi nhận khách thả tim hoặc bình luận video',
                subtitle:
                    'Ngay khi khách hàng thả tim hoặc bình luận video trên ứng dụng, hồ sơ tương tác sẽ hiện tại đây để tự động hoặc thủ công tung sản phẩm tương tự.',
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AdminColors.border),
              itemBuilder: (context, index) {
                final row = rows[index];
                final autoSimilars =
                    c.similarProductsFor(row.watchedProduct, limit: 3);
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: AdminColors.roseBg,
                        child: Icon(
                          Icons.favorite_rounded,
                          color: AdminColors.rose,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  row.userName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AdminColors.ink,
                                  ),
                                ),
                                if (row.userEmail.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${row.userEmail})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AdminColors.inkSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                AdminBadge(
                                  label:
                                      'Quan tâm: ${c.localizeCategory(row.watchedProduct.categoryName)}',
                                  color: AdminColors.forest,
                                  bgColor: AdminColors.sageSoft,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              row.actionSummary,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AdminColors.inkSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Đề xuất tự động cùng dòng:',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AdminColors.inkMuted,
                                  ),
                                ),
                                for (final sim in autoSimilars)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AdminColors.sageSoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      sim.title,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AdminColors.forest,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SecondaryBtn(
                            label: '▶️ Xem Video & Đôi giày',
                            icon: Iconsax.video_play,
                            onPressed: () =>
                                showAdminProductAndVideoPreviewDialog(
                              context,
                              controller: c,
                              product: row.watchedProduct,
                              customerActionSummary: row.actionSummary,
                              onOpenPushSimilar: () =>
                                  _openPushSimilarProductsModal(
                                context,
                                userId: row.userId,
                                userName: row.userName,
                                watchedProduct: row.watchedProduct,
                              ),
                            ),
                          ),
                          _SecondaryBtn(
                            label: '⚡ Auto đẩy 3 giày tương tự',
                            icon: Iconsax.flash_1,
                            onPressed: () => c.pushSimilarProductsToUser(
                              userId: row.userId,
                              userName: row.userName,
                              watchedProduct: row.watchedProduct,
                              similarProducts: autoSimilars,
                            ),
                          ),
                          AdminPrimaryButton(
                            label: '🎯 Tự chọn nhiều sản phẩm tương tự',
                            icon: Iconsax.send_2,
                            onPressed: () => _openPushSimilarProductsModal(
                              context,
                              userId: row.userId,
                              userName: row.userName,
                              watchedProduct: row.watchedProduct,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MODAL 1: THÊM / GẮN VIDEO QUẢNG CÁO CHO SẢN PHẨM TRÊN TAB NỔI BẬT
  // ===========================================================================
  Future<void> _openAssignVideoModal(
    BuildContext context, {
    ProductModel? initialProduct,
  }) async {
    ProductModel? selectedProduct =
        initialProduct ?? c.products.firstOrNull;
    final videoUrls = <String>[
      ...(selectedProduct?.videos ?? const <String>[]),
    ];
    bool makeFeatured = selectedProduct?.isFeatured ?? true;
    String productSearch = '';
    bool uploading = false;
    final urlCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final matchingProducts = c.products.where((p) {
            final q = productSearch.trim().toLowerCase();
            if (q.isEmpty) return true;
            return p.title.toLowerCase().contains(q) ||
                p.categoryName.toLowerCase().contains(q);
          }).take(30).toList();

          return Dialog(
            backgroundColor: AdminColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Thêm Video Quảng cáo cho Sản phẩm trên tab Nổi bật',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: AdminColors.ink,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '1. Tìm & Chọn Sản phẩm cần gắn video quảng cáo',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AdminColors.ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              onChanged: (v) =>
                                  setModalState(() => productSearch = v),
                              decoration: InputDecoration(
                                hintText:
                                    'Gõ tên giày để tìm nhanh trong 105 sản phẩm (VD: AeroPulse, CloudPace...)...',
                                prefixIcon:
                                    const Icon(Iconsax.search_normal, size: 17),
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 150),
                              decoration: BoxDecoration(
                                border: Border.all(color: AdminColors.border),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: matchingProducts.length,
                                itemBuilder: (_, i) {
                                  final item = matchingProducts[i];
                                  final isSel = selectedProduct?.id == item.id;
                                  return ListTile(
                                    dense: true,
                                    selected: isSel,
                                    selectedTileColor: AdminColors.sageSoft,
                                    title: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontWeight: isSel
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${c.localizeCategory(item.categoryName)} • Hiện có ${item.videos?.length ?? 0} video',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    trailing: isSel
                                        ? const Icon(Icons.check_circle_rounded,
                                            color: AdminColors.forest, size: 18)
                                        : null,
                                    onTap: () {
                                      setModalState(() {
                                        selectedProduct = item;
                                        videoUrls
                                          ..clear()
                                          ..addAll(
                                              item.videos ?? const <String>[]);
                                        makeFeatured = item.isFeatured ?? true;
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: makeFeatured,
                              activeTrackColor: AdminColors.forest,
                              onChanged: (v) =>
                                  setModalState(() => makeFeatured = v),
                              title: const Text(
                                'Hiển thị sản phẩm này trên tab Nổi bật (Featured Feed)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: const Text(
                                'Bật để khách hàng lướt thấy ngay trên tab Nổi bật; tắt nếu chỉ muốn mở khóa khi khách quan tâm mẫu tương tự.',
                                style: TextStyle(fontSize: 11.5),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '2. Danh sách Video Quảng cáo (${videoUrls.length} video)',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AdminColors.ink,
                                  ),
                                ),
                                _SecondaryBtn(
                                  label: uploading
                                      ? 'Đang tải lên...'
                                      : 'Tải nhiều file .MP4 từ máy',
                                  icon: Iconsax.document_upload,
                                  onPressed: uploading
                                      ? null
                                      : () async {
                                          final picked = await FilePicker
                                              .platform
                                              .pickFiles(
                                            type: FileType.video,
                                            allowMultiple: true,
                                            withData: true,
                                          );
                                          if (picked == null ||
                                              picked.files.isEmpty) {
                                            return;
                                          }
                                          setModalState(() => uploading = true);
                                          try {
                                            for (final f in picked.files) {
                                              if (f.bytes == null) continue;
                                              final uploadedUrl =
                                                  await c.uploadVideo(
                                                f.bytes!,
                                                f.name,
                                                'velora-product-videos',
                                              );
                                              if (uploadedUrl.isNotEmpty) {
                                                setModalState(() =>
                                                    videoUrls.add(uploadedUrl));
                                              }
                                            }
                                          } finally {
                                            setModalState(
                                                () => uploading = false);
                                          }
                                        },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Hoặc chọn nhanh từ kho Video Studio 9:16 VELORA:',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AdminColors.inkSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final preset in _studioPresetVideos)
                                  ActionChip(
                                    avatar: const Icon(Iconsax.video_play,
                                        size: 14, color: AdminColors.forest),
                                    label: Text(
                                      preset.label,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    onPressed: () {
                                      if (!videoUrls.contains(preset.url)) {
                                        setModalState(
                                            () => videoUrls.add(preset.url));
                                      }
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: urlCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Hoặc dán đường dẫn .mp4 URL...',
                                      isDense: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _SecondaryBtn(
                                  label: 'Thêm URL',
                                  icon: Iconsax.add,
                                  onPressed: () {
                                    final u = urlCtrl.text.trim();
                                    if (u.isNotEmpty &&
                                        !videoUrls.contains(u)) {
                                      setModalState(() {
                                        videoUrls.add(u);
                                        urlCtrl.clear();
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (videoUrls.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AdminColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Chưa có video nào được gắn. Hãy tải file .mp4 hoặc chọn từ kho Studio ở trên.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AdminColors.inkSecondary,
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: [
                                  for (int i = 0; i < videoUrls.length; i++)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AdminColors.surfaceMuted,
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Iconsax.video_circle,
                                              size: 16,
                                              color: AdminColors.forest),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Video #${i + 1}: ${videoUrls[i]}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 12),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Iconsax.trash,
                                                size: 16,
                                                color: AdminColors.rose),
                                            onPressed: () => setModalState(
                                                () => videoUrls.removeAt(i)),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          child: const Text('Hủy'),
                        ),
                        const SizedBox(width: 10),
                        AdminPrimaryButton(
                          label: 'Lưu Video & Cập nhật tab Nổi bật',
                          icon: Iconsax.tick_circle,
                          onPressed: selectedProduct == null
                              ? null
                              : () async {
                                  final ok = await c.assignVideosToProduct(
                                    product: selectedProduct!,
                                    videoUrls: videoUrls,
                                    makeFeatured: makeFeatured,
                                  );
                                  if (ok && dialogCtx.mounted) {
                                    Navigator.of(dialogCtx).pop();
                                  }
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // MODAL 2: NHẬP TAY / CHỈNH SỬA PHẢN HỒI BÌNH LUẬN VIDEO
  // ===========================================================================
  Future<void> _openManualCommentReplyModal(
    BuildContext context,
    AdminVideoCommentRecord record,
  ) async {
    final autoGenerated = c.automation.value.renderVideoCommentReply(
      authorName: record.authorName,
      productTitle: record.productTitle,
      categoryName: record.categoryName,
    );
    final replyCtrl = TextEditingController(
      text: record.hasAdminReply ? record.adminReply : autoGenerated,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trả lời bình luận video của ${record.authorName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sản phẩm: ${record.productTitle} • Bình luận: "${record.text}"',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AdminColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nội dung phản hồi (có thể sửa trực tiếp):',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => replyCtrl.text = autoGenerated,
                      icon: const Icon(Iconsax.magicpen, size: 14),
                      label: const Text(
                        'Điền mẫu tự động',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: replyCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 8),
                    AdminPrimaryButton(
                      label: 'Gửi phản hồi & Thông báo cho khách',
                      icon: Iconsax.send_1,
                      onPressed: () async {
                        if (replyCtrl.text.trim().isEmpty) return;
                        final ok = await c.replyToVideoComment(
                          record,
                          replyCtrl.text.trim(),
                        );
                        if (ok && dialogCtx.mounted) {
                          Navigator.of(dialogCtx).pop();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MODAL 3: TỰ CHỌN NHIỀU SẢN PHẨM TƯƠNG TỰ & CHỈNH SỬA LỜI NHẮN GỬI TỚI USER
  // ===========================================================================
  Future<void> _openPushSimilarProductsModal(
    BuildContext context, {
    required String userId,
    required String userName,
    required ProductModel watchedProduct,
  }) async {
    final autoDefaults = c.similarProductsFor(watchedProduct, limit: 3);
    final selectedIds = <String>{...autoDefaults.map((p) => p.id)};
    String search = '';

    String buildAutoMessage() {
      final chosen = c.products
          .where((p) => selectedIds.contains(p.id))
          .map((p) => p.title)
          .join(', ');
      return c.automation.value.renderVideoSimilarPush(
        userName: userName,
        watchedProductTitle: watchedProduct.title,
        similarProductTitles: chosen,
        categoryName: watchedProduct.categoryName,
      );
    }

    final msgCtrl = TextEditingController(text: buildAutoMessage());

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final candidates = c.products.where((p) {
            if (p.id == watchedProduct.id) return false;
            final q = search.trim().toLowerCase();
            if (q.isEmpty) return true;
            return p.title.toLowerCase().contains(q) ||
                p.categoryName.toLowerCase().contains(q);
          }).toList()
            ..sort((a, b) {
              final aSame = a.categoryId == watchedProduct.categoryId ? 0 : 1;
              final bSame = b.categoryId == watchedProduct.categoryId ? 0 : 1;
              return aSame.compareTo(bSame);
            });

          return Dialog(
            backgroundColor: AdminColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 660, maxHeight: 740),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Tung sản phẩm tương tự tới $userName',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AdminColors.ink,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    Text(
                      'Khách vừa quan tâm video: ${watchedProduct.title} (${c.localizeCategory(watchedProduct.categoryName)})',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AdminColors.forest,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (v) =>
                                setModalState(() => search = v),
                            decoration: InputDecoration(
                              hintText: 'Tìm thêm mẫu giày để gợi ý...',
                              prefixIcon:
                                  const Icon(Iconsax.search_normal, size: 16),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SecondaryBtn(
                          label: 'Chọn 3 mẫu tự động cùng dòng',
                          icon: Iconsax.magicpen,
                          onPressed: () {
                            setModalState(() {
                              selectedIds
                                ..clear()
                                ..addAll(autoDefaults.map((p) => p.id));
                              msgCtrl.text = buildAutoMessage();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AdminColors.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListView.builder(
                          itemCount: candidates.take(35).length,
                          itemBuilder: (_, i) {
                            final item = candidates[i];
                            final checked = selectedIds.contains(item.id);
                            final isSameCat =
                                item.categoryId == watchedProduct.categoryId;
                            return CheckboxListTile(
                              dense: true,
                              value: checked,
                              activeColor: AdminColors.forest,
                              title: Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                              subtitle: Text(
                                '${c.localizeCategory(item.categoryName)} • ${c.formatMoney(item.salePrice > 0 ? item.salePrice : item.price)}${isSameCat ? " • ★ Cùng dòng sản phẩm" : ""}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isSameCat
                                      ? AdminColors.forest
                                      : AdminColors.inkSecondary,
                                ),
                              ),
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true) {
                                    selectedIds.add(item.id);
                                  } else {
                                    selectedIds.remove(item.id);
                                  }
                                  msgCtrl.text = buildAutoMessage();
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lời nhắn thông báo gửi kèm (tự động điền từ mẫu, có thể sửa):',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: () => msgCtrl.text = buildAutoMessage(),
                          child: const Text(
                            'Làm mới theo mẫu tự động',
                            style: TextStyle(fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      controller: msgCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          child: const Text('Hủy'),
                        ),
                        const SizedBox(width: 8),
                        AdminPrimaryButton(
                          label:
                              'Mở khóa ${selectedIds.length} sản phẩm trên tab Nổi bật của $userName',
                          icon: Iconsax.send_2,
                          onPressed: selectedIds.isEmpty
                              ? null
                              : () async {
                                  final chosen = c.products
                                      .where((p) => selectedIds.contains(p.id))
                                      .toList();
                                  final ok = await c.pushSimilarProductsToUser(
                                    userId: userId,
                                    userName: userName,
                                    watchedProduct: watchedProduct,
                                    similarProducts: chosen,
                                    customBodyVi: msgCtrl.text.trim(),
                                  );
                                  if (ok && dialogCtx.mounted) {
                                    Navigator.of(dialogCtx).pop();
                                  }
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // MODAL 4: CHỈNH SỬA MẪU TỰ ĐỘNG (AUTO COMMENT REPLY + AUTO SIMILAR PUSH)
  // ===========================================================================
  Future<void> _openAutomationTemplatesModal(BuildContext context) async {
    final current = c.automation.value;
    bool autoReply = current.autoVideoCommentReply;
    bool autoPush = current.autoVideoSimilarPush;
    final replyTplCtrl =
        TextEditingController(text: current.templateVideoCommentReply);
    final pushTplCtrl =
        TextEditingController(text: current.templateVideoSimilarPush);
    const defaults = AdminAutomationSettings();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          backgroundColor: AdminColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Cấu hình & Chỉnh sửa Mẫu Tự động trên tab Nổi bật',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AdminColors.ink,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const Text(
                      'Bạn có thể bật/tắt tự động và tùy chỉnh nội dung mẫu tự động bất cứ lúc nào. Biến hỗ trợ: {name}, {product}, {similar}, {category}.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AdminColors.inkSecondary,
                      ),
                    ),
                    const Divider(height: 22),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: autoReply,
                      activeTrackColor: AdminColors.forest,
                      onChanged: (v) => setModalState(() => autoReply = v),
                      title: const Text(
                        '1. Tự động trả lời bình luận trên video Nổi bật',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      subtitle: const Text(
                        'Khi khách hàng bình luận video, hệ thống tự động phản hồi ngay theo mẫu dưới đây.',
                        style: TextStyle(fontSize: 11.5),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mẫu tự động trả lời bình luận ({name}, {product}, {category}):',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () => replyTplCtrl.text =
                              defaults.templateVideoCommentReply,
                          child: const Text(
                            'Khôi phục mẫu mặc định',
                            style: TextStyle(fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      controller: replyTplCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: autoPush,
                      activeTrackColor: AdminColors.forest,
                      onChanged: (v) => setModalState(() => autoPush = v),
                      title: const Text(
                        '2. Tự động mở khóa & tung nhiều sản phẩm tương tự khi khách Thả tim / Bình luận',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      subtitle: const Text(
                        'Mở khóa 3 mẫu giày cùng dòng vào tab Nổi bật của riêng khách đó và gửi thông báo gợi ý.',
                        style: TextStyle(fontSize: 11.5),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mẫu thông báo gợi ý giày tương tự ({name}, {product}, {similar}, {category}):',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () => pushTplCtrl.text =
                              defaults.templateVideoSimilarPush,
                          child: const Text(
                            'Khôi phục mẫu mặc định',
                            style: TextStyle(fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      controller: pushTplCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          child: const Text('Hủy'),
                        ),
                        const SizedBox(width: 8),
                        AdminPrimaryButton(
                          label: 'Lưu mẫu tự động',
                          icon: Iconsax.tick_circle,
                          onPressed: () async {
                            final next = c.automation.value.copyWith(
                              autoVideoCommentReply: autoReply,
                              templateVideoCommentReply:
                                  replyTplCtrl.text.trim(),
                              autoVideoSimilarPush: autoPush,
                              templateVideoSimilarPush:
                                  pushTplCtrl.text.trim(),
                            );
                            final ok = await c.saveAutomationSettings(next);
                            if (ok && dialogCtx.mounted) {
                              Navigator.of(dialogCtx).pop();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryBtn extends StatelessWidget {
  const _SecondaryBtn({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AdminColors.forest,
        side: const BorderSide(color: AdminColors.borderStrong),
        backgroundColor: AdminColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
      icon: Icon(icon, size: 15),
      label: Text(label),
    );
  }
}

class _SubTabButton extends StatelessWidget {
  const _SubTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 22),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFF111827) : Colors.transparent,
              width: 2.2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? const Color(0xFF111827)
                    : const Color(0xFF64748B),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB91C1C),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
