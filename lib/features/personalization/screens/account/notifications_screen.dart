import 'package:fashion_business_app/features/personalization/services/account_activity.dart';
import 'package:fashion_business_app/data/repositories/products/product_reposotory.dart';
import 'package:fashion_business_app/features/shop/screens/product_details/product_details.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/data/repositories/orders/orders_repository.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/features/shop/screens/order/order_detail.dart';
import 'package:fashion_business_app/utils/local_storage/local_utility.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<OrderModel>> _orders;
  late Set<String> _read;
  @override
  void initState() {
    super.initState();
    _orders = OrderRepository().fetchUserOrders();
    _read = Set<String>.from(TLocalStorage.instance().readData<List>('read_order_updates_v1') ?? []);
  }
  String _key(OrderModel order) => '${order.id}:${order.status.name}';
  Future<void> _mark(Iterable<OrderModel> orders) async {
    final updated = {..._read, ...orders.map(_key)};
    try {
      await TLocalStorage.instance().saveData('read_order_updates_v1', updated.toList());
      if (mounted) setState(() => _read = updated);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: ShopText('Couldn’t save. Please try again.')));
    }
  }
  Future<void> _reload() async {
    final request = OrderRepository().fetchUserOrders();
    setState(() { _orders = request; });
    try { await request; } catch (_) { /* Rendered below. */ }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const TAppbar(showBackArrow: true, title: ShopText('Notification',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
    body: FutureBuilder<List<OrderModel>>(future: _orders, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      if (snapshot.hasError) return Center(child: TextButton(onPressed: _reload, child: const ShopText('Try again')));
      final orders = (snapshot.data ?? []).toList()..sort((a, b) => b.orderDate.compareTo(a.orderDate));
      return RefreshIndicator(onRefresh: _reload, child: ListView(
        physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(24), children: [
          const ShopText('Stay in the loop.', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w600, letterSpacing: -0.8)),
          const SizedBox(height: 12), const ShopText('Updates from your orders.'),

          Obx(() {
            final activity = AccountActivity.current;
            if (activity == null) return const SizedBox.shrink();
            final notices = activity.inbox.toList();
            return Column(children: [
              if (orders.isNotEmpty || notices.isNotEmpty) Align(alignment: Alignment.centerRight,
                child: TextButton(onPressed: () async {
                  await _mark(orders);
                  await activity.markAllRead();
                }, child: const ShopText('Mark all as read'))),
              OutlinedButton.icon(onPressed: activity.enablePush, icon: const Icon(Icons.notifications_active_outlined),
                  label: ShopText(activity.pushEnabled.value ? 'Notifications enabled' : 'Enable notifications')),
              if (activity.pushError.value.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ShopText(activity.pushError.value, textAlign: TextAlign.center)),
              for (final notice in notices) ListTile(contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: Icon(notice['kind'] == 'product' ? Icons.shopping_bag_outlined : Icons.local_shipping_outlined),
                title: Text((Get.locale?.languageCode == 'en' ? notice['titleEn'] : notice['titleVi']) ?? ''),
                subtitle: Text((Get.locale?.languageCode == 'en' ? notice['bodyEn'] : notice['bodyVi']) ?? ''),
                trailing: notice['read'] == true ? null : const CircleAvatar(radius: 4, backgroundColor: Color(0xFFD92D3E)),
                onTap: () async {
                  await activity.markRead(notice['documentId']);
                  if (notice['kind'] == 'order') {
                    final matches = orders.where((order) => order.id == notice['targetId']);
                    if (matches.isNotEmpty) Get.to(() => OrderDetail(order: matches.first));
                  } else if (notice['kind'] == 'product') {
                    try {
                      final product = await ProductRepository.instance.fetchProductById(notice['targetId']);
                      if (mounted && product != null) Get.to(() => ProductDetail(product: product));
                      else if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: ShopText('Product no longer available.')));
                    } catch (_) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: ShopText('Product no longer available.')));
                    }
                  }
                },
              ),
            ]);
          }),
          const SizedBox(height: 20),
          if (orders.isEmpty && (AccountActivity.current?.inbox.isEmpty ?? true)) const Padding(padding: EdgeInsets.symmetric(vertical: 80), child: Column(children: [
            Icon(Iconsax.notification, size: 56), SizedBox(height: 24),
            ShopText('You’re all caught up.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            SizedBox(height: 10), ShopText('Order updates will appear here.', textAlign: TextAlign.center),
          ])),
          for (final order in orders.where((order) => !(AccountActivity.current?.inbox.any((notice) =>
              notice['kind'] == 'order' && notice['targetId'] == order.id) ?? false))) Padding(padding: const EdgeInsets.only(bottom: 14), child: Material(
            color: _read.contains(_key(order)) ? Theme.of(context).scaffoldBackgroundColor
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14), child: InkWell(borderRadius: BorderRadius.circular(14),
              onTap: () async { await _mark([order]); if (mounted) Get.to(() => OrderDetail(order: order)); },
              child: Padding(padding: const EdgeInsets.all(18), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Iconsax.bag_tick, color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ShopText(order.orderStatusText == 'Shipping' ? 'On the way' : order.orderStatusText,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8), Text('#${order.id}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  const ShopText('Order date', style: TextStyle(fontSize: 11)),
                  Text(DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(order.orderDate),
                      style: Theme.of(context).textTheme.bodySmall),
                ])),
                if (!_read.contains(_key(order))) const Padding(padding: EdgeInsets.only(left: 10, top: 6),
                    child: CircleAvatar(radius: 4, backgroundColor: Color(0xFFD92D3E))),
              ])),
            ))),
        ],
      ));
    }),
  );
}
