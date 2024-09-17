import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/admin/screen/products/add_products.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/icon/circular_icon.dart';
import 'package:fashion_business_app/common/widgets/shimmer/vertical_product_shimmer.dart';
import 'package:fashion_business_app/features/shop/controllers/all_product_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/product_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/helpers/cloud_helper_function.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';

import 'widgets/sortable_product_admin.dart';

class ShowProductAdmin extends StatelessWidget {
  const ShowProductAdmin(
      {super.key, required this.title, this.query, this.futureMethod});

  final String title;
  final Query? query;
  final Future<List<ProductModel>>? futureMethod;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final controller = Get.put(AllProductController());

    return Scaffold(
      backgroundColor: dark ? TColors.black : TColors.light,
      appBar: TAppbar(
          title: Text(title),
          showBackArrow: true,
          actions: [
            TCircularIcon(icon: Iconsax.add, onPressed: () => Get.to(() => const AddProducts()))
          ]
      ),
      body: Column( // Thêm Column bao quanh Expanded
        children: [
          Expanded(
            child: FutureBuilder(
              future: futureMethod ?? controller.fetchProductByQuery(query),
              builder: (context, snapshot) {
                const loader = TVerticalProductShimmer();
                final widget = TCloudHelperFunctions.checkMultiRecordState(snapshot: snapshot, loader: loader);
                if (widget != null) return widget;

                // Products found
                final products = snapshot.data!;
                return TSortableProductAdmin(products: products);
              },
            ),
          ),
        ],
      ),
    );
  }
}
