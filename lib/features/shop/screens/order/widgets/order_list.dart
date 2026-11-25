import 'package:fashion_business_app/common/widgets/loaders/animation_loader.dart';
import 'package:fashion_business_app/features/shop/controllers/product/order_controller.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/features/shop/screens/order/order_detail.dart';
import 'package:fashion_business_app/navigation_menu.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/constants/image_strings.dart';
import 'package:fashion_business_app/utils/helpers/cloud_helper_function.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class TOrderListItem extends StatelessWidget {
  const TOrderListItem({super.key});

  Widget _statusBadge(OrderModel order, bool isEn) {
    final isCancelled = order.status == OrderStatus.cancelled;
    final isReceived = order.status == OrderStatus.received;
    final textColor = isCancelled
        ? const Color(0xFFB91C1C)
        : (isReceived ? const Color(0xFF15803D) : const Color(0xFF1E293B));
    final bgColor = isCancelled
        ? const Color(0xFFFEF2F2)
        : (isReceived ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        order.orderStatusLabel(english: isEn),
        style: TextStyle(
          color: textColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OrderController());
    final lang = Localizations.localeOf(context).languageCode;
    final isEn = lang == 'en';

    return FutureBuilder(
      future: controller.fetUserOrders(),
      builder: (_, snapshot) {
        final emptyWidget = TAnimationLoaderWidget(
          text: 'Whoop! No Order Yet!',
          animation: TImages.masterCard,
          showAction: true,
          actionText: 'Let\'s fill it',
          onActionPressed: () => Get.off(() => const NavigationMenu()),
        );

        final response = TCloudHelperFunctions.checkMultiRecordState(
          snapshot: snapshot,
          nothingFound: emptyWidget,
        );
        if (response != null) return response;

        final orders = snapshot.data!;
        return ListView.separated(
          shrinkWrap: true,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: orders.length,
          itemBuilder: (_, index) {
            final order = orders[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Get.to(() => OrderDetail(order: order)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ShopText(
                            order.formattedOrderDate,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          _statusBadge(order, isEn),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        order.itemsSummary(english: isEn),
                        softWrap: true,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order.discountAmount > 0 &&
                                      order.couponCode.trim().isNotEmpty
                                  ? '${order.formattedDeliveryDate} · Mã ${order.couponCode.trim().toUpperCase()}'
                                  : order.formattedDeliveryDate,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          Text(
                            formatShopMoney(order.totalAmount, language: lang),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Iconsax.arrow_right_34,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
