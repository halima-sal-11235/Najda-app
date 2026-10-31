import 'package:flutter/material.dart';

// ===== Nedjda DZ palette (from the design) =====
const Color primaryColor = Color(0xFF102A43);   // Primary
const Color secondaryColor = Color(0xFF167D8D); // Secondary
const Color emergencyColor = Color(0xFFE5484D); // Emergency
const Color warningColor = Color(0xFFF4A340);   // Warning
const Color bgColor = Color(0xFFF5F8FA);        // Background
const Color cardWhite = Color(0xFFFFFFFF);      // Cards
const Color textColor = Color(0xFF243746);      // Text
const Color successColor = Color(0xFF2EB872);   // "I'm OK" green
const Color mutedColor = Color(0xFF7B8794);
const Color borderColor = Color(0xFFE3EAF0);
const Color dangerColor = emergencyColor;       // used by the onboarding form

final ThemeData _base = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: secondaryColor).copyWith(
    primary: primaryColor,
    secondary: secondaryColor,
    error: emergencyColor,
  ),
  scaffoldBackgroundColor: bgColor,
);

final ThemeData appTheme = _base.copyWith(
  textTheme: _base.textTheme.apply(bodyColor: textColor, displayColor: textColor),
);
