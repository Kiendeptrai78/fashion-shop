import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class TFullScreenLoader {
  static bool _isShowing = false;

  static void openLoadingDialog(String text, String animation) {
    final ctx = Get.overlayContext;
    if (ctx == null || _isShowing) return;
    _isShowing = true;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (context) => PopScope(canPop: false, child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 24),
          ShopText(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, height: 1.6)),
        ])),
      )),
    ).whenComplete(() => _isShowing = false);
  }

  static void stopLoading() {
    if (!_isShowing) return;
    final ctx = Get.overlayContext;
    _isShowing = false;
    if (ctx != null && Navigator.of(ctx).canPop()) {
      Navigator.of(ctx).pop();
    }
  }
}
