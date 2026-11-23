import 'package:fashion_business_app/features/shop/controllers/product/favourite_controller.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:fashion_business_app/data/services/sneaker_catalog_importer.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:fashion_business_app/data/repositories/authentication/authentication_repository.dart';
import 'package:fashion_business_app/data/repositories/products/product_reposotory.dart';
import 'package:fashion_business_app/features/shop/controllers/brand_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/category_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/product_controller.dart';
import 'package:fashion_business_app/utils/web/url_strategy.dart';
import 'app.dart';
import 'firebase_options.dart';

/// Top-level Firebase Cloud Messaging background handler (required by FCM).
@pragma('vm:entry-point')
Future<void> veloraFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

Future<void> main() async {
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();
  configureWebUrlStrategy();

  if (!kIsWeb) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }

  await GetStorage.init();
  await GetStorage.init('');
  await GetStorage.init('app_preferences');
  Get.put(ShopLocale(GetStorage('app_preferences')), permanent: true);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((FirebaseApp value) => Get.put(AuthenticationRepository()));

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(
      veloraFirebaseMessagingBackgroundHandler,
    );
  }

  if (const bool.fromEnvironment('IMPORT_SNEAKER_CATALOG')) {
    await SneakerCatalogImporter().importIfNeeded();
    await SneakerCatalogImporter().importCampaignsIfNeeded();
  }

  Get.lazyPut(() => FavouritesController(), fenix: true);
  Get.lazyPut(() => CartController(), fenix: true);
  Get.lazyPut(() => ProductRepository(), fenix: true);
  Get.lazyPut(() => ProductController(), fenix: true);
  Get.lazyPut(() => CategoryController(), fenix: true);
  Get.lazyPut(() => BrandController(), fenix: true);

  runApp(const App());

  if (!kIsWeb) {
    // Request OS Firebase Cloud Messaging permission right after launch
    Future<void>(() async {
      try {
        final messaging = FirebaseMessaging.instance;
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          await messaging.setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
        }
      } catch (_) {}
    });
  }
}
