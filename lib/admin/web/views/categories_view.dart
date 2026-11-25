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

  AdminWebController get c => widget.controller;

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

  ({
    Color accent,
    Color bg,
    IconData icon,
    String taglineVi,
    String taglineEn,
  }) _metaForCategory(CategoryModel cat) {
    final key = _canonicalKey('${cat.id} ${cat.name}');
    switch (key) {
      case 'running':
        return (
          accent: const Color(0xFF16A34A),
          bg: const Color(0xFFDCFCE7),
          icon: Iconsax.flash_1,
          taglineVi: 'Đệm NitroFoam siêu nhẹ & hoàn trả năng lượng cho Marathon / Chạy đường dài',
          taglineEn: 'Ultra-light NitroFoam cushioning & energy return for road running',
        );
      case 'lifestyle':
        return (
          accent: const Color(0xFF7C3AED),
          bg: const Color(0xFFEDE9FE),
          icon: Iconsax.verify,
          taglineVi: 'Thiết kế tối giản hiện đại, phối đồ đi làm & dạo phố hằng ngày',
          taglineEn: 'Minimalist modern silhouette crafted for all-day urban comfort',
        );
      case 'training':
        return (
          accent: const Color(0xFF0284C7),
          bg: const Color(0xFFE0F2FE),
          icon: Iconsax.weight,
          taglineVi: 'Đế phẳng ổn định trọng tâm, bám sàn tối đa cho Gym & Cross-Training',
          taglineEn: 'Flat stable base & multi-directional grip for gym and HIIT workouts',
        );
      case 'basketball':
        return (
          accent: const Color(0xFFD97706),
          bg: const Color(0xFFFEF3C7),
          icon: Iconsax.cup,
          taglineVi: 'Khóa cổ chân chắc chắn, bật nhảy êm và bám sân gỗ / sân outdoor',
          taglineEn: 'Explosive court traction & ankle lockdown for high-impact play',
        );
      case 'trail':
      default:
        return (
          accent: const Color(0xFF0D9488),
          bg: const Color(0xFFCCFBF1),
          icon: Iconsax.routing,
          taglineVi: 'Gai đế địa hình sâu & màng chống thấm nước vượt mọi cung đường Trail',
          taglineEn: 'Aggressive trail lugs & weather-resistant upper for rugged terrain',
        );
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                                ? 'Thêm Bộ sưu tập / Danh mục mới'
                                : 'Chỉnh sửa Danh mục ${existing.name}',
                            style: const TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w800,
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
                        'Hiển thị nổi bật trên Trang chủ & Thanh lọc',
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

      final selectedCat = _selectedCategoryId == null
          ? null
          : allCats.firstWhereOrNull((cat) => cat.id == _selectedCategoryId);

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
                      ? 'Bộ sưu tập & Danh mục Giày thể thao VELORA (${allCats.length})'
                      : 'VELORA Athletic Collections & Categories (${allCats.length})',
                  subtitle: vi
                      ? 'Quản lý trực quan từng dòng giày thể thao, tồn kho theo bộ sưu tập, video nổi bật và trạng thái mở bán.'
                      : 'Manage athletic shoe collections, inventory distribution, featured videos, and active models.',
                  actions: [
                    AdminSearchField(
                      hint: vi ? 'Tìm bộ sưu tập...' : 'Search collection...',
                      width: 240,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    AdminPrimaryButton(
                      label: vi ? '+ Thêm bộ sưu tập' : '+ Add Collection',
                      icon: Iconsax.add_circle,
                      onPressed: () => _openEditor(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Top KPI Summary across all collections
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth >= 1020
                        ? 4
                        : (constraints.maxWidth >= 620 ? 2 : 1);
                    return GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 2.15,
                      children: [
                        AdminStatCard(
                          title: vi ? 'Tổng dòng sản phẩm' : 'Total Collections',
                          value: '${allCats.length} bộ sưu tập',
                          subtitle: 'Chạy bộ • Hằng ngày • Tập luyện • Bóng rổ • Địa hình',
                          icon: Iconsax.category_2,
                          accentColor: AdminColors.forest,
                          accentBg: AdminColors.sageSoft,
                        ),
                        AdminStatCard(
                          title: vi ? 'Tổng mẫu giày VELORA' : 'Total Sneaker Models',
                          value: '$totalModels mẫu',
                          subtitle: '$totalActive đang mở bán • $totalDiscontinued ngừng bán',
                          icon: Iconsax.box,
                          accentColor: AdminColors.sky,
                          accentBg: AdminColors.skyBg,
                        ),
                        AdminStatCard(
                          title: vi ? 'Tổng tồn kho toàn hệ thống' : 'Total Warehouse Stock',
                          value: '$totalStock đôi',
                          subtitle: 'Tại Tổng Kho VELORA Cầu Giấy, Hà Nội',
                          icon: Iconsax.building_4,
                          accentColor: AdminColors.emerald,
                          accentBg: AdminColors.emeraldBg,
                        ),
                        AdminStatCard(
                          title: vi ? 'Đang ghim trên tab Nổi bật' : 'Pinned on Featured',
                          value:
                              '${c.products.where((p) => p.isFeatured && !p.isDiscontinued).length} mẫu',
                          subtitle: 'Phát video quảng cáo trên tab Nổi bật Mobile',
                          icon: Icons.auto_awesome_rounded,
                          accentColor: AdminColors.amber,
                          accentBg: AdminColors.amberBg,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),

                // Visual Collection Cards Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth >= 1060
                        ? 2
                        : 1;
                    return GridView.builder(
                      itemCount: filtered.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        mainAxisExtent: 268,
                      ),
                      itemBuilder: (context, index) {
                        final cat = filtered[index];
                        final catProducts = _productsForCategory(cat);
                        final meta = _metaForCategory(cat);
                        final activeCount = catProducts
                            .where((p) => !p.isDiscontinued)
                            .length;
                        final discCount = catProducts
                            .where((p) => p.isDiscontinued)
                            .length;
                        final stockSum = catProducts.fold<int>(
                            0, (sum, p) => sum + p.stock);
                        final featuredCount = catProducts
                            .where((p) => p.isFeatured && !p.isDiscontinued)
                            .length;
                        final heroImage = cat.image.trim().isNotEmpty
                            ? cat.image.trim()
                            : (catProducts.isNotEmpty
                                ? catProducts.first.thumbnail
                                : '');
                        final isSelected = _selectedCategoryId == cat.id;

                        return AdminCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Hero Sneaker Image for this Collection
                                  Container(
                                    width: 84,
                                    height: 84,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: meta.bg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color:
                                            meta.accent.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: heroImage.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: heroImage,
                                            fit: BoxFit.contain,
                                          )
                                        : Icon(
                                            meta.icon,
                                            color: meta.accent,
                                            size: 32,
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              meta.icon,
                                              size: 17,
                                              color: meta.accent,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                c.localizeCategory(cat.name),
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w800,
                                                  color: AdminColors.ink,
                                                ),
                                              ),
                                            ),
                                            AdminBadge(
                                              label: '${catProducts.length} mẫu giày',
                                              color: meta.accent,
                                              bgColor: meta.bg,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          vi ? meta.taglineVi : meta.taglineEn,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AdminColors.inkSecondary,
                                            height: 1.35,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            AdminBadge(
                                              label: 'Tồn kho: $stockSum đôi',
                                              color: AdminColors.forest,
                                              bgColor: AdminColors.sageSoft,
                                            ),
                                            AdminBadge(
                                              label: 'Đang bán: $activeCount',
                                              color: AdminColors.emerald,
                                              bgColor: AdminColors.emeraldBg,
                                            ),
                                            if (discCount > 0)
                                              AdminBadge(
                                                label: 'Ngừng bán: $discCount',
                                                color: AdminColors.rose,
                                                bgColor: AdminColors.roseBg,
                                              ),
                                            AdminBadge(
                                              label: '🎬 $featuredCount trên Nổi bật',
                                              color: AdminColors.sky,
                                              bgColor: AdminColors.skyBg,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Divider(height: 20),
                              // Mini preview strip of sneakers + Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 38,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount:
                                            catProducts.take(6).length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 6),
                                        itemBuilder: (_, i) {
                                          final p = catProducts[i];
                                          return Tooltip(
                                            message: p.title,
                                            child: InkWell(
                                              onTap: () =>
                                                  showAdminProductAndVideoPreviewDialog(
                                                context,
                                                controller: c,
                                                product: p,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Container(
                                                width: 38,
                                                height: 38,
                                                padding:
                                                    const EdgeInsets.all(3),
                                                decoration: BoxDecoration(
                                                  color:
                                                      AdminColors.surfaceMuted,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: AdminColors.border,
                                                  ),
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
                                  FilledButton.tonalIcon(
                                    onPressed: () {
                                      setState(() {
                                        _selectedCategoryId =
                                            isSelected ? null : cat.id;
                                      });
                                    },
                                    icon: Icon(
                                      isSelected
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Iconsax.eye,
                                      size: 16,
                                    ),
                                    label: Text(
                                      isSelected
                                          ? 'Thu gọn danh sách'
                                          : 'Xem ${catProducts.length} mẫu giày',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: meta.bg,
                                      foregroundColor: meta.accent,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    tooltip: 'Chỉnh sửa danh mục',
                                    onPressed: () =>
                                        _openEditor(existing: cat),
                                    icon: const Icon(
                                      Iconsax.edit_2,
                                      size: 17,
                                      color: AdminColors.forest,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

                // Expanded Product Drawer for the selected category
                if (selectedCat != null) ...[
                  const SizedBox(height: 22),
                  _buildSelectedCategoryProductsSection(selectedCat),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSelectedCategoryProductsSection(CategoryModel cat) {
    final products = _productsForCategory(cat);
    final meta = _metaForCategory(cat);

    return AdminCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(meta.icon, color: meta.accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Danh sách ${products.length} mẫu giày thuộc dòng ${c.localizeCategory(cat.name)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.ink,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => c.selectSection(AdminSection.products),
                icon: const Icon(Iconsax.box, size: 15),
                label: const Text('Mở bảng Kho hàng đầy đủ →'),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedCategoryId = null),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const Divider(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: products.map((p) {
              final price = p.salePrice > 0 ? p.salePrice : p.price;
              final isDisc = p.isDiscontinued;
              return InkWell(
                onTap: () => showAdminProductAndVideoPreviewDialog(
                  context,
                  controller: c,
                  product: p,
                ),
                borderRadius: BorderRadius.circular(14),
                child: Opacity(
                  opacity: isDisc ? 0.55 : 1.0,
                  child: Container(
                    width: 265,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdminColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDisc ? AdminColors.rose : AdminColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
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
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  decoration: isDisc
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${c.formatMoney(price)} • ${p.stock} đôi',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AdminColors.forest,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  AdminBadge(
                                    label: isDisc ? '🚫 Ngừng bán' : 'Đang bán',
                                    color: isDisc
                                        ? AdminColors.rose
                                        : AdminColors.emerald,
                                    bgColor: isDisc
                                        ? AdminColors.roseBg
                                        : AdminColors.emeraldBg,
                                  ),
                                  const Spacer(),
                                  InkWell(
                                    onTap: () => c.toggleProductDiscontinued(
                                        p, !isDisc),
                                    child: Text(
                                      isDisc ? 'Mở lại' : 'Ngừng bán',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isDisc
                                            ? AdminColors.emerald
                                            : AdminColors.rose,
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
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
