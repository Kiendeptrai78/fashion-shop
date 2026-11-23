import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/features/personalization/models/address_model.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/features/personalization/screens/account/demo_bank_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/account/coupons_screen.dart';
import 'package:fashion_business_app/features/shop/models/shipping_route_helper.dart';
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

  test('Vietnam province shipping distances from Hanoi warehouse are accurate', () {
    final cauGiay = ShippingRouteHelper.estimateForAddress(AddressModel(
      id: '1', name: 'A', phoneNumber: '0900000000',
      street: '12 Xuan Thuy', city: 'Hà Nội', state: 'Quận Cầu Giấy', country: 'Việt Nam',
    ));
    expect(cauGiay.distanceKm, lessThanOrEqualTo(10));
    expect(cauGiay.maxDays, 2);

    final bacNinh = ShippingRouteHelper.estimateFromRawText('Bắc Ninh');
    expect(bacNinh.destinationCity, 'Bắc Ninh');
    expect(bacNinh.distanceKm, inInclusiveRange(35, 55));

    final vinhPhuc = ShippingRouteHelper.estimateFromRawText('Vĩnh Phúc');
    expect(vinhPhuc.destinationCity, 'Vĩnh Phúc');
    expect(vinhPhuc.distanceKm, inInclusiveRange(35, 60));

    final haiPhong = ShippingRouteHelper.estimateFromRawText('Hải Phòng');
    expect(haiPhong.distanceKm, inInclusiveRange(105, 135));

    final thanhHoa = ShippingRouteHelper.estimateFromRawText('Thanh Hóa');
    expect(thanhHoa.distanceKm, inInclusiveRange(150, 190));

    final hueWithHanoiStreet = ShippingRouteHelper.estimateForAddress(AddressModel(
      id: '2', name: 'B', phoneNumber: '0900000000',
      street: 'Số 10 Đường Hà Nội', city: 'Thừa Thiên Huế', state: 'TP. Huế', country: 'Việt Nam',
    ));
    expect(hueWithHanoiStreet.destinationCity, 'Thừa Thiên Huế');
    expect(hueWithHanoiStreet.distanceKm, inInclusiveRange(640, 740));

    final daNang = ShippingRouteHelper.estimateFromRawText('Đà Nẵng');
    expect(daNang.distanceKm, inInclusiveRange(720, 810));

    final quangNam = ShippingRouteHelper.estimateFromRawText('Quảng Nam');
    expect(quangNam.destinationCity, 'Quảng Nam');
    expect(quangNam.distanceKm, inInclusiveRange(800, 900));

    final binhDinh = ShippingRouteHelper.estimateFromRawText('Bình Định');
    expect(binhDinh.destinationCity, 'Bình Định');
    expect(binhDinh.distanceKm, inInclusiveRange(1000, 1180));

    final hcm = ShippingRouteHelper.estimateFromRawText('TP. Hồ Chí Minh');
    expect(hcm.distanceKm, inInclusiveRange(1620, 1780));
    expect(hcm.maxDays, 5);

    final longAn = ShippingRouteHelper.estimateFromRawText('Long An');
    expect(longAn.destinationCity, 'Long An');
    expect(longAn.distanceKm, inInclusiveRange(1660, 1840));

    final canTho = ShippingRouteHelper.estimateFromRawText('Cần Thơ');
    expect(canTho.destinationCity, 'Cần Thơ');
    expect(canTho.distanceKm, inInclusiveRange(1780, 1940));

    final kienGiang = ShippingRouteHelper.estimateFromRawText('Kiên Giang');
    expect(kienGiang.destinationCity, 'Kiên Giang');
    expect(kienGiang.distanceKm, inInclusiveRange(1860, 2060));

    // Province-to-province helper
    final dnToHcm = ShippingRouteHelper.distanceBetweenProvinces('Đà Nẵng', 'TP. Hồ Chí Minh');
    expect(dnToHcm, inInclusiveRange(860, 1020));
    final hcmToCanTho = ShippingRouteHelper.distanceBetweenProvinces('TP. Hồ Chí Minh', 'Cần Thơ');
    expect(hcmToCanTho, inInclusiveRange(145, 195));
  });
}
