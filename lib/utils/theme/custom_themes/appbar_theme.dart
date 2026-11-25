import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TAppBarTheme{
  TAppBarTheme._();

  static const lightAppBarTheme = AppBarTheme(
    systemOverlayStyle: SystemUiOverlayStyle.dark,
      elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: Colors.black,size: 24),
    actionsIconTheme: IconThemeData(color: Colors.black,size: 24),
    titleTextStyle: TextStyle(fontFamily: 'BeVietnamPro',fontSize: 18,fontWeight: FontWeight.w600,color: Colors.black),
   );

  static const darkAppBarTheme = AppBarTheme(
    systemOverlayStyle: SystemUiOverlayStyle.light,
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: Colors.white,size: 24),
    actionsIconTheme: IconThemeData(color: Colors.white,size: 24),
    titleTextStyle: TextStyle(fontFamily: 'BeVietnamPro',fontSize: 18,fontWeight: FontWeight.w600,color: Colors.white),
  );
}
