import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/icon/circular_icon.dart';
import 'package:fashion_business_app/common/widgets/layouts/grid_layout.dart';
import 'package:fashion_business_app/common/widgets/loaders/animation_loader.dart';
import 'package:fashion_business_app/common/widgets/product/product_carts/product_cart_vertical.dart';
import 'package:fashion_business_app/common/widgets/shimmer/vertical_product_shimmer.dart';
import 'package:fashion_business_app/features/shop/controllers/product/favourite_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/screens/all_product/all_product.dart';
import 'package:fashion_business_app/features/shop/screens/home/home_screen.dart';
import 'package:fashion_business_app/navigation_menu.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/constants/image_strings.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/helpers/cloud_helper_function.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';

class WishList extends StatelessWidget {
  const WishList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = FavouritesController.instance;
    final dark = THelperFunctions.isDarkMode(context);
    return  Scaffold(
      backgroundColor: dark ? TColors.black : TColors.white,
      appBar: TAppbar(
        showBackArrow: false,
        title:  Text('Wishlist',style: TextStyle(fontSize: 20, color: dark ? TColors.white :  TColors.dark),),
        actions: [
          TCircularIcon(icon: Iconsax.add,onPressed: () => Get.to(const HomeScreen()))
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Obx(
              () => FutureBuilder(future: controller.favouriteProducts(), builder: (context, snapshot){

                final emptyWidget = TAnimationLoaderWidget(
                  text: 'WishList is Empty...',
                  showAction: true,
                  actionText: 'Let\'s add some',
                  animation: TImages.wishlist,
                  onActionPressed: () => Get.off(() => const NavigationMenu()),
                );

                const loader = TVerticalProductShimmer(itemCount: 6,);
                final widget = TCloudHelperFunctions.checkMultiRecordState(snapshot: snapshot, loader: loader, nothingFound: emptyWidget);
                if(widget != null) return widget;

                final products = snapshot.data!;
                return TGridLayout(itemCount: products.length, itemBuilder: (_,index) =>  TProductCartVertical(product: products[index]));
              })
          )
        ),
      ),
    );
  }
}
