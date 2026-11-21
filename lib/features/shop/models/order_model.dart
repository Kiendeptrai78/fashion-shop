import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/features/personalization/models/address_model.dart';
import 'package:fashion_business_app/features/shop/models/cart_item_model.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';

class OrderModel {
  final String id;
  final String userId;
  OrderStatus status;
  final double totalAmount;
  final double discountAmount;
  final String couponCode;
  final DateTime orderDate;
  final String paymentMethod;
  final AddressModel? address;
  final DateTime deliveryDate;
   DateTime? searchDate;
  final List<CartItemModel> items;

  OrderModel(
      {required this.id,
      this.userId = '',
      required this.status,
      required this.totalAmount,
      this.discountAmount = 0, this.couponCode = '',
      required this.orderDate,
      this.paymentMethod = 'Paypal',
      this.address,
      required this.deliveryDate,
      required this.items,  this.searchDate});

  String get formattedOrderDate => THelperFunctions.getFormattedDate(orderDate);

  String get formattedDeliveryDate => deliveryDate != null
      ? THelperFunctions.getFormattedDate(deliveryDate!)
      : '';

  String get orderStatusText => switch (status) {
        OrderStatus.pending => 'Pending',
        OrderStatus.processing => 'Processing',
        OrderStatus.shipped => 'Shipping',
        OrderStatus.received => 'Received',
        OrderStatus.cancelled => 'Cancelled',
      };

  /// Human-friendly product summary for notifications and order previews
  /// (e.g. "Air Force 1" or "Air Force 1 và 2 sản phẩm khác").
  String itemsSummary({bool english = false}) {
    final titles = items
        .map((e) => e.title.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (titles.isEmpty) return english ? 'items' : 'sản phẩm';
    if (titles.length == 1) return titles.first;
    final rest = titles.length - 1;
    return english
        ? '${titles.first} and $rest more ${rest == 1 ? 'item' : 'items'}'
        : '${titles.first} và $rest sản phẩm khác';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'status': status.toString(),
      'totalAmount': totalAmount,
      'discountAmount': discountAmount, 'couponCode': couponCode,
      'orderDate': orderDate,
      'paymentMethod': paymentMethod,
      'address': address?.toJson(),
      'deliveryDate': deliveryDate,
      'searchDate': searchDate,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  factory OrderModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    final rawStatus = (data['status'] ?? '').toString();
    final parsedStatus = OrderStatus.values.firstWhere(
      (element) => element.toString() == rawStatus || element.name == rawStatus,
      orElse: () => OrderStatus.pending,
    );
    final parsedOrderDate =
        (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final parsedDeliveryDate = (data['deliveryDate'] as Timestamp?)?.toDate() ??
        parsedOrderDate.add(const Duration(days: 3));

    return OrderModel(
        id: (data['id'] as String?) ?? snapshot.id,
        userId: (data['userId'] as String?) ??
            snapshot.reference.parent.parent?.id ??
            '',
        status: parsedStatus,
        totalAmount: (data['totalAmount'] as num? ?? 0).toDouble(),
        discountAmount: (data['discountAmount'] as num? ?? 0).toDouble(),
        couponCode: data['couponCode'] as String? ?? '',
        orderDate: parsedOrderDate,
        paymentMethod: (data['paymentMethod'] as String?) ?? 'Cash on delivery',
        address: data['address'] == null
            ? null
            : AddressModel.fromMap(
                Map<String, dynamic>.from(data['address'] as Map)),
        deliveryDate: parsedDeliveryDate,
        searchDate: (data['searchDate'] as Timestamp?)?.toDate(),
        items: (data['items'] as List<dynamic>? ?? const [])
            .map((e) => CartItemModel.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList());
  }

  factory OrderModel.fromQuerySnapshot(DocumentSnapshot<Object?> document) {
    final data = document.data() as Map<String, dynamic>;
    return OrderModel(
        id: document.id,
        status: data['Status'] ?? '',
        totalAmount: double.parse((data['TotalAmount'] ?? 0.0).toString()),
        orderDate: (data['OrderDate'] as Timestamp).toDate(),
        items: (data['Items'] as List<dynamic>)
            .map((e) => CartItemModel.fromJson(e))
            .toList(), deliveryDate:  (data['OrderDate'] as Timestamp).toDate(), searchDate: (data['OrderDate'] as Timestamp).toDate());
  }

  @override
  String toString() {
    return id;
  }
}
