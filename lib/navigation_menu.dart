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
import 'package:fashion_business_app/features/shop/screens/wishlist/wishlish_screen.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';

import 'features/shop/screens/cart/cart_screen.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());
    WidgetsBinding.instance.addPostFrameCallback((_) => AccountActivity.current?.handleInitialPush());
    final darkMode = THelperFunctions.isDarkMode(context);
    return Scaffold(
      bottomNavigationBar: Obx(
            () => NavigationBar(
          height: 80,
          elevation: 0,
          selectedIndex: controller.selectedIndex.value,
          onDestinationSelected: (index) => controller.selectedIndex.value = index,
          backgroundColor: darkMode ? TColors.black : TColors.white,
          indicatorColor: darkMode ? TColors.white.withOpacity(0.1) : TColors.black.withOpacity(0.1),
          destinations: [
            NavigationDestination(icon: Icon(Iconsax.home), label: 'Home'.tr),
            NavigationDestination(icon: ShopCountBadge(count: CartController.instance.noOfCartItem.value,
                child: const Icon(Iconsax.shopping_bag)), label: 'Cart'.tr),
            NavigationDestination(icon: ShopCountBadge(
                count: FavouritesController.instance.favourites.values.where((saved) => saved).length,
                child: const Icon(Iconsax.heart)), label: 'Wishlist'.tr),
            NavigationDestination(icon: ShopCountBadge(
                count: (AccountActivity.current?.activeOrders ?? 0) + (AccountActivity.current?.unread ?? 0)
                    + (Get.isRegistered<CustomerBenefits>() ? CustomerBenefits.instance.newCouponCount : 0),
                child: const Icon(Iconsax.user)), label: 'Profile'.tr),
          ],
        ),
      ),
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;
  final screens = [
    const HomeScreen(),
    const CartScreen(),
    const WishList(),
    const SettingScreen()
  ];
}
