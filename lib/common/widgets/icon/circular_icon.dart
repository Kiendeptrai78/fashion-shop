import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';
import 'package:flutter/material.dart';

class TCircularIcon extends StatelessWidget {
  const TCircularIcon({
    super.key,
    this.width,
    this.height,
    this.size = TSizes.lg,
    required this.icon,
    this.color,
    this.backgroundColor,
    this.onPressed,
  });

  final double? width, height, size;
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final effectiveSize = width ?? height ?? 42.0;
    final effectiveIconColor =
        color ?? (dark ? TColors.white : const Color(0xFF173E32));

    if (onPressed != null) {
      return GlassIconButton(
        size: effectiveSize,
        iconSize: size ?? TSizes.lg,
        iconColor: effectiveIconColor,
        tintColor: backgroundColor,
        useOwnLayer: true,
        onPressed: onPressed,
        icon: Icon(icon, color: effectiveIconColor, size: size),
      );
    }

    return ShopGlass(
      width: width,
      height: height,
      radius: 100,
      color: backgroundColor,
      padding: const EdgeInsets.all(8),
      child: Icon(icon, color: effectiveIconColor, size: size),
    );
  }
}
