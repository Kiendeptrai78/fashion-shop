import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/features/shop/models/shipping_route_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/features/personalization/controllers/address_controller.dart';
import 'package:fashion_business_app/features/personalization/models/address_model.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class TSingleAddress extends StatelessWidget {
  const TSingleAddress({
    super.key,
    required this.address,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final AddressModel address;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  String _formattedDisplayAddress() {
    final parts = <String>[];
    for (final raw in [address.street, address.state, address.city]) {
      final clean = raw.trim();
      if (clean.isNotEmpty &&
          !parts.any((p) => p.toLowerCase() == clean.toLowerCase())) {
        parts.add(clean);
      }
    }
    return parts.isNotEmpty ? parts.join(', ') : address.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final eta = ShippingRouteHelper.estimateForAddress(address);

    return Obx(() {
      final selected =
          AddressController.instance.selectedAddress.value.id == address.id;
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Material(
          color: selected
              ? (dark
                  ? const Color(0xFF1A3329)
                  : const Color(0xFFF1F7F4))
              : (dark ? const Color(0xFF18221D) : Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              width: selected ? 1.6 : 1,
              color: selected
                  ? const Color(0xFF173E32)
                  : theme.dividerColor.withValues(alpha: 0.2),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: ShopGlassDecoration(
                          color: selected
                              ? const Color(0xFF173E32)
                              : (dark
                                  ? const Color(0xFF23352D)
                                  : const Color(0xFFEAF1EC)),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          Iconsax.location,
                          size: 18,
                          color: selected
                              ? const Color(0xFFDDEABB)
                              : const Color(0xFF173E32),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  address.name,
                                  softWrap: true,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (selected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF173E32),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      isEn ? 'Default' : 'Mặc định',
                                      style: const TextStyle(
                                        color: Color(0xFFDDEABB),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              address.phoneNumber,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF173E32),
                          size: 22,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formattedDisplayAddress(),
                    softWrap: true,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Live Distance & ETA info pill from Tổng Kho Hà Nội
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: dark
                          ? const Color(0xFF122C38)
                          : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.truck_fast,
                          size: 14,
                          color: dark
                              ? const Color(0xFF7DD3FC)
                              : const Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isEn
                                ? 'From Hanoi Hub • ~${eta.distanceKm} km • ${eta.minDays}–${eta.maxDays} days'
                                : 'Từ Kho Hà Nội • ~${eta.distanceKm} km • Giao ${eta.minDays}–${eta.maxDays} ngày',
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: dark
                                  ? const Color(0xFFBAE6FD)
                                  : const Color(0xFF0369A1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ShopText(
                          selected
                              ? 'Default delivery address'
                              : 'Use this address',
                          softWrap: true,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF173E32)
                                : theme.hintColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (onEdit != null)
                        TextButton.icon(
                          onPressed: onEdit,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF173E32),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Iconsax.edit_2, size: 15),
                          label: Text(
                            isEn ? 'Edit' : 'Sửa',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (onDelete != null) ...[
                        const SizedBox(width: 4),
                        TextButton.icon(
                          onPressed: onDelete,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFC62828),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Iconsax.trash, size: 15),
                          label: Text(
                            isEn ? 'Delete' : 'Xóa',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
