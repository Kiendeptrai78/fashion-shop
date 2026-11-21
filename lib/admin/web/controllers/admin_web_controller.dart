import 'dart:typed_data';

import 'package:fashion_business_app/admin/web/data/admin_web_models.dart';
import 'package:fashion_business_app/admin/web/data/admin_web_repository.dart';
import 'package:fashion_business_app/features/authentication/models/user_model.dart';
import 'package:fashion_business_app/features/personalization/models/address_model.dart';
import 'package:fashion_business_app/features/shop/models/banner_model.dart';
import 'package:fashion_business_app/features/shop/models/brand_model.dart';
import 'package:fashion_business_app/features/shop/models/category_model.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/utils/constants/admin_config.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminWebController extends GetxController {
  AdminWebController({AdminWebRepository? repository})
      : repository = repository ?? AdminWebRepository();

  static AdminWebController get instance => Get.find();

  final AdminWebRepository repository;

  final activeSection = AdminSection.dashboard.obs;
  final showVnd = true.obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = ''.obs;

  final products = <ProductModel>[].obs;
  final brands = <BrandModel>[].obs;
  final categories = <CategoryModel>[].obs;
  final banners = <AdminBannerRecord>[].obs;
  final users = <UserModel>[].obs;
  final orders = <AdminOrderRecord>[].obs;
  final reviews = <AdminReviewRecord>[].obs;
  final campaigns = <AdminNotificationCampaign>[].obs;
  final pushDeviceCount = 0.obs;

  /// Optional preselected user when jumping from Users -> Notifications
  final preselectedNotificationUserId = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  String formatMoney(num usd) {
    return formatShopMoney(usd, language: showVnd.value ? 'vi' : 'en');
  }

  void selectSection(AdminSection section) {
    activeSection.value = section;
  }

  void openNotificationComposerForUser(String userId) {
    preselectedNotificationUserId.value = userId;
    activeSection.value = AdminSection.notifications;
  }

  Future<void> loadAll({bool silent = false}) async {
    if (silent) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    errorMessage.value = '';
    try {
      final results = await Future.wait([
        repository.fetchProducts(),
        repository.fetchBrands(),
        repository.fetchCategories(),
        repository.fetchBanners(),
        repository.fetchUsers(),
        repository.fetchNotificationCampaigns(),
      ]);

      final loadedProducts = results[0] as List<ProductModel>;
      final loadedBrands = results[1] as List<BrandModel>;
      final loadedCategories = results[2] as List<CategoryModel>;
      final loadedBanners = results[3] as List<AdminBannerRecord>;
      final loadedUsers = results[4] as List<UserModel>;
      final loadedCampaigns = results[5] as List<AdminNotificationCampaign>;

      products.assignAll(loadedProducts);
      brands.assignAll(loadedBrands);
      categories.assignAll(loadedCategories);
      banners.assignAll(loadedBanners);
      users.assignAll(loadedUsers);
      campaigns.assignAll(loadedCampaigns);

      final secondary = await Future.wait([
        repository.fetchAllOrders(loadedUsers),
        repository.fetchAllReviews(loadedProducts),
        repository.fetchEnabledPushDevicesCount(loadedUsers),
      ]);

      orders.assignAll(secondary[0] as List<AdminOrderRecord>);
      reviews.assignAll(secondary[1] as List<AdminReviewRecord>);
      pushDeviceCount.value = secondary[2] as int;
    } catch (e) {
      errorMessage.value = 'Không thể tải dữ liệu quản trị: $e';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Computed Analytics
  // ---------------------------------------------------------------------------
  double get totalRevenueUsd => orders
      .where((r) => r.order.status == OrderStatus.received)
      .fold<double>(0.0, (sum, r) => sum + r.order.totalAmount);

  double get activePipelineUsd => orders
      .where((r) =>
          r.order.status == OrderStatus.pending ||
          r.order.status == OrderStatus.processing ||
          r.order.status == OrderStatus.shipped)
      .fold<double>(0.0, (sum, r) => sum + r.order.totalAmount);

  int countOrdersByStatus(OrderStatus status) =>
      orders.where((r) => r.order.status == status).length;

  int get pendingOrdersCount =>
      countOrdersByStatus(OrderStatus.pending) +
      countOrdersByStatus(OrderStatus.processing);

  List<ProductModel> get lowStockProducts =>
      products.where((p) => p.stock <= 10).toList()
        ..sort((a, b) => a.stock.compareTo(b.stock));

  List<UserModel> get clientUsers =>
      users.where((u) => !AdminConfig.isAdminEmail(u.email)).toList();

  double get averageRating {
    if (reviews.isEmpty) return 0;
    final sum = reviews.fold<int>(0, (s, r) => s + r.review.rating);
    return sum / reviews.length;
  }

  int productCountForBrand(String brandId) =>
      products.where((p) => p.brand?.id == brandId).length;

  int productCountForCategory(String categoryId) =>
      products.where((p) => p.categoryId == categoryId).length;

  List<AdminOrderRecord> ordersForUser(String userId) =>
      orders.where((r) => r.userId == userId).toList();

  double totalSpentForUser(String userId) => orders
      .where((r) => r.userId == userId && r.order.status != OrderStatus.cancelled)
      .fold<double>(0.0, (sum, r) => sum + r.order.totalAmount);

  /// Revenue grouped by last 6 months (USD)
  List<({String label, double revenue, int orderCount})> get monthlyRevenueSeries {
    final now = DateTime.now();
    final buckets = <({int year, int month, String label})>[];
    for (var i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      buckets.add((
        year: date.year,
        month: date.month,
        label: 'T${date.month}/${date.year.toString().substring(2)}',
      ));
    }
    return buckets.map((bucket) {
      final matching = orders.where((r) =>
          r.order.status != OrderStatus.cancelled &&
          r.order.orderDate.year == bucket.year &&
          r.order.orderDate.month == bucket.month);
      final rev = matching.fold<double>(0.0, (sum, r) => sum + r.order.totalAmount);
      return (label: bucket.label, revenue: rev, orderCount: matching.length);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Image Upload Helper
  // ---------------------------------------------------------------------------
  Future<String> uploadImage(Uint8List bytes, String filename, String folder) {
    return repository.uploadImage(bytes, filename, folder);
  }

  // ---------------------------------------------------------------------------
  // CRUD Actions
  // ---------------------------------------------------------------------------
  void _toastSuccess(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF173E32),
      colorText: Colors.white,
      maxWidth: 420,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  void _toastError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFBE123C),
      colorText: Colors.white,
      maxWidth: 460,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    );
  }

  Future<bool> saveProduct(
    ProductModel product, {
    required bool isNew,
    bool sendNotification = false,
  }) async {
    try {
      await repository.saveProduct(
        product,
        isNew: isNew,
        sendNotification: sendNotification,
      );
      await loadAll(silent: true);
      _toastSuccess(
        'Đã lưu sản phẩm',
        isNew
            ? 'Đã thêm "${product.title}" vào cửa hàng.'
            : 'Đã cập nhật "${product.title}".',
      );
      return true;
    } catch (e) {
      _toastError('Lỗi lưu sản phẩm', e.toString());
      return false;
    }
  }

  Future<void> deleteProduct(ProductModel product) async {
    try {
      await repository.deleteProduct(product.id);
      products.removeWhere((p) => p.id == product.id);
      _toastSuccess('Đã xóa sản phẩm', 'Sản phẩm "${product.title}" đã được xóa.');
    } catch (e) {
      _toastError('Lỗi xóa sản phẩm', e.toString());
    }
  }

  Future<void> updateOrderStatus(
    AdminOrderRecord record,
    OrderStatus nextStatus,
  ) async {
    try {
      await repository.updateOrderStatus(record, nextStatus);
      await loadAll(silent: true);
      _toastSuccess(
        'Đã cập nhật đơn hàng',
        'Đơn #${record.order.id} đã chuyển trạng thái và gửi thông báo tới khách hàng.',
      );
    } catch (e) {
      _toastError('Lỗi cập nhật đơn hàng', e.toString());
    }
  }

  Future<void> updateOrderDeliveryDate(
    AdminOrderRecord record,
    DateTime deliveryDate,
  ) async {
    try {
      await repository.updateOrderDeliveryDate(record, deliveryDate);
      await loadAll(silent: true);
      _toastSuccess('Đã cập nhật ngày giao', 'Ngày giao dự kiến đã được lưu.');
    } catch (e) {
      _toastError('Lỗi cập nhật ngày giao', e.toString());
    }
  }

  Future<void> deleteOrder(AdminOrderRecord record) async {
    try {
      await repository.deleteOrder(record);
      orders.removeWhere((o) => o.docId == record.docId && o.userId == record.userId);
      _toastSuccess('Đã xóa đơn hàng', 'Đơn hàng #${record.order.id} đã được xóa.');
    } catch (e) {
      _toastError('Lỗi xóa đơn hàng', e.toString());
    }
  }

  Future<bool> saveBrand(BrandModel brand, {required bool isNew}) async {
    try {
      await repository.saveBrand(brand, isNew: isNew);
      await loadAll(silent: true);
      _toastSuccess(
        'Đã lưu thương hiệu',
        isNew ? 'Đã thêm thương hiệu "${brand.name}".' : 'Đã cập nhật "${brand.name}".',
      );
      return true;
    } catch (e) {
      _toastError('Lỗi lưu thương hiệu', e.toString());
      return false;
    }
  }

  Future<void> deleteBrand(BrandModel brand) async {
    try {
      await repository.deleteBrand(brand.id);
      brands.removeWhere((b) => b.id == brand.id);
      _toastSuccess('Đã xóa thương hiệu', 'Thương hiệu "${brand.name}" đã bị xóa.');
    } catch (e) {
      _toastError('Lỗi xóa thương hiệu', e.toString());
    }
  }

  Future<bool> saveCategory(CategoryModel category, {required bool isNew}) async {
    try {
      await repository.saveCategory(category, isNew: isNew);
      await loadAll(silent: true);
      _toastSuccess(
        'Đã lưu danh mục',
        isNew ? 'Đã thêm danh mục "${category.name}".' : 'Đã cập nhật "${category.name}".',
      );
      return true;
    } catch (e) {
      _toastError('Lỗi lưu danh mục', e.toString());
      return false;
    }
  }

  Future<void> deleteCategory(CategoryModel category) async {
    try {
      await repository.deleteCategory(category.id);
      categories.removeWhere((c) => c.id == category.id);
      _toastSuccess('Đã xóa danh mục', 'Danh mục "${category.name}" đã bị xóa.');
    } catch (e) {
      _toastError('Lỗi xóa danh mục', e.toString());
    }
  }

  Future<bool> saveBanner(BannerModel banner, {String? docId}) async {
    try {
      await repository.saveBanner(banner, docId: docId);
      await loadAll(silent: true);
      _toastSuccess(
        'Đã lưu banner',
        docId == null ? 'Đã tạo chiến dịch banner mới.' : 'Đã cập nhật banner.',
      );
      return true;
    } catch (e) {
      _toastError('Lỗi lưu banner', e.toString());
      return false;
    }
  }

  Future<void> toggleBannerActive(AdminBannerRecord record, bool active) async {
    try {
      await repository.toggleBannerActive(record.docId, active);
      await loadAll(silent: true);
    } catch (e) {
      _toastError('Lỗi cập nhật banner', e.toString());
    }
  }

  Future<void> deleteBanner(AdminBannerRecord record) async {
    try {
      await repository.deleteBanner(record.docId);
      banners.removeWhere((b) => b.docId == record.docId);
      _toastSuccess('Đã xóa banner', 'Banner đã được gỡ khỏi cửa hàng.');
    } catch (e) {
      _toastError('Lỗi xóa banner', e.toString());
    }
  }

  Future<List<AddressModel>> fetchUserAddresses(String userId) {
    return repository.fetchUserAddresses(userId);
  }

  Future<bool> updateUser(UserModel user) async {
    try {
      await repository.updateUserProfile(user);
      await loadAll(silent: true);
      _toastSuccess('Đã cập nhật người dùng', 'Thông tin của ${user.fullName} đã được lưu.');
      return true;
    } catch (e) {
      _toastError('Lỗi cập nhật người dùng', e.toString());
      return false;
    }
  }

  Future<void> deleteUser(UserModel user) async {
    if (AdminConfig.isAdminEmail(user.email)) {
      _toastError('Không thể xóa', 'Không thể xóa tài khoản quản trị viên chính.');
      return;
    }
    try {
      await repository.deleteUserRecord(user.id);
      users.removeWhere((u) => u.id == user.id);
      _toastSuccess('Đã xóa hồ sơ khách hàng', 'Đã xóa dữ liệu Firestore của ${user.email}.');
    } catch (e) {
      _toastError('Lỗi xóa người dùng', e.toString());
    }
  }

  Future<void> deleteReview(AdminReviewRecord record) async {
    try {
      await repository.deleteReview(record.productId, record.review.id);
      reviews.removeWhere(
        (r) => r.productId == record.productId && r.review.id == record.review.id,
      );
      _toastSuccess('Đã xóa đánh giá', 'Đánh giá đã được gỡ khỏi sản phẩm.');
    } catch (e) {
      _toastError('Lỗi xóa đánh giá', e.toString());
    }
  }

  Future<bool> sendNotification({
    required String titleVi,
    required String bodyVi,
    String titleEn = '',
    String bodyEn = '',
    required String kind,
    String targetId = '',
    String? specificUserId,
  }) async {
    try {
      final targetUsers = specificUserId != null && specificUserId.isNotEmpty
          ? users.where((u) => u.id == specificUserId).toList()
          : clientUsers;
      if (targetUsers.isEmpty) {
        _toastError('Không có người nhận', 'Chưa có tài khoản khách hàng nào để gửi thông báo.');
        return false;
      }
      final audienceLabel = specificUserId != null && specificUserId.isNotEmpty
          ? targetUsers.first.fullName.trim().isNotEmpty
              ? '${targetUsers.first.fullName} (${targetUsers.first.email})'
              : targetUsers.first.email
          : 'Tất cả khách hàng (${targetUsers.length})';

      final count = await repository.sendNotificationCampaign(
        titleVi: titleVi,
        bodyVi: bodyVi,
        titleEn: titleEn,
        bodyEn: bodyEn,
        kind: kind,
        targetId: targetId,
        recipients: targetUsers,
        audienceLabel: audienceLabel,
      );
      await loadAll(silent: true);
      _toastSuccess(
        'Đã gửi thông báo',
        'Đã gửi thành công đến $count tài khoản khách hàng.',
      );
      return true;
    } catch (e) {
      _toastError('Lỗi gửi thông báo', e.toString());
      return false;
    }
  }

  Future<void> deleteCampaignLog(AdminNotificationCampaign campaign) async {
    try {
      await repository.deleteNotificationCampaign(campaign.id);
      campaigns.removeWhere((c) => c.id == campaign.id);
      _toastSuccess('Đã xóa lịch sử', 'Đã xóa bản ghi chiến dịch thông báo.');
    } catch (e) {
      _toastError('Lỗi xóa lịch sử', e.toString());
    }
  }
}
