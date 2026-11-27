import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/product/badges/shop_count_badge.dart';
import 'package:fashion_business_app/common/widgets/product/badges/shop_status_badge.dart';
import 'package:fashion_business_app/common/widgets/tabs/shop_filter_tab.dart';
import 'package:fashion_business_app/features/personalization/services/account_activity.dart';
import 'package:fashion_business_app/features/shop/models/cart_item_model.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/features/shop/models/return_request_model.dart';
import 'package:fashion_business_app/features/shop/screens/order/order.dart';
import 'package:fashion_business_app/features/shop/screens/order/return_request_screen.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/localization/shop_translations.dart';
import 'package:fashion_business_app/utils/theme/theme.dart';

class _Activity extends GetxController implements AccountActivity {
  @override
  final counts = {'pending': 1, 'shipped': 1, 'received': 1}.obs;
  @override
  int get orderCount => counts.values.fold(0, (total, value) => total + value);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final orders = [
  for (final (index, status) in [OrderStatus.pending, OrderStatus.shipped, OrderStatus.received].indexed)
    OrderModel(id: 'VL2026${501 + index}', status: status, totalAmount: 96,
      orderDate: DateTime(2026, 11, 25 - index, 9, 30),
      deliveryDate: DateTime(2026, 11, 28), discountAmount: 10, couponCode: 'WELCOME10 + SHIPNEW',
      items: [CartItemModel(productId: 'shoe-$index', title: ['VELORA AeroPulse R1',
        'VELORA CourtLine Classic', 'VELORA AeroMesh Zero'][index], price: 96, quantity: 1,
        selectedVariation: {'Màu': 'Xanh rừng / Kem', 'EU': '41'})]),
];

ReturnRequestModel request(ReturnRequestStatus status, {int index = 0}) => ReturnRequestModel(
  id: 'RET-VL${24051 + index}', orderId: 'VL2026501', userId: 'preview', customerName: 'Khách hàng',
  productId: 'shoe', productTitle: index == 0 ? 'VELORA AeroPulse R1' : 'VELORA CourtLine Classic',
  refundAmountUsd: 96, type: ReturnRequestType.exchangeSize,
  reasonCategory: 'Kích cỡ chưa phù hợp', description: 'Mình muốn đổi từ EU 40 sang EU 41.',
  currentVariation: 'Xanh rừng / Kem · EU 40', requestedSizeOrColor: 'EU 41',
  pickupAddress: '12 Duy Tân, Hà Nội', status: status,
  adminResponse: index == 0 ? 'VELORA đã nhận sản phẩm. Bộ phận hỗ trợ đang kiểm tra yêu cầu đổi size của bạn.' : '',
  createdAt: DateTime(2026, 11, 25 - index, 10, 15),
);

Widget app(Widget home, {String language = 'vi', double textScale = 1}) =>
    RepaintBoundary(key: const ValueKey('preview'), child: GetMaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(language), translations: ShopTranslations(), theme: TAppTheme.lightTheme,
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale)),
        child: ShopGlassBackground(child: child!)), home: home));

Future<void> preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('ORDER_UI_PREVIEWS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('preview')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/test-previews/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('BeVietnamPro');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$weight.ttf'));
    }
    await loader.load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')
      ..addFont(rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'))).load();
    await (FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('packages/iconsax/iconsax')
      ..addFont(rootBundle.load('packages/iconsax/lib/assets/fonts/iconsax.ttf'))).load();
  });
  tearDown(() => Get.reset());

  testWidgets('orders use shared red counts and filter real rows', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.put<AccountActivity>(_Activity());
    tester.view.padding = const FakeViewPadding(top: 62);
    tester.view.viewPadding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await tester.pumpWidget(app(OrderScreen(loadOrders: () async => orders)));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(ShopFilterTabs)).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.byType(TAppbar)).dy));
    expect(find.byType(ShopStatusBadge), findsNWidgets(3));
    for (final order in orders) {
      final title = find.text(order.items.first.title);
      expect(find.ancestor(of: title, matching: find.byType(Opacity)), findsNothing);
      expect(tester.widget<Text>(title).style?.decoration, isNot(TextDecoration.lineThrough));
    }
    expect(find.byType(ShopCountBadge), findsWidgets);
    for (final badge in tester.widgetList<Badge>(find.byType(Badge))) {
      expect(badge.backgroundColor, const Color(0xFFD92D3E));
    }
    await preview(tester, 'velora-orders');
    final pending = find.byWidgetPredicate(
      (widget) => widget is ShopFilterTab && widget.label == 'Pending');
    await Scrollable.ensureVisible(tester.element(pending.first), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(pending.hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.text('VELORA AeroPulse R1'), findsOneWidget);
    expect(find.text('VELORA CourtLine Classic'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('returns share filters and readable tracking cards', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final records = [request(ReturnRequestStatus.inspecting),
      request(ReturnRequestStatus.pending, index: 1), request(ReturnRequestStatus.completed, index: 2)];
    tester.view.padding = const FakeViewPadding(top: 62);
    tester.view.viewPadding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await tester.pumpWidget(app(MyReturnRequestsScreen(requests: Stream.value(records))));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(ShopFilterTabs)).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.byType(TAppbar)).dy));
    expect(find.byType(ShopFilterTab), findsWidgets);
    expect(find.byType(ShopStatusBadge), findsWidgets);
    expect(find.text('Đang kiểm tra'), findsOneWidget);
    await preview(tester, 'velora-returns');
    await tester.tap(find.byWidgetPredicate(
      (widget) => widget is ShopFilterTab && widget.label == 'Chờ duyệt').hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.text('RET-VL24052'), findsOneWidget);
    expect(find.text('RET-VL24051'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('order and return layouts fit small phones with larger Vietnamese and English text', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final language in ['vi', 'en']) {
      await tester.pumpWidget(app(OrderScreen(key: UniqueKey(), loadOrders: () async => orders),
        language: language, textScale: 1.3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(app(OrderScreen(key: UniqueKey(), loadOrders: () async => [orders.last]),
        language: language, textScale: 1.3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(app(MyReturnRequestsScreen(key: UniqueKey(),
        requests: Stream.value([request(ReturnRequestStatus.approvedPickup)])),
        language: language, textScale: 1.3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    for (final status in ReturnRequestStatus.values) {
      await tester.pumpWidget(app(Scaffold(body: SingleChildScrollView(child:
        ReturnRequestTrackingCard(request: request(status)))), textScale: 1.3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('status text has readable contrast on every semantic surface', (tester) async {
    for (final tone in ShopStatusTone.values) {
      await tester.pumpWidget(app(Scaffold(body: ShopStatusBadge(label: 'Trạng thái', tone: tone))));
      final text = tester.widget<Text>(find.text('Trạng thái'));
      final container = tester.widget<Container>(find.descendant(
        of: find.byType(ShopStatusBadge), matching: find.byType(Container)).first);
      final foreground = text.style!.color!.computeLuminance();
      final background = (container.decoration! as BoxDecoration).color!.computeLuminance();
      final ratio = foreground > background
          ? (foreground + 0.05) / (background + 0.05)
          : (background + 0.05) / (foreground + 0.05);
      expect(ratio, greaterThanOrEqualTo(4.5), reason: tone.name);
    }
  });
}
