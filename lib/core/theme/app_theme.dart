import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Dark Theme Colors (matching image - dark gray background)
  static const Color darkBackground = Color(0xFF1A1D29); // Dark gray like in image
  static const Color darkSurface = Color(0xFF2A2F4A);
  static const Color darkPrimary = Color(0xFF6366F1); // Indigo
  static const Color darkSecondary = Color(0xFF8B5CF6); // Purple
  static const Color darkAccent = Color(0xFFEC4899); // Pink
  static const Color darkText = Color(0xFFE5E7EB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF6366F1);
  static const Color lightSecondary = Color(0xFF8B5CF6);
  static const Color lightAccent = Color(0xFFEC4899);
  static const Color lightText = Color(0xFF1F2937);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkSecondary,
        tertiary: darkAccent,
        surface: darkSurface,
        background: darkBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkText,
        onBackground: darkText,
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.apply(
              bodyColor: darkText,
              displayColor: darkText,
            ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkText),
        titleTextStyle: GoogleFonts.inter(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        tertiary: lightAccent,
        surface: lightSurface,
        background: lightBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightText,
        onBackground: lightText,
      ),
      scaffoldBackgroundColor: lightBackground,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme.apply(
              bodyColor: lightText,
              displayColor: lightText,
            ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: lightText),
        titleTextStyle: GoogleFonts.inter(
          color: lightText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

