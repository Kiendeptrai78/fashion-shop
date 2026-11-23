import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/features/personalization/screens/profile/controller/update_name_controller.dart';
import 'package:fashion_business_app/utils/constants/text_strings.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:fashion_business_app/utils/validators/validation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class ChangeName extends StatelessWidget {
  const ChangeName({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UpdateNameController());
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor:
          dark ? const Color(0xFF0E1713) : const Color(0xFFF4F6F2),
      appBar: TAppbar(
        showBackArrow: true,
        title: ShopText(
          'Change Name',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: dark
                    ? const Color(0xFF1A2D25)
                    : const Color(0xFFEAF3EE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF173E32).withValues(alpha: 0.16),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Iconsax.info_circle,
                    size: 19,
                    color: dark
                        ? const Color(0xFFDDEABB)
                        : const Color(0xFF173E32),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ShopText(
                      'User real name for easy verification. This name will appear on several pages.',
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: dark ? Colors.white70 : const Color(0xFF2B463B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF19251F) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE4EAE4),
                ),
              ),
              child: Form(
                key: controller.updateUserNameFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: controller.firstName,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => TValidator.validateEmptyText(
                        isEn ? 'First Name' : 'Tên',
                        value,
                      ),
                      decoration: InputDecoration(
                        labelText: TTexts.firstName.tr,
                        prefixIcon: const Icon(Iconsax.user),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controller.lastName,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => TValidator.validateEmptyText(
                        isEn ? 'Last Name' : 'Họ',
                        value,
                      ),
                      decoration: InputDecoration(
                        labelText: TTexts.lastName.tr,
                        prefixIcon: const Icon(Iconsax.user_edit),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF173E32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => controller.updateUserName(),
                child: const ShopText(
                  'Save',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
