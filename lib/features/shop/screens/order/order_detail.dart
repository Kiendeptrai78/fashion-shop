import 'package:fashion_business_app/common/widgets/product/badges/shop_status_badge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/dialogs/velora_confirm_dialog.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/data/repositories/orders/orders_repository.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/features/shop/models/cart_item_model.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/features/shop/models/product_availability_helper.dart';
import 'package:fashion_business_app/features/shop/models/return_request_model.dart';
import 'package:fashion_business_app/features/shop/models/shipping_route_helper.dart';
import 'package:fashion_business_app/features/shop/screens/order/return_request_screen.dart';
import 'package:fashion_business_app/features/shop/screens/product_reviews/product_review.dart';
import 'package:fashion_business_app/features/shop/screens/support_chat/velora_support_chat_screen.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class OrderDetail extends StatefulWidget {
  const OrderDetail({super.key, required this.order});
  final OrderModel order;
  @override
  State<OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
  bool _busy = false;
  String? _error;
  late final Map<int, Future<ProductAvailabilityResult>> _availabilityFutures;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _orderReturnsStream;
  OrderModel get order => widget.order;

  @override
  void initState() {
    super.initState();
    _availabilityFutures = {
      for (var i = 0; i < order.items.length; i++)
        i: ProductAvailabilityHelper.checkCartItem(order.items[i]),
    };
    if (Firebase.apps.isNotEmpty) {
      _orderReturnsStream = FirebaseFirestore.instance
          .collection('ReturnRequests')
          .where('orderId', isEqualTo: order.id)
          .snapshots();
    }
    if (order.status == OrderStatus.cancelled &&
        order.paymentMethod == 'Demo bank') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refund();
      });
    }
  }

  Future<void> _refund() async {
    try {
      await CustomerBenefits.instance.refund(order.id);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Demo refund pending. Reopen this order to retry.',
        );
      }
    }
  }

  Future<void> _update(OrderStatus next) async {
    final isCancel = next == OrderStatus.cancelled;
    final confirmed = await showVeloraConfirmDialog(
      context,
      title: isCancel ? 'Cancel Order' : 'Received Order',
      message: isCancel
          ? 'Are you sure you want to cancel this order?'
          : 'Did you actually received the order?',
      confirmLabel: 'Confirm',
      cancelLabel: 'Back',
      destructive: isCancel,
      icon: isCancel ? Iconsax.close_circle : Iconsax.tick_circle,
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await OrderRepository().updateCustomerStatus(order, next);
      if (mounted) setState(() => order.status = next);
      if (next == OrderStatus.cancelled && order.paymentMethod == 'Demo bank') {
        await _refund();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Order status has changed. Refresh and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openReviewItem(CartItemModel item) {
    Get.to(
      () => ProductReview(productId: item.productId, productTitle: item.title),
    );
  }

  void _openReviewPicker() {
    if (order.items.isEmpty) return;
    if (order.items.length == 1) {
      _openReviewItem(order.items.first);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShopText(
                'Choose a pair to review',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              for (final item in order.items)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: TRoundedImage(
                    imageUrl: item.image ?? '',
                    width: 52,
                    height: 52,
                    isNetworkImage: true,
                  ),
                  title: Text(
                    item.title,
                    softWrap: true,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF64748B),
                  ),
                  onTap: () {
                    Navigator.pop(sheet);
                    _openReviewItem(item);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleStatusBadge(bool isEn) => ShopStatusBadge(
    label: order.orderStatusLabel(english: isEn),
    tone: switch (order.status) {
      OrderStatus.pending => ShopStatusTone.pending,
      OrderStatus.received => ShopStatusTone.success,
      OrderStatus.cancelled => ShopStatusTone.error,
      _ => ShopStatusTone.progress,
    },
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final isEn = locale == 'en';
    final subtotal = order.items.fold<double>(
      0,
      (sum, item) => sum + item.price * item.quantity,
    );
    final cancelled = order.status == OrderStatus.cancelled;
    final received = order.status == OrderStatus.received;
    final canCancel = order.status == OrderStatus.pending;
    final canReceive = order.status == OrderStatus.shipped;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: TAppbar(
        showBackArrow: true,
        title: const ShopText(
          'Order details',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Chat trực tiếp với VELORA',
            onPressed: () => Get.to(
              () => VeloraSupportChatScreen(initialOrder: order),
            ),
            icon: const Icon(Iconsax.message_text_1, size: 21),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Clean White Status & Monochrome Stepper Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: double.infinity, child: Wrap(
                    alignment: WrapAlignment.spaceBetween, spacing: 12, runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy · HH:mm').format(order.orderDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      _buildSingleStatusBadge(isEn),
                    ],
                  )),
                  const SizedBox(height: 12),
                  Text(
                    order.customerOrderTitle(english: isEn),
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.orderStatusSubtitle(english: isEn),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  if (!cancelled) ...[
                    const SizedBox(height: 18),
                    _buildOrderTimeline(order.status, isEn),
                    if (order.status == OrderStatus.processing ||
                        order.status == OrderStatus.shipped) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          isEn
                              ? 'Order is already being packed/shipped and cannot be cancelled. After delivery, you can request a Return or Exchange within 7 days.'
                              : 'Đơn đã đóng gói / bàn giao vận chuyển nên không thể hủy. Sau khi nhận hàng, bạn được hỗ trợ Đổi / Trả trong 7 ngày.',
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Get.to(
                        () => VeloraSupportChatScreen(initialOrder: order),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF111827),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Iconsax.message_text_1, size: 16),
                      label: Text(
                        isEn
                            ? 'Contact VELORA Support'
                            : 'Liên hệ CSKH về đơn hàng này',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            VeloraOrderTrackingMap(
              status: order.status,
              address: order.address,
              orderDate: order.orderDate,
              deliveryDate: order.deliveryDate,
            ),

            // 2. Products Section Card
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShopText(
                    'Your pairs',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < order.items.length; i++) ...[
                    if (i > 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                      ),
                    Builder(builder: (context) {
                      final item = order.items[i];
                      return FutureBuilder<ProductAvailabilityResult>(
                        future: _availabilityFutures[i],
                        builder: (context, availSnap) {
                          final unavailable =
                              availSnap.data?.isUnavailable == true;
                          final varText =
                              (item.selectedVariation?.entries ?? const [])
                                  .map((e) => '${e.key}: ${e.value}')
                                  .join(' · ');
                          final daysLeft = returnWindowDaysLeft(order);
                          final returnEligible = daysLeft >= 0;

                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => ProductAvailabilityHelper
                                .openProductDetailFromCartItem(context, item),
                            child: Opacity(
                              opacity: unavailable ? 0.55 : 1.0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFFF1F5F9),
                                          ),
                                        ),
                                        child: TRoundedImage(
                                          imageUrl: item.image ?? '',
                                          width: 68,
                                          height: 68,
                                          borderRadius: 8,
                                          isNetworkImage: true,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              softWrap: true,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: const Color(0xFF111827),
                                                decoration: unavailable
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              varText.isNotEmpty
                                                  ? '$varText · x${item.quantity}'
                                                  : 'x${item.quantity}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              formatShopMoney(
                                                item.price * item.quantity,
                                                language: locale,
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: Color(0xFF111827),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Uniform neutral action buttons when delivered
                                  if (received) ...[
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (!unavailable)
                                          _neutralActionBtn(
                                            label: isEn
                                                ? 'Buy again'
                                                : 'Mua lại',
                                            onTap: () =>
                                                ProductAvailabilityHelper
                                                    .buyAgainFromCartItem(
                                                        context, item),
                                          ),
                                        _neutralActionBtn(
                                          label: returnEligible
                                              ? (isEn
                                                  ? 'Return / Exchange (${daysLeft}d)'
                                                  : 'Đổi / Trả (còn $daysLeft ngày)')
                                              : (isEn
                                                  ? 'Return expired'
                                                  : 'Quá hạn đổi trả'),
                                          onTap: returnEligible
                                              ? () => openReturnRequestComposer(
                                                    context,
                                                    order: order,
                                                    item: item,
                                                  )
                                              : null,
                                        ),
                                        if (!unavailable)
                                          _neutralActionBtn(
                                            label: isEn
                                                ? 'Review'
                                                : 'Đánh giá',
                                            onTap: () => _openReviewItem(item),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ],
              ),
            ),

            // 3. Return / Exchange requests for this order (if any)
            if (_orderReturnsStream != null)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _orderReturnsStream,
                builder: (context, retSnap) {
                  final reqs = (retSnap.data?.docs ?? const [])
                      .map(ReturnRequestModel.fromSnapshot)
                      .toList();
                  if (reqs.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isEn
                                      ? 'Return & Exchange (${reqs.length})'
                                      : 'Yêu cầu Đổi / Trả (${reqs.length})',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF111827),
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => Get.to(
                                  () => const MyReturnRequestsScreen(),
                                ),
                                child: Text(
                                  isEn ? 'View all' : 'Xem tất cả',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        for (final r in reqs)
                          ReturnRequestTrackingCard(request: r),
                      ],
                    ),
                  );
                },
              ),

            // 4. Shipping Address & Payment Summary Card
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShopText(
                    'Shipping Address',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (order.address != null) ...[
                    Text(
                      '${order.address!.name} · ${order.address!.phoneNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.address!.toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                  ] else
                    const ShopText('Address unavailable'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const ShopText(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Flexible(
                        child: ShopText(
                          order.paymentMethod,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  _amount('Subtotal', subtotal, locale),
                  const SizedBox(height: 10),
                  _amount(
                    'Fees and adjustments',
                    order.totalAmount + order.discountAmount - subtotal,
                    locale,
                  ),
                  if (order.discountAmount > 0) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            order.couponCode.trim().isNotEmpty
                                ? (isEn
                                    ? 'Discount (${order.couponCode.trim().toUpperCase()})'
                                    : 'Mã giảm giá (${order.couponCode.trim().toUpperCase()})')
                                : (isEn ? 'Discount' : 'Giảm giá'),
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Text(
                          formatShopMoney(-order.discountAmount,
                              language: locale),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                  ),
                  _amount('Order total', order.totalAmount, locale, total: true),
                ],
              ),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: ShopText(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar:
          (!canCancel && !canReceive && !(received && order.items.isNotEmpty))
              ? null
              : SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: received
                        ? FilledButton(
                            onPressed: _openReviewPicker,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF111827),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: const ShopText(
                              'Review product',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          )
                        : canReceive
                            ? FilledButton(
                                onPressed: _busy
                                    ? null
                                    : () => _update(OrderStatus.received),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF111827),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: ShopText(
                                  _busy
                                      ? 'Saving changes...'
                                      : 'Received Order',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                              )
                            : OutlinedButton(
                                onPressed: _busy
                                    ? null
                                    : () => _update(OrderStatus.cancelled),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFB91C1C),
                                  side: const BorderSide(
                                    color: Color(0xFFFECACA),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: ShopText(
                                  _busy ? 'Saving changes...' : 'Cancel Order',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                  ),
                ),
    );
  }

  Widget _neutralActionBtn({required String label, VoidCallback? onTap}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF111827),
        disabledForegroundColor: const Color(0xFF94A3B8),
        side: BorderSide(
          color: onTap != null
              ? const Color(0xFFCBD5E1)
              : const Color(0xFFE2E8F0),
        ),
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Clean single-color monochrome 4-step timeline (zero rainbow colors).
  Widget _buildOrderTimeline(OrderStatus status, bool isEn) {
    final step = switch (status) {
      OrderStatus.pending => 1,
      OrderStatus.processing => 2,
      OrderStatus.shipped => 3,
      OrderStatus.received => 4,
      OrderStatus.cancelled => 0,
    };
    final labels = isEn
        ? ['Confirmed', 'Packing', 'Shipping', 'Delivered']
        : ['Xác nhận', 'Đóng gói', 'Đang giao', 'Đã nhận'];

    const activeColor = Color(0xFF111827);
    const inactiveColor = Color(0xFFE2E8F0);

    return Row(
      children: List.generate(4, (idx) {
        final active = (idx + 1) <= step;
        final current = (idx + 1) == step;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: idx == 0
                          ? Colors.transparent
                          : (active ? activeColor : inactiveColor),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: active ? activeColor : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? activeColor : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                    child: active
                        ? const Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: idx == 3
                          ? Colors.transparent
                          : ((idx + 2) <= step ? activeColor : inactiveColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                labels[idx],
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                  color: active ? activeColor : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _amount(
    String label,
    double amount,
    String locale, {
    bool total = false,
  }) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ShopText(
              label,
              style: TextStyle(
                fontSize: total ? 15 : 13.5,
                fontWeight: total ? FontWeight.w700 : FontWeight.w400,
                color:
                    total ? const Color(0xFF111827) : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatShopMoney(amount, language: locale),
            style: TextStyle(
              fontWeight: total ? FontWeight.w700 : FontWeight.w600,
              fontSize: total ? 18 : 13.5,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      );
}
