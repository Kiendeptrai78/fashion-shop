import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:fashion_business_app/common/widgets/text/section_heading.dart';
import 'package:fashion_business_app/features/shop/controllers/product/checkout_controller.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';

class TBillingPaymentSection extends StatelessWidget {
  const TBillingPaymentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final controller = CheckoutController.instance ;

    return  Column(
      children: [
        TSectionHeading(title: 'Payment Method',buttonTitle: 'Change',onPressed: () => controller.selectPaymentMethod(context),),
        const SizedBox(height: TSizes.spaceBtwItems / 2,),
        Obx(() => Row(
          children: [
            TRoundedContainer(
              width: 60,
              height: 45,
              backgroundColor: dark ? TColors.light : TColors.white,
              padding: const EdgeInsets.all(TSizes.sm),
              child:  controller.selectedPaymentMethod.value.image.isEmpty ? const Icon(Iconsax.bank)
                  : Image(image: AssetImage(controller.selectedPaymentMethod.value.image),fit: BoxFit.contain,),
            ),
            const SizedBox(width: TSizes.spaceBtwItems / 2,),
            Expanded(child: ShopText(controller.selectedPaymentMethod.value.name == 'Demo bank' ? 'Bank payment' : controller.selectedPaymentMethod.value.name,style: Theme.of(context).textTheme.bodyLarge,))

          ],
        ))
      ],
    ) ;
  }
}
