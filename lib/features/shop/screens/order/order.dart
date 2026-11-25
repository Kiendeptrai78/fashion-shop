import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/data/repositories/orders/orders_repository.dart';
import 'package:fashion_business_app/features/personalization/services/account_activity.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/features/shop/models/product_availability_helper.dart';
import 'package:fashion_business_app/features/shop/models/shipping_route_helper.dart';
import 'package:fashion_business_app/features/shop/screens/order/order_detail.dart';
import 'package:fashion_business_app/features/shop/screens/product_reviews/product_review.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  late Future<List<OrderModel>> _orders;
  int _filter = 0;

  static const _tabs = [
    'All orders',
    'Pending',
    'Processing',
    'On the way',
    'Received',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _orders = OrderRepository().fetchUserOrders();
  }

  Future<void> _reload() async {
    final request = OrderRepository().fetchUserOrders();
    setState(() {
      _orders = request;
    });
    try {
      await request;
    } catch (_) {}
  }

  bool _matches(OrderModel order) => switch (_filter) {
        1 => order.status == OrderStatus.pending,
        2 => order.status == OrderStatus.processing,
        3 => order.status == OrderStatus.shipped,
        4 => order.status == OrderStatus.received,
        5 => order.status == OrderStatus.cancelled,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: const TAppbar(
        showBackArrow: true,
        title: ShopText(
          'My Orders',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clean, colorless underline tabs (zero rainbow chips)
          Container(
            color: Colors.white,
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 20),
              itemBuilder: (_, index) => Obx(() {
                final activity = AccountActivity.current;
                final count = switch (index) {
                  1 => activity?.counts['pending'] ?? 0,
                  2 => activity?.counts['processing'] ?? 0,
                  3 => activity?.counts['shipped'] ?? 0,
                  4 => activity?.counts['received'] ?? 0,
                  5 => activity?.counts['cancelled'] ?? 0,
                  _ => activity?.orderCount ?? 0,
                };
                final selected = _filter == index;
                return InkWell(
                  onTap: () => setState(() => _filter = index),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selected
                              ? const Color(0xFF111827)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShopText(
                          _tabs[index],
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? const Color(0xFF111827)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '($count)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected
                                  ? const Color(0xFF111827)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          Expanded(
            child: FutureBuilder<List<OrderModel>>(
              future: _orders,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF111827),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ShopText('Couldn’t load orders.'),
                        TextButton(
                          onPressed: _reload,
                          child: const ShopText('Try again'),
                        ),
                      ],
                    ),
                  );
                }
                final orders = (snapshot.data ?? []).where(_matches).toList()
                  ..sort((a, b) => b.orderDate.compareTo(a.orderDate));

                return RefreshIndicator(
                  onRefresh: _reload,
                  color: const Color(0xFF111827),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      if (orders.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 84),
                          child: Column(
                            children: [
                              Icon(
                                Iconsax.bag_2,
                                size: 46,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const ShopText(
                                'No orders here yet.',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 6),
                              ShopText(
                                'Your purchases will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      for (final order in orders) _orderCard(order),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Minimal status badge: strictly ONE per order item representing its status.
  Widget _buildSingleStatusBadge(OrderModel order, bool isEn) {
    final isCancelled = order.status == OrderStatus.cancelled;
    final isReceived = order.status == OrderStatus.received;
    final Color textColor = isCancelled
        ? const Color(0xFFB91C1C)
        : (isReceived ? const Color(0xFF15803D) : const Color(0xFF1E293B));
    final Color bgColor = isCancelled
        ? const Color(0xFFFEF2F2)
        : (isReceived ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        order.orderStatusLabel(english: isEn),
        style: TextStyle(
          color: textColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _orderCard(OrderModel order) {
    final locale = Localizations.localeOf(context).languageCode;
    final isEn = locale == 'en';
    final isReceived = order.status == OrderStatus.received;
    final isCancelled = order.status == OrderStatus.cancelled;
    final totalQty = order.items.fold<int>(0, (s, e) => s + e.quantity);
    final eta = ShippingRouteHelper.estimateForAddress(order.address);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Get.to(() => OrderDetail(order: order));
          if (mounted) _reload();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Date on left, strictly ONE status badge on right
              Row(
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy · HH:mm').format(order.orderDate),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  _buildSingleStatusBadge(order, isEn),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),

              // Product rows (clean, monochrome, zero extra badges)
              for (final item in order.items.take(2))
                FutureBuilder<ProductAvailabilityResult>(
                  future: ProductAvailabilityHelper.checkCartItem(item),
                  builder: (context, availSnap) {
                    final unavailable = availSnap.data?.isUnavailable == true;
                    final variationText =
                        (item.selectedVariation?.entries ?? const [])
                            .map((e) => '${e.key}: ${e.value}')
                            .join(' · ');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Opacity(
                        opacity: unavailable ? 0.55 : 1.0,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFF1F5F9),
                                ),
                              ),
                              child: TRoundedImage(
                                imageUrl: item.image ?? '',
                                width: 62,
                                height: 62,
                                borderRadius: 8,
                                isNetworkImage: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    variationText.isNotEmpty
                                        ? '$variationText · x${item.quantity}'
                                        : 'x${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formatShopMoney(
                                item.price * item.quantity,
                                language: locale,
                              ),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              if (order.items.length > 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    isEn
                        ? '+ ${order.items.length - 2} more item(s)'
                        : 'Xem thêm ${order.items.length - 2} sản phẩm khác',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),

              if (!isCancelled && !isReceived)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    isEn
                        ? 'Estimated delivery to ${eta.destinationCity}: ${eta.minDays}–${eta.maxDays} days'
                        : 'Dự kiến giao đến ${eta.destinationCity}: ${eta.minDays}–${eta.maxDays} ngày',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),

              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),

              // Summary line: item count + voucher text (plain, no extra badge) + total
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.discountAmount > 0 &&
                              order.couponCode.trim().isNotEmpty
                          ? (isEn
                              ? '$totalQty item(s) · Voucher ${order.couponCode.trim().toUpperCase()}'
                              : '$totalQty sản phẩm · Đã áp mã ${order.couponCode.trim().toUpperCase()}')
                          : (isEn
                              ? '$totalQty item(s)'
                              : '$totalQty sản phẩm'),
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Text(
                    isEn ? 'Total: ' : 'Thành tiền: ',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF475569),
                    ),
                  ),
                  Text(
                    formatShopMoney(order.totalAmount, language: locale),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),

              // Clean single-row actions for delivered orders
              if (isReceived && order.items.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => ProductAvailabilityHelper
                          .buyAgainFromCartItem(context, order.items.first),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF111827),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isEn ? 'Buy again' : 'Mua lại',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (order.items.length == 1) {
                          final item = order.items.first;
                          Get.to(
                            () => ProductReview(
                              productId: item.productId,
                              productTitle: item.title,
                            ),
                          );
                        } else {
                          Get.to(() => OrderDetail(order: order));
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const ShopText(
                        'Review product',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
