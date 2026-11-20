import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/features/shop/controllers/product/variation_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';

class TProductAttribute extends StatelessWidget {
  const TProductAttribute({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final controller = VariationController.instance;
    final theme = Theme.of(context);
    final attributes = product.productAttributes ?? [];
    final colors = attributes.where((a) => a.name == 'Color').firstOrNull?.values ?? [];
    final sizes = attributes.where((a) => a.name == 'Size').firstOrNull?.values ?? [];
    return Obx(() {
      final color = controller.selectedAttributes['Color'];
      final size = controller.selectedAttributes['Size'];
      final selected = controller.selectedVariation.value;
      final availableSizes = controller.getAttributeAvailabilityInVariation(
          product.productVariations ?? [], 'Size');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (colors.isNotEmpty) ...[
            Row(children: [
              Text('Color', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Expanded(child: Text(color ?? 'Choose a color', style: theme.textTheme.bodySmall)),
            ]),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, constraints) {
              final width = (constraints.maxWidth - 24) / 3;
              return Wrap(spacing: 12, runSpacing: 12, children: [
                for (final value in colors)
                  SizedBox(
                    width: width,
                    child: Semantics(
                      button: true, selected: color == value, label: 'Color $value',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => controller.onAttributeSelected(product, 'Color', value),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(width: color == value ? 1.5 : 1,
                              color: color == value ? theme.colorScheme.onSurface
                                  : theme.dividerColor.withValues(alpha: 0.2)),
                          ),
                          child: Column(children: [
                            TRoundedImage(
                              imageUrl: product.productVariations?.where((v) =>
                                  v.attributeValues['Color'] == value).firstOrNull?.image ?? '',
                              isNetworkImage: true, width: width - 16, height: 56,
                            ),
                            const SizedBox(height: 6),
                            Text(value, maxLines: 2, overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center, style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: color == value ? FontWeight.w600 : FontWeight.w400)),
                          ]),
                        ),
                      ),
                    ),
                  ),
              ]);
            }),
            const SizedBox(height: 28),
          ],
          Row(children: [
            Expanded(child: Text('Select size', style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600))),
            Text('EU sizing', style: theme.textTheme.bodySmall),
          ]),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final width = (constraints.maxWidth - 32) / 5;
            return Wrap(spacing: 8, runSpacing: 8, children: [
              for (final value in sizes)
                SizedBox(
                  width: width, height: 48,
                  child: OutlinedButton(
                    onPressed: availableSizes.contains(value)
                        ? () => controller.onAttributeSelected(product, 'Size', value) : null,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: size == value ? theme.colorScheme.surface : theme.colorScheme.onSurface,
                      backgroundColor: size == value ? theme.colorScheme.onSurface : null,
                      side: BorderSide(color: size == value ? theme.colorScheme.onSurface
                          : theme.dividerColor.withValues(alpha: 0.25)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(value, style: TextStyle(
                        decoration: availableSizes.contains(value) ? null : TextDecoration.lineThrough)),
                  ),
                ),
            ]);
          }),
          const SizedBox(height: 14),
          Text(selected.id.isEmpty ? 'Choose a size to check availability.'
              : selected.stock > 0 ? '${selected.stock} pairs available in EU $size.'
                  : 'This color and size is currently sold out.',
              style: theme.textTheme.bodySmall),
        ],
      );
    });
  }
}
