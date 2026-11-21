import 'package:fashion_business_app/features/personalization/services/account_activity.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/common/widgets/product/badges/shop_count_badge.dart';
import 'package:fashion_business_app/features/personalization/screens/account/demo_bank_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/account/coupons_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/account/notifications_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/account/privacy_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/preferences/shopper_onboarding.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:fashion_business_app/common/widgets/list_tiles/settings_menu_tiles.dart';
import 'package:fashion_business_app/common/widgets/list_tiles/user_profile_title.dart';
import 'package:fashion_business_app/common/widgets/text/section_heading.dart';
import 'package:fashion_business_app/data/repositories/authentication/authentication_repository.dart';
import 'package:fashion_business_app/features/authentication/screens/login/login.dart';
import 'package:fashion_business_app/features/personalization/screens/address/address_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/profile/profile_screen.dart';
import 'package:fashion_business_app/features/shop/screens/cart/cart_screen.dart';
import 'package:fashion_business_app/features/shop/screens/order/order.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ///header
             TPrimaryHeaderContainer(
                child: Column(
              children: [
                ///appbar
                TAppbar(title: Obx(() => Row(mainAxisSize: MainAxisSize.min, children: [
                  const ShopText('Account', style: TextStyle(fontSize: 20, color: TColors.white)),
                  const SizedBox(width: 16),
                  ShopCountBadge(count: (AccountActivity.current?.activeOrders ?? 0)
                      + (AccountActivity.current?.unread ?? 0) + CustomerBenefits.instance.newCouponCount,
                      child: const Icon(Iconsax.notification, color: Colors.white, size: 18)),
                ]))),

                ///user profile card
                TUserProfileTile(onPressed:() => Get.to(() => const ProfileScreen()),),
                const SizedBox(height: TSizes.spaceBtwSections,),
              ],
            )),

            ///body
            Padding(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Iconsax.language_square),
                    title: const ShopText('Language'),
                    subtitle: Text(Get.locale?.languageCode == 'en' ? 'English · USD' : 'Tiếng Việt · VND'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showModalBottomSheet(context: context, builder: (sheet) => SafeArea(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        for (final entry in {'vi': 'Tiếng Việt · VND', 'en': 'English · USD'}.entries)
                          RadioListTile<String>(value: entry.key,
                            groupValue: Get.locale?.languageCode ?? 'vi', title: Text(entry.value),
                            onChanged: (value) async {
                              Navigator.pop(sheet);
                              await Get.find<ShopLocale>().change(value!);
                              await AccountActivity.current?.syncPush();
                            }),
                      ]),
                    )),
                  ),
                  ListTile(contentPadding: EdgeInsets.zero,
                    leading: const Icon(Iconsax.setting_4),
                    title: const ShopText('Your preferences'),
                    subtitle: const ShopText('Age group and favorite collections'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Get.to(() => const ShopperOnboarding(editing: true)),
                  ),
                  const Divider(height: 32),
                  /// account settings
                  const TSectionHeading(title: 'Account settings', showActionButton: false,),
                  const SizedBox(height: TSizes.spaceBtwItems,),

                   TSettingMenuTiles(icon: Iconsax.safe_home, title: 'My Address', trailing: Obx(() => ShopCountBadge(count: AccountActivity.current?.addressCount.value ?? 0, child: const Icon(Icons.chevron_right))), subtitle: 'Set shopping delivery address',onTap: () => Get.to(() => const AddressScreen()),),
                   TSettingMenuTiles(icon: Iconsax.shopping_cart, title: 'My Cart', trailing: Obx(() => ShopCountBadge(count: CartController.instance.noOfCartItem.value, child: const Icon(Icons.chevron_right))), subtitle: 'Add, remove products and move to checkout',onTap: () => Get.to(() => const CartScreen()),),
                   TSettingMenuTiles(icon: Iconsax.bag_tick, title: 'My Orders', trailing: Obx(() => ShopCountBadge(count: AccountActivity.current?.activeOrders ?? 0, child: const Icon(Icons.chevron_right))), subtitle: 'In-progress and Completed Orders',onTap: () => Get.to(() => const OrderScreen())),
                  TSettingMenuTiles(icon: Iconsax.bank, title: 'Payment account', subtitle: 'Balance and transaction history', onTap: () => Get.to(() => const DemoBankScreen())),
                  TSettingMenuTiles(icon: Iconsax.discount_shape, title: 'My Coupons', trailing: Obx(() => ShopCountBadge(count: CustomerBenefits.instance.newCouponCount, child: const Icon(Icons.chevron_right))), subtitle: 'Welcome and holiday offers', onTap: () => Get.to(() => const CouponsScreen())),
                  TSettingMenuTiles(icon: Iconsax.notification, title: 'Notification', trailing: Obx(() => ShopCountBadge(count: AccountActivity.current?.unread ?? 0, child: const Icon(Icons.chevron_right))), subtitle: 'Updates from your orders.', onTap: () => Get.to(() => const NotificationsScreen())),
                  TSettingMenuTiles(icon: Iconsax.security_card, title: 'Account Privacy', subtitle: 'Manage data usage and connected accounts', onTap: () => Get.to(() => const PrivacyScreen())),

                  ///logout button
                  const SizedBox(height: TSizes.spaceBtwSections,),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const ShopText(
                              "Confirm Logout",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: ShopText(
                              "Are you sure you want to log out?",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close the dialog
                                },
                                child: const ShopText(
                                  "Cancel",
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Perform logout action here
                                  AuthenticationRepository.instance.logout();
                                  Navigator.pop(context); // Close the dialog
                                },
                                child: const ShopText(
                                  "Logout",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const ShopText('Logout'),
                  ),
                ),

                const SizedBox(height: TSizes.spaceBtwSections  * 2),

                ],
              ),
            )
          ],
        ),
      ),
      ),
    );
  }
}
