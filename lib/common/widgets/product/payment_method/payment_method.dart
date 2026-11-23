import 'package:fashion_business_app/features/shop/controllers/product/checkout_controller.dart';
import 'package:fashion_business_app/features/shop/models/payment_method_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class VnPayBrandBadge extends StatelessWidget {
  const VnPayBrandBadge({super.key, this.width = 58, this.height = 40});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFF005BAA).withValues(alpha: 0.3),
        ),
      ),
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'VN',
                style: TextStyle(
                  color: Color(0xFFED1C24),
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                'PAY',
                style: TextStyle(
                  color: Color(0xFF005BAA),
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TPaymentTile extends StatelessWidget {
  const TPaymentTile({super.key, required this.paymentMethod});

  final PaymentMethodModel paymentMethod;

  @override
  Widget build(BuildContext context) {
    final controller = CheckoutController.instance;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final isVnPay = paymentMethod.name == CheckoutController.vnpayMethodName;

    return Obx(() {
      final selected =
          controller.selectedPaymentMethod.value.name == paymentMethod.name;
      return Material(
        color: selected
            ? (isVnPay
                ? (dark ? const Color(0xFF122840) : const Color(0xFFEFF6FF))
                : (dark ? const Color(0xFF1A3329) : const Color(0xFFF0F7F3)))
            : (dark ? const Color(0xFF18221D) : Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            width: selected ? 1.6 : 1,
            color: selected
                ? (isVnPay ? const Color(0xFF005BAA) : const Color(0xFF173E32))
                : Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            controller.selectedPaymentMethod.value = paymentMethod;
            Get.back();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                if (isVnPay)
                  const VnPayBrandBadge()
                else
                  Container(
                    width: 58,
                    height: 40,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: dark
                          ? const Color(0xFF22352C)
                          : const Color(0xFFEBF2EE),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: paymentMethod.image.isEmpty
                        ? const Icon(
                            Iconsax.money_send,
                            color: Color(0xFF173E32),
                          )
                        : Image(
                            image: AssetImage(paymentMethod.image),
                            fit: BoxFit.contain,
                          ),
                  ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            isVnPay
                                ? (isEn
                                    ? 'VNPay Online Payment'
                                    : 'Thanh toán trực tuyến VNPay')
                                : (isEn
                                    ? 'Cash on Delivery (COD)'
                                    : 'Thanh toán khi nhận hàng (COD)'),
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (isVnPay)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF005BAA),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Sandbox Test',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isVnPay
                            ? (isEn
                                ? 'VNPAY-QR, Local ATM Card (NCB) or Visa/Mastercard'
                                : 'VNPAY-QR, Thẻ ATM nội địa (NCB) hoặc Visa/Mastercard')
                            : (isEn
                                ? 'Inspect your sneakers and pay cash upon delivery'
                                : 'Kiểm tra giày nguyên hộp và thanh toán trực tiếp cho shipper'),
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Theme.of(context).hintColor,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? (isVnPay
                          ? const Color(0xFF005BAA)
                          : const Color(0xFF173E32))
                      : Theme.of(context).hintColor,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
