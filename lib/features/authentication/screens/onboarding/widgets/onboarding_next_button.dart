import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/features/authentication/controllers/onbroading/onboarding_controller.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/device/device_utility.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';

class OnBoardingNextButton extends StatelessWidget {
  const OnBoardingNextButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dark  = THelperFunctions.isDarkMode(context);
    return Positioned(
        right: TSizes.defaultSpace,
        bottom: TDeviceUtils.getBottomNavigationBarHeight(),
        child: ElevatedButton(
          onPressed: () => OnBoardingController.instance.nextPage(),
          style: ElevatedButton.styleFrom(shape: const CircleBorder(),backgroundColor: dark ? TColors.primaryColor : Colors.black),
          child: const Icon(Iconsax.arrow_right_3),
        ));
  }
}

