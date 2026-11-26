import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fashion_business_app/features/personalization/services/loyalty_coins.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/features/shop/models/cart_item_model.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fashion_business_app/data/repositories/reviews/review_repository.dart';

void main() {
  late FakeFirebaseFirestore db;
  late LoyaltyCoins coins;
  setUp(() async {
    db = FakeFirebaseFirestore();
    coins = LoyaltyCoins(db: db, userId: 'customer');
    await db.doc('Users/customer/Orders/order-1').set({
      'id': 'order-1', 'status': 'OrderStatus.received',
      'items': [{'productId': 'shoe-a'}, {'productId': 'shoe-b'}],
    });
  });
  Future<int> review(String id, {String product = 'shoe-a', String? order = 'order-1'}) =>
      coins.saveReview(productId: product, reviewId: id, data: {'text': 'Rất vừa chân'},
        orderDocumentId: order);
  Future<int> balance() async => ((await db.doc('Users/customer/Wallet/coins').get())
      .data()?['balance'] as num? ?? 0).toInt();

  test('first purchase review earns 1000 once and a repeat is rejected', () async {
    expect(await review('first'), 1000);
    await expectLater(review('additional'), throwsStateError);
    expect(await balance(), 1000);
    expect((await db.doc('Users/customer/Orders/order-1').get()).data()!['reviewedProductIds'], ['shoe-a']);
    expect((await db.collection('Products/shoe-a/Reviews').get()).size, 1);
    expect(await review('second-pair', product: 'shoe-b'), 1000);
    expect(await balance(), 2000);
  });

  test('the same product in another delivered order can earn its own reward', () async {
    await review('first');
    await db.doc('Users/customer/Orders/order-2').set({
      'status': 'received', 'items': [{'productId': 'shoe-a'}],
    });
    expect(await review('new-purchase', order: 'order-2'), 1000);
    expect(await balance(), 2000);
  });

  test('eligibility rejects reviewed purchases including legacy reviews and reward markers', () async {
    final repository = ReviewRepository(db: db, userId: 'customer');
    expect((await repository.eligibility('shoe-a', orderId: 'order-1')).allowed, isTrue);
    await review('first');
    expect((await repository.eligibility('shoe-a', orderId: 'order-1')).allowed, isFalse);
    expect((await repository.eligibility('not-bought')).allowed, isFalse);
    await db.doc('Products/shoe-b/Reviews/legacy').set({'userId': 'customer', 'purchaseOrderId': 'order-1'});
    expect((await repository.eligibility('shoe-b', orderId: 'order-1')).allowed, isFalse);
    await db.doc('Users/customer/Orders/other').set({
      'status': 'OrderStatus.received', 'items': [{'productId': 'shoe-a'}],
    });
    expect((await repository.eligibility('shoe-a')).orderDocumentId, 'other');
    await db.doc('Users/customer/Orders/other/ReviewRewards/shoe-a').set({'amount': 1000});
    expect((await repository.eligibility('shoe-a')).allowed, isFalse);
  });

  test('unverified reviews earn nothing; non-delivered and unrelated orders reject rewards', () async {
    await expectLater(review('unverified', order: null), throwsStateError);
    await expectLater(review('wrong-product', product: 'other'), throwsStateError);
    await db.doc('Users/customer/Orders/order-1').update({'status': 'OrderStatus.pending'});
    await expectLater(review('not-delivered'), throwsStateError);
    expect(await balance(), 0);
    expect((await db.doc('Products/shoe-a/Reviews/not-delivered').get()).exists, isFalse);
  });

  test('legacy reviews hide the reminder without retroactive or duplicate rewards', () async {
    await db.doc('Products/shoe-a/Reviews/old').set({
      'userId': 'customer', 'purchaseOrderId': 'order-1',
    });
    await coins.backfillReviewedProducts((await db.collection('Users/customer/Orders').get()).docs);
    final order = (await db.doc('Users/customer/Orders/order-1').get()).data()!;
    expect(order['reviewedProductIds'], ['shoe-a']);
    await expectLater(review('extra'), throwsStateError);
    expect(await balance(), 0);
  });

  test('coins debit with order creation and a retry does not debit again', () async {
    await review('earn');
    await coins.placeOrder(orderId: 'checkout', data: {'totalAmount': 25.25}, coins: 1000,
      notification: {'kind': 'order'});
    expect(await balance(), 0);
    await coins.placeOrder(orderId: 'checkout', data: {'totalAmount': 25.25}, coins: 1000,
      notification: {'kind': 'order'});
    expect(await balance(), 0);
    expect((await db.doc('Users/customer/Orders/checkout').get()).data()!['coinsUsed'], 1000);
    expect((await db.doc('Users/customer/Notifications/order-checkout-pending').get()).exists, isTrue);
  });

  test('insufficient balance writes neither an order nor a notification', () async {
    await review('earn');
    await expectLater(coins.placeOrder(orderId: 'too-many', data: {'totalAmount': 10},
      coins: 1001, notification: {}), throwsStateError);
    expect(await balance(), 1000);
    expect((await db.doc('Users/customer/Orders/too-many').get()).exists, isFalse);
    expect((await db.doc('Users/customer/Notifications/order-too-many-pending').get()).exists, isFalse);
  });

  test('cancelling a coin-paid order refunds coins only once', () async {
    await review('earn');
    await coins.placeOrder(orderId: 'cancel-me', data: {'totalAmount': 10}, coins: 1000, notification: {});
    final ref = db.doc('Users/customer/Orders/cancel-me');
    for (var attempt = 0; attempt < 2; attempt++) {
      await db.runTransaction((tx) async {
        final data = (await tx.get(ref)).data()!;
        await LoyaltyCoins.refundInTransaction(tx, ref, data);
        tx.update(ref, {'status': 'OrderStatus.cancelled'});
      });
    }
    expect(await balance(), 1000);
  });

  test('coin conversion is exactly 1 VND, stacks after coupons and caps at total', () async {
    final benefits = CustomerBenefits(read: () => null, write: (_) async {}, now: () => DateTime(2026, 11, 25));
    await benefits.initialize();
    final coupon = benefits.coupons.firstWhere((c) => c.id == 'WELCOME10');
    final base = benefits.quoteDual(110, productCoupon: coupon);
    final reduced = benefits.quoteDual(110, productCoupon: coupon, coins: 1000);
    expect(base.totalVnd - reduced.totalVnd, 1000);
    expect(reduced.discount, base.discount);
    expect(benefits.quoteDual(110, coins: 999999999).totalVnd, 0);
    expect(LoyaltyCoins.redeemable(9000, 1000 / 25812), 1000);
    expect(LoyaltyCoins.redeemable(0, 100), 0);
    final saved = await benefits.purchase(orderId: 'coin-receipt', subtotal: 110,
      bank: false, coins: 1000, saveOrder: (_) async {});
    final retried = await benefits.purchase(orderId: 'coin-receipt', subtotal: 110,
      bank: false, saveOrder: (_) async => fail('Receipt retry must not save again'));
    expect(saved.totalVnd, retried.totalVnd);
    expect(retried.coinsUsed, 1000);
  });

  test('only fully reviewed orders hide the list action', () {
    OrderModel order(List<String> reviewed) => OrderModel(id: 'order', status: OrderStatus.received,
      totalAmount: 10, orderDate: DateTime(2026), deliveryDate: DateTime(2026),
      items: [CartItemModel(productId: 'a', title: 'A', quantity: 1), CartItemModel(productId: 'b', title: 'B', quantity: 1)],
      reviewedProductIds: reviewed);
    expect(order([]).hasUnreviewedProducts, isTrue);
    expect(order(['a']).hasUnreviewedProducts, isTrue);
    expect(order(['a', 'b']).hasUnreviewedProducts, isFalse);
  });
}
