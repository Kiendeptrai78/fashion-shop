import 'package:flutter/material.dart';

class TTextFieldTheme {
  TTextFieldTheme._();

  static final lightInputDecorationTheme = _decoration(false);
  static final darkInputDecorationTheme = _decoration(true);

  static InputDecorationTheme _decoration(bool dark) {
    final ink = dark ? const Color(0xFFE4ECE7) : const Color(0xFF263E32);
    final focus = dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32);
    final error = dark ? const Color(0xFFFFB4AB) : const Color(0xFFB3261E);
    OutlineInputBorder outline(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
    final border = dark ? const Color(0xFF7E9487) : const Color(0xFF7A8D81);
    return InputDecorationTheme(
      filled: true,
      fillColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return dark ? const Color(0xFF202B25) : const Color(0xFFE8EDE9);
        }
        if (states.contains(WidgetState.error)) {
          return dark ? const Color(0xFF362523) : const Color(0xFFFFF3F1);
        }
        if (states.contains(WidgetState.focused)) {
          return dark ? const Color(0xFF23372C) : Colors.white;
        }
        return dark ? const Color(0xFF1C2D25) : const Color(0xFFF1F4F1);
      }),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      alignLabelWithHint: true,
      errorMaxLines: 3,
      prefixIconColor: dark ? const Color(0xFFB9CABC) : const Color(0xFF526B5B),
      suffixIconColor: dark ? const Color(0xFFB9CABC) : const Color(0xFF526B5B),
      labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ink),
      floatingLabelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ink),
      hintStyle: TextStyle(fontSize: 14,
        color: dark ? const Color(0xFFADBCB2) : const Color(0xFF5F7366)),
      errorStyle: TextStyle(fontSize: 12, height: 1.4, color: error),
      border: outline(border),
      enabledBorder: outline(border),
      focusedBorder: outline(focus, 1.8),
      disabledBorder: outline(dark ? const Color(0xFF4A5A50) : const Color(0xFFB6C4BA)),
      errorBorder: outline(error),
      focusedErrorBorder: outline(error, 1.8),
    );
  }
}
