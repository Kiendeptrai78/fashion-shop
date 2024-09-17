import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/product/cart/cart_menu_icon.dart';
import 'package:fashion_business_app/common/widgets/shimmer/shimmer.dart';
import 'package:fashion_business_app/features/personalization/controllers/user_controller.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/constants/text_strings.dart';

class THomeAppbar extends StatelessWidget {
  const THomeAppbar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserController());
    final dark = THelperFunctions.isDarkMode(context);
    return TAppbar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TTexts.homeAppbarTitle,
            style: Theme.of(context)
                .textTheme
                .labelMedium!
                .apply(color: dark ? TColors.light : TColors.black),
          ),
           Obx(() {
             if(controller.profileLoading.value){
               return const TShimmerEffect(width: 80, height: 25);
             }else{
               return Text(
                 controller.user.value.fullName,
                 style:  TextStyle(color: dark ? TColors.light : TColors.black,fontSize: 18),
               );
             }

           } )
        ],
      ),
      actions:  [
        TCartCounterIcon(
          // onPressed: () {},
          iconColor: dark ? TColors.light : TColors.black,
        )
      ],
    );
  }
}
