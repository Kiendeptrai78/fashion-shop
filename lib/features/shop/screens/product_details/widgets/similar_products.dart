import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/data/repositories/products/product_reposotory.dart';
import 'package:fashion_business_app/features/shop/controllers/product/product_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';

class SimilarProducts extends StatefulWidget {
  const SimilarProducts({super.key, required this.product, required this.onOpen});
  final ProductModel product;
  final ValueChanged<ProductModel> onOpen;

  @override
  State<SimilarProducts> createState() => _SimilarProductsState();
}

class _SimilarProductsState extends State<SimilarProducts> {
  late Future<List<ProductModel>> _products;

  @override
  void initState() {
    super.initState();
    _products = ProductRepository.instance.fetchSimilarProducts(widget.product);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ProductModel>>(
    future: _products,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
      }
      if (snapshot.hasError) {
        return Row(children: [
          const Expanded(child: ShopText('Similar pairs couldn’t load.')),
          TextButton(onPressed: () => setState(() { _products =
              ProductRepository.instance.fetchSimilarProducts(widget.product); }), child: const ShopText('Retry')),
        ]);
      }
      final products = snapshot.data ?? [];
      if (products.isEmpty) return const SizedBox.shrink();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const ShopText('More your style', style: TextStyle(fontSize: 24,
            fontWeight: FontWeight.w600, letterSpacing: -0.8)),
        const SizedBox(height: 6),
        ShopText('Explore more from the ${widget.product.categoryName.toLowerCase()} collection.',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 20),
        SizedBox(height: 240, child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(width: 18),
          itemBuilder: (_, index) {
            final product = products[index];
            return SizedBox(width: 155, child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => widget.onOpen(product),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TRoundedImage(imageUrl: product.thumbnail, isNetworkImage: true, width: 155, height: 145),
                const SizedBox(height: 12),
                ShopText(product.brand?.name ?? '', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                ShopText(product.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                ShopText(formatShopPrice(ProductController.instance.getProductPrice(product), language: Localizations.localeOf(context).languageCode),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
            ));
          },
        )),
      ]);
    },
  );
}
