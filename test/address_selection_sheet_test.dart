import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/features/shop/screens/checkout/checkout.dart';
import 'package:fashion_business_app/features/shop/controllers/product/checkout_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/models/cart_item_model.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/features/personalization/screens/account/coupons_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/features/personalization/controllers/address_controller.dart';
import 'package:fashion_business_app/features/personalization/models/address_model.dart';
import 'package:fashion_business_app/features/personalization/screens/address/widgets/address_selection_sheet.dart';
import 'package:fashion_business_app/features/personalization/screens/address/address_screen.dart';

class _Addresses extends GetxController implements AddressController {
  _Addresses([this.records = const []]);
  final List<AddressModel> records;
  int loads = 0;
  @override
  Future<List<AddressModel>> getAllUserAddresses() async {
    loads++;
    selectedAddress.value = records.firstWhere((address) => address.selectedAddress, orElse: AddressModel.empty);
    return records;
  }
  @override
  final selectedAddress = AddressModel.empty().obs;
  @override
  final refreshData = false.obs;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Cart extends GetxController implements CartController {
  @override
  final cartItems = <CartItemModel>[CartItemModel(productId: 'p', quantity: 1, title: 'Shoe', price: 110)].obs;
  @override
  final totalCartPrice = 110.0.obs;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(() => Get.reset());
  testWidgets('address heading clears the toolbar on a notched iPhone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.padding = const FakeViewPadding(top: 62);
    tester.view.viewPadding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    Get.put<AddressController>(_Addresses());
    await tester.pumpWidget(const GetMaterialApp(home: AddressScreen()));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('A place for every delivery.')).dy,
      greaterThan(tester.getBottomLeft(find.byType(TAppbar)).dy));
    expect(tester.takeException(), isNull);
  });
  testWidgets('adding from checkout refreshes the open address sheet immediately', (tester) async {
    final controller = Get.put<AddressController>(_Addresses());
    final records = <AddressModel>[];
    var loads = 0;
    await tester.pumpWidget(GetMaterialApp(home: Scaffold(body: AddressSelectionSheet(
      loadAddresses: () async { loads++; return records.toList(); },
      addAddress: () async {
        final address = AddressModel(id: 'new', name: 'New recipient', phoneNumber: '0901234567',
            street: '12 Street', city: 'Hanoi', state: '', country: 'Vietnam');
        records.add(address);
        controller.selectedAddress.value = address;
      },
    ))));
    await tester.pumpAndSettle();
    expect(find.text('New recipient'), findsNothing);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add new address'));
    await tester.pumpAndSettle();
    expect(loads, 2);
    expect(find.text('New recipient'), findsOneWidget);
    expect(find.byType(AddressSelectionSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkout loads the saved default without first opening the picker', (tester) async {
    final address = AddressModel(id: 'saved', name: 'Saved recipient', phoneNumber: '0901234567',
        street: '12 Street', city: 'Hanoi', state: '', country: 'Vietnam');
    final addresses = _Addresses([address]);
    Get.put<AddressController>(addresses);
    Get.put<CartController>(_Cart());
    Get.put(CheckoutController());
    Map<String, dynamic>? saved;
    final benefits = Get.put(CustomerBenefits(read: () => saved, write: (data) async { saved = data; }));
    await benefits.initialize();
    await tester.pumpWidget(GetMaterialApp(home: CheckoutScreen(watchCoinBalance: () => Stream.value(0))));
    await tester.pumpAndSettle();
    expect(addresses.loads, 1);
    expect(find.text('Saved recipient'), findsOneWidget);
    expect(find.text('Select Address'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('delivery coordinates are optional for old addresses and retained for map pins', () {
    final data = {'Id':'a','Name':'Recipient','PhoneNumber':'0901234567',
      'Street':'12 Street','City':'Hanoi','State':'','Country':'Vietnam'};
    expect(AddressModel.fromMap(data).latitude, isNull);
    final pinned = AddressModel.fromMap({...data, 'Latitude':21.0285, 'Longitude':105.8542});
    expect(pinned.toJson()['Latitude'], 21.0285);
    expect(pinned.toJson()['Longitude'], 105.8542);
  });

  testWidgets('checkout receives both vouchers and a replaced discount when leaving the picker', (tester) async {
    Get.put<AddressController>(_Addresses());
    Get.put<CartController>(_Cart());
    Get.put(CheckoutController());
    Map<String, dynamic>? saved;
    final benefits = Get.put(CustomerBenefits(read: () => saved, write: (data) async { saved = data; },
        now: () => DateTime(2026, 11, 20, 12)));
    await benefits.initialize();
    benefits.saveCouponSelection(benefits.coupons.firstWhere((c) => c.id == 'LE-2026-11-20'));
    await tester.pumpWidget(GetMaterialApp(locale: const Locale('en'), home: CheckoutScreen(watchCoinBalance: () => Stream.value(0))));
    await tester.pumpAndSettle();
    final shippingSlot = find.text('Free Shipping');
    await Scrollable.ensureVisible(tester.element(shippingSlot), alignment: 0.5);
    await tester.tap(shippingSlot);
    await tester.pumpAndSettle();
    for (final code in ['WELCOME10', 'SHIPNEW']) {
      await tester.enterText(find.byType(TextField), code);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.byType(CouponsScreen), findsOneWidget);
    }
    await tester.tap(find.byType(ShopGlassBackButton).first);
    await tester.pumpAndSettle();
    expect(find.byType(CouponsScreen), findsNothing);
    expect(find.text('WELCOME10'), findsOneWidget);
    expect(find.text('SHIPNEW'), findsOneWidget);
    expect(find.text('LE-2026-11-20'), findsNothing);
    await Scrollable.ensureVisible(tester.element(find.text('SHIPNEW')), alignment: 0.5);
    await tester.tap(find.text('SHIPNEW'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      final remove = find.widgetWithText(OutlinedButton, 'Remove').first;
      await Scrollable.ensureVisible(tester.element(remove), alignment: 0.5);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(find.byType(CouponsScreen), findsOneWidget);
    }
    expect(find.widgetWithText(OutlinedButton, 'Remove'), findsNothing);
    await tester.tap(find.byType(ShopGlassBackButton).first);
    await tester.pumpAndSettle();
    expect(benefits.selectedProductCoupon.value, isNull);
    expect(benefits.selectedShippingCoupon.value, isNull);
    expect(find.text('WELCOME10'), findsNothing);
    expect(find.text('SHIPNEW'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
