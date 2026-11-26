import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/utils/helpers/pricing_caculator.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TBillingAmountSection extends StatelessWidget {
  const TBillingAmountSection({
    super.key,
    this.discount = 0,
    this.coinDiscount = 0,
    this.couponCode = '',
    this.productDiscount = 0,
    this.shippingDiscount = 0,
    this.productCouponCode = '',
    this.shippingCouponCode = '',
  });

  final double discount;
  final double coinDiscount;
  final String couponCode;
  final double productDiscount;
  final double shippingDiscount;
  final String productCouponCode;
  final String shippingCouponCode;

  @override
  Widget build(BuildContext context) => Obx(() {
        final subtotal = CartController.instance.totalCartPrice.value;
        final lang = Localizations.localeOf(context).languageCode;
        final isEn = lang == 'en';
        final shippingCost = double.parse(
          TPricingCalculator.calculateShippingCost(subtotal, 'US'),
        );
        final taxCost = double.parse(
          TPricingCalculator.calculateTax(subtotal, 'US'),
        );
        final totalOff = (productDiscount + shippingDiscount) > 0
            ? (productDiscount + shippingDiscount)
            : discount;
        final finalTotal =
            (TPricingCalculator.calculateTotalPrice(subtotal, 'US') - totalOff - coinDiscount)
                .clamp(0.0, double.infinity);

        final hasSeparateBreakdown =
            productDiscount > 0 || shippingDiscount > 0;

        return Column(
          children: [
            _amount(context, 'Subtotal', subtotal.toStringAsFixed(2), lang),
            const SizedBox(height: 10),
            _amount(context, 'Shipping', shippingCost.toStringAsFixed(2), lang),
            const SizedBox(height: 10),
            _amount(context, 'Tax', taxCost.toStringAsFixed(2), lang),
            if (hasSeparateBreakdown) ...[
              if (shippingDiscount > 0) ...[
                const SizedBox(height: 10),
                _discountRow(
                  label: isEn ? 'Shipping discount' : 'Miễn phí vận chuyển',
                  code: shippingCouponCode,
                  amount: shippingDiscount,
                  lang: lang,
                ),
              ],
              if (productDiscount > 0) ...[
                const SizedBox(height: 10),
                _discountRow(
                  label: 'Discount',
                  code: productCouponCode,
                  amount: productDiscount,
                  lang: lang,
                  useShopTextLabel: true,
                ),
              ],
            ] else if (discount > 0) ...[
              const SizedBox(height: 10),
              _discountRow(
                label: 'Discount',
                code: couponCode,
                amount: discount,
                lang: lang,
                useShopTextLabel: true,
              ),
            ],
            if (coinDiscount > 0) ...[
              const SizedBox(height: 10),
              _discountRow(label: isEn ? 'VELORA coins' : 'Quy đổi xu', code: '',
                amount: coinDiscount, lang: lang),
            ],
            const Divider(height: 26, color: Color(0xFFE5E7EB)),
            _amount(
              context,
              'Order total',
              finalTotal.toString(),
              lang,
              total: true,
            ),
          ],
        );
      });

  Widget _discountRow({
    required String label,
    required String code,
    required double amount,
    required String lang,
    bool useShopTextLabel = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (useShopTextLabel)
                ShopText(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF475569),
                  ),
                )
              else
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF475569),
                  ),
                ),
              if (code.trim().isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  '(${code.trim().toUpperCase()})',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF173E32),
                  ),
                ),
              ],
            ],
          ),
        ),
        ShopText(
          formatShopMoney(-amount, language: lang),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF173E32),
          ),
        ),
      ],
    );
  }

  Widget _amount(
    BuildContext context,
    String label,
    String value,
    String lang, {
    bool total = false,
  }) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShopText(
            label,
            style: TextStyle(
              fontWeight: total ? FontWeight.w700 : FontWeight.w400,
              fontSize: total ? 15 : 14,
              color: total ? const Color(0xFF111827) : const Color(0xFF475569),
            ),
          ),
          ShopText(
            formatShopMoney(num.parse(value), language: lang),
            style: TextStyle(
              fontSize: total ? 19 : 14,
              fontWeight: total ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      );
}
