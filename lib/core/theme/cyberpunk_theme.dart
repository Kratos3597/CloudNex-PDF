import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CyberpunkTheme {
  CyberpunkTheme._();

  static const Color backgroundDark = Color(0xFF020205);
  static const Color surfaceTranslucent = Color(0x331A1A2E); // Slightly more opacity for Apple feel

  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonPink = Color(0xFFFF007F);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonYellow = Color(0xFFF3E600);
  static const Color textPrimary = Color(0xFFF5F5FA);
  static const Color textSecondary = Color(0xAABBBBCB);

  static const double blurSigmaX = 25.0; // Higher blur for Apple effect
  static const double blurSigmaY = 25.0;

  static ImageFilter get glassBlurFilter =>
      ImageFilter.blur(sigmaX: blurSigmaX, sigmaY: blurSigmaY);

  static ThemeData get darkTheme {
    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonPink,
        surface: backgroundDark,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary, fontFamily: 'monospace', letterSpacing: 0.5),
        bodyMedium: TextStyle(color: textSecondary, fontFamily: 'monospace'),
      ),
    );
  }

  static BoxDecoration glassDecoration({
    BorderRadius? borderRadius,
    Color borderColor = const Color(0x22FFFFFF), // Subtler white border
    bool showGlow = false,
  }) {
    return BoxDecoration(
      color: surfaceTranslucent,
      borderRadius: borderRadius ?? BorderRadius.circular(12.0), // Rounded corners
      border: Border.all(color: borderColor, width: 0.5), // Hairline border
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ),
      boxShadow: [
        if (showGlow)
          BoxShadow(
            color: borderColor.withValues(alpha: 0.2),
            blurRadius: 15.0,
            spreadRadius: 1.0,
          ),
      ],
    );
  }

  static TextStyle neonTextStyle({
    Color color = neonCyan,
    double fontSize = 14,
    bool bold = false,
    bool italic = false,
  }) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontFamily: 'monospace',
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      shadows: [
        Shadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
      ],
    );
  }

  static Widget glitchText(String text, {TextStyle? style}) {
    return text.split('').map((char) {
      return Text(char, style: style);
    }).toList().asMap().entries.map((entry) {
      return entry.value.animate(onPlay: (controller) => controller.repeat())
          .shimmer(duration: 2.seconds, color: neonPink.withValues(alpha: 0.2))
          .shake(duration: 100.ms, hz: 4, offset: const Offset(1, 0));
    }).toList().last; // Simplified glitch effect
  }
}
