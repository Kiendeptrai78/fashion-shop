import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/features/personalization/controllers/address_controller.dart';
import 'package:fashion_business_app/features/personalization/models/address_model.dart';
import 'package:fashion_business_app/features/personalization/screens/address/add_new_address.dart';
import 'package:fashion_business_app/features/personalization/screens/address/widgets/single_address.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});
  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _controller = AddressController.instance;
  late Future<List<AddressModel>> _addresses;
  late Worker _changes;

  @override
  void initState() {
    super.initState();
    _addresses = _controller.getAllUserAddresses();
    _changes = ever(_controller.refreshData, (_) => _reload());
  }

  Future<void> _reload() async {
    final request = _controller.getAllUserAddresses();
    setState(() { _addresses = request; });
    try { await request; } catch (_) { /* Rendered by FutureBuilder. */ }
  }

  @override
  void dispose() { _changes.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const TAppbar(showBackArrow: true, title: ShopText('My Address',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
    body: FutureBuilder<List<AddressModel>>(future: _addresses, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      }
      if (snapshot.hasError) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const ShopText('Couldn’t load addresses.'),
        TextButton(onPressed: _reload, child: const ShopText('Try again')),
      ]));
      final addresses = snapshot.data ?? [];
      return RefreshIndicator(onRefresh: _reload, child: ListView(
        physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(24), children: [
          const ShopText('A place for every delivery.', style: TextStyle(fontSize: 27,
              height: 1.2, fontWeight: FontWeight.w600, letterSpacing: -0.8)),
          const SizedBox(height: 12),
          ShopText(addresses.isEmpty ? 'Add your first address to make checkout easier.'
              : 'Choose where your next pair arrives.', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 28),
          if (addresses.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 60),
            child: Icon(Iconsax.location, size: 64, color: Theme.of(context).colorScheme.primary)),
          for (final address in addresses) TSingleAddress(address: address,
              onTap: () => _controller.selectAddress(address)),
        ],
      ));
    }),
    bottomNavigationBar: SafeArea(top: false, minimum: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: ElevatedButton(onPressed: () => Get.to(() => const AddNewAddressScreen()),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add, size: 18), SizedBox(width: 10), ShopText('Add new address'),
        ]))),
  );
}
