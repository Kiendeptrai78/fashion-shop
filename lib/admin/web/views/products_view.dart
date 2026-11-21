import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:fashion_business_app/features/shop/models/catalog_search.dart';
import 'package:fashion_business_app/features/shop/models/product_attribute_model.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/models/product_variation_model.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
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
                  title: 'Quản lý Sản phẩm & Kho hàng (${all.length})',
                  subtitle:
                      'Nhập bổ sung tồn kho theo từng mẫu / size, theo dõi phiếu nhập hàng hoặc thêm mẫu giày mới.',
                  actions: [
                    OutlinedButton.icon(
                      onPressed: _openStockHistoryDialog,
                      icon: const Icon(Iconsax.receipt_text, size: 17),
                      label: Text('Lịch sử nhập kho (${widget.controller.stockReceipts.length})'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminColors.forest,
                        side: const BorderSide(color: AdminColors.borderStrong),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                      ),
                    ),
                    AdminPrimaryButton(
                      label: 'Nhập hàng vào kho',
                      icon: Iconsax.box_add,
                      onPressed: all.isEmpty ? null : () => _openRestockDialog(),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openProductEditor(),
                      icon: const Icon(Iconsax.add_circle, size: 17),
                      label: const Text('Thêm mẫu mới'),
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
                                        Tooltip(
                                          message: 'Nhập thêm tồn kho',
                                          child: FilledButton.tonalIcon(
                                            onPressed: () => _openRestockDialog(product: product),
                                            icon: const Icon(Iconsax.box_add, size: 15),
                                            label: const Text('Nhập kho', style: TextStyle(fontSize: 12)),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: AdminColors.sageSoft,
                                              foregroundColor: AdminColors.forest,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              minimumSize: const Size(0, 32),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
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
                      const SizedBox(height: 20),

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
                              isExpanded: true,
                              decoration: adminInputDecoration(label: 'Thương hiệu'),
                              items: brands
                                  .map((b) => DropdownMenuItem(
                                        value: b.id,
                                        child: Text(b.name,
                                            overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedBrandId = v ?? ''),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: categories.any((c) => c.id == _selectedCategoryId)
                                  ? _selectedCategoryId
                                  : null,
                              isExpanded: true,
                              decoration: adminInputDecoration(label: 'Danh mục'),
                              items: categories
                                  .map((c) => DropdownMenuItem(
                                        value: c.id,
                                        child: Text(c.name,
                                            overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedCategoryId = v ?? ''),
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
                                      label: Text(color,
                                          style: const TextStyle(fontSize: 12)),
                                      selected: _selectedColors.contains(color),
                                      selectedColor: AdminColors.sageSoft,
                                      checkmarkColor: AdminColors.forest,
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
                                      label: Text(size,
                                          style: const TextStyle(fontSize: 12)),
                                      selected: _selectedSizes.contains(size),
                                      selectedColor: AdminColors.sageSoft,
                                      checkmarkColor: AdminColors.forest,
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
  final _singleAddCtrl = TextEditingController(text: '10');
  final _supplierCtrl = TextEditingController();
  final _unitCostCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final Map<String, TextEditingController> _varCtrls = {};
  bool _notifyBackInStock = false;
  bool _saving = false;

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

  void _fillAllVariations(int delta) {
    setState(() {
      for (final ctrl in _varCtrls.values) {
        final cur = int.tryParse(ctrl.text.trim()) ?? 0;
        ctrl.text = '${cur + delta}';
      }
    });
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
    final added = _totalAdded;
    final newStock = _product.stock + added;

    return Dialog(
      backgroundColor: AdminColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
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
                          'Cộng dồn tồn kho trực tiếp vào sản phẩm hiện có và lưu lịch sử phiếu nhập.',
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
                    DropdownButtonFormField<String>(
                      value: allProducts.any((p) => p.id == _product.id) ? _product.id : null,
                      isExpanded: true,
                      decoration: adminInputDecoration(label: 'Chọn sản phẩm cần nhập thêm'),
                      items: allProducts
                          .map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  '${p.title} (Tồn hiện tại: ${p.stock} đôi)',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (id) {
                        final picked = allProducts.firstWhereOrNull((p) => p.id == id);
                        if (picked != null) setState(() => _selectProduct(picked));
                      },
                    ),
                    const SizedBox(height: 16),

                    // Summary banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AdminColors.sageSoft.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AdminColors.forest.withValues(alpha: 0.16)),
                      ),
                      child: Row(
                        children: [
                          AdminImageThumb(
                            url: _product.thumbnail,
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _product.title,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                ),
                                const SizedBox(height: 3),
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
                        ],
                      ),
                    ),
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
                            onPressed: () => _fillAllVariations(5),
                            child: const Text('+5 tất cả size'),
                          ),
                          TextButton(
                            onPressed: () => _fillAllVariations(10),
                            child: const Text('+10 tất cả size'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: Column(
                          children: _product.productVariations!.map((v) {
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
                              hint: 'VD: Kho tổng Nike VN',
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

class _StockHistoryDialog extends StatelessWidget {
  const _StockHistoryDialog({required this.controller});
  final AdminWebController controller;

  @override
  Widget build(BuildContext context) {
    final receipts = controller.stockReceipts;
    return Dialog(
      backgroundColor: AdminColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 720),
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
            Expanded(
              child: receipts.isEmpty
                  ? const AdminEmptyState(
                      icon: Iconsax.box_add,
                      title: 'Chưa có phiếu nhập kho nào',
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
