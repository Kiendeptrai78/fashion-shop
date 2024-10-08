import 'package:flutter/material.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/brands/brand_card.dart';
import 'package:fashion_business_app/common/widgets/product/sortable/sortable_product.dart';
import 'package:fashion_business_app/common/widgets/shimmer/vertical_product_shimmer.dart';
import 'package:fashion_business_app/features/shop/controllers/brand_controller.dart';
import 'package:fashion_business_app/features/shop/models/brand_model.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/helpers/cloud_helper_function.dart';

class BrandProduct extends StatelessWidget {
  const BrandProduct({super.key, required this.brand});

  final BrandModel brand;
  @override
  Widget build(BuildContext context) {
    final controller = BrandController.instance;

    return  Scaffold(
      appBar:  TAppbar(title: Text(brand.name)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              ///brands detail
              TBrandCard(showBorder: true, brand: brand,),
              const SizedBox(height: TSizes.spaceBtwSections,),

              FutureBuilder(future: controller.getBrandProducts(brandId: brand.id), builder: (context, snapshot){

                ///handle loader, no record, or error message
                const loader = TVerticalProductShimmer();
                final widget = TCloudHelperFunctions.checkMultiRecordState(snapshot: snapshot,loader: loader);
                if(widget != null) return widget;

                ///record found!
                final brandProducts = snapshot.data!;
                return  TSortableProduct(products: brandProducts);
              })
            ],
          ),
        ),
      ),
    );
  }
}
