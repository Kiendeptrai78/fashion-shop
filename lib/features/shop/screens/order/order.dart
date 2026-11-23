import 'package:fashion_business_app/features/personalization/services/account_activity.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/data/repositories/orders/orders_repository.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/features/shop/models/product_availability_helper.dart';
import 'package:fashion_business_app/features/shop/models/shipping_route_helper.dart';
import 'package:fashion_business_app/features/shop/screens/order/order_detail.dart';
import 'package:fashion_business_app/features/shop/screens/product_reviews/product_review.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  late Future<List<OrderModel>> _orders;
  int _filter = 0;
  final _tabs = const [
    'All orders',
    'Pending',
    'Processing',
    'On the way',
    'Received',
    'Cancelled',
  ];

  @override
  void initState() { super.initState(); _orders = OrderRepository().fetchUserOrders(); }

  Future<void> _reload() async {
    final request = OrderRepository().fetchUserOrders();
    setState(() { _orders = request; });
    try { await request; } catch (_) { /* Rendered inline. */ }
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
  Widget build(BuildContext context) => Scaffold(
    appBar: const TAppbar(showBackArrow: true, title: ShopText('My Orders',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
    body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.fromLTRB(24, 12, 24, 20), child: ShopText(
          'Every pair, every step.', style: TextStyle(fontSize: 27,
              fontWeight: FontWeight.w600, letterSpacing: -0.8))),
      SizedBox(height: 44, child: ListView.separated(scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24), itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) => Obx(() {
          final activity = AccountActivity.current;
          final number = switch (index) {
            1 => activity?.counts['pending'] ?? 0,
            2 => activity?.counts['processing'] ?? 0,
            3 => activity?.counts['shipped'] ?? 0,
            4 => activity?.counts['received'] ?? 0,
            5 => activity?.counts['cancelled'] ?? 0,
            _ => activity?.orderCount ?? 0,
          };
          final selected = _filter == index;
          final tone = switch (index) {
            1 => OrderModel.colorForStatus(OrderStatus.pending),
            2 => OrderModel.colorForStatus(OrderStatus.processing),
            3 => OrderModel.colorForStatus(OrderStatus.shipped),
            4 => OrderModel.colorForStatus(OrderStatus.received),
            5 => OrderModel.colorForStatus(OrderStatus.cancelled),
            _ => const Color(0xFF334155),
          };
          final bgTint = switch (index) {
            1 => OrderModel.bgColorForStatus(OrderStatus.pending),
            2 => OrderModel.bgColorForStatus(OrderStatus.processing),
            3 => OrderModel.bgColorForStatus(OrderStatus.shipped),
            4 => OrderModel.bgColorForStatus(OrderStatus.received),
            5 => OrderModel.bgColorForStatus(OrderStatus.cancelled),
            _ => const Color(0xFFF1F5F9),
          };
          return ChoiceChip(
            selectedColor: tone,
            backgroundColor: bgTint,
            side: BorderSide(color: tone.withValues(alpha: selected ? 1.0 : 0.35)),
            showCheckmark: false,
            label: Row(mainAxisSize: MainAxisSize.min, children: [
              ShopText(_tabs[index], style: TextStyle(color: selected ? Colors.white : tone, fontWeight: FontWeight.w700)),
              const SizedBox(width: 7),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: selected ? Colors.white24 : tone.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('$number', style: TextStyle(color: selected ? Colors.white : tone, fontSize: 11, fontWeight: FontWeight.w700))),
            ]), selected: selected, onSelected: (_) => setState(() => _filter = index));
        }),
      )),
      const SizedBox(height: 16),
      Expanded(child: FutureBuilder<List<OrderModel>>(future: _orders, builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ShopText('Couldn’t load orders.'),
          TextButton(onPressed: _reload, child: const ShopText('Try again')),
        ]));
        final orders = (snapshot.data ?? []).where(_matches).toList()
          ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
        return RefreshIndicator(onRefresh: _reload, child: ListView(
          physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            if (orders.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 90),
              child: Column(children: [Icon(Iconsax.bag_tick, size: 52), SizedBox(height: 24),
                ShopText('No orders here yet.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                SizedBox(height: 10), ShopText('Your purchases will appear here.', textAlign: TextAlign.center),
              ])),
            for (final order in orders) _orderCard(order),
          ],
        ));
      })),
    ]),
  );

  Widget _orderCard(OrderModel order) {
    final theme = Theme.of(context);
    final isCancelled = order.status == OrderStatus.cancelled;
    final tone = order.statusColor;
    final bgTone = order.statusBgColor;
    final borderTone = order.statusBorderColor;
    final locale = Localizations.localeOf(context).languageCode;
    final isEn = locale == 'en';
    final stepIndex = switch (order.status) {
      OrderStatus.pending => 1,
      OrderStatus.processing => 2,
      OrderStatus.shipped => 3,
      OrderStatus.received => 4,
      OrderStatus.cancelled => 0,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: borderTone.withValues(alpha: 0.45), width: 1.2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            await Get.to(() => OrderDetail(order: order));
            if (mounted) _reload();
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        color: bgTone,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: borderTone.withValues(alpha: 0.65)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            order.statusIcon,
                            size: 14,
                            color: tone,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            order.orderStatusLabel(english: isEn),
                            style: TextStyle(
                              color: tone,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
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
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  order.customerOrderTitle(english: isEn),
                  softWrap: true,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.orderStatusSubtitle(english: isEn),
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                ),
                const SizedBox(height: 6),
                Builder(builder: (_) {
                  final eta = ShippingRouteHelper.estimateForAddress(order.address);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Iconsax.routing, size: 13, color: Color(0xFF0284C7)),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          isEn
                              ? 'Hanoi Warehouse → ${eta.destinationCity} • Est. ${eta.minDays}–${eta.maxDays} days'
                              : 'Kho Hà Nội → ${eta.destinationCity} • Dự kiến ${eta.minDays}–${eta.maxDays} ngày',
                          softWrap: true,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                if (!isCancelled) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(4, (i) {
                      final active = (i + 1) <= stepIndex;
                      const stepColors = [
                        Color(0xFFD97706), // 1. Chờ xác nhận (Cam)
                        Color(0xFF7C3AED), // 2. Đang đóng gói (Tím)
                        Color(0xFF0284C7), // 3. Đang vận chuyển (Xanh dương)
                        Color(0xFF16A34A), // 4. Giao thành công (Xanh lá tươi)
                      ];
                      return Expanded(
                        child: Container(
                          height: 5,
                          margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                          decoration: BoxDecoration(
                            color: active
                                ? stepColors[i]
                                : theme.dividerColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
                const Divider(height: 26),
          for (final item in order.items.take(2))
            FutureBuilder<ProductAvailabilityResult>(
              future: ProductAvailabilityHelper.checkCartItem(item),
              builder: (context, availSnap) {
                final unavailable = availSnap.data?.isUnavailable == true;
                final isReceived = order.status == OrderStatus.received;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TRoundedImage(
                            imageUrl: item.image ?? '',
                            width: 64,
                            height: 64,
                            isNetworkImage: true,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  softWrap: true,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    decoration: unavailable
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
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
                                            ? '• Tap to view shoe'
                                            : '• Ấn xem chi tiết giày',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF173E32),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isReceived && !unavailable) ...[
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => ProductAvailabilityHelper
                                  .buyAgainFromCartItem(context, item),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 6,
                                ),
                                minimumSize: const Size(0, 32),
                                side: const BorderSide(
                                  color: Color(0xFF173E32),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                              child: Text(
                                isEn ? 'Buy again' : 'Mua lại',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF173E32),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const ShopText('Order total'),
            Text(formatShopMoney(order.totalAmount, language: locale),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          ]),
          if (order.status == OrderStatus.received && order.items.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  if (order.items.length == 1) {
                    final item = order.items.first;
                    Get.to(() => ProductReview(productId: item.productId, productTitle: item.title));
                  } else {
                    Get.to(() => OrderDetail(order: order));
                  }
                },
                icon: const Icon(Icons.star_rounded, size: 17, color: Color(0xFFDDEABB)),
                label: const ShopText(
                  'Review product',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF173E32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ))),
    ));
  }
}
