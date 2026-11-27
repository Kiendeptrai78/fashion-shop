import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/device/device_utility.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class TSearchContainer extends StatelessWidget {
  const TSearchContainer({
    super.key,
    required this.text,
    this.icon = Iconsax.search_normal,
    this.showBackground = true,
    this.showBorder = true,
    this.padding = const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
  });

  final String text;
  final IconData? icon;
  final bool showBackground, showBorder;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final inner = Row(
      children: [
        Icon(icon, color: TColors.darkGrey, size: 20),
        const SizedBox(width: TSizes.spaceBtwItems),
        Expanded(
          child: ShopText(
            text,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );

    return Padding(
      padding: padding,
      child: showBackground
          ? ShopGlass(
              width: TDeviceUtils.getScreenWith(context),
              radius: TSizes.cardRadiusLg,
              padding: const EdgeInsets.all(TSizes.md),
              child: inner,
            )
          : Container(
              width: TDeviceUtils.getScreenWith(context),
              padding: const EdgeInsets.all(TSizes.md),
              decoration: ShopGlassDecoration(
                color: Colors.transparent,
                borderRadius:
                    showBorder ? BorderRadius.circular(TSizes.cardRadiusLg) : null,
                border: showBorder
                    ? Border.all(
                        color: dark ? TColors.darkerGrey : TColors.borderSecondary,
                      )
                    : null,
              ),
              child: inner,
            ),
    );
  }
}
