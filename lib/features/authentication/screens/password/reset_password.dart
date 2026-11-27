import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/login_signup/auth_scaffold.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/features/authentication/controllers/forget_password/forget_passwrod_controller.dart';
import 'package:fashion_business_app/features/authentication/screens/login/login.dart';
import 'package:fashion_business_app/utils/constants/text_strings.dart';

class ResetPassword extends StatelessWidget {
  const ResetPassword({super.key, required this.email});
  final String email;

  @override
  Widget build(BuildContext context) => AuthScaffold(
    showBack: false,
    actions: [ShopGlassIconButton(onPressed: () => Get.back(), icon: CupertinoIcons.clear)],
    symbol: Iconsax.direct_right,
    title: TTexts.changeYourPasswordTitle,
    subtitle: TTexts.changeYourPasswordSubTitle,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SelectableText(email, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 28),
      ElevatedButton(onPressed: () => Get.offAll(() => const LoginScreen()),
        child: const ShopText(TTexts.done)),
      const SizedBox(height: 12),
      TextButton(onPressed: () => ForgetPasswordController.instance.resendPasswordResetEmail(email),
        child: const ShopText(TTexts.resendEmail)),
      const SizedBox(height: 16),
      const ShopText(TTexts.emailNotReceivedMessage,
        style: TextStyle(fontSize: 12, height: 1.6), textAlign: TextAlign.center),
    ]),
  );
}
