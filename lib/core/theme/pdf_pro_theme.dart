import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PdfProTheme {
  PdfProTheme._();

  // Professional Color Palette
  static const Color primaryBlue = Color(0xFF0052CC);
  static const Color accentIndigo = Color(0xFF4C9AFF);
  static const Color backgroundLight = Color(0xFFF4F5F7);
  static const Color surfaceWhite = Colors.white;
  static const Color textDark = Color(0xFF172B4D);
  static const Color textLight = Color(0xFF6B778C);
  static const Color errorRed = Color(0xFFDE350B);
  static const Color successGreen = Color(0xFF36B37E);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: accentIndigo,
        surface: surfaceWhite,
        error: errorRed,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(color: textDark, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.inter(color: textDark, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: textDark),
        bodyMedium: GoogleFonts.inter(color: textLight),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceWhite,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textLight,
        elevation: 16,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // Professional Glass Decoration
  static BoxDecoration proGlassDecoration({BorderRadius? borderRadius}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.8),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ],
    );
  }
}
