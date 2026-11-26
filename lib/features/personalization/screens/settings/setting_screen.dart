import 'package:fashion_business_app/common/widgets/list_tiles/loyalty_coins_tile.dart';
import 'package:fashion_business_app/common/widgets/dialogs/velora_confirm_dialog.dart';
import 'package:fashion_business_app/common/widgets/images/circular_image.dart';
import 'package:fashion_business_app/common/widgets/product/badges/shop_count_badge.dart';
import 'package:fashion_business_app/common/widgets/shimmer/shimmer.dart';
import 'package:fashion_business_app/data/repositories/authentication/authentication_repository.dart';
import 'package:fashion_business_app/features/personalization/controllers/address_controller.dart';
import 'package:fashion_business_app/features/personalization/controllers/user_controller.dart';
import 'package:fashion_business_app/features/personalization/screens/account/coupons_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/account/notifications_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/account/privacy_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/address/address_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/preferences/shopper_onboarding.dart';
import 'package:fashion_business_app/features/personalization/screens/profile/profile_screen.dart';
import 'package:fashion_business_app/features/personalization/services/account_activity.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/favourite_controller.dart';
import 'package:fashion_business_app/features/shop/screens/cart/cart_screen.dart';
import 'package:fashion_business_app/features/shop/screens/order/order.dart';
import 'package:fashion_business_app/features/shop/screens/order/return_request_screen.dart';
import 'package:fashion_business_app/features/shop/screens/support_chat/velora_support_chat_screen.dart';
import 'package:fashion_business_app/features/shop/screens/wishlist/wishlish_screen.dart';
import 'package:fashion_business_app/navigation_menu.dart';
import 'package:fashion_business_app/utils/constants/image_strings.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  void _openSupportChat() {
    if (Get.isRegistered<NavigationController>()) {
      Get.find<NavigationController>().selectedIndex.value = 2;
    } else {
      Get.to(() => const VeloraSupportChatScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final cardColor = dark ? const Color(0xFF19251F) : Colors.white;
    final borderColor =
        dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE4EAE4);

    final activity = AccountActivity.current;
    final benefits =
        Get.isRegistered<CustomerBenefits>() ? CustomerBenefits.instance : null;
    final favController = Get.isRegistered<FavouritesController>()
        ? FavouritesController.instance
        : null;
    final userController =
        Get.isRegistered<UserController>() ? UserController.instance : null;
    final addressController = Get.isRegistered<AddressController>()
        ? AddressController.instance
        : null;
    final cartController =
        Get.isRegistered<CartController>() ? CartController.instance : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor:
            dark ? const Color(0xFF0E1713) : const Color(0xFFF4F6F2),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // 1. Flagship Member Hero Card (3-metric live bar: Đơn hàng · Yêu thích · Voucher)
              _MemberHeroHeader(
                isEn: isEn,
                userController: userController,
                activity: activity,
                benefits: benefits,
                favController: favController,
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Order Pipeline Card (Đơn hàng của tôi)
                    _OrderPipelineCard(
                      isEn: isEn,
                      dark: dark,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      activity: activity,
                    ),
                    const SizedBox(height: 14),

                    if (activity != null) ...[
                      const CoinWalletCard(),
                      const SizedBox(height: 14),
                    ],
                    // 3. 2-Column Bento Highlights: Yêu thích & Ví Voucher
                    Row(
                      children: [
                        Expanded(
                          child: _BentoFeatureCard(
                            dark: dark,
                            cardColor: cardColor,
                            borderColor: borderColor,
                            icon: Iconsax.heart5,
                            iconColor: const Color(0xFFE11D48),
                            iconBg: dark
                                ? const Color(0xFF3A1B24)
                                : const Color(0xFFFFF1F2),
                            title: isEn ? 'Saved Pairs' : 'Yêu thích',
                            subtitleBuilder: () {
                              if (favController == null) {
                                return Text(
                                  isEn ? 'Your wishlist' : 'Giày đã lưu',
                                  softWrap: true,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.hintColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }
                              return Obx(() {
                                final count = favController.favourites.values
                                    .where((saved) => saved)
                                    .length;
                                return Text(
                                  count == 0
                                      ? (isEn
                                          ? 'Save your picks'
                                          : 'Chưa lưu đôi nào')
                                      : (isEn
                                          ? '$count saved pairs'
                                          : '$count đôi đã lưu'),
                                  softWrap: true,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: count > 0
                                        ? const Color(0xFFE11D48)
                                        : theme.hintColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                );
                              });
                            },
                            onTap: () => Get.to(() => const WishList()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _BentoFeatureCard(
                            dark: dark,
                            cardColor: cardColor,
                            borderColor: borderColor,
                            icon: Iconsax.discount_shape,
                            iconColor: const Color(0xFFD97706),
                            iconBg: dark
                                ? const Color(0xFF332613)
                                : const Color(0xFFFEF3C7),
                            title: isEn ? 'Vouchers' : 'Ví Voucher',
                            subtitleBuilder: () {
                              if (benefits == null) {
                                return Text(
                                  isEn ? 'Member offers' : 'Ưu đãi thành viên',
                                  softWrap: true,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.hintColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }
                              return Obx(() {
                                final avail = benefits.coupons
                                    .where((c) =>
                                        !benefits.used.contains(c.id) &&
                                        benefits.now().isBefore(c.expires))
                                    .length;
                                return Text(
                                  avail == 0
                                      ? (isEn
                                          ? 'No active codes'
                                          : 'Chưa có mã mới')
                                      : (isEn
                                          ? '$avail available codes'
                                          : '$avail mã khả dụng'),
                                  softWrap: true,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: avail > 0
                                        ? const Color(0xFFD97706)
                                        : theme.hintColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                );
                              });
                            },
                            onTap: () => Get.to(() => const CouponsScreen()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 4. Section: Tiện ích mua sắm & Hỗ trợ
                    _SectionLabel(
                      text: isEn
                          ? 'Shopping & Support'
                          : 'Tiện ích mua sắm & Hỗ trợ',
                    ),
                    const SizedBox(height: 8),
                    _MenuGroupCard(
                      cardColor: cardColor,
                      borderColor: borderColor,
                      children: [
                        // Địa chỉ nhận hàng
                        _AccountMenuRow(
                          icon: Iconsax.location,
                          iconColor: const Color(0xFF0284C7),
                          iconBg: dark
                              ? const Color(0xFF122C38)
                              : const Color(0xFFE0F2FE),
                          title: isEn ? 'Delivery Addresses' : 'Địa chỉ nhận hàng',
                          subtitleWidget: addressController != null
                              ? Obx(() {
                                  final selected =
                                      addressController.selectedAddress.value;
                                  final label = selected.id.isNotEmpty
                                      ? [
                                          selected.state,
                                          selected.city,
                                        ]
                                          .where((s) => s.trim().isNotEmpty)
                                          .join(', ')
                                      : (isEn
                                          ? 'Manage & edit saved addresses'
                                          : 'Thêm, sửa địa chỉ và xem khoảng cách giao');
                                  return Text(
                                    label,
                                    softWrap: true,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.hintColor,
                                    ),
                                  );
                                })
                              : null,
                          subtitle: isEn
                              ? 'Manage & edit saved addresses'
                              : 'Thêm, sửa địa chỉ và xem khoảng cách giao',
                          trailing: activity != null
                              ? Obx(() => _TrailingBadgeChevron(
                                    count: activity.addressCount.value,
                                    isNeutral: true,
                                  ))
                              : const Icon(Icons.chevron_right_rounded),
                          onTap: () => Get.to(() => const AddressScreen()),
                        ),
                        _rowDivider(borderColor),

                        // Đổi trả & Bảo hành 7 ngày
                        _AccountMenuRow(
                          icon: Iconsax.refresh_circle,
                          iconColor: const Color(0xFF7C3AED),
                          iconBg: dark
                              ? const Color(0xFF281C3E)
                              : const Color(0xFFF3E8FF),
                          title: isEn
                              ? 'Returns & Exchanges'
                              : 'Đổi trả & Bảo hành',
                          subtitle: isEn
                              ? 'Free 7-day size exchange, 1-to-1 replacement or refund'
                              : 'Miễn phí đổi size EU trong 7 ngày, đổi mới 1-1 hoặc hoàn tiền',
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () =>
                              Get.to(() => const MyReturnRequestsScreen()),
                        ),
                        _rowDivider(borderColor),

                        // Chat trực tiếp với VELORA
                        _AccountMenuRow(
                          icon: Iconsax.message_text_1,
                          iconColor: const Color(0xFF173E32),
                          iconBg: dark
                              ? const Color(0xFF1D352B)
                              : const Color(0xFFE7F2EC),
                          title: isEn
                              ? 'Chat with VELORA'
                              : 'Chat trực tiếp với VELORA',
                          subtitle: isEn
                              ? '1-to-1 support for orders, exchanges & sizing'
                              : 'Nhắn tin 1-1 với CSKH về đơn hàng, đổi trả & chọn size',
                          trailing: activity != null
                              ? Obx(() => _TrailingBadgeChevron(
                                    count: activity.chatUnread.value,
                                  ))
                              : const Icon(Icons.chevron_right_rounded),
                          onTap: _openSupportChat,
                        ),
                        _rowDivider(borderColor),

                        // Giỏ hàng của tôi
                        _AccountMenuRow(
                          icon: Iconsax.shopping_bag,
                          iconColor: const Color(0xFF0F766E),
                          iconBg: dark
                              ? const Color(0xFF132F2D)
                              : const Color(0xFFCCFBF1),
                          title: isEn ? 'My Cart' : 'Giỏ hàng của tôi',
                          subtitle: isEn
                              ? 'Review items and proceed to checkout'
                              : 'Xem nhanh sản phẩm đã chọn và thanh toán',
                          trailing: cartController != null
                              ? Obx(() => _TrailingBadgeChevron(
                                    count: cartController.noOfCartItem.value,
                                  ))
                              : const Icon(Icons.chevron_right_rounded),
                          onTap: () => Get.to(() => const CartScreen()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 5. Section: Cài đặt & Cá nhân hóa
                    _SectionLabel(
                      text: isEn
                          ? 'Preferences & Security'
                          : 'Cài đặt & Cá nhân hóa',
                    ),
                    const SizedBox(height: 8),
                    _MenuGroupCard(
                      cardColor: cardColor,
                      borderColor: borderColor,
                      children: [
                        // Thông báo
                        _AccountMenuRow(
                          icon: Iconsax.notification,
                          iconColor: const Color(0xFFDC2626),
                          iconBg: dark
                              ? const Color(0xFF351919)
                              : const Color(0xFFFEE2E2),
                          title: isEn ? 'Notifications' : 'Thông báo đơn hàng',
                          subtitle: isEn
                              ? 'Order tracking, promotions & VELORA news'
                              : 'Cập nhật trạng thái đơn hàng & ưu đãi mới nhất',
                          trailing: activity != null
                              ? Obx(() => _TrailingBadgeChevron(
                                    count: activity.unread,
                                  ))
                              : const Icon(Icons.chevron_right_rounded),
                          onTap: () =>
                              Get.to(() => const NotificationsScreen()),
                        ),
                        _rowDivider(borderColor),

                        // Ngôn ngữ & Tiền tệ
                        _AccountMenuRow(
                          icon: Iconsax.language_square,
                          iconColor: const Color(0xFF2563EB),
                          iconBg: dark
                              ? const Color(0xFF162540)
                              : const Color(0xFFDBEAFE),
                          title:
                              isEn ? 'Language & Currency' : 'Ngôn ngữ & Tiền tệ',
                          subtitle: isEn
                              ? 'Switch app language and display currency'
                              : 'Chuyển đổi giữa Tiếng Việt (VND) và English (USD)',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: dark
                                      ? const Color(0xFF22362D)
                                      : const Color(0xFFEEF3EE),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  Get.locale?.languageCode == 'en'
                                      ? 'EN · USD'
                                      : 'VI · VND',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: dark
                                        ? const Color(0xFFDDEABB)
                                        : const Color(0xFF173E32),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                          onTap: () => _showLanguageSheet(context),
                        ),
                        _rowDivider(borderColor),

                        // Sở thích mua sắm
                        _AccountMenuRow(
                          icon: Iconsax.setting_4,
                          iconColor: const Color(0xFF4F46E5),
                          iconBg: dark
                              ? const Color(0xFF1E1D3B)
                              : const Color(0xFFE0E7FF),
                          title: isEn
                              ? 'Shopping Preferences'
                              : 'Sở thích mua sắm',
                          subtitle: isEn
                              ? 'Age group & favorite sneaker collections'
                              : 'Nhóm tuổi và dòng giày VELORA bạn yêu thích',
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Get.to(
                            () => const ShopperOnboarding(editing: true),
                          ),
                        ),
                        _rowDivider(borderColor),

                        // Quyền riêng tư
                        _AccountMenuRow(
                          icon: Iconsax.security_card,
                          iconColor: const Color(0xFF059669),
                          iconBg: dark
                              ? const Color(0xFF132E24)
                              : const Color(0xFFD1FAE5),
                          title: isEn
                              ? 'Privacy & Security'
                              : 'Quyền riêng tư & Bảo mật',
                          subtitle: isEn
                              ? 'Manage data usage and linked accounts'
                              : 'Quản lý dữ liệu thiết bị và bảo mật tài khoản',
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Get.to(() => const PrivacyScreen()),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // 6. Logout button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Iconsax.logout,
                          size: 19,
                          color: Color(0xFFC62828),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC62828),
                          backgroundColor: dark
                              ? const Color(0xFF281717)
                              : const Color(0xFFFFF5F5),
                          side: BorderSide(
                            color:
                                const Color(0xFFC62828).withValues(alpha: 0.25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
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
                    Center(
                      child: Text(
                        isEn
                            ? 'VELORA Studio • Official Hanoi Warehouse'
                            : 'VELORA Studio • Tổng Kho Chính Hãng Hà Nội',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: theme.hintColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ShopText(
                    'Language',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              for (final entry in {
                'vi': 'Tiếng Việt · VND (₫)',
                'en': 'English · USD (\$)',
              }.entries)
                RadioListTile<String>(
                  value: entry.key,
                  groupValue: Get.locale?.languageCode ?? 'vi',
                  activeColor: const Color(0xFF173E32),
                  title: Text(
                    entry.value,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onChanged: (value) async {
                    Navigator.pop(sheet);
                    await Get.find<ShopLocale>().change(value!);
                    await AccountActivity.current?.syncPush();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowDivider(Color color) =>
      Divider(height: 1, indent: 66, endIndent: 16, color: color);
}

class _MemberHeroHeader extends StatelessWidget {
  const _MemberHeroHeader({
    required this.isEn,
    required this.userController,
    required this.activity,
    required this.benefits,
    required this.favController,
  });

  final bool isEn;
  final UserController? userController;
  final AccountActivity? activity;
  final CustomerBenefits? benefits;
  final FavouritesController? favController;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0C231C),
            Color(0xFF163D31),
            Color(0xFF1F5041),
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
          child: Column(
            children: [
              // Top bar: Brand membership tag + Notification & Edit Profile buttons
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDEABB).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFFDDEABB).withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 13,
                          color: Color(0xFFDDEABB),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'VELORA MEMBER',
                          style: TextStyle(
                            color: Color(0xFFDDEABB),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (activity != null)
                    Obx(() => IconButton(
                          tooltip: 'Notifications'.tr,
                          onPressed: () =>
                              Get.to(() => const NotificationsScreen()),
                          icon: ShopCountBadge(
                            count: activity!.unread,
                            child: const Icon(
                              Iconsax.notification,
                              color: Colors.white,
                              size: 21,
                            ),
                          ),
                        ))
                  else
                    IconButton(
                      tooltip: 'Notifications'.tr,
                      onPressed: () =>
                          Get.to(() => const NotificationsScreen()),
                      icon: const Icon(
                        Iconsax.notification,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                  IconButton(
                    tooltip: isEn ? 'Edit profile' : 'Chỉnh sửa hồ sơ',
                    onPressed: () => Get.to(() => const ProfileScreen()),
                    icon: const Icon(
                      Iconsax.setting_2,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Profile Identity Card
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Get.to(() => const ProfileScreen()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      if (userController != null)
                        Obx(() {
                          final pic =
                              userController!.user.value.profilePicture;
                          return Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFDDEABB),
                                width: 1.8,
                              ),
                            ),
                            child: userController!.imageUploading.value
                                ? const TShimmerEffect(
                                    width: 58,
                                    height: 58,
                                    radius: 58,
                                  )
                                : TCircularImage(
                                    image: pic.isNotEmpty ? pic : TImages.user,
                                    width: 58,
                                    height: 58,
                                    padding: 0,
                                    fit: BoxFit.cover,
                                    isNetworkImage: pic.isNotEmpty,
                                  ),
                          );
                        })
                      else
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                          child: const Icon(
                            Iconsax.user,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (userController != null)
                              Obx(() {
                                final fullName =
                                    userController!.user.value.fullName.trim();
                                return Text(
                                  fullName.isEmpty
                                      ? (isEn
                                          ? 'VELORA Customer'
                                          : 'Khách hàng VELORA')
                                      : fullName,
                                  softWrap: true,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                );
                              })
                            else
                              Text(
                                isEn ? 'Your account' : 'Tài khoản của bạn',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            const SizedBox(height: 4),
                            if (userController != null)
                              Obx(() => Text(
                                    userController!.user.value.email,
                                    softWrap: true,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color:
                                          Colors.white.withValues(alpha: 0.78),
                                    ),
                                  )),
                            const SizedBox(height: 8),
                            if (activity != null)
                              Obx(() {
                                final orders = activity!.orderCount;
                                final isVip = orders >= 3;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isVip
                                        ? const Color(0xFFF59E0B)
                                            .withValues(alpha: 0.22)
                                        : Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    isVip
                                        ? (isEn
                                            ? '★ VELORA VIP Member'
                                            : '★ Thành viên VIP VELORA')
                                        : (isEn
                                            ? 'Verified Member • Edit Profile'
                                            : 'Thành viên chính thức • Xem hồ sơ'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isVip
                                          ? const Color(0xFFFDE68A)
                                          : const Color(0xFFDDEABB),
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Frosted Glass 3-Stat Live Metrics Bar (Đơn hàng · Yêu thích · Voucher)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _HeroStatCell(
                        label: isEn ? 'Orders' : 'Đơn hàng',
                        valueWidget: activity != null
                            ? Obx(() =>
                                _HeroStatNumber('${activity!.orderCount}'))
                            : const _HeroStatNumber('0'),
                        onTap: () => Get.to(() => const OrderScreen()),
                      ),
                    ),
                    _statVerticalDivider(),
                    Expanded(
                      child: _HeroStatCell(
                        label: isEn ? 'Saved' : 'Yêu thích',
                        valueWidget: favController != null
                            ? Obx(() => _HeroStatNumber(
                                  '${favController!.favourites.values.where((v) => v).length}',
                                ))
                            : const _HeroStatNumber('0'),
                        onTap: () => Get.to(() => const WishList()),
                      ),
                    ),
                    _statVerticalDivider(),
                    Expanded(
                      child: _HeroStatCell(
                        label: isEn ? 'Vouchers' : 'Voucher',
                        valueWidget: benefits != null
                            ? Obx(() {
                                final avail = benefits!.coupons
                                    .where((c) =>
                                        !benefits!.used.contains(c.id) &&
                                        benefits!.now().isBefore(c.expires))
                                    .length;
                                return _HeroStatNumber('$avail');
                              })
                            : const _HeroStatNumber('0'),
                        onTap: () => Get.to(() => const CouponsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statVerticalDivider() => Container(
        width: 1,
        height: 28,
        color: Colors.white.withValues(alpha: 0.16),
      );
}

class _HeroStatNumber extends StatelessWidget {
  const _HeroStatNumber(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFFDDEABB),
        ),
      ),
    );
  }
}

class _HeroStatCell extends StatelessWidget {
  const _HeroStatCell({
    required this.label,
    required this.valueWidget,
    required this.onTap,
  });

  final String label;
  final Widget valueWidget;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            valueWidget,
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderPipelineCard extends StatelessWidget {
  const _OrderPipelineCard({
    required this.isEn,
    required this.dark,
    required this.cardColor,
    required this.borderColor,
    required this.activity,
  });

  final bool isEn;
  final bool dark;
  final Color cardColor;
  final Color borderColor;
  final AccountActivity? activity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.16 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isEn ? 'My Orders' : 'Đơn hàng của tôi',
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Get.to(() => const OrderScreen()),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isEn ? 'View history' : 'Xem lịch sử',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: dark
                              ? const Color(0xFFDDEABB)
                              : const Color(0xFF173E32),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 17,
                        color: dark
                            ? const Color(0xFFDDEABB)
                            : const Color(0xFF173E32),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PipelineStepTile(
                  icon: Iconsax.clock,
                  label: isEn ? 'Pending' : 'Chờ xác nhận',
                  badgeWidget: activity != null
                      ? Obx(() =>
                          _SmallBadge(count: activity!.counts['pending'] ?? 0))
                      : null,
                  onTap: () => Get.to(() => const OrderScreen()),
                ),
              ),
              Expanded(
                child: _PipelineStepTile(
                  icon: Iconsax.box_tick,
                  label: isEn ? 'Packing' : 'Đang chuẩn bị',
                  badgeWidget: activity != null
                      ? Obx(() => _SmallBadge(
                          count: activity!.counts['processing'] ?? 0))
                      : null,
                  onTap: () => Get.to(() => const OrderScreen()),
                ),
              ),
              Expanded(
                child: _PipelineStepTile(
                  icon: Iconsax.truck_fast,
                  label: isEn ? 'Shipping' : 'Đang giao',
                  badgeWidget: activity != null
                      ? Obx(() =>
                          _SmallBadge(count: activity!.counts['shipped'] ?? 0))
                      : null,
                  onTap: () => Get.to(() => const OrderScreen()),
                ),
              ),
              Expanded(
                child: _PipelineStepTile(
                  icon: Iconsax.refresh_circle,
                  label: isEn ? '7-Day Return' : 'Đổi trả 7 ngày',
                  accentColor: const Color(0xFF7C3AED),
                  onTap: () => Get.to(() => const MyReturnRequestsScreen()),
                ),
              ),
            ],
          ),
          if (activity != null)
            Obx(() {
              final received = activity!.counts['received'] ?? 0;
              if (received <= 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Get.to(() => const OrderScreen()),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: dark
                          ? const Color(0xFF1F332A)
                          : const Color(0xFFF1F7F4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.star1,
                          size: 15,
                          color: dark
                              ? const Color(0xFFDDEABB)
                              : const Color(0xFF173E32),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isEn
                                ? '$received completed orders • Tap to review or request exchange'
                                : '$received đơn đã giao thành công • Chạm để đánh giá hoặc đổi size',
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _PipelineStepTile extends StatelessWidget {
  const _PipelineStepTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeWidget,
    this.accentColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? badgeWidget;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = accentColor ??
        (dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32));
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
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
                    color: accentColor != null
                        ? accentColor!.withValues(alpha: dark ? 0.2 : 0.1)
                        : (dark
                            ? const Color(0xFF22362D)
                            : const Color(0xFFEBF2EE)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 21, color: fg),
                ),
                if (badgeWidget != null)
                  Positioned(top: -4, right: -6, child: badgeWidget!),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              softWrap: true,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BentoFeatureCard extends StatelessWidget {
  const _BentoFeatureCard({
    required this.dark,
    required this.cardColor,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitleBuilder,
    required this.onTap,
  });

  final bool dark;
  final Color cardColor;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final Widget Function() subtitleBuilder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: Theme.of(context).hintColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              subtitleBuilder(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).hintColor,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

class _MenuGroupCard extends StatelessWidget {
  const _MenuGroupCard({
    required this.cardColor,
    required this.borderColor,
    required this.children,
  });

  final Color cardColor;
  final Color borderColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _AccountMenuRow extends StatelessWidget {
  const _AccountMenuRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.subtitleWidget,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Widget? subtitleWidget;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  subtitleWidget ??
                      Text(
                        subtitle,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.hintColor,
                          height: 1.3,
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ?? const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _TrailingBadgeChevron extends StatelessWidget {
  const _TrailingBadgeChevron({
    required this.count,
    this.isNeutral = false,
  });

  final int count;
  final bool isNeutral;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (count > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: isNeutral
                  ? (dark ? const Color(0xFF24382F) : const Color(0xFFEAF1EC))
                  : const Color(0xFFD94A38),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: TextStyle(
                color: isNeutral
                    ? (dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32))
                    : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        const Icon(Icons.chevron_right_rounded),
      ],
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
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 1.5,
        ),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
