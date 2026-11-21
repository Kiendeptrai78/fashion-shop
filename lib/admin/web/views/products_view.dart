import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:fashion_business_app/features/shop/models/brand_model.dart';
import 'package:fashion_business_app/features/shop/models/catalog_search.dart';
import 'package:fashion_business_app/features/shop/models/category_model.dart';
import 'package:fashion_business_app/features/shop/models/product_attribute_model.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/models/product_variation_model.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

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

  List<ProductModel> _filtered(List<ProductModel> all) {
    final q = _query.trim().toLowerCase();
    return all.where((p) {
      if (_brandFilter.isNotEmpty && p.brand?.id != _brandFilter) return false;
      if (_categoryFilter.isNotEmpty && p.categoryId != _categoryFilter) return false;
      if (_onlyLowStock && p.stock > 10) return false;
      if (q.isEmpty) return true;
      return p.title.toLowerCase().contains(q) ||
          (p.brand?.name.toLowerCase().contains(q) ?? false) ||
          p.categoryName.toLowerCase().contains(q);
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Obx(() {
      final all = widget.controller.products.toList();
      final filtered = _filtered(all);
      final brands = widget.controller.brands.toList();
      final categories = widget.controller.categories.toList();

      return SingleChildScrollView(
        padding: EdgeInsets.all(width < 700 ? 16 : 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSectionToolbar(
                  title: 'Quản lý Sản phẩm (${all.length})',
                  subtitle:
                      'Thêm, sửa, xóa giày, quản lý biến thể màu/size, tồn kho và đồng bộ ngay lên app chính.',
                  actions: [
                    AdminPrimaryButton(
                      label: 'Thêm sản phẩm mới',
                      icon: Iconsax.add_circle,
                      onPressed: () => _openProductEditor(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Filter toolbar
                AdminCard(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AdminSearchField(
                        hint: 'Tìm tên sản phẩm, thương hiệu...',
                        onChanged: (v) => setState(() => _query = v),
                        width: 280,
                      ),
                      SizedBox(
                        width: 210,
                        child: DropdownButtonFormField<String>(
                          value: _brandFilter,
                          isExpanded: true,
                          decoration: adminInputDecoration(label: 'Thương hiệu'),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('Tất cả thương hiệu', overflow: TextOverflow.ellipsis),
                            ),
                            ...brands.map(
                              (b) => DropdownMenuItem(
                                value: b.id,
                                child: Text(b.name, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _brandFilter = v ?? ''),
                        ),
                      ),
                      SizedBox(
                        width: 210,
                        child: DropdownButtonFormField<String>(
                          value: _categoryFilter,
                          isExpanded: true,
                          decoration: adminInputDecoration(label: 'Danh mục'),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('Tất cả danh mục', overflow: TextOverflow.ellipsis),
                            ),
                            ...categories.map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _categoryFilter = v ?? ''),
                        ),
                      ),
                      FilterChip(
                        selected: _onlyLowStock,
                        selectedColor: AdminColors.amberBg,
                        checkmarkColor: AdminColors.amber,
                        label: Text(
                          'Sắp hết hàng (${widget.controller.lowStockProducts.length})',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _onlyLowStock ? AdminColors.amber : AdminColors.inkSecondary,
                          ),
                        ),
                        onSelected: (v) => setState(() => _onlyLowStock = v),
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
                          title: 'Không tìm thấy sản phẩm',
                          subtitle: 'Thử điều chỉnh bộ lọc hoặc thêm sản phẩm mới vào kho.',
                          action: AdminPrimaryButton(
                            label: 'Thêm sản phẩm',
                            onPressed: () => _openProductEditor(),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 1020),
                            child: DataTable(
                              headingRowColor:
                                  WidgetStateProperty.all(AdminColors.surfaceMuted),
                              dataRowMinHeight: 66,
                              dataRowMaxHeight: 74,
                              columns: const [
                                DataColumn(label: Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Thương hiệu', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Danh mục', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Giá bán', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Tồn kho', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Biến thể', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Nổi bật', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                              ],
                              rows: filtered.map((product) {
                                final hasSale =
                                    product.salePrice > 0 && product.salePrice < product.price;
                                final lowStock = product.stock <= 10;
                                final variationCount =
                                    product.productVariations?.length ?? 0;
                                return DataRow(
                                  cells: [
                                    DataCell(Row(
                                      children: [
                                        AdminImageThumb(
                                          url: product.thumbnail,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.contain,
                                        ),
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: 220,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: AdminColors.ink,
                                                ),
                                              ),
                                              Text(
                                                product.id,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AdminColors.inkMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )),
                                    DataCell(Text(
                                      product.brand?.name ?? '—',
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                                    )),
                                    DataCell(Text(
                                      product.categoryName.isNotEmpty
                                          ? product.categoryName
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
                                    DataCell(AdminBadge(
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
                                    )),
                                    DataCell(Text(
                                      variationCount > 0 ? '$variationCount biến thể' : 'Đơn lẻ',
                                      style: const TextStyle(fontSize: 12.5, color: AdminColors.inkSecondary),
                                    )),
                                    DataCell(Icon(
                                      product.isFeatured
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      color: product.isFeatured
                                          ? AdminColors.amber
                                          : AdminColors.inkMuted,
                                      size: 20,
                                    )),
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Chỉnh sửa sản phẩm',
                                          onPressed: () =>
                                              _openProductEditor(existing: product),
                                          icon: const Icon(Iconsax.edit_2, size: 18, color: AdminColors.forest),
                                        ),
                                        IconButton(
                                          tooltip: 'Xóa sản phẩm',
                                          onPressed: () async {
                                            final ok = await showAdminConfirmDialog(
                                              context,
                                              title: 'Xóa "${product.title}"?',
                                              message:
                                                  'Sản phẩm sẽ bị xóa khỏi Firestore và không còn hiển thị trên ứng dụng khách hàng.',
                                            );
                                            if (ok) {
                                              await widget.controller.deleteProduct(product);
                                            }
                                          },
                                          icon: const Icon(Iconsax.trash, size: 18, color: AdminColors.rose),
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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _salePriceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _thumbCtrl;
  late final TextEditingController _galleryCtrl;
  late final TextEditingController _colorsCtrl;
  late final TextEditingController _sizesCtrl;

  String _selectedBrandId = '';
  String _selectedCategoryId = '';
  bool _isFeatured = true;
  bool _isVariable = true;
  bool _sendNotification = false;
  bool _saving = false;
  late List<ProductVariationModel> _variations;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _priceCtrl = TextEditingController(text: p != null ? p.price.toString() : '120');
    _salePriceCtrl = TextEditingController(text: p != null ? p.salePrice.toString() : '0');
    _stockCtrl = TextEditingController(text: p != null ? p.stock.toString() : '20');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _thumbCtrl = TextEditingController(text: p?.thumbnail ?? '');
    _galleryCtrl = TextEditingController(text: (p?.images ?? []).join('\n'));

    final colorAttr = p?.productAttributes
        ?.where((a) => (a.name ?? '').toLowerCase() == 'color')
        .firstOrNull;
    final sizeAttr = p?.productAttributes
        ?.where((a) => (a.name ?? '').toLowerCase() == 'size')
        .firstOrNull;
    _colorsCtrl = TextEditingController(
      text: (colorAttr?.values ?? ['White', 'Black']).join(', '),
    );
    _sizesCtrl = TextEditingController(
      text: (sizeAttr?.values ?? ['EU 39', 'EU 40', 'EU 41', 'EU 42', 'EU 43']).join(', '),
    );

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
    _thumbCtrl.dispose();
    _galleryCtrl.dispose();
    _colorsCtrl.dispose();
    _sizesCtrl.dispose();
    super.dispose();
  }

  List<String> _parseCsv(String raw) => raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList();

  void _generateVariationsFromAttributes() {
    final colors = _parseCsv(_colorsCtrl.text);
    final sizes = _parseCsv(_sizesCtrl.text);
    final basePrice = double.tryParse(_priceCtrl.text.trim()) ?? 100;
    final baseSale = double.tryParse(_salePriceCtrl.text.trim()) ?? 0;
    final thumb = _thumbCtrl.text.trim();
    final generated = <ProductVariationModel>[];
    var idx = 1;
    for (final color in colors.isEmpty ? ['Default'] : colors) {
      for (final size in sizes.isEmpty ? ['Standard'] : sizes) {
        generated.add(ProductVariationModel(
          id: 'var-$idx',
          image: thumb,
          price: basePrice,
          salePrice: baseSale,
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final brand = widget.controller.brands
        .firstWhereOrNull((b) => b.id == _selectedBrandId);
    final category = widget.controller.categories
        .firstWhereOrNull((c) => c.id == _selectedCategoryId);

    final gallery = _galleryCtrl.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (gallery.isEmpty && _thumbCtrl.text.trim().isNotEmpty) {
      gallery.add(_thumbCtrl.text.trim());
    }

    final colors = _parseCsv(_colorsCtrl.text);
    final sizes = _parseCsv(_sizesCtrl.text);
    final attributes = <ProductAttributeModel>[
      if (colors.isNotEmpty) ProductAttributeModel(name: 'Color', values: colors),
      if (sizes.isNotEmpty) ProductAttributeModel(name: 'Size', values: sizes),
    ];

    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final salePrice = double.tryParse(_salePriceCtrl.text.trim()) ?? 0;
    final computedStock = _isVariable && _variations.isNotEmpty
        ? _variations.fold<int>(0, (sum, v) => sum + v.stock)
        : (int.tryParse(_stockCtrl.text.trim()) ?? 0);

    final model = ProductModel(
      id: widget.existing?.id ?? '',
      title: _titleCtrl.text.trim(),
      stock: computedStock,
      price: price,
      salePrice: salePrice,
      thumbnail: _thumbCtrl.text.trim(),
      images: gallery,
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
    final currentPriceUsd = double.tryParse(_priceCtrl.text.trim()) ?? 0;

    return Dialog(
      backgroundColor: AdminColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 820),
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
                      TextFormField(
                        controller: _titleCtrl,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Vui lòng nhập tên sản phẩm'
                            : null,
                        decoration: adminInputDecoration(
                          label: 'Tên sản phẩm *',
                          hint: 'Ví dụ: Air Force 1 Low',
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: brands.any((b) => b.id == _selectedBrandId)
                                  ? _selectedBrandId
                                  : null,
                              decoration: adminInputDecoration(label: 'Thương hiệu'),
                              items: brands
                                  .map((b) => DropdownMenuItem(
                                        value: b.id,
                                        child: Text(b.name),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedBrandId = v ?? ''),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: categories.any((c) => c.id == _selectedCategoryId)
                                  ? _selectedCategoryId
                                  : null,
                              decoration: adminInputDecoration(label: 'Danh mục'),
                              items: categories
                                  .map((c) => DropdownMenuItem(
                                        value: c.id,
                                        child: Text(c.name),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedCategoryId = v ?? ''),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceCtrl,
                              onChanged: (_) => setState(() {}),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) =>
                                  (double.tryParse((v ?? '').trim()) == null)
                                      ? 'Giá không hợp lệ'
                                      : null,
                              decoration: adminInputDecoration(
                                label: 'Giá gốc (USD) *',
                                hint: '120',
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _salePriceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: adminInputDecoration(
                                label: 'Giá khuyến mãi (USD)',
                                hint: '0 nếu không giảm',
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
                          'Quy đổi VND hiển thị trên app chính: ${formatShopMoney(currentPriceUsd, language: 'vi')} (tỷ giá 1 USD = 25,812 ₫)',
                          style: const TextStyle(fontSize: 11.5, color: AdminColors.forestLight),
                        ),
                      ),
                      const SizedBox(height: 16),

                      AdminImageUploadField(
                        label: 'Ảnh đại diện sản phẩm (Thumbnail)',
                        controller: _thumbCtrl,
                        onUploadBytes: (bytes, name) =>
                            widget.controller.uploadImage(bytes, name, 'Products/Images'),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _galleryCtrl,
                        maxLines: 3,
                        decoration: adminInputDecoration(
                          label: 'Danh sách URL ảnh bộ sưu tập (mỗi dòng 1 link)',
                          hint: 'https://...\nhttps://...',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: adminInputDecoration(
                          label: 'Mô tả sản phẩm',
                          hint: 'Chất liệu, kiểu dáng, hướng dẫn bảo quản...',
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
                              const Text('Sản phẩm nổi bật', style: TextStyle(fontSize: 13)),
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
                              const Text('Có biến thể (Màu / Size)', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                          if (_isNew)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: _sendNotification,
                                  activeColor: AdminColors.forest,
                                  onChanged: (v) => setState(() => _sendNotification = v),
                                ),
                                const Text('Đánh dấu gửi thông báo sản phẩm mới',
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
                                      'Thuộc tính & Biến thể sản phẩm',
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
                                    label: const Text('Tạo biến thể tự động'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _colorsCtrl,
                                      decoration: adminInputDecoration(
                                        label: 'Màu sắc (cách nhau dấu phẩy)',
                                        hint: 'White, Black, Red',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _sizesCtrl,
                                      decoration: adminInputDecoration(
                                        label: 'Kích cỡ (cách nhau dấu phẩy)',
                                        hint: 'EU 39, EU 40, EU 41, EU 42',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
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
                                  constraints: const BoxConstraints(maxHeight: 210),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: _variations.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (_, index) {
                                      final v = _variations[index];
                                      final label = v.attributeValues.entries
                                          .map((e) => '${e.key}: ${e.value}')
                                          .join(' • ');
                                      return ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(label,
                                            style: const TextStyle(
                                                fontSize: 12.5, fontWeight: FontWeight.w600)),
                                        subtitle: Text(
                                          'Giá: \$${v.price} • Sale: \$${v.salePrice} • Kho: ${v.stock}',
                                          style: const TextStyle(fontSize: 11.5),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              tooltip: 'Giảm kho',
                                              icon: const Icon(Icons.remove_circle_outline, size: 18),
                                              onPressed: () => setState(() {
                                                if (v.stock > 0) v.stock -= 1;
                                                _stockCtrl.text = _variations
                                                    .fold<int>(0, (s, e) => s + e.stock)
                                                    .toString();
                                              }),
                                            ),
                                            IconButton(
                                              tooltip: 'Tăng kho',
                                              icon: const Icon(Icons.add_circle_outline, size: 18),
                                              onPressed: () => setState(() {
                                                v.stock += 1;
                                                _stockCtrl.text = _variations
                                                    .fold<int>(0, (s, e) => s + e.stock)
                                                    .toString();
                                              }),
                                            ),
                                            IconButton(
                                              tooltip: 'Xóa biến thể',
                                              icon: const Icon(Iconsax.trash,
                                                  size: 16, color: AdminColors.rose),
                                              onPressed: () => setState(() {
                                                _variations.removeAt(index);
                                                _stockCtrl.text = _variations
                                                    .fold<int>(0, (s, e) => s + e.stock)
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
