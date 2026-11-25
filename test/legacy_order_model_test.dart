import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/features/personalization/models/address_model.dart';

class _Snapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this.record);
  final Map<String, dynamic> record;
  @override
  String get id => 'document-id';
  @override
  Map<String, dynamic> data() => record;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('old orders accept integer totals and missing optional metadata', () {
    final order = OrderModel.fromSnapshot(_Snapshot({
      'id': 'old-order', 'userId': 'user', 'status': 'OrderStatus.pending',
      'totalAmount': 117, 'orderDate': Timestamp.fromDate(DateTime(2024, 4, 23)),
      'deliveryDate': Timestamp.fromDate(DateTime(2024, 4, 26)),
      'paymentMethod': 'Cash on delivery', 'items': <dynamic>[],
    }));
    expect(order.totalAmount, 117.0);
    expect(order.searchDate, isNull);
    expect(order.address, isNull);
    expect(order.discountAmount, 0);
    expect(order.couponCode, isEmpty);
  });

  test('saved discount and old address without timestamp remain readable', () {
    final address = AddressModel.fromMap({'Id': 'a', 'Name': 'Recipient',
      'PhoneNumber': '0901234567', 'Street': '12 Street', 'City': 'Hanoi',
      'State': '', 'Country': 'Vietnam'});
    expect(address.dateTime, isNull);
    expect(address.toString(), '12 Street, Hanoi, Vietnam');
    final order = OrderModel.fromSnapshot(_Snapshot({
      'id': 'discount-order', 'userId': 'user', 'status': 'OrderStatus.pending',
      'totalAmount': 107.0, 'discountAmount': 10, 'couponCode': 'WELCOME10',
      'orderDate': Timestamp.fromDate(DateTime(2026, 11, 20)),
      'deliveryDate': Timestamp.fromDate(DateTime(2026, 11, 23)),
      'paymentMethod': 'Demo bank', 'items': <dynamic>[],
    }));
    expect(order.discountAmount, 10.0);
    expect(order.couponCode, 'WELCOME10');
    expect(order.toJson()['discountAmount'], 10.0);
  });
}
