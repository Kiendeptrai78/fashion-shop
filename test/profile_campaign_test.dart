import 'package:fashion_business_app/features/personalization/screens/profile/profile_screen.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/list_tiles/user_profile_title.dart';
import 'package:fashion_business_app/features/authentication/models/user_model.dart';
import 'package:fashion_business_app/features/personalization/controllers/user_controller.dart';
import 'package:fashion_business_app/features/shop/models/banner_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _User extends GetxController implements UserController {
  @override
  final user = UserModel.empty().obs;
  @override
  final imageUploading = false.obs;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(() => Get.reset());
  testWidgets('profile updates when account finishes loading', (tester) async {
    final controller = Get.put<UserController>(_User());
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: TUserProfileTile(onPressed: () {}),
    )));
    expect(find.text('Your account'), findsOneWidget);
    controller.user.value = UserModel(id: '1', email: 'shop@example.com', firstName: 'Sneaker',
        lastName: 'Fan', username: 'fan', phoneNumber: '', profilePicture: '', role: 'Client');
    await tester.pump();
    expect(find.text('Sneaker Fan'), findsOneWidget);
    expect(find.text('shop@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('profile displays account data without fake demographic values', (tester) async {
    final controller = Get.put<UserController>(_User());
    controller.user.value = UserModel(id: 'id', email: 'buyer@example.com', firstName: 'Buyer',
        lastName: 'One', username: 'buyer', phoneNumber: '', profilePicture: '', role: 'Client');
    await tester.pumpWidget(const GetMaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();
    // Account data may be present in both the profile header and its detail rows.
    expect(find.text('Buyer One'), findsWidgets);
    expect(find.text('buyer@example.com'), findsWidgets);
    expect(find.byType(TAppbar), findsOneWidget);
    expect(find.byType(ShopGlassBackButton), findsOneWidget);
    expect(find.text('Male'), findsNothing);
    expect(find.text('April 15, 2002'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  test('legacy banners and campaign metadata roundtrip', () {
    final old = BannerModel.fromJson({'ImageUrl': 'old.jpg', 'Active': true});
    expect(old.videoUrl, isEmpty);
    final campaign = BannerModel.fromJson({'ImageUrl': 'poster.jpg', 'VideoUrl': 'clip.mp4',
      'Active': true, 'CategoryId': 'running', 'SortOrder': 2});
    final restored = BannerModel.fromJson(campaign.toJson());
    expect(restored.videoUrl, 'clip.mp4');
    expect(restored.categoryId, 'running');
    expect(restored.sortOrder, 2);
  });
  testWidgets('closing the phone editor keeps its field alive through the exit animation', (tester) async {
    Get.put<UserController>(_User());
    await tester.pumpWidget(const GetMaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(tester.element(find.text('Not added yet')), alignment: 0.5);
    await tester.tap(find.text('Not added yet'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '0912345678');
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pump(const Duration(milliseconds: 30));
    tester.view.viewInsets = const FakeViewPadding(bottom: 10);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Not added yet'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(find.byType(TextFormField)).initialValue, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
