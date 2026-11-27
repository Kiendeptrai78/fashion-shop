import 'package:fashion_business_app/common/widgets/login_signup/auth_scaffold.dart';
import 'package:fashion_business_app/utils/constants/text_strings.dart';
import 'package:flutter/material.dart';
import 'widgets/signup_form.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) => const AuthScaffold(
    title: TTexts.signupTitle,
    subtitle: 'Save your favorites and keep every order in one place.',
    child: TSignupForm(),
  );
}
