import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:fashion_business_app/features/shop/models/catalog_query.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';

typedef CatalogPageLoader = Future<CatalogPage> Function({required CatalogFilter filter, String? cursor});

class CatalogController extends GetxController {
  CatalogController({required this.loadPage, required this.loadFacets});

  final CatalogPageLoader loadPage;
  final Future<CatalogFacets> Function() loadFacets;
  final products = <ProductModel>[].obs;
  final facets = const CatalogFacets().obs;
  final isLoading = false.obs;
  final error = RxnString();
  final pageNumber = 1.obs;
  final hasNext = false.obs;
  final totalCount = 0.obs;
  CatalogFilter filter = const CatalogFilter();
  final _cursors = <String?>[null];
  String? _nextCursor;
  int _request = 0;
  int _retryPage = 1;
  String? _retryCursor;

  Future<void> initialize() async {
    await Future.wait([refreshPage(), _fetchFacets()]);
  }

  Future<void> _fetchFacets() async {
    try {
      facets.value = await loadFacets();
    } catch (_) {
      // The catalog remains browsable; a refresh retries its filter metadata.
    }
  }

  Future<void> setFilter(CatalogFilter value) async {
    if (value.key == filter.key) return;
    filter = value;
    await refreshPage();
  }

  Future<void> refreshPage() async {
    _cursors
      ..clear()
      ..add(null);
    pageNumber.value = 1;
    totalCount.value = 0;
    hasNext.value = false;
    _nextCursor = null;
    products.clear();
    await _fetch(1, null);
  }

  Future<void> nextPage() async {
    if (isLoading.value || !hasNext.value || _nextCursor == null) return;
    await _fetch(pageNumber.value + 1, _nextCursor);
  }

  Future<void> previousPage() async {
    if (isLoading.value || pageNumber.value <= 1) return;
    final target = pageNumber.value - 1;
    await _fetch(target, _cursors[target - 1]);
  }

  Future<void> retry() => _fetch(_retryPage, _retryCursor);

  Future<void> _fetch(int targetPage, String? cursor) async {
    final request = ++_request;
    _retryPage = targetPage;
    _retryCursor = cursor;
    isLoading.value = true;
    error.value = null;
    try {
      final result = await loadPage(filter: filter, cursor: cursor);
      if (request != _request) return;
      products.assignAll(result.products);
      pageNumber.value = targetPage;
      hasNext.value = result.hasNext;
      _nextCursor = result.nextCursor;
      if (result.totalCount != null) totalCount.value = result.totalCount!;
      if (_cursors.length < targetPage) _cursors.add(cursor);
    } catch (exception) {
      if (kDebugMode) debugPrint('Catalog page failed: $exception');
      if (request == _request) error.value = 'Could not load sneakers. Please try again.';
    } finally {
      if (request == _request) isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _request++;
    super.onClose();
  }
}
