import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';

class TProductTextTitle extends StatelessWidget {
  const TProductTextTitle(
      {super.key,
      required this.title,
      this.smallSize = false,
      this.maxLines = 2,
      this.textAlign = TextAlign.left
      });
  final String title;
  final bool smallSize;
  final int? maxLines;
  final TextAlign? textAlign;
  @override
  Widget build(BuildContext context) {
    return ShopText(
      title,
      style: smallSize
          ? Theme.of(context).textTheme.labelLarge
          : Theme.of(context).textTheme.titleSmall,
      softWrap: true,
      textAlign: textAlign,
    );
  }
}
