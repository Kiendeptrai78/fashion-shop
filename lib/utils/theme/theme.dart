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

class TAppTheme {
  TAppTheme._();

  static final RadioThemeData _lightRadioTheme = RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF173E32);
      return const Color(0xFF8C9F95);
    }),
  );

  static final RadioThemeData _darkRadioTheme = RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFDDEABB);
      return const Color(0xFF6B8578);
    }),
  );

  static final SwitchThemeData _lightSwitchTheme = SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFDDEABB);
      return Colors.white;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF173E32);
      return const Color(0xFFD5DFD9);
    }),
  );

  static final SwitchThemeData _darkSwitchTheme = SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF102B23);
      return const Color(0xFF9EB0A6);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFDDEABB);
      return const Color(0xFF283A31);
    }),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.light,
    primaryColor: TColors.primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: TColors.primaryColor,
      primary: const Color(0xFF173E32),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    textTheme: TTextTheme.lightTextTheme,
    elevatedButtonTheme: TElevatedButtonTheme.lightElevatedButtonTheme,
    chipTheme: TChipTheme.lightChipTheme,
    inputDecorationTheme: TTextFieldTheme.lightInputDecorationTheme,
    bottomSheetTheme: TBottomSheetTheme.lightBottomSheetTheme,
    checkboxTheme: TCheckboxTheme.lightCheckboxTheme,
    radioTheme: _lightRadioTheme,
    switchTheme: _lightSwitchTheme,
    appBarTheme: TAppBarTheme.lightAppBarTheme,
    outlinedButtonTheme: TOutlinedButtonTheme.lightOutlinedButtonTheme,
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.dark,
    primaryColor: TColors.primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: TColors.primaryColor,
      primary: const Color(0xFFDDEABB),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: Colors.black,
    textTheme: TTextTheme.darkTextTheme,
    elevatedButtonTheme: TElevatedButtonTheme.darkElevatedButtonTheme,
    chipTheme: TChipTheme.darkChipTheme,
    inputDecorationTheme: TTextFieldTheme.darkInputDecorationTheme,
    bottomSheetTheme: TBottomSheetTheme.darkBottomSheetTheme,
    checkboxTheme: TCheckboxTheme.darkCheckboxTheme,
    radioTheme: _darkRadioTheme,
    switchTheme: _darkSwitchTheme,
    appBarTheme: TAppBarTheme.darkAppBarTheme,
    outlinedButtonTheme: TOutlinedButtonTheme.darkOutlinedButtonTheme,
  );
}
