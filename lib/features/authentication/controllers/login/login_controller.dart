import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:fashion_business_app/common/widgets/loaders/loader.dart';
import 'package:fashion_business_app/data/repositories/authentication/authentication_repository.dart';
import 'package:fashion_business_app/features/authentication/controllers/signup/network_manager.dart';
import 'package:fashion_business_app/features/personalization/controllers/user_controller.dart';
import 'package:fashion_business_app/utils/constants/admin_config.dart';
import 'package:fashion_business_app/utils/constants/image_strings.dart';
import 'package:fashion_business_app/utils/popups/full_screen_loader.dart';

class LoginController extends GetxController{

  ///variables
  final rememberMe = false.obs;
  final hidePassword = true.obs;
  final localStorage = GetStorage();
  final email = TextEditingController();
  final password = TextEditingController();
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  GlobalKey<FormState> loginFormKeyAdmin = GlobalKey<FormState>();
  final userController = Get.isRegistered<UserController>()
      ? Get.find<UserController>() : Get.put(UserController());
  bool _signingIn = false;

  @override
  void onInit() {
    final rememberedEmail = localStorage.read('REMEMBER_ME_EMAIL');
    final rememberedPassword = localStorage.read('REMEMBER_ME_PASSWORD');

    if (rememberedEmail != null) {
      email.text = rememberedEmail;
    }
    if (rememberedPassword != null) {
      password.text = rememberedPassword;
    }

    super.onInit();
  }
  Future<void> emailAndPasswordSignInAdmin() async {
    try {
      //form validation
      if (!loginFormKeyAdmin.currentState!.validate()) {
        return;
      }

      final normalizedEmail = email.text.trim();
      if (!AdminConfig.isAdminEmail(normalizedEmail)) {
        TLoaders.errorSnackBar(
          title: 'Không có quyền truy cập',
          message: 'Chỉ tài khoản quản trị viên (${AdminConfig.adminEmail}) mới được phép đăng nhập.',
        );
        return;
      }

      //start loading
      TFullScreenLoader.openLoadingDialog('Đang xác thực quản trị viên...', TImages.loading);

      //check Internet connect
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      //save email if remember me is selected (never persist plaintext password)
      if (rememberMe.value) {
        localStorage.write('REMEMBER_ME_EMAIL', normalizedEmail);
      }

      //login user using Email & password auth
      await AuthenticationRepository.instance
          .loginWithEmailAndPassword(normalizedEmail, password.text.trim());

      //remove loader
      TFullScreenLoader.stopLoading();

      AuthenticationRepository.instance.screenRedirectAdmin();
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Đăng nhập thất bại', message: e.toString());
    }
  }


  ///email and password signIn
  Future<void> emailAndPasswordSignIn() async {
    if (_signingIn) return;
    _signingIn = true;
    try{
      //start loading
      TFullScreenLoader.openLoadingDialog('Logging you in ....', TImages.loading);

      //check Internet connect
      final isConnected = await NetworkManager.instance.isConnected();
      if(!isConnected){
        TFullScreenLoader.stopLoading();
        return;
      }

      //form validation
      if(!loginFormKey.currentState!.validate()){
        TFullScreenLoader.stopLoading();
        return;
      }

      //save date if remember me is selected
      if(rememberMe.value){
        localStorage.write('REMEMBER_ME_EMAIL', email.text.trim());
        localStorage.write('REMEMBER_ME_PASSWORD', password.text.trim());
      }

      //login user using Email & password auth
      await AuthenticationRepository.instance.loginWithEmailAndPassword(email.text.trim(), password.text.trim());

      await AuthenticationRepository.instance.screenRedirect(
        beforeNavigate: TFullScreenLoader.stopLoading);
    }catch(e){
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    } finally {
      TFullScreenLoader.stopLoading();
      _signingIn = false;
    }
  }


  ///google sign in
  Future<void> googleSignIn() async {
    if (_signingIn) return;
    _signingIn = true;
    try{
      //start loading
      TFullScreenLoader.openLoadingDialog('Logging with google...', TImages.loading);

      //check Internet connect
      final isConnected = await NetworkManager.instance.isConnected();
      if(!isConnected){
        TFullScreenLoader.stopLoading();
        return;
      }

      //googleSigning
      final userCredentials = await AuthenticationRepository.instance.signInWithGoogle();
      if (userCredentials == null) {
        TFullScreenLoader.stopLoading();
        return;
      }

      //save user record
      await userController.saveUserRecord(userCredentials);

      await AuthenticationRepository.instance.screenRedirect(
        beforeNavigate: TFullScreenLoader.stopLoading);

    }catch(e){
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Oh Snap',message: e.toString());
    } finally {
      TFullScreenLoader.stopLoading();
      _signingIn = false;
    }
  }

  ///facebook signing
}
