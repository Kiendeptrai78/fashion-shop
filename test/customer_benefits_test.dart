import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';

void main() {
  late Map<String, dynamic>? saved;
  late DateTime date;
  late CustomerBenefits benefits;
  setUp(() async {
    saved = null;
    date = DateTime(2026, 11, 20, 12);
    benefits = CustomerBenefits(read: () => saved, write: (value) async { saved = value; }, now: () => date);
    await benefits.initialize();
  });

  test('welcome and holiday gifts are issued once and are not renewed', () async {
    expect(benefits.coupons.length, 3);
    expect(benefits.coupons.where((c) => c.id == 'WELCOME10').length, 1);
    final expiry = benefits.coupons.first.expires;
    date = date.add(const Duration(days: 1));
    await benefits.initialize();
    expect(benefits.coupons.length, 3);
    expect(benefits.coupons.first.expires, expiry);
    date = DateTime(2027, 1, 1, 10);
    await benefits.initialize();
    expect(benefits.coupons.where((c) => c.title == 'New year').length, 1);
    await benefits.initialize();
    expect(benefits.coupons.where((c) => c.title == 'New year').length, 1);
  });

  test('new coupon badge clears after viewing and returns for a new holiday', () async {
    expect(benefits.newCouponCount, 3);
    await benefits.markCouponsSeen();
    expect(benefits.newCouponCount, 0);
    date = DateTime(2027, 1, 1);
    await benefits.initialize();
    expect(benefits.newCouponCount, 1);
  });

  test('Vietnam lunar New Year gift follows lunar date across years', () {
    expect(couponsIssuedOn(DateTime(2026, 2, 17), newCustomer: false).single.title, 'Lunar New Year');
    expect(couponsIssuedOn(DateTime(2027, 2, 6), newCustomer: false).single.title, 'Lunar New Year');
    expect(couponsIssuedOn(DateTime(2026, 2, 18), newCustomer: false), isEmpty);
  });

  test('discount checks minimum, cap and expiry; shipping coupon removes shipping only', () {
    final welcome = benefits.coupons.firstWhere((c) => c.id == 'WELCOME10');
    expect(benefits.eligible(welcome, 49), isFalse);
    expect(benefits.quote(49, welcome).discount, 0);
    expect(benefits.quote(110, welcome).discount, 10);
    expect(benefits.quote(110, welcome).total, 107);
    final ship = benefits.coupons.firstWhere((c) => c.id == 'SHIPNEW');
    expect(benefits.quote(110, ship).total, 112);
    date = date.add(const Duration(days: 31));
    expect(benefits.eligible(welcome, 110), isFalse);
  });

  test('bank purchase deducts once, consumes coupon and retries the same receipt', () async {
    final coupon = benefits.coupons.firstWhere((c) => c.id == 'WELCOME10');
    var writes = 0;
    final result = await benefits.purchase(orderId: 'order-1', subtotal: 110, bank: true,
        coupon: coupon, saveOrder: (_) async { writes++; });
    expect(result.total, 107);
    expect(benefits.balanceVnd, 10000000 - 2761884);
    expect(benefits.used, contains('WELCOME10'));
    expect(benefits.ledger.length, 1);
    final retry = await benefits.purchase(orderId: 'order-1', subtotal: 110, bank: true,
        coupon: coupon, saveOrder: (_) async { writes++; });
    expect(writes, 1);
    expect(retry.total, result.total);
    expect(benefits.ledger.length, 1);
  });

  test('cash on delivery consumes coupon without debiting demo wallet', () async {
    await benefits.purchase(orderId: 'cod-1', subtotal: 110, bank: false,
        coupon: benefits.coupons.first, saveOrder: (_) async {});
    expect(benefits.balanceVnd, 10000000);
    expect(benefits.ledger, isEmpty);
    expect(benefits.used, contains('WELCOME10'));
  });

  test('failed order write changes neither balance nor coupon use', () async {
    await expectLater(benefits.purchase(orderId: 'failed', subtotal: 110, bank: true,
        coupon: benefits.coupons.first, saveOrder: (_) async { throw Exception('offline'); }), throwsException);
    expect(benefits.balanceVnd, 10000000);
    expect(benefits.used, isEmpty);
    expect(benefits.ledger, isEmpty);
    expect(benefits.busy.value, isFalse);
  });

  test('insufficient funds and used coupons never write an order', () async {
    var writes = 0;
    await expectLater(benefits.purchase(orderId: 'expensive', subtotal: 10000, bank: true,
        saveOrder: (_) async { writes++; }), throwsStateError);
    expect(writes, 0);
    final coupon = benefits.coupons.first;
    await benefits.purchase(orderId: 'first', subtotal: 110, bank: false,
        coupon: coupon, saveOrder: (_) async {});
    await expectLater(benefits.purchase(orderId: 'reuse', subtotal: 110, bank: false,
        coupon: coupon, saveOrder: (_) async { writes++; }), throwsStateError);
    expect(writes, 0);
  });

  test('concurrent submission is blocked until the first order finishes', () async {
    final pending = Completer<void>();
    final first = benefits.purchase(orderId: 'a', subtotal: 110, bank: true,
        saveOrder: (_) => pending.future);
    await expectLater(benefits.purchase(orderId: 'b', subtotal: 110, bank: true,
        saveOrder: (_) async {}), throwsStateError);
    pending.complete();
    await first;
    expect(benefits.ledger.length, 1);
  });

  test('demo top-up and cancellation refund persist and refund only once', () async {
    await benefits.topUp();
    expect(benefits.balanceVnd, 20000000);
    await benefits.purchase(orderId: 'refundable', subtotal: 110, bank: true, saveOrder: (_) async {});
    await benefits.refund('refundable');
    expect(benefits.balanceVnd, 20000000);
    await benefits.refund('refundable');
    expect(benefits.balanceVnd, 20000000);
    final restored = CustomerBenefits(read: () => saved, write: (data) async { saved = data; }, now: () => date);
    await restored.initialize();
    expect(restored.balanceVnd, 20000000);
    expect(restored.ledger.length, 3);
  });
}
