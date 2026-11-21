import 'dart:math';
import 'package:get/get.dart';
import 'package:vnlunar/vnlunar.dart';
import 'package:fashion_business_app/utils/local_storage/local_utility.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:fashion_business_app/utils/helpers/pricing_caculator.dart';

const customerBenefitsKey = 'customer_benefits_demo_v1';

class ShopCoupon {
  const ShopCoupon({required this.id, required this.title, required this.expires,
    this.percent = 0, this.maxUsd = 0, this.minUsd = 0, this.shipping = false});
  final String id, title;
  final DateTime expires;
  final int percent;
  final double maxUsd, minUsd;
  final bool shipping;

  double discount(double subtotal) => subtotal < minUsd ? 0 : shipping
      ? TPricingCalculator.getShippingCost('US')
      : (min(subtotal * percent / 100, maxUsd) * 100).floorToDouble() / 100;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'expires': expires.toIso8601String(),
    'percent': percent, 'maxUsd': maxUsd, 'minUsd': minUsd, 'shipping': shipping};
  factory ShopCoupon.fromJson(Map<String, dynamic> data) => ShopCoupon(
    id: data['id'], title: data['title'], expires: DateTime.parse(data['expires']),
    percent: data['percent'], maxUsd: (data['maxUsd'] as num).toDouble(),
    minUsd: (data['minUsd'] as num).toDouble(), shipping: data['shipping'] == true);
}

/// Store policy: one coupon per holiday occurrence, using Vietnam's calendar.
List<ShopCoupon> couponsIssuedOn(DateTime date, {required bool newCustomer}) {
  final day = DateTime(date.year, date.month, date.day);
  final coupons = <ShopCoupon>[];
  if (newCustomer) {
    coupons.addAll([
      ShopCoupon(id: 'WELCOME10', title: 'A welcome for your first pairs', percent: 10,
          maxUsd: 10, minUsd: 50, expires: day.add(const Duration(days: 30))),
      ShopCoupon(id: 'SHIPNEW', title: 'Shipping on us', shipping: true,
          expires: day.add(const Duration(days: 14))),
    ]);
  }
  final solar = <String, String>{'1-1': 'New year', '3-8': 'International Women’s Day',
    '4-30': 'Reunification Day', '5-1': 'Labour Day', '9-2': 'National Day',
    '11-20': 'Vietnamese Teachers’ Day', '12-25': 'Christmas'};
  String? event = solar['${day.month}-${day.day}'];
  String eventId = '${day.month}-${day.day}';
  final lunar = convertSolar2Lunar(day.day, day.month, day.year, 7);
  if (lunar[3] == 0) {
    if (lunar[0] == 1 && lunar[1] == 1) { event = 'Lunar New Year'; eventId = 'TET'; }
    if (lunar[0] == 10 && lunar[1] == 3) { event = 'Hùng Kings Festival'; eventId = 'HUNG'; }
    if (lunar[0] == 15 && lunar[1] == 8) { event = 'Mid-autumn Festival'; eventId = 'TRUNGTHU'; }
  }
  if (event != null) coupons.add(ShopCoupon(id: 'LE-${day.year}-$eventId', title: event,
      percent: 15, maxUsd: 15, minUsd: 40, expires: day.add(const Duration(days: 7))));
  return coupons;
}

class CheckoutQuote {
  CheckoutQuote({required this.subtotal, this.discount = 0})
      : shipping = TPricingCalculator.getShippingCost('US'),
        tax = TPricingCalculator.getTaxRateForLocation('US');
  final double subtotal, discount, shipping, tax;
  double get total => max(0, subtotal + shipping + tax - discount);
  int get totalVnd => (total * usdToVnd).round();
}

class CustomerBenefits extends GetxController {
  CustomerBenefits({required this.read, required this.write, DateTime Function()? now})
      : now = now ?? DateTime.now;
  factory CustomerBenefits.local() => CustomerBenefits(
    read: () => TLocalStorage.instance().readData<Map<String, dynamic>>(customerBenefitsKey),
    write: (data) => TLocalStorage.instance().saveData(customerBenefitsKey, data),
  );
  static CustomerBenefits get instance => Get.find();
  final Map<String, dynamic>? Function() read;
  final Future<void> Function(Map<String, dynamic>) write;
  final DateTime Function() now;
  final revision = 0.obs;
  final busy = false.obs;
  Map<String, dynamic> _state = {};
  int get balanceVnd { revision.value; return (_state['balance'] as num? ?? 10000000).toInt(); }
  List<ShopCoupon> get coupons {
    revision.value;
    return (_state['coupons'] as List? ?? []).map((data) => ShopCoupon.fromJson(Map<String, dynamic>.from(data))).toList();
  }
  Set<String> get seen => Set<String>.from(_state['seenCoupons'] as List? ?? []);
  int get newCouponCount => coupons.where((coupon) => !seen.contains(coupon.id)
      && !used.contains(coupon.id) && now().isBefore(coupon.expires)).length;
  Future<void> markCouponsSeen() => _save({..._state,
      'seenCoupons': {...seen, ...coupons.map((coupon) => coupon.id)}.toList()});

