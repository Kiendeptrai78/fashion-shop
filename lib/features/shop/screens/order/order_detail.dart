import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/dialogs/velora_confirm_dialog.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/data/repositories/orders/orders_repository.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/features/shop/models/cart_item_model.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/features/shop/screens/product_reviews/product_review.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
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
    final tone = cancelled ? theme.colorScheme.error : theme.colorScheme.primary;
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
              color: tone.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tone.withValues(alpha: 0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  cancelled
                      ? Icons.cancel_outlined
                      : received
                          ? Icons.check_circle_outline
                          : Icons.local_shipping_outlined,
                  color: tone,
                  size: 30,
                ),
                const SizedBox(height: 14),
                ShopText(
                  order.orderStatusText == 'Shipping' ? 'On the way' : order.orderStatusText,
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: tone),
                ),
                const SizedBox(height: 8),
                Text('#${order.id}', style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(DateFormat.yMMMd(locale).format(order.orderDate), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const ShopText('Your pairs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          for (final item in order.items)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1A2721) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5EAE3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TRoundedImage(imageUrl: item.image ?? '', width: 78, height: 84, isNetworkImage: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                        if ((item.selectedVariation?.entries ?? []).isNotEmpty) ...[
                          const SizedBox(height: 5),
                          ShopText(
                            (item.selectedVariation?.entries ?? []).map((e) => '${e.key}: ${e.value}').join(' · '),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 5),
                        ShopText('Qty ${item.quantity}', style: theme.textTheme.bodySmall),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                formatShopMoney(item.price * item.quantity, language: locale),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
                                ),
                              ),
                            ),
                            if (received)
                              OutlinedButton.icon(
                                onPressed: () => _openReviewItem(item),
                                icon: const Icon(Icons.star_rounded, size: 15, color: Color(0xFFD99A1E)),
                                label: const ShopText('Write a review', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: const Size(0, 32),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
