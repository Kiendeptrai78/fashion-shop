import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/admin/web/data/admin_web_models.dart';
import 'package:fashion_business_app/data/services/image_storage_service.dart';
import 'package:fashion_business_app/features/authentication/models/user_model.dart';
import 'package:fashion_business_app/features/personalization/models/address_model.dart';
import 'package:fashion_business_app/features/shop/models/banner_model.dart';
import 'package:fashion_business_app/features/shop/models/brand_model.dart';
import 'package:fashion_business_app/features/shop/models/catalog_search.dart';
import 'package:fashion_business_app/features/shop/models/category_model.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/models/product_review_model.dart';
import 'package:fashion_business_app/utils/constants/admin_config.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';

class AdminWebRepository {
  AdminWebRepository({FirebaseFirestore? db, ImageStorageService? storage})
      : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ??
            ImageStorageService(
              cloudName: const String.fromEnvironment(
                'CLOUDINARY_CLOUD_NAME',
                defaultValue: 'lbbgn51d',
              ),
              uploadPreset: const String.fromEnvironment(
                'CLOUDINARY_UPLOAD_PRESET',
                defaultValue: 'fashion_shop',
              ),
            );

  final FirebaseFirestore _db;
  final ImageStorageService _storage;

  // ---------------------------------------------------------------------------
  // Image Upload (Cloudinary)
  // ---------------------------------------------------------------------------
  Future<String> uploadImage(Uint8List bytes, String filename, String folder) {
    return _storage.uploadImageData(folder, bytes, filename);
  }

  // ---------------------------------------------------------------------------
  // Products
  // ---------------------------------------------------------------------------
  Future<List<ProductModel>> fetchProducts() async {
    final snapshot = await _db.collection('Products').get();
    final items = snapshot.docs.map(ProductModel.fromSnapshot).toList();
    items.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return items;
  }

  Future<String> saveProduct(
    ProductModel product, {
    bool isNew = false,
    bool sendNotification = false,
  }) async {
    final effectiveCatalogId =
        product.catalogId.isEmpty ? sneakerCatalogId : product.catalogId;
    final prepared = ProductModel(
      id: product.id,
      title: product.title.trim(),
      stock: product.stock,
      price: product.price,
      salePrice: product.salePrice,
      thumbnail: product.thumbnail.trim(),
      images: product.images,
      description: product.description?.trim() ?? '',
      productType: product.productType,
      isFeatured: product.isFeatured,
      brand: product.brand,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      catalogId: effectiveCatalogId,
      productAttributes: product.productAttributes,
      productVariations: product.productVariations,
    );

    final payload = Map<String, dynamic>.from(prepared.toJson());
    // Always include BrowseKeys so the customer storefront search/filter sees it immediately.
    payload['BrowseKeys'] = catalogBrowseKeys(
      title: prepared.title,
      brandName: prepared.brand?.name ?? '',
      categoryName: prepared.categoryName,
      brandId: prepared.brand?.id ?? '',
      categoryId: prepared.categoryId,
    );

    String docId = prepared.id;
    if (isNew || docId.isEmpty) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      if (sendNotification) payload['notificationPending'] = true;
      final ref = await _db.collection('Products').add(payload);
      docId = ref.id;
    } else {
      payload['updatedAt'] = FieldValue.serverTimestamp();
      await _db.collection('Products').doc(docId).set(payload, SetOptions(merge: true));
    }

    // Keep ProductCategory & BrandCategory relations synced for Store screen
    if (prepared.categoryId.isNotEmpty) {
      await _db
          .collection('ProductCategory')
          .doc('$docId-${prepared.categoryId}')
          .set({'productId': docId, 'categoryId': prepared.categoryId});
      if (prepared.brand != null && prepared.brand!.id.isNotEmpty) {
        await _db
            .collection('BrandCategory')
            .doc('${prepared.brand!.id}-${prepared.categoryId}')
            .set({
          'brandId': prepared.brand!.id,
          'categoryId': prepared.categoryId,
        });
      }
    }

