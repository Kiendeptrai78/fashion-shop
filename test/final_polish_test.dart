import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/features/authentication/screens/splash/splash_screen.dart';
import 'package:fashion_business_app/features/authentication/screens/login/login.dart';
import 'package:fashion_business_app/features/authentication/controllers/login/login_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_review_model.dart';
import 'package:fashion_business_app/features/shop/screens/product_reviews/product_review.dart';
import 'package:fashion_business_app/utils/localization/shop_translations.dart';

class _Login extends GetxController implements LoginController {
  @override
  final rememberMe = false.obs;
  @override
  final hidePassword = true.obs;
  @override
  final email = TextEditingController();
  @override
  final password = TextEditingController();
  @override
  final loginFormKey = GlobalKey<FormState>();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(() => Get.reset());
  Widget app(Widget home) => GetMaterialApp(locale: const Locale('vi'), translations: ShopTranslations(),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates, home: home);

  test('review summary uses real entries without invented totals', () {
    expect(ProductReviewSummary([]).count, 0);
    expect(ProductReviewSummary([]).average, 0);
    final summary = ProductReviewSummary(const [
      ProductReviewEntry(id:'a', authorName:'Buyer A', rating:5, text:'Comfortable'),
      ProductReviewEntry(id:'b', authorName:'Buyer B', rating:3, text:'A little narrow'),
    ]);
    expect(summary.count, 2);
    expect(summary.average, 4);
    expect(summary.stars[5], 1);
    expect(summary.stars[3], 1);
    expect(summary.stars[1], 0);
  });

  testWidgets('splash is branded and respects reduced motion', (tester) async {
    await tester.pumpWidget(app(const MediaQuery(data: MediaQueryData(disableAnimations: true),
        child: SplashScreen())));
    await tester.pumpAndSettle();
    expect(find.text('VELORA'), findsOneWidget);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, SplashScreen.background);
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty product reviews show an honest empty state', (tester) async {
    await tester.pumpWidget(app(ProductReview(productId:'shoe', productTitle:'Test shoe', loadReviews: () async => [])));
    await tester.pumpAndSettle();
    expect(find.text('Hãy chia sẻ trải nghiệm đầu tiên.'), findsOneWidget);
    expect(find.text('12,161,342'), findsNothing);
    expect(find.text('Viết đánh giá'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('review star filters show only matching recent entries', (tester) async {
    await tester.pumpWidget(app(ProductReview(productId:'shoe', loadReviews: () async => const [
      ProductReviewEntry(id:'a', authorName:'Buyer A', rating:5, text:'Comfortable fit'),
      ProductReviewEntry(id:'b', authorName:'Buyer B', rating:1, text:'Too narrow for me'),
    ])));
    await tester.pumpAndSettle();
    final filter = find.widgetWithText(ChoiceChip, '1 ★');
    await tester.ensureVisible(filter);
    await tester.tap(filter);
    await tester.pumpAndSettle();
    expect(find.text('Comfortable fit'), findsNothing);
    expect(find.text('Too narrow for me'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login fits a small phone without overflowing translated actions', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.put<LoginController>(_Login());
    await tester.pumpWidget(app(const LoginScreen()));
    await tester.pumpAndSettle();
    expect(find.text('VELORA'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
