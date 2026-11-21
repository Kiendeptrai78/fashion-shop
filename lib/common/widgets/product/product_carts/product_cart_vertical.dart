import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/common/widgets/product/favourite_icon/favourite_icon.dart';
import 'package:fashion_business_app/features/shop/controllers/product/product_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/screens/product_details/product_details.dart';

class TProductCartVertical extends StatelessWidget {
  const TProductCartVertical({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = ProductController.instance;
    final colors = product.productAttributes?.where((a) => a.name == 'Color').firstOrNull?.values;
    final sale = product.salePrice > 0 && product.salePrice < product.price;
    return Semantics(
      button: true,
      label: '${product.brand?.name ?? ''} ${product.title}',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.to(() => ProductDetail(product: product)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Stack(fit: StackFit.expand, children: [
                ColoredBox(color: theme.brightness == Brightness.dark
                    ? const Color(0xFF22342B) : const Color(0xFFF1F2ED)),
                TRoundedImage(imageUrl: product.thumbnail, isNetworkImage: true,
                    width: double.infinity, height: double.infinity,
                    padding: const EdgeInsets.fromLTRB(10, 26, 10, 16), borderRadius: 0),
                Positioned(top: 0, right: 0, child: TFavouriteIcon(productId: product.id)),
                if (sale)
                  Positioned(top: 12, left: 10, child: ShopText('SALE',
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary, fontWeight: FontWeight.w700, letterSpacing: 0.7))),
              ])),
            ),
            const SizedBox(height: 12),
            ShopText(product.brand?.name ?? product.categoryName,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(fontSize: 11)),
            const SizedBox(height: 4),
            ShopText(product.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.3)),
            const SizedBox(height: 4),
            ShopText(colors == null ? product.categoryName : '${colors.length} colors · ${product.categoryName}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(fontSize: 11)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              ShopText(formatShopPrice(controller.getProductPrice(product), language: Localizations.localeOf(context).languageCode),
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
              if (sale)
                ShopText(formatShopMoney(product.price, language: Localizations.localeOf(context).languageCode),
                    style: theme.textTheme.labelMedium?.copyWith(decoration: TextDecoration.lineThrough)),
            ]),
          ],
        ),
      ),
    );
  }
}
