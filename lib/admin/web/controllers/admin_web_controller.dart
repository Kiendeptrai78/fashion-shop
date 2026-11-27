import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fashion_business_app/admin/web/data/admin_web_models.dart';
import 'package:fashion_business_app/admin/web/data/admin_web_repository.dart';
import 'package:fashion_business_app/features/authentication/models/user_model.dart';
import 'package:fashion_business_app/features/personalization/models/address_model.dart';
import 'package:fashion_business_app/features/shop/models/banner_model.dart';
import 'package:fashion_business_app/features/shop/models/brand_model.dart';
import 'package:fashion_business_app/features/shop/models/category_model.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/models/product_review_model.dart';
import 'package:fashion_business_app/features/shop/models/product_variation_model.dart';
import 'package:fashion_business_app/features/shop/models/return_request_model.dart';
import 'package:fashion_business_app/features/shop/models/shipping_route_helper.dart';
import 'package:fashion_business_app/features/shop/models/support_chat_model.dart';
import 'package:fashion_business_app/routes/routes.dart';
import 'package:fashion_business_app/utils/constants/admin_config.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/helpers/pricing_caculator.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:fashion_business_app/utils/localization/shop_translations.dart';
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
  final isVi = true.obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = ''.obs;

  String tr(String vi, String en) => isVi.value ? vi : en;

  String localizeCategory(String raw) {
    if (raw.trim().isEmpty) return isVi.value ? 'Giày thể thao' : 'Athletic';
    return shopTranslate(raw.trim(), language: isVi.value ? 'vi' : 'en');
  }

  void setLanguage(bool vi) {
    isVi.value = vi;
    if (Get.isRegistered<ShopLocale>()) {
      Get.find<ShopLocale>().change(vi ? 'vi' : 'en');
    }
  }

  /// Financial & accounting controls (adjustable live on Finance/Dashboard)
  final cogsRatePercent = 30.0.obs; // % giá vốn hàng bán mặc định 30%
  final vatRatePercent = 8.0.obs; // % thuế GTGT mặc định 8%
  final onlyCompletedForFinance = false.obs; // false = tính mọi đơn chưa hủy, true = chỉ đơn Đã nhận
  final financePeriod = FinancePeriod.last6Months.obs;
  final selectedTimeFilter = AdminTimeFilter.today.obs;
  final customSelectedDate = Rxn<DateTime>();
  final customSelectedMonth = Rxn<DateTime>();
  final compareCustomMonth = Rxn<DateTime>();
  final compareCustomDate = Rxn<DateTime>();

  final products = <ProductModel>[].obs;
  final vouchers = <AdminVoucherRecord>[].obs;
  final brands = <BrandModel>[].obs;
  final categories = <CategoryModel>[].obs;
  final banners = <AdminBannerRecord>[].obs;
  final users = <UserModel>[].obs;
  final orders = <AdminOrderRecord>[].obs;
  final returnRequests = <ReturnRequestModel>[].obs;
  final supportChats = <SupportChatThreadModel>[].obs;
  final reviews = <AdminReviewRecord>[].obs;
  final videoComments = <AdminVideoCommentRecord>[].obs;
  final campaigns = <AdminNotificationCampaign>[].obs;
  final userInterests = <AdminUserInterest>[].obs;
  final stockReceipts = <AdminStockReceipt>[].obs;
  final automation = AdminAutomationSettings.defaults().obs;
  final pushDeviceCount = 0.obs;

  /// Optional preselected user when jumping from Users -> Notifications, Vouchers or Support Chat
  final preselectedNotificationUserId = RxnString();
  final preselectedVoucherUserId = RxnString();
  final preselectedChatUserId = RxnString();
  final preselectedChatCustomerName = ''.obs;
  final preselectedChatCustomerEmail = ''.obs;
  final preselectedChatDraft = ''.obs;
  final preselectedChatOrderId = ''.obs;
  final preselectedChatReturnId = ''.obs;
  final preselectedChatProductTitle = ''.obs;
  final preselectedChatProductThumb = ''.obs;
  final preselectedChatContextSummary = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  String formatMoney(num usd) {
    return formatShopMoney(usd, language: showVnd.value ? 'vi' : 'en');
  }

  String formatCompactMoney(num usd) {
    if (!showVnd.value) {
      if (usd == 0) return '0';
      return '\$${usd.toStringAsFixed(0)}';
    }
    final vnd = (usd * usdToVnd).round();
    if (vnd == 0) return '0';
    final absVnd = vnd.abs();
    final sign = vnd < 0 ? '-' : '';
    if (absVnd >= 1000000) {
      final tr = (absVnd / 1000000).toStringAsFixed(1).replaceAll('.0', '');
      return '$sign${tr}tr';
    }
    if (absVnd >= 1000) {
      return '$sign${(absVnd / 1000).round()}k';
    }
    return '$sign$absVnd₫';
  }

  static String routeForSection(AdminSection section) {
    switch (section) {
      case AdminSection.dashboard:
      case AdminSection.finance:
        return TRoutes.adminDashboard;
      case AdminSection.orders:
        return TRoutes.adminOrders;
      case AdminSection.returns:
        return TRoutes.adminReturns;
      case AdminSection.supportChat:
        return TRoutes.adminSupportChat;
      case AdminSection.products:
        return TRoutes.adminProducts;
      case AdminSection.featured:
        return TRoutes.adminFeatured;
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
    final normalized =
        section == AdminSection.finance ? AdminSection.dashboard : section;
    activeSection.value = normalized;
    if (kIsWeb) {
      syncBrowserPath(routeForSection(normalized));
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

  void openSupportChatForCustomer({
    required String userId,
    required String customerName,
    String customerEmail = '',
    String draftMessage = '',
    String orderId = '',
    String returnRequestId = '',
    String productTitle = '',
    String productThumbnail = '',
    String contextSummary = '',
  }) {
    preselectedChatUserId.value = userId;
    preselectedChatCustomerName.value = customerName;
    preselectedChatCustomerEmail.value = customerEmail;
    preselectedChatDraft.value = draftMessage;
    preselectedChatOrderId.value = orderId;
    preselectedChatReturnId.value = returnRequestId;
    preselectedChatProductTitle.value = productTitle;
    preselectedChatProductThumb.value = productThumbnail;
    preselectedChatContextSummary.value = contextSummary;
    selectSection(AdminSection.supportChat);
  }

  Future<void> loadAll({bool silent = false}) async {
    if (silent) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    errorMessage.value = '';
    try {
      // Wave 1: Fire all 12 independent top-level fetches in parallel (1 round-trip!)
      final wave1 = await Future.wait<dynamic>([
        repository.fetchProducts(),
        repository.fetchBrands(),
        repository.fetchCategories(),
        repository.fetchBanners(),
        repository.fetchUsers(),
        repository.fetchNotificationCampaigns(),
        repository.fetchVouchers(),
        repository.fetchUserInterests(),
        repository.fetchStockReceipts(),
        repository.fetchAutomationSettings(),
        repository.fetchReturnRequests().catchError((_) => <ReturnRequestModel>[]),
        repository
            .fetchSupportChatThreads()
            .catchError((_) => <SupportChatThreadModel>[]),
      ]);

      final loadedProducts = wave1[0] as List<ProductModel>;
      final loadedBrands = wave1[1] as List<BrandModel>;
      final rawCategories = wave1[2] as List<CategoryModel>;
      final loadedBanners = wave1[3] as List<AdminBannerRecord>;
      final loadedUsers = wave1[4] as List<UserModel>;
      final loadedCampaigns = wave1[5] as List<AdminNotificationCampaign>;
      final loadedVouchers = wave1[6] as List<AdminVoucherRecord>;
      final loadedInterests = wave1[7] as List<AdminUserInterest>;
      final loadedReceipts = wave1[8] as List<AdminStockReceipt>;
      final loadedAutomation = wave1[9] as AdminAutomationSettings;
      final loadedReturns = wave1[10] as List<ReturnRequestModel>;
      final loadedChats = wave1[11] as List<SupportChatThreadModel>;

      // Merge any categories discovered from products or canonical VELORA sport categories
      final catById = <String, CategoryModel>{
        for (final c in rawCategories)
          if (c.id.isNotEmpty) c.id: c,
      };
      for (final p in loadedProducts) {
        if (p.categoryId.isNotEmpty && !catById.containsKey(p.categoryId)) {
          catById[p.categoryId] = CategoryModel(
            id: p.categoryId,
            name: p.categoryName.isNotEmpty ? p.categoryName : p.categoryId,
            image: p.thumbnail,
            isFeatured: true,
          );
        }
      }
      if (catById.isEmpty) {
        const defaults = [
          ('running-category', 'Chạy bộ'),
          ('lifestyle-category', 'Hằng ngày'),
          ('training-category', 'Tập luyện'),
          ('basketball-category', 'Bóng rổ'),
          ('trail-category', 'Địa hình'),
        ];
        for (final d in defaults) {
          catById[d.$1] = CategoryModel(
            id: d.$1,
            name: d.$2,
            image: '',
            isFeatured: true,
          );
        }
      }
      final loadedCategories = catById.values.toList();

      products.assignAll(loadedProducts);
      brands.assignAll(loadedBrands);
      categories.assignAll(loadedCategories);
      banners.assignAll(loadedBanners);
      users.assignAll(loadedUsers);
      campaigns.assignAll(loadedCampaigns);
      vouchers.assignAll(loadedVouchers);
      userInterests.assignAll(loadedInterests);
      stockReceipts.assignAll(loadedReceipts);
      automation.value = loadedAutomation;
      returnRequests.assignAll(loadedReturns);
      supportChats.assignAll(loadedChats);

      // Wave 2: Fire all 4 collectionGroup / mapped fetches in parallel (1 round-trip!)
      final wave2 = await Future.wait<dynamic>([
        repository.fetchAllOrders(loadedUsers),
        repository.fetchAllReviews(loadedProducts),
        repository.fetchEnabledPushDevicesCount(loadedUsers),
        repository
            .fetchAllVideoComments(loadedProducts)
            .catchError((_) => <AdminVideoCommentRecord>[]),
      ]);

      orders.assignAll(wave2[0] as List<AdminOrderRecord>);
      reviews.assignAll(wave2[1] as List<AdminReviewRecord>);
      pushDeviceCount.value = wave2[2] as int;
      videoComments.assignAll(wave2[3] as List<AdminVideoCommentRecord>);
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
    // Actual cash collected from customer for this order
    final netRevenue = record.order.totalAmount > 0
        ? record.order.totalAmount
        : math.max(0.0, grossSubtotal - discount);
    final shipping = TPricingCalculator.getShippingCost('US');
    final tax = vatRatePercent.value > 0
        ? netRevenue * (vatRatePercent.value / 100.0)
        : 0.0;
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

  // ---------------------------------------------------------------------------
  // Period-Aware Sales & Cashflow Helpers (Today / Yesterday / 7d / Month / All)
  // ---------------------------------------------------------------------------
  bool matchesTimeFilter(
    DateTime orderDate,
    AdminTimeFilter filter, {
    DateTime? customDate,
    DateTime? customMonth,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(orderDate.year, orderDate.month, orderDate.day);
    switch (filter) {
      case AdminTimeFilter.today:
        return d == today;
      case AdminTimeFilter.yesterday:
        return d == today.subtract(const Duration(days: 1));
      case AdminTimeFilter.last7Days:
        final start = today.subtract(const Duration(days: 6));
        return !d.isBefore(start) && !d.isAfter(today);
      case AdminTimeFilter.thisMonth:
        return orderDate.year == now.year && orderDate.month == now.month;
      case AdminTimeFilter.customMonth:
        final m = customMonth ?? customSelectedMonth.value ?? now;
        return orderDate.year == m.year && orderDate.month == m.month;
      case AdminTimeFilter.customDate:
        final target = customDate ?? customSelectedDate.value ?? today;
        final t = DateTime(target.year, target.month, target.day);
        return d == t;
      case AdminTimeFilter.allTime:
        return true;
    }
  }

  String get selectedPeriodTitle {
    final now = DateTime.now();
    switch (selectedTimeFilter.value) {
      case AdminTimeFilter.today:
        return 'Hôm nay (${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')})';
      case AdminTimeFilter.yesterday:
        final y = now.subtract(const Duration(days: 1));
        return 'Hôm qua (${y.day.toString().padLeft(2, '0')}/${y.month.toString().padLeft(2, '0')})';
      case AdminTimeFilter.last7Days:
        return '7 ngày qua';
      case AdminTimeFilter.thisMonth:
        return 'Tháng ${now.month}/${now.year}';
      case AdminTimeFilter.customMonth:
        final m = customSelectedMonth.value ?? now;
        return 'Tháng ${m.month}/${m.year}';
      case AdminTimeFilter.customDate:
        final d = customSelectedDate.value ?? now;
        return 'Ngày ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      case AdminTimeFilter.allTime:
        return 'Toàn thời gian';
    }
  }

  int countOrdersForFilter(AdminTimeFilter filter) => orders
      .where((r) => matchesTimeFilter(r.order.orderDate, filter))
      .length;

  int countOrdersInMonth(int year, int month) => orders
      .where((r) =>
          r.order.status != OrderStatus.cancelled &&
          r.order.orderDate.year == year &&
          r.order.orderDate.month == month)
      .length;

  double revenueInMonthUsd(int year, int month) => orders
      .where((r) =>
          r.order.status != OrderStatus.cancelled &&
          r.order.orderDate.year == year &&
          r.order.orderDate.month == month)
      .fold<double>(0.0, (s, r) => s + r.order.totalAmount);

  List<AdminOrderRecord> get ordersInSelectedPeriod => orders
      .where((r) => matchesTimeFilter(
            r.order.orderDate,
            selectedTimeFilter.value,
            customDate: customSelectedDate.value,
            customMonth: customSelectedMonth.value,
          ))
      .toList();

  /// Orders in the comparison period (either user-picked month/date or automatic preceding period)
  ({String label, List<AdminOrderRecord> records, bool active})
      get comparisonPeriodData {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Explicit custom comparison date takes priority if set
    if (compareCustomDate.value != null) {
      final cd = compareCustomDate.value!;
      final t = DateTime(cd.year, cd.month, cd.day);
      final list = orders.where((r) {
        if (onlyCompletedForFinance.value &&
            r.order.status != OrderStatus.received) {
          return false;
        }
        if (r.order.status == OrderStatus.cancelled) return false;
        final d = DateTime(
          r.order.orderDate.year,
          r.order.orderDate.month,
          r.order.orderDate.day,
        );
        return d == t;
      }).toList();
      final lbl =
          '${cd.day.toString().padLeft(2, '0')}/${cd.month.toString().padLeft(2, '0')}/${cd.year}';
      return (label: lbl, records: list, active: true);
    }

    // 2. Explicit custom comparison month if set
    if (compareCustomMonth.value != null) {
      final cm = compareCustomMonth.value!;
      final list = orders.where((r) {
        if (onlyCompletedForFinance.value &&
            r.order.status != OrderStatus.received) {
          return false;
        }
        if (r.order.status == OrderStatus.cancelled) return false;
        return r.order.orderDate.year == cm.year &&
            r.order.orderDate.month == cm.month;
      }).toList();
      return (label: 'T${cm.month}/${cm.year}', records: list, active: true);
    }

    // 3. Automatic preceding period matching the selected filter
    bool eligible(AdminOrderRecord r) {
      if (onlyCompletedForFinance.value) {
        return r.order.status == OrderStatus.received;
      }
      return r.order.status != OrderStatus.cancelled;
    }

    switch (selectedTimeFilter.value) {
      case AdminTimeFilter.today:
        final prev = today.subtract(const Duration(days: 1));
        final list = orders.where((r) {
          if (!eligible(r)) return false;
          final d = DateTime(
            r.order.orderDate.year,
            r.order.orderDate.month,
            r.order.orderDate.day,
          );
          return d == prev;
        }).toList();
        return (label: 'Hôm qua', records: list, active: true);

      case AdminTimeFilter.yesterday:
        final prev = today.subtract(const Duration(days: 2));
        final list = orders.where((r) {
          if (!eligible(r)) return false;
          final d = DateTime(
            r.order.orderDate.year,
            r.order.orderDate.month,
            r.order.orderDate.day,
          );
          return d == prev;
        }).toList();
        return (
          label:
              '${prev.day.toString().padLeft(2, '0')}/${prev.month.toString().padLeft(2, '0')}',
          records: list,
          active: true,
        );

      case AdminTimeFilter.customDate:
        final cur = customSelectedDate.value ?? today;
        final prev = DateTime(cur.year, cur.month, cur.day)
            .subtract(const Duration(days: 1));
        final list = orders.where((r) {
          if (!eligible(r)) return false;
          final d = DateTime(
            r.order.orderDate.year,
            r.order.orderDate.month,
            r.order.orderDate.day,
          );
          return d == prev;
        }).toList();
        return (
          label:
              '${prev.day.toString().padLeft(2, '0')}/${prev.month.toString().padLeft(2, '0')}',
          records: list,
          active: true,
        );

      case AdminTimeFilter.last7Days:
        final endPrev = today.subtract(const Duration(days: 7));
        final startPrev = today.subtract(const Duration(days: 13));
        final list = orders.where((r) {
          if (!eligible(r)) return false;
          final d = DateTime(
            r.order.orderDate.year,
            r.order.orderDate.month,
            r.order.orderDate.day,
          );
          return !d.isBefore(startPrev) && !d.isAfter(endPrev);
        }).toList();
        return (label: '7 ngày trước', records: list, active: true);

      case AdminTimeFilter.thisMonth:
        final prevMonth = DateTime(now.year, now.month - 1, 1);
        final list = orders.where((r) {
          if (!eligible(r)) return false;
          return r.order.orderDate.year == prevMonth.year &&
              r.order.orderDate.month == prevMonth.month;
        }).toList();
        return (
          label: 'T${prevMonth.month}/${prevMonth.year}',
          records: list,
          active: true,
        );

      case AdminTimeFilter.customMonth:
        final curM = customSelectedMonth.value ?? now;
        final prevMonth = DateTime(curM.year, curM.month - 1, 1);
        final list = orders.where((r) {
          if (!eligible(r)) return false;
          return r.order.orderDate.year == prevMonth.year &&
              r.order.orderDate.month == prevMonth.month;
        }).toList();
        return (
          label: 'T${prevMonth.month}/${prevMonth.year}',
          records: list,
          active: true,
        );

      case AdminTimeFilter.allTime:
        return (label: '', records: const [], active: false);
    }
  }

  /// 6-month series anchored at the active month (when customMonth is chosen) or current month
  List<({String label, double revenue, int orderCount})>
      get activeMonthlyComparisonSeries {
    final anchor = selectedTimeFilter.value == AdminTimeFilter.customMonth
        ? (customSelectedMonth.value ?? DateTime.now())
        : DateTime.now();
    return List.generate(6, (i) {
      final d = DateTime(anchor.year, anchor.month - (5 - i), 1);
      final matching = orders.where((r) =>
          r.order.status != OrderStatus.cancelled &&
          r.order.orderDate.year == d.year &&
          r.order.orderDate.month == d.month);
      final rev =
          matching.fold<double>(0.0, (sum, r) => sum + r.order.totalAmount);
      return (
        label: 'T${d.month}/${d.year.toString().substring(2)}',
        revenue: rev,
        orderCount: matching.length,
      );
    });
  }

  List<AdminOrderRecord> get validOrdersInSelectedPeriod =>
      ordersInSelectedPeriod
          .where((r) => r.order.status != OrderStatus.cancelled)
          .toList();

  List<AdminOrderRecord> get financeFilteredOrders =>
      ordersInSelectedPeriod.where((r) {
        if (onlyCompletedForFinance.value) {
          return r.order.status == OrderStatus.received;
        }
        return r.order.status != OrderStatus.cancelled;
      }).toList();

  List<OrderFinancialBreakdown> get periodFinanceBreakdowns =>
      financeFilteredOrders.map(breakdownForOrder).toList();

  double get periodCollectedUsd => validOrdersInSelectedPeriod.fold<double>(
        0.0,
        (s, r) => s + r.order.totalAmount,
      );

  double get periodVnPayCollectedUsd => validOrdersInSelectedPeriod
      .where((r) => r.order.paymentMethod.toLowerCase().contains('vnpay'))
      .fold<double>(0.0, (s, r) => s + r.order.totalAmount);

  double get periodCodCollectedUsd => validOrdersInSelectedPeriod
      .where((r) => !r.order.paymentMethod.toLowerCase().contains('vnpay'))
      .fold<double>(0.0, (s, r) => s + r.order.totalAmount);

  double get periodDeliveredUsd => validOrdersInSelectedPeriod
      .where((r) => r.order.status == OrderStatus.received)
      .fold<double>(0.0, (s, r) => s + r.order.totalAmount);

  int get periodPairsSold => validOrdersInSelectedPeriod.fold<int>(
        0,
        (s, r) => s + r.order.items.fold<int>(0, (isum, i) => isum + i.quantity),
      );

  int get periodDeliveredCount => ordersInSelectedPeriod
      .where((r) => r.order.status == OrderStatus.received)
      .length;

  int get periodInProgressCount => ordersInSelectedPeriod
      .where((r) =>
          r.order.status == OrderStatus.pending ||
          r.order.status == OrderStatus.processing ||
          r.order.status == OrderStatus.shipped)
      .length;

  int get periodCancelledCount => ordersInSelectedPeriod
      .where((r) => r.order.status == OrderStatus.cancelled)
      .length;

  double get periodCancelledUsd => ordersInSelectedPeriod
      .where((r) => r.order.status == OrderStatus.cancelled)
      .fold<double>(0.0, (s, r) => s + r.order.totalAmount);

  /// Aggregated sneakers sold in the selected period ("Bán được gì?")
  List<AdminSoldProductSummary> soldProductsForRecords(
    List<AdminOrderRecord> records,
  ) {
    final map = <String, ({
      String productId,
      String title,
      String thumb,
      int qty,
      Set<String> orderIds,
      double grossUsd,
      Map<String, int> varCounts,
    })>{};

    for (final r in records) {
      for (final item in r.order.items) {
        final key = item.productId.trim().isNotEmpty
            ? item.productId.trim()
            : item.title.trim();
        final existing = map[key];
        final orderIds = existing?.orderIds ?? <String>{};
        orderIds.add(r.order.id);
        final varCounts = existing?.varCounts ?? <String, int>{};
        final varLabel = (item.selectedVariation?.entries ?? const [])
            .map((e) => '${e.value}')
            .where((s) => s.trim().isNotEmpty)
            .join('/');
        if (varLabel.isNotEmpty) {
          varCounts[varLabel] = (varCounts[varLabel] ?? 0) + item.quantity;
        }
        final thumb = (existing?.thumb.isNotEmpty == true)
            ? existing!.thumb
            : (item.image ?? '');
        map[key] = (
          productId: item.productId,
          title: item.title,
          thumb: thumb,
          qty: (existing?.qty ?? 0) + item.quantity,
          orderIds: orderIds,
          grossUsd: (existing?.grossUsd ?? 0.0) + (item.price * item.quantity),
          varCounts: varCounts,
        );
      }
    }

    final list = map.values.map((e) {
      final varStr = e.varCounts.entries
          .take(4)
          .map((kv) => '${kv.key} (x${kv.value})')
          .join(', ');
      return AdminSoldProductSummary(
        productId: e.productId,
        title: e.title,
        thumbnail: e.thumb,
        quantitySold: e.qty,
        orderCount: e.orderIds.length,
        grossRevenueUsd: e.grossUsd,
        variationsSummary: varStr,
      );
    }).toList();

    list.sort((a, b) {
      final c = b.quantitySold.compareTo(a.quantitySold);
      if (c != 0) return c;
      return b.grossRevenueUsd.compareTo(a.grossRevenueUsd);
    });
    return list;
  }

  List<AdminSoldProductSummary> get periodSoldProducts =>
      soldProductsForRecords(validOrdersInSelectedPeriod);

  /// Clean daily revenue series for the last 7 days
  List<({String label, double revenue, int orderCount})> get last7DaysRevenueSeries {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - index));
      final matches = orders.where((r) =>
          r.order.status != OrderStatus.cancelled &&
          r.order.orderDate.year == day.year &&
          r.order.orderDate.month == day.month &&
          r.order.orderDate.day == day.day);
      final rev = matches.fold<double>(0.0, (s, r) => s + r.order.totalAmount);
      final label = index == 6
          ? 'Hôm nay'
          : '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}';
      return (label: label, revenue: rev, orderCount: matches.length);
    });
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

  int get pendingReturnsCount => returnRequests
      .where((r) =>
          r.status == ReturnRequestStatus.pending ||
          r.status == ReturnRequestStatus.approvedPickup ||
          r.status == ReturnRequestStatus.inspecting)
      .length;

  int get unreadSupportChatsCount =>
      supportChats.fold<int>(0, (sum, c) => sum + c.unreadByAdmin);

  void _upsertSupportChatLocal({
    required String userId,
    required String customerName,
    String customerEmail = '',
    required String lastMessage,
    String orderId = '',
    String returnRequestId = '',
    String productTitle = '',
    String productThumbnail = '',
    String contextSummary = '',
  }) {
    if (userId.trim().isEmpty) return;
    final idx = supportChats.indexWhere((c) => c.userId == userId);
    final prev = idx >= 0 ? supportChats[idx] : null;
    final updated = SupportChatThreadModel(
      userId: userId,
      customerName: customerName.trim().isNotEmpty
          ? customerName.trim()
          : (prev?.customerName ?? 'Khách hàng VELORA'),
      customerEmail: customerEmail.trim().isNotEmpty
          ? customerEmail.trim()
          : (prev?.customerEmail ?? ''),
      lastMessage: lastMessage,
      lastSender: 'admin',
      unreadByAdmin: 0,
      unreadByCustomer: (prev?.unreadByCustomer ?? 0) + 1,
      activeOrderId:
          orderId.isNotEmpty ? orderId : (prev?.activeOrderId ?? ''),
      activeReturnId: returnRequestId.isNotEmpty
          ? returnRequestId
          : (prev?.activeReturnId ?? ''),
      activeProductTitle: productTitle.isNotEmpty
          ? productTitle
          : (prev?.activeProductTitle ?? ''),
      activeProductThumbnail: productThumbnail.isNotEmpty
          ? productThumbnail
          : (prev?.activeProductThumbnail ?? ''),
      activeContextSummary: contextSummary.isNotEmpty
          ? contextSummary
          : (prev?.activeContextSummary ?? ''),
      updatedAt: DateTime.now(),
    );
    if (idx >= 0) {
      supportChats.removeAt(idx);
    }
    supportChats.insert(0, updated);
  }

  void _prependCampaignLogLocal({
    required String titleVi,
    String titleEn = '',
    required String bodyVi,
    String bodyEn = '',
    required String kind,
    String targetId = '',
    required String audienceLabel,
    required int recipientCount,
  }) {
    campaigns.insert(
      0,
      AdminNotificationCampaign(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        titleVi: titleVi,
        bodyVi: bodyVi,
        titleEn: titleEn.isNotEmpty ? titleEn : titleVi,
        bodyEn: bodyEn.isNotEmpty ? bodyEn : bodyVi,
        kind: kind,
        targetId: targetId,
        audienceLabel: audienceLabel,
        recipientCount: recipientCount,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<bool> sendAdminSupportMessage({
    required String userId,
    required String customerName,
    String customerEmail = '',
    required String text,
    String imageUrl = '',
    String videoUrl = '',
    String orderId = '',
    String returnRequestId = '',
    String productId = '',
    String productTitle = '',
    String productThumbnail = '',
    String contextSummary = '',
  }) async {
    try {
      final preview = text.trim().isNotEmpty
          ? text.trim()
          : (videoUrl.isNotEmpty
              ? '🎬 VELORA đã gửi video đính kèm'
              : '📷 VELORA đã gửi hình ảnh');
      _upsertSupportChatLocal(
        userId: userId,
        customerName: customerName,
        customerEmail: customerEmail,
        lastMessage: preview,
        orderId: orderId,
        returnRequestId: returnRequestId,
        productTitle: productTitle,
        productThumbnail: productThumbnail,
        contextSummary: contextSummary,
      );
      await repository.sendAdminSupportMessage(
        userId: userId,
        customerName: customerName,
        customerEmail: customerEmail,
        text: text,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        orderId: orderId,
        returnRequestId: returnRequestId,
        productId: productId,
        productTitle: productTitle,
        productThumbnail: productThumbnail,
        contextSummary: contextSummary,
      );
      return true;
    } catch (e) {
      _toastError('Lỗi gửi tin nhắn cho khách', e.toString());
      return false;
    }
  }

  /// Sends a 1-1 New Product introduction message via Support Chat in parallel.
  Future<int> broadcastNewProductChat({
    required ProductModel product,
    String? customTemplate,
    String? singleUserId,
    bool onlyMatchingCategory = false,
    bool silentToast = false,
  }) async {
    try {
      List<UserModel> targets;
      if (singleUserId != null && singleUserId.trim().isNotEmpty) {
        targets = clientUsers.where((u) => u.id == singleUserId).toList();
      } else if (onlyMatchingCategory && product.categoryId.isNotEmpty) {
        final interestedIds = userInterests
            .where((i) =>
                i.interestedCategoryIds.contains(product.categoryId) ||
                i.interestedCategories.any((c) =>
                    c.toLowerCase() == product.categoryName.toLowerCase()))
            .map((i) => i.userId)
            .toSet();
        targets = clientUsers.where((u) => interestedIds.contains(u.id)).toList();
        if (targets.isEmpty) targets = clientUsers;
      } else {
        targets = clientUsers;
      }

      if (targets.isEmpty) return 0;

      final effPrice = (product.salePrice > 0 && product.salePrice < product.price)
          ? product.salePrice
          : product.price;
      final priceStr = formatMoney(effPrice);
      final catLabel = localizeCategory(product.categoryName);

      await Future.wait(targets.map((u) async {
        final name = u.fullName.trim().isNotEmpty
            ? u.fullName.trim()
            : (u.email.split('@').first);
        final tpl = (customTemplate != null && customTemplate.trim().isNotEmpty)
            ? customTemplate.trim()
            : automation.value.templateChatNewProduct;
        final text = tpl
            .replaceAll('{name}', name)
            .replaceAll('{product}', product.title)
            .replaceAll('{category}', catLabel)
            .replaceAll('{price}', priceStr);

        _upsertSupportChatLocal(
          userId: u.id,
          customerName: name,
          customerEmail: u.email,
          lastMessage: text,
          productTitle: product.title,
          productThumbnail: product.thumbnail,
          contextSummary: 'Sản phẩm mới • $catLabel • $priceStr',
        );

        await repository.sendAdminSupportMessage(
          userId: u.id,
          customerName: name,
          customerEmail: u.email,
          text: text,
          imageUrl: product.thumbnail,
          productId: product.id,
          productTitle: product.title,
          productThumbnail: product.thumbnail,
          contextSummary: 'Sản phẩm mới • $catLabel • $priceStr',
          sendPushNotification: true,
        );
      }));

      final sent = targets.length;
      if (!silentToast) {
        _toastSuccess(
          'Đã nhắn tin giới thiệu sản phẩm mới',
          'Đã gửi tin nhắn 1-1 giới thiệu "${product.title}" tới $sent khách hàng!',
        );
      }
      return sent;
    } catch (e) {
      if (!silentToast) {
        _toastError('Lỗi gửi tin nhắn sản phẩm mới', e.toString());
      }
      return 0;
    }
  }

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

  void _upsertProductInMemory(ProductModel saved) {
    final idx = products.indexWhere((p) => p.id == saved.id);
    if (idx >= 0) {
      products[idx] = saved;
    } else {
      products.add(saved);
      products.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    }
  }

  Future<bool> saveProduct(
    ProductModel product, {
    required bool isNew,
    bool sendNotification = false,
  }) async {
    try {
      final docId = await repository.saveProduct(
        product,
        isNew: isNew,
        sendNotification: sendNotification,
      );
      final saved = ProductModel(
        id: docId,
        title: product.title.trim(),
        stock: product.stock,
        price: product.price,
        salePrice: product.salePrice,
        thumbnail: product.thumbnail.trim(),
        images: product.images,
        videos: product.videos,
        videoSources: product.videoSources,
        description: product.description,
        productType: product.productType,
        isFeatured: product.isFeatured,
        isDiscontinued: product.isDiscontinued,
        brand: product.brand,
        categoryId: product.categoryId,
        categoryName: product.categoryName,
        catalogId: product.catalogId,
        productAttributes: product.productAttributes,
        productVariations: product.productVariations,
      );
      _upsertProductInMemory(saved);

      if (isNew && automation.value.autoChatOnNewProduct) {
        // Dispatch 1-1 intro chats in background so product save finishes immediately!
        broadcastNewProductChat(
          product: saved,
          onlyMatchingCategory: false,
          silentToast: true,
        );
      }
      _toastSuccess(
        'Đã lưu sản phẩm',
        isNew
            ? (automation.value.autoChatOnNewProduct
                ? 'Đã thêm "${saved.title}" và đang gửi tin nhắn giới thiệu tới khách hàng.'
                : 'Đã thêm "${saved.title}" vào cửa hàng.')
            : 'Đã cập nhật "${saved.title}".',
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

  Future<bool> toggleProductDiscontinued(
    ProductModel product,
    bool isDiscontinued,
  ) async {
    final updated = ProductModel(
      id: product.id,
      title: product.title,
      stock: product.stock,
      price: product.price,
      salePrice: product.salePrice,
      thumbnail: product.thumbnail,
      images: product.images,
      videos: product.videos,
        videoSources: product.videoSources,
      description: product.description,
      productType: product.productType,
      isFeatured: isDiscontinued ? false : product.isFeatured,
      isDiscontinued: isDiscontinued,
      brand: product.brand,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      catalogId: product.catalogId,
      productAttributes: product.productAttributes,
      productVariations: product.productVariations,
    );
    _upsertProductInMemory(updated);
    try {
      await repository.saveProduct(updated, isNew: false);
      _toastSuccess(
        isDiscontinued ? 'Đã chuyển sang Ngừng bán' : 'Đã mở bán trở lại',
        isDiscontinued
            ? '"${product.title}" đã chuyển vào danh sách Ngừng bán.'
            : '"${product.title}" đã được mở bán trở lại trên cửa hàng.',
      );
      return true;
    } catch (e) {
      _upsertProductInMemory(product);
      _toastError('Lỗi cập nhật trạng thái bán', e.toString());
      return false;
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
      final updatedVars = product.productVariations?.map((v) {
        final add = variationDeltas[v.id] ?? 0;
        if (add == 0) return v;
        final json = v.toJson();
        json['Stock'] = (v.stock + add).clamp(0, 999999);
        return ProductVariationModel.fromJson(json);
      }).toList();
      _upsertProductInMemory(
        ProductModel(
          id: product.id,
          title: product.title,
          stock: newStock,
          price: product.price,
          salePrice: product.salePrice,
          thumbnail: product.thumbnail,
          images: product.images,
          videos: product.videos,
        videoSources: product.videoSources,
          description: product.description,
          productType: product.productType,
          isFeatured: product.isFeatured,
          isDiscontinued: product.isDiscontinued,
          brand: product.brand,
          categoryId: product.categoryId,
          categoryName: product.categoryName,
          catalogId: product.catalogId,
          productAttributes: product.productAttributes,
          productVariations: updatedVars,
        ),
      );
      stockReceipts.insert(
        0,
        AdminStockReceipt(
          id: 'local-${DateTime.now().microsecondsSinceEpoch}',
          productId: product.id,
          productTitle: product.title,
          productThumbnail: product.thumbnail,
          addedQuantity: totalAdded,
          previousStock: product.stock,
          newStock: newStock,
          unitCostUsd: unitCostUsd,
          supplier: supplier,
          note: note,
          variationDeltas: variationDeltas,
          createdAt: DateTime.now(),
        ),
      );
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

  void _applyReviewReplyLocal(AdminReviewRecord record, String replyText) {
    final idx = reviews.indexWhere(
      (r) => r.productId == record.productId && r.review.id == record.review.id,
    );
    if (idx < 0) return;
    final old = reviews[idx].review;
    reviews[idx] = AdminReviewRecord(
      productId: record.productId,
      productTitle: record.productTitle,
      productThumbnail: record.productThumbnail,
      purchaseOrderId: record.purchaseOrderId,
      review: ProductReviewEntry(
        id: old.id,
        userId: old.userId,
        authorName: old.authorName,
        rating: old.rating,
        text: old.text,
        createdAt: old.createdAt,
        adminReply: replyText.trim(),
        adminReplyAt: DateTime.now(),
        imageUrls: old.imageUrls,
        videoUrls: old.videoUrls,
        verifiedPurchase: old.verifiedPurchase,
      ),
    );
  }

  Future<int> autoReplyAllUnrepliedReviews() async {
    final pending = reviews.where((r) => !r.review.hasAdminReply).toList();
    if (pending.isEmpty) {
      _toastSuccess('Không còn đánh giá chờ', 'Tất cả đánh giá đều đã được phản hồi.');
      return 0;
    }
    try {
      await Future.wait(pending.map((rec) async {
        final text = automation.value.renderAutoReply(
          authorName: rec.review.authorName,
          productTitle: rec.productTitle,
          rating: rec.review.rating,
        );
        _applyReviewReplyLocal(rec, text);
        await repository.replyToReview(rec, text);
      }));
      final count = pending.length;
      _toastSuccess(
        'Đã tự động trả lời $count đánh giá',
        'Toàn bộ phản hồi đã lưu và gửi thông báo tới từng khách hàng.',
      );
      return count;
    } catch (e) {
      _toastError('Lỗi trả lời tự động', e.toString());
      return 0;
    }
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
    if (nextStatus == OrderStatus.cancelled &&
        record.order.status != OrderStatus.pending) {
      _toastError(
        'Không thể hủy đơn hàng',
        'Chỉ có thể hủy đơn khi đang ở trạng thái "Chờ xác nhận". Đơn hàng đã sang bước chuẩn bị/vận chuyển không thể hủy.',
      );
      return;
    }
    final idx = orders.indexWhere(
      (o) => o.docId == record.docId && o.userId == record.userId,
    );
    final eta = ShippingRouteHelper.estimateForAddress(record.order.address);
    final nextDelivery = eta.latestDeliveryDate(record.order.orderDate);
    final updatedOrder = OrderModel(
      id: record.order.id,
      userId: record.order.userId,
      status: nextStatus,
      totalAmount: record.order.totalAmount,
      discountAmount: record.order.discountAmount,
      couponCode: record.order.couponCode,
      reviewedProductIds: record.order.reviewedProductIds,
      coinsUsed: record.order.coinsUsed,
      orderDate: record.order.orderDate,
      paymentMethod: record.order.paymentMethod,
      address: record.order.address,
      deliveryDate: nextDelivery,
      items: record.order.items,
      searchDate: nextStatus == OrderStatus.received
          ? DateTime.now()
          : record.order.searchDate,
    );
    final updatedRecord = AdminOrderRecord(
      docId: record.docId,
      userId: record.userId,
      order: updatedOrder,
      customer: record.customer,
    );

    // Optimistic in-memory update for instant UI responsiveness!
    if (idx >= 0) {
      orders[idx] = updatedRecord;
    }

    String? autoChatText;
    String? autoChatContext;
    if (automation.value.autoChatOnOrderStatus && record.userId.isNotEmpty) {
      final statusLabel = switch (nextStatus) {
        OrderStatus.pending => 'Chờ xác nhận',
        OrderStatus.processing => 'Đang đóng gói',
        OrderStatus.shipped => 'Đang vận chuyển',
        OrderStatus.received => 'Giao thành công',
        OrderStatus.cancelled => 'Đã hủy đơn',
      };
      final etaNote = nextStatus == OrderStatus.received
          ? 'Cảm ơn bạn đã tin chọn VELORA — nhớ đánh giá đôi giày để nhận ưu đãi nhé!'
          : (nextStatus == OrderStatus.cancelled
              ? 'Nếu bạn cần đặt lại mẫu khác, cứ nhắn VELORA hỗ trợ ngay.'
              : 'Lộ trình từ Kho Hà Nội → ${eta.destinationCity} (dự kiến ${eta.minDays}–${eta.maxDays} ngày)');
      autoChatText = automation.value.renderOrderStatusChat(
        customerName: record.customerName,
        itemsSummary: record.order.itemsSummary(),
        statusLabel: statusLabel,
        etaNote: etaNote,
      );
      autoChatContext = 'Cập nhật tự động • $statusLabel';
      final thumb = record.order.items.isNotEmpty
          ? (record.order.items.first.image ?? '')
          : '';
      _upsertSupportChatLocal(
        userId: record.userId,
        customerName: record.customerName,
        customerEmail: record.customerEmail,
        lastMessage: autoChatText,
        orderId: record.order.id,
        productTitle: record.order.itemsSummary(),
        productThumbnail: thumb,
        contextSummary: autoChatContext,
      );
    }

    try {
      await repository.updateOrderStatus(
        record,
        nextStatus,
        autoChatText: autoChatText,
        autoChatContext: autoChatContext,
      );
      _toastSuccess(
        'Đã cập nhật đơn hàng',
        automation.value.autoChatOnOrderStatus
            ? 'Đã chuyển trạng thái đơn hàng, gửi thông báo & nhắn tin 1-1 tới ${record.customerName}.'
            : 'Đơn hàng đã chuyển trạng thái và gửi thông báo tới khách hàng.',
      );
    } catch (e) {
      if (idx >= 0 && idx < orders.length) {
        orders[idx] = record;
      }
      _toastError('Lỗi cập nhật đơn hàng', e.toString());
    }
  }

  Future<void> updateOrderDeliveryDate(
    AdminOrderRecord record,
    DateTime deliveryDate,
  ) async {
    final idx = orders.indexWhere(
      (o) => o.docId == record.docId && o.userId == record.userId,
    );
    if (idx >= 0) {
      orders[idx] = AdminOrderRecord(
        docId: record.docId,
        userId: record.userId,
        customer: record.customer,
        order: OrderModel(
          id: record.order.id,
          userId: record.order.userId,
          status: record.order.status,
          totalAmount: record.order.totalAmount,
          discountAmount: record.order.discountAmount,
          couponCode: record.order.couponCode,
          reviewedProductIds: record.order.reviewedProductIds,
          coinsUsed: record.order.coinsUsed,
          orderDate: record.order.orderDate,
          paymentMethod: record.order.paymentMethod,
          address: record.order.address,
          deliveryDate: deliveryDate,
          items: record.order.items,
          searchDate: record.order.searchDate,
        ),
      );
    }
    try {
      await repository.updateOrderDeliveryDate(record, deliveryDate);
      _toastSuccess('Đã cập nhật ngày giao', 'Ngày giao dự kiến đã được lưu.');
    } catch (e) {
      if (idx >= 0 && idx < orders.length) {
        orders[idx] = record;
      }
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

  // ---------------------------------------------------------------------------
  // Return & Exchange Requests Management
  // ---------------------------------------------------------------------------
  void _applyReturnUpdateLocal(
    ReturnRequestModel request,
    ReturnRequestStatus nextStatus,
    String responseText,
  ) {
    final idx = returnRequests.indexWhere((r) => r.id == request.id);
    if (idx < 0) return;
    returnRequests[idx] = ReturnRequestModel(
      id: request.id,
      orderId: request.orderId,
      userId: request.userId,
      customerName: request.customerName,
      customerEmail: request.customerEmail,
      customerPhone: request.customerPhone,
      pickupAddress: request.pickupAddress,
      productId: request.productId,
      productTitle: request.productTitle,
      productThumbnail: request.productThumbnail,
      refundAmountUsd: request.refundAmountUsd,
      quantity: request.quantity,
      currentVariation: request.currentVariation,
      requestedSizeOrColor: request.requestedSizeOrColor,
      type: request.type,
      reasonCategory: request.reasonCategory,
      description: request.description,
      imageUrls: request.imageUrls,
      videoUrls: request.videoUrls,
      status: nextStatus,
      adminResponse: responseText,
      createdAt: request.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Future<bool> updateReturnRequest({
    required ReturnRequestModel request,
    required ReturnRequestStatus nextStatus,
    String? customAdminResponse,
  }) async {
    try {
      final responseText = (customAdminResponse != null &&
              customAdminResponse.trim().isNotEmpty)
          ? customAdminResponse.trim()
          : (request.adminResponse.trim().isNotEmpty
              ? request.adminResponse.trim()
              : automation.value.renderReturnReply(
                  customerName: request.customerName,
                  productTitle: request.productTitle,
                  typeLabel: request.typeLabel(),
                  requestedSizeOrColor: request.requestedSizeOrColor,
                ));
      _applyReturnUpdateLocal(request, nextStatus, responseText);
      await repository.updateReturnRequest(
        request: request,
        nextStatus: nextStatus,
        adminResponse: responseText,
      );
      _toastSuccess(
        'Đã cập nhật yêu cầu Đổi / Trả',
        'Yêu cầu của ${request.customerName} đã chuyển sang "${ReturnRequestModel.statusLabelOf(nextStatus)}" và gửi thông báo tới khách.',
      );
      return true;
    } catch (e) {
      _toastError('Lỗi cập nhật đổi trả', e.toString());
      return false;
    }
  }

  Future<int> autoApproveAllPendingReturnRequests() async {
    final pending = returnRequests
        .where((r) => r.status == ReturnRequestStatus.pending)
        .toList();
    if (pending.isEmpty) {
      _toastSuccess(
        'Không có yêu cầu chờ duyệt',
        'Tất cả yêu cầu Đổi trả & Bảo hành đều đã được xử lý.',
      );
      return 0;
    }
    try {
      await Future.wait(pending.map((req) async {
        final reply = automation.value.renderReturnReply(
          customerName: req.customerName,
          productTitle: req.productTitle,
          typeLabel: req.typeLabel(),
          requestedSizeOrColor: req.requestedSizeOrColor,
        );
        _applyReturnUpdateLocal(req, ReturnRequestStatus.approvedPickup, reply);
        await repository.updateReturnRequest(
          request: req,
          nextStatus: ReturnRequestStatus.approvedPickup,
          adminResponse: reply,
        );
      }));
      final count = pending.length;
      _toastSuccess(
        'Đã tự động duyệt & điều Shipper cho $count yêu cầu',
        'Toàn bộ khách hàng đã nhận thông báo Shipper VELORA đến thu hồi tận nơi.',
      );
      return count;
    } catch (e) {
      _toastError('Lỗi tự động duyệt đổi trả', e.toString());
      return 0;
    }
  }

  Future<void> deleteReturnRequest(ReturnRequestModel request) async {
    try {
      await repository.deleteReturnRequest(request.id);
      returnRequests.removeWhere((r) => r.id == request.id);
      _toastSuccess('Đã xóa yêu cầu đổi trả', 'Bản ghi đổi trả đã được gỡ.');
    } catch (e) {
      _toastError('Lỗi xóa yêu cầu đổi trả', e.toString());
    }
  }

  Future<bool> saveBrand(BrandModel brand, {required bool isNew}) async {
    try {
      await repository.saveBrand(brand, isNew: isNew);
      if (!isNew && brand.id.isNotEmpty) {
        final idx = brands.indexWhere((b) => b.id == brand.id);
        if (idx >= 0) brands[idx] = brand;
      } else {
        brands.assignAll(await repository.fetchBrands());
      }
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
      if (!isNew && category.id.isNotEmpty) {
        final idx = categories.indexWhere((c) => c.id == category.id);
        if (idx >= 0) categories[idx] = category;
      } else {
        categories.assignAll(await repository.fetchCategories());
      }
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
      if (docId != null && docId.isNotEmpty) {
        final idx = banners.indexWhere((b) => b.docId == docId);
        if (idx >= 0) {
          banners[idx] = AdminBannerRecord(docId: docId, banner: banner);
        }
      } else {
        banners.assignAll(await repository.fetchBanners());
      }
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
    final idx = banners.indexWhere((b) => b.docId == record.docId);
    if (idx >= 0) {
      banners[idx] = AdminBannerRecord(
        docId: record.docId,
        banner: BannerModel(
          imageUrl: record.banner.imageUrl,
          targetScreen: record.banner.targetScreen,
          active: active,
          title: record.banner.title,
          subtitle: record.banner.subtitle,
          sortOrder: record.banner.sortOrder,
          categoryId: record.banner.categoryId,
          brandId: record.banner.brandId,
        ),
      );
    }
    try {
      await repository.toggleBannerActive(record.docId, active);
    } catch (e) {
      if (idx >= 0 && idx < banners.length) banners[idx] = record;
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
      final idx = users.indexWhere((u) => u.id == user.id);
      if (idx >= 0) users[idx] = user;
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
    _applyReviewReplyLocal(record, replyText);
    try {
      await repository.replyToReview(record, replyText);
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

  // ---------------------------------------------------------------------------
  // Featured Tab ("Nổi bật") Video, Comment Reply & Similar-Product Automation
  // ---------------------------------------------------------------------------
  List<ProductModel> similarProductsFor(ProductModel watched, {int limit = 4}) {
    final sameCat = products
        .where((p) =>
            p.id != watched.id &&
            p.categoryId.isNotEmpty &&
            p.categoryId == watched.categoryId)
        .take(limit)
        .toList();
    if (sameCat.length >= limit) return sameCat;
    final extras = products
        .where((p) => p.id != watched.id && !sameCat.any((s) => s.id == p.id))
        .take(limit - sameCat.length);
    return [...sameCat, ...extras];
  }

  Future<bool> toggleProductFeatured(
      ProductModel product, bool isFeatured) async {
    final updated = ProductModel(
      id: product.id,
      title: product.title,
      stock: product.stock,
      price: product.price,
      salePrice: product.salePrice,
      thumbnail: product.thumbnail,
      images: product.images,
      videos: product.videos,
        videoSources: product.videoSources,
      description: product.description,
      productType: product.productType,
      isFeatured: isFeatured,
      isDiscontinued: product.isDiscontinued,
      brand: product.brand,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      catalogId: product.catalogId,
      productAttributes: product.productAttributes,
      productVariations: product.productVariations,
    );
    _upsertProductInMemory(updated);
    try {
      await repository.saveProduct(updated, isNew: false);
      _toastSuccess(
        isFeatured ? 'Đã ghim lên tab Nổi bật' : 'Đã gỡ khỏi tab Nổi bật',
        isFeatured
            ? '"${product.title}" đã hiển thị trên tab Nổi bật của ứng dụng.'
            : '"${product.title}" chỉ hiển thị khi khách hàng tương tác mẫu cùng gu.',
      );
      return true;
    } catch (e) {
      _upsertProductInMemory(product);
      _toastError('Lỗi cập nhật Nổi bật', e.toString());
      return false;
    }
  }

  Future<bool> assignVideosToProduct({
    required ProductModel product,
    required List<String> videoUrls,
    List<Map<String, dynamic>>? videoSources,
    bool makeFeatured = true,
  }) async {
    final cleaned = videoUrls
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .toSet()
        .toList();
    final updated = ProductModel(
      id: product.id,
      title: product.title,
      stock: product.stock,
      price: product.price,
      salePrice: product.salePrice,
      thumbnail: product.thumbnail,
      images: product.images,
      videos: cleaned,
      videoSources: videoSources ?? product.videoSources,
      description: product.description,
      productType: product.productType,
      isFeatured: makeFeatured ? true : product.isFeatured,
      isDiscontinued: product.isDiscontinued,
      brand: product.brand,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      catalogId: product.catalogId,
      productAttributes: product.productAttributes,
      productVariations: product.productVariations,
    );
    return saveProduct(updated, isNew: false);
  }

  void _applyVideoCommentReplyLocal(
    AdminVideoCommentRecord record,
    String replyText,
  ) {
    final idx = videoComments.indexWhere(
      (c) => c.productId == record.productId && c.id == record.id,
    );
    if (idx < 0) return;
    videoComments[idx] = AdminVideoCommentRecord(
      id: record.id,
      productId: record.productId,
      productTitle: record.productTitle,
      productThumbnail: record.productThumbnail,
      categoryId: record.categoryId,
      categoryName: record.categoryName,
      userId: record.userId,
      authorName: record.authorName,
      text: record.text,
      videoUrl: record.videoUrl,
      createdAt: record.createdAt,
      adminReply: replyText.trim(),
      adminReplyAt: DateTime.now(),
    );
  }

  Future<bool> replyToVideoComment(
      AdminVideoCommentRecord record, String replyText) async {
    _applyVideoCommentReplyLocal(record, replyText);
    try {
      await repository.replyToVideoComment(record, replyText);
      _toastSuccess(
        'Đã trả lời bình luận video',
        'Phản hồi đã hiển thị trên video "${record.productTitle}" và báo tới ${record.authorName}.',
      );
      return true;
    } catch (e) {
      _toastError('Lỗi trả lời bình luận', e.toString());
      return false;
    }
  }

  Future<bool> autoReplySingleVideoComment(
      AdminVideoCommentRecord record) async {
    final text = automation.value.renderVideoCommentReply(
      authorName: record.authorName,
      productTitle: record.productTitle,
      categoryName: record.categoryName,
    );
    return replyToVideoComment(record, text);
  }

  Future<int> autoReplyAllUnrepliedVideoComments() async {
    final pending = videoComments.where((c) => !c.hasAdminReply).toList();
    if (pending.isEmpty) {
      _toastSuccess(
        'Không còn bình luận chờ',
        'Tất cả bình luận trên tab Nổi bật đều đã được phản hồi.',
      );
      return 0;
    }
    try {
      await Future.wait(pending.map((rec) async {
        final text = automation.value.renderVideoCommentReply(
          authorName: rec.authorName,
          productTitle: rec.productTitle,
          categoryName: rec.categoryName,
        );
        _applyVideoCommentReplyLocal(rec, text);
        await repository.replyToVideoComment(rec, text);
      }));
      final count = pending.length;
      _toastSuccess(
        'Đã tự động trả lời $count bình luận video',
        'Toàn bộ phản hồi theo mẫu tự động đã gửi tới khách hàng.',
      );
      return count;
    } catch (e) {
      _toastError('Lỗi trả lời tự động', e.toString());
      return 0;
    }
  }

  Future<void> deleteVideoComment(AdminVideoCommentRecord record) async {
    try {
      await repository.deleteVideoComment(record.productId, record.id);
      videoComments.removeWhere(
        (c) => c.productId == record.productId && c.id == record.id,
      );
      _toastSuccess('Đã xóa bình luận', 'Bình luận trên video đã được gỡ.');
    } catch (e) {
      _toastError('Lỗi xóa bình luận', e.toString());
    }
  }

  Future<bool> pushSimilarProductsToUser({
    required String userId,
    required String userName,
    required ProductModel watchedProduct,
    required List<ProductModel> similarProducts,
    String? customBodyVi,
  }) async {
    if (similarProducts.isEmpty) {
      _toastError('Chưa chọn sản phẩm', 'Hãy chọn ít nhất 1 sản phẩm tương tự để gợi ý.');
      return false;
    }
    try {
      final simTitles = similarProducts.map((p) => p.title).join(', ');
      final bodyVi = (customBodyVi != null && customBodyVi.trim().isNotEmpty)
          ? customBodyVi.trim()
          : automation.value.renderVideoSimilarPush(
              userName: userName,
              watchedProductTitle: watchedProduct.title,
              similarProductTitles: simTitles,
              categoryName: watchedProduct.categoryName,
            );
      await repository.pushSimilarProductsToUser(
        userId: userId,
        userName: userName,
        watchedProduct: watchedProduct,
        similarProducts: similarProducts,
        bodyVi: bodyVi,
      );
      _prependCampaignLogLocal(
        titleVi: 'Gợi ý tương tự ${watchedProduct.title}: ${similarProducts.first.title}',
        bodyVi: bodyVi,
        kind: 'product',
        targetId: similarProducts.first.id,
        audienceLabel: 'Đẩy ${similarProducts.length} sản phẩm tương tự tới $userName',
        recipientCount: 1,
      );
      _toastSuccess(
        'Đã tung ${similarProducts.length} sản phẩm tương tự tới $userName',
        'Các mẫu ($simTitles) đã được mở khóa trên tab Nổi bật & gửi thông báo tới $userName.',
      );
      return true;
    } catch (e) {
      _toastError('Lỗi đẩy sản phẩm tương tự', e.toString());
      return false;
    }
  }

  Future<int> autoPushSimilarProductsForAllVideoInteractions() async {
    final targets = <String, ({String userId, String userName, ProductModel product})>{};

    // 1. From UserInterests (video_like / video_comment)
    for (final interest in userInterests) {
      if (interest.userId.isEmpty) continue;
      ProductModel? watched;
      if (interest.lastProductId.isNotEmpty) {
        watched = products.firstWhereOrNull((p) => p.id == interest.lastProductId);
      }
      if (watched == null && interest.interestedCategoryIds.isNotEmpty) {
        final cid = interest.interestedCategoryIds.first;
        watched = products.firstWhereOrNull((p) => p.categoryId == cid);
      }
      watched ??= products.firstOrNull;
      if (watched != null) {
        targets[interest.userId] = (
          userId: interest.userId,
          userName: interest.userName,
          product: watched,
        );
      }
    }

    // 2. From VideoComments
    for (final c in videoComments) {
      if (c.userId.isEmpty || targets.containsKey(c.userId)) continue;
      final watched = products.firstWhereOrNull((p) => p.id == c.productId) ??
          products.firstOrNull;
      if (watched != null) {
        targets[c.userId] = (
          userId: c.userId,
          userName: c.authorName,
          product: watched,
        );
      }
    }

    if (targets.isEmpty) {
      _toastSuccess(
        'Chưa có lượt tương tác mới',
        'Khi khách thả tim hoặc bình luận video, hệ thống sẽ tự động đẩy sản phẩm tương tự.',
      );
      return 0;
    }

    var count = 0;
    try {
      await Future.wait(targets.values.map((entry) async {
        final sims = similarProductsFor(entry.product, limit: 3);
        if (sims.isEmpty) return;
        final simTitles = sims.map((p) => p.title).join(', ');
        final bodyVi = automation.value.renderVideoSimilarPush(
          userName: entry.userName,
          watchedProductTitle: entry.product.title,
          similarProductTitles: simTitles,
          categoryName: entry.product.categoryName,
        );
        await repository.pushSimilarProductsToUser(
          userId: entry.userId,
          userName: entry.userName,
          watchedProduct: entry.product,
          similarProducts: sims,
          bodyVi: bodyVi,
        );
        count++;
      }));
      _toastSuccess(
        'Đã tự động đẩy sản phẩm tương tự cho $count khách hàng',
        'Mỗi khách hàng đã được mở khóa 3 mẫu giày cùng gu trên tab Nổi bật kèm thông báo.',
      );
    } catch (e) {
      _toastError('Lỗi tự động đẩy sản phẩm', e.toString());
    }
    return count;
  }

  void _upsertVoucherLocal(AdminVoucherRecord voucher) {
    final code = voucher.code.trim().toUpperCase();
    final normalized = AdminVoucherRecord(
      code: code,
      title: voucher.title,
      expires: voucher.expires,
      percent: voucher.percent,
      maxUsd: voucher.maxUsd,
      minUsd: voucher.minUsd,
      shipping: voucher.shipping,
      active: voucher.active,
      targetAudience: voucher.targetAudience,
      targetUserIds: voucher.targetUserIds,
      excludeBomHang: voucher.excludeBomHang,
      autoTag: voucher.autoTag,
      createdAt: voucher.createdAt ?? DateTime.now(),
    );
    final idx = vouchers.indexWhere((v) => v.code.toUpperCase() == code);
    if (idx >= 0) {
      vouchers[idx] = normalized;
    } else {
      vouchers.insert(0, normalized);
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
      _upsertVoucherLocal(voucher);
      await repository.saveVoucher(
        voucher,
        isNew: isNew,
        recipients: recipients,
        sendNotification: sendNotification,
      );
      if (sendNotification && voucher.active && recipients.isNotEmpty) {
        final code = voucher.code.trim().toUpperCase();
        _prependCampaignLogLocal(
          titleVi: 'Mã giảm giá mới: $code',
          bodyVi: voucher.title,
          kind: 'voucher',
          targetId: code,
          audienceLabel:
              'Voucher $code • ${voucher.audienceSummary} (${recipients.length})',
          recipientCount: recipients.length,
        );
      }
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
    final idx = vouchers.indexWhere((v) => v.code == record.code);
    if (idx >= 0) {
      vouchers[idx] = AdminVoucherRecord(
        code: record.code,
        title: record.title,
        expires: record.expires,
        percent: record.percent,
        maxUsd: record.maxUsd,
        minUsd: record.minUsd,
        shipping: record.shipping,
        active: active,
        targetAudience: record.targetAudience,
        targetUserIds: record.targetUserIds,
        excludeBomHang: record.excludeBomHang,
        autoTag: record.autoTag,
        createdAt: record.createdAt,
      );
    }
    try {
      await repository.toggleVoucherActive(record.code, active);
    } catch (e) {
      if (idx >= 0 && idx < vouchers.length) vouchers[idx] = record;
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
      _prependCampaignLogLocal(
        titleVi: titleVi.trim(),
        titleEn: titleEn.trim(),
        bodyVi: bodyVi.trim(),
        bodyEn: bodyEn.trim(),
        kind: kind,
        targetId: targetId,
        audienceLabel: audienceLabel,
        recipientCount: count,
      );
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
