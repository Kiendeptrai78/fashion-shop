import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/features/shop/screens/order/order.dart';
import 'package:fashion_business_app/features/shop/services/vnpay_sandbox_service.dart';
import 'package:fashion_business_app/navigation_menu.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class CheckoutCompleteScreen extends StatelessWidget {
  const CheckoutCompleteScreen({
    super.key,
    this.vnpayResult,
    this.orderTotal,
    this.discountAmount = 0,
    this.couponCode = '',
    this.paymentMethodLabel = '',
  });

  final VnPayTransactionResult? vnpayResult;
  final double? orderTotal;
  final double discountAmount;
  final String couponCode;
  final String paymentMethodLabel;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final isEn = lang == 'en';
    final vnp = vnpayResult;
    final hasCoupon = couponCode.trim().isNotEmpty && discountAmount > 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: ShopGlassDecoration(
                    color: const Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 46,
                    color: Color(0xFF059669),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  vnp != null
                      ? (isEn
                          ? 'VNPay Payment Successful!'
                          : 'Thanh toán VNPay thành công!')
                      : (isEn
                          ? 'Your order has been placed!'
                          : 'Đặt hàng thành công!'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                ShopText(
                  'Follow its progress in My Orders.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
                const SizedBox(height: 22),

                // Clear Order & Voucher Summary Card (shows immediately whether voucher was applied!)
                if (orderTotal != null || hasCoupon)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: ShopGlassDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Iconsax.receipt_item,
                              size: 18,
                              color: Color(0xFF173E32),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isEn
                                    ? 'Order & Voucher Summary'
                                    : 'Chi tiết thanh toán & Mã giảm giá',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Voucher applied / not applied status banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: ShopGlassDecoration(
                            color: hasCoupon
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: hasCoupon
                                  ? const Color(0xFF10B981)
                                      .withValues(alpha: 0.45)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                hasCoupon
                                    ? Icons.check_circle_rounded
                                    : Iconsax.ticket_discount,
                                size: 18,
                                color: hasCoupon
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: hasCoupon
                                    ? Wrap(
                                        spacing: 6,
                                        runSpacing: 3,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            isEn
                                                ? 'Applied voucher'
                                                : 'Đã áp dụng mã',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF065F46),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF173E32),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              couponCode.trim().toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        isEn
                                            ? 'No voucher applied on this order'
                                            : 'Đơn hàng này không dùng mã giảm giá',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                              ),
                              if (hasCoupon)
                                Text(
                                  '-${formatShopMoney(discountAmount, language: lang)}',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF173E32),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (paymentMethodLabel.trim().isNotEmpty)
                          _receiptRow(
                            isEn ? 'Payment method' : 'Phương thức',
                            paymentMethodLabel,
                          ),
                        if (orderTotal != null)
                          _receiptRow(
                            isEn ? 'Total amount' : 'Tổng thanh toán',
                            formatShopMoney(orderTotal!, language: lang),
                            highlight: true,
                          ),
                      ],
                    ),
                  ),

                if (vnp != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: ShopGlassDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF005BAA).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Iconsax.shield_tick,
                              size: 18,
                              color: Color(0xFF005BAA),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isEn
                                    ? 'VNPay Transaction Receipt'
                                    : 'Biên lai giao dịch VNPay',
                                style: const TextStyle(
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
                const SizedBox(height: 26),
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
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool highlight = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: highlight ? 13 : 12,
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                  color: highlight
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF475569),
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: highlight ? 15 : 12.5,
                fontWeight: FontWeight.w800,
                color: highlight
                    ? const Color(0xFF173E32)
                    : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      );
}
