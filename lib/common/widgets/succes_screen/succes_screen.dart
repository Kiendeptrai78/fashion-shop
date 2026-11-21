import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, required this.image, required this.title,
    required this.subtitle, required this.onPressed});
  final String image, title, subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(
    child: SingleChildScrollView(padding: const EdgeInsets.all(32), child: Column(children: [
      Lottie.asset(image, width: 180, height: 180, animate: !MediaQuery.disableAnimationsOf(context)),
      const SizedBox(height: 28),
      ShopText(title, textAlign: TextAlign.center, style: const TextStyle(
          fontSize: 28, height: 1.25, letterSpacing: -0.7, fontWeight: FontWeight.w600)),
      const SizedBox(height: 16),
      ShopText(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7)),
      const SizedBox(height: 32),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onPressed, child: const ShopText('Continue'))),
    ])),
  )));
}
