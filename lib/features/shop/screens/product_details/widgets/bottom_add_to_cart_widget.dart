import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/product_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/variation_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/screens/checkout/checkout.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class TBottomAddToCart extends StatelessWidget {
  const TBottomAddToCart({super.key, required this.product, required this.onSelectOptions});

  final ProductModel product;
  final VoidCallback onSelectOptions;

  @override
  Widget build(BuildContext context) {
    final cart = CartController.instance;
    final variations = VariationController.instance;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final lang = Localizations.localeOf(context).languageCode;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF14211B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5EAE3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.25 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Obx(() {
          final variable = product.productType == ProductType.variable.toString();
          final selected = variations.selectedVariation.value;
          final ready = !variable || selected.id.isNotEmpty;
          final stock = variable ? selected.stock : product.stock;
          final quantity = cart.productQuantityInCart.value < 1 ? 1 : cart.productQuantityInCart.value;
          final price = variable && ready
              ? variations.getVariationPrice()
              : ProductController.instance.getProductPrice(product);
          final soldOut = ready && stock < 1;

          void handleAddToCart() {
            if (!ready) {
              onSelectOptions();
              return;
            }
            if (soldOut) return;
            cart.addToCart(product);
          }

          void handleBuyNow() {
            if (!ready) {
              onSelectOptions();
              return;
            }
            if (soldOut) return;
            final added = cart.addToCart(product, showToast: false);
            if (added) {
              Get.to(() => const CheckoutScreen());
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF1E3028) : const Color(0xFFF5F7F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: dark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFDFE5DD),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                          tooltip: 'Decrease quantity'.tr,
                          onPressed: ready && quantity > 1 ? () => cart.productQuantityInCart.value-- : null,
                          icon: const Icon(Icons.remove, size: 16),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: ShopText(
                            '$quantity',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                          tooltip: 'Increase quantity'.tr,
                          onPressed: ready && quantity < stock ? () => cart.productQuantityInCart.value++ : null,
                          icon: const Icon(Icons.add, size: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatShopPrice(price, language: lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (!ready || soldOut)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: !ready ? onSelectOptions : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size.fromHeight(48),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: ShopText(
                      !ready ? 'Select size' : 'Sold out',
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: handleAddToCart,
                          icon: const Icon(Iconsax.shopping_bag, size: 18),
                          label: const ShopText(
                            'Add to bag',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
                            side: BorderSide(
                              color: dark ? const Color(0xFFDDEABB).withValues(alpha: 0.45) : const Color(0xFF173E32),
                              width: 1.4,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: handleBuyNow,
                          icon: const Icon(Iconsax.flash_1, size: 18),
                          label: const ShopText(
                            'Buy now',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF173E32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          );
        }),
      ),
    );
  }
}
