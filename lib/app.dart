import 'package:fashion_business_app/features/authentication/screens/splash/splash_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:fashion_business_app/utils/localization/shop_translations.dart';
import 'package:fashion_business_app/routes/app_route.dart';
import 'package:fashion_business_app/utils/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'bindings/genaral_bindings.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: kIsWeb ? 'VELORA Admin' : 'VELORA',
      locale: Locale(Get.find<ShopLocale>().language),
      fallbackLocale: const Locale('en'),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      translations: ShopTranslations(),
      themeMode: ThemeMode.system,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      initialBinding: GeneralBinding(),
      getPages: AppRoutes.pages,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
