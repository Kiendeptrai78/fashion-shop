import 'package:fashion_business_app/common/widgets/glass/shop_overlays.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/common/widgets/product/payment_method/payment_method.dart';
import 'package:fashion_business_app/features/shop/models/payment_method_model.dart';
import 'package:fashion_business_app/utils/constants/image_strings.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class CheckoutController extends GetxController {
  static CheckoutController get instance => Get.find();

  static const String codMethodName = 'Cash on delivery';
  static const String vnpayMethodName = 'VNPay';

  final selectedPaymentMethod = PaymentMethodModel(
    name: codMethodName,
    image: TImages.paymentDelivery,
  ).obs;

  bool get isVnPaySelected =>
      selectedPaymentMethod.value.name == vnpayMethodName;

  Future<dynamic> selectPaymentMethod(BuildContext context) =>
      showShopBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShopText(
                  'Select Payment Method',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  Localizations.localeOf(context).languageCode == 'en'
                      ? 'Choose online payment via VNPay Sandbox or Cash on Delivery.'
                      : 'Chọn thanh toán trực tuyến qua VNPay hoặc thanh toán khi nhận hàng.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 18),
                TPaymentTile(
                  paymentMethod: PaymentMethodModel(
                    name: vnpayMethodName,
                    image: '',
                  ),
                ),
                const SizedBox(height: 12),
                TPaymentTile(
                  paymentMethod: PaymentMethodModel(
                    name: codMethodName,
                    image: TImages.paymentDelivery,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
