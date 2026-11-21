import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';

class TSettingMenuTiles extends StatelessWidget {
  const TSettingMenuTiles({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title, subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF22362D) : const Color(0xFFEBF2EE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
        ),
      ),
      title: ShopText(
        title,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: ShopText(
        subtitle,
        style: theme.textTheme.labelMedium?.copyWith(color: theme.hintColor),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: theme.hintColor),
      onTap: onTap,
    );
  }
}
