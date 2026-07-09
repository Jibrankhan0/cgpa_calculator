import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Background
  static const Color bgPrimary = Color(0xFF080C18);
  static const Color bgGradientStart = Color(0xFF0D1326);
  static const Color bgGradientEnd = Color(0xFF111833);

  // Surface
  static const Color surfaceGlass = Color(0x0FFFFFFF);
  static const Color borderGlass = Color(0x1AFFFFFF);

  // Accents
  static const Color accentPrimary = Color(0xFF6366F1);
  static const Color accentSecondary = Color(0xFFA855F7);
  static const Color accentTertiary = Color(0xFF3B82F6);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Text
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);

  // Shadows
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 20,
    offset: Offset(0, 8),
  );

  static const BoxShadow glowShadow = BoxShadow(
    color: Color(0x336366F1),
    blurRadius: 24,
    offset: Offset(0, 8),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgPrimary,
    colorScheme: const ColorScheme.dark(
      primary: accentPrimary,
      secondary: accentSecondary,
      surface: bgPrimary,
      error: danger,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.lexend(
        fontSize: 56,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.lexend(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.lexend(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.lexend(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: textPrimary),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSecondary),
      labelLarge: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: 1.0,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: textMuted,
        letterSpacing: 1.5,
      ),
    ),
  );

  static Color getGpaColor(double gpa) {
    if (gpa >= 3.5) return success;
    if (gpa >= 2.5) return warning;
    return danger;
  }
}
