import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/widgets/shared/glass_effect.dart';

void main() {
  testWidgets('minimal selection keeps its tint while moving and after settling', (tester) async {
    for (final motion in [0.0, 0.5, 1.0, 0.0]) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(
        child: SizedBox(width: 220, height: 44, child: Stack(children: [AnimatedGlassIndicator(
          velocity: 0, itemCount: 2, alignment: Alignment.centerLeft,
          thickness: motion, quality: GlassQuality.minimal,
          indicatorColor: const Color(0x0F000000), isBackgroundIndicator: false,
          expansion: EdgeInsets.zero, settings: LiquidGlassSettings.classicIndicator,
        )])),
      ))));
      final tint = find.byWidgetPredicate((widget) => widget is DecoratedBox &&
          widget.decoration is ShapeDecoration &&
          (widget.decoration as ShapeDecoration).color == const Color(0x0F000000));
      expect(tint, findsOneWidget);
      final opacity = tester.widget<Opacity>(find.ancestor(of: tint, matching: find.byType(Opacity)).first);
      expect(opacity.opacity, 1);
      expect(find.byType(GlassEffect), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
}
