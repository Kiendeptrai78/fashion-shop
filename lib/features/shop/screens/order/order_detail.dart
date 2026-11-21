import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/data/repositories/orders/orders_repository.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

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
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _refund(); });
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
    final confirmed = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(
      title: ShopText(next == OrderStatus.cancelled ? 'Cancel Order' : 'Received Order'),
      content: ShopText(next == OrderStatus.cancelled
          ? 'Are you sure you want to cancel this order?' : 'Did you actually received the order?'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialog, false), child: const ShopText('Back')),
        TextButton(onPressed: () => Navigator.pop(dialog, true), child: const ShopText('Confirm'))],
    ));
    if (confirmed != true || !mounted) return;
    setState(() { _busy = true; _error = null; });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final subtotal = order.items.fold<double>(0, (sum, item) => sum + item.price * item.quantity);
    final cancelled = order.status == OrderStatus.cancelled;
    final tone = cancelled ? theme.colorScheme.error : theme.colorScheme.primary;
    final canCancel = [OrderStatus.pending, OrderStatus.processing].contains(order.status);
    final canReceive = order.status == OrderStatus.shipped;
    return Scaffold(
      appBar: const TAppbar(showBackArrow: true, title: ShopText('Order details',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(cancelled ? Icons.cancel_outlined : order.status == OrderStatus.received
                ? Icons.check_circle_outline : Icons.local_shipping_outlined, color: tone, size: 32),
            const SizedBox(height: 18),
            ShopText(order.orderStatusText == 'Shipping' ? 'On the way' : order.orderStatusText,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, color: tone)),
            const SizedBox(height: 10), Text('#${order.id}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 6), Text(DateFormat.yMMMd(locale).format(order.orderDate),
                style: theme.textTheme.bodySmall),
          ])),
        const SizedBox(height: 28),
        const ShopText('Your pairs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        for (final item in order.items) Padding(padding: const EdgeInsets.only(bottom: 20),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TRoundedImage(imageUrl: item.image ?? '', width: 82, height: 88, isNetworkImage: true),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 7),
              ShopText((item.selectedVariation?.entries ?? []).map((e) => '${e.key}: ${e.value}').join(' · '),
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 7), ShopText('Qty ${item.quantity}', style: theme.textTheme.bodySmall),
              const SizedBox(height: 7), Text(formatShopMoney(item.price * item.quantity, language: locale),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ])),
          ])),
        const Divider(height: 32),
        const ShopText('Shipping Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        if (order.address != null) ...[
          Text(order.address!.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8), Text(order.address!.phoneNumber),
          const SizedBox(height: 8), Text(order.address!.toString(), style: theme.textTheme.bodySmall?.copyWith(height: 1.6)),
        ] else const ShopText('Address unavailable'),
        const Divider(height: 36),
        const ShopText('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14), ShopText(order.paymentMethod),
        const Divider(height: 36),
        _amount('Subtotal', subtotal, locale), const SizedBox(height: 14),
        _amount('Fees and adjustments', order.totalAmount + order.discountAmount - subtotal, locale),
        if (order.discountAmount > 0) ...[const SizedBox(height: 14),
          _amount('Discount', -order.discountAmount, locale),
          const SizedBox(height: 8), Text(order.couponCode, style: theme.textTheme.bodySmall),
        ],
        const Divider(height: 32), _amount('Order total', order.totalAmount, locale, total: true),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 20),
            child: ShopText(_error!, style: TextStyle(color: theme.colorScheme.error))),
      ]),
      bottomNavigationBar: !canCancel && !canReceive ? null : SafeArea(top: false,
        minimum: const EdgeInsets.fromLTRB(24, 12, 24, 20), child: OutlinedButton(
          onPressed: _busy ? null : () => _update(canCancel ? OrderStatus.cancelled : OrderStatus.received),
          child: ShopText(_busy ? 'Saving changes...' : canCancel ? 'Cancel Order' : 'Received Order'),
        )),
    );
  }

  Widget _amount(String label, double amount, String locale, {bool total = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(child: ShopText(label)), const SizedBox(width: 12),
      Text(formatShopMoney(amount, language: locale), style: TextStyle(
          fontWeight: total ? FontWeight.w700 : FontWeight.w500, fontSize: total ? 21 : 14)),
    ],
  );
}
