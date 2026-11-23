import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/data/admin_web_models.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:fashion_business_app/admin/web/widgets/admin_product_video_preview_dialog.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class AdminReviewsView extends StatefulWidget {
  const AdminReviewsView({super.key, required this.controller});

  final AdminWebController controller;

  @override
  State<AdminReviewsView> createState() => _AdminReviewsViewState();
}

class _AdminReviewsViewState extends State<AdminReviewsView> {
  String _query = '';
  int? _starFilter;
  String _productFilter = '';
  bool _onlyUnreplied = false;
  bool _bulkReplying = false;

  Future<void> _openReplyDialog(AdminReviewRecord record) async {
    final replyCtrl = TextEditingController(text: record.review.adminReply ?? '');
    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AdminColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            record.review.hasAdminReply
                ? 'Sửa phản hồi đánh giá'
                : 'Trả lời đánh giá của ${record.review.authorName}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Text(
                    '"${record.review.text}"',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: AdminColors.inkSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      final suggested = widget.controller.automation.value.renderAutoReply(
                        authorName: record.review.authorName,
                        productTitle: record.productTitle,
                        rating: record.review.rating,
                      );
                      setModalState(() => replyCtrl.text = suggested);
                    },
                    icon: const Icon(Icons.auto_awesome_rounded, size: 15),
                    label: const Text('Điền mẫu tự động theo số sao', style: TextStyle(fontSize: 12)),
                  ),
                ),
                TextField(
                  controller: replyCtrl,
                  maxLines: 4,
                  decoration: adminInputDecoration(
                    label: 'Nội dung phản hồi (Nhập tay hoặc sửa mẫu) *',
                    hint: 'Cảm ơn bạn đã tin tưởng và ủng hộ VELORA...',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Khách hàng sẽ nhận được thông báo ngay khi bạn gửi phản hồi.',
                  style: TextStyle(fontSize: 11.5, color: AdminColors.forestLight),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            OutlinedButton(
              onPressed: saving ? null : () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            AdminPrimaryButton(
              label: 'Gửi phản hồi',
              icon: Iconsax.send_2,
              loading: saving,
              onPressed: () async {
                if (replyCtrl.text.trim().isEmpty) return;
                setModalState(() => saving = true);
                final ok =
                    await widget.controller.replyToReview(record, replyCtrl.text.trim());
                if (!context.mounted) return;
                setModalState(() => saving = false);
                if (ok) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
    replyCtrl.dispose();
  }

  Future<void> _openAutoTemplatesDialog() async {
    final cfg = widget.controller.automation.value;
    final highCtrl = TextEditingController(text: cfg.replyTemplateHigh);
    final midCtrl = TextEditingController(text: cfg.replyTemplateMid);
    final lowCtrl = TextEditingController(text: cfg.replyTemplateLow);
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: AdminColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chỉnh mẫu Trả lời Đánh giá Tự động',
                    style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Biến tự động thay thế: {name} (tên khách), {product} (tên sản phẩm), {stars} (số sao).',
                    style: TextStyle(fontSize: 12, color: AdminColors.inkSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: highCtrl,
                    maxLines: 3,
                    decoration: adminInputDecoration(label: 'Mẫu cho đánh giá 4★ – 5★ (Tích cực)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: midCtrl,
                    maxLines: 3,
                    decoration: adminInputDecoration(label: 'Mẫu cho đánh giá 3★ (Trung lập)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lowCtrl,
                    maxLines: 3,
                    decoration: adminInputDecoration(label: 'Mẫu cho đánh giá 1★ – 2★ (Cần hỗ trợ)'),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: saving ? null : () => Navigator.of(context).pop(),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 10),
                      AdminPrimaryButton(
                        label: 'Lưu mẫu tự động',
                        icon: Iconsax.tick_circle,
                        loading: saving,
                        onPressed: () async {
                          setModalState(() => saving = true);
                          final ok = await widget.controller.saveAutomationSettings(
                            cfg.copyWith(
                              replyTemplateHigh: highCtrl.text.trim(),
                              replyTemplateMid: midCtrl.text.trim(),
                              replyTemplateLow: lowCtrl.text.trim(),
                            ),
                          );
                          if (!context.mounted) return;
                          setModalState(() => saving = false);
                          if (ok) Navigator.of(context).pop();
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
    );
    highCtrl.dispose();
    midCtrl.dispose();
    lowCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Obx(() {
      final all = widget.controller.reviews;
      final cfg = widget.controller.automation.value;
      final unrepliedCount = all.where((r) => !r.review.hasAdminReply).length;
      final q = _query.trim().toLowerCase();
      final filtered = all.where((r) {
        if (_starFilter != null && r.review.rating != _starFilter) return false;
        if (_productFilter.isNotEmpty && r.productId != _productFilter) return false;
        if (_onlyUnreplied && r.review.hasAdminReply) return false;
        if (q.isEmpty) return true;
        return r.review.authorName.toLowerCase().contains(q) ||
            r.review.text.toLowerCase().contains(q) ||
            r.productTitle.toLowerCase().contains(q);
      }).toList();

      final total = all.length;
      final avg = widget.controller.averageRating;

      return SingleChildScrollView(
        padding: EdgeInsets.all(width < 700 ? 16 : 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSectionToolbar(
                  title: 'Quản lý Đánh giá sản phẩm ($total)',
                  subtitle:
                      'Hỗ trợ cả Trả lời Tự động theo số sao và Nhập tay chi tiết — tự động đẩy thông báo cho khách.',
                  actions: [
                    OutlinedButton.icon(
                      onPressed: _openAutoTemplatesDialog,
                      icon: const Icon(Iconsax.setting_2, size: 17),
                      label: const Text('Mẫu trả lời tự động'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminColors.forest,
                        side: const BorderSide(color: AdminColors.borderStrong),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                      ),
                    ),
                    AdminPrimaryButton(
                      label: 'Trả lời tự động tất cả ($unrepliedCount)',
                      icon: Icons.auto_awesome_rounded,
                      loading: _bulkReplying,
                      onPressed: unrepliedCount == 0
                          ? null
                          : () async {
                              final ok = await showAdminConfirmDialog(
                                context,
                                title: 'Tự động trả lời $unrepliedCount đánh giá?',
                                message:
                                    'Hệ thống sẽ dùng đúng mẫu theo số sao (4-5★, 3★, 1-2★) để phản hồi toàn bộ đánh giá chưa trả lời và gửi thông báo tới khách hàng.',
                                confirmLabel: 'Chạy tự động ngay',
                                destructive: false,
                              );
                              if (!ok) return;
                              setState(() => _bulkReplying = true);
                              await widget.controller.autoReplyAllUnrepliedReviews();
                              if (mounted) setState(() => _bulkReplying = false);
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Auto-reply status bar
                AdminCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AdminColors.sageSoft,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: AdminColors.forest, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chế độ Trả lời Tự động + Thủ công',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            Text(
                              unrepliedCount == 0
                                  ? 'Tuyệt vời! Toàn bộ đánh giá đều đã được phản hồi.'
                                  : 'Còn $unrepliedCount đánh giá chưa phản hồi — bạn có thể bấm "Trả lời tự động" 1 chạm hoặc "Nhập tay" từng đánh giá bên dưới.',
                              style: const TextStyle(
                                  fontSize: 12, color: AdminColors.inkSecondary),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: cfg.autoReviewReply,
                        activeColor: AdminColors.forest,
                        onChanged: (v) => widget.controller
                            .saveAutomationSettings(cfg.copyWith(autoReviewReply: v)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Rating summary card
                AdminCard(
                  padding: const EdgeInsets.all(22),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 700;
                      final summaryLeft = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Điểm đánh giá trung bình',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AdminColors.inkSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                total == 0 ? '0.0' : avg.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w700,
                                  color: AdminColors.ink,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 6),
                                child: Text('/ 5.0',
                                    style: TextStyle(
                                        fontSize: 15, color: AdminColors.inkMuted)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < avg.round()
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: AdminColors.amber,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tổng cộng $total lượt đánh giá đã xác thực đơn mua',
                            style: const TextStyle(fontSize: 12, color: AdminColors.inkMuted),
                          ),
                        ],
                      );

                      final bars = Column(
                        children: [
                          for (var star = 5; star >= 1; star--) ...[
                            Builder(builder: (_) {
                              final count = all.where((r) => r.review.rating == star).length;
                              final ratio = total == 0 ? 0.0 : count / total;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        '$star ★',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: AdminColors.inkSecondary,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(999),
                                        child: LinearProgressIndicator(
                                          value: ratio,
                                          minHeight: 8,
                                          backgroundColor: AdminColors.surfaceMuted,
                                          color: AdminColors.forest,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 36,
                                      child: Text(
                                        '$count',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      );

                      if (wide) {
                        return Row(
                          children: [
                            SizedBox(width: 260, child: summaryLeft),
                            const SizedBox(width: 32),
                            Expanded(child: bars),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          summaryLeft,
                          const SizedBox(height: 20),
                          bars,
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // Filters
                AdminCard(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AdminSearchField(
                        hint: 'Tìm nội dung, người đánh giá, sản phẩm...',
                        width: 260,
                        onChanged: (v) => setState(() => _query = v),
                      ),
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String>(
                          value: _productFilter,
                          isExpanded: true,
                          decoration: adminInputDecoration(label: 'Lọc theo sản phẩm'),
                          items: [
                            const DropdownMenuItem(value: '', child: Text('Tất cả sản phẩm')),
                            ...widget.controller.products.map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(p.title, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _productFilter = v ?? ''),
                        ),
                      ),
                      FilterChip(
                        selected: _onlyUnreplied,
                        selectedColor: AdminColors.amber,
                        checkmarkColor: Colors.white,
                        label: Text(
                          'Chưa trả lời ($unrepliedCount)',
                          style: TextStyle(
                            color: _onlyUnreplied ? Colors.white : AdminColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onSelected: (v) => setState(() => _onlyUnreplied = v),
                      ),
                      Wrap(
                        spacing: 6,
                        children: [
                          ChoiceChip(
                            label: const Text('Tất cả sao'),
                            selected: _starFilter == null,
                            onSelected: (_) => setState(() => _starFilter = null),
                          ),
                          for (var star = 5; star >= 1; star--)
                            ChoiceChip(
                              label: Text('$star ★'),
                              selected: _starFilter == star,
                              onSelected: (_) => setState(() => _starFilter = star),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Reviews List
                if (filtered.isEmpty)
                  const AdminCard(
                    child: AdminEmptyState(
                      icon: Iconsax.star,
                      title: 'Chưa có đánh giá nào',
                      subtitle:
                          'Khi khách hàng hoàn tất đơn hàng và gửi đánh giá trên app, chúng sẽ xuất hiện tại đây.',
                    ),
                  )
                else
                  Column(
                    children: filtered.map((record) {
                      final r = record.review;
                      final matchedProduct = widget.controller.products
                              .firstWhereOrNull(
                                  (p) => p.id == record.productId) ??
                          ProductModel(
                            id: record.productId,
                            title: record.productTitle,
                            stock: 10,
                            price: 0,
                            thumbnail: record.productThumbnail,
                            productType: 'ProductType.variable',
                            isFeatured: true,
                          );

                      void openInspect({
                        String? initialVideoUrl,
                        String? initialImageUrl,
                      }) {
                        showAdminProductAndVideoPreviewDialog(
                          context,
                          controller: widget.controller,
                          product: matchedProduct,
                          reviewRecord: record,
                          initialVideoUrl: initialVideoUrl,
                          initialImageUrl: initialImageUrl,
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AdminCard(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () => openInspect(),
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    AdminImageThumb(
                                      url: record.productThumbnail,
                                      width: 62,
                                      height: 62,
                                      fit: BoxFit.contain,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: AdminColors.forest,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Iconsax.eye,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 6,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        InkWell(
                                          onTap: () => openInspect(),
                                          child: Text(
                                            record.productTitle,
                                            style: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                              color: AdminColors.forest,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
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
                                        if (record.purchaseOrderId.isNotEmpty)
                                          AdminBadge(
                                            label: 'Đã mua #${record.purchaseOrderId}',
                                            color: AdminColors.emerald,
                                            bgColor: AdminColors.emeraldBg,
                                            icon: Iconsax.verify,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      r.text,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: AdminColors.ink,
                                        height: 1.5,
                                      ),
                                    ),
                                    if (r.hasMedia) ...[
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          for (final imgUrl in r.imageUrls)
                                            InkWell(
                                              onTap: () => openInspect(
                                                  initialImageUrl: imgUrl),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: AdminImageThumb(
                                                url: imgUrl,
                                                width: 68,
                                                height: 68,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          for (var vIdx = 0; vIdx < r.videoUrls.length; vIdx++)
                                            InkWell(
                                              onTap: () => openInspect(
                                                initialVideoUrl:
                                                    r.videoUrls[vIdx],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Container(
                                                width: 96,
                                                height: 68,
                                                decoration: BoxDecoration(
                                                  color: AdminColors.forest,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .play_circle_fill_rounded,
                                                      color: AdminColors.sage,
                                                      size: 24,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '▶️ Phát Video #${vIdx + 1}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10.5,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      'Bởi ${r.authorName}'
                                      '${r.createdAt != null ? ' • ${DateFormat('dd/MM/yyyy HH:mm').format(r.createdAt!)}' : ''}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AdminColors.inkMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () => openInspect(),
                                          icon: const Icon(Iconsax.eye, size: 15),
                                          label: Text(
                                            r.hasMedia
                                                ? 'Xem Đôi giày & Phát Video/Ảnh đánh giá'
                                                : 'Xem Đôi giày & Video sản phẩm',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AdminColors.sky,
                                            side: BorderSide(
                                              color: AdminColors.sky
                                                  .withValues(alpha: 0.4),
                                            ),
                                            backgroundColor: AdminColors.skyBg,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                          ),
                                        ),
                                        if (!r.hasAdminReply)
                                          FilledButton.tonalIcon(
                                            onPressed: () =>
                                                widget.controller.autoReplySingleReview(record),
                                            icon: const Icon(Icons.auto_awesome_rounded, size: 15),
                                            label: const Text('Trả lời tự động',
                                                style: TextStyle(fontSize: 12)),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: AdminColors.sageSoft,
                                              foregroundColor: AdminColors.forest,
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 6),
                                            ),
                                          ),
                                        OutlinedButton.icon(
                                          onPressed: () => _openReplyDialog(record),
                                          icon: const Icon(Iconsax.edit_2, size: 15),
                                          label: Text(
                                            r.hasAdminReply ? 'Sửa phản hồi' : 'Nhập tay',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (r.hasAdminReply) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AdminColors.sageSoft.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(11),
                                          border: Border.all(
                                              color: AdminColors.forest.withValues(alpha: 0.18)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Iconsax.verify,
                                                    size: 14, color: AdminColors.forest),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  'Phản hồi từ VELORA',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: AdminColors.forest,
                                                  ),
                                                ),
                                                if (r.adminReplyAt != null) ...[
                                                  const Spacer(),
                                                  Text(
                                                    DateFormat('dd/MM/yyyy HH:mm')
                                                        .format(r.adminReplyAt!),
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AdminColors.inkMuted,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              r.adminReply!,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                color: AdminColors.ink,
                                                height: 1.45,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Xóa đánh giá',
                                onPressed: () async {
                                  final ok = await showAdminConfirmDialog(
                                    context,
                                    title: 'Xóa đánh giá này?',
                                    message:
                                        'Đánh giá của "${r.authorName}" trên sản phẩm "${record.productTitle}" sẽ bị xóa vĩnh viễn.',
                                  );
                                  if (ok) {
                                    await widget.controller.deleteReview(record);
                                  }
                                },
                                icon: const Icon(Iconsax.trash, size: 18, color: AdminColors.rose),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
