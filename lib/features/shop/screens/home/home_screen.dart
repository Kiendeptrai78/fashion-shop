import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/layouts/grid_layout.dart';
import 'package:fashion_business_app/common/widgets/product/badges/shop_count_badge.dart';
import 'package:fashion_business_app/common/widgets/product/cart/cart_menu_icon.dart';
import 'package:fashion_business_app/common/widgets/product/product_carts/product_cart_vertical.dart';
import 'package:fashion_business_app/common/widgets/shimmer/vertical_product_shimmer.dart';
import 'package:fashion_business_app/data/repositories/banners/banner_repository.dart';
import 'package:fashion_business_app/data/repositories/products/product_reposotory.dart';
import 'package:fashion_business_app/features/personalization/screens/account/coupons_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/account/demo_bank_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/account/notifications_screen.dart';
import 'package:fashion_business_app/features/personalization/services/account_activity.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/features/shop/controllers/product/catalog_controller.dart';
import 'package:fashion_business_app/features/shop/models/banner_model.dart';
import 'package:fashion_business_app/features/shop/models/catalog_query.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/screens/all_product/all_product.dart';
import 'package:fashion_business_app/features/shop/screens/assistant/velora_ai_chat_screen.dart';
import 'package:fashion_business_app/features/shop/screens/home/widgets/campaign_carousel.dart';
import 'package:fashion_business_app/features/shop/screens/order/order.dart';
import 'package:fashion_business_app/features/shop/screens/support_chat/velora_support_chat_screen.dart';
import 'package:fashion_business_app/routes/app_route.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'widgets/home_editorial.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.catalog,
    this.showBackArrow = false,
    this.title = 'Sneakers',
    this.initialFilter = const CatalogFilter(),
    this.campaigns,
  });

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
    _catalog = widget.catalog ??
        CatalogController(
          loadPage: ProductRepository.instance.fetchCatalogPage,
          loadFacets: ProductRepository.instance.fetchCatalogFacets,
        );
    _catalog.filter = widget.initialFilter;
    _search.text = widget.initialFilter.search;
    _campaigns = widget.showBackArrow
        ? Future.value([])
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
      _campaigns = widget.showBackArrow
          ? Future.value([])
          : widget.campaigns ?? BannerRepository().fetchBanners();
    });
    await _catalog.initialize();
  }

  void _openCampaign(BannerModel banner) {
    if (banner.categoryId != null ||
        banner.brandId != null ||
        !AppRoutes.pages.any((route) => route.name == banner.targetScreen)) {
      Get.to(() => AllProductScreen(
            title: banner.title.isEmpty ? 'Explore sneakers' : banner.title,
            categoryId: banner.categoryId,
            brandId: banner.brandId,
          ));
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

  void _clearSearch() {
    _debounce?.cancel();
    _search.clear();
    _catalog.setFilter(CatalogFilter(
      search: '',
      brandId: _catalog.filter.brandId,
      categoryId: _catalog.filter.categoryId,
    ));
  }

  Future<void> _showFilters() async {
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
                  IconButton(
                    tooltip: 'Close filters'.tr,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ]),
                const SizedBox(height: 20),
                ShopText('Activity', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  ChoiceChip(
                    label: const ShopText('All sneakers'),
                    selected: category == null,
                    onSelected: (_) => update(() => category = null),
                  ),
                  for (final item in facets.categories)
                    ChoiceChip(
                      label: ShopText(item.name),
                      selected: category == item.id,
                      onSelected: (selected) => update(() => category = selected ? item.id : null),
                    ),
                ]),
                const SizedBox(height: 28),
                Row(children: [
                  TextButton(
                    onPressed: () => update(() => category = null),
                    child: const ShopText('Clear all'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(
                        context,
                        CatalogFilter(search: _search.text, categoryId: category),
                      ),
                      child: const ShopText('Show results'),
                    ),
                  ),
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
        return TGridLayout(
          itemCount: products.length,
          mainAxisExtent: width + 138 * MediaQuery.textScalerOf(context).scale(1),
          itemBuilder: (_, index) => TProductCartVertical(product: products[index]),
        );
      });

  Widget _quickShortcut({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int badge,
    required VoidCallback onTap,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? const Color(0xFF1D2D26) : const Color(0xFFF3F6F1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE0E8E2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32)),
              const SizedBox(width: 7),
              ShopText(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: dark ? Colors.white : const Color(0xFF173E32),
                ),
              ),
              if (badge > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: dark ? const Color(0xFF102B23) : const Color(0xFFDDEABB),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final activity = AccountActivity.current;

    return Scaffold(
      appBar: TAppbar(
        showBackArrow: widget.showBackArrow,
        title: widget.showBackArrow
            ? ShopText(
                widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E4D3E), Color(0xFF102B23)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'V',
                      style: TextStyle(
                        color: Color(0xFFDDEABB),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'VELORA',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                            height: 1.05,
                          ),
                        ),
                        ShopText(
                          'SNEAKER CULTURE, EVERY DAY',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 8,
                            letterSpacing: 1.1,
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: [
          if (!widget.showBackArrow && Get.isRegistered<ShopLocale>())
            Builder(builder: (context) {
              final currentLang = Localizations.localeOf(context).languageCode;
              final isVi = currentLang != 'en';
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => Get.find<ShopLocale>().change(isVi ? 'en' : 'vi'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF1E352B) : const Color(0xFFE7F0EA),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFF173E32).withValues(alpha: 0.22),
                      ),
                    ),
                    child: Text(
                      isVi ? 'VI 🇻🇳' : 'EN 🇬🇧',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
                      ),
                    ),
                  ),
                ),
              );
            }),
          if (!widget.showBackArrow)
            const _HomeSupportChatIconButton(),
          if (!widget.showBackArrow)
            activity != null
                ? Obx(() => IconButton(
                      tooltip: 'Notifications'.tr,
                      onPressed: () => Get.to(() => const NotificationsScreen()),
                      icon: ShopCountBadge(
                        count: activity.unread,
                        child: const Icon(Iconsax.notification, size: 22),
                      ),
                    ))
                : IconButton(
                    tooltip: 'Notifications'.tr,
                    onPressed: () => Get.to(() => const NotificationsScreen()),
                    icon: const Icon(Iconsax.notification, size: 22),
                  ),
          const TCartCounterIcon(),
        ],
      ),
      floatingActionButton: widget.showBackArrow
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'velora-support-chat-fab',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF173E32),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: const Color(0xFF173E32).withValues(alpha: 0.25),
                    ),
                  ),
                  onPressed: () =>
                      Get.to(() => const VeloraSupportChatScreen()),
                  icon: const Icon(Iconsax.message_text_1, size: 18),
                  label: const Text(
                    'Chat VELORA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'velora-ai-fab',
                  tooltip: 'AI Stylist'.tr,
                  backgroundColor: const Color(0xFF173E32),
                  foregroundColor: const Color(0xFFDDEABB),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onPressed: () => Get.to(() => const VeloraAiChatScreen()),
                  child: const Icon(Icons.auto_awesome_rounded, size: 20),
                ),
              ],
            ),
      body: RefreshIndicator(
        onRefresh: _refreshHome,
        color: const Color(0xFF173E32),
        child: SingleChildScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _search,
                  builder: (context, value, _) {
                    return TextField(
                      controller: _search,
                      onChanged: (text) {
                        _debounce?.cancel();
                        _debounce = Timer(const Duration(milliseconds: 350), () {
                          _catalog.setFilter(CatalogFilter(
                            search: text,
                            brandId: _catalog.filter.brandId,
                            categoryId: _catalog.filter.categoryId,
                          ));
                        });
                      },
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      decoration: InputDecoration(
                        hintText: 'Search model or brand'.tr,
                        prefixIcon: const Icon(Iconsax.search_normal_1, size: 20),
                        suffixIcon: value.text.isNotEmpty
                            ? IconButton(
                                tooltip: 'Clear search'.tr,
                                onPressed: _clearSearch,
                                icon: const Icon(Icons.close_rounded, size: 19),
                              )
                            : IconButton(
                                tooltip: 'Filters'.tr,
                                onPressed: _showFilters,
                                icon: Icon(
                                  Icons.tune_rounded,
                                  size: 20,
                                  color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
                                ),
                              ),
                        filled: true,
                        fillColor: dark ? const Color(0xFF1D2D26) : const Color(0xFFF3F5F0),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE3E8E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE3E8E1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
                            width: 1.4,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                Obx(() {
                  final facets = _catalog.facets.value;
                  final filter = _catalog.filter;
                  final loading = _catalog.isLoading.value;
                  final page = _catalog.pageNumber.value;
                  final count = _catalog.totalCount.value;
                  final products = _catalog.products.toList();
                  final error = _catalog.error.value;
                  final active = [filter.brandId, filter.categoryId].whereType<String>().length;
                  final isRootHome = !widget.showBackArrow &&
                      page == 1 &&
                      filter.search.trim().isEmpty &&
                      filter.brandId == null &&
                      filter.categoryId == null;
                  final activeOrders = AccountActivity.current?.activeOrders ?? 0;
                  final couponCount = Get.isRegistered<CustomerBenefits>()
                      ? CustomerBenefits.instance.newCouponCount
                      : 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isRootHome) ...[
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              Material(
                                color: const Color(0xFF173E32),
                                borderRadius: BorderRadius.circular(12),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => Get.to(() => const VeloraAiChatScreen()),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.auto_awesome_rounded, size: 15, color: Color(0xFFDDEABB)),
                                        SizedBox(width: 6),
                                        ShopText(
                                          'AI Stylist',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFDDEABB),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _quickShortcut(
                                context: context,
                                icon: Iconsax.discount_shape,
                                label: 'Vouchers',
                                badge: couponCount,
                                onTap: () => Get.to(() => const CouponsScreen()),
                              ),
                              const SizedBox(width: 8),
                              _quickShortcut(
                                context: context,
                                icon: Iconsax.bag_tick,
                                label: 'Orders',
                                badge: activeOrders,
                                onTap: () => Get.to(() => const OrderScreen()),
                              ),
                              const SizedBox(width: 8),
                              _quickShortcut(
                                context: context,
                                icon: Iconsax.wallet_3,
                                label: 'Wallet',
                                badge: 0,
                                onTap: () => Get.to(() => const DemoBankScreen()),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        HomeEditorialHero(onExplore: () {
                          final target = _catalogAnchor.currentContext;
                          if (target != null) {
                            Scrollable.ensureVisible(
                              target,
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 450),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        }),
                        const SizedBox(height: 28),
                        if (facets.categories.isNotEmpty) ...[
                          ShopText(
                            'Made for your day',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ShopText('Start with the way you move.', style: theme.textTheme.bodySmall),
                          const SizedBox(height: 14),
                          HomeCollections(
                            categories: facets.categories,
                            onSelect: (category) => Get.to(
                              () => AllProductScreen(title: category.name, categoryId: category.id),
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],
                        ShopText(
                          'The sneaker selection',
                          key: _catalogAnchor,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ShopText('Good pairs. More possibilities.', style: theme.textTheme.bodySmall),
                        const SizedBox(height: 14),
                      ],
                      if (!isRootHome) SizedBox(key: _catalogAnchor),
                      if (facets.categories.isNotEmpty)
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final category in [null, ...facets.categories]) ...[
                                Builder(builder: (context) {
                                  final selected = filter.categoryId == category?.id;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Material(
                                      color: selected
                                          ? (dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32))
                                          : (dark ? const Color(0xFF1D2D26) : const Color(0xFFF3F5F0)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(999),
                                        side: BorderSide(
                                          color: selected
                                              ? Colors.transparent
                                              : (dark
                                                  ? Colors.white.withValues(alpha: 0.08)
                                                  : const Color(0xFFE2E7E0)),
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        onTap: () {
                                          _debounce?.cancel();
                                          _catalog.setFilter(CatalogFilter(
                                            search: _search.text,
                                            brandId: filter.brandId,
                                            categoryId: category?.id,
                                          ));
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                          child: Center(
                                            child: ShopText(
                                              category?.name ?? 'All',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                fontSize: 12.5,
                                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                                color: selected
                                                    ? (dark ? const Color(0xFF102B23) : Colors.white)
                                                    : theme.colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                          child: ShopText('$count products · Page $page', style: theme.textTheme.bodySmall),
                        ),
                        OutlinedButton.icon(
                          onPressed: facets.categories.isEmpty ? null : _showFilters,
                          icon: const Icon(Icons.tune_rounded, size: 17),
                          label: ShopText(active == 0 ? 'Filters' : 'Filters ($active)'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            minimumSize: const Size(0, 38),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ]),
                      if (filter.brandId != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: InputChip(
                            label: ShopText(
                              facets.brands
                                      .where((b) => b.id == filter.brandId)
                                      .map((b) => b.name)
                                      .firstOrNull ??
                                  'Selected brand',
                            ),
                            onDeleted: () => _catalog.setFilter(
                              CatalogFilter(search: _search.text, categoryId: filter.categoryId),
                            ),
                          ),
                        ),
                      const SizedBox(height: 18),
                      if (loading)
                        const TVerticalProductShimmer(itemCount: 10)
                      else if (error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Column(children: [
                              const Icon(Icons.wifi_off_rounded, size: 32),
                              const SizedBox(height: 12),
                              ShopText(error, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              OutlinedButton(onPressed: _catalog.retry, child: const ShopText('Try again')),
                            ]),
                          ),
                        )
                      else if (products.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: Column(children: [
                              const Icon(Icons.search_off_rounded, size: 36),
                              const SizedBox(height: 12),
                              ShopText('No matching sneakers', style: theme.textTheme.titleMedium),
                              const SizedBox(height: 8),
                              const ShopText('Try another model, brand or activity.'),
                            ]),
                          ),
                        )
                      else if (isRootHome) ...[
                        _productGrid(products.take(4).toList()),
                        FutureBuilder<List<BannerModel>>(
                          future: _campaigns,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 28),
                              child: CampaignCarousel(campaigns: snapshot.data!, onOpen: _openCampaign),
                            );
                          },
                        ),
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
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        Expanded(
                          child: ShopText(
                            'Page $page',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: loading || !_catalog.hasNext.value ? null : () => _changePage(true),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                          label: const ShopText('Next'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
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

class _HomeSupportChatIconButton extends StatefulWidget {
  const _HomeSupportChatIconButton();

  @override
  State<_HomeSupportChatIconButton> createState() =>
      _HomeSupportChatIconButtonState();
}

class _HomeSupportChatIconButtonState
    extends State<_HomeSupportChatIconButton> {
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _threadStream;

  @override
  void initState() {
    super.initState();
    final user =
        Firebase.apps.isNotEmpty ? FirebaseAuth.instance.currentUser : null;
    if (user != null) {
      _threadStream = FirebaseFirestore.instance
          .collection('SupportChats')
          .doc(user.uid)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_threadStream == null) {
      return IconButton(
        tooltip: 'Chat trực tiếp với VELORA',
        onPressed: () => Get.to(() => const VeloraSupportChatScreen()),
        icon: const Icon(Iconsax.message_text_1, size: 22),
      );
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _threadStream,
      builder: (context, snapshot) {
        final unread =
            (snapshot.data?.data()?['unreadByCustomer'] as num?)?.toInt() ?? 0;
        return IconButton(
          tooltip: 'Chat trực tiếp với VELORA',
          onPressed: () => Get.to(() => const VeloraSupportChatScreen()),
          icon: ShopCountBadge(
            count: unread,
            child: const Icon(Iconsax.message_text_1, size: 22),
          ),
        );
      },
    );
  }
}
