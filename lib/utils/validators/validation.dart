import 'package:get/get.dart';
import 'package:fashion_business_app/utils/localization/shop_translations.dart';
class TValidator {
  ///empty text validation
  static String? validateEmptyText(String? fieldName,String? value){
    if(value == null || value.isEmpty){
      return shopTranslate('$fieldName is required', language: Get.locale?.languageCode ?? 'vi');
    }
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return shopTranslate('Email is required.', language: Get.locale?.languageCode ?? 'vi');
    }
    // Regular expression for email validation
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegExp.hasMatch(value)) {
      return shopTranslate('Invalid email address.', language: Get.locale?.languageCode ?? 'vi');
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return shopTranslate('Password is required.', language: Get.locale?.languageCode ?? 'vi');
    }

    if (value.length < 6) {
      return shopTranslate('Password must be at least 6 characters long.', language: Get.locale?.languageCode ?? 'vi');
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return shopTranslate('Password must contain at least one number.', language: Get.locale?.languageCode ?? 'vi');
    }

    if (!value.contains(RegExp(r'[!@#%^&*(),.?":{}|<>]'))) {
      return shopTranslate('Password must contain at least one special character.', language: Get.locale?.languageCode ?? 'vi');
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return shopTranslate('Phone number is required.', language: Get.locale?.languageCode ?? 'vi');
    }

    final phoneRegExp = RegExp(r'^\d{10}$');

    if (!phoneRegExp.hasMatch(value)) {
      return shopTranslate('Invalid phone number format (10 digits required)', language: Get.locale?.languageCode ?? 'vi');
    }
    return null;
  }
}
