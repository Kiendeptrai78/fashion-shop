import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/common/widgets/product/product_carts/product_cart_horizontal.dart';
import 'package:fashion_business_app/common/widgets/shimmer/horizontal_product_shimmer.dart';
import 'package:fashion_business_app/common/widgets/text/section_heading.dart';
import 'package:fashion_business_app/features/shop/controllers/category_controller.dart';
import 'package:fashion_business_app/features/shop/models/category_model.dart';
import 'package:fashion_business_app/features/shop/screens/all_product/all_product.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/constants/image_strings.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/helpers/cloud_helper_function.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';

class SubCategoriesScreen extends StatelessWidget {
  const SubCategoriesScreen({super.key, required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    final controller = CategoryController.instance;
    final dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      appBar: TAppbar(
        title: Text(category.name,
            style: TextStyle(
                fontSize: 20, color: dark ? TColors.white : TColors.dark)),
        showBackArrow: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              ///banner
              const TRoundedImage(imageUrl: TImages.banner2,width: double.infinity,height: null,applyImageRadius: true,),
              const SizedBox(height: TSizes.spaceBtwSections,),

              ///sub_categories
              FutureBuilder(future: controller.getSubCategories(category.id), builder: (context, snapshot){

                ///no record
                const loader = THorizontalProductShimmer();
                final widget = TCloudHelperFunctions.checkMultiRecordState(snapshot: snapshot,loader: loader);
                if(widget != null) return widget;

                ///record found
                final subCategories = snapshot.data!;

                return ListView.builder(
                    shrinkWrap: true,
                    itemCount: subCategories.length,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (_, index){

                      final subCategory = subCategories[index];

                      return FutureBuilder(future: controller.getCategoryProducts(categoryId: subCategory.id), builder: (context, snapshot){

                        ///no record
                        final widget = TCloudHelperFunctions.checkMultiRecordState(snapshot: snapshot,loader: loader);
                        if(widget != null) return widget;

                        ///record found
                        final products = snapshot.data!;

                        return Column(
                          children: [
                            ///heading
                            TSectionHeading(
                                title: subCategory.name,
                                onPressed: () => Get.to(
                                        () => AllProductScreen(
                                      title: subCategory.name,
                                      futureMethod: controller.getCategoryProducts(categoryId: subCategory.id, limit: -1),))
                            ),
                            const SizedBox(height: TSizes.spaceBtwItems / 2,),

                            ///categories
                            SizedBox(
                              height: 120,
                              child:  ListView.separated(
                                  itemCount: products.length,
                                  scrollDirection: Axis.horizontal,
                                  separatorBuilder: (context,index) => const SizedBox(width: TSizes.spaceBtwItems,),
                                  itemBuilder: (context,index) =>  TProductCartHorizontal(product: products[index])
                              ),
                            )

                          ],
                        );
                      });
                    },

                );

              })
            ],
          ),
        ),
      ),
    );
  }
}
