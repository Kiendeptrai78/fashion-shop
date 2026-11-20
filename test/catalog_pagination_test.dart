import 'dart:async';

import 'package:fashion_business_app/features/shop/controllers/product/catalog_controller.dart';
import 'package:fashion_business_app/features/shop/models/catalog_query.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:flutter_test/flutter_test.dart';

ProductModel product(int index) => ProductModel.empty()..id = index.toString().padLeft(5, '0');

CatalogController makeController(CatalogPageLoader loader) => CatalogController(
    loadPage: loader, loadFacets: () async => const CatalogFacets());

void main() {
  test('cursor pages contain ten items and can continue beyond any fixed page limit', () async {
    final requests = <String?>[];
    final controller = makeController(({required filter, cursor}) async {
      requests.add(cursor);
      final offset = cursor == null ? 0 : int.parse(cursor) + 1;
      final items = List.generate(10, (i) => product(offset + i));
      return CatalogPage(products: items, hasNext: true, nextCursor: items.last.id,
          totalCount: cursor == null ? 1000000 : null);
    });
    await controller.initialize();
    for (var i = 0; i < 125; i++) {
      expect(controller.products, hasLength(10));
      await controller.nextPage();
    }
    expect(controller.pageNumber.value, 126);
    expect(controller.products.first.id, '01250');
    expect(requests[1], '00009');
    await controller.previousPage();
    expect(controller.pageNumber.value, 125);
    expect(controller.products.first.id, '01240');
    expect(controller.totalCount.value, 1000000);
  });

  test('changing search or filters clears cursors and starts at page one', () async {
    final requests = <(String, String?)>[];
    final controller = makeController(({required filter, cursor}) async {
      requests.add((filter.key, cursor));
      return CatalogPage(products: List.generate(10, product), hasNext: true, nextCursor: '00009');
    });
    await controller.initialize();
    await controller.nextPage();
    const filter = CatalogFilter(search: 'Pegasus', brandId: 'nike', categoryId: 'running');
    await controller.setFilter(filter);
    expect(controller.pageNumber.value, 1);
    expect(requests.last, (filter.key, null));
  });

  test('an older response cannot overwrite a newer search', () async {
    final pending = <Completer<CatalogPage>>[];
    final controller = makeController(({required filter, cursor}) {
      final completer = Completer<CatalogPage>();
      pending.add(completer);
      return completer.future;
    });
    final first = controller.initialize();
    final second = controller.setFilter(const CatalogFilter(search: 'nike'));
    pending[1].complete(CatalogPage(products: [product(2)], hasNext: false));
    await second;
    pending[0].complete(CatalogPage(products: [product(1)], hasNext: true));
    await first;
    expect(controller.products.single.id, '00002');
    expect(controller.hasNext.value, isFalse);
  });

  test('a failed next page retries its cursor and does not skip a page', () async {
    var fail = true;
    final controller = makeController(({required filter, cursor}) async {
      if (cursor != null && fail) throw Exception('offline');
      return CatalogPage(products: [product(cursor == null ? 1 : 2)],
          hasNext: cursor == null, nextCursor: '00001');
    });
    await controller.initialize();
    await controller.nextPage();
    expect(controller.pageNumber.value, 1);
    expect(controller.products.single.id, '00001');
    expect(controller.error.value, isNotNull);
    fail = false;
    await controller.retry();
    expect(controller.pageNumber.value, 2);
    expect(controller.products.single.id, '00002');
    expect(controller.hasNext.value, isFalse);
    await controller.nextPage();
    expect(controller.pageNumber.value, 2);
  });

  test('indexed prefixes support combined filters without reading other pages', () {
    final keys = catalogBrowseKeys(title: 'Air Force 1', brandName: 'Nike',
        categoryName: 'Lifestyle', brandId: 'nike', categoryId: 'lifestyle');
    expect(keys, contains(const CatalogFilter(search: '  NIKE   AIR ', brandId: 'nike',
        categoryId: 'lifestyle').key));
    expect(keys, contains(const CatalogFilter(search: 'force').key));
    expect(keys, contains(const CatalogFilter(search: 'air f', categoryId: 'lifestyle').key));
    expect(keys, isNot(contains(const CatalogFilter(brandId: 'adidas').key)));
  });
}
