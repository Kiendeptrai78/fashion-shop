import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/common/widgets/list_tiles/loyalty_coins_tile.dart';
import 'package:fashion_business_app/features/shop/models/cart_item_model.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/features/shop/screens/order/order.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/screens/checkout/widgets/billing_amount_section.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'order_returns_ui_test.dart' show app, preview;

class _Cart extends GetxController implements CartController {
  @override
  final totalCartPrice = 110.0.obs;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('BeVietnamPro');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$weight.ttf'));
    }
    await loader.load();
    await (FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('packages/iconsax/iconsax')
      ..addFont(rootBundle.load('packages/iconsax/lib/assets/fonts/iconsax.ttf'))).load();
  });
  tearDown(() => Get.reset());

  testWidgets('list review reminder disappears after all products were reviewed', (tester) async {
    OrderModel order(List<String> reviewed) => OrderModel(id: 'VL2026001', status: OrderStatus.received,
      totalAmount: 110, orderDate: DateTime(2026, 11, 25), deliveryDate: DateTime(2026, 11, 25),
      items: [CartItemModel(productId: 'shoe', title: 'VELORA Court', quantity: 1)],
      reviewedProductIds: reviewed);
    await tester.pumpWidget(app(OrderScreen(loadOrders: () async => [order([])])));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Đánh giá sản phẩm'), findsOneWidget);
    await tester.pumpWidget(app(OrderScreen(key: UniqueKey(), loadOrders: () async => [order(['shoe'])])));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Đánh giá sản phẩm'), findsNothing);
    expect(find.text('Mua lại'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['vi', 'en']) {
    testWidgets('coin tile and toggle fit narrow $language screens with large text', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var enabled = false;
      final content = StatefulBuilder(builder: (context, setState) => SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          const LoyaltyCoinsTile(balance: 1000), const SizedBox(height: 16),
          LoyaltyCoinsTile(balance: 1000, useCoins: enabled,
            onChanged: (value) => setState(() => enabled = value)),
        ]))));
      await tester.pumpWidget(app(Scaffold(body: content), language: language, textScale: 1.3));
      expect(find.byType(GoldCoinIcon), findsNWidgets(2));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(enabled, isTrue);
      if (language == 'vi') await preview(tester, 'velora-coins');
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(enabled, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('billing shows a separate coin discount and keeps VND precision', (tester) async {
    Get.put<CartController>(_Cart());
    await tester.pumpWidget(app(const Scaffold(body: TBillingAmountSection(coinDiscount: 1000 / 25812))));
    expect(find.text('Quy đổi xu'), findsOneWidget);
    expect(find.text('-1.000 ₫'), findsOneWidget);
    expect(find.text('3.019.004 ₫'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
