import 'package:fashion_business_app/common/widgets/login_signup/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => AuthScaffold(
    showBack: false,
    title: 'Welcome back',
    subtitle: 'Your favorites, your next pair, all in one place.',
    hero: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(aspectRatio: 2.4,
        child: Image.asset('assets/images/banners/login-velora-concept.png', fit: BoxFit.cover)),
    ),
    child: const TLoginForm(),
  );
}
