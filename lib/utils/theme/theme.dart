import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:fashion_business_app/utils/theme/custom_themes/appbar_theme.dart';
import 'package:fashion_business_app/utils/theme/custom_themes/bottom_sheet_theme.dart';
import 'package:fashion_business_app/utils/theme/custom_themes/checkbox_theme.dart';
import 'package:fashion_business_app/utils/theme/custom_themes/chip_theme.dart';
import 'package:fashion_business_app/utils/theme/custom_themes/elevated_button_theme.dart';
import 'package:fashion_business_app/utils/theme/custom_themes/outlined_button_theme.dart';
import 'package:fashion_business_app/utils/theme/custom_themes/text_field_theme.dart';
import 'package:fashion_business_app/utils/theme/custom_themes/text_theme.dart';

class TAppTheme{
  TAppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.light,
    primaryColor: TColors.primaryColor,
    colorScheme: ColorScheme.fromSeed(seedColor: TColors.primaryColor,
        brightness: Brightness.light),
    scaffoldBackgroundColor: Colors.white,
    textTheme: TTextTheme.lightTextTheme,
    elevatedButtonTheme: TElevatedButtonTheme.lightElevatedButtonTheme,
    chipTheme: TChipTheme.lightChipTheme,
    inputDecorationTheme: TTextFieldTheme.lightInputDecorationTheme,
    bottomSheetTheme: TBottomSheetTheme.lightBottomSheetTheme,
    checkboxTheme: TCheckboxTheme.lightCheckboxTheme,
    appBarTheme: TAppBarTheme.lightAppBarTheme,
      outlinedButtonTheme: TOutlinedButtonTheme.lightOutlinedButtonTheme


  );
  static ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      brightness: Brightness.dark,
      primaryColor: TColors.primaryColor,
      colorScheme: ColorScheme.fromSeed(seedColor: TColors.primaryColor,
          brightness: Brightness.dark),
      scaffoldBackgroundColor: Colors.black,
      textTheme: TTextTheme.darkTextTheme,
      elevatedButtonTheme: TElevatedButtonTheme.darkElevatedButtonTheme,
    chipTheme: TChipTheme.darkChipTheme,
    inputDecorationTheme: TTextFieldTheme.darkInputDecorationTheme,
    bottomSheetTheme: TBottomSheetTheme.darkBottomSheetTheme,
    checkboxTheme: TCheckboxTheme.darkCheckboxTheme,
    appBarTheme: TAppBarTheme.darkAppBarTheme,
    outlinedButtonTheme: TOutlinedButtonTheme.darkOutlinedButtonTheme
  );

}
