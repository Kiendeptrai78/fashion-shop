import 'package:fashion_business_app/features/personalization/screens/account/notifications_screen.dart';
import 'package:fashion_business_app/features/personalization/services/account_activity.dart';
import 'package:fashion_business_app/common/widgets/glass/shop_overlays.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'order_returns_ui_test.dart' show app;

const title = 'Bộ sưu tập giày chạy bộ mới dành cho bạn với nhiều lựa chọn màu sắc và kích cỡ';
const body = 'Khám phá những mẫu giày phù hợp với sở thích của bạn. '
    'Xem đầy đủ thông tin chất liệu, kích cỡ và ưu đãi trước khi lựa chọn đôi giày tiếp theo.';

class _Inbox extends GetxController implements AccountActivity {
  @override
  final inbox = <Map<String, dynamic>>[{
    'documentId': 'promo-1', 'kind': 'promo', 'read': false,
    'titleVi': title, 'bodyVi': body, 'createdAt': DateTime(2026, 11, 27),
  }].obs;
  @override
  int get unread => inbox.where((notice) => notice['read'] != true).length;
  var reads = 0;
  @override
  Future<void> markRead(String documentId) async { reads++; }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(() => Get.reset());
  testWidgets('notification preview stays compact and opens the full message', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final activity = Get.put<AccountActivity>(_Inbox()) as _Inbox;
    await tester.pumpWidget(app(NotificationsScreen(loadOrders: () async => [])));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text(title)).maxLines, 2);
    expect(tester.widget<Text>(find.text(body)).maxLines, 2);
    final card = find.ancestor(of: find.text(title), matching: find.byType(InkWell)).first;
    expect(tester.getSize(card).height, lessThan(160));
    expect(find.text('Bật thông báo'), findsNothing);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(activity.reads, 1);
    expect(find.byType(ShopGlassAlertDialog), findsOneWidget);
    expect(tester.widgetList<Text>(find.text(body)).any((text) => text.maxLines == null), isTrue);
    expect(tester.takeException(), isNull);
  });
}
