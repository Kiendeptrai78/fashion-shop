import 'package:fashion_business_app/common/widgets/glass/shop_overlays.dart';
import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TFullScreenLoader {
  static DialogRoute<void>? _route;

  static void openLoadingDialog(String text, String animation) {
    final ctx = Get.overlayContext;
    if (ctx == null || _route?.isActive == true) return;
    final navigator = Navigator.of(ctx, rootNavigator: true);
    final route = DialogRoute<void>(
      context: ctx,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (context) => PopScope(
        canPop: false,
        child: ShopGlassDialog(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const GlassProgressIndicator.circular(
                  size: 30,
                  strokeWidth: 3,
                  useOwnLayer: true,
                ),
                const SizedBox(height: 20),
                ShopText(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    _route = route;
    navigator.push(route).whenComplete(() {
      if (identical(_route, route)) _route = null;
    });
  }

  static void stopLoading() {
    final route = _route;
    _route = null;
    // A callback may have changed the top page; only remove our own dialog.
    if (route?.isActive == true) route!.navigator?.removeRoute(route);
  }
}
