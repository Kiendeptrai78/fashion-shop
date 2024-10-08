import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:fashion_business_app/common/widgets/icon/circular_icon.dart';
import 'package:fashion_business_app/features/shop/controllers/all_product_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/product_controller.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';

import '../../../features/shop/models/product_model.dart';

class AddProducts extends StatelessWidget {
  const AddProducts({super.key, this.product});

  final ProductModel? product;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AllProductController());

    final dark = THelperFunctions.isDarkMode(context);

    if (product != null) {
      controller.setProductData(product!);
    } else {
      controller.resetProductData();
    }
    return Scaffold(
      backgroundColor: dark ? TColors.black : TColors.light,
      appBar: TAppbar(
        title: product == null
            ? const Text('Add Products')
            : const Text('Update Products'),
        showBackArrow: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ///container1 - title.
            Container(
              decoration: BoxDecoration(
                color: dark ? TColors.black : TColors.light,
                borderRadius: BorderRadius.circular(22.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                child: Column(
                  children: [
                    TextField(
                      controller: controller.titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(
                      height: TSizes.spaceBtwItems,
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: TextField(
                          controller: controller.priceController,
                          decoration: const InputDecoration(labelText: 'Price'),
                          keyboardType: TextInputType.number,
                        )),
                        const SizedBox(
                          width: TSizes.spaceBtwInoutFields,
                        ),
                        Expanded(
                            child: TextField(
                          controller: controller.salePriceController,
                          decoration:
                              const InputDecoration(labelText: 'Sale Price'),
                          keyboardType: TextInputType.number,
                        )),
                      ],
                    ),
                    const SizedBox(
                      height: TSizes.spaceBtwItems,
                    ),
                    TextField(
                      controller: controller.stockController,
                      decoration: const InputDecoration(labelText: 'Stock'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(
                      height: TSizes.spaceBtwItems,
                    ),
                    TextField(
                      controller: controller.descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(
                      height: TSizes.spaceBtwItems,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: TSizes.spaceBtwItems,
            ),

            ///container2 - thumbnail - image.
            Container(
              decoration: BoxDecoration(
                color: dark ? TColors.black : TColors.light,
                borderRadius: BorderRadius.circular(22.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ///thumbnail
                        GestureDetector(
                          onTap: () =>
                              controller.pickAndUploadImageForThumbnail(),
                          child: Obx(() => Column(
                                children: [
                                  controller.imageUrl.value.isNotEmpty
                                      ? Image.network(controller.imageUrl.value,
                                          height: 200, width: 200)
                                      : Container(
                                          height: 200,
                                          width: 200,
                                          color: dark
                                              ? TColors.dark
                                              : TColors.white,
                                          child: const Icon(Icons.add),
                                        ),
                                ],
                              )),
                        ),
                        const SizedBox(
                          height: TSizes.spaceBtwItems / 2,
                        ),
                        TextButton(
                            onPressed: () =>
                                controller.pickAndUploadImageForThumbnail(),
                            child: const Text('Choose Thumbnail Image ')),
                      ],
                    ),
                    const Divider(),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Obx(() {
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: List.generate(
                                          controller.images.length, (index) {
                                        final imageController =
                                            controller.images[index];
                                        return Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Stack(
                                            children: [
                                              Image.network(
                                                imageController.text,
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              ),
                                              Positioned(
                                                right: 0,
                                                top: 0,
                                                child: IconButton(
                                                  icon: const Icon(
                                                      Icons.remove_circle,
                                                      color: Colors.red),
                                                  onPressed: () {
                                                    // Xóa ảnh khỏi danh sách
                                                    controller.images
                                                        .removeAt(index);
                                                    controller.images.refresh();
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ),
                                  );
                                }),

                        const SizedBox(height: 16),
                        TextButton(
                            onPressed: () =>
                                controller.pickAndUploadImagesForProduct(),
                            child: const Text('Choose Product Image ')),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: TSizes.spaceBtwItems,
            ),

            ///isFeatured
            Container(
              decoration: BoxDecoration(
                color: dark ? TColors.black : TColors.light,
                borderRadius: BorderRadius.circular(22.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                child: Column(
                  children: [
                    ///show ui
                    Obx(() => Row(
                          children: [
                            const Text('Show UI User: '),
                            const SizedBox(width: TSizes.spaceBtwSections),
                            Switch(
                              value: controller.isFeatured.value,
                              onChanged: (value) =>
                                  controller.isFeatured.value = value,
                            ),
                          ],
                        )),
                    const SizedBox(height: TSizes.spaceBtwItems),


                    const SizedBox(
                      height: TSizes.spaceBtwItems,
                    ),

                    ///productType
                    Row(
                      children: [
                        const Text('Type product: '),
                        const SizedBox(
                          width: TSizes.spaceBtwSections,
                        ),
                        Obx(() => DropdownButton<ProductType>(
                              value: controller.selectedProductType.value,
                              onChanged: (newValue) {
                                controller.selectedProductType.value =
                                    newValue!;
                              },
                              items: ProductType.values.map((type) {
                                return DropdownMenuItem<ProductType>(
                                  value: type,
                                  child: Text(type == ProductType.single
                                      ? 'Single'
                                      : 'Variable'),
                                );
                              }).toList(),
                            )),
                      ],
                    ),
                    const SizedBox(
                      height: TSizes.spaceBtwItems,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            Obx(() {
              if (controller.selectedProductType.value != ProductType.single) {
                return Column(
                  children: [
                    _Attributes(dark, controller),
                    const SizedBox(height: 10,),
                    _Variations(dark, controller),
                  ],
                );
              } else {
                // Nếu là Single, không hiển thị _Attributes và _Variations
                return const SizedBox(); // Trả về một widget rỗng để không hiển thị gì
              }
            }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final product = this.product;
          if (product != null) {
            await controller.updateProductData(product); // Hàm update sản phẩm
          } else {
            await AllProductController.instance
                .saveProduct(); // Hàm lưu sản phẩm mới
          }
        },
        child: const Icon(Icons.save),
      ),
    );
  }

  Container _Variations(bool dark, AllProductController controller) {
    return Container(
            decoration: BoxDecoration(
              color: dark ? TColors.black : TColors.light,
              borderRadius: BorderRadius.circular(22.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8.0,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Obx(
                    () => Column(
                      children: [
                        ...List.generate(controller.variations.length,
                            (index) {
                          final variation = controller.variations[index];
                          return Column(
                            children: [
                              const SizedBox(height: 16.0),
                              Column(
                                children: [
                                  const Text('Product image'),
                                  const SizedBox(
                                      height: TSizes.spaceBtwItems / 2),
                                  GestureDetector(
                                    onTap: () => controller
                                        .pickAndUploadImageForVariation(
                                            index),
                                    child: variation.image.isNotEmpty
                                        ? Image.network(
                                            variation.image,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            height: 100,
                                            width: 100,
                                            color: dark
                                                ? TColors.dark
                                                : TColors.white,
                                            child: const Icon(Icons.add),
                                          ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16.0),
                              TextField(
                                decoration: InputDecoration(
                                    labelText:
                                        'Variation Price ${index + 1}'),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  variation.price =
                                      double.tryParse(value) ?? 0.0;
                                  controller.variations[index] =
                                      variation; // Cập nhật giá trị

                                },
                              ),
                              const SizedBox(height: 16.0),
                              TextField(
                                decoration: InputDecoration(
                                    labelText:
                                        'Variation Sale Price ${index + 1}'),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  variation.salePrice =
                                      double.tryParse(value) ?? 0.0;
                                  controller.variations[index] =
                                      variation; // Cập nhật giá trị

                                },
                              ),
                              const SizedBox(height: 16.0),
                              TextField(
                                decoration: InputDecoration(
                                    labelText:
                                        'Variation Stock ${index + 1}'),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  variation.stock = int.tryParse(value) ?? 0;
                                  controller.variations[index] =
                                      variation; // Cập nhật giá trị

                                },

                              ),
                              const SizedBox(height: 16.0),
                              TextField(
                                decoration: InputDecoration(
                                    labelText: 'Color ${index + 1}'),
                                onChanged: (value) {
                                  variation.attributeValues['Color'] = value;
                                  controller.variations[index] =
                                      variation; // Cập nhật giá trị

                                },

                              ),
                              const SizedBox(height: 16.0),
                              TextField(
                                decoration: InputDecoration(
                                    labelText: 'Size ${index + 1}'),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  variation.attributeValues['Size'] = value;

                                },

                              ),
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () =>
                                    controller.removeVariation(index),
                              ),
                            ],
                          );
                        }),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: controller.addVariation,
                            child: const Text('Add products'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
            ),
          );
  }

  Container _Attributes(bool dark, AllProductController controller) {
    return Container(
            decoration: BoxDecoration(
              color: dark ? TColors.black : TColors.light,
              borderRadius: BorderRadius.circular(22.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8.0,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Obx(() => Column(
                        children: List.generate(controller.attributes.length,
                            (index) {
                          final attribute = controller.attributes[index];
                          return Column(
                            children: [
                              TextField(
                                decoration: InputDecoration(
                                    labelText: 'Color and Size ${index + 1}'),
                                controller: TextEditingController(
                                    text: attribute.name),
                                onChanged: (value) {
                                  attribute.name = value;
                                },
                              ),
                              const SizedBox(height: 8),
                              Column(
                                children: List.generate(
                                    attribute.values!.length, (valueIndex) {
                                  final textController =
                                      TextEditingController(
                                          text:
                                              attribute.values?[valueIndex]);
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: textController,
                                          decoration: InputDecoration(
                                              labelText:
                                                  'Value ${valueIndex + 1}'),
                                          onChanged: (newValue) {
                                            attribute.values?[valueIndex] =
                                                newValue;
                                            controller.attributes.refresh();
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () => controller
                                            .removeValue(index, valueIndex),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => controller.addValue(index),
                                  child: const Text('Add values'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () =>
                                      controller.removeAttribute(index),
                                  child: const Text('Remove'),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        }),
                      )),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: controller.addAttribute,
                      child: const Text('Add attributes'),
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
