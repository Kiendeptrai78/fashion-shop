import 'package:fashion_business_app/utils/localization/shop_translations.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';

class TLoaders {
  static hideSnackBar() => ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();

  static customToast({required message}) {
    ScaffoldMessenger.of(Get.context!).showSnackBar(
     SnackBar(
      elevation: 0,
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.transparent,
      content: Container(
        padding: const EdgeInsets.all(12.0),
        margin: const EdgeInsets.symmetric(horizontal: 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: THelperFunctions.isDarkMode(Get.context!)
              ? TColors.darkerGrey.withOpacity(0.9)
              : TColors.grey.withOpacity(0.9),
        ),
        child: Center(
          child: ShopText(
            message,
            style: Theme.of(Get.context!).textTheme.labelLarge,
          ),
        ),
      ),
    ));
  }

  static successSnackBar({required title, message = '', duration = 3}) {
    Get.snackbar(shopTranslate(title, language: Get.locale?.languageCode ?? 'vi'),
        shopTranslate(message, language: Get.locale?.languageCode ?? 'vi'),
        isDismissible: true,
        shouldIconPulse: true,
        backgroundColor: const Color(0xFF173E32),
        colorText: TColors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 16,
        duration: Duration(seconds: duration),
        margin: const EdgeInsets.all(14),
        icon: const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFFDDEABB),
        ));
  }

  static warningSnackBar({required title, message = ''}) {
    Get.snackbar(shopTranslate(title, language: Get.locale?.languageCode ?? 'vi'),
        shopTranslate(message, language: Get.locale?.languageCode ?? 'vi'),
        isDismissible: true,
        shouldIconPulse: true,
        colorText: TColors.white,
        backgroundColor: Colors.orange,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(20),
        icon: const Icon(
          Icons.warning_amber,
          color: TColors.white,
        ));
  }

  static errorSnackBar({required title, message = ''}) {
    Get.snackbar(shopTranslate(title, language: Get.locale?.languageCode ?? 'vi'),
        shopTranslate(message, language: Get.locale?.languageCode ?? 'vi'),
        isDismissible: true,
        shouldIconPulse: true,
        colorText: TColors.white,
        backgroundColor: Colors.red.shade600,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(20),
        icon: const Icon(
          Icons.warning_amber,
          color: TColors.white,
        ));
  }

}
