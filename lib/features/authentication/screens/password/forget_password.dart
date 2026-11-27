import 'package:fashion_business_app/common/widgets/login_signup/auth_scaffold.dart';
import 'package:fashion_business_app/features/authentication/controllers/forget_password/forget_passwrod_controller.dart';
import 'package:fashion_business_app/utils/constants/text_strings.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:fashion_business_app/utils/validators/validation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class ForgetPassword extends StatelessWidget {
  const ForgetPassword({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ForgetPasswordController>()
        ? ForgetPasswordController.instance : Get.put(ForgetPasswordController());
    return AuthScaffold(
      title: TTexts.forgetPasswordTitle,
      subtitle: TTexts.forgetPasswordSubTitle,
      symbol: Iconsax.key,
      child: Form(
        key: controller.forgetPasswordFormKey,
        child: Column(children: [
          TextFormField(
            controller: controller.email,
            validator: TValidator.validateEmail,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            autocorrect: false,
            decoration: InputDecoration(labelText: TTexts.email.tr,
              hintText: 'you@example.com', prefixIcon: const Icon(Iconsax.direct_right)),
          ),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => controller.sendPasswordResetEmail(),
            child: const ShopText('Send reset link'))),
        ]),
      ),
    );
  }
}
