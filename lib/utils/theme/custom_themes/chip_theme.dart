import 'package:flutter/material.dart';

class TChipTheme {
  TChipTheme._();

  static ChipThemeData lightChipTheme = ChipThemeData(
    disabledColor: Colors.grey.withValues(alpha: 0.35),
    backgroundColor: const Color(0xFFF3F5F0),
    selectedColor: const Color(0xFF173E32),
    side: const BorderSide(color: Color(0xFFDFE5DD)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    labelStyle: const TextStyle(
      color: Color(0xFF173E32),
      fontWeight: FontWeight.w500,
      fontSize: 13,
    ),
    secondaryLabelStyle: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    checkmarkColor: const Color(0xFFDDEABB),
  );

  static ChipThemeData darkChipTheme = ChipThemeData(
    disabledColor: Colors.grey.withValues(alpha: 0.35),
    backgroundColor: const Color(0xFF1D2D26),
    selectedColor: const Color(0xFFDDEABB),
    side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    labelStyle: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w500,
      fontSize: 13,
    ),
    secondaryLabelStyle: const TextStyle(
      color: Color(0xFF102B23),
      fontWeight: FontWeight.w700,
      fontSize: 13,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    checkmarkColor: const Color(0xFF102B23),
  );
}
