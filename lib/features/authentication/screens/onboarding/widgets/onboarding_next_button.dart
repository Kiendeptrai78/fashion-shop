import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/features/authentication/controllers/onbroading/onboarding_controller.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/device/device_utility.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class OnBoardingNextButton extends StatelessWidget {
  const OnBoardingNextButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: TSizes.defaultSpace,
      bottom: TDeviceUtils.getBottomNavigationBarHeight(),
      child: GlassIconButton(
        size: 54,
        iconSize: 22,
        useOwnLayer: true,
        tintColor: const Color(0xFF173E32),
        iconColor: const Color(0xFFDDEABB),
        onPressed: () => OnBoardingController.instance.nextPage(),
        icon: const Icon(Iconsax.arrow_right_3, color: Color(0xFFDDEABB)),
      ),
    );
  }
}
