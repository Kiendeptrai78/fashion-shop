import 'package:get/get.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/images_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/models/product_variation_model.dart';

class VariationController extends GetxController {
  static VariationController get instance => Get.find();

  final selectedAttributes = <String, String>{}.obs;
  final variationStockStatus = ''.obs;
  final selectedVariation = ProductVariationModel.empty().obs;

  void onAttributeSelected(ProductModel product, String attributeName, String attributeValue) {
    selectedAttributes[attributeName] = attributeValue;
    final variants = product.productVariations ?? [];
    if (attributeName == 'Color') {
      final colorVariants = variants.where((v) => v.attributeValues['Color'] == attributeValue);
      if (selectedAttributes['Size'] != null && !colorVariants.any((v) =>
          v.attributeValues['Size'] == selectedAttributes['Size'] && v.stock > 0)) {
        selectedAttributes.remove('Size');
      }
      final preview = colorVariants.firstOrNull;
      if (preview != null && preview.image.isNotEmpty && Get.isRegistered<ImageController>()) {
        ImageController.instance.selectedProductImage.value = preview.image;
      }
    }
    final selected = variants.firstWhere((v) =>
        v.attributeValues.length == selectedAttributes.length &&
        v.attributeValues.entries.every((e) => selectedAttributes[e.key] == e.value),
        orElse: ProductVariationModel.empty);
    selectedVariation.value = selected;
    variationStockStatus.value = selected.stock > 0 ? 'In stock' : 'Out of stock';
    if (selected.image.isNotEmpty && Get.isRegistered<ImageController>()) {
      ImageController.instance.selectedProductImage.value = selected.image;
    }
    if (Get.isRegistered<CartController>()) {
      final cart = CartController.instance;
      final existing = cart.getVariationQuantityInCart(product.id, selected.id);
      cart.productQuantityInCart.value = selected.stock > 0
          ? existing.clamp(1, selected.stock).toInt() : 1;
    }
  }

  Set<String?> getAttributeAvailabilityInVariation(
      List<ProductVariationModel> variations, String attributeName) {
    return variations.where((v) {
      if (v.stock <= 0) return false;
      if (attributeName == 'Color') return true;
      return selectedAttributes.entries.where((e) => e.key != attributeName)
          .every((e) => v.attributeValues[e.key] == e.value);
    }).map((v) => v.attributeValues[attributeName]).whereType<String>().toSet();
  }

  String getVariationPrice() {
    final price = selectedVariation.value.salePrice > 0
        ? selectedVariation.value.salePrice : selectedVariation.value.price;
    return price.toStringAsFixed(price % 1 == 0 ? 0 : 2);
  }

  void getProductVariationStockStatus() {
    variationStockStatus.value = selectedVariation.value.stock > 0 ? 'In stock' : 'Out of stock';
  }

  void resetSelectedAttribute() {
    selectedAttributes.clear();
    variationStockStatus.value = '';
    selectedVariation.value = ProductVariationModel.empty();
  }
}
