import 'dart:ui';
import 'package:flutter/material.dart';

class CyberpunkTheme {
  CyberpunkTheme._();

  static const Color backgroundDark = Color(0xFF0A0A12);
  static const Color surfaceTranslucent = Color(0x1A0D0D1A);

  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonPink = Color(0xFFFF007F);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color textPrimary = Color(0xFFF5F5FA);
  static const Color textSecondary = Color(0x8AFFFFFF);

  static const double blurSigmaX = 20.0;
  static const double blurSigmaY = 20.0;

  static ImageFilter get glassBlurFilter =>
      ImageFilter.blur(sigmaX: blurSigmaX, sigmaY: blurSigmaY);

  static ThemeData get darkTheme {
    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonPink,
        surface: backgroundDark,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary, fontFamily: 'monospace'),
        bodyMedium: TextStyle(color: textSecondary, fontFamily: 'monospace'),
      ),
    );
  }

  static BoxDecoration glassDecoration({
    BorderRadius? borderRadius,
    Color borderColor = const Color(0x3300F0FF),
  }) {
    return BoxDecoration(
      color: surfaceTranslucent,
      borderRadius: borderRadius ?? BorderRadius.circular(24.0),
      border: Border.all(color: borderColor, width: 1.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 20.0,
          spreadRadius: -5.0,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}