    return docId;
  }

  Future<void> deleteProduct(String productId) async {
    await _db.collection('Products').doc(productId).delete();
  }

  // ---------------------------------------------------------------------------
  // Brands
  // ---------------------------------------------------------------------------
  Future<List<BrandModel>> fetchBrands() async {
    final snapshot = await _db.collection('Brands').get();
    final list = snapshot.docs.map(BrandModel.fromSnapshot).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Future<void> saveBrand(BrandModel brand, {bool isNew = false}) async {
    if (isNew || brand.id.isEmpty) {
      final ref = _db.collection('Brands').doc();
      final id = brand.id.isNotEmpty ? brand.id : ref.id;
      await _db.collection('Brands').doc(id).set({
        'Id': id,
        'Name': brand.name.trim(),
        'Image': brand.image.trim(),
        'ProductsCount': brand.productsCount ?? 0,
        'IsFeatured': brand.isFeatured ?? false,
        'CatalogId': sneakerCatalogId,
      });
    } else {
      await _db.collection('Brands').doc(brand.id).set({
        'Id': brand.id,
        'Name': brand.name.trim(),
        'Image': brand.image.trim(),
        'ProductsCount': brand.productsCount ?? 0,
        'IsFeatured': brand.isFeatured ?? false,
        'CatalogId': sneakerCatalogId,
      }, SetOptions(merge: true));
    }
  }

  Future<void> deleteBrand(String brandId) async {
    await _db.collection('Brands').doc(brandId).delete();
  }

  // ---------------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------------
  Future<List<CategoryModel>> fetchCategories() async {
    final snapshot = await _db.collection('Categories').get();
    final list = snapshot.docs.map(CategoryModel.fromSnapShot).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Future<void> saveCategory(CategoryModel category, {bool isNew = false}) async {
    final data = {
      'Name': category.name.trim(),
      'Image': category.image.trim(),
      'ParentId': category.parentId.trim(),
      'IsFeatured': category.isFeatured,
      'CatalogId': sneakerCatalogId,
    };
    if (isNew || category.id.isEmpty) {
      await _db.collection('Categories').add(data);
    } else {
      await _db.collection('Categories').doc(category.id).set(data, SetOptions(merge: true));
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    await _db.collection('Categories').doc(categoryId).delete();
  }

  // ---------------------------------------------------------------------------
  // Banners / Campaigns
  // ---------------------------------------------------------------------------
  Future<List<AdminBannerRecord>> fetchBanners() async {
    final snapshot = await _db.collection('Banners').get();
    final list = snapshot.docs
        .map((doc) => AdminBannerRecord(
              docId: doc.id,
              banner: BannerModel.fromSnapShot(doc),
            ))
        .toList();
    list.sort((a, b) => a.banner.sortOrder.compareTo(b.banner.sortOrder));
    return list;
  }

  Future<void> saveBanner(BannerModel banner, {String? docId}) async {
    final data = banner.toJson();
    if (docId == null || docId.isEmpty) {
      await _db.collection('Banners').add(data);
    } else {
      // Remove optional fields explicitly if cleared
      await _db.collection('Banners').doc(docId).set({
        ...data,
        if (banner.categoryId == null || banner.categoryId!.isEmpty)
          'CategoryId': FieldValue.delete(),
        if (banner.brandId == null || banner.brandId!.isEmpty)
          'BrandId': FieldValue.delete(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> toggleBannerActive(String docId, bool active) async {
    await _db.collection('Banners').doc(docId).update({'Active': active});
  }

  Future<void> deleteBanner(String docId) async {
    await _db.collection('Banners').doc(docId).delete();
  }

  // ---------------------------------------------------------------------------
  // Users & Addresses
  // ---------------------------------------------------------------------------
  Future<List<UserModel>> fetchUsers() async {
    final snapshot = await _db.collection('Users').get();
    final list = snapshot.docs.map((doc) {
      final model = UserModel.fromSnapshot(doc);
      // Enforce consistent role display based on AdminConfig policy.
      model.role = AdminConfig.roleForEmail(model.email);
      return model;
    }).toList();
    list.sort((a, b) {
      if (a.role == 'Admin' && b.role != 'Admin') return -1;
      if (b.role == 'Admin' && a.role != 'Admin') return 1;
      return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
    });
    return list;
  }

  Future<List<AddressModel>> fetchUserAddresses(String userId) async {
    final snapshot = await _db
        .collection('Users')
        .doc(userId)
        .collection('Addresses')
        .get();
    return snapshot.docs.map(AddressModel.fromDocumentSnapshot).toList();
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _db.collection('Users').doc(user.id).update({
      'FirstName': user.firstName.trim(),
      'LastName': user.lastName.trim(),
      'PhoneNumber': user.phoneNumber.trim(),
      'Role': AdminConfig.roleForEmail(user.email),
    });
  }

  Future<void> deleteUserRecord(String userId) async {
    await _db.collection('Users').doc(userId).delete();
  }

  // ---------------------------------------------------------------------------
  // Orders
  // ---------------------------------------------------------------------------
  Future<List<AdminOrderRecord>> fetchAllOrders(List<UserModel> users) async {
    final userMap = {for (final u in users) u.id: u};
    final records = <AdminOrderRecord>[];

    await Future.wait(users.map((user) async {
      try {
        final snap = await _db
            .collection('Users')
            .doc(user.id)
            .collection('Orders')
            .get();
        for (final doc in snap.docs) {
          try {
            records.add(AdminOrderRecord(
              docId: doc.id,
              userId: user.id,
              order: OrderModel.fromSnapshot(doc),
              customer: userMap[user.id],
            ));
          } catch (_) {
            // Skip malformed legacy documents gracefully
          }
        }
      } catch (_) {}
    }));

    records.sort((a, b) => b.order.orderDate.compareTo(a.order.orderDate));
    return records;
  }

  Future<void> updateOrderStatus(
    AdminOrderRecord record,
    OrderStatus nextStatus,
  ) async {
    final orderRef = _db
        .collection('Users')
        .doc(record.userId)
        .collection('Orders')
        .doc(record.docId);

    final updates = <String, dynamic>{
      'status': nextStatus.toString(),
      'notificationPending': true,
      if (nextStatus == OrderStatus.received) 'searchDate': DateTime.now(),
    };
    await orderRef.update(updates);

    // Immediately create an in-app notification so the customer sees it in NotificationsScreen
    final statusTitles = _orderStatusNotificationCopy(nextStatus, record.order.id);
    final notifId = 'order-${record.order.id}-${nextStatus.name}';
    await _db
        .collection('Users')
        .doc(record.userId)
        .collection('Notifications')
        .doc(notifId)
        .set({
      'id': notifId,
      'kind': 'order',
      'targetId': record.order.id,
      'titleVi': statusTitles.$1,
      'titleEn': statusTitles.$2,
      'bodyVi': statusTitles.$3,
      'bodyEn': statusTitles.$4,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateOrderDeliveryDate(
    AdminOrderRecord record,
    DateTime deliveryDate,
  ) async {
    await _db
        .collection('Users')
        .doc(record.userId)
        .collection('Orders')
        .doc(record.docId)
        .update({'deliveryDate': deliveryDate});
  }

  Future<void> deleteOrder(AdminOrderRecord record) async {
    await _db
        .collection('Users')
        .doc(record.userId)
        .collection('Orders')
        .doc(record.docId)
        .delete();
  }

  (String, String, String, String) _orderStatusNotificationCopy(
      OrderStatus status, String orderId) {
    switch (status) {
      case OrderStatus.pending:
        return (
          'Đã nhận đơn hàng #$orderId',
          'Order #$orderId received',
          'Đơn hàng của bạn đã được ghi nhận và đang chờ xác nhận.',
          'Your order has been received and is awaiting confirmation.',
        );
      case OrderStatus.processing:
        return (
          'Đơn hàng #$orderId đang được chuẩn bị',
          'Preparing order #$orderId',
          'Cửa hàng đang đóng gói sản phẩm cho bạn.',
          'We are preparing your items for shipment.',
        );
      case OrderStatus.shipped:
        return (
          'Đơn hàng #$orderId đang giao',
          'Order #$orderId is on the way',
          'Đơn hàng đã được bàn giao cho đơn vị vận chuyển.',
          'Your order has been shipped and is on its way.',
        );
      case OrderStatus.received:
        return (
          'Đơn hàng #$orderId đã hoàn tất',
          'Order #$orderId completed',
          'Cảm ơn bạn đã mua sắm! Bạn có thể đánh giá sản phẩm ngay bây giờ.',
          'Thank you for shopping! You can now review your items.',
        );
      case OrderStatus.cancelled:
        return (
          'Đơn hàng #$orderId đã hủy',
          'Order #$orderId cancelled',
          'Đơn hàng của bạn đã được chuyển sang trạng thái hủy.',
          'Your order has been cancelled.',
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Reviews (Products/{productId}/Reviews/{uid})
  // ---------------------------------------------------------------------------
  Future<List<AdminReviewRecord>> fetchAllReviews(
      List<ProductModel> products) async {
    final results = <AdminReviewRecord>[];
    await Future.wait(products.map((product) async {
      try {
        final snap = await _db
            .collection('Products')
            .doc(product.id)
            .collection('Reviews')
            .get();
        for (final doc in snap.docs) {
          final data = doc.data();
          final rating = (data['rating'] as num? ?? 0).toInt();
          if (rating < 1 || rating > 5) continue;
          results.add(AdminReviewRecord(
            productId: product.id,
            productTitle: product.title,
            productThumbnail: product.thumbnail,
            purchaseOrderId: (data['purchaseOrderId'] ?? '') as String,
            review: ProductReviewEntry(
              id: doc.id,
              authorName: (data['authorName'] ?? 'Khách hàng') as String,
              rating: rating,
              text: (data['text'] ?? '') as String,
              createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
            ),
          ));
        }
      } catch (_) {}
    }));
    results.sort((a, b) {
      final ad = a.review.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.review.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return results;
  }

  Future<void> deleteReview(String productId, String reviewId) async {
    await _db
        .collection('Products')
        .doc(productId)
        .collection('Reviews')
        .doc(reviewId)
        .delete();
  }

  // ---------------------------------------------------------------------------
  // Notifications & Push Devices
  // ---------------------------------------------------------------------------
  Future<List<AdminNotificationCampaign>> fetchNotificationCampaigns() async {
    try {
      final snap = await _db
          .collection('AdminNotifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      return snap.docs.map(AdminNotificationCampaign.fromSnapshot).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> fetchEnabledPushDevicesCount(List<UserModel> users) async {
    var total = 0;
    await Future.wait(users.map((user) async {
      try {
        final snap = await _db
            .collection('Users')
            .doc(user.id)
            .collection('Devices')
            .where('enabled', isEqualTo: true)
            .get();
        total += snap.size;
      } catch (_) {}
    }));
    return total;
  }

  Future<int> sendNotificationCampaign({
    required String titleVi,
    required String bodyVi,
    required String titleEn,
    required String bodyEn,
    required String kind,
    required String targetId,
    required List<UserModel> recipients,
    required String audienceLabel,
  }) async {
    if (recipients.isEmpty) return 0;

    final campaignRef = _db.collection('AdminNotifications').doc();
    final notifId = 'admin-${campaignRef.id}';
    final safeTitleEn = titleEn.trim().isNotEmpty ? titleEn.trim() : titleVi.trim();
    final safeBodyEn = bodyEn.trim().isNotEmpty ? bodyEn.trim() : bodyVi.trim();

    // Commit in batches of 400 to stay safely within Firestore's 500-op batch limit.
    for (var start = 0; start < recipients.length; start += 400) {
      final chunk = recipients.skip(start).take(400);
      final batch = _db.batch();
      for (final user in chunk) {
        final ref = _db
            .collection('Users')
            .doc(user.id)
            .collection('Notifications')
            .doc(notifId);
        batch.set(ref, {
          'id': notifId,
          'kind': kind,
          'targetId': targetId,
          'titleVi': titleVi.trim(),
          'titleEn': safeTitleEn,
          'bodyVi': bodyVi.trim(),
          'bodyEn': safeBodyEn,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }

    await campaignRef.set({
      'titleVi': titleVi.trim(),
      'titleEn': safeTitleEn,
      'bodyVi': bodyVi.trim(),
      'bodyEn': safeBodyEn,
      'kind': kind,
      'targetId': targetId,
      'audienceLabel': audienceLabel,
      'recipientCount': recipients.length,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return recipients.length;
  }

  Future<void> deleteNotificationCampaign(String id) async {
    await _db.collection('AdminNotifications').doc(id).delete();
  }
}
