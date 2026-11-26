import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/data/admin_web_models.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:fashion_business_app/admin/web/widgets/admin_product_video_preview_dialog.dart';
import 'package:fashion_business_app/features/shop/models/category_model.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class AdminCategoriesView extends StatefulWidget {
  const AdminCategoriesView({super.key, required this.controller});

  final AdminWebController controller;

  @override
  State<AdminCategoriesView> createState() => _AdminCategoriesViewState();
}

class _AdminCategoriesViewState extends State<AdminCategoriesView> {
  String _query = '';
  String? _selectedCategoryId;
  final Map<String, GlobalKey> _cardKeys = {};
  final Map<String, GlobalKey> _drawerKeys = {};

  AdminWebController get c => widget.controller;

  GlobalKey _cardKeyFor(String id) =>
      _cardKeys.putIfAbsent(id, () => GlobalKey());

  GlobalKey _drawerKeyFor(String id) =>
      _drawerKeys.putIfAbsent(id, () => GlobalKey());

  String _canonicalKey(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.contains('running') || s.contains('chạy bộ')) return 'running';
    if (s.contains('lifestyle') || s.contains('hằng ngày')) return 'lifestyle';
    if (s.contains('training') || s.contains('tập luyện')) return 'training';
    if (s.contains('basketball') || s.contains('bóng rổ')) return 'basketball';
    if (s.contains('trail') || s.contains('địa hình')) return 'trail';
    return s;
  }

  List<ProductModel> _productsForCategory(CategoryModel cat) {
    final ck = _canonicalKey(cat.id.isNotEmpty ? cat.id : cat.name);
    final ckName = _canonicalKey(cat.name);
    return c.products.where((p) {
      if (p.categoryId == cat.id) return true;
      final pk = _canonicalKey(p.categoryId);
      final pn = _canonicalKey(p.categoryName);
      return pk == ck || pn == ck || pk == ckName || pn == ckName;
    }).toList();
  }

  ({IconData icon, String taglineVi, String taglineEn}) _metaForCategory(
    CategoryModel cat,
  ) {
    final key = _canonicalKey('${cat.id} ${cat.name}');
    switch (key) {
      case 'running':
        return (
          icon: Iconsax.flash_1,
          taglineVi: 'Đệm nhẹ & hoàn trả năng lượng cho chạy bộ đường dài',
          taglineEn: 'Lightweight cushioning & energy return for road running',
        );
      case 'lifestyle':
        return (
          icon: Iconsax.verify,
          taglineVi: 'Thiết kế tối giản hiện đại, phối đồ đi làm & dạo phố',
          taglineEn: 'Minimalist modern silhouette for everyday comfort',
        );
      case 'training':
        return (
          icon: Iconsax.weight,
          taglineVi: 'Đế phẳng ổn định trọng tâm cho tập Gym & Cross-Training',
          taglineEn: 'Flat stable base & grip for gym and HIIT workouts',
        );
      case 'basketball':
        return (
          icon: Iconsax.cup,
          taglineVi: 'Khóa cổ chân chắc chắn, bật nhảy êm & bám sân bóng rổ',
          taglineEn: 'Court traction & ankle support for basketball play',
        );
      case 'trail':
      default:
        return (
          icon: Iconsax.routing,
          taglineVi: 'Gai đế địa hình sâu & chống thấm nước vượt đường Trail',
          taglineEn: 'Trail lugs & weather-resistant upper for rugged terrain',
        );
    }
  }

  void _toggleCategoryDrawer(String catId) {
    final collapsing = _selectedCategoryId == catId;
    setState(() {
      _selectedCategoryId = collapsing ? null : catId;
    });

    // Only scroll gently when expanding AND only if the drawer starts near/below the bottom of viewport
    if (!collapsing) {
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (!mounted || _selectedCategoryId != catId) return;
        final ctx = _drawerKeys[catId]?.currentContext;
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

  Future<void> _openEditor({CategoryModel? existing}) async {
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
            constraints: const BoxConstraints(maxWidth: 500),
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
                                ? 'Thêm Bộ sưu tập / Danh mục mới'
                                : 'Chỉnh sửa Danh mục ${existing.name}',
                            style: const TextStyle(
                              fontSize: 17,
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Vui lòng nhập tên danh mục'
                          : null,
                      decoration: adminInputDecoration(
                        label: 'Tên danh mục giày thể thao *',
                        hint: 'Ví dụ: Chạy bộ, Bóng rổ, Địa hình...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    AdminImageUploadField(
                      label: 'Ảnh đại diện bộ sưu tập (tự lấy ảnh giày nếu để trống)',
                      controller: imageCtrl,
                      previewWidth: 88,
                      previewHeight: 88,
                      onUploadBytes: (bytes, name) =>
                          c.uploadImage(bytes, name, 'Categories/Images'),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeTrackColor: AdminColors.forest,
                      title: const Text(
                        'Hiển thị trên Trang chủ & Thanh lọc',
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      value: isFeatured,
                      onChanged: (v) => setModalState(() => isFeatured = v),
                    ),
                    const SizedBox(height: 18),
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
                              ? 'Tạo danh mục'
                              : 'Lưu thay đổi',
                          icon: Iconsax.tick_circle,
                          loading: saving,
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => saving = true);
                            final ok = await c.saveCategory(
                              CategoryModel(
                                id: existing?.id ?? '',
                                name: nameCtrl.text.trim(),
                                image: imageCtrl.text.trim(),
                                parentId: existing?.parentId ?? '',
                                isFeatured: isFeatured,
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
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Obx(() {
      final vi = c.isVi.value;
      final allCats = c.categories.toList();
      final q = _query.trim().toLowerCase();
      final filtered = allCats.where((cat) {
        if (q.isEmpty) return true;
        final localized = c.localizeCategory(cat.name).toLowerCase();
        return cat.name.toLowerCase().contains(q) ||
            localized.contains(q) ||
            cat.id.toLowerCase().contains(q);
      }).toList();

      final totalModels = c.products.length;
      final totalStock = c.products.fold<int>(0, (s, p) => s + p.stock);
      final totalActive = c.products.where((p) => !p.isDiscontinued).length;
      final totalDiscontinued =
          c.products.where((p) => p.isDiscontinued).length;
      final featuredTotal =
          c.products.where((p) => p.isFeatured && !p.isDiscontinued).length;

      return SingleChildScrollView(
        padding: EdgeInsets.all(width < 700 ? 16 : 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSectionToolbar(
                  title: vi
                      ? 'Danh mục (${allCats.length})'
                      : 'Categories (${allCats.length})',
                  actions: [
                    AdminSearchField(
                      hint: vi ? 'Tìm danh mục...' : 'Search...',
                      width: 220,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    AdminPrimaryButton(
                      label: vi ? 'Thêm danh mục' : 'Add Category',
                      icon: Iconsax.add_circle,
                      onPressed: () => _openEditor(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Clean neutral summary strip (no rainbow backgrounds)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth >= 1020
                        ? 4
                        : (constraints.maxWidth >= 620 ? 2 : 1);
                    final cardWidth =
                        (constraints.maxWidth - (cols - 1) * 14) / cols;
                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        _buildNeutralMetricCard(
                          width: cardWidth,
                          label: vi ? 'Dòng sản phẩm' : 'Collections',
                          value: '${allCats.length} danh mục',
                          sub: 'Chạy bộ · Hằng ngày · Tập luyện · Bóng rổ · Địa hình',
                        ),
                        _buildNeutralMetricCard(
                          width: cardWidth,
                          label: vi ? 'Tổng mẫu giày' : 'Sneaker Models',
                          value: '$totalModels mẫu',
                          sub: '$totalActive đang bán · $totalDiscontinued ngừng bán',
                        ),
                        _buildNeutralMetricCard(
                          width: cardWidth,
                          label: vi ? 'Tổng tồn kho' : 'Total Stock',
                          value: '$totalStock đôi',
                          sub: 'Kho Tổng VELORA Hà Nội',
                        ),
                        _buildNeutralMetricCard(
                          width: cardWidth,
                          label: vi ? 'Ghim tab Nổi bật' : 'Pinned on Featured',
                          value: '$featuredTotal mẫu',
                          sub: 'Đang hiển thị video review thực tế',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Collection Rows with inline smooth slide-down drawer right underneath each row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth >= 1040 ? 2 : 1;
                    final rows = <List<CategoryModel>>[];
                    for (var i = 0; i < filtered.length; i += cols) {
                      rows.add(
                        filtered.sublist(
                          i,
                          i + cols > filtered.length ? filtered.length : i + cols,
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (var r = 0; r < rows.length; r++) ...[
                          if (r > 0) const SizedBox(height: 16),
                          Builder(builder: (context) {
                            final rowCats = rows[r];
                            final selectedInRow = rowCats.firstWhereOrNull(
                              (cat) => cat.id == _selectedCategoryId,
                            );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (cols == 1)
                                  _buildCategoryCard(rowCats.first, vi: vi)
                                else
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildCategoryCard(
                                          rowCats[0],
                                          vi: vi,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: rowCats.length > 1
                                            ? _buildCategoryCard(
                                                rowCats[1],
                                                vi: vi,
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ),

                                // Butter-smooth 60fps SizeTransition drawer (retains child while collapsing!)
                                _SmoothExpandableDrawer(
                                  expanded: selectedInRow != null,
                                  child: selectedInRow == null
                                      ? null
                                      : Padding(
                                          key: _drawerKeyFor(selectedInRow.id),
                                          padding:
                                              const EdgeInsets.only(top: 12),
                                          child:
                                              _buildSelectedCategoryProductsSection(
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

  Widget _buildNeutralMetricCard({
    required double width,
    required String label,
    required String value,
    required String sub,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel cat, {required bool vi}) {
    final catProducts = _productsForCategory(cat);
    final meta = _metaForCategory(cat);
    final activeCount = catProducts.where((p) => !p.isDiscontinued).length;
    final discCount = catProducts.where((p) => p.isDiscontinued).length;
    final stockSum = catProducts.fold<int>(0, (sum, p) => sum + p.stock);
    final featuredCount =
        catProducts.where((p) => p.isFeatured && !p.isDiscontinued).length;
    final heroImage = cat.image.trim().isNotEmpty
        ? cat.image.trim()
        : (catProducts.isNotEmpty ? catProducts.first.thumbnail : '');
    final isSelected = _selectedCategoryId == cat.id;

    final statsParts = <String>[
      'Tồn kho: $stockSum đôi',
      'Đang bán: $activeCount',
      if (discCount > 0) 'Ngừng bán: $discCount',
      'Nổi bật: $featuredCount',
    ];

    return Container(
      key: _cardKeyFor(cat.id),
      padding: const EdgeInsets.all(20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: heroImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: heroImage,
                        fit: BoxFit.contain,
                      )
                    : Icon(
                        meta.icon,
                        color: const Color(0xFF475569),
                        size: 28,
                      ),
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
                            c.localizeCategory(cat.name),
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        // Single restrained neutral badge per card
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${catProducts.length} mẫu giày',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statsParts.join('  ·  '),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: catProducts.take(6).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final p = catProducts[i];
                      return Tooltip(
                        message: p.title,
                        child: InkWell(
                          onTap: () => showAdminProductAndVideoPreviewDialog(
                            context,
                            controller: c,
                            product: p,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 36,
                            height: 36,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: p.thumbnail,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => _toggleCategoryDrawer(cat.id),
                icon: Icon(
                  isSelected
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                ),
                label: Text(
                  isSelected
                      ? 'Thu gọn'
                      : 'Xem ${catProducts.length} mẫu giày',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                    horizontal: 13,
                    vertical: 9,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Chỉnh sửa danh mục',
                onPressed: () => _openEditor(existing: cat),
                icon: const Icon(
                  Iconsax.edit_2,
                  size: 17,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCategoryProductsSection(CategoryModel cat) {
    final products = _productsForCategory(cat);

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
                  '${c.localizeCategory(cat.name)} (${products.length} mẫu)',
                  style: const TextStyle(
                    fontSize: 15,
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
                onPressed: () => _toggleCategoryDrawer(cat.id),
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
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Chưa có mẫu giày nào trong danh mục này.',
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
                        child: Opacity(
                          opacity: isDisc ? 0.6 : 1.0,
                          child: Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF111827),
                                          decoration: isDisc
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${c.formatMoney(price)} · ${p.stock} đôi',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          // Single status badge per sneaker item
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDisc
                                                  ? const Color(0xFFFEF2F2)
                                                  : const Color(0xFFF0FDF4),
                                              borderRadius:
                                                  BorderRadius.circular(4),
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
                                          const Spacer(),
                                          InkWell(
                                            onTap: () =>
                                                c.toggleProductDiscontinued(
                                                    p, !isDisc),
                                            child: Text(
                                              isDisc ? 'Mở lại' : 'Ngừng',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF64748B),
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          if (products.length > 8) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _toggleCategoryDrawer(cat.id),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                ),
                icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 17),
                label: const Text(
                  'Thu gọn danh sách ↑',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SmoothExpandableDrawer extends StatefulWidget {
  const _SmoothExpandableDrawer({
    required this.expanded,
    required this.child,
  });

  final bool expanded;
  final Widget? child;

  @override
  State<_SmoothExpandableDrawer> createState() =>
      _SmoothExpandableDrawerState();
}

class _SmoothExpandableDrawerState extends State<_SmoothExpandableDrawer>
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
  void didUpdateWidget(covariant _SmoothExpandableDrawer oldWidget) {
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
