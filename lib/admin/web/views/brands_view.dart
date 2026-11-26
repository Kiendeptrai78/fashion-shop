import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/data/admin_web_models.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:fashion_business_app/admin/web/widgets/admin_product_video_preview_dialog.dart';
import 'package:fashion_business_app/features/shop/models/brand_model.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class AdminBrandsView extends StatefulWidget {
  const AdminBrandsView({super.key, required this.controller});

  final AdminWebController controller;

  @override
  State<AdminBrandsView> createState() => _AdminBrandsViewState();
}

class _AdminBrandsViewState extends State<AdminBrandsView> {
  String _query = '';
  String? _selectedBrandId;
  final Map<String, GlobalKey> _cardKeys = {};
  final Map<String, GlobalKey> _drawerKeys = {};

  AdminWebController get c => widget.controller;

  GlobalKey _cardKeyFor(String id) =>
      _cardKeys.putIfAbsent(id, () => GlobalKey());

  GlobalKey _drawerKeyFor(String id) =>
      _drawerKeys.putIfAbsent(id, () => GlobalKey());

  List<ProductModel> _productsForBrand(BrandModel brand) {
    final bn = brand.name.trim().toLowerCase();
    return c.products.where((p) {
      if (p.brand?.id == brand.id) return true;
      return (p.brand?.name.trim().toLowerCase() ?? '') == bn;
    }).toList();
  }

