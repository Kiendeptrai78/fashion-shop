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
    return Scaffold(
      appBar: TAppbar(title: const Text('Shopping bag', style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.6)),
          showBackArrow: Navigator.of(context).canPop()),
      body: Obx(() {
        if (controller.cartItems.isEmpty) return const ShoppingEmptyState(wishlist: false);
        return ListView(padding: const EdgeInsets.fromLTRB(24, 12, 24, 24), children: [
          Row(children: [
            Expanded(child: Text('${controller.noOfCartItem.value} ${controller.noOfCartItem.value == 1 ? 'item' : 'items'} in your bag',
                style: theme.textTheme.bodySmall)),
            TextButton(onPressed: exploreSneakers, child: const Text('Keep shopping')),
          ]),
          const SizedBox(height: 12),
          for (final item in controller.cartItems) ...[
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TRoundedImage(imageUrl: item.image ?? '', isNetworkImage: true,
                  width: 100, height: 110, padding: const EdgeInsets.all(4)),
              const SizedBox(width: 18),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text((item.brandName ?? '').toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1, color: theme.hintColor)),
                const SizedBox(height: 5),
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 8),
                Text((item.selectedVariation?.entries ?? []).map((e) => '${e.key}: ${e.value}').join(' · '),
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                Text('\$${(item.price * item.quantity).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 10),
                Row(children: [
                  Container(decoration: BoxDecoration(border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(tooltip: 'Decrease quantity', icon: const Icon(Icons.remove, size: 17),
                          onPressed: () => controller.removeOneFromCart(item)),
                      Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      IconButton(tooltip: 'Increase quantity', icon: const Icon(Icons.add, size: 17),
                          onPressed: () => controller.addOneToCart(item)),
                    ])),
                  const Spacer(),
                  IconButton(tooltip: 'Remove item', icon: const Icon(Iconsax.trash, size: 19),
                      onPressed: () => controller.removeFromCartDialog(controller.cartItems.indexOf(item))),
                ]),
              ])),
            ]),
            const Padding(padding: EdgeInsets.symmetric(vertical: 22), child: Divider(height: 1)),
          ],
          const Text('One step closer to your next pair.', style: TextStyle(fontSize: 13)),
        ]);
      }),
      bottomNavigationBar: Obx(() => controller.cartItems.isEmpty ? const SizedBox.shrink()
          : SafeArea(top: false, child: Container(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15)))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Subtotal', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('\$${controller.totalCartPrice.value.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              ]),
              const SizedBox(height: 6),
              Align(alignment: Alignment.centerLeft, child: Text('Shipping and taxes calculated at checkout',
                  style: theme.textTheme.bodySmall)),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () => Get.to(() => const CheckoutScreen()),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Continue to checkout'), SizedBox(width: 12), Icon(Icons.arrow_forward, size: 18),
                ]))),
            ]),
          ))),
    );
  }
}
