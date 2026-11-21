import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/screens/checkout/checkout.dart';
import 'package:fashion_business_app/features/shop/screens/widgets/shopping_empty_state.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: TAppbar(
        title: const ShopText(
          'Shopping bag',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.6),
        ),
        showBackArrow: Navigator.of(context).canPop(),
      ),
      body: Obx(() {
        if (controller.cartItems.isEmpty) return const ShoppingEmptyState(wishlist: false);
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            Row(children: [
              Expanded(
                child: ShopText(
                  '${controller.noOfCartItem.value} ${controller.noOfCartItem.value == 1 ? 'item' : 'items'} in your bag',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              TextButton(onPressed: exploreSneakers, child: const ShopText('Keep shopping')),
            ]),
            const SizedBox(height: 10),
            for (final item in controller.cartItems) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF1A2721) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE6EAE3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF22342B) : const Color(0xFFF3F4EF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TRoundedImage(
                        imageUrl: item.image ?? '',
                        isNetworkImage: true,
                        width: 96,
                        height: 106,
                        borderRadius: 14,
                        padding: const EdgeInsets.all(6),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((item.brandName ?? '').isNotEmpty) ...[
                            ShopText(
                              (item.brandName ?? '').toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: dark ? const Color(0xFFB6CEB4) : const Color(0xFF4F6B5D),
                              ),
                            ),
                            const SizedBox(height: 3),
                          ],
                          ShopText(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, height: 1.25),
                          ),
                          if ((item.selectedVariation?.entries ?? []).isNotEmpty) ...[
                            const SizedBox(height: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: dark ? const Color(0xFF24372E) : const Color(0xFFF2F5F0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ShopText(
                                (item.selectedVariation?.entries ?? [])
                                    .map((e) => '${e.key}: ${e.value}')
                                    .join(' · '),
                                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          ShopText(
                            formatShopMoney(item.price * item.quantity, language: lang),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(children: [
                            Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: dark ? const Color(0xFF22342B) : const Color(0xFFF6F7F3),
                                border: Border.all(
                                  color: dark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFDFE5DD),
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                    tooltip: 'Decrease quantity'.tr,
                                    icon: const Icon(Icons.remove, size: 16),
                                    onPressed: () => controller.removeOneFromCart(item),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: ShopText(
                                      '${item.quantity}',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                    ),
                                  ),
                                  IconButton(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                    tooltip: 'Increase quantity'.tr,
                                    icon: const Icon(Icons.add, size: 16),
                                    onPressed: () => controller.addOneToCart(item),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Remove item'.tr,
                              icon: Icon(Iconsax.trash, size: 19, color: theme.hintColor),
                              onPressed: () =>
                                  controller.removeFromCartDialog(controller.cartItems.indexOf(item)),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 6),
            Center(
              child: ShopText(
                'One step closer to your next pair.',
                style: TextStyle(fontSize: 12.5, color: theme.hintColor),
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(() => controller.cartItems.isEmpty
          ? const SizedBox.shrink()
          : Container(
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
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const ShopText('Subtotal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          ShopText(
                            formatShopMoney(controller.totalCartPrice.value, language: lang),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ShopText(
                          'Shipping and taxes calculated at checkout',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => Get.to(() => const CheckoutScreen()),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ShopText('Continue to checkout'),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )),
    );
  }
}
