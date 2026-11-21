import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/features/personalization/screens/account/demo_bank_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/account/coupons_screen.dart';
import 'package:fashion_business_app/utils/localization/shop_translations.dart';

void main() {
  late CustomerBenefits benefits;
  setUp(() async {
    Map<String, dynamic>? saved;
    benefits = Get.put(CustomerBenefits(read: () => saved,
        write: (data) async { saved = data; }, now: () => DateTime(2026, 11, 20, 12)));
    await benefits.initialize();
  });
  tearDown(() => Get.reset());

  Widget app(Widget home) => GetMaterialApp(locale: const Locale('vi'), translations: ShopTranslations(),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates, home: home);

  testWidgets('demo bank is readable on a small phone and top-up updates the balance', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const DemoBankScreen()));
    await tester.pumpAndSettle();
    expect(find.text('10.000.000 ₫'), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Xác nhận nạp'));
    await tester.pumpAndSettle();
    expect(find.text('20.000.000 ₫'), findsOneWidget);
    expect(benefits.ledger.length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkout coupon picker returns an eligible welcome code', (tester) async {
    ShopCoupon? selected;
    await tester.pumpWidget(app(Scaffold(body: Builder(builder: (context) => TextButton(
      onPressed: () async { selected = await Get.to<ShopCoupon>(() => const CouponsScreen(subtotal: 110)); },
      child: const Text('Choose'),
    )))));
    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    expect(find.text('WELCOME10'), findsOneWidget);
    final apply = find.widgetWithText(OutlinedButton, 'Áp dụng').first;
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();
    expect(selected?.id, 'WELCOME10');
    expect(tester.takeException(), isNull);
  });
}
