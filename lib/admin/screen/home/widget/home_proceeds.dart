import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:fashion_business_app/admin/screen/orders/order_admin.dart';
import 'package:fashion_business_app/common/widgets/custom_shapes/containers/search_container.dart';
import 'package:fashion_business_app/common/widgets/text/section_heading.dart';
import 'package:fashion_business_app/features/shop/controllers/product/order_controller.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';
import 'package:date_picker_plus/date_picker_plus.dart';

import 'proceed_detail.dart';
import 'product_home_proceed.dart';
import 'revenue_home.dart';

class HomeProceeds extends StatelessWidget {
  const HomeProceeds({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final orderController = Get.put(OrderController());
    final now = DateTime.now();

    // Gọi hàm fetchReceivedOrders để lấy dữ liệu
    orderController.fetchReceivedOrders();

    return SingleChildScrollView(
      child: Column(
        children: [
          /// Header
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
              padding: const EdgeInsets.all(TSizes.spaceBtwSections),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ///search date
                  /// Dropdown menu cho các tùy chọn ngày
                  Obx(() {
                    return DropdownButtonFormField<String>(
                      value: orderController.selectedDateRange.value,
                      items: [
                        DropdownMenuItem(
                          value: 'today',
                          child: Text('Today, ${DateFormat('dd/MM/yyyy').format(now)}',
                              style: const TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'yesterday',
                          child: Text('Yesterday, ${DateFormat('dd/MM/yyyy').format(now.subtract(const Duration(days: 1)))}',
                              style: const TextStyle(fontSize: 12)),
                        ),
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('All', style: TextStyle(fontSize: 12)),
                        ),
                        const DropdownMenuItem(
                          value: 'custom',
                          child: Text('Custom', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        orderController.selectedDateRange.value = newValue!;
                        orderController.updateDateRange();
                      },
                    );
                  }),
                  const SizedBox(height: TSizes.spaceBtwItems),



                  /// Hiển thị các picker date nếu chọn "Tùy chỉnh"
                  Obx(() {
                    if (orderController.selectedDateRange.value == 'custom') {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              DateTime? selectedDate = await showDatePicker(
                                context: context,
                                initialDate: orderController.startDate.value ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (selectedDate != null) {
                                orderController.startDate.value = selectedDate;
                                orderController.filterOrdersByDate();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Obx(() => Text(
                                'Start Date: ${orderController.startDate.value != null ? DateFormat('dd/MM/yyyy').format(orderController.startDate.value!) : 'Select Date'}',
                                style: const TextStyle(fontSize: 14),
                              )),
                            ),
                          ),

                          const SizedBox(height: 16),

                          GestureDetector(
                            onTap: () async {
                              DateTime? selectedDate = await showDatePicker(
                                context: context,
                                initialDate: orderController.endDate.value ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (selectedDate != null) {
                                orderController.endDate.value = selectedDate;
                                orderController.filterOrdersByDate();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Obx(() => Text(
                                'End Date: ${orderController.endDate.value != null ? DateFormat('dd/MM/yyyy').format(orderController.endDate.value!) : 'Select Date'}',
                                style: const TextStyle(fontSize: 14),
                              )),
                            ),
                          ),
                        ],
                      );
                    }
                    return Container();
                  }),
                  const SizedBox(height: TSizes.spaceBtwItems),

                  ///profit
                 GestureDetector(
                   onTap: () => Get.to((const ProceedDetail())),
                   child:  Container(
                     decoration: BoxDecoration(
                       color: dark ? TColors.black : TColors.light,
                       borderRadius: BorderRadius.circular(16.0),
                       boxShadow: const [
                         BoxShadow(
                           color: Colors.black26,
                           blurRadius: 8.0,
                           offset: Offset(0, 4),
                         ),
                       ],
                     ),
                     width: 300,
                     height: 180,
                     padding: const EdgeInsets.all(16.0),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Obx(() {
                           return Row(
                             children: [
                               Text(
                                 '${orderController.receivedOrdersCount.value} Orders',
                                 style: const TextStyle(
                                   fontSize: 12,
                                 ),
                               ),
                               const SizedBox(width: TSizes.spaceBtwSections * 4),
                               const Text(
                                 'profit',
                                 style: TextStyle(
                                   fontSize: 12,
                                 ),
                               ),
                               const SizedBox(width: TSizes.spaceBtwItems / 1.5),
                               const Icon(Iconsax.eye_slash),
                             ],
                           );
                         }),
                         const SizedBox(height: TSizes.spaceBtwItems),
                         Obx(() {
                           orderController.fetchAllUserOrders();
                           return Row(
                             children: [
                               Text(
                                 '${orderController.totalProfit.value.toStringAsFixed(1)} \$',
                                 style: const TextStyle(
                                   fontSize: 24,
                                   fontWeight: FontWeight.bold,
                                   color: Colors.blue,
                                 ),
                               ),
                               const SizedBox(width: TSizes.spaceBtwSections * 3.5),
                               const Text(
                                 '*****',
                                 style: TextStyle(
                                   fontSize: 16,
                                 ),
                               ),
                             ],
                           );
                         }),
                         const SizedBox(height: TSizes.spaceBtwItems),
                         const Divider(),
                         const SizedBox(height: TSizes.spaceBtwItems / 2),
                         const Row(
                           children: [
                             Icon(Iconsax.receipt),
                             SizedBox(width: TSizes.spaceBtwItems / 4),
                             Text(
                               '0 returns',
                               style: TextStyle(
                                 fontSize: 16,
                               ),
                             ),
                           ],
                         ),
                       ],
                     ),
                   ),
                 ),
                  const SizedBox(height: TSizes.spaceBtwSections),

                  /// Các sản phẩm
                   const ProductHomeProceed(),
                ],
              ),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),

          /// Body
          const RevenueHome(),
          const SizedBox(height: TSizes.spaceBtwSections),
        ],
      ),
    );
  }
}


