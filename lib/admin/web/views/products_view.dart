import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:fashion_business_app/features/shop/models/catalog_search.dart';
import 'package:fashion_business_app/features/shop/models/product_attribute_model.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/models/product_variation_model.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class AdminProductsView extends StatefulWidget {
  const AdminProductsView({super.key, required this.controller});

  final AdminWebController controller;

  @override
  State<AdminProductsView> createState() => _AdminProductsViewState();
}

class _AdminProductsViewState extends State<AdminProductsView> {
  String _query = '';
  String _brandFilter = '';
  String _categoryFilter = '';
  bool _onlyLowStock = false;
  String _sellingTab = 'all'; // 'all' | 'active' | 'lowStock' | 'discontinued'

  String _canonicalCatKey(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.contains('running') || s.contains('chạy bộ')) return 'running';
    if (s.contains('lifestyle') || s.contains('hằng ngày')) return 'lifestyle';
    if (s.contains('training') || s.contains('tập luyện')) return 'training';
    if (s.contains('basketball') || s.contains('bóng rổ')) return 'basketball';
    if (s.contains('trail') || s.contains('địa hình')) return 'trail';
    return s;
  }

  bool _matchesCategory(ProductModel p, String filterId) {
    if (filterId.isEmpty) return true;
    if (p.categoryId == filterId) return true;
    final fk = _canonicalCatKey(filterId);
    return _canonicalCatKey(p.categoryId) == fk ||
        _canonicalCatKey(p.categoryName) == fk;
  }

  List<ProductModel> _filtered(List<ProductModel> all) {
    final q = _query.trim().toLowerCase();
    return all.where((p) {
      if (_sellingTab == 'active' && p.isDiscontinued) return false;
      if (_sellingTab == 'discontinued' && !p.isDiscontinued) return false;
      if ((_sellingTab == 'lowStock' || _onlyLowStock) && p.stock > 10) {
        return false;
      }
      if (_brandFilter.isNotEmpty && p.brand?.id != _brandFilter) return false;
      if (_categoryFilter.isNotEmpty && !_matchesCategory(p, _categoryFilter)) {
        return false;
      }
      if (q.isEmpty) return true;
      return p.title.toLowerCase().contains(q) ||
          p.id.toLowerCase().contains(q) ||
          (p.brand?.name.toLowerCase().contains(q) ?? false) ||
          p.categoryName.toLowerCase().contains(q) ||
          widget.controller.localizeCategory(p.categoryName).toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openProductEditor({ProductModel? existing}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProductEditorDialog(
        controller: widget.controller,
        existing: existing,
      ),
    );
  }

  Future<void> _openRestockDialog({ProductModel? product}) async {
    if (widget.controller.products.isEmpty) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RestockProductDialog(
        controller: widget.controller,
        initialProduct: product ?? widget.controller.products.first,
      ),
    );
  }

  Future<void> _openStockHistoryDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _StockHistoryDialog(controller: widget.controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Obx(() {
      final all = widget.controller.products.toList();
      final filtered = _filtered(all);
      final categories = widget.controller.categories.toList();
      final vi = widget.controller.isVi.value;
      final safeCategoryValue =
          categories.any((c) => c.id == _categoryFilter) ? _categoryFilter : '';

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
                      ? 'Quản lý Sản phẩm & Kho hàng (${all.length})'
                      : 'Product & Inventory Management (${all.length})',
                  subtitle: vi
                      ? 'Nhập bổ sung tồn kho theo từng mẫu / size, theo dõi phiếu nhập hàng hoặc thêm mẫu giày mới.'
                      : 'Restock inventory by model & EU size, track stock receipts, or add new VELORA models.',
                  actions: [
                    OutlinedButton.icon(
                      onPressed: _openStockHistoryDialog,
                      icon: const Icon(Iconsax.receipt_text, size: 17),
                      label: Text(
                        vi
                            ? 'Lịch sử nhập kho (${widget.controller.stockReceipts.length})'
                            : 'Stock Receipts (${widget.controller.stockReceipts.length})',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminColors.forest,
                        side: const BorderSide(color: AdminColors.borderStrong),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                      ),
                    ),
                    AdminPrimaryButton(
                      label: vi ? 'Nhập hàng vào kho' : 'Restock Inventory',
                      icon: Iconsax.box_add,
                      onPressed: all.isEmpty ? null : () => _openRestockDialog(),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openProductEditor(),
                      icon: const Icon(Iconsax.add_circle, size: 17),
                      label: Text(vi ? 'Thêm mẫu mới' : 'Add New Model'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminColors.ink,
                        side: const BorderSide(color: AdminColors.borderStrong),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Filter toolbar
                AdminCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selling Status Tabs (Đang mở bán vs Sản phẩm Ngừng bán)
                      Builder(builder: (_) {
                        final activeCount =
                            all.where((p) => !p.isDiscontinued).length;
                        final discontinuedCount =
                            all.where((p) => p.isDiscontinued).length;
                        final lowCount =
                            widget.controller.lowStockProducts.length;
                        Widget buildStatusChip({
                          required String label,
                          required bool selected,
                          required Color activeColor,
                          required Color idleBg,
                          required Color idleText,
                          required VoidCallback onTap,
                        }) {
                          return InkWell(
                            onTap: onTap,
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: selected ? activeColor : idleBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? activeColor
                                      : activeColor.withValues(alpha: 0.32),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (selected) ...[
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: selected ? Colors.white : idleText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            buildStatusChip(
                              label: vi
                                  ? 'Tất cả kho (${all.length})'
                                  : 'All Inventory (${all.length})',
                              selected: _sellingTab == 'all',
                              activeColor: AdminColors.forest,
                              idleBg: AdminColors.surfaceMuted,
                              idleText: AdminColors.ink,
                              onTap: () => setState(() {
                                _sellingTab = 'all';
                                _onlyLowStock = false;
                              }),
                            ),
                            buildStatusChip(
                              label: vi
                                  ? '✅ Đang mở bán ($activeCount)'
                                  : '✅ Active ($activeCount)',
                              selected: _sellingTab == 'active',
                              activeColor: const Color(0xFF15803D),
                              idleBg: AdminColors.emeraldBg,
                              idleText: const Color(0xFF166534),
                              onTap: () => setState(() {
                                _sellingTab = 'active';
                                _onlyLowStock = false;
                              }),
                            ),
                            buildStatusChip(
                              label: vi
                                  ? '⚠️ Sắp hết hàng ($lowCount)'
                                  : '⚠️ Low Stock ($lowCount)',
                              selected: _sellingTab == 'lowStock' || _onlyLowStock,
                              activeColor: const Color(0xFFD97706),
                              idleBg: AdminColors.amberBg,
                              idleText: const Color(0xFFB45309),
                              onTap: () => setState(() {
                                _sellingTab = 'lowStock';
                                _onlyLowStock = true;
                              }),
                            ),
                            buildStatusChip(
                              label: vi
                                  ? '🚫 Sản phẩm Ngừng bán ($discontinuedCount)'
                                  : '🚫 Discontinued ($discontinuedCount)',
                              selected: _sellingTab == 'discontinued',
                              activeColor: const Color(0xFFDC2626),
                              idleBg: AdminColors.roseBg,
                              idleText: const Color(0xFFBE123C),
                              onTap: () => setState(() {
                                _sellingTab = 'discontinued';
                                _onlyLowStock = false;
                              }),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          AdminSearchField(
                            hint: vi
                                ? 'Tìm tên mẫu giày VELORA, danh mục'
                                : 'Search VELORA model, SKU, or category',
                            onChanged: (v) => setState(() => _query = v),
                            width: 330,
                          ),
                          SizedBox(
                            width: 240,
                            child: DropdownButtonFormField<String>(
                              value: safeCategoryValue,
                              isExpanded: true,
                              decoration: adminInputDecoration(
                                label: vi ? 'Danh mục giày thể thao' : 'Athletic Category',
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: '',
                                  child: Text(
                                    vi
                                        ? 'Tất cả danh mục (${all.length})'
                                        : 'All categories (${all.length})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                ...categories.map((c) {
                                  final count =
                                      all.where((p) => _matchesCategory(p, c.id)).length;
                                  final label = widget.controller.localizeCategory(c.name);
                                  return DropdownMenuItem(
                                    value: c.id,
                                    child: Text(
                                      '$label ($count)',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (v) => setState(() => _categoryFilter = v ?? ''),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: Text(
                                vi ? 'Tất cả (${all.length})' : 'All (${all.length})',
                              ),
                              selected: safeCategoryValue.isEmpty,
                              onSelected: (_) => setState(() => _categoryFilter = ''),
                            ),
                            ...categories.map((c) {
                              final count =
                                  all.where((p) => _matchesCategory(p, c.id)).length;
                              final label = widget.controller.localizeCategory(c.name);
                              return Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: ChoiceChip(
                                  label: Text('$label ($count)'),
                                  selected: safeCategoryValue == c.id,
                                  onSelected: (_) =>
                                      setState(() => _categoryFilter = c.id),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Product Table
                AdminCard(
                  padding: EdgeInsets.zero,
                  child: filtered.isEmpty
                      ? AdminEmptyState(
                          icon: Iconsax.box,
                          title: vi ? 'Không tìm thấy sản phẩm' : 'No products found',
                          subtitle: vi
                              ? 'Thử điều chỉnh bộ lọc hoặc thêm sản phẩm mới vào kho.'
                              : 'Try adjusting your category filter or search query.',
                          action: AdminPrimaryButton(
                            label: vi ? 'Thêm sản phẩm' : 'Add Product',
                            onPressed: () => _openProductEditor(),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 1020),
                            child: DataTable(
                              columnSpacing: 16,
                              horizontalMargin: 16,
                              headingRowColor:
                                  WidgetStateProperty.all(AdminColors.surfaceMuted),
                              dataRowMinHeight: 68,
                              dataRowMaxHeight: 76,
                              columns: [
                                DataColumn(label: Text(vi ? 'Sản phẩm VELORA' : 'VELORA Product', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text(vi ? 'Danh mục' : 'Category', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text(vi ? 'Giá bán' : 'Price', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text(vi ? 'Tồn kho & Nhập nhanh (từ bên ngoài)' : 'Stock & Quick Restock', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text(vi ? 'Trạng thái bán' : 'Status', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text(vi ? 'Thao tác' : 'Actions', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                              ],
                              rows: filtered.map((product) {
                                final hasSale =
                                    product.salePrice > 0 && product.salePrice < product.price;
                                final lowStock = product.stock <= 10;
                                final isDisc = product.isDiscontinued;
                                return DataRow(
                                  cells: [
                                    DataCell(Opacity(
                                      opacity: isDisc ? 0.55 : 1.0,
                                      child: Row(
                                        children: [
                                          AdminImageThumb(
                                            url: product.thumbnail,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.contain,
                                          ),
                                          const SizedBox(width: 10),
                                          SizedBox(
                                            width: 200,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.title,
                                                  softWrap: true,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13,
                                                    color: AdminColors.ink,
                                                    decoration: isDisc
                                                        ? TextDecoration.lineThrough
                                                        : null,
                                                  ),
                                                ),
                                                Text(
                                                  product.id,
                                                  softWrap: true,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AdminColors.inkMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                    DataCell(Text(
                                      product.categoryName.isNotEmpty
                                          ? widget.controller.localizeCategory(product.categoryName)
                                          : '—',
                                      style: const TextStyle(fontSize: 12.5, color: AdminColors.inkSecondary),
                                    )),
                                    DataCell(Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.controller.formatMoney(
                                              hasSale ? product.salePrice : product.price),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                            color: AdminColors.forest,
                                          ),
                                        ),
                                        if (hasSale)
                                          Text(
                                            widget.controller.formatMoney(product.price),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AdminColors.inkMuted,
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                      ],
                                    )),
                                    // Tồn kho & Ô điền số lượng nhập nhanh trực tiếp từ bên ngoài!
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AdminBadge(
                                          label: product.stock <= 0
                                              ? 'Hết hàng'
                                              : '${product.stock} đôi',
                                          color: product.stock <= 0
                                              ? AdminColors.rose
                                              : lowStock
                                                  ? AdminColors.amber
                                                  : AdminColors.emerald,
                                          bgColor: product.stock <= 0
                                              ? AdminColors.roseBg
                                              : lowStock
                                                  ? AdminColors.amberBg
                                                  : AdminColors.emeraldBg,
                                        ),
                                        const SizedBox(width: 8),
                                        _InlineQuickRestockBox(
                                          key: ValueKey('quick-restock-${product.id}'),
                                          product: product,
                                          controller: widget.controller,
                                        ),
                                      ],
                                    )),
                                    // Trạng thái bán (Đang mở bán vs Đã ngừng bán)
                                    DataCell(AdminBadge(
                                      label: isDisc
                                          ? (vi ? '🚫 Đã ngừng bán' : '🚫 Discontinued')
                                          : (vi ? '✅ Đang mở bán' : '✅ Active'),
                                      color: isDisc
                                          ? AdminColors.rose
                                          : AdminColors.emerald,
                                      bgColor: isDisc
                                          ? AdminColors.roseBg
                                          : AdminColors.emeraldBg,
                                    )),
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Tooltip(
                                          message: 'Nhập kho chi tiết theo từng size EU',
                                          child: FilledButton.tonalIcon(
                                            onPressed: () => _openRestockDialog(product: product),
                                            icon: const Icon(Iconsax.box_add, size: 14),
                                            label: Text(vi ? 'Theo size' : 'By Size', style: const TextStyle(fontSize: 11.5)),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: AdminColors.sageSoft,
                                              foregroundColor: AdminColors.forest,
                                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                              minimumSize: const Size(0, 30),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        OutlinedButton.icon(
                                          onPressed: () => widget.controller
                                              .toggleProductDiscontinued(
                                                  product, !isDisc),
                                          icon: Icon(
                                            isDisc
                                                ? Iconsax.refresh
                                                : Icons.block_rounded,
                                            size: 13,
                                          ),
                                          label: Text(
                                            isDisc
                                                ? (vi ? 'Mở bán lại' : 'Re-list')
                                                : (vi ? 'Ngừng bán' : 'Discontinue'),
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: isDisc
                                                ? AdminColors.emerald
                                                : AdminColors.rose,
                                            side: BorderSide(
                                              color: (isDisc
                                                      ? AdminColors.emerald
                                                      : AdminColors.rose)
                                                  .withValues(alpha: 0.4),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                              vertical: 5,
                                            ),
                                            minimumSize: const Size(0, 30),
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          tooltip: 'Chỉnh sửa sản phẩm',
                                          onPressed: () =>
                                              _openProductEditor(existing: product),
                                          icon: const Icon(Iconsax.edit_2, size: 17, color: AdminColors.forest),
                                        ),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          tooltip: 'Xóa hẳn khỏi kho',
                                          onPressed: () async {
                                            final ok = await showAdminConfirmDialog(
                                              context,
                                              title: 'Xóa "${product.title}"?',
                                              message:
                                                  'Mẹo: Bạn có thể bấm nút "Ngừng bán" để ẩn sản phẩm trên cửa hàng mà vẫn giữ lịch sử đơn cũ. Nếu chọn Xóa, sản phẩm sẽ bị xóa khỏi kho.',
                                            );
                                            if (ok) {
                                              await widget.controller.deleteProduct(product);
                                            }
                                          },
                                          icon: const Icon(Iconsax.trash, size: 17, color: AdminColors.rose),
                                        ),
                                      ],
                                    )),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _ProductEditorDialog extends StatefulWidget {
  const _ProductEditorDialog({
    required this.controller,
    this.existing,
  });

  final AdminWebController controller;
  final ProductModel? existing;

  @override
  State<_ProductEditorDialog> createState() => _ProductEditorDialogState();
}

class _ProductEditorDialogState extends State<_ProductEditorDialog> {
  static const _presetColors = [
    'White',
    'Black',
    'Grey',
    'Red',
    'Blue',
    'Navy',
    'Green',
    'Beige',
    'Brown',
    'Pink',
  ];
  static const _presetSizes = [
    'EU 36',
    'EU 37',
    'EU 38',
    'EU 39',
    'EU 40',
    'EU 41',
    'EU 42',
    'EU 43',
    'EU 44',
    'EU 45',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _salePriceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _descCtrl;
  final _customColorCtrl = TextEditingController();

  late List<String> _images;
  late List<String> _videos;
  late String _thumbnailUrl;
  late List<String> _selectedColors;
  late List<String> _selectedSizes;
  late bool _inputInVnd;

  String _selectedBrandId = '';
  String _selectedCategoryId = '';
  bool _isFeatured = true;
  bool _isVariable = true;
  bool _sendNotification = true;
  bool _saving = false;
  bool _uploadingVideos = false;
  late List<ProductVariationModel> _variations;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _inputInVnd = widget.controller.showVnd.value;

    _titleCtrl = TextEditingController(text: p?.title ?? '');
    final initialPriceUsd = p?.price ?? 100.0;
    final initialSaleUsd = p?.salePrice ?? 0.0;
    _priceCtrl = TextEditingController(
      text: _inputInVnd
          ? (initialPriceUsd * usdToVnd).round().toString()
          : initialPriceUsd.toStringAsFixed(initialPriceUsd % 1 == 0 ? 0 : 2),
    );
    _salePriceCtrl = TextEditingController(
      text: initialSaleUsd <= 0
          ? ''
          : _inputInVnd
              ? (initialSaleUsd * usdToVnd).round().toString()
              : initialSaleUsd.toStringAsFixed(initialSaleUsd % 1 == 0 ? 0 : 2),
    );
    _stockCtrl = TextEditingController(text: p != null ? p.stock.toString() : '20');
    _descCtrl = TextEditingController(text: p?.description ?? '');

    final initialImages = <String>[
      if ((p?.thumbnail ?? '').trim().isNotEmpty) p!.thumbnail.trim(),
      for (final img in p?.images ?? const <String>[])
        if (img.trim().isNotEmpty) img.trim(),
    ].toSet().toList();
    _images = initialImages;
    _videos = [
      for (final v in p?.videos ?? const <String>[])
        if (v.trim().isNotEmpty) v.trim(),
    ];
    _thumbnailUrl = (p?.thumbnail ?? '').trim().isNotEmpty
        ? p!.thumbnail.trim()
        : (initialImages.isNotEmpty ? initialImages.first : '');

    final colorAttr = p?.productAttributes
        ?.where((a) => (a.name ?? '').toLowerCase() == 'color')
        .firstOrNull;
    final sizeAttr = p?.productAttributes
        ?.where((a) => (a.name ?? '').toLowerCase() == 'size')
        .firstOrNull;
    _selectedColors = List<String>.from(colorAttr?.values ?? ['White', 'Black']);
    _selectedSizes =
        List<String>.from(sizeAttr?.values ?? ['EU 39', 'EU 40', 'EU 41', 'EU 42']);

    _selectedBrandId = p?.brand?.id ??
        (widget.controller.brands.isNotEmpty ? widget.controller.brands.first.id : '');
    _selectedCategoryId = p?.categoryId ??
        (widget.controller.categories.isNotEmpty
            ? widget.controller.categories.first.id
            : '');
    _isFeatured = p?.isFeatured ?? true;
    _isVariable = p == null
        ? true
        : p.productType == ProductType.variable.toString() ||
            (p.productVariations?.isNotEmpty ?? false);
    _variations = (p?.productVariations ?? [])
        .map((v) => ProductVariationModel(
              id: v.id,
              image: v.image,
              description: v.description,
              price: v.price,
              salePrice: v.salePrice,
              stock: v.stock,
              attributeValues: Map<String, String>.from(v.attributeValues),
            ))
        .toList();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _salePriceCtrl.dispose();
    _stockCtrl.dispose();
    _descCtrl.dispose();
    _customColorCtrl.dispose();
    super.dispose();
  }

  double _parsePriceToUsd(String raw) {
    final cleaned = raw.trim().replaceAll(',', '').replaceAll('.', '');
    if (_inputInVnd) {
      final vnd = double.tryParse(cleaned) ?? 0;
      return double.parse((vnd / usdToVnd).toStringAsFixed(2));
    }
    return double.tryParse(raw.trim().replaceAll(',', '')) ?? 0;
  }

  void _addCustomColor() {
    final color = _customColorCtrl.text.trim();
    if (color.isEmpty) return;
    if (!_selectedColors.contains(color)) {
      setState(() => _selectedColors.add(color));
    }
    _customColorCtrl.clear();
  }

  void _generateVariationsFromAttributes() {
    final colors = _selectedColors.isEmpty ? ['Default'] : _selectedColors;
    final sizes = _selectedSizes.isEmpty ? ['Standard'] : _selectedSizes;
    final basePriceUsd = _parsePriceToUsd(_priceCtrl.text);
    final baseSaleUsd = _parsePriceToUsd(_salePriceCtrl.text);
    final generated = <ProductVariationModel>[];
    var idx = 1;
    for (var cIdx = 0; cIdx < colors.length; cIdx++) {
      final color = colors[cIdx];
      final colorImage = _images.isNotEmpty
          ? _images[cIdx % _images.length]
          : _thumbnailUrl;
      for (final size in sizes) {
        generated.add(ProductVariationModel(
          id: 'var-$idx',
          image: colorImage,
          price: basePriceUsd,
          salePrice: baseSaleUsd,
          stock: 10,
          attributeValues: {'Color': color, 'Size': size},
        ));
        idx++;
      }
    }
    setState(() {
      _variations = generated;
      _stockCtrl.text =
          _variations.fold<int>(0, (s, v) => s + v.stock).toString();
    });
  }

  Future<void> _pickAndUploadVideos() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      setState(() => _uploadingVideos = true);
      for (final f in result.files) {
        final bytes = f.bytes;
        if (bytes == null || bytes.isEmpty) continue;
        final url = await widget.controller.uploadVideo(
          bytes,
          f.name,
          'Products/Videos',
        );
        if (url.trim().isNotEmpty && !_videos.contains(url.trim())) {
          setState(() => _videos.add(url.trim()));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải video lên Cloudinary: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingVideos = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng tải lên ít nhất 1 hình ảnh cho sản phẩm.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final brand = widget.controller.brands
        .firstWhereOrNull((b) => b.id == _selectedBrandId);
    final category = widget.controller.categories
        .firstWhereOrNull((c) => c.id == _selectedCategoryId);

    final effectiveThumb =
        _thumbnailUrl.isNotEmpty ? _thumbnailUrl : _images.first;
    final attributes = <ProductAttributeModel>[
      if (_selectedColors.isNotEmpty)
        ProductAttributeModel(name: 'Color', values: _selectedColors),
      if (_selectedSizes.isNotEmpty)
        ProductAttributeModel(name: 'Size', values: _selectedSizes),
    ];

    final priceUsd = _parsePriceToUsd(_priceCtrl.text);
    final salePriceUsd = _parsePriceToUsd(_salePriceCtrl.text);
    final computedStock = _isVariable && _variations.isNotEmpty
        ? _variations.fold<int>(0, (sum, v) => sum + v.stock)
        : (int.tryParse(_stockCtrl.text.trim()) ?? 0);

    final model = ProductModel(
      id: widget.existing?.id ?? '',
      title: _titleCtrl.text.trim(),
      stock: computedStock,
      price: priceUsd,
      salePrice: salePriceUsd,
      thumbnail: effectiveThumb,
      images: _images,
      videos: _videos,
      description: _descCtrl.text.trim(),
      productType: _isVariable
          ? ProductType.variable.toString()
          : ProductType.single.toString(),
      isFeatured: _isFeatured,
      brand: brand,
      categoryId: category?.id ?? widget.existing?.categoryId ?? '',
      categoryName: category?.name ?? widget.existing?.categoryName ?? '',
      catalogId: widget.existing?.catalogId.isNotEmpty == true
          ? widget.existing!.catalogId
          : sneakerCatalogId,
      productAttributes: _isVariable ? attributes : [],
      productVariations: _isVariable ? _variations : [],
    );

    final ok = await widget.controller.saveProduct(
      model,
      isNew: _isNew,
      sendNotification: _isNew && _sendNotification,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final brands = widget.controller.brands;
    final categories = widget.controller.categories;
    final previewPriceUsd = _parsePriceToUsd(_priceCtrl.text);
    final allColors = {..._presetColors, ..._selectedColors}.toList();

    return Dialog(
      backgroundColor: AdminColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840, maxHeight: 840),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 16, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AdminColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isNew ? 'Thêm sản phẩm mới' : 'Chỉnh sửa: ${widget.existing!.title}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            // Form body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Visual multi-image gallery uploader (first and clearest!)
                      AdminMultiImageUploader(
                        images: _images,
                        thumbnailUrl: _thumbnailUrl,
                        onChanged: (nextImages, nextThumb) {
                          setState(() {
                            _images = nextImages;
                            _thumbnailUrl = nextThumb;
                          });
                        },
                        onUploadBytes: (bytes, name) => widget.controller
                            .uploadImage(bytes, name, 'Products/Images'),
                      ),
                      const SizedBox(height: 16),

                      // Multi-video promo uploader (for TikTok-style VELORA Reels feed)
                      Container(
                        padding: const EdgeInsets.all(14),
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
                                const Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: AdminColors.forest,
                                  size: 19,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Video quảng cáo sản phẩm (${_videos.length} video — hiển thị trên VELORA Reels kiểu TikTok)',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AdminColors.ink,
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _uploadingVideos ? null : _pickAndUploadVideos,
                                  icon: _uploadingVideos
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Iconsax.video_add, size: 16),
                                  label: Text(
                                    _uploadingVideos
                                        ? 'Đang tải lên...'
                                        : 'Thêm 1 hoặc nhiều Video (MP4)',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            if (_videos.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(_videos.length, (vIdx) {
                                  final vUrl = _videos[vIdx];
                                  final fileName = vUrl.split('/').last;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AdminColors.border),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.videocam_rounded,
                                          color: AdminColors.forest,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 190),
                                          child: Text(
                                            'Video #${vIdx + 1}: $fileName',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: () => setState(() => _videos.removeAt(vIdx)),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 16,
                                            color: AdminColors.rose,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _titleCtrl,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Vui lòng nhập tên sản phẩm'
                            : null,
                        decoration: adminInputDecoration(
                          label: 'Tên mẫu giày VELORA *',
                          hint: 'Ví dụ: VELORA AeroPulse R2',
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: categories.any((c) => c.id == _selectedCategoryId)
                            ? _selectedCategoryId
                            : null,
                        isExpanded: true,
                        decoration: adminInputDecoration(label: 'Danh mục giày thể thao'),
                        items: categories
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCategoryId = v ?? ''),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceCtrl,
                              onChanged: (_) => setState(() {}),
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              validator: (v) => _parsePriceToUsd(v ?? '') <= 0
                                  ? 'Nhập giá lớn hơn 0'
                                  : null,
                              decoration: adminInputDecoration(
                                label: _inputInVnd
                                    ? 'Giá gốc (VNĐ) *'
                                    : 'Giá gốc (USD) *',
                                hint: _inputInVnd ? '2500000' : '120',
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _salePriceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: adminInputDecoration(
                                label: _inputInVnd
                                    ? 'Giá giảm (VNĐ)'
                                    : 'Giá giảm (USD)',
                                hint: 'Bỏ trống nếu không giảm',
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _stockCtrl,
                              keyboardType: TextInputType.number,
                              decoration: adminInputDecoration(
                                label: 'Tổng tồn kho',
                                hint: '20',
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _inputInVnd
                              ? 'Giá hiển thị: ${formatShopMoney(previewPriceUsd, language: 'vi')} (≈ ${formatShopMoney(previewPriceUsd, language: 'en')})'
                              : 'Quy đổi VNĐ trên app: ${formatShopMoney(previewPriceUsd, language: 'vi')}',
                          style: const TextStyle(
                              fontSize: 11.5, color: AdminColors.forestLight),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: adminInputDecoration(
                          label: 'Mô tả sản phẩm',
                          hint: 'Chất liệu, kiểu dáng, cảm giác mang, hướng dẫn bảo quản...',
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Toggles
                      Wrap(
                        spacing: 24,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: _isFeatured,
                                activeColor: AdminColors.forest,
                                onChanged: (v) => setState(() => _isFeatured = v),
                              ),
                              const Text('Sản phẩm nổi bật',
                                  style: TextStyle(fontSize: 13)),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: _isVariable,
                                activeColor: AdminColors.forest,
                                onChanged: (v) => setState(() => _isVariable = v),
                              ),
                              const Text('Có biến thể (Màu / Size)',
                                  style: TextStyle(fontSize: 13)),
                            ],
                          ),
                          if (_isNew)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: _sendNotification,
                                  activeColor: AdminColors.forest,
                                  onChanged: (v) =>
                                      setState(() => _sendNotification = v),
                                ),
                                const Text('Thông báo khách thích danh mục này',
                                    style: TextStyle(fontSize: 13)),
                              ],
                            ),
                        ],
                      ),

                      if (_isVariable) ...[
                        const SizedBox(height: 16),
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
                                  const Expanded(
                                    child: Text(
                                      'Chọn Màu sắc & Kích cỡ (chạm để bật/tắt)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AdminColors.ink,
                                      ),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: _generateVariationsFromAttributes,
                                    icon: const Icon(Iconsax.magicpen, size: 15),
                                    label: const Text('Tạo bảng biến thể'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Màu sắc',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AdminColors.inkSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  for (final color in allColors)
                                    FilterChip(
                                      label: Text(
                                        color,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _selectedColors.contains(color)
                                              ? Colors.white
                                              : AdminColors.ink,
                                        ),
                                      ),
                                      selected: _selectedColors.contains(color),
                                      selectedColor: AdminColors.forest,
                                      checkmarkColor: Colors.white,
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            _selectedColors.add(color);
                                          } else {
                                            _selectedColors.remove(color);
                                          }
                                        });
                                      },
                                    ),
                                  SizedBox(
                                    width: 150,
                                    child: TextField(
                                      controller: _customColorCtrl,
                                      onSubmitted: (_) => _addCustomColor(),
                                      style: const TextStyle(fontSize: 12),
                                      decoration: InputDecoration(
                                        hintText: '+ Thêm màu...',
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 8),
                                        suffixIcon: IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(Icons.add_rounded,
                                              size: 16),
                                          onPressed: _addCustomColor,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Kích cỡ (Size)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AdminColors.inkSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final size in _presetSizes)
                                    FilterChip(
                                      label: Text(
                                        size,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _selectedSizes.contains(size)
                                              ? Colors.white
                                              : AdminColors.ink,
                                        ),
                                      ),
                                      selected: _selectedSizes.contains(size),
                                      selectedColor: AdminColors.forest,
                                      checkmarkColor: Colors.white,
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            _selectedSizes.add(size);
                                          } else {
                                            _selectedSizes.remove(size);
                                          }
                                        });
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Hiện có ${_variations.length} biến thể • Tổng tồn kho: ${_variations.fold<int>(0, (s, v) => s + v.stock)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AdminColors.inkSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_variations.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: _variations.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (_, index) {
                                      final v = _variations[index];
                                      final label = v.attributeValues.entries
                                          .map((e) => '${e.key}: ${e.value}')
                                          .join(' • ');
                                      return ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        leading: AdminImageThumb(
                                          url: v.image,
                                          width: 34,
                                          height: 34,
                                          borderRadius: 7,
                                          fit: BoxFit.contain,
                                        ),
                                        title: Text(label,
                                            style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600)),
                                        subtitle: Text(
                                          'Giá: ${widget.controller.formatMoney(v.price)} • Kho: ${v.stock}',
                                          style: const TextStyle(fontSize: 11.5),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              tooltip: 'Giảm kho',
                                              icon: const Icon(
                                                  Icons.remove_circle_outline,
                                                  size: 18),
                                              onPressed: () => setState(() {
                                                if (v.stock > 0) v.stock -= 1;
                                                _stockCtrl.text = _variations
                                                    .fold<int>(
                                                        0, (s, e) => s + e.stock)
                                                    .toString();
                                              }),
                                            ),
                                            IconButton(
                                              tooltip: 'Tăng kho',
                                              icon: const Icon(
                                                  Icons.add_circle_outline,
                                                  size: 18),
                                              onPressed: () => setState(() {
                                                v.stock += 1;
                                                _stockCtrl.text = _variations
                                                    .fold<int>(
                                                        0, (s, e) => s + e.stock)
                                                    .toString();
                                              }),
                                            ),
                                            IconButton(
                                              tooltip: 'Xóa biến thể',
                                              icon: const Icon(Iconsax.trash,
                                                  size: 16,
                                                  color: AdminColors.rose),
                                              onPressed: () => setState(() {
                                                _variations.removeAt(index);
                                                _stockCtrl.text = _variations
                                                    .fold<int>(
                                                        0, (s, e) => s + e.stock)
                                                    .toString();
                                              }),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Footer actions
            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AdminColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 12),
                  AdminPrimaryButton(
                    label: _isNew ? 'Tạo sản phẩm' : 'Lưu thay đổi',
                    icon: Iconsax.tick_circle,
                    loading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestockProductDialog extends StatefulWidget {
  const _RestockProductDialog({
    required this.controller,
    required this.initialProduct,
  });

  final AdminWebController controller;
  final ProductModel initialProduct;

  @override
  State<_RestockProductDialog> createState() => _RestockProductDialogState();
}

class _RestockProductDialogState extends State<_RestockProductDialog> {
  late ProductModel _product;
  final _productSearchCtrl = TextEditingController();
  final _variationSearchCtrl = TextEditingController();
  final _singleAddCtrl = TextEditingController(text: '10');
  final _supplierCtrl = TextEditingController();
  final _unitCostCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final Map<String, TextEditingController> _varCtrls = {};
  String _stockFilter = 'all'; // 'all' | 'low' | categoryId
  bool _notifyBackInStock = false;
  bool _saving = false;
  bool _showProductPicker = true;

  @override
  void initState() {
    super.initState();
    _selectProduct(widget.initialProduct);
  }

  void _selectProduct(ProductModel p) {
    for (final c in _varCtrls.values) {
      c.dispose();
    }
    _varCtrls.clear();
    _product = p;
    _notifyBackInStock = p.stock <= 5;
    for (final v in (p.productVariations ?? const <ProductVariationModel>[])) {
      _varCtrls[v.id] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _productSearchCtrl.dispose();
    _variationSearchCtrl.dispose();
    _singleAddCtrl.dispose();
    _supplierCtrl.dispose();
    _unitCostCtrl.dispose();
    _noteCtrl.dispose();
    for (final c in _varCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _hasVariations =>
      _product.productVariations != null && _product.productVariations!.isNotEmpty;

  int get _totalAdded {
    if (_hasVariations) {
      return _varCtrls.values.fold<int>(
        0,
        (sum, c) => sum + (int.tryParse(c.text.trim()) ?? 0).clamp(0, 99999),
      );
    }
    return (int.tryParse(_singleAddCtrl.text.trim()) ?? 0).clamp(0, 99999);
  }

  void _fillAllVariations(int delta, {List<ProductVariationModel>? subset}) {
    setState(() {
      final targets = subset != null
          ? subset.map((v) => _varCtrls[v.id]).whereType<TextEditingController>()
          : _varCtrls.values;
      for (final ctrl in targets) {
        final cur = int.tryParse(ctrl.text.trim()) ?? 0;
        ctrl.text = '${(cur + delta).clamp(0, 99999)}';
      }
    });
  }

  void _resetAllVariations() {
    setState(() {
      for (final ctrl in _varCtrls.values) {
        ctrl.text = '0';
      }
    });
  }

  String _categoryLabel(ProductModel p) {
    if (p.categoryName.isNotEmpty) return p.categoryName;
    return widget.controller.categories
            .firstWhereOrNull((c) => c.id == p.categoryId)
            ?.name ??
        'Giày thể thao VELORA';
  }

  List<ProductModel> _filterProducts(List<ProductModel> allProducts) {
    final q = _productSearchCtrl.text.trim().toLowerCase();
    return allProducts.where((p) {
      if (_stockFilter == 'low' && p.stock > 15) return false;
      if (_stockFilter != 'all' &&
          _stockFilter != 'low' &&
          p.categoryId != _stockFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      final catName = _categoryLabel(p).toLowerCase();
      return p.title.toLowerCase().contains(q) ||
          p.id.toLowerCase().contains(q) ||
          catName.contains(q);
    }).toList();
  }

  Future<void> _submit() async {
    final added = _totalAdded;
    if (added <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số lượng hàng bổ sung (> 0).')),
      );
      return;
    }
    setState(() => _saving = true);
    final deltas = <String, int>{};
    if (_hasVariations) {
      _varCtrls.forEach((id, ctrl) {
        final v = int.tryParse(ctrl.text.trim()) ?? 0;
        if (v > 0) deltas[id] = v;
      });
    }
    final ok = await widget.controller.restockProduct(
      product: _product,
      totalAdded: added,
      variationDeltas: deltas,
      unitCostUsd: double.tryParse(_unitCostCtrl.text.trim()) ?? 0,
      supplier: _supplierCtrl.text.trim(),
      note: _noteCtrl.text.trim(),
      notifyBackInStock: _notifyBackInStock,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = widget.controller.products;
    final filteredProducts = _filterProducts(allProducts);
    final lowStockCount = allProducts.where((p) => p.stock <= 15).length;
    final categories = widget.controller.categories;
    final added = _totalAdded;
    final newStock = _product.stock + added;

    final varQuery = _variationSearchCtrl.text.trim().toLowerCase();
    final filteredVariations = (_product.productVariations ?? const <ProductVariationModel>[])
        .where((v) {
      if (varQuery.isEmpty) return true;
      final label = v.attributeValues.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(' ')
          .toLowerCase();
      return label.contains(varQuery) || v.id.toLowerCase().contains(varQuery);
    }).toList();

    return Dialog(
      backgroundColor: AdminColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 860),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 16, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AdminColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AdminColors.sageSoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Iconsax.box_add, color: AdminColors.forest, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phiếu Nhập hàng / Bổ sung tồn kho',
                          style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Tìm kiếm nhanh mẫu giày, lọc theo danh mục hoặc tồn kho thấp để nhập hàng.',
                          style: TextStyle(fontSize: 12, color: AdminColors.inkSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selected product summary card + toggle picker button
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AdminColors.sageSoft.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AdminColors.forest.withValues(alpha: 0.22)),
                      ),
                      child: Row(
                        children: [
                          AdminImageThumb(
                            url: _product.thumbnail,
                            width: 52,
                            height: 52,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const AdminBadge(
                                      label: 'ĐANG CHỌN NHẬP KHO',
                                      color: AdminColors.forest,
                                      bgColor: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _categoryLabel(_product),
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: AdminColors.inkSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _product.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                    color: AdminColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tồn kho: ${_product.stock} đôi  →  $newStock đôi (+$added)',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AdminColors.forest,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                setState(() => _showProductPicker = !_showProductPicker),
                            icon: Icon(
                              _showProductPicker
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Iconsax.search_normal_1,
                              size: 16,
                            ),
                            label: Text(_showProductPicker ? 'Thu gọn' : 'Đổi sản phẩm'),
                          ),
                        ],
                      ),
                    ),

                    if (_showProductPicker) ...[
                      const SizedBox(height: 14),
                      // Search box + quick filter chips
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AdminColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _productSearchCtrl,
                              onChanged: (_) => setState(() {}),
                              decoration: adminInputDecoration(
                                label: 'Tìm kiếm sản phẩm cần nhập kho',
                                hint: 'Nhập tên giày, mã sản phẩm hoặc danh mục (VD: AeroPulse, GTX, Chạy bộ)...',
                                prefixIcon: const Icon(Iconsax.search_normal_1, size: 18),
                                suffixIcon: _productSearchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 18),
                                        onPressed: () {
                                          _productSearchCtrl.clear();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ChoiceChip(
                                    label: Text('Tất cả (${allProducts.length})'),
                                    selected: _stockFilter == 'all',
                                    onSelected: (_) =>
                                        setState(() => _stockFilter = 'all'),
                                  ),
                                  const SizedBox(width: 6),
                                  ChoiceChip(
                                    label: Text('Tồn thấp ≤15 ($lowStockCount)'),
                                    selected: _stockFilter == 'low',
                                    onSelected: (_) =>
                                        setState(() => _stockFilter = 'low'),
                                  ),
                                  ...categories.map((cat) {
                                    final count = allProducts
                                        .where((p) => p.categoryId == cat.id)
                                        .length;
                                    if (count == 0) return const SizedBox.shrink();
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: ChoiceChip(
                                        label: Text('${cat.name} ($count)'),
                                        selected: _stockFilter == cat.id,
                                        onSelected: (_) =>
                                            setState(() => _stockFilter = cat.id),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 195),
                              child: filteredProducts.isEmpty
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(vertical: 22),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'Không tìm thấy mẫu giày nào khớp từ khóa.',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: AdminColors.inkMuted,
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      itemCount: filteredProducts.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 6),
                                      itemBuilder: (_, idx) {
                                        final item = filteredProducts[idx];
                                        final isSelected = item.id == _product.id;
                                        final isLow = item.stock <= 15;
                                        return InkWell(
                                          borderRadius: BorderRadius.circular(10),
                                          onTap: () => setState(() {
                                            _selectProduct(item);
                                          }),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AdminColors.forest.withValues(alpha: 0.09)
                                                  : Colors.white,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: isSelected
                                                    ? AdminColors.forest
                                                    : AdminColors.border,
                                                width: isSelected ? 1.5 : 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                AdminImageThumb(
                                                  url: item.thumbnail,
                                                  width: 38,
                                                  height: 38,
                                                  fit: BoxFit.contain,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        item.title,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: isSelected
                                                              ? FontWeight.w700
                                                              : FontWeight.w600,
                                                          color: AdminColors.ink,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${_categoryLabel(item)} • Mã: ${item.id}',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AdminColors.inkMuted,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                AdminBadge(
                                                  label: 'Tồn: ${item.stock} đôi',
                                                  color: isLow
                                                      ? AdminColors.amber
                                                      : AdminColors.emerald,
                                                  bgColor: isLow
                                                      ? AdminColors.amberBg
                                                      : AdminColors.emeraldBg,
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  isSelected
                                                      ? Icons.check_circle_rounded
                                                      : Icons.radio_button_unchecked_rounded,
                                                  size: 18,
                                                  color: isSelected
                                                      ? AdminColors.forest
                                                      : AdminColors.inkMuted,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),

                    if (_hasVariations) ...[
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Nhập số lượng theo từng Màu / Size',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                _fillAllVariations(5, subset: filteredVariations),
                            child: const Text('+5 size đang lọc'),
                          ),
                          TextButton(
                            onPressed: () =>
                                _fillAllVariations(10, subset: filteredVariations),
                            child: const Text('+10 size đang lọc'),
                          ),
                          TextButton(
                            onPressed: _resetAllVariations,
                            child: const Text('Đặt lại 0'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if ((_product.productVariations?.length ?? 0) > 4) ...[
                        TextField(
                          controller: _variationSearchCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: adminInputDecoration(
                            label: 'Lọc nhanh Size hoặc Màu (VD: 41, 42, White...)',
                            prefixIcon: const Icon(Iconsax.search_normal_1, size: 16),
                            suffixIcon: _variationSearchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16),
                                    onPressed: () {
                                      _variationSearchCtrl.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: Column(
                          children: filteredVariations.map((v) {
                            final ctrl = _varCtrls[v.id]!;
                            final label = v.attributeValues.entries
                                .map((e) => '${e.key}: ${e.value}')
                                .join(' • ');
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: AdminColors.border)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          label.isNotEmpty ? label : 'Biến thể #${v.id}',
                                          style: const TextStyle(
                                              fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          'Hiện còn: ${v.stock} đôi',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: v.stock <= 2
                                                ? AdminColors.rose
                                                : AdminColors.inkMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 110,
                                    child: TextField(
                                      controller: ctrl,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                      decoration: adminInputDecoration(label: '+ Nhập thêm'),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: _singleAddCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: adminInputDecoration(label: 'Số lượng nhập thêm (đôi) *'),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [5, 10, 20, 50].map((n) {
                          return ActionChip(
                            label: Text('+$n đôi'),
                            onPressed: () {
                              final cur = int.tryParse(_singleAddCtrl.text.trim()) ?? 0;
                              setState(() => _singleAddCtrl.text = '${cur + n}');
                            },
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _supplierCtrl,
                            decoration: adminInputDecoration(
                              label: 'Nhà cung cấp / Nguồn hàng',
                              hint: 'VD: Xưởng sản xuất VELORA Bình Dương',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _unitCostCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: adminInputDecoration(
                              label: 'Giá nhập tham khảo (USD/đôi)',
                              hint: 'VD: 65',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 2,
                      decoration: adminInputDecoration(
                        label: 'Ghi chú lô nhập',
                        hint: 'VD: Lô hàng bổ sung cuối tháng 11, đã kiểm QC',
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AdminColors.forest,
                      title: const Text(
                        'Gửi thông báo "Hàng đã về kho" cho khách quan tâm',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Tự động gửi tới khách thích danh mục hoặc từng hỏi AI về dòng giày này.',
                        style: TextStyle(fontSize: 11.5, color: AdminColors.inkMuted),
                      ),
                      value: _notifyBackInStock,
                      onChanged: (v) => setState(() => _notifyBackInStock = v),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AdminColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 10),
                  AdminPrimaryButton(
                    label: 'Xác nhận nhập +$added đôi',
                    icon: Iconsax.tick_circle,
                    loading: _saving,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockHistoryDialog extends StatefulWidget {
  const _StockHistoryDialog({required this.controller});
  final AdminWebController controller;

  @override
  State<_StockHistoryDialog> createState() => _StockHistoryDialogState();
}

class _StockHistoryDialogState extends State<_StockHistoryDialog> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchCtrl.text.trim().toLowerCase();
    final receipts = widget.controller.stockReceipts.where((r) {
      if (q.isEmpty) return true;
      return r.productTitle.toLowerCase().contains(q) ||
          r.productId.toLowerCase().contains(q) ||
          r.supplier.toLowerCase().contains(q) ||
          r.note.toLowerCase().contains(q);
    }).toList();

    return Dialog(
      backgroundColor: AdminColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 740),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 16, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AdminColors.border)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Lịch sử Phiếu nhập kho',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: adminInputDecoration(
                  label: 'Tìm kiếm lịch sử phiếu nhập',
                  hint: 'Nhập tên mẫu giày, nhà cung cấp hoặc ghi chú lô hàng...',
                  prefixIcon: const Icon(Iconsax.search_normal_1, size: 18),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: receipts.isEmpty
                  ? const AdminEmptyState(
                      icon: Iconsax.box_add,
                      title: 'Không tìm thấy phiếu nhập kho nào',
                      subtitle: 'Mọi lần nhập bổ sung tồn kho sẽ được lưu chi tiết tại đây.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: receipts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final r = receipts[index];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AdminColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AdminColors.border),
                          ),
                          child: Row(
                            children: [
                              AdminImageThumb(
                                url: r.productThumbnail,
                                width: 46,
                                height: 46,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.productTitle,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700, fontSize: 13.5),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Tồn: ${r.previousStock} → ${r.newStock} đôi'
                                      '${r.supplier.isNotEmpty ? ' • NCC: ${r.supplier}' : ''}',
                                      style: const TextStyle(
                                          fontSize: 12, color: AdminColors.inkSecondary),
                                    ),
                                    if (r.note.isNotEmpty)
                                      Text(
                                        r.note,
                                        style: const TextStyle(
                                            fontSize: 11.5, color: AdminColors.inkMuted),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  AdminBadge(
                                    label: '+${r.addedQuantity} đôi',
                                    color: AdminColors.emerald,
                                    bgColor: AdminColors.emeraldBg,
                                  ),
                                  if (r.createdAt != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd/MM/yyyy HH:mm').format(r.createdAt!),
                                      style: const TextStyle(
                                          fontSize: 11, color: AdminColors.inkMuted),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineQuickRestockBox extends StatefulWidget {
  const _InlineQuickRestockBox({
    super.key,
    required this.product,
    required this.controller,
  });

  final ProductModel product;
  final AdminWebController controller;

  @override
  State<_InlineQuickRestockBox> createState() => _InlineQuickRestockBoxState();
}

class _InlineQuickRestockBoxState extends State<_InlineQuickRestockBox> {
  final _qtyCtrl = TextEditingController(text: '20');
  bool _busy = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitQuickRestock() async {
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0 || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.controller.restockProduct(
        product: widget.product,
        totalAdded: qty,
        supplier: 'Tổng Kho VELORA Hà Nội',
        note: 'Nhập nhanh trực tiếp từ bảng sản phẩm (+$qty đôi)',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 58,
          height: 30,
          child: TextField(
            controller: _qtyCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onSubmitted: (_) => _submitQuickRestock(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AdminColors.ink,
            ),
            decoration: InputDecoration(
              hintText: '+SL',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AdminColors.borderStrong),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AdminColors.borderStrong),
              ),
            ),
          ),
        ),
        const SizedBox(width: 5),
        SizedBox(
          height: 30,
          child: FilledButton(
            onPressed: _busy ? null : _submitQuickRestock,
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.forest,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _busy
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    '+ Nhập',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }
}
