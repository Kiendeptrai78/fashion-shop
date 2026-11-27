import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/common/widgets/product/payment_method/payment_method.dart';
import 'package:fashion_business_app/common/widgets/text/section_heading.dart';
import 'package:fashion_business_app/features/shop/controllers/product/checkout_controller.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class TBillingPaymentSection extends StatelessWidget {
  const TBillingPaymentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final controller = CheckoutController.instance;

    return Column(
      children: [
        TSectionHeading(
          title: 'Payment Method',
          buttonTitle: 'Change',
          onPressed: () => controller.selectPaymentMethod(context),
        ),
        const SizedBox(height: TSizes.spaceBtwItems / 2),
        Obx(() {
          final method = controller.selectedPaymentMethod.value;
          final isVnPay = method.name == CheckoutController.vnpayMethodName;
          return Material(
            color: dark ? const Color(0xFF18221D) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isVnPay
                    ? const Color(0xFF005BAA).withValues(alpha: 0.35)
                    : Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => controller.selectPaymentMethod(context),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    if (isVnPay)
                      const VnPayBrandBadge(width: 60, height: 42)
                    else
                      Container(
                        width: 60,
                        height: 42,
                        padding: const EdgeInsets.all(6),
                        decoration: ShopGlassDecoration(
                          color: dark
                              ? const Color(0xFF22352C)
                              : const Color(0xFFEBF2EE),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: method.image.isEmpty
                            ? const Icon(
                                Iconsax.money_send,
                                color: Color(0xFF173E32),
                              )
                            : Image(
                                image: AssetImage(method.image),
                                fit: BoxFit.contain,
                              ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isVnPay
                                ? (isEn
                                    ? 'VNPay Online Payment (Sandbox)'
                                    : 'Thanh toán trực tuyến VNPay (Test)')
                                : (isEn
                                    ? 'Cash on Delivery (COD)'
                                    : 'Thanh toán khi nhận hàng (COD)'),
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isVnPay
                                ? (isEn
                                    ? 'VNPAY-QR · NCB Test Card · Visa/Mastercard'
                                    : 'VNPAY-QR · Thẻ ATM NCB · Visa/Mastercard')
                                : (isEn
                                    ? 'Pay cash when your order arrives'
                                    : 'Trả tiền mặt trực tiếp khi nhận giày'),
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 20),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
