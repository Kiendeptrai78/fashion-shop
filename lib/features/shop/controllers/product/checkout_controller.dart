import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/common/widgets/product/payment_method/payment_method.dart';
import 'package:fashion_business_app/features/shop/models/payment_method_model.dart';
import 'package:fashion_business_app/utils/constants/image_strings.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class CheckoutController extends GetxController {
  static CheckoutController get instance => Get.find();
  final selectedPaymentMethod = PaymentMethodModel(name: 'Cash on delivery', image: TImages.paymentDelivery).obs;

  Future<dynamic> selectPaymentMethod(BuildContext context) => showModalBottomSheet(
    context: context, builder: (_) => SafeArea(child: Padding(padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const ShopText('Select Payment Method', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        TPaymentTile(paymentMethod: PaymentMethodModel(name: 'Cash on delivery', image: TImages.paymentDelivery)),
        const SizedBox(height: 12),
        TPaymentTile(paymentMethod: PaymentMethodModel(name: 'Demo bank', image: '')),
        const SizedBox(height: 12),

      ]),
    )),
  );
}
