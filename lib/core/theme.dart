import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF4F8FC);
  static const navy = Color(0xFF10294A);
  static const teal = Color(0xFF1A7F8E);
  static const tealLight = Color(0xFFE3F2F4);
  static const red = Color(0xFFE84A4F);
  static const textMuted = Color(0xFF5B6B7F);
  static const border = Color(0xFFDDE6EF);
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.teal),
    scaffoldBackgroundColor: AppColors.background,
    // Bundle an Arabic font (for example Cairo or Tajawal) in assets, then:
    // fontFamily: 'Cairo',
  );
}
