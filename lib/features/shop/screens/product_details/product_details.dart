import 'package:fashion_business_app/features/shop/screens/product_reviews/product_review.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/features/shop/controllers/product/images_controller.dart';
import 'package:fashion_business_app/common/widgets/product/cart/cart_menu_icon.dart';
import 'package:fashion_business_app/common/widgets/product/favourite_icon/favourite_icon.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/variation_controller.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/screens/product_details/widgets/product_attributes.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'widgets/bottom_add_to_cart_widget.dart';
import 'widgets/product_detail_image_slider.dart';
import 'widgets/product_meta_data.dart';
import 'widgets/similar_products.dart';

class ProductDetail extends StatefulWidget {
  const ProductDetail({super.key, required this.product});

  final ProductModel product;

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  late ProductModel product;
  final _scroll = ScrollController();
  final _optionsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    product = widget.product;
    _selectProduct();
  }

  void _selectProduct() {
    Get.put(ImageController()).selectedProductImage.value = product.thumbnail;
    final variations = VariationController.instance;
    variations.resetSelectedAttribute();
    final cart = CartController.instance;
    cart.updateAlreadyAddedProductCount(product);
    if (cart.productQuantityInCart.value < 1) cart.productQuantityInCart.value = 1;
    final colors = product.productAttributes?.where((a) => a.name == 'Color').firstOrNull?.values;
    if (colors != null && colors.isNotEmpty) {
      variations.onAttributeSelected(product, 'Color', colors.first);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _openSimilar(ProductModel selected) {
    setState(() => product = selected);
    _selectProduct();
    _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF1A2721) : const Color(0xFFF6F8F4);
    final border = dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5EAE2);

    return Scaffold(
      appBar: TAppbar(
        showBackArrow: true,
        title: ShopText(
          product.brand?.name ?? 'Sneakers',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
        actions: [
          TFavouriteIcon(productId: product.id),
          const TCartCounterIcon(),
        ],
      ),
      bottomNavigationBar: TBottomAddToCart(
        product: product,
        onSelectOptions: () {
          final options = _optionsKey.currentContext;
          if (options != null) {
            Scrollable.ensureVisible(
              options,
              duration: const Duration(milliseconds: 250),
              alignment: 0.1,
            );
          }
        },
      ),
      body: SingleChildScrollView(
        controller: _scroll,
        child: Column(
          children: [
            TProductImageSlider(product: product),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TProductMetaData(product: product),
                  const SizedBox(height: 18),
                  // Trust assurances strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _assurance(context, Iconsax.verify, 'Verified genuine')),
                        Expanded(child: _assurance(context, Iconsax.truck_fast, 'Fast delivery')),
                        Expanded(child: _assurance(context, Iconsax.refresh_circle, 'Easy returns')),
                      ],
                    ),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1)),
                  if (product.productType == ProductType.variable.toString())
                    KeyedSubtree(key: _optionsKey, child: TProductAttribute(product: product)),
                  const SizedBox(height: 24),
                  Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 16),
                      initiallyExpanded: true,
                      title: const ShopText(
                        'About this pair',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ShopText(
                            product.description ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (product.brand != null) _detailChip(context, 'Brand', product.brand!.name, surface, border),
                      if (product.categoryName.isNotEmpty)
                        _detailChip(context, 'Collection', product.categoryName, surface, border),
                      if ((product.productAttributes?.where((a) => a.name == 'Size').firstOrNull?.values ?? [])
                          .isNotEmpty)
                        _detailChip(context, 'Sizing', 'EU', surface, border),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Material(
                    color: surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF283A2E) : const Color(0xFFE7F0EA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.star_rounded, color: Color(0xFFD99A1E), size: 22),
                      ),
                      title: const ShopText(
                        'Customer reviews',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      subtitle: const ShopText('See how this pair feels in everyday life.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Get.to(() => ProductReview(productId: product.id, productTitle: product.title)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SimilarProducts(key: ValueKey(product.id), product: product, onOpen: _openSimilar),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _assurance(BuildContext context, IconData icon, String label) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32)),
        const SizedBox(height: 5),
        ShopText(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _detailChip(BuildContext context, String label, String value, Color bg, Color border) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ShopText(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).hintColor)),
            const SizedBox(height: 3),
            ShopText(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          ],
        ),
      );
}
