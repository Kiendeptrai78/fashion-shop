import 'package:fashion_business_app/routes/app_route.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'bindings/genaral_bindings.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      themeMode: ThemeMode.system,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      initialBinding: GeneralBinding(),
      getPages: AppRoutes.pages,
      home: const Scaffold(backgroundColor: TColors.darkerGrey,body: Center(child: CircularProgressIndicator(color: TColors.white,),),),
      debugShowCheckedModeBanner: false,
    );
  }
}
