import 'package:fashion_business_app/features/shop/screens/product_reviews/product_review.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/features/shop/controllers/product/images_controller.dart';
import 'package:fashion_business_app/common/widgets/product/favourite_icon/favourite_icon.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/variation_controller.dart';
import 'package:flutter/material.dart';
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
  Widget build(BuildContext context) => Scaffold(
    appBar: TAppbar(showBackArrow: true,
        title: ShopText(product.brand?.name ?? 'Sneakers', style: const TextStyle(fontSize: 15)),
        actions: [TFavouriteIcon(productId: product.id)]),
    bottomNavigationBar: TBottomAddToCart(product: product, onSelectOptions: () {
      final options = _optionsKey.currentContext;
      if (options != null) Scrollable.ensureVisible(options,
          duration: const Duration(milliseconds: 250), alignment: 0.1);
    }),
    body: SingleChildScrollView(controller: _scroll, child: Column(children: [
      TProductImageSlider(product: product),
      Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 32), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          TProductMetaData(product: product),
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(height: 1)),
          if (product.productType == ProductType.variable.toString())
            KeyedSubtree(key: _optionsKey, child: TProductAttribute(product: product)),
          const SizedBox(height: 28),
          Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(tilePadding: EdgeInsets.zero, childrenPadding: const EdgeInsets.only(bottom: 20),
              initiallyExpanded: true,
              title: const ShopText('About this pair', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              children: [Align(alignment: Alignment.centerLeft, child: ShopText(product.description ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7)))],
            )),
          const Divider(height: 32),
          Wrap(spacing: 24, runSpacing: 16, children: [
            if (product.brand != null) _detail('Brand', product.brand!.name),
            if (product.categoryName.isNotEmpty) _detail('Collection', product.categoryName),
            if ((product.productAttributes?.where((a) => a.name == 'Size').firstOrNull?.values ?? []).isNotEmpty)
              _detail('Sizing', 'EU'),
          ]),
          const Divider(height: 32),
          ListTile(contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.star_outline_rounded, color: Theme.of(context).colorScheme.primary),
            title: const ShopText('Customer reviews', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const ShopText('See how this pair feels in everyday life.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => ProductReview(productId: product.id, productTitle: product.title)),
          ),
          const Divider(height: 32),
          SimilarProducts(key: ValueKey(product.id), product: product, onOpen: _openSimilar),
        ],
      )),
    ])),
  );

  Widget _detail(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    ShopText(label, style: Theme.of(context).textTheme.bodySmall),
    const SizedBox(height: 5),
    ShopText(value, style: const TextStyle(fontWeight: FontWeight.w600)),
  ]);
}
