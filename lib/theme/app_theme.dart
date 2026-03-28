import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color primaryIndigo = Color(0xFF3F51B5);
  static const Color backgroundDark = Color(0xFF0A0E21);
  static const Color surfaceGlass = Color(0x1AFFFFFF);
  static const Color accentAmber = Color(0xFFFFC107);
  static const Color errorRed = Color(0xFFFF5252);
  static const Color successGreen = Color(0xFF4CAF50);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: primaryCyan,
      secondary: primaryIndigo,
      surface: backgroundDark,
      error: errorRed,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.lexend(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      displayMedium: GoogleFonts.lexend(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleLarge: GoogleFonts.lexend(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: Colors.white60),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: GoogleFonts.inter(color: Colors.white),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(
          backgroundDark.withValues(alpha: 0.9),
        ),
      ),
    ),
  );
}
