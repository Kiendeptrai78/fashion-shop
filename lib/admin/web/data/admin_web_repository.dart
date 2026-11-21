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

  Future<String> uploadVideo(Uint8List bytes, String filename, String folder) {
    return _storage.uploadVideoData(folder, bytes, filename);
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

    // Deliver notification to users who follow this product's category or asked AI for similar shoes
    if (isNew && sendNotification && prepared.stock > 0) {
      await notifyUsersForFavoriteCategoryProduct(
        productId: docId,
        productTitle: prepared.title,
        productThumbnail: prepared.thumbnail,
        brandName: prepared.brand?.name ?? '',
        categoryId: prepared.categoryId,
        categoryName: prepared.categoryName,
      );
    }

    return docId;
  }

  /// Sends an in-app + FCM push-queued notification to customers whose
  /// `FavoriteCategoryIds` OR AI `UserInterests` match this product.
  Future<int> notifyUsersForFavoriteCategoryProduct({
    required String productId,
    required String productTitle,
    String productThumbnail = '',
    String brandName = '',
    required String categoryId,
    required String categoryName,
  }) async {
    final recipientIds = <String>{};

    if (categoryId.isNotEmpty) {
      final matchingUsersSnap = await _db
          .collection('Users')
          .where('FavoriteCategoryIds', arrayContains: categoryId)
          .get();
      for (final d in matchingUsersSnap.docs) {
        if (!AdminConfig.isAdminEmail(d.data()['Email'] as String?)) {
          recipientIds.add(d.id);
        }
      }
    }

    // Also include customers whose AI Stylist interest matches category or brand
    try {
      final interestsSnap = await _db.collection('UserInterests').get();
      final normBrand = brandName.trim().toLowerCase();
      final normCat = categoryName.trim().toLowerCase();
      for (final doc in interestsSnap.docs) {
        final data = doc.data();
        if (AdminConfig.isAdminEmail(data['userEmail'] as String?)) continue;
        final uid = (data['userId'] ?? doc.id).toString();
        final catIds = (data['interestedCategoryIds'] as List?)?.map((e) => e.toString()).toSet() ?? {};
        final cats = (data['interestedCategories'] as List?)
                ?.map((e) => e.toString().toLowerCase())
                .toSet() ??
            {};
        final brands = (data['interestedBrands'] as List?)
                ?.map((e) => e.toString().toLowerCase())
                .toSet() ??
            {};
        if ((categoryId.isNotEmpty && catIds.contains(categoryId)) ||
            (normCat.isNotEmpty && cats.contains(normCat)) ||
            (normBrand.isNotEmpty && brands.contains(normBrand))) {
          recipientIds.add(uid);
        }
      }
    } catch (_) {}

    final recipients = recipientIds.toList();
    if (recipients.isEmpty) return 0;

    final notifId = 'product-$productId';
    final catLabel = categoryName.isNotEmpty ? categoryName : (brandName.isNotEmpty ? brandName : 'bạn quan tâm');
    final titleVi = 'Đôi giày mới đúng gu của bạn!';
    final bodyVi = '$productTitle vừa mở bán trong danh mục $catLabel. Xem ngay kẻo hết size!';
    final titleEn = 'A new pair matching your style!';
    final bodyEn =
        '$productTitle just arrived in ${categoryName.isNotEmpty ? categoryName : 'a collection you follow'}.';

    for (var start = 0; start < recipients.length; start += 400) {
      final chunk = recipients.skip(start).take(400);
      final batch = _db.batch();
      for (final uid in chunk) {
        final ref = _db
            .collection('Users')
            .doc(uid)
            .collection('Notifications')
            .doc(notifId);
        batch.set(ref, {
          'id': notifId,
          'kind': 'product',
          'targetId': productId,
          'categoryId': categoryId,
          if (productThumbnail.isNotEmpty) 'imageUrl': productThumbnail,
          'titleVi': titleVi,
          'titleEn': titleEn,
          'bodyVi': bodyVi,
          'bodyEn': bodyEn,
          'read': false,
          'pushPending': true,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
    }

    await _db.collection('AdminNotifications').add({
      'titleVi': titleVi,
      'titleEn': titleEn,
      'bodyVi': bodyVi,
      'bodyEn': bodyEn,
      'kind': 'product',
      'targetId': productId,
      if (productThumbnail.isNotEmpty) 'imageUrl': productThumbnail,
      'audienceLabel': 'Khách quan tâm $catLabel (${recipients.length})',
      'recipientCount': recipients.length,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return recipients.length;
  }

  Future<void> deleteProduct(String productId) async {
    await _db.collection('Products').doc(productId).delete();
  }

  /// Restock an existing product (single or variation-level) and log a StockReceipt.
  Future<int> restockProduct({
    required ProductModel product,
    required int totalAdded,
    Map<String, int> variationDeltas = const {},
    double unitCostUsd = 0,
    String supplier = '',
    String note = '',
    bool notifyBackInStock = false,
  }) async {
    final previousStock = product.stock;
    final variations = product.productVariations;
    int newStock = previousStock + totalAdded;
    final payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (variations != null && variations.isNotEmpty && variationDeltas.isNotEmpty) {
      var computedTotal = 0;
      final updatedVars = variations.map((v) {
        final add = variationDeltas[v.id] ?? 0;
        final next = (v.stock + add).clamp(0, 999999);
        computedTotal += next;
        final json = v.toJson();
        json['Stock'] = next;
        return json;
      }).toList();
      newStock = computedTotal;
      payload['ProductVariations'] = updatedVars;
    }
    payload['Stock'] = newStock;

    await _db.collection('Products').doc(product.id).set(payload, SetOptions(merge: true));

    await _db.collection('StockReceipts').add({
      'productId': product.id,
      'productTitle': product.title,
      'productThumbnail': product.thumbnail,
      'addedQuantity': totalAdded,
      'previousStock': previousStock,
      'newStock': newStock,
      'unitCostUsd': unitCostUsd,
      'supplier': supplier.trim(),
      'note': note.trim(),
      'variationDeltas': variationDeltas,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (notifyBackInStock && newStock > 0) {
      await notifyUsersForFavoriteCategoryProduct(
        productId: product.id,
        productTitle: '${product.title} đã về thêm hàng ($totalAdded đôi)',
        productThumbnail: product.thumbnail,
        brandName: product.brand?.name ?? '',
        categoryId: product.categoryId,
        categoryName: product.categoryName,
      );
    }

    return newStock;
  }

  Future<List<AdminStockReceipt>> fetchStockReceipts() async {
    try {
      final snap = await _db
          .collection('StockReceipts')
          .orderBy('createdAt', descending: true)
          .limit(60)
          .get();
      return snap.docs.map(AdminStockReceipt.fromSnapshot).toList();
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Automation Settings (Settings/AdminAutomation)
  // ---------------------------------------------------------------------------
  Future<AdminAutomationSettings> fetchAutomationSettings() async {
    try {
      final doc = await _db.collection('Settings').doc('AdminAutomation').get();
      return AdminAutomationSettings.fromMap(doc.data());
    } catch (_) {
      return AdminAutomationSettings.defaults();
    }
  }

  Future<void> saveAutomationSettings(AdminAutomationSettings settings) async {
    await _db
        .collection('Settings')
        .doc('AdminAutomation')
        .set(settings.toMap(), SetOptions(merge: true));
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
    final byKey = <String, AdminOrderRecord>{};

    // Primary: collectionGroup fetches ALL Orders across every user, even if
    // a customer placed an order without a matching Users/{uid} profile doc.
    try {
      final groupSnap = await _db.collectionGroup('Orders').get();
      for (final doc in groupSnap.docs) {
        try {
          final order = OrderModel.fromSnapshot(doc);
          final uid = doc.reference.parent.parent?.id ?? order.userId;
          final key = '$uid/${doc.id}';
          byKey[key] = AdminOrderRecord(
            docId: doc.id,
            userId: uid,
            order: order,
            customer: userMap[uid],
          );
        } catch (_) {}
      }
    } catch (_) {
      // Fallback: iterate through known Users documents.
      await Future.wait(users.map((user) async {
        try {
          final snap = await _db
              .collection('Users')
              .doc(user.id)
              .collection('Orders')
              .get();
          for (final doc in snap.docs) {
            try {
              final key = '${user.id}/${doc.id}';
              byKey[key] = AdminOrderRecord(
                docId: doc.id,
                userId: user.id,
                order: OrderModel.fromSnapshot(doc),
                customer: userMap[user.id],
              );
            } catch (_) {}
          }
        } catch (_) {}
      }));
    }

    final records = byKey.values.toList()
      ..sort((a, b) => b.order.orderDate.compareTo(a.order.orderDate));
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

    // Immediately create an in-app notification using product name(s) & photo, never raw UUID
    final statusTitles = _orderStatusNotificationCopy(nextStatus, record.order);
    final notifId = 'order-${record.order.id}-${nextStatus.name}';
    final orderThumb =
        record.order.items.isNotEmpty ? (record.order.items.first.image ?? '') : '';
    await _db
        .collection('Users')
        .doc(record.userId)
        .collection('Notifications')
        .doc(notifId)
        .set({
      'id': notifId,
      'kind': 'order',
      'targetId': record.order.id,
      if (orderThumb.isNotEmpty) 'imageUrl': orderThumb,
      'titleVi': statusTitles.$1,
      'titleEn': statusTitles.$2,
      'bodyVi': statusTitles.$3,
      'bodyEn': statusTitles.$4,
      'read': false,
      'pushPending': true,
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
      OrderStatus status, OrderModel order) {
    final viItems = order.itemsSummary(english: false);
    final enItems = order.itemsSummary(english: true);
    switch (status) {
      case OrderStatus.pending:
        return (
          'Đơn hàng $viItems của bạn đã được tiếp nhận',
          'Your order for $enItems has been received',
          'Cửa hàng đã ghi nhận đơn hàng và đang chờ xác nhận.',
          'We have received your order and it is awaiting confirmation.',
        );
      case OrderStatus.processing:
        return (
          'Đơn hàng $viItems của bạn đang được chuẩn bị',
          'Your order for $enItems is being prepared',
          'VELORA đang kiểm tra và đóng gói cẩn thận cho bạn.',
          'VELORA is carefully packing your items.',
        );
      case OrderStatus.shipped:
        return (
          'Đơn hàng $viItems của bạn đang trên đường giao',
          'Your order for $enItems is on the way',
          'Đơn hàng đã bàn giao cho đơn vị vận chuyển. Hãy chú ý điện thoại nhé!',
          'Your order has been handed to the carrier and is on its way.',
        );
      case OrderStatus.received:
        return (
          'Đơn hàng $viItems của bạn đã giao thành công',
          'Your order for $enItems has been delivered',
          'Cảm ơn bạn đã mua sắm tại VELORA! Bạn có thể đánh giá sản phẩm ngay bây giờ.',
          'Thank you for shopping with VELORA! You can now review your pair.',
        );
      case OrderStatus.cancelled:
        return (
          'Đơn hàng $viItems của bạn đã bị hủy',
          'Your order for $enItems was cancelled',
          'Đơn hàng đã chuyển sang trạng thái hủy. Liên hệ cửa hàng nếu bạn cần hỗ trợ.',
          'Your order has been cancelled. Contact support if you need help.',
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
              adminReply: (data['adminReply'] as String?)?.trim(),
              adminReplyAt: (data['adminReplyAt'] as Timestamp?)?.toDate(),
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

  Future<void> replyToReview(AdminReviewRecord record, String replyText) async {
    final trimmed = replyText.trim();
    await _db
        .collection('Products')
        .doc(record.productId)
        .collection('Reviews')
        .doc(record.review.id)
        .update({
      'adminReply': trimmed,
      'adminReplyAt': FieldValue.serverTimestamp(),
    });

    // Notify the customer who wrote this review (review doc ID == reviewer uid)
    final notifId = 'review-reply-${record.productId}';
    final snippet = trimmed.length > 90 ? '${trimmed.substring(0, 90)}...' : trimmed;
    final titleVi = 'VELORA đã phản hồi đánh giá của bạn';
    final titleEn = 'VELORA replied to your review';
    final bodyVi = '${record.productTitle}: "$snippet"';
    final bodyEn = '${record.productTitle}: "$snippet"';

    await _db
        .collection('Users')
        .doc(record.review.id)
        .collection('Notifications')
        .doc(notifId)
        .set({
      'id': notifId,
      'kind': 'review',
      'targetId': record.productId,
      if (record.productThumbnail.isNotEmpty) 'imageUrl': record.productThumbnail,
      'titleVi': titleVi,
      'titleEn': titleEn,
      'bodyVi': bodyVi,
      'bodyEn': bodyEn,
      'read': false,
      'pushPending': true,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection('AdminNotifications').add({
      'titleVi': titleVi,
      'titleEn': titleEn,
      'bodyVi': bodyVi,
      'bodyEn': bodyEn,
      'kind': 'review',
      'targetId': record.productId,
      'audienceLabel': 'Phản hồi đánh giá của ${record.review.authorName}',
      'recipientCount': 1,
      'createdAt': FieldValue.serverTimestamp(),
    });
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
  // Vouchers (Vouchers/{code})
  // ---------------------------------------------------------------------------
  Future<List<AdminVoucherRecord>> fetchVouchers() async {
    try {
      final snap = await _db.collection('Vouchers').get();
      final list = snap.docs.map(AdminVoucherRecord.fromSnapshot).toList();
      list.sort((a, b) {
        final ad = a.createdAt ?? a.expires;
        final bd = b.createdAt ?? b.expires;
        return bd.compareTo(ad);
      });
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveVoucher(
    AdminVoucherRecord voucher, {
    required bool isNew,
    required List<UserModel> recipients,
    bool sendNotification = false,
  }) async {
    final code = voucher.code.trim().toUpperCase();
    await _db
        .collection('Vouchers')
        .doc(code)
        .set(voucher.toFirestore(isNew: isNew), SetOptions(merge: true));

    if (sendNotification && voucher.active && recipients.isNotEmpty) {
      final offerVi = voucher.shipping
          ? 'Miễn phí vận chuyển'
          : 'Giảm ${voucher.percent}% (tối đa \$${voucher.maxUsd.toStringAsFixed(0)})';
      final offerEn = voucher.shipping
          ? 'Free shipping'
          : '${voucher.percent}% off (up to \$${voucher.maxUsd.toStringAsFixed(0)})';
      await sendNotificationCampaign(
        titleVi: 'Mã giảm giá mới: $code',
        bodyVi: '$offerVi — ${voucher.title}. Mở Ví Voucher để dùng ngay!',
        titleEn: 'New voucher: $code',
        bodyEn: '$offerEn — ${voucher.title}. Open My Coupons to apply!',
        kind: 'voucher',
        targetId: code,
        recipients: recipients,
        audienceLabel: 'Voucher $code • ${voucher.audienceSummary} (${recipients.length})',
      );
    }
  }

  Future<void> toggleVoucherActive(String code, bool active) async {
    await _db.collection('Vouchers').doc(code).update({'active': active});
  }

  Future<void> deleteVoucher(String code) async {
    await _db.collection('Vouchers').doc(code).delete();
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

  Future<List<AdminUserInterest>> fetchUserInterests() async {
    try {
      final snap = await _db
          .collection('UserInterests')
          .orderBy('updatedAt', descending: true)
          .limit(50)
          .get();
      return snap.docs.map(AdminUserInterest.fromSnapshot).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> sendNotificationCampaign({
    required String titleVi,
    required String bodyVi,
    required String titleEn,
    required String bodyEn,
    required String kind,
    required String targetId,
    String imageUrl = '',
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
          if (imageUrl.trim().isNotEmpty) 'imageUrl': imageUrl.trim(),
          'titleVi': titleVi.trim(),
          'titleEn': safeTitleEn,
          'bodyVi': bodyVi.trim(),
          'bodyEn': safeBodyEn,
          'read': false,
          'pushPending': true,
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
