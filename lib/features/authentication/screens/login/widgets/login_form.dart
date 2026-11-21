import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/features/authentication/controllers/login/login_controller.dart';
import 'package:fashion_business_app/features/authentication/screens/password/forget_password.dart';
import 'package:fashion_business_app/features/authentication/screens/signup/signup.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/constants/text_strings.dart';
import 'package:fashion_business_app/utils/validators/validation.dart';

class TLoginForm extends StatelessWidget {
  const TLoginForm({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<LoginController>() ? Get.find<LoginController>() : Get.put(LoginController());
    return Form(
        key: controller.loginFormKey,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: TSizes.spaceBtwSections),
          child: Column(
            children: [
              ///email
              TextFormField(
                controller: controller.email,
                validator: (value) => TValidator.validateEmail(value) ,
                decoration: InputDecoration(
                    prefixIcon: Icon(Iconsax.direct_right),
                    labelText: TTexts.email.tr),
              ),
              const SizedBox(
                height: TSizes.spaceBtwInoutFields,
              ),

              ///password
              Obx(() => TextFormField(
                controller: controller.password,
                validator: (value) => TValidator.validatePassword(value),
                obscureText: controller.hidePassword.value,
                expands: false,
                decoration:  InputDecoration(
                    labelText: TTexts.password.tr,
                    prefixIcon: const Icon(Iconsax.password_check),
                    suffixIcon: IconButton(
                        onPressed: () => controller.hidePassword.value = !controller.hidePassword.value,
                        icon:  Icon(controller.hidePassword.value ? Iconsax.eye_slash : Iconsax.eye)
                    )
                ),
              )),
              const SizedBox(
                height: TSizes.spaceBtwInoutFields / 2,
              ),

              Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8, children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Obx(() => Checkbox(value: controller.rememberMe.value,
                        onChanged: (value) => controller.rememberMe.value = value ?? false)),
                    const Flexible(child: ShopText(TTexts.rememberMe)),
                  ]),
                  TextButton(onPressed: () => Get.to(() => const ForgetPassword()),
                      child: const ShopText(TTexts.forgetPassword)),
                ],
              ),
              const SizedBox(
                height: TSizes.spaceBtwSections,
              ),

              ///Sign in button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () => controller.emailAndPasswordSignIn(),
                    child: const ShopText(TTexts.signIn)),
              ),
              const SizedBox(
                height: TSizes.spaceBtwItems,
              ),

              ///create account
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                    onPressed: () => Get.to(() => const SignupScreen()),
                    child: const ShopText(TTexts.createAccount)),
              ),
            ],
          ),
        ));
  }
}
