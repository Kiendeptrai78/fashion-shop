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
  OrderModel get order => widget.order;

  @override
  void initState() {
    super.initState();
    if (order.status == OrderStatus.cancelled && order.paymentMethod == 'Demo bank') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refund();
      });
    }
  }

  Future<void> _refund() async {
    try {
      await CustomerBenefits.instance.refund(order.id);
    } catch (_) {
      if (mounted) setState(() => _error = 'Demo refund pending. Reopen this order to retry.');
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
      if (mounted) setState(() => _error = 'Order status has changed. Refresh and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openReviewItem(CartItemModel item) {
    Get.to(() => ProductReview(productId: item.productId, productTitle: item.title));
  }

  void _openReviewPicker() {
    if (order.items.isEmpty) return;
    if (order.items.length == 1) {
      _openReviewItem(order.items.first);
      return;
    }
    showModalBottomSheet(
      context: context,
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              for (final item in order.items)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: TRoundedImage(imageUrl: item.image ?? '', width: 52, height: 52, isNetworkImage: true),
                  title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.star_rounded, color: Color(0xFFD99A1E)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    final subtotal = order.items.fold<double>(0, (sum, item) => sum + item.price * item.quantity);
    final cancelled = order.status == OrderStatus.cancelled;
    final received = order.status == OrderStatus.received;
    final tone = order.statusColor;
    final bgTone = order.statusBgColor;
    final borderTone = order.statusBorderColor;
    final canCancel = [OrderStatus.pending, OrderStatus.processing].contains(order.status);
    final canReceive = order.status == OrderStatus.shipped;

    return Scaffold(
      appBar: const TAppbar(
        showBackArrow: true,
        title: ShopText('Order details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgTone.withValues(alpha: dark ? 0.16 : 0.72),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderTone.withValues(alpha: 0.7), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: tone,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            order.statusIcon,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            order.orderStatusLabel(english: locale == 'en'),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat.yMMMd(locale).format(order.orderDate),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  order.customerOrderTitle(english: locale == 'en'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  order.orderStatusSubtitle(english: locale == 'en'),
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                ),
                if (!cancelled) ...[
                  const SizedBox(height: 16),
                  _buildOrderTimeline(order.status, locale == 'en'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          VeloraOrderTrackingMap(
            status: order.status,
            address: order.address,
            orderDate: order.orderDate,
            deliveryDate: order.deliveryDate,
          ),
          const SizedBox(height: 24),
          const ShopText('Your pairs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          for (final item in order.items)
            FutureBuilder<ProductAvailabilityResult>(
              future: ProductAvailabilityHelper.checkCartItem(item),
              builder: (context, availSnap) {
                final unavailable = availSnap.data?.isUnavailable == true;
                final isEn = locale == 'en';
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: unavailable
                        ? (dark
                            ? const Color(0xFF171E1B)
                            : const Color(0xFFF8FAFC))
                        : (dark ? const Color(0xFF1A2721) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: unavailable
                          ? const Color(0xFFCBD5E1)
                          : (dark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFE5EAE3)),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () =>
                        ProductAvailabilityHelper.openProductDetailFromCartItem(
                      context,
                      item,
                    ),
                    child: Opacity(
                      opacity: unavailable ? 0.56 : 1.0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TRoundedImage(
                            imageUrl: item.image ?? '',
                            width: 78,
                            height: 84,
                            isNetworkImage: true,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                    decoration: unavailable
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                if ((item.selectedVariation?.entries ?? [])
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  ShopText(
                                    (item.selectedVariation?.entries ?? [])
                                        .map((e) => '${e.key}: ${e.value}')
                                        .join(' · '),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    ShopText(
                                      'Qty ${item.quantity}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    if (unavailable)
                                      const DiscontinuedProductBadge(
                                          compact: true)
                                    else
                                      Text(
                                        isEn
                                            ? '• Tap to view detail'
                                            : '• Ấn xem chi tiết giày',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF173E32),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  alignment: WrapAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      formatShopMoney(
                                          item.price * item.quantity,
                                          language: locale),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: dark
                                            ? const Color(0xFFDDEABB)
                                            : const Color(0xFF173E32),
                                      ),
                                    ),
                                    if (received)
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          if (!unavailable)
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  ProductAvailabilityHelper
                                                      .buyAgainFromCartItem(
                                                          context, item),
                                              icon: const Icon(
                                                Iconsax.shopping_cart,
                                                size: 14,
                                              ),
                                              label: Text(
                                                isEn ? 'Buy again' : 'Mua lại',
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                minimumSize: const Size(0, 32),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                          OutlinedButton.icon(
                                            onPressed: () =>
                                                openReturnRequestComposer(
                                              context,
                                              order: order,
                                              item: item,
                                            ),
                                            icon: const Icon(
                                              Iconsax.refresh_circle,
                                              size: 14,
                                              color: Color(0xFF0284C7),
                                            ),
                                            label: Text(
                                              isEn
                                                  ? 'Return / Exchange'
                                                  : 'Đổi / Trả',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF0284C7),
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                color: Color(0xFF38BDF8),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              minimumSize: const Size(0, 32),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                          if (!unavailable)
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  _openReviewItem(item),
                                              icon: const Icon(
                                                Icons.star_rounded,
                                                size: 15,
                                                color: Color(0xFFD99A1E),
                                              ),
                                              label: const ShopText(
                                                'Write a review',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                minimumSize: const Size(0, 32),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                        ],
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
          // Live Return / Exchange Tracking section for this order
          if (Firebase.apps.isNotEmpty)
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('ReturnRequests')
                  .where('orderId', isEqualTo: order.id)
                  .snapshots(),
              builder: (context, retSnap) {
                final reqs = (retSnap.data?.docs ?? const [])
                    .map(ReturnRequestModel.fromSnapshot)
                    .toList();
                if (reqs.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          locale == 'en'
                              ? 'Return & Exchange Progress (${reqs.length})'
                              : 'Tiến trình Đổi trả & Bảo hành (${reqs.length})',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Get.to(() => const MyReturnRequestsScreen()),
                          child: Text(
                            locale == 'en' ? 'View all' : 'Xem tất cả',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final r in reqs)
                      ReturnRequestTrackingCard(request: r),
                  ],
                );
              },
            ),
          const Divider(height: 30),
          const ShopText('Shipping Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (order.address != null) ...[
            Text(order.address!.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(order.address!.phoneNumber),
            const SizedBox(height: 6),
            Text(order.address!.toString(), style: theme.textTheme.bodySmall?.copyWith(height: 1.6)),
          ] else
            const ShopText('Address unavailable'),
          const Divider(height: 32),
          const ShopText('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ShopText(order.paymentMethod),
          const Divider(height: 32),
          _amount('Subtotal', subtotal, locale),
          const SizedBox(height: 12),
          _amount('Fees and adjustments', order.totalAmount + order.discountAmount - subtotal, locale),
          if (order.discountAmount > 0) ...[
            const SizedBox(height: 12),
            _amount('Discount', -order.discountAmount, locale),
            const SizedBox(height: 6),
            Text(order.couponCode, style: theme.textTheme.bodySmall),
          ],
          const Divider(height: 30),
          _amount('Order total', order.totalAmount, locale, total: true),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: ShopText(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ),
        ],
      ),
      bottomNavigationBar: (!canCancel && !canReceive && !(received && order.items.isNotEmpty))
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              child: received
                  ? FilledButton.icon(
                      onPressed: _openReviewPicker,
                      icon: const Icon(Icons.star_rounded, size: 19, color: Color(0xFFDDEABB)),
                      label: const ShopText(
                        'Review product',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF173E32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    )
                  : canReceive
                      ? FilledButton.icon(
                          onPressed: _busy ? null : () => _update(OrderStatus.received),
                          icon: const Icon(Iconsax.tick_circle, size: 19),
                          label: ShopText(
                            _busy ? 'Saving changes...' : 'Received Order',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF173E32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: _busy ? null : () => _update(OrderStatus.cancelled),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFC62828),
                            side: BorderSide(color: const Color(0xFFC62828).withValues(alpha: 0.35)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: ShopText(_busy ? 'Saving changes...' : 'Cancel Order'),
                        ),
            ),
    );
  }

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
        : ['Xác nhận', 'Đóng gói', 'Vận chuyển', 'Đã giao'];
    final icons = [
      Iconsax.receipt_2,
      Iconsax.box,
      Iconsax.truck_fast,
      Iconsax.tick_circle,
    ];
    const stepColors = [
      Color(0xFFD97706), // 1. Chờ xác nhận (Cam)
      Color(0xFF7C3AED), // 2. Đang đóng gói (Tím)
      Color(0xFF0284C7), // 3. Đang vận chuyển (Xanh dương)
      Color(0xFF16A34A), // 4. Giao thành công (Xanh lá tươi)
    ];
    return Row(
      children: List.generate(4, (idx) {
        final active = (idx + 1) <= step;
        final current = (idx + 1) == step;
        final stepColor = stepColors[idx];
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2.5,
                      color: idx == 0
                          ? Colors.transparent
                          : (active ? stepColor : Colors.black12),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: active ? stepColor : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? stepColor : Colors.black26,
                        width: current ? 2 : 1.2,
                      ),
                    ),
                    child: Icon(
                      icons[idx],
                      size: 14,
                      color: active ? Colors.white : Colors.black38,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2.5,
                      color: idx == 3
                          ? Colors.transparent
                          : ((idx + 2) <= step ? stepColors[idx + 1] : Colors.black12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                labels[idx],
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                  color: active ? stepColor : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _amount(String label, double amount, String locale, {bool total = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: ShopText(label)),
          const SizedBox(width: 12),
          Text(
            formatShopMoney(amount, language: locale),
            style: TextStyle(fontWeight: total ? FontWeight.w700 : FontWeight.w500, fontSize: total ? 20 : 14),
          ),
        ],
      );
}
