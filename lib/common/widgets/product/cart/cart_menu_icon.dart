import 'package:fashion_business_app/common/widgets/product/badges/shop_count_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/screens/cart/cart_screen.dart';

class TCartCounterIcon extends StatelessWidget {
  const TCartCounterIcon({
    super.key,
    this.iconColor,
    this.counterBgColor,
    this.counterTextColor,
  });

  final Color? iconColor, counterBgColor, counterTextColor;

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;
    return IconButton(
      tooltip: 'Cart'.tr,
      onPressed: () => Get.to(() => const CartScreen()),
      icon: Obx(() => ShopCountBadge(count: controller.noOfCartItem.value,
          child: Icon(Iconsax.shopping_bag, color: iconColor))),
    );
  }
}
