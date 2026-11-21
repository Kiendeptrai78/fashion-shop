import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/features/authentication/models/user_model.dart';
import 'package:fashion_business_app/features/shop/models/banner_model.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/features/shop/models/product_review_model.dart';

enum AdminSection {
  dashboard,
  orders,
  products,
  brands,
  categories,
  banners,
  users,
  reviews,
  notifications,
}

class AdminOrderRecord {
  const AdminOrderRecord({
    required this.docId,
    required this.userId,
    required this.order,
    this.customer,
  });

  final String docId;
  final String userId;
  final OrderModel order;
  final UserModel? customer;

  String get customerName {
    final name = customer?.fullName.trim() ?? '';
    if (name.isNotEmpty) return name;
    final addrName = order.address?.name.trim() ?? '';
    if (addrName.isNotEmpty) return addrName;
    return customer?.email ?? userId;
  }

  String get customerEmail => customer?.email ?? '';
}

class AdminBannerRecord {
  const AdminBannerRecord({
    required this.docId,
    required this.banner,
  });

  final String docId;
  final BannerModel banner;
}

class AdminReviewRecord {
  const AdminReviewRecord({
    required this.productId,
    required this.productTitle,
    required this.productThumbnail,
    required this.review,
    this.purchaseOrderId = '',
  });

  final String productId;
  final String productTitle;
  final String productThumbnail;
  final ProductReviewEntry review;
  final String purchaseOrderId;
}

class AdminNotificationCampaign {
  const AdminNotificationCampaign({
    required this.id,
    required this.titleVi,
    required this.bodyVi,
    required this.titleEn,
    required this.bodyEn,
    required this.kind,
    required this.targetId,
    required this.audienceLabel,
    required this.recipientCount,
    this.createdAt,
  });

  final String id;
  final String titleVi;
  final String bodyVi;
  final String titleEn;
  final String bodyEn;
  final String kind;
  final String targetId;
  final String audienceLabel;
  final int recipientCount;
  final DateTime? createdAt;

  factory AdminNotificationCampaign.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AdminNotificationCampaign(
      id: doc.id,
      titleVi: (data['titleVi'] ?? '') as String,
      bodyVi: (data['bodyVi'] ?? '') as String,
      titleEn: (data['titleEn'] ?? '') as String,
      bodyEn: (data['bodyEn'] ?? '') as String,
      kind: (data['kind'] ?? 'promo') as String,
      targetId: (data['targetId'] ?? '') as String,
      audienceLabel: (data['audienceLabel'] ?? 'Tất cả khách hàng') as String,
      recipientCount: (data['recipientCount'] as num? ?? 0).toInt(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
