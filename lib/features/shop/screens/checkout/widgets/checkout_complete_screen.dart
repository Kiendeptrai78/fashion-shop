import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/features/shop/screens/order/order.dart';
import 'package:fashion_business_app/navigation_menu.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class CheckoutCompleteScreen extends StatelessWidget {
  const CheckoutCompleteScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Padding(
    padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.check_circle_outline_rounded, size: 88, color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 30),
      const ShopText('Your order is in.', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
      const SizedBox(height: 14),
      const ShopText('Follow its progress in My Orders.', textAlign: TextAlign.center),
      const SizedBox(height: 32),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Get.off(() => const OrderScreen()),
          child: const ShopText('My Orders'))),
      TextButton(onPressed: () => Get.offAll(() => const NavigationMenu()), child: const ShopText('Keep shopping')),
    ]),
  )));
}
