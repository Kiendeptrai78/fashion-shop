import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

Future<bool?> showVeloraConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
  IconData? icon,
}) {
  final theme = Theme.of(context);
  final dark = theme.brightness == Brightness.dark;
  final accent = destructive ? const Color(0xFFC62828) : const Color(0xFF173E32);
  final accentBg = destructive
      ? (dark ? const Color(0xFF3A1D1D) : const Color(0xFFFFEFEF))
      : (dark ? const Color(0xFF1E372D) : const Color(0xFFEAF2EE));
  final accentIcon = destructive
      ? const Color(0xFFDC2626)
      : (dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32));

  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => Dialog(
      backgroundColor: dark ? const Color(0xFF17241E) : Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5EAE3),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon ?? (destructive ? Iconsax.warning_2 : Iconsax.info_circle),
                  color: accentIcon,
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              ShopText(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              ShopText(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(
                          color: dark ? Colors.white.withValues(alpha: 0.14) : const Color(0xFFD5DDD7),
                        ),
                      ),
                      child: ShopText(
                        cancelLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: ShopText(
                        confirmLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
