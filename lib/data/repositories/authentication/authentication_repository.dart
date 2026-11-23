import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/features/personalization/controllers/user_controller.dart';
import 'package:fashion_business_app/features/personalization/services/account_activity.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/features/personalization/models_shopper_preferences.dart';
import 'package:fashion_business_app/features/personalization/screens/preferences/shopper_onboarding.dart';
import 'package:fashion_business_app/admin/login/login_admin_screen.dart';
import 'package:fashion_business_app/routes/routes.dart';
import 'package:fashion_business_app/utils/constants/admin_config.dart';
import 'package:fashion_business_app/utils/web/url_strategy.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:fashion_business_app/data/repositories/users/user_repository.dart';
import 'package:fashion_business_app/features/authentication/screens/login/login.dart';
import 'package:fashion_business_app/features/authentication/screens/onboarding/onboarding.dart';
import 'package:fashion_business_app/features/authentication/screens/signup/verify_email.dart';
import 'package:fashion_business_app/navigation_menu.dart';
import 'package:fashion_business_app/utils/constants/image_strings.dart';
import 'package:fashion_business_app/utils/exceptions/firebase_auth_exception.dart';
import 'package:fashion_business_app/utils/exceptions/firebase_exception.dart';
import 'package:fashion_business_app/utils/exceptions/format_exception.dart';
import 'package:fashion_business_app/utils/exceptions/platform_exception.dart';
import 'package:fashion_business_app/utils/local_storage/local_utility.dart';
import 'package:fashion_business_app/utils/popups/full_screen_loader.dart';

import '../../../admin/screen/home/home_admin.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  ///variables
  final deviceStorage = GetStorage('app_preferences');
  final _auth = FirebaseAuth.instance;

  ///get auth user data
  User get authUser => _auth.currentUser!;

  ///called from main.dart on app launch
  @override
  void onReady() {
    if (!kIsWeb) {
      FlutterNativeSplash.remove();
    }
    if (kIsWeb) {
      screenRedirectAdmin();
    } else {
      screenRedirect();
    }
  }

  Future<void> _ensureAdminUserDoc(User user) async {
    try {
      final ref = FirebaseFirestore.instance.collection('Users').doc(user.uid);
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          'FirstName': 'Quản trị',
          'LastName': 'Viên',
          'Username': 'ADMIN',
          'Email': user.email ?? AdminConfig.adminEmail,
          'PhoneNumber': user.phoneNumber ?? '',
          'ProfilePicture': user.photoURL ?? '',
          'Role': 'Admin',
        });
      } else if (snap.data()?['Role'] != 'Admin') {
        await ref.update({'Role': 'Admin'});
      }
    } catch (_) {
      // Keep admin login resilient even if profile sync encounters a transient issue.
    }
  }

  ///function to determine the relevant
  void screenRedirect() async {
    if (kIsWeb) {
      screenRedirectAdmin();
      return;
    }
    await deviceStorage.write('app_installed_v1', true);

    User? user = _auth.currentUser;
    if (user == null) {
      try {
        user = await _auth
            .authStateChanges()
            .first
            .timeout(const Duration(milliseconds: 1200), onTimeout: () => _auth.currentUser);
      } catch (_) {
        user = _auth.currentUser;
      }
    }

    if (user != null) {
      if (user.emailVerified || AdminConfig.isAdminEmail(user.email)) {
        await TLocalStorage.init(user.uid);
        final userCtrl = Get.isRegistered<UserController>()
            ? UserController.instance
            : Get.put(UserController(), permanent: true);
        await userCtrl.fetchUserRecord();
        if (Get.isRegistered<CustomerBenefits>()) Get.delete<CustomerBenefits>(force: true);
        final benefits = Get.put(CustomerBenefits.local(), permanent: true);
        await benefits.initialize();
        if (Get.isRegistered<AccountActivity>()) Get.delete<AccountActivity>(force: true);
        Get.put(AccountActivity(user.uid), permanent: true);

        if (ShopperPreferences.load().completed) {
          Get.offAll(() => const NavigationMenu());
        } else {
          Get.offAll(() => const ShopperOnboarding());
        }
      } else {
        Get.offAll(() => VerifyEmailScreen(email: _auth.currentUser?.email));
      }
    } else {
      //local storage
      deviceStorage.writeIfNull('IsFirstTime', true);
      deviceStorage.read('IsFirstTime') != true
          ? Get.offAll(() => const LoginScreen())
          : Get.offAll(() => const LoginScreen());
    }
  }

  String _resolveInitialAdminRoute() {
    if (!kIsWeb) return TRoutes.adminDashboard;
    final path = initialBrowserPath().trim().toLowerCase();
    const validAdminPaths = {
      TRoutes.adminDashboard,
      TRoutes.adminFinance,
      TRoutes.adminOrders,
      TRoutes.adminProducts,
      TRoutes.adminVouchers,
      TRoutes.adminBrands,
      TRoutes.adminCategories,
      TRoutes.adminBanners,
      TRoutes.adminUsers,
      TRoutes.adminReviews,
      TRoutes.adminNotifications,
    };
    return validAdminPaths.contains(path) ? path : TRoutes.adminDashboard;
  }

  ///function to determine the relevant screen for the Admin portal
  void screenRedirectAdmin() async {
    final user = _auth.currentUser;
    if (user != null) {
      if (!AdminConfig.isAdminEmail(user.email)) {
        await _auth.signOut();
        Get.offAllNamed(TRoutes.adminLogin);
        return;
      }

      await TLocalStorage.init(user.uid);
      await _ensureAdminUserDoc(user);
      Get.offAllNamed(_resolveInitialAdminRoute());
    } else {
      Get.offAllNamed(TRoutes.adminLogin);
    }
  }


  /*--------------------------------- email & password sign-in--------------------------------------*/

  ///[Email Authentication] - sign in
  Future<UserCredential> loginWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. please try again';
    }
  }

  ///[Email Authentication] - Register
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. please try again';
    }
  }

  ///[Authenticate] - Authenticate user

  ///[Email verification] - verify email
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. please try again';
    }
  }

  ///[logout user] -valid for any authentication
  Future<void> logoutAdmin() async {
    try {
      if (!kIsWeb && defaultTargetPlatform != TargetPlatform.iOS) {
        try {
          await GoogleSignIn().signOut();
        } catch (_) {}
      }
      await AccountActivity.current?.disconnect();
      if (Get.isRegistered<AccountActivity>()) Get.delete<AccountActivity>(force: true);
      await FirebaseAuth.instance.signOut();
      Get.offAllNamed(TRoutes.adminLogin);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. please try again';
    }
  }
  ///[Email Authentication] - forget password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. please try again';
    }
  }
