import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/login_signup/auth_scaffold.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/data/repositories/authentication/authentication_repository.dart';
import 'package:fashion_business_app/features/authentication/controllers/signup/verify_email_controller.dart';
import 'package:fashion_business_app/utils/constants/text_strings.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key, this.email});
  final String? email;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VerifyEmailController());
    return AuthScaffold(
      showBack: false,
      actions: [ShopGlassIconButton(onPressed: () => AuthenticationRepository.instance.logout(),
        icon: CupertinoIcons.clear)],
      symbol: Iconsax.direct_right,
      title: TTexts.confirmEmail,
      subtitle: TTexts.confirmEmailSubTitle,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SelectableText(email ?? '', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 28),
        ElevatedButton(onPressed: () => controller.checkEmailVerificationStatus(),
          child: const ShopText(TTexts.continues)),
        const SizedBox(height: 12),
        TextButton(onPressed: () => controller.sendEmailVerification(),
          child: const ShopText(TTexts.resendEmail)),
        const SizedBox(height: 16),
        const ShopText(TTexts.emailNotReceivedMessage,
          style: TextStyle(fontSize: 12, height: 1.6), textAlign: TextAlign.center),
      ]),
    );
  }
}
