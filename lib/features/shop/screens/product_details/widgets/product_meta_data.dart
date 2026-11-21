import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:fashion_business_app/common/widgets/product/product_carts/product_price_text.dart';
import 'package:fashion_business_app/features/shop/controllers/product/product_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';

class TProductMetaData extends StatelessWidget {
  const TProductMetaData({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final controller = ProductController.instance;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final salePercentage = controller.calculateSalePercentage(product.price, product.salePrice);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.brand != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF20352C) : const Color(0xFFEAF2EE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ShopText(
              '${product.brand!.name.toUpperCase()} · ${product.categoryName}',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        ShopText(
          product.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TProductPriceText(price: controller.getProductPrice(product), isLarge: true),
            if (product.productType == ProductType.single.toString() && product.salePrice > 0)
              ShopText(
                formatShopMoney(product.price, language: Localizations.localeOf(context).languageCode),
                style: theme.textTheme.bodySmall?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: theme.hintColor,
                ),
              ),
            if (salePercentage != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF173E32),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ShopText(
                  '-$salePercentage%',
                  style: const TextStyle(
                    color: Color(0xFFDDEABB),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: product.stock > 0
                ? (dark ? const Color(0xFF1D3329) : const Color(0xFFEDF6F0))
                : (dark ? const Color(0xFF351D1D) : const Color(0xFFFFF0F0)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                size: 7,
                color: product.stock > 0 ? const Color(0xFF237A57) : theme.colorScheme.error,
              ),
              const SizedBox(width: 7),
              ShopText(
                '${controller.getProductStockStatus(product.stock)} · ${product.stock} pairs',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: product.stock > 0
                      ? (dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32))
                      : theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
