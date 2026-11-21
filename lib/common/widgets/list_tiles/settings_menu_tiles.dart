import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';

class TSettingMenuTiles extends StatelessWidget {
  const TSettingMenuTiles(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      this.trailing,
      this.onTap
      });

  final IconData icon;
  final String title, subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        size: 28,
        color: TColors.primaryColor,
      ),
      title: ShopText(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: ShopText(
        subtitle,
        style: Theme.of(context).textTheme.labelMedium,
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
