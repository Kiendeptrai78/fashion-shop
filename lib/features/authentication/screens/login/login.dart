import 'package:fashion_business_app/admin/login/login_admin_screen.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/common/styles/spacing_styles.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/constants/text_strings.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/login_signup/form_divider.dart';
import 'widgets/login_form.dart';
import 'widgets/login_header.dart';
import '../../../../common/widgets/login_signup/social_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: TSpacingStyle.paddingWithAppBarHeight,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () => Get.to(() => const LoginAdminScreen()),
                            child: const Icon(Iconsax.user, size: 20,color: TColors.primaryColor,)),
                      ],
                    ),

                    ///logo and subtitle
                    const TLoginHeader(),

                    ///form
                    const TLoginForm(),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
