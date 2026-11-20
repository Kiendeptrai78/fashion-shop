export 'catalog_search.dart';

import 'brand_model.dart';
import 'category_model.dart';
import 'product_model.dart';

class CatalogPage {
  const CatalogPage({required this.products, required this.hasNext,
      this.nextCursor, this.totalCount});

  final List<ProductModel> products;
  final bool hasNext;
  final String? nextCursor;
  final int? totalCount;
}

class CatalogFacets {
  const CatalogFacets({this.brands = const [], this.categories = const []});

  final List<BrandModel> brands;
  final List<CategoryModel> categories;
}
