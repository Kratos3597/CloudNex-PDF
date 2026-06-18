import 'dart:ui';
import 'package:flutter/material.dart';

class CyberpunkTheme {
  CyberpunkTheme._();

  static const Color backgroundDark = Color(0xFF020205);
  static const Color surfaceTranslucent = Color(0x220D0D1A);

  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonPink = Color(0xFFFF007F);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonYellow = Color(0xFFF3E600);
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
    bool showGlow = false,
  }) {
    return BoxDecoration(
      color: surfaceTranslucent,
      borderRadius: borderRadius ?? BorderRadius.circular(4.0),
      border: Border.all(color: borderColor.withOpacity(0.5), width: 1.5),
      boxShadow: [
        if (showGlow)
          BoxShadow(
            color: borderColor.withOpacity(0.3),
            blurRadius: 12.0,
            spreadRadius: 1.0,
          ),
      ],
    );
  }

  static TextStyle neonTextStyle({
    Color color = neonCyan,
    double fontSize = 14,
    bool bold = false,
  }) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontFamily: 'monospace',
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      shadows: [
        Shadow(color: color.withOpacity(0.5), blurRadius: 8),
      ],
    );
  }
}
