import 'dart:math' as math;
import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/common/widgets/login_signup/auth_scaffold.dart';
import 'package:fashion_business_app/utils/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty fields have a visible boundary in both themes', () {
    for (final theme in [TAppTheme.lightTheme, TAppTheme.darkTheme]) {
      final decoration = theme.inputDecorationTheme;
      final fill = WidgetStateProperty.resolveAs<Color>(decoration.fillColor!, {});
      final border = decoration.enabledBorder!.borderSide.color;
      final light = math.max(fill.computeLuminance(), border.computeLuminance());
      final dark = math.min(fill.computeLuminance(), border.computeLuminance());
      expect((light + 0.05) / (dark + 0.05), greaterThanOrEqualTo(3));
      expect(decoration.focusedBorder!.borderSide.width,
          greaterThan(decoration.enabledBorder!.borderSide.width));
      expect(decoration.errorBorder!.borderSide.color, isNot(border));
    }
  });

  testWidgets('field keeps entered text through focus and validation states', (tester) async {
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(MaterialApp(theme: TAppTheme.lightTheme, home: Scaffold(
      body: Form(key: form, child: Column(children: [
        TextFormField(decoration: const InputDecoration(labelText: 'Email'),
          validator: (value) => value == 'you@example.com' ? null : 'Check your email'),
        TextButton(onPressed: () => form.currentState!.validate(), child: const Text('Validate')),
      ])),
    )));
    await tester.tap(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), 'wrong');
    await tester.tap(find.text('Validate'));
    await tester.pumpAndSettle();
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.text('wrong'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'you@example.com');
    await tester.tap(find.text('Validate'));
    await tester.pumpAndSettle();
    expect(find.text('Check your email'), findsNothing);
    expect(find.text('you@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account form remains scrollable with keyboard and large text on a small phone', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    var submitted = false;
    await tester.pumpWidget(LiquidGlassWidgets.wrap(
      brightnessResolver: ShopGlass.resolveBrightness,
      theme: ShopGlass.themeData,
      child: MaterialApp(theme: TAppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.4)),
          child: ShopGlassBackground(child: child!),
        ),
        home: AuthScaffold(title: 'Create your VELORA account',
          subtitle: 'Save your favorites and keep every order in one place.',
          child: Column(children: [
            for (final label in ['First name', 'Last name', 'Email', 'Phone', 'Password']) ...[
              TextFormField(decoration: InputDecoration(labelText: label)),
              const SizedBox(height: 16),
            ],
            ElevatedButton(onPressed: () => submitted = true, child: const Text('Continue')),
          ]),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    expect(submitted, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
