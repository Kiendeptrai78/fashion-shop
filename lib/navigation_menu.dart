import 'package:fashion_business_app/features/personalization/services/account_activity.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/common/widgets/product/badges/shop_count_badge.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/favourite_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/features/personalization/screens/settings/setting_screen.dart';
import 'package:fashion_business_app/features/shop/screens/home/home_screen.dart';
import 'package:fashion_business_app/features/shop/screens/reels/velora_reels_screen.dart';
import 'package:fashion_business_app/features/shop/screens/wishlist/wishlish_screen.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';

import 'features/shop/screens/cart/cart_screen.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());
    WidgetsBinding.instance.addPostFrameCallback((_) => AccountActivity.current?.handleInitialPush());
    final darkMode = THelperFunctions.isDarkMode(context);
    final activeColor = darkMode ? const Color(0xFFDDEABB) : const Color(0xFF173E32);
    final inactiveColor = darkMode ? Colors.white60 : const Color(0xFF6B7770);

    return Scaffold(
      bottomNavigationBar: Obx(() {
        final cartCount = CartController.instance.noOfCartItem.value;
        final favCount = FavouritesController.instance.favourites.values.where((saved) => saved).length;
        final profileCount = (AccountActivity.current?.activeOrders ?? 0) +
            (AccountActivity.current?.unread ?? 0) +
            (Get.isRegistered<CustomerBenefits>() ? CustomerBenefits.instance.newCouponCount : 0);

        return DecoratedBox(
          decoration: BoxDecoration(
            color: darkMode ? const Color(0xFF111C17) : Colors.white,
            border: Border(
              top: BorderSide(
                color: darkMode ? Colors.white.withValues(alpha: 0.08) : const Color(0xFF173E32).withValues(alpha: 0.08),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: darkMode ? 0.25 : 0.05),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? activeColor : inactiveColor,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return IconThemeData(
                  size: 23,
                  color: selected ? activeColor : inactiveColor,
                );
              }),
            ),
            child: NavigationBar(
              height: 74,
              elevation: 0,
              selectedIndex: controller.selectedIndex.value,
              onDestinationSelected: (index) => controller.selectedIndex.value = index,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              indicatorColor: darkMode ? const Color(0xFF1F382E) : const Color(0xFFE7F0EA),
              indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Iconsax.home),
                  selectedIcon: const Icon(Iconsax.home_15),
                  label: 'Home'.tr,
                ),
                NavigationDestination(
                  icon: const Icon(Iconsax.magic_star),
                  selectedIcon: const Icon(Icons.auto_awesome_rounded),
                  label: 'Featured'.tr,
                ),
                NavigationDestination(
                  icon: ShopCountBadge(count: cartCount, child: const Icon(Iconsax.shopping_bag)),
                  selectedIcon: ShopCountBadge(count: cartCount, child: const Icon(Iconsax.shopping_bag5)),
                  label: 'Cart'.tr,
                ),
                NavigationDestination(
                  icon: ShopCountBadge(count: favCount, child: const Icon(Iconsax.heart)),
                  selectedIcon: ShopCountBadge(count: favCount, child: const Icon(Iconsax.heart5)),
                  label: 'Wishlist'.tr,
                ),
                NavigationDestination(
                  icon: ShopCountBadge(count: profileCount, child: const Icon(Iconsax.user)),
                  selectedIcon: ShopCountBadge(count: profileCount, child: const Icon(Iconsax.user_octagon)),
                  label: 'Profile'.tr,
                ),
              ],
            ),
          ),
        );
      }),
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;
  final screens = [
    const HomeScreen(),
    const VeloraReelsScreen(),
    const CartScreen(),
    const WishList(),
    const SettingScreen()
  ];
}
