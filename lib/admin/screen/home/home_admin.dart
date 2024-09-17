import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:fashion_business_app/admin/screen/customers/show_customer.dart';
import 'package:fashion_business_app/admin/screen/orders/order_admin.dart';
import 'package:fashion_business_app/admin/screen/products/show_product_admin.dart';
import 'package:fashion_business_app/common/widgets/shimmer/shimmer.dart';
import 'package:fashion_business_app/data/repositories/authentication/authentication_repository.dart';
import 'package:fashion_business_app/features/personalization/controllers/user_controller.dart';
import 'package:fashion_business_app/features/personalization/screens/profile/profile_screen.dart';
import 'package:fashion_business_app/features/shop/controllers/product/order_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/product_controller.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/constants/text_strings.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';

import 'widget/home_proceeds.dart';
import 'widget/profile_admin.dart';

class HomeScreenAdmin extends StatelessWidget {
  const HomeScreenAdmin({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final userController = Get.put(UserController());
    final productController = Get.put(ProductController());

    return Scaffold(
      backgroundColor: dark ? TColors.black : TColors.light,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Home'),
            const Spacer(),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Iconsax.notification),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(width: TSizes.spaceBtwItems),
            const Icon(Icons.email_outlined),
          ],
        ),
        iconTheme: IconThemeData(color: dark ? Colors.white : Colors.black),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
              ),
              child: ProfileAdmin(controller: userController),
            ),
            ListTile(
              title: const Row(
                children: [
                  Icon(Icons.image),
                  SizedBox(
                    width: TSizes.spaceBtwItems / 2,
                  ),
                  Text('Loading Images')
                ],
              ),
              onTap: () {
                // Xử lý khi người dùng chọn mục trong menu
              },
            ),
            ListTile(
              title: const Row(
                children: [
                  Icon(Iconsax.ship),
                  SizedBox(
                    width: TSizes.spaceBtwItems / 2,
                  ),
                  Text('Orders')
                ],
              ),
              onTap: () => Get.to(() => const OrderAdmin()),
            ),
            ListTile(
              title: const Row(
                children: [
                  Icon(Iconsax.box),
                  SizedBox(
                    width: TSizes.spaceBtwItems / 2,
                  ),
                  Text('Products')
                ],
              ),
              onTap: () => Get.to(() => ShowProductAdmin(
                    title: 'Products',
                    futureMethod: productController
                        .fetchAllFeaturedProductsNotIsFeatured(),
                  )),
            ),

            ListTile(
              title: const Row(
                children: [
                  Icon(Iconsax.user),
                  SizedBox(
                    width: TSizes.spaceBtwItems / 2,
                  ),
                  Text('Customers')
                ],
              ),
              onTap: () => Get.to(() => const ShowCustomer()),
            ),
            const Divider(),
            TextButton(
              onPressed: () {
                AuthenticationRepository.instance.logoutAdmin();
                Navigator.pop(context);
              },
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
      body: const HomeProceeds(),
    );
  }
}
