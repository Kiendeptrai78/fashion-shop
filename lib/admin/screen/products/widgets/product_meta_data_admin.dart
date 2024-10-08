import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:fashion_business_app/common/widgets/images/circular_image.dart';
import 'package:fashion_business_app/common/widgets/product/product_carts/product_price_text.dart';
import 'package:fashion_business_app/common/widgets/text/brand_title_text_with_verified_icon.dart';
import 'package:fashion_business_app/common/widgets/text/product_title.dart';
import 'package:fashion_business_app/features/shop/controllers/all_product_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/product_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/variation_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';

class TProductMetaDataAdmin extends StatelessWidget {
  const TProductMetaDataAdmin({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final controller = ProductController.instance;
    final controllerAll = AllProductController.instance;
    final controllerVariation = Get.put(VariationController());

    final salePercentage = controller.calculateSalePercentage(product.price, product.salePrice);
    return Column(
      crossAxisAlignment:  CrossAxisAlignment.start,
      children: [
        ///price and sale price
        Row(
          children: [
            if(salePercentage != null)
            ///sale tag
              TRoundedContainer(
                radius: TSizes.sm,
                backgroundColor: TColors.secondary.withOpacity(0.8),
                padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs),
                child: Text(
                  '$salePercentage%',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge!
                      .apply(color: TColors.black),
                ),
              ),
            if(salePercentage != null)  const SizedBox(width: TSizes.spaceBtwItems,),

            ///price
            if(product.productType == ProductType.single.toString() && product.salePrice > 0)
              Text('\$${product.price}',style: Theme.of(context).textTheme.titleSmall!.apply(decoration: TextDecoration.lineThrough),),
            if(product.productType == ProductType.single.toString() && product.salePrice > 0)
              const SizedBox(width: TSizes.spaceBtwItems,),
            TProductPriceText(price: controller.getProductPrice(product),isLarge: true,)
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems,),

        ///title
        TProductTextTitle(title: product.title),
        const SizedBox(height: TSizes.spaceBtwItems / 1.5,),

        ///stock status
          Row(
          children: [
            const TProductTextTitle(title: 'Quantity:'),
            const SizedBox(width: TSizes.spaceBtwItems,),
            Text(product.stock.toStringAsFixed(0),style: Theme.of(context).textTheme.titleMedium,),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems / 1.5,),


      ],
    );
  }
}
