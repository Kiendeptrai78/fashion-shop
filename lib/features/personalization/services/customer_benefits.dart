import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  CheckoutQuote({
    required this.subtotal,
    this.discount = 0,
    this.productDiscount = 0,
    this.shippingDiscount = 0,
    this.coinsUsed = 0,
  })  : shipping = TPricingCalculator.getShippingCost('US'),
        tax = TPricingCalculator.getTaxRateForLocation('US');
  final double subtotal, discount, productDiscount, shippingDiscount, shipping, tax;
  final int coinsUsed;
  double get coinDiscount => coinsUsed / usdToVnd;
  double get total => max(0, subtotal + shipping + tax - discount - coinDiscount);
  int get totalVnd => (total * usdToVnd).round();
}

class CustomerBenefits extends GetxController {
  CustomerBenefits({
    required this.read,
    required this.write,
    DateTime Function()? now,
    this.fetchRemoteCoupons,
  }) : now = now ?? DateTime.now;
  factory CustomerBenefits.local() => CustomerBenefits(
    read: () => TLocalStorage.instance().readData<Map<String, dynamic>>(customerBenefitsKey),
    write: (data) => TLocalStorage.instance().saveData(customerBenefitsKey, data),
    fetchRemoteCoupons: _fetchActiveFirestoreVouchers,
  );
  static CustomerBenefits get instance => Get.find();
  final Map<String, dynamic>? Function() read;
  final Future<void> Function(Map<String, dynamic>) write;
  final DateTime Function() now;
  final Future<List<ShopCoupon>> Function()? fetchRemoteCoupons;

  static Future<List<ShopCoupon>> _fetchActiveFirestoreVouchers() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      // Determine customer's segment from their own order history so targeted vouchers sync accurately
      var receivedOrders = 0;
      var cancelledOrders = 0;
      var totalOrders = 0;
      var totalSpent = 0.0;
      if (uid.isNotEmpty) {
        try {
          final orderSnap = await FirebaseFirestore.instance
              .collection('Users')
              .doc(uid)
              .collection('Orders')
              .get();
          totalOrders = orderSnap.docs.length;
          for (final doc in orderSnap.docs) {
            final d = doc.data();
            final status = (d['status'] ?? '').toString().split('.').last;
            if (status == 'received') {
              receivedOrders++;
              totalSpent += (d['totalAmount'] as num? ?? 0).toDouble();
            } else if (status == 'cancelled') {
              cancelledOrders++;
            }
          }
        } catch (_) {}
      }
      final cancelRate = totalOrders == 0 ? 0.0 : cancelledOrders / totalOrders;
      final isBomHang = cancelledOrders >= 2 || (totalOrders >= 2 && cancelRate >= 0.5);
      final isVip = !isBomHang && (receivedOrders >= 3 || totalSpent >= 300);
      final isLoyal = !isBomHang && receivedOrders >= 1;
      final isNewMember = !isBomHang && receivedOrders == 0;

      final snap = await FirebaseFirestore.instance
          .collection('Vouchers')
          .where('active', isEqualTo: true)
          .get();
      final result = <ShopCoupon>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final audience = (data['targetAudience'] ?? 'all').toString();
        final excludeBom = data['excludeBomHang'] != false;
        final targetIds = (data['targetUserIds'] as List?)
                ?.map((e) => e.toString())
                .toSet() ??
            const <String>{};

        if (audience == 'specific') {
          if (uid.isEmpty || !targetIds.contains(uid)) continue;
        } else {
          if (excludeBom && isBomHang) continue;
          if (audience == 'vip' && !isVip) continue;
          if (audience == 'loyal' && !isLoyal) continue;
          if (audience == 'newMember' && !isNewMember) continue;
        }