  void _toggleBrandDrawer(String brandId) {
    final collapsing = _selectedBrandId == brandId;
    setState(() {
      _selectedBrandId = collapsing ? null : brandId;
    });

    if (!collapsing) {
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (!mounted || _selectedBrandId != brandId) return;
        final ctx = _drawerKeys[brandId]?.currentContext;
        if (ctx == null || !ctx.mounted) return;
        final box = ctx.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return;
        final topY = box.localToGlobal(Offset.zero).dy;
        final viewH = MediaQuery.sizeOf(ctx).height;
        if (topY > viewH * 0.72) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: 0.25,
          );
        }
      });
    }
  }

  Future<void> _openEditor({BrandModel? existing}) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final imageCtrl = TextEditingController(text: existing?.image ?? '');
    bool isFeatured = existing?.isFeatured ?? true;
    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: AdminColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            existing == null
                                ? 'Thêm thương hiệu mới'
                                : 'Chỉnh sửa thương hiệu',
                            style: const TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w700,
                              color: AdminColors.ink,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed:
                              saving ? null : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: nameCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Vui lòng nhập tên thương hiệu'
                          : null,
                      decoration: adminInputDecoration(
                        label: 'Tên thương hiệu *',
                        hint: 'Ví dụ: Nike, Adidas, New Balance...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    AdminImageUploadField(
                      label: 'Logo / Ảnh đại diện thương hiệu',
                      controller: imageCtrl,
                      previewWidth: 88,
                      previewHeight: 88,
                      onUploadBytes: (bytes, name) =>
                          c.uploadImage(bytes, name, 'Brands/Images'),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeTrackColor: AdminColors.forest,
                      title: const Text(
                        'Hiển thị thương hiệu nổi bật',
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text(
                        'Xuất hiện ưu tiên trong bộ lọc và trang Cửa hàng trên app.',
                        style:
                            TextStyle(fontSize: 12, color: AdminColors.inkMuted),
                      ),
                      value: isFeatured,
                      onChanged: (v) => setModalState(() => isFeatured = v),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed:
                              saving ? null : () => Navigator.of(context).pop(),
                          child: const Text('Hủy'),
                        ),
                        const SizedBox(width: 10),
                        AdminPrimaryButton(
                          label: existing == null
                              ? 'Tạo thương hiệu'
                              : 'Lưu thay đổi',
                          icon: Iconsax.tick_circle,
                          loading: saving,
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => saving = true);
                            final count = existing != null
                                ? c.productCountForBrand(existing.id)
                                : 0;
                            final ok = await c.saveBrand(
                              BrandModel(
                                id: existing?.id ?? '',
                                name: nameCtrl.text.trim(),
                                image: imageCtrl.text.trim(),
                                isFeatured: isFeatured,
                                productsCount: count,
                              ),
                              isNew: existing == null,
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
      ),
    );
    nameCtrl.dispose();
    imageCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Obx(() {
      final q = _query.trim().toLowerCase();
      final filtered = c.brands.where((b) {
        if (q.isEmpty) return true;
        return b.name.toLowerCase().contains(q) ||
            b.id.toLowerCase().contains(q);
      }).toList();

      return SingleChildScrollView(
        padding: EdgeInsets.all(width < 700 ? 16 : 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSectionToolbar(
                  title: 'Thương hiệu (${c.brands.length})',
                  actions: [
                    AdminSearchField(
                      hint: 'Tìm thương hiệu...',
                      width: 220,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    AdminPrimaryButton(
                      label: 'Thêm thương hiệu',
                      icon: Iconsax.add_circle,
                      onPressed: () => _openEditor(),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                if (filtered.isEmpty)
                  AdminCard(
                    child: AdminEmptyState(
                      icon: Iconsax.award,
                      title: 'Chưa có thương hiệu phù hợp',
                      subtitle:
                          'Thêm các thương hiệu giày để phân loại sản phẩm trên ứng dụng.',
                      action: AdminPrimaryButton(
                        label: 'Thêm thương hiệu đầu tiên',
                        onPressed: () => _openEditor(),
                      ),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth >= 1100
                          ? 3
                          : constraints.maxWidth >= 680
                              ? 2
                              : 1;
                      final rows = <List<BrandModel>>[];
                      for (var i = 0; i < filtered.length; i += cols) {
                        rows.add(
                          filtered.sublist(
                            i,
                            i + cols > filtered.length
                                ? filtered.length
                                : i + cols,
                          ),
                        );
                      }

                      return Column(
                        children: [
                          for (var r = 0; r < rows.length; r++) ...[
                            if (r > 0) const SizedBox(height: 16),
                            Builder(builder: (context) {
                              final rowBrands = rows[r];
                              final selectedInRow = rowBrands.firstWhereOrNull(
                                (b) => b.id == _selectedBrandId,
                              );

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (var cIdx = 0;
                                          cIdx < cols;
                                          cIdx++) ...[
                                        if (cIdx > 0)
                                          const SizedBox(width: 16),
                                        Expanded(
                                          child: cIdx < rowBrands.length
                                              ? _buildBrandCard(
                                                  rowBrands[cIdx])
                                              : const SizedBox.shrink(),
                                        ),
                                      ],
                                    ],
                                  ),
                                  _BrandSmoothDrawer(
                                    expanded: selectedInRow != null,
                                    child: selectedInRow == null
                                        ? null
                                        : Padding(
                                            key: _drawerKeyFor(
                                                selectedInRow.id),
                                            padding:
                                                const EdgeInsets.only(top: 12),
                                            child: _buildBrandProductsDrawer(
                                              selectedInRow,
                                            ),
                                          ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildBrandCard(BrandModel brand) {
    final brandProducts = _productsForBrand(brand);
    final isSelected = _selectedBrandId == brand.id;
    final stockSum = brandProducts.fold<int>(0, (s, p) => s + p.stock);

    return Container(
      key: _cardKeyFor(brand.id),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AdminColors.forest : const Color(0xFFE5E7EB),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdminImageThumb(
                url: brand.image,
                width: 56,
                height: 56,
                fit: BoxFit.contain,
                borderRadius: 12,
                placeholderIcon: Iconsax.award,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            brand.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        if (brand.isFeatured == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Nổi bật',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${brandProducts.length} mẫu giày · Tồn kho $stockSum đôi',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _toggleBrandDrawer(brand.id),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      isSelected ? AdminColors.forest : Colors.white,
                  foregroundColor:
                      isSelected ? Colors.white : const Color(0xFF111827),
                  side: BorderSide(
                    color: isSelected
                        ? AdminColors.forest
                        : const Color(0xFFCBD5E1),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(
                  isSelected
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                ),
                label: Text(
                  isSelected
                      ? 'Thu gọn'
                      : 'Xem ${brandProducts.length} mẫu giày',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Chỉnh sửa thương hiệu',
                onPressed: () => _openEditor(existing: brand),
                icon: const Icon(
                  Iconsax.edit_2,
                  size: 16,
                  color: Color(0xFF475569),
                ),
              ),
              IconButton(
                tooltip: 'Xóa thương hiệu',
                onPressed: () async {
                  final ok = await showAdminConfirmDialog(
                    context,
                    title: 'Xóa thương hiệu "${brand.name}"?',
                    message:
                        'Thương hiệu sẽ bị xóa khỏi danh mục Brands trên Firestore.',
                  );
                  if (ok) {
                    await c.deleteBrand(brand);
                  }
                },
                icon: const Icon(
                  Iconsax.trash,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrandProductsDrawer(BrandModel brand) {
    final products = _productsForBrand(brand);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Danh sách ${products.length} mẫu giày thuộc hãng ${brand.name}',
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => c.selectSection(AdminSection.products),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF111827),
                ),
                child: const Text(
                  'Mở Kho hàng →',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: () => _toggleBrandDrawer(brand.id),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF111827),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 17),
                label: const Text(
                  'Thu gọn',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Chưa có mẫu giày nào thuộc thương hiệu này.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final itemCols = constraints.maxWidth >= 1080
                    ? 4
                    : (constraints.maxWidth >= 760
                        ? 3
                        : (constraints.maxWidth >= 500 ? 2 : 1));
                final tileWidth =
                    (constraints.maxWidth - (itemCols - 1) * 12) / itemCols;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: products.map((p) {
                    final price = p.salePrice > 0 ? p.salePrice : p.price;
                    final isDisc = p.isDiscontinued;
                    return SizedBox(
                      width: tileWidth,
                      child: InkWell(
                        onTap: () => showAdminProductAndVideoPreviewDialog(
                          context,
                          controller: c,
                          product: p,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: p.thumbnail,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${c.formatMoney(price)} · ${p.stock} đôi',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDisc
                                      ? const Color(0xFFFEF2F2)
                                      : const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isDisc ? 'Ngừng bán' : 'Đang bán',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDisc
                                        ? const Color(0xFFB91C1C)
                                        : const Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _BrandSmoothDrawer extends StatefulWidget {
  const _BrandSmoothDrawer({
    required this.expanded,
    required this.child,
  });

  final bool expanded;
  final Widget? child;

  @override
  State<_BrandSmoothDrawer> createState() => _BrandSmoothDrawerState();
}

class _BrandSmoothDrawerState extends State<_BrandSmoothDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _sizeFactor;
  late final Animation<double> _opacity;
  Widget? _cachedChild;

  @override
  void initState() {
    super.initState();
    _cachedChild = widget.child;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 210),
      value: widget.expanded ? 1.0 : 0.0,
    )..addStatusListener((status) {
        if (status == AnimationStatus.dismissed && !widget.expanded && mounted) {
          setState(() => _cachedChild = null);
        }
      });
    _sizeFactor = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _opacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
      reverseCurve: const Interval(0.25, 1.0, curve: Curves.easeIn),
    );
  }

  @override
  void didUpdateWidget(covariant _BrandSmoothDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child != null) {
      _cachedChild = widget.child;
    }
    if (widget.expanded && !oldWidget.expanded) {
      _ctrl.forward();
    } else if (!widget.expanded && oldWidget.expanded) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedChild == null && !widget.expanded) {
      return const SizedBox(width: double.infinity, height: 0);
    }
    return ClipRect(
      child: SizeTransition(
        sizeFactor: _sizeFactor,
        axisAlignment: -1.0,
        child: FadeTransition(
          opacity: _opacity,
          child: RepaintBoundary(
            child: _cachedChild ?? const SizedBox(width: double.infinity),
          ),
        ),
      ),
    );
  }
}
