import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/common/styles/shadows.dart';
import 'package:fashion_business_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:fashion_business_app/common/widgets/icon/circular_icon.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/common/widgets/product/favourite_icon/favourite_icon.dart';
import 'package:fashion_business_app/common/widgets/product/product_carts/product_cart_add_button.dart';
import 'package:fashion_business_app/common/widgets/text/brand_title_text_with_verified_icon.dart';
import 'package:fashion_business_app/common/widgets/text/product_title.dart';
import 'package:fashion_business_app/features/shop/controllers/product/product_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/screens/product_details/product_details.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/constants/image_strings.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';

import 'product_price_text.dart';

class TProductCartVertical extends StatelessWidget {
  const TProductCartVertical({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final controller = ProductController.instance;
    final salePercentage = controller.calculateSalePercentage(product.price, product.salePrice);
    final dark = THelperFunctions.isDarkMode(context);
    return GestureDetector(
      onTap: () => Get.to(() =>  ProductDetail(product: product,)),
      child: Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
            boxShadow: [TShadowStyle.verticalProductShadow],
            borderRadius: BorderRadius.circular(TSizes.productImageRadius),
            color: dark ? TColors.darkerGrey : TColors.light),
        child: Column(

          children: [
            ///thumbnail
            TRoundedContainer(
              backgroundColor: dark ? TColors.dark : TColors.light,
              // width: 170,
              // height: 170,
              child: Stack(
                children: [
                  ///image
                   Center(
                     child: TRoundedImage(
                       imageUrl: product.thumbnail,
                       backgroundColor: TColors.light,
                       applyImageRadius: true,
                       isNetworkImage: true,
                     ),
                   ),

                  if(salePercentage != null)
                  ///sale tag
                  Positioned(
                      top: 12,
                      child: TRoundedContainer(
                        radius: TSizes.sm,
                        backgroundColor: TColors.secondary.withOpacity(0.8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: TSizes.sm, vertical: TSizes.xs),
                        child: Text(
                          '$salePercentage%',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge!
                              .apply(color: TColors.black),
                        ),
                      )),

                  ///favourite icon button
                   Positioned(
                      top: 0,
                      right: 0,
                      child: TFavouriteIcon(productId: product.id,)
                  )
                ],
              ),
            ),
            const SizedBox(
              height: TSizes.spaceBtwItems / 2,
            ),

            ///detail
             Padding(
              padding: const EdgeInsets.only(left: TSizes.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   TProductTextTitle(title: product.title, smallSize: true,),
                  const SizedBox(height: TSizes.spaceBtwItems / 2,),

                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ///price
                 Flexible(child: Column(
                   children: [
                     if(product.productType == ProductType.single.toString() && product.salePrice > 0)
                     Padding(
                       padding: const EdgeInsets.only(left: TSizes.sm),
                       child: Text(product.price.toString(),style: Theme.of(context).textTheme.labelMedium!.apply(decoration: TextDecoration.lineThrough),)
                     ) ,
                     Padding(
                       padding: const EdgeInsets.only(left: TSizes.sm),
                       child: TProductPriceText(price: controller.getProductPrice(product),)
                     )
                   ],
                 )),
                ///add to cart
                ProductCartAddToCartButton(product: product)
              ],
            )
          ],
        ),
      ),
    );
  }
}



