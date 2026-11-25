import 'package:fashion_business_app/features/shop/screens/order/order.dart';
import 'package:fashion_business_app/features/shop/services/vnpay_sandbox_service.dart';
import 'package:fashion_business_app/navigation_menu.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class CheckoutCompleteScreen extends StatelessWidget {
  const CheckoutCompleteScreen({super.key, this.vnpayResult});

  final VnPayTransactionResult? vnpayResult;

  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final vnp = vnpayResult;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 86,
                color: vnp != null
                    ? const Color(0xFF16A34A)
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                vnp != null
                    ? (isEn
                        ? 'VNPay Payment Successful!'
                        : 'Thanh toán VNPay thành công!')
                    : (isEn ? 'Your order is in.' : 'Đã nhận đơn hàng của bạn.'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ShopText(
                'Follow its progress in My Orders.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
              if (vnp != null) ...[
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF005BAA).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Iconsax.shield_tick,
                            size: 18,
                            color: Color(0xFF005BAA),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Biên lai thanh toán VNPay (Sandbox)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: Color(0xFF003E78),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _receiptRow('Mã tham chiếu', vnp.txnRef),
                      _receiptRow('Mã GD VNPay', vnp.transactionNo),
                      _receiptRow('Ngân hàng / Kênh', vnp.bankCode),
                      _receiptRow(
                        'Số tiền đã thanh toán',
                        '${NumberFormat('#,###', 'vi_VN').format(vnp.amountVnd)} ₫',
                      ),
                      _receiptRow('Trạng thái', 'Thành công (Mã 00)'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.off(() => const OrderScreen()),
                  child: const ShopText('My Orders'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Get.offAll(() => const NavigationMenu()),
                child: const ShopText('Keep shopping'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      );
}
