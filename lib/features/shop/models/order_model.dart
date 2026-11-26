import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/features/personalization/models/address_model.dart';
import 'package:fashion_business_app/features/shop/models/cart_item_model.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class OrderModel {
  final String id;
  final String userId;
  OrderStatus status;
  final double totalAmount;
  final double discountAmount;
  final String couponCode;
  final List<String> reviewedProductIds;
  final int coinsUsed;
  bool get hasUnreviewedProducts => items.any((item) => !reviewedProductIds.contains(item.productId));
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
      this.reviewedProductIds = const [], this.coinsUsed = 0,
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

  String orderStatusLabel({bool english = false}) => switch (status) {
        OrderStatus.pending =>
          english ? 'Awaiting confirmation' : 'Chờ xác nhận',
        OrderStatus.processing =>
          english ? 'Packing & preparing' : 'Đang đóng gói',
        OrderStatus.shipped =>
          english ? 'Out for delivery' : 'Đang vận chuyển',
        OrderStatus.received =>
          english ? 'Delivered' : 'Giao thành công',
        OrderStatus.cancelled =>
          english ? 'Cancelled' : 'Đã hủy đơn',
      };

  String orderStatusSubtitle({bool english = false}) => switch (status) {
        OrderStatus.pending => english
            ? 'Your order has been placed and is awaiting VELORA confirmation.'
            : 'Đơn hàng đã được tiếp nhận, đang chờ cửa hàng VELORA xác nhận.',
        OrderStatus.processing => english
            ? 'VELORA confirmed your order and is carefully packing your shoes.'
            : 'VELORA đã xác nhận đơn và đang kiểm tra QC, đóng gói hộp giày.',
        OrderStatus.shipped => english
            ? 'Handed over to express courier and on the way to your address.'
            : 'Đã bàn giao cho đơn vị vận chuyển nhanh, đang trên đường giao tới bạn.',
        OrderStatus.received => english
            ? 'Delivered successfully. Share your photo/video review anytime!'
            : 'Giao hàng thành công. Bạn có thể chụp ảnh/quay video đánh giá đôi giày!',
        OrderStatus.cancelled => english
            ? 'This order was cancelled.'
            : 'Đơn hàng đã chuyển sang trạng thái hủy.',
      };

  /// Customer-facing title without exposing raw database IDs.
  String customerOrderTitle({bool english = false}) {
    final summary = itemsSummary(english: english);
    return english ? 'Order: $summary' : 'Đơn hàng $summary của bạn';
  }

  /// Distinct, high-contrast semantic color for each order status (never brand green).
  static Color colorForStatus(OrderStatus s) => switch (s) {
        OrderStatus.pending => const Color(0xFFD97706), // Amber / Cam
        OrderStatus.processing => const Color(0xFF7C3AED), // Violet / Tím
        OrderStatus.shipped => const Color(0xFF0284C7), // Sky Blue / Xanh dương
        OrderStatus.received => const Color(0xFF16A34A), // Emerald / Xanh lá tươi
        OrderStatus.cancelled => const Color(0xFFDC2626), // Red / Đỏ
      };

  static Color bgColorForStatus(OrderStatus s) => switch (s) {
        OrderStatus.pending => const Color(0xFFFEF3C7),
        OrderStatus.processing => const Color(0xFFEDE9FE),
        OrderStatus.shipped => const Color(0xFFE0F2FE),
        OrderStatus.received => const Color(0xFFDCFCE7),
        OrderStatus.cancelled => const Color(0xFFFFE4E6),
      };

  static Color borderColorForStatus(OrderStatus s) => switch (s) {
        OrderStatus.pending => const Color(0xFFF59E0B),
        OrderStatus.processing => const Color(0xFFA78BFA),
        OrderStatus.shipped => const Color(0xFF38BDF8),
        OrderStatus.received => const Color(0xFF4ADE80),
        OrderStatus.cancelled => const Color(0xFFFB7185),
      };

  static IconData iconForStatus(OrderStatus s) => switch (s) {
        OrderStatus.pending => Iconsax.clock,
        OrderStatus.processing => Iconsax.box_time,
        OrderStatus.shipped => Iconsax.truck_fast,
        OrderStatus.received => Iconsax.tick_circle,
        OrderStatus.cancelled => Iconsax.close_circle,
      };

  Color get statusColor => colorForStatus(status);
  Color get statusBgColor => bgColorForStatus(status);
  Color get statusBorderColor => borderColorForStatus(status);
  IconData get statusIcon => iconForStatus(status);

  /// Human-friendly product summary for notifications and order previews
  /// (e.g. "VELORA AeroPulse R1" or "VELORA AeroPulse R1 và 2 sản phẩm khác").
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
      'reviewedProductIds': reviewedProductIds, 'coinsUsed': coinsUsed,
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
        reviewedProductIds: List<String>.from(data['reviewedProductIds'] as List? ?? []),
        coinsUsed: (data['coinsUsed'] as num? ?? 0).toInt(),
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
