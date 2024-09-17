import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/brands/brand_card.dart';
import 'package:fashion_business_app/common/widgets/layouts/grid_layout.dart';
import 'package:fashion_business_app/common/widgets/product/sortable/sortable_product.dart';
import 'package:fashion_business_app/common/widgets/shimmer/brands_shimmer.dart';
import 'package:fashion_business_app/common/widgets/text/section_heading.dart';
import 'package:fashion_business_app/features/shop/controllers/brand_controller.dart';
import 'package:fashion_business_app/features/shop/models/brand_model.dart';
import 'package:fashion_business_app/features/shop/screens/brands/brand_products.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';

class AllBrandScreen extends StatelessWidget {
  const AllBrandScreen({super.key, this.futureMethod});

  final Future<List<BrandModel>>? futureMethod;


  @override
  Widget build(BuildContext context) {
    final brandController = BrandController.instance;
    return Scaffold(
      appBar: const TAppbar(
        title: Text('Brands'),
        showBackArrow: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              ///Heading
              const TSectionHeading(
                title: 'Brands',
                showActionButton: false,
              ),
              const SizedBox(
                height: TSizes.spaceBtwItems,
              ),

              ///brands
              Obx(() {
                if(brandController.isLoading.value) return const TBrandShimmer();

                if(brandController.featuredBrands.isEmpty){
                  return Center(child: Text('No Data Found!',style: Theme.of(context).textTheme.bodyMedium!.apply(color: Colors.white),));
                }else{
                  return  TGridLayout(
                      itemCount: brandController.featuredBrands.length,
                      mainAxisExtent: 80,
                      itemBuilder: (_,index){
                        final brand = brandController.featuredBrands[index];
                        return  TBrandCard(
                          showBorder: true,
                          brand: brand,
                          onTap: () => Get.to(() =>  BrandProduct(brand: brand,)),);
                      }
                  );
                }
              })
            ],
          ),
        ),
      ),
    );
  }
}
