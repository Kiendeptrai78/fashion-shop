import 'package:fashion_business_app/common/widgets/chat/shop_chat_send_button.dart';
import 'package:fashion_business_app/common/widgets/dialogs/velora_confirm_dialog.dart';
import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('send stays readable on a light composer and preserves its callback', (tester) async {
    var sent = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body:
      Center(child: ShopChatSendButton(onPressed: () => sent++)))));
    final button = tester.widget<GlassIconButton>(find.byType(GlassIconButton));
    expect(button.surfaceStyle, GlassSurfaceStyle.solid);
    final contrast = (button.iconColor!.computeLuminance() + 0.05) /
        (button.color!.computeLuminance() + 0.05);
    expect(contrast, greaterThan(7));
    await tester.tap(find.byType(ShopChatSendButton));
    expect(sent, 1);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body:
      Center(child: ShopChatSendButton(onPressed: null)))));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<GlassIconButton>(find.byType(GlassIconButton)).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmation dialog has text and actions without a decorative icon', (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (context) =>
      TextButton(onPressed: () async {
        result = await showVeloraConfirmDialog(context, title: 'Confirm Logout',
          message: 'Are you sure?', destructive: true);
      }, child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm Logout'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    expect(tester.takeException(), isNull);
  });
}
