import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/layouts/grid_layout.dart';
import 'package:fashion_business_app/common/widgets/product/product_carts/product_cart_vertical.dart';
import 'package:fashion_business_app/common/widgets/shimmer/vertical_product_shimmer.dart';
import 'package:fashion_business_app/features/shop/controllers/product/favourite_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/screens/widgets/shopping_empty_state.dart';

class WishList extends StatefulWidget {
  const WishList({super.key});

  @override
  State<WishList> createState() => _WishListState();
}

class _WishListState extends State<WishList> {
  final _controller = FavouritesController.instance;
  late Future<List<ProductModel>> _products;
  late Worker _changes;

  @override
  void initState() {
    super.initState();
    _products = _controller.favouriteProducts();
    _changes = ever(_controller.favourites, (_) => _reload());
  }

  Future<void> _reload() async {
    final future = _controller.favouriteProducts();
    setState(() { _products = future; });
    try { await future; } catch (_) { /* Displayed by FutureBuilder. */ }
  }

  @override
  void dispose() {
    _changes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: TAppbar(title: const ShopText('Saved pairs', style: TextStyle(fontSize: 22,
        fontWeight: FontWeight.w600, letterSpacing: -0.6)), actions: [
      IconButton(tooltip: 'Explore sneakers'.tr, onPressed: exploreSneakers,
          icon: const Icon(Iconsax.search_normal, size: 22)),
    ]),
    body: FutureBuilder<List<ProductModel>>(future: _products, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const SingleChildScrollView(padding: EdgeInsets.all(24),
            child: TVerticalProductShimmer(itemCount: 4));
      }
      if (snapshot.hasError) {
        return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
          mainAxisSize: MainAxisSize.min, children: [
            const Icon(Iconsax.wifi_square, size: 36), const SizedBox(height: 20),
            const ShopText('Couldn’t load your saved pairs.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _reload, child: const ShopText('Try again')),
          ])));
      }
      final products = snapshot.data ?? [];
      if (products.isEmpty) return const ShoppingEmptyState(wishlist: true);
      return RefreshIndicator(onRefresh: _reload, child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ShopText('YOUR PERSONAL EDIT', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 2)),
          const SizedBox(height: 10),
          const ShopText('Worth coming back for.', style: TextStyle(fontSize: 25,
              fontWeight: FontWeight.w600, letterSpacing: -0.8)),
          const SizedBox(height: 8),
          ShopText('${products.length} saved ${products.length == 1 ? 'pair' : 'pairs'} · Tap a pair to choose your size',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 28),
          LayoutBuilder(builder: (context, constraints) {
            final width = (constraints.maxWidth - 16) / 2;
            return TGridLayout(
              itemCount: products.length,
              mainAxisExtent: width + 138 * MediaQuery.textScalerOf(context).scale(1),
              itemBuilder: (_, index) => TProductCartVertical(product: products[index]),
            );
          }),
        ]),
      ));
    }),
  );
}
