import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'widgets/home_editorial.dart';
import 'package:fashion_business_app/features/shop/models/banner_model.dart';
import 'package:fashion_business_app/data/repositories/banners/banner_repository.dart';
import 'package:fashion_business_app/features/shop/screens/home/widgets/campaign_carousel.dart';
import 'package:fashion_business_app/features/shop/screens/all_product/all_product.dart';
import 'package:fashion_business_app/routes/app_route.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/layouts/grid_layout.dart';
import 'package:fashion_business_app/common/widgets/product/cart/cart_menu_icon.dart';
import 'package:fashion_business_app/common/widgets/product/product_carts/product_cart_vertical.dart';
import 'package:fashion_business_app/common/widgets/shimmer/vertical_product_shimmer.dart';
import 'package:fashion_business_app/data/repositories/products/product_reposotory.dart';
import 'package:fashion_business_app/features/shop/controllers/product/catalog_controller.dart';
import 'package:fashion_business_app/features/shop/models/catalog_query.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.catalog, this.showBackArrow = false,
      this.title = 'Sneakers', this.initialFilter = const CatalogFilter(), this.campaigns});

  final CatalogController? catalog;
  final bool showBackArrow;
  final String title;
  final CatalogFilter initialFilter;
  final Future<List<BannerModel>>? campaigns;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final CatalogController _catalog;
  final _scroll = ScrollController();
  final _catalogAnchor = GlobalKey();
  final _search = TextEditingController();
  Timer? _debounce;
  late Future<List<BannerModel>> _campaigns;

  @override
  void initState() {
    super.initState();
    _catalog = widget.catalog ?? CatalogController(
      loadPage: ProductRepository.instance.fetchCatalogPage,
      loadFacets: ProductRepository.instance.fetchCatalogFacets,
    );
    _catalog.filter = widget.initialFilter;
    _search.text = widget.initialFilter.search;
    _campaigns = widget.showBackArrow ? Future.value([])
        : widget.campaigns ?? BannerRepository().fetchBanners();
    _catalog.initialize();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _search.dispose();
    if (widget.catalog == null) _catalog.onClose();
    super.dispose();
  }

  Future<void> _refreshHome() async {
    setState(() {
      _campaigns = widget.showBackArrow ? Future.value([])
          : widget.campaigns ?? BannerRepository().fetchBanners();
    });
    await _catalog.initialize();
  }

  void _openCampaign(BannerModel banner) {
    if (banner.categoryId != null || banner.brandId != null ||
        !AppRoutes.pages.any((route) => route.name == banner.targetScreen)) {
      Get.to(() => AllProductScreen(title: banner.title.isEmpty ? 'Explore sneakers' : banner.title,
          categoryId: banner.categoryId, brandId: banner.brandId));
    } else {
      Get.toNamed(banner.targetScreen);
    }
  }

  Future<void> _changePage(bool forward) async {
    if (forward) {
      await _catalog.nextPage();
    } else {
      await _catalog.previousPage();
    }
    if (mounted && _catalog.error.value == null && _scroll.hasClients) {
      await _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  Future<void> _showFilters() async {
    var brand = _catalog.filter.brandId;
    var category = _catalog.filter.categoryId;
    final facets = _catalog.facets.value;
    final result = await showModalBottomSheet<CatalogFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(builder: (context, update) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Expanded(child: ShopText('Find your pair', style: Theme.of(context).textTheme.headlineSmall)),
                  IconButton(tooltip: 'Close filters'.tr, onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ]),
                const SizedBox(height: 24),
                ShopText('Brand', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  ChoiceChip(label: const ShopText('All brands'), selected: brand == null,
                      onSelected: (_) => update(() => brand = null)),
                  for (final item in facets.brands)
                    ChoiceChip(label: ShopText(item.name), selected: brand == item.id,
                        onSelected: (selected) => update(() => brand = selected ? item.id : null)),
                ]),
                const SizedBox(height: 24),
                ShopText('Activity', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  ChoiceChip(label: const ShopText('All sneakers'), selected: category == null,
                      onSelected: (_) => update(() => category = null)),
                  for (final item in facets.categories)
                    ChoiceChip(label: ShopText(item.name), selected: category == item.id,
                        onSelected: (selected) => update(() => category = selected ? item.id : null)),
                ]),
                const SizedBox(height: 28),
                Row(children: [
                  TextButton(onPressed: () => update(() { brand = null; category = null; }),
                      child: const ShopText('Clear all')),
                  const SizedBox(width: 16),
                  Expanded(child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, CatalogFilter(
                        search: _search.text, brandId: brand, categoryId: category)),
                    child: const ShopText('Show results'),
                  )),
                ]),
              ],
            ),
          ),
        );
      }),
    );
    if (result != null && mounted) {
      _debounce?.cancel();
      await _catalog.setFilter(result);
    }
  }

  Widget _productGrid(List<ProductModel> products) => LayoutBuilder(builder: (context, constraints) {
    final width = (constraints.maxWidth - 16) / 2;
    return TGridLayout(itemCount: products.length,
      mainAxisExtent: width + 126 * MediaQuery.textScalerOf(context).scale(1),
      itemBuilder: (_, index) => TProductCartVertical(product: products[index]),
    );
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: TAppbar(
        showBackArrow: widget.showBackArrow,
        title: widget.showBackArrow
            ? ShopText(widget.title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 22,
                fontWeight: FontWeight.w700, letterSpacing: -0.6))
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('VELORA', style: theme.textTheme.titleLarge?.copyWith(fontSize: 23,
                    fontWeight: FontWeight.w700, letterSpacing: 3)),
                ShopText('SNEAKER CULTURE, EVERY DAY', style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 8, letterSpacing: 1.2)),
              ]),
        actions: const [TCartCounterIcon()],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHome,
        child: SingleChildScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _search,
                  onChanged: (value) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 350), () {
                      _catalog.setFilter(CatalogFilter(search: value,
                          brandId: _catalog.filter.brandId, categoryId: _catalog.filter.categoryId));
                    });
                  },
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    hintText: 'Search model or brand'.tr,
                    prefixIcon: const Icon(Icons.search_rounded, size: 22),
                    filled: true,
                    fillColor: theme.brightness == Brightness.dark ? const Color(0xFF22342B) : const Color(0xFFF3F4EF),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() {
                  final facets = _catalog.facets.value;
                  final filter = _catalog.filter;
                  final loading = _catalog.isLoading.value;
                  final page = _catalog.pageNumber.value;
                  final count = _catalog.totalCount.value;
                  final products = _catalog.products.toList();
                  final error = _catalog.error.value;
                  final active = [filter.brandId, filter.categoryId].whereType<String>().length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!widget.showBackArrow && page == 1 && filter.search.trim().isEmpty &&
                          filter.brandId == null && filter.categoryId == null) ...[
                        HomeEditorialHero(onExplore: () {
                          final target = _catalogAnchor.currentContext;
                          if (target != null) {
                            Scrollable.ensureVisible(target,
                                duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 450),
                                curve: Curves.easeOutCubic);
                          }
                        }),
                        const SizedBox(height: 28),
                        if (facets.categories.isNotEmpty) ...[
                          ShopText('Made for your day', style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 23, fontWeight: FontWeight.w600, letterSpacing: -0.7)),
                          const SizedBox(height: 6),
                          ShopText('Start with the way you move.', style: theme.textTheme.bodySmall),
                          const SizedBox(height: 16),
                          HomeCollections(categories: facets.categories, onSelect: (category) => Get.to(() =>
                              AllProductScreen(title: category.name, categoryId: category.id))),
                          const SizedBox(height: 24),
                        ],
                        if (facets.brands.isNotEmpty) ...[
                          Row(children: [
                            Expanded(child: ShopText('Shop by brand', style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600))),
                            TextButton(onPressed: _showFilters, child: const ShopText('View all')),
                          ]),
                          const SizedBox(height: 8),
                          SizedBox(height: 44, child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: facets.brands.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (_, index) {
                              final brand = facets.brands[index];
                              return TextButton(
                                onPressed: () => Get.to(() => AllProductScreen(title: brand.name, brandId: brand.id)),
                                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12),
                                    foregroundColor: theme.colorScheme.onSurface),
                                child: ShopText(brand.name.toUpperCase(), style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                              );
                            },
                          )),
                          const SizedBox(height: 28),
                        ],
                        ShopText('The sneaker selection', key: _catalogAnchor, style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        ShopText('Good pairs. More possibilities.', style: theme.textTheme.bodySmall),
                        const SizedBox(height: 16),
                      ],
                      if (widget.showBackArrow || page != 1 || filter.search.trim().isNotEmpty ||
                          filter.brandId != null || filter.categoryId != null) SizedBox(key: _catalogAnchor),
                      if (facets.categories.isNotEmpty)
                        SizedBox(
                          height: 42,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final category in [null, ...facets.categories])
                                Padding(
                                  padding: const EdgeInsets.only(right: 20),
                                  child: InkWell(
                                    onTap: () {
                                      _debounce?.cancel();
                                      _catalog.setFilter(CatalogFilter(search: _search.text,
                                          brandId: filter.brandId, categoryId: category?.id));
                                    },
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(border: Border(bottom: BorderSide(
                                        width: 2,
                                        color: filter.categoryId == category?.id
                                            ? theme.colorScheme.onSurface : Colors.transparent,
                                      ))),
                                      child: ShopText(category?.name ?? 'All', style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: filter.categoryId == category?.id
                                              ? FontWeight.w700 : FontWeight.w400)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: ShopText('$count products · Page $page', style: theme.textTheme.bodySmall)),
                        OutlinedButton.icon(
                          onPressed: facets.brands.isEmpty ? null : _showFilters,
                          icon: const Icon(Icons.tune_rounded, size: 18),
                          label: ShopText(active == 0 ? 'Filters' : 'Filters ($active)'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            minimumSize: const Size(0, 40),
                          ),
                        ),
                      ]),
                      if (filter.brandId != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: InputChip(
                            label: ShopText(facets.brands.where((b) => b.id == filter.brandId)
                                .map((b) => b.name).firstOrNull ?? 'Selected brand'),
                            onDeleted: () => _catalog.setFilter(CatalogFilter(
                                search: _search.text, categoryId: filter.categoryId)),
                          ),
                        ),
                      const SizedBox(height: 20),
                      if (loading)
                        const TVerticalProductShimmer(itemCount: 10)
                      else if (error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(children: [
                            const Icon(Icons.wifi_off_rounded, size: 32),
                            const SizedBox(height: 12),
                            ShopText(error, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            OutlinedButton(onPressed: _catalog.retry, child: const ShopText('Try again')),
                          ]),
                        )
                      else if (products.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Center(child: Column(children: [
                            const Icon(Icons.search_off_rounded, size: 36),
                            const SizedBox(height: 12),
                            ShopText('No matching sneakers', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            const ShopText('Try another model, brand or activity.'),
                          ])),
                        )
                      else if (!widget.showBackArrow && page == 1 && filter.search.trim().isEmpty &&
                          filter.brandId == null && filter.categoryId == null) ...[
                        _productGrid(products.take(4).toList()),
                        FutureBuilder<List<BannerModel>>(future: _campaigns, builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                          return Padding(padding: const EdgeInsets.symmetric(vertical: 28),
                              child: CampaignCarousel(campaigns: snapshot.data!, onOpen: _openCampaign));
                        }),
                        if (products.length > 4) ...[
                          const SizedBox(height: 16),
                          _productGrid(products.skip(4).toList()),
                        ],
                      ] else
                        _productGrid(products),
                      const SizedBox(height: 28),
                      Row(children: [
                        OutlinedButton.icon(
                          onPressed: loading || page <= 1 ? null : () => _changePage(false),
                          icon: const Icon(Icons.arrow_back_rounded, size: 17),
                          label: const ShopText('Previous'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                        ),
                        Expanded(child: ShopText('Page $page', textAlign: TextAlign.center,
                            style: theme.textTheme.labelLarge)),
                        OutlinedButton.icon(
                          onPressed: loading || !_catalog.hasNext.value ? null : () => _changePage(true),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                          label: const ShopText('Next'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                        ),
                      ]),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
