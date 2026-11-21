import 'package:fashion_business_app/admin/login/login_admin_screen.dart';
import 'package:fashion_business_app/admin/screen/home/home_admin.dart';
import 'package:fashion_business_app/admin/web/data/admin_web_models.dart';
import 'package:fashion_business_app/admin/web/screens/admin_web_shell.dart';
import 'package:fashion_business_app/features/authentication/screens/splash/splash_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:fashion_business_app/features/authentication/screens/onboarding/onboarding.dart';
import 'package:fashion_business_app/features/authentication/screens/password/forget_password.dart';
import 'package:fashion_business_app/features/authentication/screens/signup/signup.dart';
import 'package:fashion_business_app/features/authentication/screens/signup/verify_email.dart';
import 'package:fashion_business_app/features/personalization/screens/address/address_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/profile/profile_screen.dart';
import 'package:fashion_business_app/features/personalization/screens/settings/setting_screen.dart';
import 'package:fashion_business_app/features/shop/screens/checkout/checkout.dart';
import 'package:fashion_business_app/features/shop/screens/home/home_screen.dart';
import 'package:fashion_business_app/features/shop/screens/order/order.dart';
import 'package:fashion_business_app/features/shop/screens/product_reviews/product_review.dart';
import 'package:fashion_business_app/features/shop/screens/store/store_screen.dart';
import 'package:fashion_business_app/features/shop/screens/wishlist/wishlish_screen.dart';

import 'routes.dart';

class AppRoutes {
  static final pages = [
    GetPage(
      name: TRoutes.home,
      page: () => kIsWeb ? const SplashScreen() : const HomeScreen(),
    ),
    GetPage(name: TRoutes.store, page: () => const StoreScreen()),
    GetPage(name: TRoutes.favourites, page: () => const WishList()),
    GetPage(name: TRoutes.settings, page: () => const SettingScreen()),
    GetPage(name: TRoutes.productReviews, page: () => const ProductReview()),
    GetPage(name: TRoutes.order, page: () => const OrderScreen()),
    GetPage(name: TRoutes.checkout, page: () => CheckoutScreen()),
    GetPage(name: TRoutes.userProfile, page: () => const ProfileScreen()),
    GetPage(name: TRoutes.userAddress, page: () => const AddressScreen()),
    GetPage(name: TRoutes.signup, page: () => const SignupScreen()),
    GetPage(name: TRoutes.verifyEmail, page: () => const VerifyEmailScreen()),
    GetPage(name: TRoutes.forgetPassWord, page: () => const ForgetPassword()),
    GetPage(name: TRoutes.onBoarding, page: () => const OnBoardingScreen()),

    // Admin Web Portal routes
    GetPage(name: TRoutes.adminLogin, page: () => const LoginAdminScreen()),
    GetPage(name: '/admin', page: () => const HomeScreenAdmin()),
    GetPage(
      name: TRoutes.adminDashboard,
      page: () => const AdminWebShell(initialSection: AdminSection.dashboard),
    ),
    GetPage(
      name: TRoutes.adminFinance,
      page: () => const AdminWebShell(initialSection: AdminSection.finance),
    ),
    GetPage(
      name: TRoutes.adminOrders,
      page: () => const AdminWebShell(initialSection: AdminSection.orders),
    ),
    GetPage(
      name: TRoutes.adminProducts,
      page: () => const AdminWebShell(initialSection: AdminSection.products),
    ),
    GetPage(
      name: TRoutes.adminVouchers,
      page: () => const AdminWebShell(initialSection: AdminSection.vouchers),
    ),
    GetPage(
      name: TRoutes.adminBrands,
      page: () => const AdminWebShell(initialSection: AdminSection.brands),
    ),
    GetPage(
      name: TRoutes.adminCategories,
      page: () => const AdminWebShell(initialSection: AdminSection.categories),
    ),
    GetPage(
      name: TRoutes.adminBanners,
      page: () => const AdminWebShell(initialSection: AdminSection.banners),
    ),
    GetPage(
      name: TRoutes.adminUsers,
      page: () => const AdminWebShell(initialSection: AdminSection.users),
    ),
    GetPage(
      name: TRoutes.adminReviews,
      page: () => const AdminWebShell(initialSection: AdminSection.reviews),
    ),
    GetPage(
      name: TRoutes.adminNotifications,
      page: () => const AdminWebShell(initialSection: AdminSection.notifications),
    ),
  ];
}
