import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/common/widgets/glass/shop_overlays.dart';
import 'package:fashion_business_app/utils/localization/shop_translations.dart';
import 'package:flutter/material.dart';

Future<bool?> showVeloraConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) {
  final theme = Theme.of(context);
  final dark = theme.brightness == Brightness.dark;
  final lang = Localizations.localeOf(context).languageCode;
  final accent =
      destructive ? const Color(0xFFC62828) : const Color(0xFF173E32);

  return GlassDialog.show<bool>(
    context: context,
    settings: dark ? shopDarkOverlaySettings : shopLightOverlaySettings,
    quality: GlassQuality.standard,
    barrierDismissible: true,
    title: shopTranslate(title, language: lang),
    message: shopTranslate(message, language: lang),
    actions: [
      GlassDialogAction(
        label: shopTranslate(cancelLabel, language: lang),
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
      ),
      GlassDialogAction(
        label: shopTranslate(confirmLabel, language: lang),
        isPrimary: !destructive,
        isDestructive: destructive,
        tintColor: destructive ? null : accent,
        foregroundColor: destructive ? null : Colors.white,
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
      ),
    ],
  );
}
