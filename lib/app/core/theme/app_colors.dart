import 'package:flutter/material.dart';

class AppColors {
  static const Color blue = Color(0xFF4481EB);
  static const Color cultured = Color(0xFFF5F5F5);
  static get Slate_Gray=>const Color(0xff6B737A);

  static const Color gunmetal = Color(0xFF2C3E50);
  static const Color purple = Color(0xff22172A);
  static const Color borderColor = Color(0xff006175);
  // Additional colors
  static const Color primary = blue;
  static const Color background = Colors.white;
  static const Color surface = cultured;
  static const Color error = Color(0xFFE53935);

  static const Color onPrimary = Colors.white;
  static const Color onBackground = gunmetal;
  static const Color onSurface = gunmetal;
  static const Color onError = Colors.white;

  static ColorScheme get colorScheme => const ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    secondary: blue,
    onSecondary: onPrimary,
    error: error,
    onError: onError,
    surface: surface,
    onSurface: onSurface,
  );
}
