import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ========== DARK THEME COLORS ==========
  static const Color darkBgPrimary = Color(0xFF080C18);
  static const Color darkBgGradientStart = Color(0xFF0D1326);
  static const Color darkBgGradientEnd = Color(0xFF111833);
  static const Color darkSurfaceGlass = Color(0x0FFFFFFF);
  static const Color darkBorderGlass = Color(0x1AFFFFFF);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF475569);

  // ========== LIGHT THEME COLORS ==========
  static const Color lightBgPrimary = Color(0xFFF8FAFC);
  static const Color lightBgGradientStart = Color(0xFFEFF6FF);
  static const Color lightBgGradientEnd = Color(0xFFF1F5F9);
  static const Color lightSurfaceGlass = Color(0x0A000000);
  static const Color lightBorderGlass = Color(0x14000000);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // ========== SHARED COLORS ==========
  static const Color accentPrimary = Color(0xFF6366F1);
  static const Color accentSecondary = Color(0xFFA855F7);
  static const Color accentTertiary = Color(0xFF3B82F6);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // ========== THEME-AWARE HELPERS ==========
  static Color bgPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBgPrimary : lightBgPrimary;

  static Color bgGradientStart(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBgGradientStart : lightBgGradientStart;

  static Color bgGradientEnd(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBgGradientEnd : lightBgGradientEnd;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary;

  static Color textMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextMuted : lightTextMuted;

  static Color surfaceGlass(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurfaceGlass : lightSurfaceGlass;

  static Color borderGlass(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBorderGlass : lightBorderGlass;

  // ========== DARK THEME ==========
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBgPrimary,
    colorScheme: const ColorScheme.dark(
      primary: accentPrimary,
      secondary: accentSecondary,
      surface: darkBgPrimary,
      error: danger,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.lexend(
        fontSize: 56,
        fontWeight: FontWeight.bold,
        color: darkTextPrimary,
      ),
      displayMedium: GoogleFonts.lexend(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: darkTextPrimary,
      ),
      headlineMedium: GoogleFonts.lexend(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
      ),
      titleLarge: GoogleFonts.lexend(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: darkTextPrimary,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: darkTextPrimary),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: darkTextSecondary),
      labelLarge: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: darkTextPrimary,
        letterSpacing: 1.0,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: darkTextMuted,
        letterSpacing: 1.5,
      ),
    ),
  );

  // ========== LIGHT THEME ==========
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBgPrimary,
    colorScheme: const ColorScheme.light(
      primary: accentPrimary,
      secondary: accentSecondary,
      surface: lightBgPrimary,
      error: danger,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
      displayLarge: GoogleFonts.lexend(
        fontSize: 56,
        fontWeight: FontWeight.bold,
        color: lightTextPrimary,
      ),
      displayMedium: GoogleFonts.lexend(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: lightTextPrimary,
      ),
      headlineMedium: GoogleFonts.lexend(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: lightTextPrimary,
      ),
      titleLarge: GoogleFonts.lexend(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: lightTextPrimary,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: lightTextPrimary),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: lightTextSecondary),
      labelLarge: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: lightTextPrimary,
        letterSpacing: 1.0,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: lightTextMuted,
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
