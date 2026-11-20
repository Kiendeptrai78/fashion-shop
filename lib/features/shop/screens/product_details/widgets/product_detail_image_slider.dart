import 'package:fashion_business_app/features/shop/controllers/product/variation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/features/shop/controllers/product/images_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';

class TProductImageSlider extends StatelessWidget {
  const TProductImageSlider({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ImageController());
    final images = controller.getAllProductImages(product, resetSelection: false);
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.light
          ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: AspectRatio(
                aspectRatio: 1.3,
                child: Obx(() => TRoundedImage(
                  imageUrl: controller.selectedProductImage.value,
                  width: double.infinity,
                  height: double.infinity,
                  isNetworkImage: true,
                  onPressed: () => controller.showEnlargedImage(
                      controller.selectedProductImage.value),
                )),
              ),
            ),
            if (images.length > 1)
              SizedBox(
                height: 76,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, index) => Obx(() => TRoundedImage(
                    imageUrl: images[index],
                    width: 68,
                    height: 68,
                    isNetworkImage: true,
                    padding: const EdgeInsets.all(4),
                    backgroundColor: Colors.transparent,
                    borderRadius: 12,
                    border: Border.all(
                      color: controller.selectedProductImage.value == images[index]
                          ? theme.colorScheme.primary : Colors.transparent,
                    ),
                    onPressed: () {
                      final variant = product.productVariations?.where((v) => v.image == images[index]).firstOrNull;
                      final color = variant?.attributeValues['Color'];
                      if (color != null) VariationController.instance.onAttributeSelected(product, 'Color', color);
                      controller.selectedProductImage.value = images[index];
                    },
                  )),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
