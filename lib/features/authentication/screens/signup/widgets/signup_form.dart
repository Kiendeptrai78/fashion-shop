import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/features/authentication/controllers/signup/signup_controller.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/constants/text_strings.dart';
import 'package:fashion_business_app/utils/validators/validation.dart';

import 'team_of_the_conditions.dart';

class TSignupForm extends StatelessWidget {
  const TSignupForm({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SignupController());
    return Form(
        key: controller.signupFormKey,
        child: Column(
          children: [
            Row(
              children: [
                ///first name
                Expanded(
                  child: TextFormField(
                    controller: controller.firstName,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.givenName],
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        TValidator.validateEmptyText('First name', value),
                    expands: false,
                    decoration: InputDecoration(
                        labelText: TTexts.firstName.tr,
                        prefixIcon: const Icon(Iconsax.user)),
                  ),
                ),

                const SizedBox(
                  width: TSizes.spaceBtwInoutFields,
                ),

                ///last name
                Expanded(
                  child: TextFormField(
                    controller: controller.lastName,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.familyName],
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        TValidator.validateEmptyText('Last name', value),
                    expands: false,
                    decoration: InputDecoration(
                        labelText: TTexts.lastName.tr,
                        prefixIcon: const Icon(Iconsax.user)),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: TSizes.spaceBtwInoutFields,
            ),

            ///user name
            TextFormField(
              controller: controller.userName,
              autofillHints: const [AutofillHints.newUsername],
              textInputAction: TextInputAction.next,
              autocorrect: false,
              validator: (value) =>
                  TValidator.validateEmptyText('Username', value),
              expands: false,
              decoration: InputDecoration(
                  labelText: TTexts.username.tr,
                  prefixIcon: const Icon(Iconsax.user_edit)),
            ),

            const SizedBox(
              height: TSizes.spaceBtwInoutFields,
            ),

            ///email
            TextFormField(
              controller: controller.email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              autocorrect: false,
              validator: (value) => TValidator.validateEmail(value),
              expands: false,
              decoration: InputDecoration(
                  labelText: TTexts.email.tr, prefixIcon: const Icon(Iconsax.direct)),
            ),

            const SizedBox(
              height: TSizes.spaceBtwInoutFields,
            ),

            ///phone number
            TextFormField(
              controller: controller.phoneNumber,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              textInputAction: TextInputAction.next,
              validator: (value) => TValidator.validatePhoneNumber(value),
              expands: false,
              decoration: InputDecoration(
                  labelText: TTexts.phone.tr, prefixIcon: const Icon(Iconsax.call)),
            ),

            const SizedBox(
              height: TSizes.spaceBtwInoutFields,
            ),
            ///Role
            SizedBox(
              height: 0,
              width: 0,
              child: TextFormField(
                controller: controller.role,
              ),
            ),

            ///password
            Obx(() => TextFormField(
              controller: controller.password,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              validator: (value) => TValidator.validatePassword(value),
              obscureText: controller.hidePassword.value,
              expands: false,
              decoration:  InputDecoration(
                  labelText: TTexts.password.tr,
                  prefixIcon: const Icon(Iconsax.password_check),
                  suffixIcon: IconButton(
                      onPressed: () => controller.hidePassword.value = !controller.hidePassword.value,
                      icon:  Icon(controller.hidePassword.value ? Iconsax.eye_slash : Iconsax.eye))),
            )),

            const SizedBox(
              height: TSizes.spaceBtwInoutFields,
            ),

            ///term&conditions checkbox
            const TTermOfTheConditions(),

            const SizedBox(
              height: TSizes.spaceBtwSections,
            ),

            ///sign up button

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => controller.signup(),
                child: const ShopText(TTexts.createAccount),
              ),
            )
          ],
        ));
  }
}
