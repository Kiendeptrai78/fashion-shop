import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/data/repositories/authentication/authentication_repository.dart';
import 'package:fashion_business_app/features/personalization/controllers/address_controller.dart';
import 'package:fashion_business_app/features/personalization/models/address_model.dart';
import 'package:fashion_business_app/features/personalization/screens/account/coupons_screen.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/features/shop/models/product_availability_helper.dart';
import 'package:fashion_business_app/features/shop/models/shipping_route_helper.dart';
import 'package:fashion_business_app/features/shop/screens/checkout/vnpay_sandbox_screen.dart';
import 'package:fashion_business_app/features/shop/screens/checkout/widgets/billing_amount_section.dart';
import 'package:fashion_business_app/features/shop/services/vnpay_sandbox_service.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';

import '../../controllers/product/checkout_controller.dart';
import 'widgets/billing_address_section.dart';
import 'widgets/billing_payment_section.dart';
import 'widgets/checkout_complete_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _checkoutController = CheckoutController.instance;
  final _benefits = CustomerBenefits.instance;
  final _orderId = const Uuid().v4();
  ShopCoupon? _productCoupon;
  ShopCoupon? _shippingCoupon;
  String? _error;

  @override
  void initState() {
    super.initState();
    final addresses = AddressController.instance;
    if (addresses.selectedAddress.value.id.isEmpty) {
      addresses.getAllUserAddresses().catchError((_) => <AddressModel>[]);
    }
    _syncSavedCoupons();
    _benefits.initialize().then((_) {
      if (!mounted) return;
      setState(_syncSavedCoupons);
    });
  }

  void _syncSavedCoupons() {
    final sub = CartController.instance.totalCartPrice.value;
    final savedProd = _benefits.selectedProductCoupon.value;
    final savedShip = _benefits.selectedShippingCoupon.value;
    if (_productCoupon == null &&
        savedProd != null &&
        !savedProd.shipping &&
        _benefits.eligible(savedProd, sub)) {
      _productCoupon = savedProd;
    }
    if (_shippingCoupon == null &&
        savedShip != null &&
        savedShip.shipping &&
        _benefits.eligible(savedShip, sub)) {
      _shippingCoupon = savedShip;
    }
  }

  Future<void> _openCouponPicker(
    double subtotal, {
    required bool focusShippingFirst,
  }) async {
    await Get.to<void>(
      () => CouponsScreen(
        subtotal: subtotal,
        currentlyAppliedProductCode: _productCoupon?.id,
        currentlyAppliedShippingCode: _shippingCoupon?.id,
        focusShippingFirst: focusShippingFirst,
      ),
    );
    if (mounted) {
      setState(() {
        _productCoupon = _benefits.selectedProductCoupon.value;
        _shippingCoupon = _benefits.selectedShippingCoupon.value;
      });
    }
  }

  String _combinedCouponLabel(ShopCoupon? prod, ShopCoupon? ship) {
    final parts = [
      if (ship != null) ship.id,
      if (prod != null) prod.id,
    ];
    return parts.join(' + ');
  }

  Future<void> _submit() async {
    if (_benefits.busy.value) return;
    final address = AddressController.instance.selectedAddress.value;
    if (address.id.isEmpty) {
      await AddressController.instance.selectNewAddressPopup(context);
      return;
    }
    final cart = CartController.instance;
    final subtotal = cart.totalCartPrice.value;
    final isVnPay = _checkoutController.isVnPaySelected;
    final activeProd =
        (_productCoupon != null && _benefits.eligible(_productCoupon!, subtotal))
            ? _productCoupon
            : null;
    final activeShip = (_shippingCoupon != null &&
            _benefits.eligible(_shippingCoupon!, subtotal))
        ? _shippingCoupon
        : null;
    setState(() => _error = null);

    VnPayTransactionResult? vnpayResult;
    if (isVnPay) {
      final quote = _benefits.quoteDual(
        subtotal,
        productCoupon: activeProd,
        shippingCoupon: activeShip,
      );
      final summaryInfo = cart.cartItems.isNotEmpty
          ? 'Thanh toan ${cart.cartItems.first.title} VELORA'
          : 'Thanh toan don hang VELORA';
      final rawVnpay = await Get.to<dynamic>(
        () => VnPaySandboxScreen(
          orderId: _orderId,
          amountVnd: quote.totalVnd,
          orderInfo: summaryInfo,
        ),
      );
      vnpayResult = rawVnpay is VnPayTransactionResult ? rawVnpay : null;
      if (!mounted) return;
      if (vnpayResult == null || !vnpayResult.isSuccess) {
        setState(() {
          _error = vnpayResult?.statusDescription ??
              'Bạn đã hủy giao dịch thanh toán VNPay. Bạn có thể thử lại hoặc chọn Thanh toán khi nhận hàng.';
        });
        return;
      }
    }

    final appliedCouponCode = _combinedCouponLabel(activeProd, activeShip);
    var finalMethodLabel = vnpayResult != null
        ? 'VNPay (${vnpayResult.bankCode})'
        : CheckoutController.codMethodName;

    try {
      final completedQuote = await _benefits.purchase(
        orderId: _orderId,
        subtotal: subtotal,
        bank: false,
        coupon: activeProd,
        shippingCoupon: activeShip,
        saveOrder: (quote) async {
          final uid = AuthenticationRepository.instance.authUser.uid;
          final date = DateTime.now();
          final eta = ShippingRouteHelper.estimateForAddress(address);
          finalMethodLabel = vnpayResult != null
              ? 'VNPay (${vnpayResult.bankCode})'
              : CheckoutController.codMethodName;
          final order = OrderModel(
            id: _orderId,
            userId: uid,
            status: OrderStatus.pending,
            totalAmount: quote.total,
            discountAmount: quote.discount,
            couponCode: appliedCouponCode,
            orderDate: date,
            searchDate: date,
            paymentMethod: finalMethodLabel,
            address: address,
            deliveryDate: eta.latestDeliveryDate(date),
            items: cart.cartItems.toList(),
          );
          final db = FirebaseFirestore.instance;
          final user = db.collection('Users').doc(uid);
          final batch = db.batch();
          batch.set(user.collection('Orders').doc(_orderId), {
            ...order.toJson(),
            'discountAmount': quote.discount,
            'productDiscount': quote.productDiscount,
            'shippingDiscount': quote.shippingDiscount,
            'couponCode': appliedCouponCode,
            'productCouponCode': activeProd?.id ?? '',
            'shippingCouponCode': activeShip?.id ?? '',
            'paymentStatus':
                vnpayResult != null ? 'vnpay_paid' : 'pay_on_delivery',
            if (vnpayResult != null) ...{
              'vnpayTxnRef': vnpayResult.txnRef,
              'vnpayTransactionNo': vnpayResult.transactionNo,
              'vnpayBankCode': vnpayResult.bankCode,
              'vnpayResponseCode': vnpayResult.responseCode,
              'vnpayPayDate': vnpayResult.payDate,
            },
            'notificationPending': true,
          });
          final summaryVi = order.itemsSummary(english: false);
          final summaryEn = order.itemsSummary(english: true);
          batch.set(
            user.collection('Notifications').doc('order-$_orderId-pending'),
            {
              'kind': 'order',
              'targetId': _orderId,
              'read': false,
              'pushPending': true,
              'titleVi': vnpayResult != null
                  ? 'Đã thanh toán VNPay cho đơn $summaryVi'
                  : 'Đơn hàng $summaryVi của bạn đã được tiếp nhận',
              'titleEn': vnpayResult != null
                  ? 'VNPay payment confirmed for $summaryEn'
                  : 'Your order for $summaryEn has been received',
              'bodyVi': vnpayResult != null
                  ? 'Giao dịch VNPay #${vnpayResult.transactionNo} (${vnpayResult.bankCode}) thành công. Tổng Kho Hà Nội đang xác nhận gửi hàng.'
                  : 'Cửa hàng đang xác nhận đơn hàng. Bạn có thể theo dõi tiến trình trong Đơn hàng của tôi.',
              'bodyEn': vnpayResult != null
                  ? 'VNPay transaction #${vnpayResult.transactionNo} (${vnpayResult.bankCode}) succeeded. VELORA is confirming your order.'
                  : 'We are confirming your order. Track its progress in My Orders.',
              'createdAt': FieldValue.serverTimestamp(),
            },
          );
          await batch.commit();
        },
      );
      cart.clearCart();
      if (!mounted) return;
      await Get.off(
        () => CheckoutCompleteScreen(
          vnpayResult: vnpayResult,
          orderTotal: completedQuote.total,
          discountAmount: completedQuote.discount,
          couponCode: appliedCouponCode,
          paymentMethodLabel: finalMethodLabel,
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is StateError
              ? error.message.toString()
              : 'Couldn’t place the order. Please try again.',
        );
      }
    }
  }

  /// Dual-slot Voucher Card:
  /// Slot 1: Mã Miễn phí vận chuyển (max 1)
  /// Slot 2: Mã Giảm giá sản phẩm (max 1)
  Widget _buildDualVoucherSection(
    BuildContext context, {
    required double subtotal,
    required String lang,
    required bool isEn,
  }) {
    final activeShip =
        (_shippingCoupon != null && _benefits.eligible(_shippingCoupon!, subtotal))
            ? _shippingCoupon
            : null;
    final activeProd =
        (_productCoupon != null && _benefits.eligible(_productCoupon!, subtotal))
            ? _productCoupon
            : null;

    final bestShip = _benefits.bestShippingCouponFor(subtotal);
    final bestProd = _benefits.bestProductCouponFor(subtotal);

    final shipAvailCount = _benefits.sortedShippingCouponsFor(subtotal).length;
    final prodAvailCount = _benefits.sortedProductCouponsFor(subtotal).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                const Icon(
                  Iconsax.ticket_discount,
                  size: 18,
                  color: Color(0xFF173E32),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEn ? 'VELORA Vouchers' : 'Mã ưu đãi VELORA',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                Text(
                  isEn
                      ? '1 Freeship + 1 Discount'
                      : 'Tối đa 1 Freeship + 1 Giảm giá',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Slot 1: Freeship Voucher
          _buildVoucherSlotRow(
            icon: Icons.local_shipping_outlined,
            slotLabel: isEn ? 'Free Shipping' : 'Mã vận chuyển',
            applied: activeShip,
            bestCandidate: bestShip,
            availCount: shipAvailCount,
            subtotal: subtotal,
            lang: lang,
            isEn: isEn,
            onOpenPicker: () =>
                _openCouponPicker(subtotal, focusShippingFirst: true),
            onQuickApply: bestShip == null
                ? null
                : () {
                    _benefits.selectedShippingCoupon.value = bestShip;
                    setState(() => _shippingCoupon = bestShip);
                  },
            onRemove: () {
              _benefits.selectedShippingCoupon.value = null;
              setState(() => _shippingCoupon = null);
            },
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Slot 2: Product Discount Voucher
          _buildVoucherSlotRow(
            icon: Iconsax.discount_shape,
            slotLabel: isEn ? 'Product Discount' : 'Mã giảm giá SP',
            applied: activeProd,
            bestCandidate: bestProd,
            availCount: prodAvailCount,
            subtotal: subtotal,
            lang: lang,
            isEn: isEn,
            onOpenPicker: () =>
                _openCouponPicker(subtotal, focusShippingFirst: false),
            onQuickApply: bestProd == null
                ? null
                : () {
                    _benefits.selectedProductCoupon.value = bestProd;
                    setState(() => _productCoupon = bestProd);
                  },
            onRemove: () {
              _benefits.selectedProductCoupon.value = null;
              setState(() => _productCoupon = null);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherSlotRow({
    required IconData icon,
    required String slotLabel,
    required ShopCoupon? applied,
    required ShopCoupon? bestCandidate,
    required int availCount,
    required double subtotal,
    required String lang,
    required bool isEn,
    required VoidCallback onOpenPicker,
    required VoidCallback? onQuickApply,
    required VoidCallback onRemove,
  }) {
    if (applied != null) {
      final saved = applied.discount(subtotal);
      return InkWell(
        onTap: onOpenPicker,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
          child: Row(
            children: [
              Icon(icon, size: 17, color: const Color(0xFF173E32)),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isEn ? 'Applied' : 'Đã áp mã',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            applied.id,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$slotLabel · -${formatShopMoney(saved, language: lang)}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF173E32),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onOpenPicker,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  isEn ? 'Change' : 'Đổi',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove coupon'.tr,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
                onPressed: onRemove,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 17,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bestSavings =
        bestCandidate != null ? bestCandidate.discount(subtotal) : 0.0;

    return InkWell(
      onTap: onOpenPicker,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 17, color: const Color(0xFF64748B)),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        slotLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      if (bestCandidate != null && bestSavings > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5.5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Text(
                            isEn ? 'Recommended' : 'Đề xuất',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bestCandidate != null && bestSavings > 0
                        ? (isEn
                            ? '${bestCandidate.id} · Save ${formatShopMoney(bestSavings, language: lang)}'
                            : '${bestCandidate.id} · Giảm ${formatShopMoney(bestSavings, language: lang)}')
                        : (availCount > 0
                            ? (isEn
                                ? 'View $availCount voucher(s)'
                                : 'Xem $availCount mã hiện có')
                            : (isEn ? 'Enter or select code' : 'Chọn hoặc nhập mã')),
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (bestCandidate != null && bestSavings > 0 && onQuickApply != null)
              SizedBox(
                height: 29,
                child: OutlinedButton(
                  onPressed: onQuickApply,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF173E32),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF173E32)),
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: Text(
                    isEn ? 'Apply' : 'Áp ngay',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: Color(0xFF94A3B8),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartController.instance;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final isEn = lang == 'en';

    return PopScope(
      canPop: !_benefits.busy.value,
      child: Scaffold(
        appBar: const TAppbar(
          showBackArrow: true,
          title: ShopText(
            'Checkout',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.6,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShopText(
                'The final details.',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              ShopText(
                'Review your pairs and choose how to pay.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              const TBillingAddressSection(),
              const SizedBox(height: 12),
              Obx(() {
                final selectedAddr =
                    AddressController.instance.selectedAddress.value;
                final eta = ShippingRouteHelper.estimateForAddress(selectedAddr);
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        size: 18,
                        color: Color(0xFF475569),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          eta.customerEtaHeadline(english: isEn),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 22),
                child: Divider(height: 1),
              ),
              const TBillingPaymentSection(),
              Obx(() {
                if (!_checkoutController.isVnPaySelected) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF005BAA).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Iconsax.shield_tick,
                          size: 18,
                          color: Color(0xFF005BAA),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            isEn
                                ? 'VNPay Sandbox Test Gateway: supports VNPAY-QR, NCB test card (9704198526191432198, OTP 123456) and Visa/Mastercard with HMAC-SHA512 signing.'
                                : 'Cổng thanh toán VNPay Sandbox Test: hỗ trợ quét VNPAY-QR, thẻ ATM NCB (9704198526191432198, OTP 123456) hoặc Visa/Mastercard ký số HMAC-SHA512.',
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF003E78),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 22),
                child: Divider(height: 1),
              ),
              Row(
                children: [
                  const Expanded(
                    child: ShopText(
                      'Your pairs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const ShopText('Edit bag'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Obx(
                () => Column(
                  children: [
                    for (final item in cart.cartItems)
                      FutureBuilder<ProductAvailabilityResult>(
                        future: ProductAvailabilityHelper.checkCartItem(item),
                        builder: (context, availSnap) {
                          final unavailable =
                              availSnap.data?.isUnavailable == true;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => ProductAvailabilityHelper
                                  .openProductDetailFromCartItem(context, item),
                              child: Opacity(
                                opacity: unavailable ? 0.55 : 1.0,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TRoundedImage(
                                      imageUrl: item.image ?? '',
                                      width: 80,
                                      height: 80,
                                      isNetworkImage: true,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ShopText(
                                            item.brandName ?? '',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                          const SizedBox(height: 3),
                                          ShopText(
                                            item.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              decoration: unavailable
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                          if (unavailable) ...[
                                            const SizedBox(height: 5),
                                            const DiscontinuedProductBadge(
                                                compact: true),
                                          ],
                                          const SizedBox(height: 5),
                                          ShopText(
                                            (item.selectedVariation?.entries ??
                                                    [])
                                                .map((e) =>
                                                    '${e.key}: ${e.value}')
                                                .join(' · '),
                                            style: theme.textTheme.bodySmall,
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 12,
                                            children: [
                                              ShopText(
                                                'Qty ${item.quantity}',
                                                style:
                                                    theme.textTheme.bodySmall,
                                              ),
                                              ShopText(
                                                formatShopMoney(
                                                  item.price * item.quantity,
                                                  language: lang,
                                                ),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Dual Stackable Vouchers Section (1 Freeship + 1 Product Discount)
              Obx(() {
                _benefits.revision.value;
                return _buildDualVoucherSection(
                  context,
                  subtotal: cart.totalCartPrice.value,
                  lang: lang,
                  isEn: isEn,
                );
              }),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 22),
                child: Divider(height: 1),
              ),
              const ShopText(
                'Order summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Obx(() {
                final sub = cart.totalCartPrice.value;
                final activeProd = (_productCoupon != null &&
                        _benefits.eligible(_productCoupon!, sub))
                    ? _productCoupon
                    : null;
                final activeShip = (_shippingCoupon != null &&
                        _benefits.eligible(_shippingCoupon!, sub))
                    ? _shippingCoupon
                    : null;
                final q = _benefits.quoteDual(
                  sub,
                  productCoupon: activeProd,
                  shippingCoupon: activeShip,
                );
                return TBillingAmountSection(
                  discount: q.discount,
                  productDiscount: q.productDiscount,
                  shippingDiscount: q.shippingDiscount,
                  productCouponCode: activeProd?.id ?? '',
                  shippingCouponCode: activeShip?.id ?? '',
                );
              }),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ShopText(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: Obx(() {
          _benefits.revision.value;
          final subtotal = cart.totalCartPrice.value;
          final activeProd = (_productCoupon != null &&
                  _benefits.eligible(_productCoupon!, subtotal))
              ? _productCoupon
              : null;
          final activeShip = (_shippingCoupon != null &&
                  _benefits.eligible(_shippingCoupon!, subtotal))
              ? _shippingCoupon
              : null;
          final quote = _benefits.quoteDual(
            subtotal,
            productCoupon: activeProd,
            shippingCoupon: activeShip,
          );
          final originalTotal = quote.subtotal + quote.shipping + quote.tax;
          final appliedLabel = _combinedCouponLabel(activeProd, activeShip);
          final isVnPay = _checkoutController.isVnPaySelected;
          final busy = _benefits.busy.value;

          return SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.16),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (appliedLabel.isNotEmpty && quote.discount > 0)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F6F4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 15,
                            color: Color(0xFF173E32),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isEn
                                  ? 'Applied $appliedLabel · Saved ${formatShopMoney(quote.discount, language: lang)}'
                                  : 'Đã áp mã $appliedLabel · Tiết kiệm ${formatShopMoney(quote.discount, language: lang)}',
                              softWrap: true,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF173E32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const ShopText(
                        'Total to pay',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (quote.discount > 0)
                            Text(
                              formatShopMoney(originalTotal, language: lang),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ShopText(
                            formatShopMoney(quote.total, language: lang),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: isVnPay
                          ? ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005BAA),
                              foregroundColor: Colors.white,
                            )
                          : null,
                      onPressed: subtotal <= 0 || busy ? null : _submit,
                      child: busy
                          ? const ShopText('Placing your order...')
                          : (isVnPay
                              ? Text(
                                  isEn
                                      ? 'Pay online via VNPay (Sandbox)'
                                      : 'Thanh toán trực tuyến qua VNPay',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : const ShopText(
                                  'Place order · Pay on delivery')),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
