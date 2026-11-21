import 'dart:typed_data';

import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/data/admin_web_models.dart';
import 'package:fashion_business_app/admin/web/data/admin_web_repository.dart';
import 'package:fashion_business_app/admin/web/screens/admin_login_web_screen.dart';
import 'package:fashion_business_app/admin/web/views/banners_view.dart';
import 'package:fashion_business_app/admin/web/views/brands_view.dart';
import 'package:fashion_business_app/admin/web/views/categories_view.dart';
import 'package:fashion_business_app/admin/web/views/dashboard_view.dart';
import 'package:fashion_business_app/admin/web/views/finance_view.dart';
import 'package:fashion_business_app/admin/web/views/notifications_view.dart';
import 'package:fashion_business_app/admin/web/views/orders_view.dart';
import 'package:fashion_business_app/admin/web/views/products_view.dart';
import 'package:fashion_business_app/admin/web/views/reviews_view.dart';
import 'package:fashion_business_app/admin/web/views/users_view.dart';
import 'package:fashion_business_app/admin/web/views/vouchers_view.dart';
import 'package:fashion_business_app/features/authentication/models/user_model.dart';
import 'package:fashion_business_app/features/personalization/models/address_model.dart';
import 'package:fashion_business_app/features/shop/models/banner_model.dart';
import 'package:fashion_business_app/features/shop/models/brand_model.dart';
import 'package:fashion_business_app/features/shop/models/cart_item_model.dart';
import 'package:fashion_business_app/features/shop/models/category_model.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/models/product_review_model.dart';
import 'package:fashion_business_app/utils/constants/admin_config.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeAdminWebRepository implements AdminWebRepository {
  final _brand = BrandModel(
    id: 'sneaker-brand-nike',
    name: 'Nike',
    image: '',
    isFeatured: true,
    productsCount: 1,
  );
  final _category = CategoryModel(
    id: 'sneaker-category-running',
    name: 'Running',
    image: '',
    isFeatured: true,
  );

  @override
  Future<List<ProductModel>> fetchProducts() async => [
        ProductModel(
          id: 'p1',
          title: 'Air Force 1',
          stock: 5,
          price: 110,
          salePrice: 95,
          thumbnail: '',
          productType: ProductType.variable.toString(),
          isFeatured: true,
          brand: _brand,
          categoryId: _category.id,
          categoryName: _category.name,
        ),
      ];

  @override
  Future<List<BrandModel>> fetchBrands() async => [_brand];

  @override
  Future<List<CategoryModel>> fetchCategories() async => [_category];

  @override
  Future<List<AdminBannerRecord>> fetchBanners() async => [
        AdminBannerRecord(
          docId: 'b1',
          banner: BannerModel(
            imageUrl: '',
            targetScreen: '/all-products',
            active: true,
            title: 'Made to move.',
            subtitle: 'Explore running',
            sortOrder: 0,
            categoryId: _category.id,
          ),
        ),
      ];

  @override
  Future<List<UserModel>> fetchUsers() async => [
        UserModel(
          id: 'admin-1',
          email: AdminConfig.adminEmail,
          firstName: 'Tinh',
          lastName: 'Phan',
          username: 'ADMIN',
          phoneNumber: '0901234567',
          profilePicture: '',
          role: 'Admin',
        ),
        UserModel(
          id: 'user-1',
          email: 'customer@example.com',
          firstName: 'Lan',
          lastName: 'Nguyen',
          username: 'LANNGUYEN',
          phoneNumber: '0909876543',
          profilePicture: '',
          role: 'Client',
        ),
      ];

  @override
  Future<List<AdminOrderRecord>> fetchAllOrders(List<UserModel> users) async => [
        AdminOrderRecord(
          docId: 'order-doc-1',
          userId: 'user-1',
          customer: users.last,
          order: OrderModel(
            id: 'ORD-1001',
            userId: 'user-1',
            status: OrderStatus.received,
            totalAmount: 110,
            orderDate: DateTime(2026, 11, 15),
            deliveryDate: DateTime(2026, 11, 18),
            paymentMethod: 'COD',
            items: [
              CartItemModel(
                productId: 'p1',
                title: 'Air Force 1',
                price: 110,
                quantity: 1,
              ),
            ],
          ),
        ),
      ];

  @override
  Future<List<AdminReviewRecord>> fetchAllReviews(
          List<ProductModel> products) async =>
      [
        AdminReviewRecord(
          productId: 'p1',
          productTitle: 'Air Force 1',
          productThumbnail: '',
          purchaseOrderId: 'ORD-1001',
          review: ProductReviewEntry(
            id: 'user-1',
            authorName: 'Lan Nguyen',
            rating: 5,
            text: 'Giày đi rất êm và đúng form!',
            createdAt: DateTime(2026, 11, 19),
          ),
        ),
      ];

  @override
  Future<List<AdminNotificationCampaign>> fetchNotificationCampaigns() async => [
        AdminNotificationCampaign(
          id: 'camp-1',
          titleVi: 'Flash Sale cuối tuần',
          bodyVi: 'Giảm 20% toàn bộ bộ sưu tập Nike.',
          titleEn: 'Weekend Flash Sale',
          bodyEn: '20% off all Nike.',
          kind: 'promo',
          targetId: '',
          audienceLabel: 'Tất cả khách hàng (1)',
          recipientCount: 1,
          createdAt: DateTime(2026, 11, 20),
        ),
      ];

  @override
  Future<List<AdminVoucherRecord>> fetchVouchers() async => [
        AdminVoucherRecord(
          code: 'VELORA20',
          title: 'Ưu đãi 20% cuối tuần',
          percent: 20,
          maxUsd: 25,
          minUsd: 50,
          active: true,
          expires: DateTime(2027, 1, 1),
        ),
      ];

  @override
  Future<int> fetchEnabledPushDevicesCount(List<UserModel> users) async => 2;

  @override
  Future<List<AdminUserInterest>> fetchUserInterests() async => [
        AdminUserInterest(
          userId: 'user-1',
          userName: 'Lan Nguyen',
          userEmail: 'customer@example.com',
          lastQuery: 'Tìm giày chạy bộ Nike dưới 3 triệu',
          interestedBrands: const ['Nike'],
          interestedCategories: const ['Running'],
          interestedCategoryIds: const ['sneaker-category-running'],
          queryCount: 3,
          updatedAt: DateTime(2026, 11, 21),
        ),
      ];

  @override
  Future<List<AdminStockReceipt>> fetchStockReceipts() async => [
        AdminStockReceipt(
          id: 'rcpt-1',
          productId: 'p1',
          productTitle: 'Air Force 1',
          addedQuantity: 20,
          previousStock: 5,
          newStock: 25,
          supplier: 'Kho Tổng VELORA',
          note: 'Nhập bổ sung đợt cuối tháng',
          createdAt: DateTime(2026, 11, 21),
        ),
      ];

  @override
  Future<AdminAutomationSettings> fetchAutomationSettings() async =>
      AdminAutomationSettings.defaults();

  @override
  Future<List<AddressModel>> fetchUserAddresses(String userId) async => [];

  @override
  Future<String> uploadImage(Uint8List bytes, String filename, String folder) async =>
      'https://example.com/$filename';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(() => Get.reset());

  test('AdminConfig strictly distinguishes admin email vs regular customer emails', () {
    expect(AdminConfig.isAdminEmail('phanviettinh150402@gmail.com'), isTrue);
    expect(AdminConfig.isAdminEmail('  PHANVIETTINH150402@GMAIL.COM  '), isTrue);
    expect(AdminConfig.roleForEmail('phanviettinh150402@gmail.com'), 'Admin');

    expect(AdminConfig.isAdminEmail('someoneelse@gmail.com'), isFalse);
    expect(AdminConfig.isAdminEmail('admin@gmail.com'), isFalse);
    expect(AdminConfig.isAdminEmail(''), isFalse);
    expect(AdminConfig.roleForEmail('customer@example.com'), 'Client');
  });

  testWidgets('AdminLoginWebScreen renders desktop layout and blocks non-admin emails',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const GetMaterialApp(home: AdminLoginWebScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập quản trị'), findsOneWidget);
    expect(find.text('VELORA'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'user@gmail.com');
    await tester.enterText(find.byType(TextFormField).last, 'SomePassword123');
    await tester.tap(find.text('Đăng nhập bảng điều khiển'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Email này là tài khoản khách hàng'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('All 9 Admin Web views render cleanly without layout exceptions',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = Get.put(AdminWebController(repository: _FakeAdminWebRepository()));
    await controller.loadAll();

    final views = <Widget>[
      AdminDashboardView(controller: controller),
      AdminFinanceView(controller: controller),
      AdminOrdersView(controller: controller),
      AdminProductsView(controller: controller),
      AdminVouchersView(controller: controller),
      AdminBrandsView(controller: controller),
      AdminCategoriesView(controller: controller),
      AdminBannersView(controller: controller),
      AdminUsersView(controller: controller),
      AdminReviewsView(controller: controller),
      AdminNotificationsView(controller: controller),
    ];

    for (final view in views) {
      await tester.pumpWidget(GetMaterialApp(home: Scaffold(body: view)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
