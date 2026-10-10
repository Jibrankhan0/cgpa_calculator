import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Palette {
  final Color bg, surface, field, fg, muted, border;
  final Color accent, accentSoft, accentInk, accentDeep;
  final Color invBg, invFg, invEyebrow, tabbar, danger;

  const Palette({
    required this.bg,
    required this.surface,
    required this.field,
    required this.fg,
    required this.muted,
    required this.border,
    required this.accent,
    required this.accentSoft,
    required this.accentInk,
    required this.accentDeep,
    required this.invBg,
    required this.invFg,
    required this.invEyebrow,
    required this.tabbar,
    required this.danger,
  });

  static const Palette light = Palette(
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF7F8FA),
    field: Color(0xFFFFFFFF),
    fg: Color(0xFF111111),
    muted: Color(0xFF6B7280),
    border: Color(0xFFD9DEE7),
    accent: Color(0xFF1677FF),
    accentSoft: Color(0xFFEAF3FF),
    accentInk: Color(0xFF1561CB),
    accentDeep: Color(0xFF1564D4),
    invBg: Color(0xFF111111),
    invFg: Color(0xFFFFFFFF),
    invEyebrow: Color(0xFF6FABFF),
    tabbar: Color(0xFFFFFFFF),
    danger: Color(0xFFDC2626),
  );

  static const Palette dark = Palette(
    bg: Color(0xFF111111),
    surface: Color(0xFF303030),
    field: Color(0xFF414141),
    fg: Color(0xFFFFFFFF),
    muted: Color(0xFFA3A7AE),
    border: Color(0xFF3A3B40),
    accent: Color(0xFF1677FF),
    accentSoft: Color(0xFF152F4E),
    accentInk: Color(0xFF579DFF),
    accentDeep: Color(0xFF1564D4),
    invBg: Color(0xFFFFFFFF),
    invFg: Color(0xFF111111),
    invEyebrow: Color(0xFF1450A4),
    tabbar: Color(0xFF282828),
    danger: Color(0xFFF87171),
  );

  static Palette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light, Palette.light);
  static ThemeData dark() => _build(Brightness.dark, Palette.dark);

  static ThemeData _build(Brightness brightness, Palette p) {
    final base = brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();
    final textTheme = GoogleFonts.interTextTheme(base.textTheme)
        .apply(bodyColor: p.fg, displayColor: p.fg);

    OutlineInputBorder outline(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: p.accent,
        onPrimary: Colors.white,
        secondary: p.accent,
        onSecondary: Colors.white,
        error: p.danger,
        onError: Colors.white,
        surface: p.surface,
        onSurface: p.fg,
        outline: p.border,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: p.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: p.border),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.field,
        hintStyle: TextStyle(color: p.muted, fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: outline(p.border),
        enabledBorder: outline(p.border),
        focusedBorder: outline(p.accent, 1.5),
        errorBorder: outline(p.accent),
        focusedErrorBorder: outline(p.accent, 1.5),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accentInk,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
    );
  }
}
