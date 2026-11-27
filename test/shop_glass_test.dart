import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('iOS glass stays shader-free while Android keeps adaptive quality', (tester) async {
    final config = ShopGlass.adaptiveConfig;
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    expect(config.maxQuality, ios ? GlassQuality.minimal : GlassQuality.premium);
    if (ios) {
      expect(config.initialQuality, GlassQuality.minimal);
      expect(config.allowStepUp, isFalse);
    }
    GlassQuality? effectiveQuality;
    await tester.pumpWidget(LiquidGlassWidgets.wrap(
      adaptiveQuality: true,
      adaptiveConfig: config,
      child: MaterialApp(home: Builder(builder: (context) {
        effectiveQuality = GlassAdaptiveScopeData.maybeOf(context)?.effectiveQuality;
        return const ShopGlassBackground(child: Center(child: ShopGlass(child: Text('Glass'))));
      })),
    ));
    if (ios) expect(effectiveQuality, GlassQuality.minimal);
    expect(find.text('Glass'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: const TargetPlatformVariant({TargetPlatform.iOS, TargetPlatform.android}));

  testWidgets('ShopGlass renders GlassContainer and keeps controls tappable across platforms',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      LiquidGlassWidgets.wrap(
        brightnessResolver: ShopGlass.resolveBrightness,
        theme: ShopGlass.themeData,
        child: MaterialApp(
          home: ShopGlassBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: ShopGlass(
                  child: TextButton(
                    onPressed: () => taps++,
                    child: const Text('Checkout'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(GlassPage), findsOneWidget);
    expect(find.byType(GlassContainer), findsOneWidget);
    await tester.tap(find.text('Checkout'));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('high contrast activates GlassAccessibilityScope without shader or blur',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(highContrast: true),
          child: Scaffold(
            body: ShopGlass(child: Text('Readable payment details')),
          ),
        ),
      ),
    );
    expect(find.byType(GlassAccessibilityScope), findsOneWidget);
    expect(find.byType(GlassContainer), findsNothing);
    expect(find.text('Readable payment details'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('content glass preserves functional colors and product images', () {
    final neutral = ShopGlassDecoration(color: Colors.white);
    expect(neutral.gradient, isNotNull);
    final destructive = ShopGlassDecoration(color: Colors.red);
    expect(destructive.color, Colors.red);
    expect(destructive.gradient, isNull);
    const image = DecorationImage(image: AssetImage('shoe.png'));
    final product = ShopGlassDecoration(color: Colors.white, image: image);
    expect(product.image, same(image));
    expect(product.color, Colors.white);
    expect(product.gradient, isNull);
  });
}
