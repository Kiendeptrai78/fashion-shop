import 'package:fashion_business_app/features/shop/screens/checkout/widgets/billing_amount_section.dart';
import 'package:flutter/material.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/models/cart_item_model.dart';
import 'package:fashion_business_app/features/shop/screens/cart/cart_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Cart extends GetxController implements CartController {
  @override
  final cartItems = <CartItemModel>[].obs;
  @override
  final noOfCartItem = 0.obs;
  @override
  final totalCartPrice = 0.0.obs;
  @override
  void addOneToCart(CartItemModel item) {
    item.quantity++;
    totalCartPrice.value = item.quantity * item.price;
    cartItems.refresh();
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(() => Get.reset());
  testWidgets('checkout breakdown and total update together', (tester) async {
    final cart = Get.put<CartController>(_Cart());
    cart.totalCartPrice.value = 110;
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: TBillingAmountSection())));
    expect(find.text('\$110.00'), findsOneWidget);
    expect(find.text('\$5.00'), findsOneWidget);
    expect(find.text('\$2.00'), findsOneWidget);
    expect(find.text('\$117.00'), findsOneWidget);
    cart.totalCartPrice.value = 220;
    await tester.pump();
    expect(find.text('\$227.00'), findsOneWidget);
    expect(find.text('\$117.00'), findsNothing);
  });
  testWidgets('checkout shows selected discount in the final total', (tester) async {
    final cart = Get.put<CartController>(_Cart());
    cart.totalCartPrice.value = 110;
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold(
        body: TBillingAmountSection(discount: 10))));
    expect(find.text('Discount'), findsOneWidget);
    expect(find.text('-\$10.00'), findsOneWidget);
    expect(find.text('\$107.00'), findsOneWidget);
  });
  testWidgets('bag updates quantities and removes checkout when emptied', (tester) async {
    final cart = Get.put<CartController>(_Cart());
    cart.cartItems.add(CartItemModel(productId: 'shoe', title: 'Air Force 1', quantity: 1,
        price: 110, brandName: 'Nike', selectedVariation: {'Size': '42', 'Color': 'White'}));
    cart.totalCartPrice.value = 110;
    await tester.pumpWidget(const GetMaterialApp(home: CartScreen()));
    expect(find.text('Size: 42 · Color: White'), findsOneWidget);
    expect(find.text('Continue to checkout'), findsOneWidget);
    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
    expect(find.text('\$220.00'), findsNWidgets(2));
    cart.cartItems.clear();
    await tester.pump();
    expect(find.text('Your next pair awaits.'), findsOneWidget);
    expect(find.text('Continue to checkout'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
