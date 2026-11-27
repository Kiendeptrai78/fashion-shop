import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:fashion_business_app/utils/localization/shop_translations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TLoaders {
  static hideSnackBar() =>
      ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();

  static customToast({required message}) {
    final ctx = Get.context;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        elevation: 0,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.transparent,
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ShopGlass(
            radius: 28,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Center(
              child: ShopText(
                message,
                style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static successSnackBar({required title, message = '', duration = 3}) {
    final lang = Get.locale?.languageCode ?? 'vi';
    Get.snackbar(
      shopTranslate(title, language: lang),
      shopTranslate(message, language: lang),
      isDismissible: true,
      shouldIconPulse: false,
      backgroundColor: const Color(0xE6173E32),
      barBlur: 18,
      colorText: TColors.white,
      snackPosition: SnackPosition.TOP,
      borderRadius: 18,
      borderColor: Colors.white.withValues(alpha: 0.22),
      borderWidth: 1,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(14),
      icon: const Icon(
        Icons.check_circle_rounded,
        color: Color(0xFFDDEABB),
      ),
    );
  }

  static warningSnackBar({required title, message = ''}) {
    final lang = Get.locale?.languageCode ?? 'vi';
    Get.snackbar(
      shopTranslate(title, language: lang),
      shopTranslate(message, language: lang),
      isDismissible: true,
      shouldIconPulse: false,
      colorText: TColors.white,
      backgroundColor: const Color(0xE6B45309),
      barBlur: 18,
      borderColor: Colors.white.withValues(alpha: 0.22),
      borderWidth: 1,
      borderRadius: 18,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(20),
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: TColors.white,
      ),
    );
  }

  static errorSnackBar({required title, message = ''}) {
    final lang = Get.locale?.languageCode ?? 'vi';
    Get.snackbar(
      shopTranslate(title, language: lang),
      shopTranslate(message, language: lang),
      isDismissible: true,
      shouldIconPulse: false,
      colorText: TColors.white,
      backgroundColor: const Color(0xE6B91C1C),
      barBlur: 18,
      borderColor: Colors.white.withValues(alpha: 0.22),
      borderWidth: 1,
      borderRadius: 18,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(20),
      icon: const Icon(
        Icons.error_outline_rounded,
        color: TColors.white,
      ),
    );
  }
}