  Set<String> get used => Set<String>.from(_state['used'] as List? ?? []);
  List<Map<String, dynamic>> get ledger {
    revision.value;
    return (_state['ledger'] as List? ?? []).map((data) => Map<String, dynamic>.from(data)).toList().reversed.toList();
  }
  bool eligible(ShopCoupon coupon, double subtotal) => !used.contains(coupon.id)
      && now().isBefore(coupon.expires) && subtotal >= coupon.minUsd;

  Future<void> initialize() async {
    _state = read() ?? {};
    final existing = coupons;
    final date = now();
    final incoming = [for (var offset = 0; offset < 7; offset++)
      ...couponsIssuedOn(date.subtract(Duration(days: offset)),
          newCustomer: offset == 0 && _state['created'] != true)];
    final ids = existing.map((coupon) => coupon.id).toSet();
    final added = incoming.where((coupon) => !ids.contains(coupon.id)).toList();
    if (_state['created'] != true || added.isNotEmpty) {
      await _save({..._state, 'created': true, 'balance': balanceVnd,
        'coupons': [...existing, ...added].map((coupon) => coupon.toJson()).toList()});
    }
  }

  Future<void> _save(Map<String, dynamic> next) async {
    await write(next);
    _state = next;
    revision.value++;
  }

  Future<void> topUp({int amountVnd = 10000000}) async {
    if (amountVnd <= 0) throw ArgumentError.value(amountVnd);
    if (busy.value) return;
    busy.value = true;
    try {
      await _save({..._state, 'balance': balanceVnd + amountVnd,
        'ledger': [...ledger.reversed, {'id': 'topup-${now().microsecondsSinceEpoch}',
          'amount': amountVnd, 'date': now().toUtc().toIso8601String(), 'title': 'Demo top-up'}]});
    } finally { busy.value = false; }
  }

  Future<void> refund(String orderId) async {
    if (busy.value) throw StateError('A checkout is already in progress.');
    final entries = ledger.reversed.toList();
    if (entries.any((entry) => entry['id'] == 'refund-$orderId')) return;
    final debit = entries.where((entry) => entry['id'] == orderId && (entry['amount'] as num) < 0).firstOrNull;
    if (debit == null) return;
    busy.value = true;
    try {
      final amount = -(debit['amount'] as num).toInt();
      await _save({..._state, 'balance': balanceVnd + amount,
        'ledger': [...entries, {'id': 'refund-$orderId', 'amount': amount,
          'date': now().toUtc().toIso8601String(), 'title': 'Demo refund'}]});
    } finally { busy.value = false; }
  }

  CheckoutQuote quote(double subtotal, ShopCoupon? coupon) => CheckoutQuote(subtotal: subtotal,
      discount: coupon != null && eligible(coupon, subtotal) ? coupon.discount(subtotal) : 0);

  /// One stable order ID prevents duplicate documents when a checkout is retried.
  Future<CheckoutQuote> purchase({required String orderId, required double subtotal,
    required bool bank, ShopCoupon? coupon,
    required Future<void> Function(CheckoutQuote quote) saveOrder}) async {
    if (busy.value) throw StateError('A checkout is already in progress.');
    busy.value = true;
    try {
      final receipts = Map<String, dynamic>.from(_state['receipts'] as Map? ?? {});
      final result = quote(subtotal, coupon);
      if (receipts.containsKey(orderId)) {
        final receipt = Map<String, dynamic>.from(receipts[orderId]);
        return CheckoutQuote(subtotal: (receipt['subtotal'] as num).toDouble(),
            discount: (receipt['discount'] as num).toDouble());
      }
      if (subtotal <= 0) throw StateError('Your bag is empty.');
      if (coupon != null && !eligible(coupon, subtotal)) throw StateError('This coupon is no longer available.');
      if (bank && balanceVnd < result.totalVnd) throw StateError('Not enough demo balance.');
      await saveOrder(result);
      final entries = ledger.reversed.toList();
      if (bank) entries.add({'id': orderId, 'amount': -result.totalVnd,
        'date': now().toUtc().toIso8601String(), 'title': 'Demo payment'});
      await _save({..._state, 'balance': balanceVnd - (bank ? result.totalVnd : 0),
        'used': {...used, if (coupon != null) coupon.id}.toList(),
        'receipts': {...receipts, orderId: {'subtotal': result.subtotal, 'discount': result.discount}},
        'ledger': entries});
      return result;
    } finally { busy.value = false; }
  }
}
