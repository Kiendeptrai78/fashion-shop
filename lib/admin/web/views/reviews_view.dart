import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Obx(() {
      final all = widget.controller.reviews;
      final q = _query.trim().toLowerCase();
      final filtered = all.where((r) {
        if (_starFilter != null && r.review.rating != _starFilter) return false;
        if (_productFilter.isNotEmpty && r.productId != _productFilter) return false;
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
                const AdminSectionToolbar(
                  title: 'Quản lý Đánh giá sản phẩm',
                  subtitle:
                      'Theo dõi mức độ hài lòng của người mua đã nhận hàng và kiểm duyệt nội dung đánh giá.',
                ),
                const SizedBox(height: 20),

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
                              final count =
                                  all.where((r) => r.review.rating == star).length;
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
                        width: 280,
                        onChanged: (v) => setState(() => _query = v),
                      ),
                      SizedBox(
                        width: 230,
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
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AdminCard(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AdminImageThumb(
                                url: record.productThumbnail,
                                width: 58,
                                height: 58,
                                fit: BoxFit.contain,
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
                                        Text(
                                          record.productTitle,
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: AdminColors.ink,
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
                                    const SizedBox(height: 8),
                                    Text(
                                      'Bởi ${r.authorName}'
                                      '${r.createdAt != null ? ' • ${DateFormat('dd/MM/yyyy HH:mm').format(r.createdAt!)}' : ''}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AdminColors.inkMuted,
                                      ),
                                    ),
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
                                icon: const Icon(Iconsax.trash,
                                    size: 18, color: AdminColors.rose),
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
