import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/common/widgets/glass/shop_overlays.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:fashion_business_app/features/personalization/screens/settings/setting_screen.dart';
import 'order_returns_ui_test.dart' show app, preview;

void main() {
  testWidgets('borderless sheet removes both the material outline and glass rim', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (context) =>
      TextButton(onPressed: () => showShopBottomSheet<void>(context: context, borderless: true,
        builder: (_) => const Padding(padding: EdgeInsets.all(24), child: Text('Comments'))),
        child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(GlassContainer), findsNothing);
    expect((tester.widget<BottomSheet>(find.byType(BottomSheet)).shape as RoundedRectangleBorder).side,
      BorderSide.none);
    expect(tester.takeException(), isNull);
  });
  setUpAll(() async {
    final font = FontLoader('BeVietnamPro');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$weight.ttf'));
    }
    await font.load();
    await (FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('packages/iconsax/iconsax')
      ..addFont(rootBundle.load('packages/iconsax/lib/assets/fonts/iconsax.ttf'))).load();
  });

  testWidgets('the account language picker uses the shared glass sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const SettingScreen()));
    await tester.pumpAndSettle();
    final language = find.text('Ngôn ngữ & Tiền tệ');
    await Scrollable.ensureVisible(tester.element(language), alignment: 0.5);
    await tester.tap(language);
    await tester.pumpAndSettle();
    expect(find.byType(ShopOverlaySurface), findsOneWidget);
    await preview(tester, 'velora-liquid-language-sheet');
    expect(tester.takeException(), isNull);
  });
  testWidgets('glass sheet returns selection and preserves dismissal', (tester) async {
    String? selected;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (context) =>
      TextButton(onPressed: () async {
        selected = await showShopBottomSheet<String>(context: context,
          builder: (sheet) => TextButton(onPressed: () => Navigator.pop(sheet, 'chosen'),
            child: const Text('Choose')));
      }, child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(ShopOverlaySurface), findsOneWidget);
    expect(find.byType(GlassContainer), findsOneWidget);
    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    expect(selected, 'chosen');
    expect(find.byType(ShopOverlaySurface), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrollable glass sheet fits a small screen with the keyboard open', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (context) =>
      TextButton(onPressed: () => showShopBottomSheet<void>(context: context,
        isScrollControlled: true, useSafeArea: true,
        builder: (sheet) => SingleChildScrollView(padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheet).bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const TextField(),
            for (var i = 0; i < 20; i++) Text('Row $i'),
          ]))), child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.byType(ShopOverlaySurface)).bottom, lessThanOrEqualTo(700));
  });
}
