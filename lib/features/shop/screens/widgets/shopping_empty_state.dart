import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/navigation_menu.dart';

void exploreSneakers() {
  if (Get.isRegistered<NavigationController>()) {
    Get.find<NavigationController>().selectedIndex.value = 0;
    if (Get.key.currentState?.canPop() ?? false) Get.back();
  } else {
    Get.off(() => const NavigationMenu());
  }
}

class ShoppingEmptyState extends StatelessWidget {
  const ShoppingEmptyState({super.key, required this.wishlist});
  final bool wishlist;

  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 112, height: 112,
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(36)),
        child: Icon(wishlist ? Iconsax.heart : Iconsax.bag_2, size: 44,
            color: Theme.of(context).colorScheme.primary)),
      const SizedBox(height: 28),
      ShopText(wishlist ? 'Keep your favorites close.' : 'Your next pair awaits.',
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 25,
              fontWeight: FontWeight.w600, letterSpacing: -0.8, height: 1.2)),
      const SizedBox(height: 12),
      ShopText(wishlist ? 'Tap the heart on any sneaker to save it here.\nCome back when you’re ready to choose.'
          : 'Your bag is empty. Explore the collection\nand find something that moves you.',
          textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7)),
      const SizedBox(height: 28),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: exploreSneakers,
          child: const ShopText('Explore sneakers'))),
    ]),
  ));
}
