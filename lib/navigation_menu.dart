import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:fashion_business_app/common/widgets/tabs/shop_tab_body.dart';

import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/common/widgets/product/badges/shop_count_badge.dart';
import 'package:fashion_business_app/features/personalization/screens/settings/setting_screen.dart';
import 'package:fashion_business_app/features/personalization/services/account_activity.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/features/shop/screens/home/home_screen.dart';
import 'package:fashion_business_app/features/shop/screens/reels/velora_reels_screen.dart';
import 'package:fashion_business_app/features/shop/screens/support_chat/velora_support_chat_screen.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';
import 'package:flutter/material.dart';
import 'package:fashion_business_app/common/widgets/chat/shop_chat_background.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => AccountActivity.current?.handleInitialPush(),
    );
    final darkMode = THelperFunctions.isDarkMode(context);
    final activeColor =
        darkMode ? const Color(0xFFDDEABB) : const Color(0xFF173E32);
    final inactiveColor = darkMode ? Colors.white : Colors.black;
    final mq = MediaQuery.of(context);

    return Obx(() {
      final selectedIdx = controller.selectedIndex.value.clamp(0, 3);
      final overVideo = selectedIdx == 1;
      final bottomGap = (mq.viewPadding.bottom - 10).clamp(12.0, double.infinity).toDouble();
      final navOccupiedHeight = 60.0 + bottomGap;
      final adjustedBottomInset = (mq.viewInsets.bottom - navOccupiedHeight)
          .clamp(0.0, double.infinity);

      final chatUnread = AccountActivity.current?.chatUnread.value ?? 0;
      final profileCount = (AccountActivity.current?.activeOrders ?? 0) +
          (AccountActivity.current?.unread ?? 0) +
          (Get.isRegistered<CustomerBenefits>()
              ? CustomerBenefits.instance.newCouponCount
              : 0);

      final glassTabs = [
        GlassTab(
          icon: const Icon(Iconsax.home),
          activeIcon: const Icon(Iconsax.home_15),
          label: 'Home'.tr,
        ),
        GlassTab(
          icon: const Icon(CupertinoIcons.play_circle),
          activeIcon: const Icon(CupertinoIcons.play_circle_fill),
          label: 'Featured'.tr,
        ),
        GlassTab(
          icon: ShopCountBadge(
            count: chatUnread,
            child: const Icon(Iconsax.message_text_1),
          ),
          activeIcon: ShopCountBadge(
            count: chatUnread,
            child: const Icon(Iconsax.message_text5),
          ),
          label: 'Chat',
        ),
        GlassTab(
          icon: ShopCountBadge(
            count: profileCount,
            child: const Icon(Iconsax.user),
          ),
          activeIcon: ShopCountBadge(
            count: profileCount,
            child: const Icon(Iconsax.user_octagon),
          ),
          label: 'Profile'.tr,
        ),
      ];

      final bottomTabBar = GlassTabBar.bottom(
        tabs: glassTabs,
        selectedIndex: selectedIdx,
        onTabSelected: (index) {
          FocusManager.instance.primaryFocus?.unfocus();
          controller.selectedIndex.value = index;
        },
        horizontalPadding: 0,
        verticalPadding: 0,
        barHeight: 60,
        pressScale: 1.01,
        interactionBehavior: GlassInteractionBehavior.scaleOnly,
        magnification: 1.02,
        quality: GlassQuality.minimal,
        backgroundQuality: GlassQuality.minimal,
        indicatorExpansion: EdgeInsets.zero,
        indicatorColor: const Color(0x0F000000),
        indicatorSettings: LiquidGlassSettings.classicIndicator,
        glowOpacity: 0,
        settings: LiquidGlassSettings.ios27Light.copyWith(
          frost: darkMode ? 0.18 : 0.08,
          blur: darkMode ? 18 : 14,
          glassColor: darkMode
              ? const Color(0x55202020)
              : const Color(0xBBF5F5F5),
          bodyShade: darkMode ? 0.15 : 0.06,
        ),
        selectedIconColor: activeColor,
        unselectedIconColor: inactiveColor,
        selectedLabelColor: activeColor,
        unselectedLabelColor: inactiveColor,
        labelFontSize: 11.5,
        iconSize: 21,
        interactionGlowColor: Colors.transparent,
      );

      return Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        resizeToAvoidBottomInset: false,
        bottomNavigationBar: Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, bottomGap),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              // Keep live blur fixed; the moving indicator must not own a
              // BackdropFilter whose changing bounds can flash below the bar.
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: bottomTabBar,
              ),
            ),
        ),
        body: Builder(builder: (context) {
          final bodyMedia = MediaQuery.of(context);
          return MediaQuery(
            data: bodyMedia.copyWith(
              viewInsets: bodyMedia.viewInsets.copyWith(bottom: adjustedBottomInset),
            ),
            child: ShopTabBody(
              index: selectedIdx,
              backgroundColor: overVideo ? const Color(0xFF0B0E0D)
                  : selectedIdx == 2
                      ? (darkMode ? ShopChatBackground.darkColor : ShopChatBackground.lightColor)
                      : null,
              child: RepaintBoundary(
              key: ValueKey(selectedIdx),
              child: Padding(
                padding: EdgeInsets.only(bottom: selectedIdx == 2 ? navOccupiedHeight : 0),
                child: controller.screens[selectedIdx],
              ),
              ),
            ),
          );
        }),
      );
    });
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;
  final screens = [
    const HomeScreen(),
    const VeloraReelsScreen(),
    const VeloraSupportChatScreen(embeddedInNav: true),
    const SettingScreen(),
  ];
}
