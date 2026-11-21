import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class TFullScreenLoader {
  static void openLoadingDialog(String text, String animation) {
    showDialog(
      context: Get.overlayContext!, barrierDismissible: false,
      builder: (context) => PopScope(canPop: false, child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 24),
          ShopText(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, height: 1.6)),
        ])),
      )),
    );
  }
  static stopLoading() { Navigator.of(Get.overlayContext!).pop(); }
}
