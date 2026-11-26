import 'package:fashion_business_app/common/widgets/tabs/shop_filter_tab.dart';
import 'package:fashion_business_app/common/widgets/product/badges/shop_status_badge.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
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
  const OrderScreen({super.key, this.loadOrders, this.initialFilter = 0});
  final Future<List<OrderModel>> Function()? loadOrders;
  final int initialFilter;
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  late Future<List<OrderModel>> _orders;
  late int _filter = widget.initialFilter;

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
    _orders = widget.loadOrders?.call() ?? OrderRepository().fetchUserOrders();
  }

  Future<void> _reload() async {
    final request = widget.loadOrders?.call() ?? OrderRepository().fetchUserOrders();
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
          Container(
            color: Colors.white,
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, index) {
                final activity = AccountActivity.current;
                Widget tab(int count) => ShopFilterTab(
                  label: _tabs[index], count: count, selected: _filter == index,
                  onTap: () => setState(() => _filter = index),
                );
                if (activity == null) return tab(0);
                return Obx(() => tab(switch (index) {
                  1 => activity.counts['pending'] ?? 0,
                  2 => activity.counts['processing'] ?? 0,
                  3 => activity.counts['shipped'] ?? 0,
                  4 => activity.counts['received'] ?? 0,
                  5 => activity.counts['cancelled'] ?? 0,
                  _ => activity.orderCount,
                }));
              },
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
                      color: TColors.primaryColor,
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
                  color: TColors.primaryColor,
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
                                  color: TColors.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const ShopText(
                                'Your purchases will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF46524B)),
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

  Widget _buildSingleStatusBadge(OrderModel order, bool isEn) => ShopStatusBadge(
    label: order.orderStatusLabel(english: isEn),
    tone: switch (order.status) {
      OrderStatus.pending => ShopStatusTone.pending,
      OrderStatus.received => ShopStatusTone.success,
      OrderStatus.cancelled => ShopStatusTone.error,
      _ => ShopStatusTone.progress,
    },
  );

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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Get.to(() => OrderDetail(order: order));
          if (mounted) _reload();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: double.infinity, child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12, runSpacing: 10,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${isEn ? 'Order' : 'Đơn'} #${order.id.length > 12 ? order.id.substring(order.id.length - 8) : order.id}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: TColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(DateFormat('dd/MM/yyyy · HH:mm').format(order.orderDate),
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF46524B))),
                  ]),
                  _buildSingleStatusBadge(order, isEn),
                ],
              )),
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
                              width: 72,
                              height: 72,
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    height: 1.4,
                                    color: TColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  variationText.isNotEmpty
                                      ? '$variationText · x${item.quantity}'
                                      : 'x${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 13, height: 1.4, fontWeight: FontWeight.w500,
                                    color: Color(0xFF46524B),
                                  ),
                                ),
                                if (unavailable) ...[
                                  const SizedBox(height: 4),
                                  Text(isEn ? 'Currently discontinued' : 'Hiện đã ngừng bán',
                                    style: const TextStyle(fontSize: 12, height: 1.4,
                                      fontWeight: FontWeight.w600, color: Color(0xFF46524B))),
                                ],
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
                              color: TColors.textPrimary,
                            ),
                          ),
                        ],
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
                      color: Color(0xFF46524B),
                    ),
                  ),
                ),

              if (!isCancelled && !isReceived)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF3F7F4),
                    borderRadius: BorderRadius.circular(10)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.local_shipping_outlined, size: 17, color: TColors.textPrimary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      isEn
                          ? 'Estimated delivery to ${eta.destinationCity}: ${eta.minDays}–${eta.maxDays} days'
                          : 'Dự kiến giao đến ${eta.destinationCity}: ${eta.minDays}–${eta.maxDays} ngày',
                      style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF46524B)),
                    )),
                  ]),
                ),

              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isEn ? '$totalQty item(s)' : '$totalQty sản phẩm',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF46524B))),
                    if (order.discountAmount > 0 && order.couponCode.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('${isEn ? 'Voucher' : 'Mã ưu đãi'}: ${order.couponCode.trim().toUpperCase()}',
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, height: 1.4, color: TColors.textPrimary)),
                    ],
                  ])),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(isEn ? 'Order total' : 'Thành tiền',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF46524B))),
                    const SizedBox(height: 4),
                    Text(formatShopMoney(order.totalAmount, language: locale),
                      style: const TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 17, color: TColors.textPrimary)),
                  ]),
                ],
              ),

              // Delivered-order actions wrap when the available width is narrow.
              if (isReceived && order.items.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.end, spacing: 8, runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => ProductAvailabilityHelper
                          .buyAgainFromCartItem(context, order.items.first),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF173E32),
                        side: const BorderSide(color: Color(0xFF4D6A5C)),
                        minimumSize: const Size(0, 40),
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
                    if (order.hasUnreviewedProducts) FilledButton(
                      onPressed: () async {
                        if (order.items.length == 1) {
                          final item = order.items.first;
                          await Get.to(
                            () => ProductReview(
                              productId: item.productId,
                              productTitle: item.title,
                              purchaseOrderId: order.id,
                            ),
                          );
                        } else {
                          await Get.to(() => OrderDetail(order: order));
                        }
                        if (mounted) _reload();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF173E32),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 40),
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
