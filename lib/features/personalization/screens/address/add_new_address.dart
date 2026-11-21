import 'widgets/address_map_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/features/personalization/controllers/address_controller.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:fashion_business_app/utils/validators/validation.dart';

class AddNewAddressScreen extends StatelessWidget {
  const AddNewAddressScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = AddressController.instance;
    return Scaffold(
      appBar: const TAppbar(showBackArrow: true, title: ShopText('Add new address',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
      body: Form(key: controller.addressFormKey, child: ListView(
        padding: const EdgeInsets.all(24), children: [
          const ShopText('Ready for delivery.', style: TextStyle(fontSize: 28,
              height: 1.2, fontWeight: FontWeight.w600, letterSpacing: -0.8)),
          const SizedBox(height: 12),
          const ShopText('Add the details that help your pair reach you.', style: TextStyle(height: 1.6)),
          const SizedBox(height: 28),
          const ShopText('Recipient', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          _field(controller.name, 'Name', Iconsax.user, autofill: AutofillHints.name),
          const SizedBox(height: 18),
          TextFormField(controller: controller.phoneNumber,
            keyboardType: TextInputType.phone, autofillHints: const [AutofillHints.telephoneNumber],
            validator: TValidator.validatePhoneNumber,
            decoration: InputDecoration(prefixIcon: const Icon(Iconsax.mobile), labelText: 'Phone Number'.tr)),
          const Divider(height: 48),
          const ShopText('Delivery address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          _field(controller.street, 'Street', Iconsax.building_31, autofill: AutofillHints.streetAddressLine1),
          const SizedBox(height: 18),
          _field(controller.city, 'City', Iconsax.building),
          const SizedBox(height: 18),
          _field(controller.state, 'State', Iconsax.location),
          const SizedBox(height: 18),
          _field(controller.country, 'Country', Iconsax.global, autofill: AutofillHints.countryName),
          const SizedBox(height: 24),
          Obx(() => AddressMapPicker(value: controller.location.value,
              onChanged: (point) => controller.location.value = point)),
          const SizedBox(height: 24),
        ],
      )),
      bottomNavigationBar: SafeArea(top: false, minimum: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: ElevatedButton(onPressed: controller.addNewAddresses, child: const ShopText('Save address'))),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon, {String? autofill}) => TextFormField(
    controller: controller, textCapitalization: TextCapitalization.words,
    autofillHints: autofill == null ? null : [autofill], textInputAction: TextInputAction.next,
    validator: (value) => TValidator.validateEmptyText(label.tr, value),
    decoration: InputDecoration(prefixIcon: Icon(icon), labelText: label.tr),
  );
}
