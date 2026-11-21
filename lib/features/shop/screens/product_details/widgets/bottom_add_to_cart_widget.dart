import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/product_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/variation_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';

class TBottomAddToCart extends StatelessWidget {
  const TBottomAddToCart({super.key, required this.product, required this.onSelectOptions});

  final ProductModel product;
  final VoidCallback onSelectOptions;

  @override
  Widget build(BuildContext context) {
    final cart = CartController.instance;
    final variations = VariationController.instance;
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12)))),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Obx(() {
          final variable = product.productType == ProductType.variable.toString();
          final selected = variations.selectedVariation.value;
          final ready = !variable || selected.id.isNotEmpty;
          final stock = variable ? selected.stock : product.stock;
          final quantity = cart.productQuantityInCart.value;
          final price = variable && ready ? variations.getVariationPrice()
              : ProductController.instance.getProductPrice(product);
          return Row(children: [
            Container(
              height: 52,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2))),
              child: Row(children: [
                IconButton(tooltip: 'Decrease quantity'.tr,
                    onPressed: ready && quantity > 1 ? () => cart.productQuantityInCart.value-- : null,
                    icon: const Icon(Icons.remove, size: 18)),
                ShopText('${quantity < 1 ? 1 : quantity}', style: theme.textTheme.titleMedium),
                IconButton(tooltip: 'Increase quantity'.tr,
                    onPressed: ready && quantity < stock ? () => cart.productQuantityInCart.value++ : null,
                    icon: const Icon(Icons.add, size: 18)),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: !ready ? onSelectOptions : stock < 1 ? null : () => cart.addToCart(product),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: !ready || stock < 1
                    ? ShopText(!ready ? 'Select size' : 'Sold out')
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const ShopText('Add to bag', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(formatShopPrice(price, language: Localizations.localeOf(context).languageCode),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
              ),
            )),
          ]);
        }),
      ),
    );
  }
}
