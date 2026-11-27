import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/features/personalization/controllers/address_controller.dart';
import 'package:fashion_business_app/features/personalization/models/address_model.dart';
import 'package:fashion_business_app/features/personalization/screens/address/add_new_address.dart';
import 'package:fashion_business_app/features/personalization/screens/address/widgets/single_address.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class AddressSelectionSheet extends StatefulWidget {
  const AddressSelectionSheet({super.key, this.loadAddresses, this.addAddress});
  final Future<List<AddressModel>> Function()? loadAddresses;
  final Future<void> Function()? addAddress;
  @override
  State<AddressSelectionSheet> createState() => _AddressSelectionSheetState();
}

class _AddressSelectionSheetState extends State<AddressSelectionSheet> {
  late Future<List<AddressModel>> _addresses;
  bool _adding = false;
  Future<List<AddressModel>> _load() => widget.loadAddresses?.call()
      ?? AddressController.instance.getAllUserAddresses();
  @override
  void initState() { super.initState(); _addresses = _load(); }

  Future<void> _add() async {
    setState(() => _adding = true);
    try {
      if (widget.addAddress != null) { await widget.addAddress!(); }
      else { await Get.to(() => const AddNewAddressScreen()); }
      if (!mounted) return;
      setState(() { _addresses = _load(); });
    } finally { if (mounted) setState(() => _adding = false); }
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: DraggableScrollableSheet(
    initialChildSize: 0.78, minChildSize: 0.45, maxChildSize: 0.94, expand: false,
    builder: (context, scroll) => Column(children: [
      const SizedBox(height: 12),
      Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.black12,
          borderRadius: BorderRadius.circular(4))),
      Padding(padding: const EdgeInsets.fromLTRB(24, 18, 12, 12), child: Row(children: [
        const Expanded(child: ShopText('Select Address', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
        ShopGlassIconButton(onPressed: () => Navigator.pop(context), icon: Icons.close),
      ])),
      Expanded(child: FutureBuilder<List<AddressModel>>(future: _addresses, builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        if (snapshot.hasError) return Center(child: TextButton(onPressed: () => setState(() { _addresses = _load(); }),
            child: const ShopText('Try again')));
        final addresses = snapshot.data ?? [];
        return ListView(controller: scroll, padding: const EdgeInsets.symmetric(horizontal: 24), children: [
          if (addresses.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 48),
            child: Column(children: [Icon(Iconsax.location, size: 48), SizedBox(height: 20),
              ShopText('Add your first address to make checkout easier.', textAlign: TextAlign.center)])),
          for (final address in addresses) TSingleAddress(
            address: address,
            onTap: () async {
              if (await AddressController.instance.selectAddress(address) && context.mounted) Navigator.pop(context);
            },
            onEdit: () async {
              await Get.to(() => AddNewAddressScreen(editingAddress: address));
              if (!mounted) return;
              setState(() { _addresses = _load(); });
            },
          ),
        ]);
      })),
      Padding(padding: const EdgeInsets.all(24), child: SizedBox(width: double.infinity,
          child: ElevatedButton(onPressed: _adding ? null : _add, child: const ShopText('Add new address')))),
    ]),
  ));
}
