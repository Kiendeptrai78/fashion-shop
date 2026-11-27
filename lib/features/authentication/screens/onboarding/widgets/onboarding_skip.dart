import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/features/authentication/screens/login/login.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/device/device_utility.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnBoardingSkip extends StatelessWidget {
  const OnBoardingSkip({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: TDeviceUtils.getAppBarHeight(),
      right: TSizes.spaceBtwItems,
      child: GlassButton.custom(
        useOwnLayer: true,
        height: 36,
        shape: const LiquidRoundedSuperellipse(borderRadius: 18),
        onTap: () => Get.offAll(() => const LoginScreen()),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: ShopText(
            'Skip',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