/*--------------------------------- Federated identity & social sign-in--------------------------------------*/

  ///[Google Authentication] -Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..setCustomParameters({'prompt': 'select_account'});

      if (kIsWeb) {
        return await _auth.signInWithPopup(provider);
      }

      // On iOS, FirebaseAuth.signInWithProvider uses ASWebAuthenticationSession
      // directly with Firebase Auth OAuth and never crashes when GIDClientID is absent.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return await _auth.signInWithProvider(provider);
      }

      // On Android, try native GoogleSignIn first and fall back cleanly to
      // FirebaseAuth.signInWithProvider if SHA-1 / OAuth client isn't configured yet.
      try {
        final GoogleSignInAccount? userAccount = await GoogleSignIn().signIn();
        if (userAccount == null) return null;
        final GoogleSignInAuthentication googleAuth =
            await userAccount.authentication;
        if (googleAuth.idToken == null && googleAuth.accessToken == null) {
          return await _auth.signInWithProvider(provider);
        }
        final credentials = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        return await _auth.signInWithCredential(credentials);
      } on FirebaseAuthException {
        rethrow;
      } catch (_) {
        return await _auth.signInWithProvider(provider);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'web-context-canceled' || e.code == 'canceled') {
        return null;
      }
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      if (kDebugMode) print('Google sign-in error: $e');
      rethrow;
    }
  }
  ///[Facebook Authentication] -Facebook

/*--------------------------------- ./end Federated identity & social sign-in--------------------------------------*/

  ///[logout user] -valid for any authentication
  Future<void> logout() async {
    try {
      if (!kIsWeb && defaultTargetPlatform != TargetPlatform.iOS) {
        try {
          await GoogleSignIn().signOut();
        } catch (_) {}
      }
      await AccountActivity.current?.disconnect();
      if (Get.isRegistered<AccountActivity>()) Get.delete<AccountActivity>(force: true);
      await FirebaseAuth.instance.signOut();
      if (kIsWeb) {
        Get.offAllNamed(TRoutes.adminLogin);
      } else {
        Get.offAll(() => const LoginScreen());
      }
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. please try again';
    }
  }


/*--------------------------------- email & password delete -------------------------------------*/
  ///[logout user] -valid for any authentication
  Future<void> reAuthenticateWithEmailAndPassword(String email, String password) async {
    try {
     //create a credential
      AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
      //reAuthenticate
      await _auth.currentUser!.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. please try again';
    }
  }

  ///delete user  - remove AUTH an FireStore account
  Future<void> deleteAccount () async {
    try {
      await UserRepository.instance.removeUserRecord(_auth.currentUser!.uid);
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. please try again';
    }
  }
}
