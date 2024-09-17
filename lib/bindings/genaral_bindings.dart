import 'package:get/get.dart';
import 'package:fashion_business_app/features/authentication/controllers/signup/network_manager.dart';
import 'package:fashion_business_app/features/personalization/controllers/address_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/checkout_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/variation_controller.dart';

class GeneralBinding extends Bindings{
  @override
  void dependencies() {
    Get.put(NetworkManager());
    Get.put(VariationController());
    Get.put(AddressController());
    Get.put(CheckoutController());

  }

}