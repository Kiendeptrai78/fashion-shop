import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fashion_business_app/admin/web/data/admin_web_models.dart';
import 'package:fashion_business_app/admin/web/data/admin_web_repository.dart';
import 'package:fashion_business_app/features/authentication/models/user_model.dart';
import 'package:fashion_business_app/features/personalization/models/address_model.dart';
import 'package:fashion_business_app/features/shop/models/banner_model.dart';
import 'package:fashion_business_app/features/shop/models/brand_model.dart';
import 'package:fashion_business_app/features/shop/models/category_model.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/routes/routes.dart';
import 'package:fashion_business_app/utils/constants/admin_config.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/helpers/pricing_caculator.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:fashion_business_app/utils/web/url_strategy.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  /// Financial & accounting controls (adjustable live on Finance/Dashboard)
  final cogsRatePercent = 60.0.obs; // % giá vốn hàng bán trên tổng tiền hàng
  final vatRatePercent = 8.0.obs; // % thuế GTGT (0 = dùng thuế cố định đơn hàng $2)
  final onlyCompletedForFinance = false.obs; // false = tính mọi đơn chưa hủy, true = chỉ đơn Đã nhận
  final financePeriod = FinancePeriod.last6Months.obs;

  final products = <ProductModel>[].obs;
  final vouchers = <AdminVoucherRecord>[].obs;
  final brands = <BrandModel>[].obs;
  final categories = <CategoryModel>[].obs;
  final banners = <AdminBannerRecord>[].obs;
  final users = <UserModel>[].obs;
  final orders = <AdminOrderRecord>[].obs;
  final reviews = <AdminReviewRecord>[].obs;
  final campaigns = <AdminNotificationCampaign>[].obs;
  final userInterests = <AdminUserInterest>[].obs;
  final stockReceipts = <AdminStockReceipt>[].obs;
  final automation = AdminAutomationSettings.defaults().obs;
  final pushDeviceCount = 0.obs;

  /// Optional preselected user when jumping from Users -> Notifications or Vouchers
  final preselectedNotificationUserId = RxnString();
  final preselectedVoucherUserId = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  String formatMoney(num usd) {
    return formatShopMoney(usd, language: showVnd.value ? 'vi' : 'en');
  }

  static String routeForSection(AdminSection section) {
    switch (section) {
      case AdminSection.dashboard:
        return TRoutes.adminDashboard;
      case AdminSection.finance:
        return TRoutes.adminFinance;
      case AdminSection.orders:
        return TRoutes.adminOrders;
      case AdminSection.products:
        return TRoutes.adminProducts;
      case AdminSection.vouchers:
        return TRoutes.adminVouchers;
      case AdminSection.brands:
        return TRoutes.adminBrands;
      case AdminSection.categories:
        return TRoutes.adminCategories;
      case AdminSection.banners:
        return TRoutes.adminBanners;
      case AdminSection.users:
        return TRoutes.adminUsers;
      case AdminSection.reviews:
        return TRoutes.adminReviews;
      case AdminSection.notifications:
        return TRoutes.adminNotifications;
    }
  }

  void selectSection(AdminSection section) {
    activeSection.value = section;
    if (kIsWeb) {
      syncBrowserPath(routeForSection(section));
    }
  }

  void openNotificationComposerForUser(String userId) {
    preselectedNotificationUserId.value = userId;
    selectSection(AdminSection.notifications);
  }

  void openVoucherComposerForUser(String userId) {
    preselectedVoucherUserId.value = userId;
    selectSection(AdminSection.vouchers);
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
        repository.fetchVouchers(),
      ]);

      final loadedProducts = results[0] as List<ProductModel>;
      final loadedBrands = results[1] as List<BrandModel>;
      final loadedCategories = results[2] as List<CategoryModel>;
      final loadedBanners = results[3] as List<AdminBannerRecord>;
      final loadedUsers = results[4] as List<UserModel>;
      final loadedCampaigns = results[5] as List<AdminNotificationCampaign>;
      final loadedVouchers = results[6] as List<AdminVoucherRecord>;

      products.assignAll(loadedProducts);
      brands.assignAll(loadedBrands);
      categories.assignAll(loadedCategories);
      banners.assignAll(loadedBanners);
      users.assignAll(loadedUsers);
      campaigns.assignAll(loadedCampaigns);
      vouchers.assignAll(loadedVouchers);

      final secondary = await Future.wait([
        repository.fetchAllOrders(loadedUsers),
        repository.fetchAllReviews(loadedProducts),
        repository.fetchEnabledPushDevicesCount(loadedUsers),
        repository.fetchUserInterests(),
        repository.fetchStockReceipts(),
        repository.fetchAutomationSettings(),
      ]);

      orders.assignAll(secondary[0] as List<AdminOrderRecord>);
      reviews.assignAll(secondary[1] as List<AdminReviewRecord>);
      pushDeviceCount.value = secondary[2] as int;
      userInterests.assignAll(secondary[3] as List<AdminUserInterest>);
      stockReceipts.assignAll(secondary[4] as List<AdminStockReceipt>);
      automation.value = secondary[5] as AdminAutomationSettings;
    } catch (e) {
      errorMessage.value = 'Không thể tải dữ liệu quản trị: $e';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Computed Analytics & Financial P&L / Tax Engine
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

  double get cancelledOrdersUsd => orders
      .where((r) => r.order.status == OrderStatus.cancelled)
      .fold<double>(0.0, (sum, r) => sum + r.order.totalAmount);

  List<AdminOrderRecord> get financeEligibleOrders => orders.where((r) {
        if (onlyCompletedForFinance.value) {
          return r.order.status == OrderStatus.received;
        }
        return r.order.status != OrderStatus.cancelled;
      }).toList();

  OrderFinancialBreakdown breakdownForOrder(AdminOrderRecord record) {
    final itemsSubtotal = record.order.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final grossSubtotal =
        itemsSubtotal > 0 ? itemsSubtotal : record.order.totalAmount;
    final discount = record.order.discountAmount;
    final netRevenue = math.max(0.0, grossSubtotal - discount);
    final shipping = TPricingCalculator.getShippingCost('US');
    final orderFixedTax = TPricingCalculator.getTaxRateForLocation('US');
    final tax = vatRatePercent.value > 0
        ? netRevenue * (vatRatePercent.value / 100.0)
        : orderFixedTax;
    final cogs = grossSubtotal * (cogsRatePercent.value / 100.0);
    final netProfit = netRevenue - cogs - tax;

    return OrderFinancialBreakdown(
      record: record,
      grossSubtotal: grossSubtotal,
      discount: discount,
      netRevenue: netRevenue,
      tax: tax,
      cogs: cogs,
      shipping: shipping,
      netProfit: netProfit,
    );
  }

  List<OrderFinancialBreakdown> get financeBreakdowns =>
      financeEligibleOrders.map(breakdownForOrder).toList();

  double get financeGrossRevenueUsd =>
      financeBreakdowns.fold<double>(0.0, (s, b) => s + b.grossSubtotal);

  double get financeNetRevenueUsd =>
      financeBreakdowns.fold<double>(0.0, (s, b) => s + b.netRevenue);

  double get financeTotalDiscountUsd =>
      financeBreakdowns.fold<double>(0.0, (s, b) => s + b.discount);

  double get financeTotalTaxUsd =>
      financeBreakdowns.fold<double>(0.0, (s, b) => s + b.tax);

  double get financeTotalCogsUsd =>
      financeBreakdowns.fold<double>(0.0, (s, b) => s + b.cogs);

  double get financeTotalShippingUsd =>
      financeBreakdowns.fold<double>(0.0, (s, b) => s + b.shipping);

  double get financeNetProfitUsd =>
      financeBreakdowns.fold<double>(0.0, (s, b) => s + b.netProfit);

  double get financeProfitMarginPercent => financeNetRevenueUsd <= 0
      ? 0.0
      : (financeNetProfitUsd / financeNetRevenueUsd) * 100.0;

  List<FinancePeriodPoint> get financeChartSeries {
    final now = DateTime.now();
    final breakdowns = financeBreakdowns;

    if (financePeriod.value == FinancePeriod.last7Days) {
      return List.generate(7, (index) {
        final day = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: 6 - index));
        final matches = breakdowns.where((b) =>
            b.record.order.orderDate.year == day.year &&
            b.record.order.orderDate.month == day.month &&
            b.record.order.orderDate.day == day.day);
        return FinancePeriodPoint(
          label: '${day.day}/${day.month}',
          revenue: matches.fold<double>(0, (s, b) => s + b.netRevenue),
          costAndTax: matches.fold<double>(0, (s, b) => s + b.cogs + b.tax),
          tax: matches.fold<double>(0, (s, b) => s + b.tax),
          profit: matches.fold<double>(0, (s, b) => s + b.netProfit),
          orderCount: matches.length,
        );
      });
    }

    final monthsCount = financePeriod.value == FinancePeriod.last12Months ? 12 : 6;
    return List.generate(monthsCount, (index) {
      final d = DateTime(now.year, now.month - (monthsCount - 1 - index), 1);
      final matches = breakdowns.where((b) =>
          b.record.order.orderDate.year == d.year &&
          b.record.order.orderDate.month == d.month);
      return FinancePeriodPoint(
        label: 'T${d.month}/${d.year.toString().substring(2)}',
        revenue: matches.fold<double>(0, (s, b) => s + b.netRevenue),
        costAndTax: matches.fold<double>(0, (s, b) => s + b.cogs + b.tax),
        tax: matches.fold<double>(0, (s, b) => s + b.tax),
        profit: matches.fold<double>(0, (s, b) => s + b.netProfit),
        orderCount: matches.length,
      );
    });
  }

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

  Future<String> uploadVideo(Uint8List bytes, String filename, String folder) {
    return repository.uploadVideo(bytes, filename, folder);
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

  /// Customer segmentation engine used across Users, Vouchers, and Notifications
  CustomerProfileStats customerStatsFor(UserModel user) {
    final userOrders = ordersForUser(user.id);
    final total = userOrders.length;
    final received = userOrders.where((r) => r.order.status == OrderStatus.received).length;
    final cancelled = userOrders.where((r) => r.order.status == OrderStatus.cancelled).length;
    final active = total - received - cancelled;
    final spent = userOrders
        .where((r) => r.order.status == OrderStatus.received)
        .fold<double>(0.0, (sum, r) => sum + r.order.totalAmount);
    final cancelRate = total == 0 ? 0.0 : cancelled / total;

    CustomerSegment segment;
    if (AdminConfig.isAdminEmail(user.email)) {
      segment = CustomerSegment.admin;
    } else if (cancelled >= 2 || (total >= 2 && cancelRate >= 0.5)) {
      segment = CustomerSegment.bomHang;
    } else if (received >= 3 || spent >= 300) {
      segment = CustomerSegment.vip;
    } else if (received >= 1) {
      segment = CustomerSegment.loyal;
    } else {
      segment = CustomerSegment.newMember;
    }

    return CustomerProfileStats(
      user: user,
      segment: segment,
      totalOrders: total,
      receivedOrders: received,
      cancelledOrders: cancelled,
      activeOrders: active,
      totalSpent: spent,
    );
  }

  List<UserModel> usersMatchingVoucherAudience({
    required String targetAudience,
    List<String> targetUserIds = const [],
    bool excludeBomHang = true,
  }) {
    final clients = clientUsers;
    if (targetAudience == 'specific') {
      final ids = targetUserIds.toSet();
      return clients.where((u) => ids.contains(u.id)).toList();
    }
    return clients.where((u) {
      final stats = customerStatsFor(u);
      if (excludeBomHang && stats.segment == CustomerSegment.bomHang) {
        return false;
      }
      switch (targetAudience) {
        case 'vip':
          return stats.segment == CustomerSegment.vip;
        case 'loyal':
          return stats.segment == CustomerSegment.loyal ||
              stats.segment == CustomerSegment.vip;
        case 'newMember':
          return stats.segment == CustomerSegment.newMember;
        default:
          return true;
      }
    }).toList();
  }

  Future<bool> restockProduct({
    required ProductModel product,
    required int totalAdded,
    Map<String, int> variationDeltas = const {},
    double unitCostUsd = 0,
    String supplier = '',
    String note = '',
    bool notifyBackInStock = false,
  }) async {
    try {
      final newStock = await repository.restockProduct(
        product: product,
        totalAdded: totalAdded,
        variationDeltas: variationDeltas,
        unitCostUsd: unitCostUsd,
        supplier: supplier,
        note: note,
        notifyBackInStock: notifyBackInStock,
      );
      await loadAll(silent: true);
      _toastSuccess(
        'Đã nhập kho +$totalAdded đôi',
        '"${product.title}" hiện còn $newStock đôi trong kho.',
      );
      return true;
    } catch (e) {
      _toastError('Lỗi nhập hàng', e.toString());
      return false;
    }
  }

  Future<bool> saveAutomationSettings(AdminAutomationSettings next) async {
    try {
      await repository.saveAutomationSettings(next);
      automation.value = next;
      _toastSuccess('Đã lưu cấu hình tự động', 'Thiết lập tự động cho Voucher & Đánh giá đã được lưu.');
      return true;
    } catch (e) {
      _toastError('Lỗi lưu cấu hình', e.toString());
      return false;
    }
  }

  Future<bool> autoReplySingleReview(AdminReviewRecord record) async {
    final text = automation.value.renderAutoReply(
      authorName: record.review.authorName,
      productTitle: record.productTitle,
      rating: record.review.rating,
    );
    return replyToReview(record, text);
  }

  Future<int> autoReplyAllUnrepliedReviews() async {
    final pending = reviews.where((r) => !r.review.hasAdminReply).toList();
    if (pending.isEmpty) {
      _toastSuccess('Không còn đánh giá chờ', 'Tất cả đánh giá đều đã được phản hồi.');
      return 0;
    }
    var count = 0;
    try {
      for (final rec in pending) {
        final text = automation.value.renderAutoReply(
          authorName: rec.review.authorName,
          productTitle: rec.productTitle,
          rating: rec.review.rating,
        );
        await repository.replyToReview(rec, text);
        count++;
      }
      await loadAll(silent: true);
      _toastSuccess(
        'Đã tự động trả lời $count đánh giá',
        'Toàn bộ phản hồi đã lưu và gửi thông báo tới từng khách hàng.',
      );
    } catch (e) {
      _toastError('Lỗi trả lời tự động', e.toString());
    }
    return count;
  }

  Future<bool> issueAutoVoucherNow(String preset) async {
    final cfg = automation.value;
    final now = DateTime.now();
    final ym = '${now.year}${now.month.toString().padLeft(2, '0')}';
    late final AdminVoucherRecord voucher;

    switch (preset) {
      case 'new_member':
        voucher = AdminVoucherRecord(
          code: 'NEW$ym',
          title: 'Chào mừng thành viên mới VELORA — Giảm ${cfg.welcomePercent}%',
          percent: cfg.welcomePercent,
          maxUsd: 15,
          minUsd: 40,
          active: true,
          targetAudience: 'newMember',
          excludeBomHang: true,
          autoTag: 'new_member',
          expires: now.add(Duration(days: cfg.welcomeDays)),
        );
        break;
      case 'holiday':
        voucher = AdminVoucherRecord(
          code: 'HOLIDAY$ym',
          title: 'Ưu đãi Ngày lễ VELORA — Giảm ${cfg.holidayPercent}% toàn bộ Sneaker',
          percent: cfg.holidayPercent,
          maxUsd: 25,
          minUsd: 50,
          active: true,
          targetAudience: 'all',
          excludeBomHang: true,
          autoTag: 'holiday',
          expires: now.add(Duration(days: cfg.holidayDays)),
        );
        break;
      case 'vip':
      default:
        voucher = AdminVoucherRecord(
          code: 'VIP$ym',
          title: 'Tri ân Khách VIP thân thiết — Giảm ${cfg.vipPercent}% đặc quyền',
          percent: cfg.vipPercent,
          maxUsd: 35,
          minUsd: 60,
          active: true,
          targetAudience: 'vip',
          excludeBomHang: true,
          autoTag: 'vip',
          expires: now.add(Duration(days: cfg.vipDays)),
        );
        break;
    }

    return saveVoucher(voucher, isNew: true, sendNotification: true);
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

  Future<bool> replyToReview(AdminReviewRecord record, String replyText) async {
    try {
      await repository.replyToReview(record, replyText);
      await loadAll(silent: true);
      _toastSuccess(
        'Đã gửi phản hồi',
        'Phản hồi của VELORA đã được lưu và gửi thông báo tới ${record.review.authorName}.',
      );
      return true;
    } catch (e) {
      _toastError('Lỗi phản hồi đánh giá', e.toString());
      return false;
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

  Future<bool> saveVoucher(
    AdminVoucherRecord voucher, {
    required bool isNew,
    bool sendNotification = false,
  }) async {
    try {
      final recipients = usersMatchingVoucherAudience(
        targetAudience: voucher.targetAudience,
        targetUserIds: voucher.targetUserIds,
        excludeBomHang: voucher.excludeBomHang,
      );
      await repository.saveVoucher(
        voucher,
        isNew: isNew,
        recipients: recipients,
        sendNotification: sendNotification,
      );
      await loadAll(silent: true);
      _toastSuccess(
        'Đã lưu Voucher ${voucher.code}',
        sendNotification
            ? 'Đã áp dụng cho ${voucher.audienceSummary} và gửi thông báo tới ${recipients.length} khách hàng.'
            : 'Voucher đã được đồng bộ cho nhóm ${voucher.audienceSummary}.',
      );
      return true;
    } catch (e) {
      _toastError('Lỗi lưu Voucher', e.toString());
      return false;
    }
  }

  Future<void> toggleVoucherActive(AdminVoucherRecord record, bool active) async {
    try {
      await repository.toggleVoucherActive(record.code, active);
      await loadAll(silent: true);
    } catch (e) {
      _toastError('Lỗi cập nhật Voucher', e.toString());
    }
  }

  Future<void> deleteVoucher(AdminVoucherRecord record) async {
    try {
      await repository.deleteVoucher(record.code);
      vouchers.removeWhere((v) => v.code == record.code);
      _toastSuccess('Đã xóa Voucher', 'Mã giảm giá ${record.code} đã được xóa.');
    } catch (e) {
      _toastError('Lỗi xóa Voucher', e.toString());
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

      final matchedProduct = targetId.isNotEmpty
          ? products.firstWhereOrNull((p) => p.id == targetId)
          : null;
      final count = await repository.sendNotificationCampaign(
        titleVi: titleVi,
        bodyVi: bodyVi,
        titleEn: titleEn,
        bodyEn: bodyEn,
        kind: kind,
        targetId: targetId,
        imageUrl: matchedProduct?.thumbnail ?? '',
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
