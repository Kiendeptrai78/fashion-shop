import 'package:flutter/material.dart';
import 'package:fashion_business_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:fashion_business_app/common/widgets/images/circular_image.dart';
import 'package:fashion_business_app/common/widgets/text/brand_title_text_with_verified_icon.dart';
import 'package:fashion_business_app/features/shop/models/brand_model.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';

import '../../../utils/constants/image_strings.dart';

class TBrandCard extends StatelessWidget {
  const TBrandCard({
    super.key, required this.showBorder, this.onTap, required this.brand,
  });

  final BrandModel brand;
  final bool showBorder;
  final void Function()? onTap;
  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return GestureDetector(
      onTap: onTap,
      child: TRoundedContainer(
        padding: const EdgeInsets.all(TSizes.sm),
        showBorder: showBorder,
        backgroundColor: Colors.transparent,
        child: Row(
          children: [
            ///icon product
            Flexible(
              child: TCircularImage(
                image: brand.image,
                isNetworkImage: true,
                backgroundColor: Colors.transparent,
                overlayColor: dark ? TColors.white : TColors.black,
              ),),
            const SizedBox(width: TSizes.spaceBtwItems / 4,),

            ///text
            Expanded(child:  Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                 TBrandTitleWithVerifiedIcon(title: brand.name,brandTextSizes: TextSizes.large,),
                Text('Products',overflow: TextOverflow.ellipsis,style: Theme.of(context).textTheme.labelMedium,)
              ],
            ))
          ],
        ),
      ),
    );
  }
}
