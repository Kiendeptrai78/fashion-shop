import 'package:fashion_business_app/features/shop/models/product_attribute_model.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/models/product_size_guide.dart';
import 'package:fashion_business_app/features/shop/screens/product_details/widgets/product_size_guide_section.dart';
import 'package:fashion_business_app/utils/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'product_options_test.dart' show optionsProduct;

Widget app(Widget child, {String language = 'vi', bool dark = false, double scale = 1}) =>
    MaterialApp(locale: Locale(language), supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: dark ? TAppTheme.darkTheme : TAppTheme.lightTheme,
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale)), child: child!),
      home: Scaffold(body: child));

void main() {
  tearDown(() => Get.reset());

  test('legacy products keep an optional guide; custom measurements round trip', () {
    final product = ProductModel.fromJson({'Title': 'VELORA Court'}, id: 'court');
    expect(product.sizeGuide, isNull);
    expect(product.toJson().containsKey('SizeGuide'), isFalse);
    product.sizeGuide = const ProductSizeGuide(rows: [
      ProductSizeMeasurement(size: '41', footLengthCm: 26.2),
    ], fitNote: 'Form ôm chân', source: 'VELORA');
    final restored = ProductModel.fromJson(product.toJson(), id: product.id).sizeGuide!;
    expect(restored.rows.single.footLengthCm, 26.2);
    expect(restored.fitNote, 'Form ôm chân');
    expect(restored.source, 'VELORA');
    expect(restored.isReference, isFalse);
  });

  testWidgets('inline guide shows offered and sold-out sizes without a button', (tester) async {
    final product = optionsProduct()..title = 'VELORA Court';
    await tester.pumpWidget(app(SingleChildScrollView(child: Padding(
      padding: const EdgeInsets.all(20),
      child: ProductSizeGuideSection(product: product, selectedSize: '41')))));
    expect(find.text('Bảng size tham khảo'), findsOneWidget);
    expect(find.text('Bảng tham khảo chung'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
    expect(find.text('41'), findsOneWidget);
    expect(find.text('25,5'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['vi', 'en']) {
    testWidgets('custom chart overrides reference on narrow $language screen with large text', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final product = optionsProduct()..title = 'VELORA CourtLine Classic'
        ..sizeGuide = const ProductSizeGuide(rows: [
          ProductSizeMeasurement(size: 'EU 41', footLengthCm: 26.2),
        ], fitNote: 'Form ôm chân');
      await tester.pumpWidget(app(SingleChildScrollView(child: Padding(
        padding: const EdgeInsets.all(20),
        child: ProductSizeGuideSection(product: product, selectedSize: '41'))),
        language: language, dark: language == 'en', scale: 1.3));
      expect(find.text(language == 'vi' ? 'Bảng size riêng của mẫu' : 'Product size chart'), findsOneWidget);
      expect(find.text(language == 'vi' ? '26,2' : '26.2'), findsOneWidget);
      expect(find.text(language == 'vi' ? 'Chưa có số đo' : 'Not provided'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Form ôm chân'), 100,
        scrollable: find.byType(Scrollable));
      expect(find.text('Form ôm chân'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('unsupported half sizes do not invent measurements', (tester) async {
    final product = ProductModel.empty()..productAttributes = [
      ProductAttributeModel(name: 'Size', values: ['40.5']),
    ];
    await tester.pumpWidget(app(SingleChildScrollView(child: ProductSizeGuideSection(product: product))));
    expect(find.text('Bảng tham khảo chung'), findsOneWidget);
    expect(find.text('40.5'), findsOneWidget);
    expect(find.text('Chưa có số đo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
