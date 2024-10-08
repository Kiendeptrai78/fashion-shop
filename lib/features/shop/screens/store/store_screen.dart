import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/appbar/tabbar.dart';
import 'package:fashion_business_app/common/widgets/custom_shapes/containers/search_container.dart';
import 'package:fashion_business_app/common/widgets/layouts/grid_layout.dart';
import 'package:fashion_business_app/common/widgets/brands/brand_card.dart';
import 'package:fashion_business_app/common/widgets/product/cart/cart_menu_icon.dart';
import 'package:fashion_business_app/common/widgets/shimmer/brands_shimmer.dart';
import 'package:fashion_business_app/common/widgets/text/section_heading.dart';
import 'package:fashion_business_app/features/shop/controllers/brand_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/category_controller.dart';
import 'package:fashion_business_app/features/shop/screens/brands/all_brands.dart';
import 'package:fashion_business_app/features/shop/screens/brands/brand_products.dart';
import 'package:fashion_business_app/features/shop/screens/store/widgets/category_tab.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final categories = CategoryController.instance.featuredCategories;
    final brandController = Get.put(BrandController());

    return  DefaultTabController(
        length: categories.length,
        child: Scaffold(
          backgroundColor: dark ?  TColors.black : TColors.white,
          appBar: TAppbar(
            title:  Text('Store',style: TextStyle(fontSize: 20,color: dark ? TColors.white :  TColors.dark),),
            actions: [
              TCartCounterIcon( iconColor: dark ?  TColors.white : TColors.dark)
            ],
          ),
          body: NestedScrollView(
            headerSliverBuilder: (_,innerBoxIsScrolled){
              return [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  pinned: true,
                  floating: true,
                  expandedHeight: 430,

                  flexibleSpace: Padding(
                    padding: const EdgeInsets.all(TSizes.defaultSpace),
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children:  [

                        ///search bar
                        const SizedBox(height: TSizes.spaceBtwItems,),
                        const TSearchContainer(text: 'Search in store',showBorder: true,showBackground: false,padding: EdgeInsets.zero,),
                        const SizedBox(height: TSizes.spaceBtwSections,),

                        ///Featured brands
                        TSectionHeading(title: 'Featured Brands',onPressed: () => Get.to(() => const AllBrandScreen()),),
                        const SizedBox(height: TSizes.spaceBtwItems / 1.5,),

                        ///brands grid
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
                                    showBorder: false,
                                    brand: brand,
                                    onTap: () => Get.to(() =>  BrandProduct(brand: brand))
                                 );
                           }
                           );
                         }
                       }),
                      ],
                    ),
                  ),

                  ///tab
                  bottom:  TTabBar(tabs: categories.map((category) => Tab(child: Text(category.name))).toList()),
                ),
              ];
            },
            body:  TabBarView(children: categories.map((category) => TCategoryTab(category: category)).toList()),
          ),
        ));
  }
}




