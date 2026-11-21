import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/features/personalization/controllers/address_controller.dart';
import 'package:fashion_business_app/features/personalization/models/address_model.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class TSingleAddress extends StatelessWidget {
  const TSingleAddress({super.key, required this.address, required this.onTap});
  final AddressModel address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final selected = AddressController.instance.selectedAddress.value.id == address.id;
      return Padding(padding: const EdgeInsets.only(bottom: 16), child: Material(
        color: selected ? theme.colorScheme.primary.withValues(alpha: 0.05) : theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: selected ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.18))),
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16),
          child: Padding(padding: const EdgeInsets.all(20), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Icon(Iconsax.location, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(address.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                if (selected) Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 21),
              ]),
              const SizedBox(height: 16),
              Text(address.phoneNumber, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(address.toString(), style: theme.textTheme.bodySmall?.copyWith(height: 1.6)),
              const SizedBox(height: 16),
              ShopText(selected ? 'Default delivery address' : 'Use this address',
                  style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          )),
        ),
      ));
    });
  }
}
