import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/dialogs/velora_confirm_dialog.dart';
import 'package:fashion_business_app/common/widgets/list_tiles/settings_menu_tiles.dart';
import 'package:fashion_business_app/common/widgets/list_tiles/user_profile_title.dart';
import 'package:fashion_business_app/common/widgets/product/badges/shop_count_badge.dart';
import 'package:fashion_business_app/data/repositories/authentication/authentication_repository.dart';
import 'package:fashion_business_app/features/personalization/screens/account/coupons_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/account/demo_bank_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/account/notifications_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/account/privacy_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/address/address_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/preferences/shopper_onboarding.dart';
import 'package:fashion_business_app/features/personalization/screens/profile/profile_screen.dart';
import 'package:fashion_business_app/features/personalization/services/account_activity.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/screens/cart/cart_screen.dart';
import 'package:fashion_business_app/features/shop/screens/order/order.dart';
import 'package:fashion_business_app/features/shop/screens/order/return_request_screen.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final cardColor = dark ? const Color(0xFF1A2721) : Colors.white;
    final borderColor = dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5EAE3);
    final activity = AccountActivity.current;
    final hasBenefits = Get.isRegistered<CustomerBenefits>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: dark ? const Color(0xFF111B16) : const Color(0xFFF6F7F3),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF102B23), Color(0xFF173E32), Color(0xFF215243)],
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    TAppbar(
                      title: const ShopText(
                        'Account',
                        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: TColors.white),
                      ),
                      actions: [
                        if (activity != null)
                          Obx(() => IconButton(
                                tooltip: 'Notifications'.tr,
                                onPressed: () => Get.to(() => const NotificationsScreen()),
                                icon: ShopCountBadge(
                                  count: activity.unread,
                                  child: const Icon(Iconsax.notification, color: Colors.white, size: 21),
                                ),
                              ))
                        else
                          IconButton(
                            tooltip: 'Notifications'.tr,
                            onPressed: () => Get.to(() => const NotificationsScreen()),
                            icon: const Icon(Iconsax.notification, color: Colors.white, size: 21),
                          ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 22),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                        ),
                        child: TUserProfileTile(
                          onPressed: () => Get.to(() => const ProfileScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 4-tile Quick Action Hub
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _QuickHubTile(
                              icon: Iconsax.bag_tick,
                              label: 'Orders',
                              badgeWidget: activity != null
                                  ? Obx(() => _SmallBadge(count: activity.activeOrders))
                                  : null,
                              onTap: () => Get.to(() => const OrderScreen()),
                            ),
                          ),
                          Expanded(
                            child: _QuickHubTile(
                              icon: Iconsax.discount_shape,
                              label: 'Vouchers',
                              badgeWidget: hasBenefits
                                  ? Obx(() => _SmallBadge(count: CustomerBenefits.instance.newCouponCount))
                                  : null,
                              onTap: () => Get.to(() => const CouponsScreen()),
                            ),
                          ),
                          Expanded(
                            child: _QuickHubTile(
                              icon: Iconsax.wallet_3,
                              label: 'Wallet',
                              onTap: () => Get.to(() => const DemoBankScreen()),
                            ),
                          ),
                          Expanded(
                            child: _QuickHubTile(
                              icon: Iconsax.notification,
                              label: 'Notifications',
                              badgeWidget: activity != null
                                  ? Obx(() => _SmallBadge(count: activity.unread))
                                  : null,
                              onTap: () => Get.to(() => const NotificationsScreen()),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Group 1: Shopping & Orders
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 10),
                      child: ShopText(
                        'Shopping & Orders',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          TSettingMenuTiles(
                            icon: Iconsax.safe_home,
                            title: 'My Address',
                            subtitle: 'Set shopping delivery address',
                            trailing: activity != null
                                ? Obx(() => ShopCountBadge(
                                      count: activity.addressCount.value,
                                      child: const Icon(Icons.chevron_right_rounded),
                                    ))
                                : const Icon(Icons.chevron_right_rounded),
                            onTap: () => Get.to(() => const AddressScreen()),
                          ),
                          _cardDivider(borderColor),
                          TSettingMenuTiles(
                            icon: Iconsax.shopping_cart,
                            title: 'My Cart',
                            subtitle: 'Add, remove products and move to checkout',
                            trailing: Obx(() => ShopCountBadge(
                                  count: CartController.instance.noOfCartItem.value,
                                  child: const Icon(Icons.chevron_right_rounded),
                                )),
                            onTap: () => Get.to(() => const CartScreen()),
                          ),
                          _cardDivider(borderColor),
                          TSettingMenuTiles(
                            icon: Iconsax.bag_tick,
                            title: 'My Orders',
                            subtitle: 'In-progress and Completed Orders',
                            trailing: activity != null
                                ? Obx(() => ShopCountBadge(
                                      count: activity.activeOrders,
                                      child: const Icon(Icons.chevron_right_rounded),
                                    ))
                                : const Icon(Icons.chevron_right_rounded),
                            onTap: () => Get.to(() => const OrderScreen()),
                          ),
                          _cardDivider(borderColor),
                          TSettingMenuTiles(
                            icon: Iconsax.refresh_circle,
                            title: Localizations.localeOf(context).languageCode == 'en'
                                ? 'Returns & Exchanges'
                                : 'Đổi trả & Bảo hành',
                            subtitle: Localizations.localeOf(context).languageCode == 'en'
                                ? 'Exchange size, 1-to-1 replacement or refund'
                                : 'Đổi kích cỡ EU, đổi đôi mới 1-1 hoặc hoàn tiền',
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () =>
                                Get.to(() => const MyReturnRequestsScreen()),
                          ),
                          _cardDivider(borderColor),
                          TSettingMenuTiles(
                            icon: Iconsax.bank,
                            title: 'Payment account',
                            subtitle: 'Balance and transaction history',
                            onTap: () => Get.to(() => const DemoBankScreen()),
                          ),
                          _cardDivider(borderColor),
                          TSettingMenuTiles(
                            icon: Iconsax.discount_shape,
                            title: 'My Coupons',
                            subtitle: 'Welcome and holiday offers',
                            trailing: hasBenefits
                                ? Obx(() => ShopCountBadge(
                                      count: CustomerBenefits.instance.newCouponCount,
                                      child: const Icon(Icons.chevron_right_rounded),
                                    ))
                                : const Icon(Icons.chevron_right_rounded),
                            onTap: () => Get.to(() => const CouponsScreen()),
                          ),
                          _cardDivider(borderColor),
                          TSettingMenuTiles(
                            icon: Iconsax.notification,
                            title: 'Notification',
                            subtitle: 'Updates from your orders.',
                            trailing: activity != null
                                ? Obx(() => ShopCountBadge(
                                      count: activity.unread,
                                      child: const Icon(Icons.chevron_right_rounded),
                                    ))
                                : const Icon(Icons.chevron_right_rounded),
                            onTap: () => Get.to(() => const NotificationsScreen()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Group 2: Preferences & Security
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 10),
                      child: ShopText(
                        'Preferences & Security',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          TSettingMenuTiles(
                            icon: Iconsax.language_square,
                            title: 'Language',
                            subtitle: Get.locale?.languageCode == 'en' ? 'English · USD' : 'Tiếng Việt · VND',
                            onTap: () => showModalBottomSheet(
                              context: context,
                              showDragHandle: true,
                              builder: (sheet) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (final entry in {'vi': 'Tiếng Việt · VND', 'en': 'English · USD'}.entries)
                                      RadioListTile<String>(
                                        value: entry.key,
                                        groupValue: Get.locale?.languageCode ?? 'vi',
                                        title: Text(entry.value),
                                        onChanged: (value) async {
                                          Navigator.pop(sheet);
                                          await Get.find<ShopLocale>().change(value!);
                                          await AccountActivity.current?.syncPush();
                                        },
                                      ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          _cardDivider(borderColor),
                          TSettingMenuTiles(
                            icon: Iconsax.setting_4,
                            title: 'Your preferences',
                            subtitle: 'Age group and favorite collections',
                            onTap: () => Get.to(() => const ShopperOnboarding(editing: true)),
                          ),
                          _cardDivider(borderColor),
                          TSettingMenuTiles(
                            icon: Iconsax.security_card,
                            title: 'Account Privacy',
                            subtitle: 'Manage data usage and connected accounts',
                            onTap: () => Get.to(() => const PrivacyScreen()),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Iconsax.logout, size: 19, color: Color(0xFFC62828)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC62828),
                          backgroundColor: dark
                              ? const Color(0xFF2B1A1A)
                              : const Color(0xFFFFF5F5),
                          side: BorderSide(
                            color: const Color(0xFFC62828).withValues(alpha: 0.25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          final confirmed = await showVeloraConfirmDialog(
                            context,
                            title: 'Confirm Logout',
                            message: 'Are you sure you want to log out?',
                            confirmLabel: 'Logout',
                            cancelLabel: 'Cancel',
                            destructive: true,
                            icon: Iconsax.logout,
                          );
                          if (confirmed == true) {
                            AuthenticationRepository.instance.logout();
                          }
                        },
                        label: const ShopText(
                          'Logout',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardDivider(Color color) => Divider(height: 1, indent: 68, endIndent: 16, color: color);
}

class _QuickHubTile extends StatelessWidget {
  const _QuickHubTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeWidget,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? badgeWidget;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF22362D) : const Color(0xFFEBF2EE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    size: 21,
                    color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
                  ),
                ),
                if (badgeWidget != null)
                  Positioned(top: -4, right: -6, child: badgeWidget!),
              ],
            ),
            const SizedBox(height: 7),
            ShopText(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFD94A38),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700, height: 1),
      ),
    );
  }
}
