import 'package:fashion_business_app/features/personalization/services/account_activity.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/data/repositories/orders/orders_repository.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
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
          final tone = Theme.of(context).colorScheme.primary;
          return ChoiceChip(selectedColor: tone, showCheckmark: false,
            label: Row(mainAxisSize: MainAxisSize.min, children: [
              ShopText(_tabs[index], style: TextStyle(color: selected ? Colors.white : tone, fontWeight: FontWeight.w600)),
              const SizedBox(width: 7),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: selected ? Colors.white24 : tone.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('$number', style: TextStyle(color: selected ? Colors.white : tone, fontSize: 11))),
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
    final tone = order.status == OrderStatus.cancelled ? theme.colorScheme.error : theme.colorScheme.primary;
    final locale = Localizations.localeOf(context).languageCode;
    return Padding(padding: const EdgeInsets.only(bottom: 18), child: Material(
      color: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15))),
      child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () async {
        await Get.to(() => OrderDetail(order: order));
        if (mounted) _reload();
      }, child: Padding(padding: const EdgeInsets.all(18), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: ShopText(order.orderStatusText == 'Shipping' ? 'On the way'
              : order.orderStatusText, style: TextStyle(color: tone, fontWeight: FontWeight.w600))),
            const Icon(Icons.chevron_right, size: 20)]),
          const SizedBox(height: 8),
          Text('#${order.id}', style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(DateFormat.yMMMd(locale).format(order.orderDate), style: theme.textTheme.bodySmall),
          const Divider(height: 28),
          for (final item in order.items.take(2)) Padding(padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              TRoundedImage(imageUrl: item.image ?? '', width: 64, height: 64, isNetworkImage: true),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 5),
                ShopText('Qty ${item.quantity}', style: theme.textTheme.bodySmall),
              ])),
            ])),
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
