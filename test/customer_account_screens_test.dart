import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/features/personalization/models/address_model.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/features/personalization/screens/account/demo_bank_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/account/coupons_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/settings/setting_screen.dart';
import 'package:fashion_business_app/features/shop/models/shipping_route_helper.dart';
import 'package:fashion_business_app/features/shop/services/vnpay_sandbox_service.dart';
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
    expect(find.text('•••••••• ₫'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('toggle-wallet-balance-visibility')));
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

  testWidgets('applying both voucher types keeps the picker open until back', (tester) async {
    ShopCoupon? selected;
    await tester.pumpWidget(app(Scaffold(body: Builder(builder: (context) => TextButton(
      onPressed: () async { selected = await Get.to<ShopCoupon>(() => const CouponsScreen(subtotal: 110)); },
      child: const Text('Choose'),
    )))));
    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    expect(find.text('WELCOME10'), findsOneWidget);
    expect(find.text('SHIPNEW'), findsOneWidget);
    expect(find.textContaining('Mã Giảm giá sản phẩm'), findsOneWidget);
    expect(find.textContaining('Mã Miễn phí vận chuyển'), findsOneWidget);
    expect(find.text('Đồng ý'), findsNothing);
    expect(find.text('Đề xuất tốt nhất'), findsWidgets);
    expect(find.text('Đề xuất dùng'), findsWidgets);
    final apply = find.widgetWithText(OutlinedButton, 'Áp dụng').first;
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();
    expect(find.byType(CouponsScreen), findsOneWidget);
    expect(selected, isNull);
    expect(benefits.selectedProductCoupon.value?.id, 'LE-2026-11-20');

    Future<void> applyCode(String code) async {
      final card = find.ancestor(of: find.text(code), matching: find.byType(InkWell)).first;
      final button = find.descendant(of: card, matching: find.byType(OutlinedButton));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(CouponsScreen), findsOneWidget);
    }

    await applyCode('SHIPNEW');
    expect(benefits.selectedShippingCoupon.value?.id, 'SHIPNEW');
    expect(benefits.selectedProductCoupon.value?.id, 'LE-2026-11-20');
    await applyCode('WELCOME10');
    expect(benefits.selectedProductCoupon.value?.id, 'WELCOME10');
    expect(benefits.selectedShippingCoupon.value?.id, 'SHIPNEW');
    expect(find.text('Bỏ áp dụng'), findsNWidgets(2));

    await applyCode('WELCOME10');
    expect(benefits.selectedProductCoupon.value, isNull);
    expect(benefits.selectedShippingCoupon.value?.id, 'SHIPNEW');
    await applyCode('SHIPNEW');
    expect(benefits.selectedShippingCoupon.value, isNull);
    expect(find.text('Bỏ áp dụng'), findsNothing);
    await applyCode('WELCOME10');
    await applyCode('SHIPNEW');
    expect(find.text('Bỏ áp dụng'), findsNWidgets(2));

    await tester.tap(find.byType(ShopGlassBackButton).first);
    await tester.pumpAndSettle();
    expect(find.byType(CouponsScreen), findsNothing);
    expect(find.text('Choose'), findsOneWidget);

    // Verify dual stacking: 1 Freeship ($5) + 1 Product Discount ($10) = $15 total discount
    final ship = benefits.coupons.firstWhere((c) => c.id == 'SHIPNEW');
    final prod = benefits.coupons.firstWhere((c) => c.id == 'WELCOME10');
    final dualQuote = benefits.quoteDual(110, productCoupon: prod, shippingCoupon: ship);
    expect(dualQuote.shippingDiscount, 5);
    expect(dualQuote.productDiscount, 10);
    expect(dualQuote.discount, 15);
    expect(tester.takeException(), isNull);
  });

  testWidgets('typed vouchers also apply without closing the checkout picker', (tester) async {
    await tester.pumpWidget(app(const CouponsScreen(subtotal: 110)));
    await tester.pumpAndSettle();
    for (final code in ['WELCOME10', 'SHIPNEW']) {
      await tester.enterText(find.byType(TextField), code);
      await tester.tap(find.widgetWithText(FilledButton, 'Áp mã'));
      await tester.pumpAndSettle();
      expect(find.byType(CouponsScreen), findsOneWidget);
    }
    expect(benefits.selectedProductCoupon.value?.id, 'WELCOME10');
    expect(benefits.selectedShippingCoupon.value?.id, 'SHIPNEW');
    expect(tester.takeException(), isNull);
  });

  testWidgets('pressing back from checkout coupon picker pops cleanly without bool cast error', (tester) async {
    Object? poppedResult = 'sentinel';
    await tester.pumpWidget(app(Scaffold(body: Builder(builder: (context) => TextButton(
      onPressed: () async {
        final res = await Get.to<ShopCoupon>(() => const CouponsScreen(subtotal: 110));
        poppedResult = res;
      },
      child: const Text('OpenPicker'),
    )))));
    await tester.tap(find.text('OpenPicker'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ShopGlassBackButton).first);
    await tester.pumpAndSettle();
    expect(poppedResult, isNull);
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

  test('VNPay Sandbox v2.1.0 signs payment URL with HMAC-SHA512 and verifies return params', () {
    final req = VnPaySandboxService.buildSignedPaymentRequest(
      txnRef: 'VELORA123456',
      amountVnd: 2500000,
      orderInfo: 'Thanh toán đơn giày VELORA',
      bankCode: 'NCB',
      now: DateTime(2026, 11, 23, 14, 30, 0),
    );
    expect(req.paymentUrl, startsWith(VnPaySandboxService.sandboxEndpoint));
    expect(req.params['vnp_Version'], '2.1.0');
    expect(req.params['vnp_Amount'], '250000000');
    expect(req.params['vnp_OrderInfo'], 'Thanh toan don giay VELORA');
    expect(req.secureHash.length, 128); // SHA-512 hex length

    final parsedUri = Uri.parse(req.paymentUrl);
    expect(VnPaySandboxService.verifyReturnParams(parsedUri.queryParameters), isTrue);

    final tampered = Map<String, String>.from(parsedUri.queryParameters);
    tampered['vnp_Amount'] = '100';
    expect(VnPaySandboxService.verifyReturnParams(tampered), isFalse);
    expect(VnPaySandboxService.describeResponseCode('00'), contains('thành công'));
    expect(VnPaySandboxService.describeResponseCode('24'), contains('hủy'));
  });

  testWidgets('SettingScreen renders without GetX Obx errors', (tester) async {
    await tester.pumpWidget(app(const SettingScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Đơn hàng'), findsOneWidget);
    expect(find.text('Yêu thích'), findsWidgets);
    expect(find.text('Voucher'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
