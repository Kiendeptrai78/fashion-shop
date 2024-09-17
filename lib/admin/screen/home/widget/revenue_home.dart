import 'package:fashion_business_app/common/widgets/text/section_heading.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class RevenueHome extends StatelessWidget {
  const RevenueHome({
    super.key,
  });


  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(TSizes.spaceBtwItems),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const TSectionHeading(
                  title: 'Revenue',
                  showActionButton: false,
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Iconsax.arrow_right_3, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 20, // Đặt maxY thành một giá trị hợp lệ, ví dụ: 20
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: 8,
                        color: Colors.blue,
                      ),
                    ],
                    showingTooltipIndicators: [5],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: 10,
                        color: Colors.blue,
                      ),
                    ],
                    showingTooltipIndicators: [5],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: 14,
                        color: Colors.blue,
                      ),
                    ],
                    showingTooltipIndicators: [5],
                  ),
                  BarChartGroupData(
                    x: 3,
                    barRods: [
                      BarChartRodData(
                        toY: 15,
                        color: Colors.blue,
                      ),
                    ],
                    showingTooltipIndicators: [5],
                  ),
                  BarChartGroupData(
                    x: 4,
                    barRods: [
                      BarChartRodData(
                        toY: 13,
                        color: Colors.blue,
                      ),
                    ],
                    showingTooltipIndicators: [5],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwSections),
        ],
      ),
    );
  }
}
