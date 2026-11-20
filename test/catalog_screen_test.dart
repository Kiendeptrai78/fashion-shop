import 'package:fashion_business_app/common/widgets/product/product_carts/product_cart_vertical.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/catalog_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/favourite_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/product_controller.dart';
import 'package:fashion_business_app/features/shop/models/catalog_query.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/screens/home/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Prices extends GetxController implements ProductController {
  @override
  String getProductPrice(ProductModel product) => '100';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Cart extends GetxController implements CartController {
  @override
  final noOfCartItem = 0.obs;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Favourites extends FavouritesController {
  @override
  Future<void> initFavourites() async {}
}

void main() {
  tearDown(() => Get.reset());

  testWidgets('catalog shows 10, 10, then 4 products and supports previous page', (tester) async {
    Get.put<ProductController>(_Prices());
    Get.put<CartController>(_Cart());
    Get.put<FavouritesController>(_Favourites());
    final requested = <String?>[];
    final controller = CatalogController(
      loadFacets: () async => const CatalogFacets(),
      loadPage: ({required filter, cursor}) async {
        requested.add(cursor);
        final start = cursor == null ? 0 : int.parse(cursor) + 1;
        final end = (start + 10).clamp(0, 24);
        final products = [for (var i = start; i < end; i++)
          ProductModel.empty()..id = '$i'..title = 'Style ${i.toString().padLeft(2, '0')}'];
        return CatalogPage(products: products, hasNext: end < 24,
            nextCursor: products.last.id, totalCount: 24);
      },
    );
    await tester.pumpWidget(GetMaterialApp(home: HomeScreen(catalog: controller, campaigns: Future.value([]))));
    await tester.pumpAndSettle();
    expect(find.byType(TProductCartVertical), findsNWidgets(10));
    expect(find.text('Style 00'), findsOneWidget);
    for (var page = 2; page <= 3; page++) {
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Page $page'), findsOneWidget);
      expect(find.byType(TProductCartVertical), findsNWidgets(page == 2 ? 10 : 4));
    }
    expect(requested, [null, '9', '19']);
    await tester.ensureVisible(find.text('Previous'));
    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();
    expect(find.text('Style 10'), findsOneWidget);
    expect(find.byType(TProductCartVertical), findsNWidgets(10));
    expect(tester.takeException(), isNull);
  });
}
