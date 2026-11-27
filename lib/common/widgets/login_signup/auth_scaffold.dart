import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';

/// Shared, scrollable account flow with room for the keyboard and large text.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, required this.subtitle,
    required this.child, this.showBack = true, this.onBack, this.hero,
    this.symbol, this.actions});
  final String title, subtitle;
  final Widget child;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? hero;
  final IconData? symbol;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFE4ECE7) : const Color(0xFF173E32);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: TAppbar(showBackArrow: showBack, leadingOnPressed: onBack,
        title: Text('VELORA', style: shopAppbarTitleStyle.copyWith(letterSpacing: 3)),
        actions: actions),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: shopAppbarContentPadding(context, const EdgeInsets.fromLTRB(24, 20, 24, 28)),
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (hero != null) ...[hero!, const SizedBox(height: 28)],
            if (symbol != null) ...[
              Container(width: 64, height: 64,
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF273C30) : const Color(0xFFE1EADF),
                  borderRadius: BorderRadius.circular(20)),
                child: Icon(symbol, size: 28, color: ink)),
              const SizedBox(height: 24),
            ],
            ShopText(title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
              height: 1.25, letterSpacing: -0.8, color: ink)),
            const SizedBox(height: 10),
            ShopText(subtitle, style: TextStyle(fontSize: 14, height: 1.65,
              color: dark ? const Color(0xFFB2C3B8) : const Color(0xFF53695C))),
            const SizedBox(height: 28),
            AutofillGroup(child: child),
          ]),
        )),
      ),
    );
  }
}
