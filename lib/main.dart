import 'package:fashion_business_app/features/shop/controllers/product/favourite_controller.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:fashion_business_app/data/services/sneaker_catalog_importer.dart';
import 'package:fashion_business_app/features/personalization/controllers/user_controller.dart';

import 'package:firebase_core/firebase_core.dart';
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

Future<void> main() async {
  ///add widgets binding
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  configureWebUrlStrategy();

  if (!kIsWeb) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }

  ///GetX Local storage
  await GetStorage.init('');
  await GetStorage.init('app_preferences');
  Get.put(ShopLocale(GetStorage('app_preferences')), permanent: true);


  ///--Initialize firebase authentication repository
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
      .then((FirebaseApp value) => Get.put(AuthenticationRepository()));

  if (const bool.fromEnvironment('IMPORT_SNEAKER_CATALOG')) {
    await SneakerCatalogImporter().importIfNeeded();
    await SneakerCatalogImporter().importCampaignsIfNeeded();
  }

  Get.lazyPut(() => FavouritesController(), fenix: true);
  Get.lazyPut(() => CartController(), fenix: true);  // Ensure CartController is always available

  Get.lazyPut(() => ProductRepository(), fenix: true);  // Ensure CartController is always available
  Get.lazyPut(() => ProductController(), fenix: true);  // Ensure CartController is always available
  Get.lazyPut(() => CategoryController(), fenix: true);  // Ensure CartController is always available
  Get.lazyPut(() => BrandController(), fenix: true);  // Ensure CartController is always available


  runApp(const App());
}
