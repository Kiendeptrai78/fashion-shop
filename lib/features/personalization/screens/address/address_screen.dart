import 'package:fashion_business_app/common/widgets/dialogs/velora_confirm_dialog.dart';
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

  Future<void> _confirmDelete(AddressModel address) async {
    final confirmed = await showVeloraConfirmDialog(
      context,
      title: 'Xóa địa chỉ này?',
      message: 'Địa chỉ của ${address.name} (${address.city}) sẽ bị xóa khỏi sổ địa chỉ nhận hàng của bạn.',
      confirmLabel: 'Xóa địa chỉ',
      cancelLabel: 'Hủy',
      destructive: true,
    );
    if (confirmed == true) {
      await _controller.deleteAddress(address);
    }
  }

  @override
  void dispose() { _changes.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
      extendBodyBehindAppBar: true,
    appBar: const TAppbar(showBackArrow: true, title: ShopText('My Address',
        style: shopAppbarTitleStyle)),
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
        physics: const AlwaysScrollableScrollPhysics(), padding: shopAppbarContentPadding(context, EdgeInsets.all(20)), children: [
          const ShopText('A place for every delivery.', style: TextStyle(fontSize: 25,
              height: 1.2, fontWeight: FontWeight.w700, letterSpacing: -0.6)),
          const SizedBox(height: 8),
          ShopText(addresses.isEmpty ? 'Add your first address to make checkout easier.'
              : 'Choose where your next pair arrives.', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 22),
          if (addresses.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 60),
            child: Icon(Iconsax.location, size: 64, color: Theme.of(context).colorScheme.primary)),
          for (final address in addresses) TSingleAddress(
            address: address,
            onTap: () => _controller.selectAddress(address),
            onEdit: () => Get.to(() => AddNewAddressScreen(editingAddress: address)),
            onDelete: () => _confirmDelete(address),
          ),
        ],
      ));
    }),
    bottomNavigationBar: SafeArea(top: false, minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: ElevatedButton(onPressed: () => Get.to(() => const AddNewAddressScreen()),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add, size: 18), SizedBox(width: 10), ShopText('Add new address'),
        ]))),
  );
}