        final rawExpires = data['expires'];
        DateTime? expires;
        if (rawExpires is Timestamp) {
          expires = rawExpires.toDate();
        } else if (rawExpires is String) {
          expires = DateTime.tryParse(rawExpires);
        }
        if (expires == null) continue;
        result.add(ShopCoupon(
          id: ((data['code'] ?? doc.id) as String).trim().toUpperCase(),
          title: (data['title'] ?? 'Ưu đãi từ VELORA') as String,
          expires: expires,
          percent: (data['percent'] as num? ?? 0).toInt(),
          maxUsd: (data['maxUsd'] as num? ?? 0).toDouble(),
          minUsd: (data['minUsd'] as num? ?? 0).toDouble(),
          shipping: data['shipping'] == true,
        ));
      }
      return result;
    } catch (_) {
      return [];
    }
  }
  final revision = 0.obs;
  final busy = false.obs;
  final selectedProductCoupon = Rxn<ShopCoupon>();
  final selectedShippingCoupon = Rxn<ShopCoupon>();
  Rxn<ShopCoupon> get selectedCartCoupon => selectedProductCoupon;

  void saveCouponSelection(ShopCoupon coupon) {
    if (coupon.shipping) {
      selectedShippingCoupon.value = coupon;
    } else {
      selectedProductCoupon.value = coupon;
    }
  }
  Map<String, dynamic> _state = {};
  int get balanceVnd { revision.value; return (_state['balance'] as num? ?? 10000000).toInt(); }
  List<ShopCoupon> get coupons {
    revision.value;
    return (_state['coupons'] as List? ?? []).map((data) => ShopCoupon.fromJson(Map<String, dynamic>.from(data))).toList();
  }
  List<ShopCoupon> get availableCoupons => coupons
      .where((c) => !used.contains(c.id) && now().isBefore(c.expires))
      .toList();

  /// Sorts available coupons Shopee/Grab style:
  /// - Eligible coupons first, ranked by highest actual savings descending
  /// - Ineligible coupons below, ranked by smallest remaining spend needed
  List<ShopCoupon> sortedAvailableFor(double? subtotal) {
    final list = List<ShopCoupon>.from(availableCoupons);
    final sub = subtotal ?? 0;
    list.sort((a, b) {
      if (sub > 0) {
        final aOk = eligible(a, sub);
        final bOk = eligible(b, sub);
        if (aOk != bOk) return aOk ? -1 : 1;
        if (aOk && bOk) {
          final diff = b.discount(sub).compareTo(a.discount(sub));
          if (diff != 0) return diff;
          return a.expires.compareTo(b.expires);
        }
        final gapA = a.minUsd - sub;
        final gapB = b.minUsd - sub;
        final gapDiff = gapA.compareTo(gapB);
        if (gapDiff != 0) return gapDiff;
      }
      // Browse mode (no subtotal): prioritize zero/low minUsd & higher discount value
      final scoreA = a.shipping ? 12.0 : (a.percent.toDouble() + (a.minUsd == 0 ? 5 : 0));
      final scoreB = b.shipping ? 12.0 : (b.percent.toDouble() + (b.minUsd == 0 ? 5 : 0));
      final sDiff = scoreB.compareTo(scoreA);
      if (sDiff != 0) return sDiff;
      return a.expires.compareTo(b.expires);
    });
    return list;
  }

  /// Returns the single best recommended coupon for [subtotal] (or top value
  /// coupon when browsing with `subtotal == null`).
  ShopCoupon? bestCouponFor(double? subtotal) {
    final sorted = sortedAvailableFor(subtotal);
    if (sorted.isEmpty) return null;
    if (subtotal != null && subtotal > 0) {
      final first = sorted.first;
      return eligible(first, subtotal) && first.discount(subtotal) > 0
          ? first
          : null;
    }
    return sorted.first;
  }

  List<ShopCoupon> sortedShippingCouponsFor(double? subtotal) =>
      sortedAvailableFor(subtotal).where((c) => c.shipping).toList();

  List<ShopCoupon> sortedProductCouponsFor(double? subtotal) =>
      sortedAvailableFor(subtotal).where((c) => !c.shipping).toList();

  ShopCoupon? bestShippingCouponFor(double? subtotal) {
    final list = sortedShippingCouponsFor(subtotal);
    if (list.isEmpty) return null;
    if (subtotal != null && subtotal > 0) {
      final first = list.first;
      return eligible(first, subtotal) && first.discount(subtotal) > 0
          ? first
          : null;
    }
    return list.first;
  }

  ShopCoupon? bestProductCouponFor(double? subtotal) {
    final list = sortedProductCouponsFor(subtotal);
    if (list.isEmpty) return null;
    if (subtotal != null && subtotal > 0) {
      final first = list.first;
      return eligible(first, subtotal) && first.discount(subtotal) > 0
          ? first
          : null;
    }
    return list.first;
  }

  ShopCoupon? findAvailableByCode(String rawCode) {
    final norm = rawCode.trim().toUpperCase();
    if (norm.isEmpty) return null;
    return availableCoupons.firstWhereOrNull(
      (c) => c.id.trim().toUpperCase() == norm,
    );
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
    final remote = fetchRemoteCoupons != null
        ? await fetchRemoteCoupons!.call()
        : const <ShopCoupon>[];
    final byId = <String, ShopCoupon>{
      for (final coupon in existing) coupon.id: coupon,
    };
    var changed = _state['created'] != true;
    for (final coupon in incoming) {
      if (!byId.containsKey(coupon.id)) {
        byId[coupon.id] = coupon;
        changed = true;
      }
    }
    for (final coupon in remote) {
      final prev = byId[coupon.id];
      if (prev == null ||
          prev.title != coupon.title ||
          prev.percent != coupon.percent ||
          prev.maxUsd != coupon.maxUsd ||
          prev.minUsd != coupon.minUsd ||
          prev.shipping != coupon.shipping ||
          prev.expires != coupon.expires) {
        byId[coupon.id] = coupon;
        changed = true;
      }
    }
    if (changed) {
      await _save({..._state, 'created': true, 'balance': balanceVnd,
        'coupons': byId.values.map((coupon) => coupon.toJson()).toList()});
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

  CheckoutQuote quote(double subtotal, ShopCoupon? coupon) => CheckoutQuote(
        subtotal: subtotal,
        discount: coupon != null && eligible(coupon, subtotal)
            ? coupon.discount(subtotal)
            : 0,
        productDiscount:
            coupon != null && !coupon.shipping && eligible(coupon, subtotal)
                ? coupon.discount(subtotal)
                : 0,
        shippingDiscount:
            coupon != null && coupon.shipping && eligible(coupon, subtotal)
                ? coupon.discount(subtotal)
                : 0,
      );

  /// Stackable quote: up to 1 Product Discount coupon + 1 Freeship coupon.
  CheckoutQuote quoteDual(
    double subtotal, {
    ShopCoupon? productCoupon,
    ShopCoupon? shippingCoupon,
    int coins = 0,
  }) {
    final prodOff = (productCoupon != null &&
            !productCoupon.shipping &&
            eligible(productCoupon, subtotal))
        ? productCoupon.discount(subtotal)
        : 0.0;
    final shipOff = (shippingCoupon != null &&
            shippingCoupon.shipping &&
            eligible(shippingCoupon, subtotal))
        ? shippingCoupon.discount(subtotal)
        : 0.0;
    final base = CheckoutQuote(subtotal: subtotal, discount: prodOff + shipOff);
    return CheckoutQuote(
      subtotal: subtotal,
      discount: prodOff + shipOff,
      productDiscount: prodOff,
      shippingDiscount: shipOff,
      coinsUsed: coins.clamp(0, base.totalVnd),
    );
  }

  /// One stable order ID prevents duplicate documents when a checkout is retried.
  Future<CheckoutQuote> purchase({
    required String orderId,
    required double subtotal,
    required bool bank,
    ShopCoupon? coupon,
    ShopCoupon? shippingCoupon,
    int coins = 0,
    required Future<void> Function(CheckoutQuote quote) saveOrder,
  }) async {
    if (busy.value) throw StateError('A checkout is already in progress.');
    busy.value = true;
    try {
      final receipts = Map<String, dynamic>.from(_state['receipts'] as Map? ?? {});
      final prodC = (coupon != null && !coupon.shipping) ? coupon : null;
      final shipC = shippingCoupon ?? ((coupon != null && coupon.shipping) ? coupon : null);
      final result = quoteDual(
        subtotal,
        productCoupon: prodC,
        shippingCoupon: shipC,
        coins: coins,
      );
      if (receipts.containsKey(orderId)) {
        final receipt = Map<String, dynamic>.from(receipts[orderId]);
        return CheckoutQuote(
          subtotal: (receipt['subtotal'] as num).toDouble(),
          discount: (receipt['discount'] as num).toDouble(),
          productDiscount: (receipt['productDiscount'] as num? ?? 0).toDouble(),
          shippingDiscount: (receipt['shippingDiscount'] as num? ?? 0).toDouble(),
          coinsUsed: (receipt['coinsUsed'] as num? ?? 0).toInt(),
        );
      }
      if (subtotal <= 0) throw StateError('Your bag is empty.');
      if (prodC != null && !eligible(prodC, subtotal)) {
        throw StateError('This coupon is no longer available.');
      }
      if (shipC != null && !eligible(shipC, subtotal)) {
        throw StateError('This shipping voucher is no longer available.');
      }
      if (bank && balanceVnd < result.totalVnd) {
        throw StateError('Not enough demo balance.');
      }
      await saveOrder(result);
      final entries = ledger.reversed.toList();
      if (bank) {
        entries.add({
          'id': orderId,
          'amount': -result.totalVnd,
          'date': now().toUtc().toIso8601String(),
          'title': 'Demo payment',
        });
      }
      await _save({
        ..._state,
        'balance': balanceVnd - (bank ? result.totalVnd : 0),
        'used': {
          ...used,
          if (prodC != null) prodC.id,
          if (shipC != null) shipC.id,
        }.toList(),
        'receipts': {
          ...receipts,
          orderId: {
            'subtotal': result.subtotal,
            'discount': result.discount,
            'productDiscount': result.productDiscount,
            'shippingDiscount': result.shippingDiscount,
            'coinsUsed': result.coinsUsed,
          },
        },
        'ledger': entries,
      });
      if (prodC != null && selectedProductCoupon.value?.id == prodC.id) {
        selectedProductCoupon.value = null;
      }
      if (shipC != null && selectedShippingCoupon.value?.id == shipC.id) {
        selectedShippingCoupon.value = null;
      }
      return result;
    } finally {
      busy.value = false;
    }
  }
}
