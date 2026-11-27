import 'package:fashion_business_app/features/personalization/screens/address/widgets/address_location_picker.dart';
import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/common/widgets/glass/shop_overlays.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('liquid location picker searches and returns the selected location', (tester) async {
    var selected = 'Hà Nội';
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatefulBuilder(
      builder: (context, update) => Padding(padding: const EdgeInsets.all(20),
        child: AddressLocationPicker(label: 'Tỉnh / Thành phố', value: selected,
          items: const ['Hà Nội', 'Đà Nẵng', 'Hồ Chí Minh'], icon: Icons.location_city,
          onChanged: (value) => update(() => selected = value))),
    ))));
    await tester.tap(find.byType(GlassPicker));
    await tester.pumpAndSettle();
    expect(find.byType(ShopOverlaySurface), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Đà Nẵng');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Hồ Chí Minh'), findsNothing);
    await tester.tap(find.widgetWithText(ListTile, 'Đà Nẵng'));
    await tester.pumpAndSettle();
    expect(selected, 'Đà Nẵng');
    expect(find.byType(ShopOverlaySurface), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
