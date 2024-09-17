import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/admin/login/widget/login_form_admin.dart';
import 'package:fashion_business_app/common/styles/spacing_styles.dart';
import 'package:fashion_business_app/common/widgets/login_signup/form_divider.dart';
import 'package:fashion_business_app/features/authentication/screens/login/login.dart';
import 'package:fashion_business_app/features/authentication/screens/login/widgets/login_form.dart';
import 'package:fashion_business_app/features/authentication/screens/login/widgets/login_header.dart';
import 'package:fashion_business_app/utils/constants/image_strings.dart';
import 'package:fashion_business_app/utils/constants/sizes.dart';
import 'package:fashion_business_app/utils/constants/text_strings.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';

class LoginAdminScreen extends StatelessWidget {
  const LoginAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return  Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: TSpacingStyle.paddingWithAppBarHeight,
          child: Column(
            children: [
              ///logo and subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Get.to(() => const LoginScreen()),
                          child: const Icon(Iconsax.user, size: 20,color: TColors.primaryColor,)),
                    ],
                  ),
                  Text(
                    'WelCome Administrator',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(
                    height: TSizes.sm,
                  ),

                ],
              ),

              ///form
              const TLoginFormAdmin(),


            ],
          ),
        ),
      ),
    );
  }
}
