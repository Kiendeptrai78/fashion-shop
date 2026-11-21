import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:fashion_business_app/utils/localization/shop_translations.dart';
import 'package:fashion_business_app/utils/local_storage/local_utility.dart';
import 'package:fashion_business_app/features/personalization/models_shopper_preferences.dart';
import 'package:fashion_business_app/common/widgets/product/product_carts/product_price_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  var serial = 0;
  Future<GetStorage> storage(String prefix) async {
    final name = '$prefix-${serial++}';
    final box = GetStorage(name, temp.path);
    await box.initStorage;
    return box;
  }
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('shop-locale-test-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'), (call) async => temp.path);
  });
  tearDown(() { Get.reset(); });

  test('VND uses requested fixed rate; formatting never changes base USD', () {
    expect(formatShopMoney(110, language: 'vi'), '2.839.320 ₫');
    expect(formatShopMoney(117, language: 'vi'), '3.020.004 ₫');
    expect(formatShopMoney(127.5, language: 'vi'), '3.291.030 ₫');
    expect(formatShopMoney(110, language: 'en'), '\$110.00');
    expect(formatShopPrice('100 - 110', language: 'vi'), '2.581.200 ₫ – 2.839.320 ₫');
    expect(shopTranslate('24 products · Page 2'), '24 sản phẩm · Trang 2');
    expect(shopTranslate('Color: White / Blue · Size: 42'), 'Màu: Trắng / Xanh dương · Cỡ: 42');
  });

  test('language defaults to Vietnamese and survives controller recreation', () async {
    final box = await storage('locale');
    final locale = ShopLocale(box);
    expect(locale.language, 'vi');
    await box.write('language', 'en');
    expect(ShopLocale(box).language, 'en');
  });

  test('completion, optional age and category IDs stay isolated by account', () async {
    final firstName = 'account-a-${serial++}';
    final secondName = 'account-b-${serial++}';
    await GetStorage(firstName, temp.path).initStorage;
    await GetStorage(secondName, temp.path).initStorage;
    await TLocalStorage.init(firstName);
    expect(ShopperPreferences.load().completed, isFalse);
    await const ShopperPreferences(completed: true, ageGroup: '25_34',
        categoryIds: ['running-id']).save();
    await TLocalStorage.init(secondName);
    expect(ShopperPreferences.load().completed, isFalse);
    expect(ShopperPreferences.load().categoryIds, isEmpty);
    await TLocalStorage.init(firstName);
    expect(ShopperPreferences.load().completed, isTrue);
    expect(ShopperPreferences.load().ageGroup, '25_34');
    expect(ShopperPreferences.load().categoryIds, ['running-id']);
  });

  test('preference model keeps IDs and handles missing optional age', () {
    final saved = ShopperPreferences.fromJson({'completed': true,
      'categoryIds': ['running-id', 'court-id', 'running-id']});
    expect(saved.ageGroup, 'unspecified');
    expect(saved.categoryIds, ['running-id', 'court-id']);
    final restored = ShopperPreferences.fromJson(saved.toJson());
    expect(restored.completed, isTrue);
    expect(restored.categoryIds, saved.categoryIds);
  });

  testWidgets('changing locale updates const labels and currency immediately', (tester) async {
    final box = await tester.runAsync(() => storage('live-locale'));
    final locale = Get.put(ShopLocale(box!));
    await tester.pumpWidget(GetMaterialApp(locale: const Locale('vi'),
      translations: ShopTranslations(), supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const Scaffold(body: Column(children: [ShopText('Cart'), TProductPriceText(price: '110')]))));
    await tester.pumpAndSettle();
    expect(find.text('Giỏ hàng'), findsOneWidget);
    expect(find.text('2.839.320 ₫'), findsOneWidget);
    locale.change('en');
    await tester.pumpAndSettle();
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('\$110.00'), findsOneWidget);
  });
}
