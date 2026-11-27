import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:flutter/material.dart';

class TElevatedButtonTheme{
  TElevatedButtonTheme._();

  static final lightElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 2,
      shadowColor: const Color(0x33173E32),
      foregroundColor: Colors.white,
      backgroundColor: TColors.primaryColor,
      disabledBackgroundColor: TColors.primaryColor.withValues(alpha: 0.1),
      disabledForegroundColor: TColors.primaryColor.withValues(alpha: 0.55),
      side: const BorderSide(color: Color(0x44FFFFFF)),
      minimumSize: const Size(64, 52),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      textStyle: const TextStyle(
        fontSize: 15.5,
        height: 1.2,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
  static final darkElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      foregroundColor: Colors.white,
      backgroundColor: TColors.primaryColor,
      disabledBackgroundColor: Colors.white12,
      disabledForegroundColor: Colors.white54,
      side: BorderSide.none,
      minimumSize: const Size(64, 52),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      textStyle: const TextStyle(
        fontSize: 15.5,
        height: 1.2,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

}
