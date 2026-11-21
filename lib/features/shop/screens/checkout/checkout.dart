import 'package:fashion_business_app/features/personalization/models/address_model.dart';
import 'package:fashion_business_app/features/personalization/screens/account/demo_bank_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:fashion_business_app/data/repositories/authentication/authentication_repository.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/features/personalization/screens/account/coupons_screen.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'widgets/checkout_complete_screen.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/screens/checkout/widgets/billing_amount_section.dart';
import '../../controllers/product/checkout_controller.dart';
import 'widgets/billing_address_section.dart';
import 'widgets/billing_payment_section.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/features/personalization/controllers/address_controller.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _checkoutController = CheckoutController.instance;
  final _benefits = CustomerBenefits.instance;
  final _orderId = const Uuid().v4();
  ShopCoupon? _coupon;
  String? _error;

  @override
  void initState() {
    super.initState();
    final addresses = AddressController.instance;
    if (addresses.selectedAddress.value.id.isEmpty) {
      addresses.getAllUserAddresses().catchError((_) => <AddressModel>[]);
    }
  }

  Future<void> _submit() async {
    if (_benefits.busy.value) return;
    final address = AddressController.instance.selectedAddress.value;
    if (address.id.isEmpty) {
      await AddressController.instance.selectNewAddressPopup(context);
      return;
    }
    final cart = CartController.instance;
    final bank = _checkoutController.selectedPaymentMethod.value.name == 'Demo bank';
    setState(() => _error = null);
    try {
      await _benefits.purchase(orderId: _orderId, subtotal: cart.totalCartPrice.value,
        bank: bank, coupon: _coupon, saveOrder: (quote) async {
          final uid = AuthenticationRepository.instance.authUser.uid;
          final date = DateTime.now();
          final order = OrderModel(id: _orderId, userId: uid, status: OrderStatus.pending,
            totalAmount: quote.total, orderDate: date, searchDate: date,
            paymentMethod: bank ? 'Demo bank' : 'Cash on delivery', address: address,
            deliveryDate: date.add(const Duration(days: 3)), items: cart.cartItems.toList());
          final db = FirebaseFirestore.instance;
          final user = db.collection('Users').doc(uid);
          final batch = db.batch();
          batch.set(user.collection('Orders').doc(_orderId), {...order.toJson(),
            'discountAmount': quote.discount, 'couponCode': _coupon?.id ?? '',
            'paymentStatus': bank ? 'demo_paid' : 'pay_on_delivery', 'notificationPending': true});
          batch.set(user.collection('Notifications').doc('order-$_orderId-pending'), {
            'kind': 'order', 'targetId': _orderId, 'read': false,
            'titleVi': 'Đã nhận đơn hàng', 'titleEn': 'Order received',
            'bodyVi': 'Bạn có thể theo dõi tiến trình trong Đơn hàng của tôi.',
            'bodyEn': 'Track its progress in My Orders.', 'createdAt': FieldValue.serverTimestamp(),
          });
          await batch.commit();
        });
      cart.clearCart();
      if (!mounted) return;
      await Get.off(() => const CheckoutCompleteScreen());
    } catch (error) {
      if (mounted) setState(() => _error = error is StateError ? error.message.toString()
          : 'Couldn’t place the order. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartController.instance;
    final theme = Theme.of(context);
    return PopScope(canPop: !_benefits.busy.value, child: Scaffold(
      appBar: const TAppbar(showBackArrow: true, title: ShopText('Checkout',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.6))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const ShopText('The final details.', style: TextStyle(fontSize: 28,
              fontWeight: FontWeight.w600, letterSpacing: -1)),
          const SizedBox(height: 8),
          ShopText('Review your pairs and choose how to pay.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 28),
          const TBillingAddressSection(),
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(height: 1)),
          const TBillingPaymentSection(),
          Obx(() => _checkoutController.selectedPaymentMethod.value.name != 'Demo bank'
              ? const SizedBox.shrink() : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 16),
                const ShopText('Balance is debited after your order is saved.', style: TextStyle(fontSize: 12, height: 1.6)),
                const SizedBox(height: 10),
                Text(formatShopMoney(_benefits.balanceVnd / usdToVnd,
                    language: Localizations.localeOf(context).languageCode), style: const TextStyle(fontWeight: FontWeight.w600)),
                TextButton(onPressed: () => Get.to(() => const DemoBankScreen()), child: const ShopText('Top up balance')),
              ])),
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(height: 1)),
          Row(children: [
            const Expanded(child: ShopText('Your pairs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
            TextButton(onPressed: () => Get.back(), child: const ShopText('Edit bag')),
          ]),
          const SizedBox(height: 12),
          Obx(() => Column(children: [for (final item in cart.cartItems)
            Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                TRoundedImage(imageUrl: item.image ?? '', width: 84, height: 84, isNetworkImage: true),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ShopText(item.brandName ?? '', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  ShopText(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ShopText((item.selectedVariation?.entries ?? []).map((e) => '${e.key}: ${e.value}').join(' · '),
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(spacing: 12, children: [ShopText('Qty ${item.quantity}', style: theme.textTheme.bodySmall),
                    ShopText(formatShopMoney(item.price * item.quantity, language: Localizations.localeOf(context).languageCode),
                        style: const TextStyle(fontWeight: FontWeight.w600))]),
                ])),
              ])),
          ])),
          const Divider(height: 32),
          ListTile(contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.local_offer_outlined),
            title: const ShopText('My Coupons'),
            subtitle: _coupon == null ? const ShopText('Choose a coupon') : Text(_coupon!.id),
            trailing: _coupon == null ? const Icon(Icons.chevron_right) : IconButton(
                tooltip: 'Remove coupon'.tr, onPressed: () => setState(() => _coupon = null),
                icon: const Icon(Icons.close, size: 18)),
            onTap: () async {
              final coupon = await Get.to<ShopCoupon>(() => CouponsScreen(subtotal: cart.totalCartPrice.value));
              if (coupon != null && mounted) setState(() => _coupon = coupon);
            },
          ),
          const Divider(height: 32),
          const ShopText('Order summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          TBillingAmountSection(discount: _benefits.quote(cart.totalCartPrice.value, _coupon).discount),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 16),
              child: ShopText(_error!, style: TextStyle(color: theme.colorScheme.error))),
        ]),
      ),
      bottomNavigationBar: Obx(() {
        final subtotal = cart.totalCartPrice.value;
        final total = _benefits.quote(subtotal, _coupon).total;
        final bank = _checkoutController.selectedPaymentMethod.value.name == 'Demo bank';
        final busy = _benefits.busy.value;
        return SafeArea(top: false, child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15)))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const ShopText('Total to pay'),
              ShopText(formatShopMoney(total, language: Localizations.localeOf(context).languageCode), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: subtotal <= 0 || busy ? null : _submit,
              child: ShopText(busy ? 'Placing your order...' : bank ? 'Pay now' : 'Place order · Pay on delivery'),
            )),
          ]),
        ));
      }),
    ));
  }
}
