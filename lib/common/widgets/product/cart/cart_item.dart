import 'package:flutter/material.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/common/widgets/text/brand_title_text_with_verified_icon.dart';
import 'package:fashion_business_app/common/widgets/text/product_title.dart';
import 'package:fashion_business_app/features/shop/models/cart_item_model.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/constants/image_strings.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';

class TCartItem extends StatelessWidget {
  const TCartItem({
    super.key,
    required this.cartItem,
  });
  final CartItemModel cartItem;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Row(
      children: [
        TRoundedImage(
          imageUrl: cartItem.image ?? '',
          width: 60,
          height: 60,
          isNetworkImage: true,
          padding: const EdgeInsets.all(TSizes.sm),
          backgroundColor: dark ? TColors.darkerGrey : TColors.light,
        ),
        const SizedBox(
          width: TSizes.spaceBtwItems,
        ),

        ///title, price, size
        Expanded(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TBrandTitleWithVerifiedIcon(title: cartItem.brandName ?? ''),
            Flexible(
                child: TProductTextTitle(
              title: cartItem.title,
              maxLines: 1,
            )),

            ///attributes
            Text.rich(TextSpan(
                children: (cartItem.selectedVariation ?? {})
                    .entries
                    .map((e) => TextSpan(children: [
                          TextSpan(
                              text: ' ${e.key} ',
                              style: Theme.of(context).textTheme.bodySmall),
                          TextSpan(
                              text: ' ${e.value} ',
                              style: Theme.of(context).textTheme.bodyLarge),
                        ]))
                    .toList()
            ))
          ],
        ))
      ],
    );
  }
}
