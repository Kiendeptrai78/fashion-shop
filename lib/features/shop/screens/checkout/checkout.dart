import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/order_controller.dart';
import 'package:fashion_business_app/features/shop/screens/checkout/widgets/billing_amount_section.dart';
import 'package:fashion_business_app/utils/helpers/pricing_caculator.dart';
import '../../../../data/repositories/payment/payment.dart';
import '../../controllers/product/checkout_controller.dart';
import 'widgets/billing_address_section.dart';
import 'widgets/billing_payment_section.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/features/personalization/controllers/address_controller.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const EventChannel eventChannel =
  EventChannel('flutter.native/eventPayOrder');
  static const MethodChannel platform =
  MethodChannel('flutter.native/channelPayOrder');
  String zpTransToken = "";
  String payResult = "";
  bool showResult = false;

  final CheckoutController _checkoutController = CheckoutController.instance;


  Future<void> _createOrderAndPay(String amount) async {
    int parsedAmount = (double.parse(amount) * 22222).toInt(); // Update the amount conversion
    if (parsedAmount < 1000 || parsedAmount > 100000000) {
      setState(() {
        zpTransToken = "Invalid Amount";
      });
      return;
    }
    // Hiển thị vòng quay loading
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // Tạo đơn hàng
    var result = await createOrder(parsedAmount);
    Navigator.pop(context); // Tắt vòng quay loading

    if (result != null) {
      zpTransToken = result.zptranstoken;
      setState(() {
        zpTransToken = result.zptranstoken;
        showResult = true;
      });

      // Tiến hành thanh toán
      String response = "";
      try {
        final String result =
        await platform.invokeMethod('payOrder', {"zptoken": zpTransToken});
        response = result;
        print("payOrder Result: '$result'.");
        if (response == "Payment Success") {
          _processOrder(); // Call order processing method on successful payment
        }
      } on PlatformException catch (e) {
        print("Failed to Invoke: '${e.message}'.");
        response = "Thanh toán thất bại";
      }
      print(response);
      setState(() {
        payResult = response;
      });
    }
  }

  void _processOrder() {
    final orderController = Get.put(OrderController());
    final cartController = CartController.instance;
    final subTotal = cartController.totalCartPrice.value;
    final totalAmount = TPricingCalculator.calculateTotalPrice(subTotal, 'US');

    orderController.processOrder(totalAmount);
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartController.instance;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const TAppbar(showBackArrow: true, title: Text('Checkout',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.6))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('The final details.', style: TextStyle(fontSize: 28,
              fontWeight: FontWeight.w600, letterSpacing: -1)),
          const SizedBox(height: 8),
          Text('Review your pairs and choose how to pay.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 28),
          const TBillingAddressSection(),
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(height: 1)),
          const TBillingPaymentSection(),
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(height: 1)),
          Row(children: [
            const Expanded(child: Text('Your pairs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
            TextButton(onPressed: () => Get.back(), child: const Text('Edit bag')),
          ]),
          const SizedBox(height: 12),
          Obx(() => Column(children: [for (final item in cart.cartItems)
            Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                TRoundedImage(imageUrl: item.image ?? '', width: 84, height: 84, isNetworkImage: true),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.brandName ?? '', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text((item.selectedVariation?.entries ?? []).map((e) => '${e.key}: ${e.value}').join(' · '),
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(spacing: 12, children: [Text('Qty ${item.quantity}', style: theme.textTheme.bodySmall),
                    Text('\$${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600))]),
                ])),
              ])),
          ])),
          const Divider(height: 32),
          const Text('Order summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          const TBillingAmountSection(),
        ]),
      ),
      bottomNavigationBar: Obx(() {
        final subtotal = cart.totalCartPrice.value;
        final total = TPricingCalculator.calculateTotalPrice(subtotal, 'US');
        final zalo = _checkoutController.selectedPaymentMethod.value.name == 'ZaloPay';
        return SafeArea(top: false, child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15)))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total to pay'),
              Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: subtotal <= 0 ? null : () {
                if (AddressController.instance.selectedAddress.value.id.isEmpty) {
                  AddressController.instance.selectNewAddressPopup(context);
                  return;
                }
                if (zalo) { _createOrderAndPay(total.toString()); } else { _processOrder(); }
              },
              child: Text(zalo ? 'Pay with ZaloPay' : 'Place order · Pay on delivery'),
            )),
          ]),
        ));
      }),
    );
  }
}
