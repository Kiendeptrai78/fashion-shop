import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/data/repositories/orders/orders_repository.dart';
import 'package:fashion_business_app/data/repositories/products/product_reposotory.dart';
import 'package:fashion_business_app/features/personalization/screens/account/coupons_screen.dart';
import 'package:fashion_business_app/features/personalization/services/account_activity.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/features/shop/screens/order/order_detail.dart';
import 'package:fashion_business_app/features/shop/screens/order/return_request_screen.dart';
import 'package:fashion_business_app/features/shop/screens/product_details/product_details.dart';
import 'package:fashion_business_app/features/shop/screens/product_reviews/product_review.dart';
import 'package:fashion_business_app/features/shop/screens/reels/velora_reels_screen.dart';
import 'package:fashion_business_app/features/shop/screens/support_chat/velora_support_chat_screen.dart';
import 'package:fashion_business_app/utils/local_storage/local_utility.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<OrderModel>> _orders;
  late Set<String> _read;
  String _selectedTab = 'all'; // 'all' | 'order' | 'voucher' | 'review' | 'product' | 'promo'

  static const _tabs = [
    ('all', 'All'),
    ('order', 'Orders'),
    ('voucher', 'Vouchers'),
    ('review', 'Reviews'),
    ('product', 'New arrivals'),
    ('promo', 'VELORA'),
  ];

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: ShopText('Couldn’t save. Please try again.')),
        );
      }
    }
  }

  Future<void> _reload() async {
    final request = OrderRepository().fetchUserOrders();
    setState(() {
      _orders = request;
    });
    try {
      await request;
    } catch (_) {
      // Rendered below.
    }
  }

  DateTime? _parseTimestamp(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  ({IconData icon, Color color, Color bg, String label}) _metaForKind(String kind, bool dark) {
    switch (kind) {
      case 'order':
        return (
          icon: Iconsax.truck_fast,
          color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
          bg: dark ? const Color(0xFF1E372D) : const Color(0xFFEAF2EE),
          label: 'Orders',
        );
      case 'voucher':
        return (
          icon: Iconsax.ticket_discount,
          color: const Color(0xFFD97706),
          bg: dark ? const Color(0xFF3A2A15) : const Color(0xFFFFF5E5),
          label: 'Vouchers',
        );
      case 'review':
        return (
          icon: Icons.star_rounded,
          color: const Color(0xFFC88A16),
          bg: dark ? const Color(0xFF342A14) : const Color(0xFFFFF8E1),
          label: 'Reviews',
        );
      case 'return':
        return (
          icon: Iconsax.refresh_circle,
          color: const Color(0xFF0284C7),
          bg: dark ? const Color(0xFF142D3C) : const Color(0xFFE0F2FE),
          label: 'Returns',
        );
      case 'product':
        return (
          icon: Iconsax.magic_star,
          color: const Color(0xFF0F766E),
          bg: dark ? const Color(0xFF163532) : const Color(0xFFE6F6F4),
          label: 'New arrivals',
        );
      default:
        return (
          icon: Icons.campaign_rounded,
          color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
          bg: dark ? const Color(0xFF20342B) : const Color(0xFFEDF3EF),
          label: 'VELORA',
        );
    }
  }

  Future<void> _openNotice(
    Map<String, dynamic> notice,
    List<OrderModel> orders,
    AccountActivity activity,
  ) async {
    await activity.markRead(notice['documentId']);
    final docId = (notice['documentId'] ?? notice['id'] ?? '').toString();
    final kind = (notice['kind'] ?? '').toString();
    final targetId = (notice['targetId'] ?? '').toString();
    final titleVi = (notice['titleVi'] ?? '').toString().toLowerCase();
    final bodyVi = (notice['bodyVi'] ?? '').toString().toLowerCase();

    final isVideoCommentReply = kind == 'video_comment' ||
        docId.startsWith('video-reply-') ||
        titleVi.contains('bình luận video');
    final isVideoReelPush = kind == 'video_reel' ||
        docId.startsWith('sim-push-') ||
        docId.startsWith('auto-sim-') ||
        bodyVi.contains('tab nổi bật');

    if (kind == 'order') {
      final matches = orders.where((order) => order.id == targetId);
      if (matches.isNotEmpty) Get.to(() => OrderDetail(order: matches.first));
    } else if ((isVideoCommentReply || isVideoReelPush) && targetId.isNotEmpty) {
      try {
        final product =
            await ProductRepository.instance.fetchProductById(targetId);
        if (mounted && product != null) {
          Get.to(
            () => VeloraReelsScreen(
              initialProduct: product,
              showBackButton: true,
              initialOpenComments: isVideoCommentReply,
            ),
          );
        }
      } catch (_) {}
    } else if (kind == 'product' && targetId.isNotEmpty) {
      try {
        final product = await ProductRepository.instance.fetchProductById(targetId);
        if (mounted && product != null) {
          Get.to(() => ProductDetail(product: product));
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: ShopText('Product no longer available.')),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: ShopText('Product no longer available.')),
          );
        }
      }
    } else if (kind == 'support_chat' || docId.startsWith('chat-')) {
      if (mounted) {
        Get.to(() => const VeloraSupportChatScreen());
      }
    } else if (kind == 'return' || docId.startsWith('return-')) {
      if (mounted) {
        Get.to(
          () => MyReturnRequestsScreen(
            highlightRequestId: targetId.isNotEmpty ? targetId : null,
          ),
        );
      }
    } else if (kind == 'review' && targetId.isNotEmpty) {
      if (mounted) Get.to(() => ProductReview(productId: targetId));
    } else if (kind == 'voucher') {
      if (Get.isRegistered<CustomerBenefits>()) {
        await CustomerBenefits.instance.initialize();
      }
      if (mounted) Get.to(() => CouponsScreen(initialCouponCode: targetId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: TAppbar(
        showBackArrow: true,
        title: const ShopText(
          'Notification',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          Obx(() {
            final activity = AccountActivity.current;
            final hasUnread = (activity?.unread ?? 0) > 0;
            if (!hasUnread) return const SizedBox.shrink();
            return TextButton(
              onPressed: () async {
                final orders = await _orders.catchError((_) => <OrderModel>[]);
                await _mark(orders);
                await activity?.markAllRead();
              },
              child: const ShopText('Mark all as read', style: TextStyle(fontSize: 12.5)),
            );
          }),
        ],
      ),
      body: FutureBuilder<List<OrderModel>>(
        future: _orders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (snapshot.hasError) {
            return Center(
              child: TextButton(onPressed: _reload, child: const ShopText('Try again')),
            );
          }
          final orders = (snapshot.data ?? []).toList()
            ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
          final orderMap = {for (final o in orders) o.id: o};

          return RefreshIndicator(
            onRefresh: _reload,
            color: const Color(0xFF173E32),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                const ShopText(
                  'Stay in the loop.',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.6),
                ),
                const SizedBox(height: 4),
                ShopText(
                  'Orders, vouchers, reviews & VELORA updates.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 14),

                // Filter chips
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _tabs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, index) {
                      final (id, label) = _tabs[index];
                      final selected = _selectedTab == id;
                      return Material(
                        color: selected
                            ? (dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32))
                            : (dark ? const Color(0xFF1D2D26) : const Color(0xFFF3F5F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: BorderSide(
                            color: selected
                                ? Colors.transparent
                                : (dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E7E0)),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => setState(() => _selectedTab = id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Center(
                              child: ShopText(
                                label,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  color: selected
                                      ? (dark ? const Color(0xFF102B23) : Colors.white)
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                Obx(() {
                  final activity = AccountActivity.current;
                  final allNotices = activity?.inbox.toList() ?? [];
                  final filteredNotices = _selectedTab == 'all'
                      ? allNotices
                      : allNotices.where((n) => (n['kind'] ?? 'promo').toString() == _selectedTab).toList();

                  final fallbackOrders = (_selectedTab == 'all' || _selectedTab == 'order')
                      ? orders.where((order) => !allNotices.any((n) =>
                          n['kind'] == 'order' && n['targetId'] == order.id)).toList()
                      : <OrderModel>[];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (activity != null && !activity.pushEnabled.value)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: OutlinedButton.icon(
                            onPressed: activity.enablePush,
                            icon: const Icon(Icons.notifications_active_outlined, size: 18),
                            label: const ShopText('Enable notifications'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      if (activity != null && activity.pushError.value.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ShopText(activity.pushError.value, style: theme.textTheme.bodySmall),
                        ),
                      if (filteredNotices.isEmpty && fallbackOrders.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 72),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Iconsax.notification, size: 50),
                                SizedBox(height: 18),
                                ShopText(
                                  'You’re all caught up.',
                                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                                ),
                                SizedBox(height: 8),
                                ShopText(
                                  'Order updates will appear here.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      for (final notice in filteredNotices) ...[
                        Builder(builder: (context) {
                          final kind = (notice['kind'] ?? 'promo').toString();
                          final targetId = (notice['targetId'] ?? '').toString();
                          final isRead = notice['read'] == true;
                          final meta = _metaForKind(kind, dark);
                          final rawImage = (notice['imageUrl'] ?? '').toString().trim();
                          final matchedOrder = kind == 'order' ? orderMap[targetId] : null;
                          final imageUrl = rawImage.isNotEmpty
                              ? rawImage
                              : (matchedOrder != null && matchedOrder.items.isNotEmpty
                                  ? (matchedOrder.items.first.image ?? '')
                                  : '');
                          final title =
                              (lang == 'en' ? notice['titleEn'] : notice['titleVi'])?.toString() ?? '';
                          final body =
                              (lang == 'en' ? notice['bodyEn'] : notice['bodyVi'])?.toString() ?? '';
                          final createdAt = _parseTimestamp(notice['createdAt']);

                          return _notificationCard(
                            context: context,
                            dark: dark,
                            isRead: isRead,
                            imageUrl: imageUrl,
                            icon: meta.icon,
                            iconColor: meta.color,
                            iconBg: meta.bg,
                            tagLabel: meta.label,
                            title: title,
                            body: body,
                            timestamp: createdAt != null
                                ? DateFormat('dd/MM HH:mm').format(createdAt)
                                : '',
                            onTap: () => _openNotice(notice, orders, activity!),
                          );
                        }),
                      ],
                      for (final order in fallbackOrders) ...[
                        Builder(builder: (context) {
                          final isRead = _read.contains(_key(order));
                          final meta = _metaForKind('order', dark);
                          final thumb = order.items.isNotEmpty ? (order.items.first.image ?? '') : '';
                          final title = lang == 'en'
                              ? 'Your order for ${order.itemsSummary(english: true)}'
                              : 'Đơn hàng ${order.itemsSummary()} của bạn';
                          final statusLabel = order.orderStatusText == 'Shipping'
                              ? 'On the way'
                              : order.orderStatusText;

                          return _notificationCard(
                            context: context,
                            dark: dark,
                            isRead: isRead,
                            imageUrl: thumb,
                            icon: meta.icon,
                            iconColor: meta.color,
                            iconBg: meta.bg,
                            tagLabel: statusLabel,
                            title: title,
                            body: '${formatShopMoney(order.totalAmount, language: lang)} · ${DateFormat.yMMMd(lang).format(order.orderDate)}',
                            timestamp: DateFormat('dd/MM').format(order.orderDate),
                            onTap: () async {
                              await _mark([order]);
                              if (mounted) Get.to(() => OrderDetail(order: order));
                            },
                          );
                        }),
                      ],
                    ],
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _notificationCard({
    required BuildContext context,
    required bool dark,
    required bool isRead,
    required String imageUrl,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String tagLabel,
    required String title,
    required String body,
    required String timestamp,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final bgColor = isRead
        ? (dark ? const Color(0xFF18241E) : Colors.white)
        : (dark ? const Color(0xFF1F332A) : const Color(0xFFF3F8F5));
    final borderColor = isRead
        ? (dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE7EBE5))
        : (dark ? const Color(0xFFDDEABB).withValues(alpha: 0.25) : const Color(0xFF173E32).withValues(alpha: 0.2));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl.isNotEmpty)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF22342B) : const Color(0xFFF3F4EF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TRoundedImage(
                          imageUrl: imageUrl,
                          isNetworkImage: true,
                          width: 56,
                          height: 56,
                          borderRadius: 14,
                          padding: const EdgeInsets.all(4),
                        ),
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: iconBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: bgColor, width: 1.5),
                          ),
                          child: Icon(icon, size: 12, color: iconColor),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, size: 22, color: iconColor),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: iconBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: ShopText(
                              tagLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: iconColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (timestamp.isNotEmpty)
                            Text(
                              timestamp,
                              style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                            ),
                          if (!isRead) ...[
                            const SizedBox(width: 6),
                            const CircleAvatar(radius: 4, backgroundColor: Color(0xFFD92D3E)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          body,
                          softWrap: true,
                          style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
