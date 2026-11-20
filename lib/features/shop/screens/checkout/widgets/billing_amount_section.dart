import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/utils/helpers/pricing_caculator.dart';

class TBillingAmountSection extends StatelessWidget {
  const TBillingAmountSection({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    final subtotal = CartController.instance.totalCartPrice.value;
    return Column(children: [
      _amount(context, 'Subtotal', subtotal.toStringAsFixed(2)),
      const SizedBox(height: 12),
      _amount(context, 'Shipping', double.parse(TPricingCalculator.calculateShippingCost(subtotal, 'US')).toStringAsFixed(2)),
      const SizedBox(height: 12),
      _amount(context, 'Tax', double.parse(TPricingCalculator.calculateTax(subtotal, 'US')).toStringAsFixed(2)),
      const Divider(height: 32),
      _amount(context, 'Order total', TPricingCalculator.calculateTotalPrice(subtotal, 'US').toStringAsFixed(2), total: true),
    ]);
  });

  Widget _amount(BuildContext context, String label, String value, {bool total = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontWeight: total ? FontWeight.w600 : FontWeight.w400)),
      Text('\$$value', style: TextStyle(fontSize: total ? 20 : 14,
          fontWeight: total ? FontWeight.w700 : FontWeight.w500)),
    ],
  );
}
