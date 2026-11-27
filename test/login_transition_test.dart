import 'dart:async';
import 'dart:io';
import 'package:fashion_business_app/common/widgets/glass/shop_overlays.dart';
import 'package:fashion_business_app/data/repositories/authentication/authentication_repository.dart';
import 'package:fashion_business_app/features/authentication/controllers/login/login_controller.dart';
import 'package:fashion_business_app/features/authentication/controllers/signup/network_manager.dart';
import 'package:fashion_business_app/features/authentication/screens/splash/splash_screen.dart';
import 'package:fashion_business_app/features/personalization/controllers/user_controller.dart';
import 'package:fashion_business_app/routes/app_route.dart';
import 'package:fashion_business_app/utils/popups/full_screen_loader.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class _Credential extends Fake implements UserCredential {}
class _Network extends GetxController implements NetworkManager {
  @override
  Future<bool> isConnected() async => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class _User extends GetxController implements UserController {
  final saved = Completer<void>();
  @override
  Future<void> saveUserRecord(UserCredential? credential) => saved.future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class _Auth extends GetxController implements AuthenticationRepository {
  final credential = Completer<UserCredential?>();
  final ready = Completer<void>();
  var requests = 0;
  @override
  Future<UserCredential?> signInWithGoogle() { requests++; return credential.future; }
  @override
  Future<void> screenRedirect({VoidCallback? beforeNavigate}) async {
    await ready.future;
    beforeNavigate?.call();
    Get.offAll(() => const Scaffold(body: Text('Ready Home')));
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  setUpAll(() async {
    temp = Directory.systemTemp.createTempSync('velora-login-test-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'), (call) async => temp.path);
    await GetStorage('GetStorage', temp.path).initStorage;
  });
  tearDown(() { TFullScreenLoader.stopLoading(); Get.reset(); });
  tearDownAll(() => temp.deleteSync(recursive: true));

  test('the root route cannot open Home before session preparation', () {
    expect(AppRoutes.pages.firstWhere((page) => page.name == '/').page(), isA<SplashScreen>());
  });

  testWidgets('loader removes its own route instead of popping a newer page', (tester) async {
    await tester.pumpWidget(GetMaterialApp(home: Scaffold(body: Builder(builder: (context) =>
      TextButton(onPressed: () => TFullScreenLoader.openLoadingDialog('Loading', ''),
        child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pump();
    Get.to(() => const Scaffold(body: Text('New page')));
    await tester.pumpAndSettle();
    TFullScreenLoader.stopLoading();
    await tester.pumpAndSettle();
    expect(find.text('New page'), findsOneWidget);
    Get.back();
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(find.byType(ShopGlassDialog), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Google login stays loading until session is ready and rejects duplicate taps', (tester) async {
    final auth = Get.put<AuthenticationRepository>(_Auth()) as _Auth;
    final user = Get.put<UserController>(_User()) as _User;
    Get.put<NetworkManager>(_Network());
    final controller = Get.put(LoginController());
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: Text('Login'))));
    await tester.pumpAndSettle();
    final login = controller.googleSignIn();
    await tester.pump();
    await controller.googleSignIn();
    expect(auth.requests, 1);
    auth.credential.complete(_Credential());
    await tester.pump();
    expect(find.byType(ShopGlassDialog), findsOneWidget);
    user.saved.complete();
    await tester.pump();
    expect(find.text('Ready Home'), findsNothing);
    expect(find.byType(ShopGlassDialog), findsOneWidget);
    auth.ready.complete();
    await tester.pumpAndSettle();
    await login;
    expect(find.text('Ready Home'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
    expect(find.byType(ShopGlassDialog), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
