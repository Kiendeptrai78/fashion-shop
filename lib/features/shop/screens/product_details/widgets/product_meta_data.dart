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
    final salePercentage = controller.calculateSalePercentage(product.price, product.salePrice);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.brand != null) ...[
          Text('${product.brand!.name.toUpperCase()} · ${product.categoryName}',
              style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1)),
          const SizedBox(height: 8),
        ],
        Text(product.title, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.8, height: 1.2)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TProductPriceText(price: controller.getProductPrice(product), isLarge: true),
            if (product.productType == ProductType.single.toString() && product.salePrice > 0)
              Text('\$${product.price}', style: theme.textTheme.bodySmall?.copyWith(
                  decoration: TextDecoration.lineThrough)),
            if (salePercentage != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('-$salePercentage%', style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.circle, size: 7,
                color: product.stock > 0 ? theme.colorScheme.primary : theme.colorScheme.error),
            const SizedBox(width: 8),
            Text('${controller.getProductStockStatus(product.stock)} · ${product.stock} pairs',
                style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
