import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/common/widgets/product/badges/shop_count_badge.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/screens/cart/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class TCartCounterIcon extends StatelessWidget {
  const TCartCounterIcon({
    super.key,
    this.iconColor,
    this.counterBgColor,
    this.counterTextColor,
    this.onDark = false,
  });

  final Color? iconColor, counterBgColor, counterTextColor;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;
    final dark = onDark || Theme.of(context).brightness == Brightness.dark;
    final resolvedColor =
        iconColor ?? (dark ? Colors.white : const Color(0xFF173E32));
    return Center(
      child: GlassIconButton(
        size: 40,
        iconSize: 20,
        useOwnLayer: true,
        glowColor: Colors.transparent,
        style: GlassButtonStyle.filled,
        settings: shopToolbarGlassSettings(context, onDark: onDark),
        semanticLabel: 'Cart'.tr,
        iconColor: resolvedColor,
        onPressed: () => Get.to(() => const CartScreen()),
        icon: Obx(
          () => SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: ShopCountBadge(
                count: controller.noOfCartItem.value,
                child: Icon(
                  Iconsax.shopping_bag,
                  color: resolvedColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
