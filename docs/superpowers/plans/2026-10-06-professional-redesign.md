# Plan: Professional redesign (MCKRU CGPA Calculator)

**Date:** 2026-10-06
**Goal:** Restyle the entire Flutter app to match the approved HTML design mockup, keeping every piece of functionality, data, navigation, and calculation behavior identical.

**Design source (source of truth):**
`C:\Users\Jibran Khan Dehpal\Downloads\open-design-main\open-design-main\.od\projects\fa9bdbf7-ae45-4dba-81e3-f5358d346991\mckru-cgpa-redesign.html`
(mocked screens: Splash, Home, GPA, CGPA, Settings in light+dark, empty state; token sheet at bottom of file).

**Baseline (verified):** Flutter 3.41.6 / Dart 3.11.4, `flutter analyze` = 83 issues (all `withOpacity` deprecation infos + 5 warnings: unused `_PageHeader`, `_SettingsGroup`, `dart:math`/`app_theme` imports). No errors. `flutter test` is currently broken (default counter test).

---

## Hard constraints (never violate)

1. **Do not modify:** `lib/providers/app_data.dart`, `lib/services/gpa_service.dart`, `lib/main.dart`, `lib/widgets/staggered_animation.dart`, models, calculations, or validation semantics.
2. **Do not change SharedPreferences keys:** `mckru_gpa2`, `mckru_cgpa2`, `mckru_dark2`, `mckru_onboarded2`, `mckru_name`, `mckru_avatar`.
3. **Preserve verbatim:** tab index mapping 0=Home, 1=GPA, 2=CGPA, 3=Storage, 4=Settings; input formatters `^\d{0,3}\.?\d{0,1}$` (marks) and `^\d{0,2}\.?\d{0,2}$` (GPA) incl. the auto-"." insertion logic (`_isFormatting`); all `GpaService` validation messages and their display condition (validation is display-only, never blocks input); splash 2500 ms timer + `hasSeenOnboarding` branch; onboarding flow (3 pages + name/avatar step, default name `'Student'`); GPA/CGPA computation loops exactly as written today; grade colors from `GpaService.gradeMap`; `StaggeredAnimation` usage; portrait lock and textScaler clamp in `main.dart`; `BottomNavBar` public ctor `({required currentIndex, required onTap})`.
4. **Dependencies:** keep `provider`, `shared_preferences`, `flutter_svg`; add only `google_fonts` (user-approved). No other new packages.
5. **Do not invent functionality.** Where the mock shows data the app doesn't have (e.g. "Semester 4 · Spring 2026"), substitute real derivable data or static copy.

---

## Design tokens (from the mock's token sheet)

| Token | Light | Dark |
|---|---|---|
| bg | `#FFFFFF` | `#111111` |
| surface (cards) | `#F7F8FA` | `#303030` |
| field (inputs) | `#FFFFFF` | `#414141` |
| fg | `#111111` | `#FFFFFF` |
| muted | `#6B7280` | `#A3A7AE` |
| border (1px) | `#D9DEE7` | `#3A3B40` |
| accent | `#1677FF` | `#1677FF` |
| accentSoft | `#EAF3FF` | `#152F4E` |
| accentInk | `#1561CB` | `#579DFF` |
| accentDeep (primary btn) | `#1564D4` | `#1564D4` |
| invBg / invFg (hero card) | `#111111` / `#FFFFFF` | `#FFFFFF` / `#111111` |
| hero eyebrow | `#6FABFF` | `#1450A4` |
| tabbar | `#FFFFFF` | `#282828` |
| danger (dialogs only, not in mock) | `#DC2626` | `#F87171` |

**Rules:** Inter font (google_fonts), radius **8px everywhere**, 1px borders, **flat design — no gradients, no box shadows, no emojis**, 8px grid, ≥44px touch targets, tabular figures on all numbers.

**Error styling (mock has no red token):** invalid input → border `accent` + bg `accentSoft`; error text row → `accentInk`.

**Status pills:** `Excellent` (≥3.5) → pill-up (`accentSoft` bg + `accentInk` text); `Good`/`Average`/`Keep Trying` → flat (`field` bg + border + `muted` text). Text from `GpaService.getSemesterStatus`, emoji dropped.

**Grammar per screen:** page titles + actions live in the shell top bar (per-tab); pages render only scrollable content.

---

## Task 1 — Dependencies + design tokens

**Files:** `pubspec.yaml`, `lib/theme/app_theme.dart`

### Steps
1. `flutter pub add google_fonts`
2. In `app_theme.dart`: **keep the existing `AppColors` class untouched** (screens still reference it until Tasks 5–11 finish), append the new `Palette` class, and replace `AppTheme.light()/dark()` bodies with the new implementation below.
3. Delete the old `ThemeData` bodies (Nunito font, radius-20 card theme, purple text theme).

### New code — `Palette`

```dart
class Palette {
  final Color bg, surface, field, fg, muted, border;
  final Color accent, accentSoft, accentInk, accentDeep;
  final Color invBg, invFg, invEyebrow, tabbar, danger;

  const Palette({
    required this.bg, required this.surface, required this.field,
    required this.fg, required this.muted, required this.border,
    required this.accent, required this.accentSoft, required this.accentInk,
    required this.accentDeep, required this.invBg, required this.invFg,
    required this.invEyebrow, required this.tabbar, required this.danger,
  });

  static const Palette light = Palette(
    bg: Color(0xFFFFFFFF), surface: Color(0xFFF7F8FA), field: Color(0xFFFFFFFF),
    fg: Color(0xFF111111), muted: Color(0xFF6B7280), border: Color(0xFFD9DEE7),
    accent: Color(0xFF1677FF), accentSoft: Color(0xFFEAF3FF),
    accentInk: Color(0xFF1561CB), accentDeep: Color(0xFF1564D4),
    invBg: Color(0xFF111111), invFg: Color(0xFFFFFFFF),
    invEyebrow: Color(0xFF6FABFF), tabbar: Color(0xFFFFFFFF),
    danger: Color(0xFFDC2626),
  );

  static const Palette dark = Palette(
    bg: Color(0xFF111111), surface: Color(0xFF303030), field: Color(0xFF414141),
    fg: Color(0xFFFFFFFF), muted: Color(0xFFA3A7AE), border: Color(0xFF3A3B40),
    accent: Color(0xFF1677FF), accentSoft: Color(0xFF152F4E),
    accentInk: Color(0xFF579DFF), accentDeep: Color(0xFF1564D4),
    invBg: Color(0xFFFFFFFF), invFg: Color(0xFF111111),
    invEyebrow: Color(0xFF1450A4), tabbar: Color(0xFF282828),
    danger: Color(0xFFF87171),
  );

  static Palette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
```

### New code — `AppTheme`

```dart
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
        primary: p.accent, onPrimary: Colors.white,
        secondary: p.accent, onSecondary: Colors.white,
        error: p.danger, onError: Colors.white,
        surface: p.surface, onSurface: p.fg, outline: p.border,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: p.border)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: p.border)),
      ),
      appBarTheme: AppBarTheme(backgroundColor: p.bg, surfaceTintColor: Colors.transparent),
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
```

(Keep the `AppColors` class exactly as-is above `AppTheme` — it is deleted in Task 12.)

### Verify
`flutter analyze` → still only pre-existing infos/warnings (no errors, no new warnings).

### Commit
`style: add design tokens palette and Inter-based theme`

---

## Task 2 — Shared design primitives

**File (new):** `lib/widgets/ui.dart`

All screens in Tasks 5–11 import this. Complete code:

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

const double kRadius = 8;

TextStyle numStyle(double size, FontWeight weight, Color color) => TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

class UiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const UiCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.color});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: p.border),
      ),
      child: child,
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;

  const SectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: p.muted, letterSpacing: 0.14),
          ),
          if (trailing != null)
            Text(trailing!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.muted)),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool expanded;

  const PrimaryButton({super.key, required this.label, this.onTap, this.icon, this.expanded = false});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final btn = Material(
      color: p.accentDeep,
      borderRadius: BorderRadius.circular(kRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadius),
        child: SizedBox(
          height: 46,
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 17, color: Colors.white), const SizedBox(width: 7)],
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool danger;

  const GhostButton({super.key, required this.label, this.onTap, this.icon, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final fg = danger ? p.danger : p.fg;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(kRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadius),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: danger ? p.danger.withValues(alpha: 0.4) : p.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 6)],
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  const SquareIconButton({super.key, required this.icon, this.onTap, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(kRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadius),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: p.border),
          ),
          child: Icon(icon, size: 19, color: p.fg),
        ),
      ),
    );
  }
}

class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AppSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: value ? p.accent : p.border,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class IdxBadge extends StatelessWidget {
  final String text;
  const IdxBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(kRadius)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: p.accentInk)),
    );
  }
}

class GradeChip extends StatelessWidget {
  final String letter;
  final double gpa;
  const GradeChip({super.key, required this.letter, required this.gpa});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(kRadius)),
      child: Text('$letter · ${gpa.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.accentInk,
              fontFeatures: const [FontFeature.tabularFigures()])),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String status;
  final bool up;
  const StatusPill({super.key, required this.status, required this.up});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: up ? p.accentSoft : p.field,
        borderRadius: BorderRadius.circular(kRadius),
        border: up ? null : Border.all(color: p.border),
      ),
      child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          color: up ? p.accentInk : p.muted)),
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Text(text.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.muted, letterSpacing: 0.06));
  }
}

class InputError extends StatelessWidget {
  final String message;
  const InputError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 13, color: p.accentInk),
          const SizedBox(width: 4),
          Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.accentInk)),
          ),
        ],
      ),
    );
  }
}

InputDecoration fieldInput(BuildContext context, {String? hint, bool error = false, Widget? suffix}) {
  final p = Palette.of(context);
  OutlineInputBorder outline(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadius),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    suffix: suffix,
    filled: true,
    fillColor: error ? p.accentSoft : p.field,
    hintStyle: TextStyle(color: p.muted, fontWeight: FontWeight.w500),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: outline(error ? p.accent : p.border),
    enabledBorder: outline(error ? p.accent : p.border),
    focusedBorder: outline(p.accent, 1.5),
  );
}

class ResultCard extends StatelessWidget {
  final String eyebrow;
  final String value;
  final double? progress;
  final String? message;

  const ResultCard({super.key, required this.eyebrow, required this.value, this.progress, this.message});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return UiCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: p.muted, letterSpacing: 0.18)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: numStyle(44, FontWeight.w800, p.fg)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('/4.00', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.muted)),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 4,
              width: double.infinity,
              child: Stack(
                children: [
                  Container(height: 4, decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(2))),
                  FractionallySizedBox(
                    widthFactor: progress!.clamp(0.0, 1.0),
                    child: Container(height: 4, decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(2))),
                  ),
                ],
              ),
            ),
          ],
          if (message != null) ...[
            const SizedBox(height: 10),
            Text(message!, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.muted)),
          ],
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  const StatTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return UiCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: p.muted, letterSpacing: 0.12)),
          Text(value, style: numStyle(26, FontWeight.w800, p.fg)),
        ],
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsRow({super.key, required this.icon, required this.label, required this.desc,
    this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(kRadius)),
            child: Icon(icon, size: 17, color: p.accentInk),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.fg)),
                const SizedBox(height: 1),
                Text(desc, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: p.muted)),
              ],
            ),
          ),
          trailing ?? Icon(Icons.chevron_right, size: 18, color: p.muted),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? buttonLabel;
  final VoidCallback? onButton;

  const EmptyState({super.key, this.icon = Icons.folder_outlined, required this.title,
    required this.body, this.buttonLabel, this.onButton});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(kRadius)),
            child: Icon(icon, size: 26, color: p.accentInk),
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.fg)),
          const SizedBox(height: 6),
          Text(body, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: p.muted, height: 1.5)),
          if (buttonLabel != null) ...[
            const SizedBox(height: 20),
            PrimaryButton(label: buttonLabel!, icon: Icons.add, onTap: onButton),
          ],
        ],
      ),
    );
  }
}
```

### Verify
`flutter analyze` (no new issues) + commit: `feat: add shared UI primitives for the redesign`

---

## Task 3 — Flat bottom navigation

**File:** `lib/widgets/bottom_nav_bar.dart` (full rewrite; keep public ctor identical)

Design: flat bar (no rounded top, no shadow), 1px top border, 68px height, active tab = 16×3px accent indicator at the top edge + `accentInk` icon/label, inactive = `muted`. Labels per mock: **Home, GPA, CGPA, Data, Settings**. Reuse the existing SVG path data + `_svgPath()` helper verbatim.

### Complete code

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

  static const List<({String icon, String label})> _items = [
    (icon: 'M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2zM9 22V12h6v10', label: 'Home'),
    (icon: 'M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8zM14 2v6h6M16 13H8M16 17H8', label: 'GPA'),
    (icon: 'M22 10v6M2 10l10-5 10 5-10 5zM6 12v5c3 3 9 3 12 0v-5', label: 'CGPA'),
    (icon: 'M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-10M12 15V3', label: 'Data'),
    (icon: 'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z', label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.tabbar,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (int i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: _items[i].icon,
                    label: _items[i].label,
                    isActive: currentIndex == i,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final color = isActive ? p.accentInk : p.muted;

    return InkWell(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 16,
            height: 3,
            decoration: BoxDecoration(
              color: isActive ? p.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          SvgPicture.string(
            '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="$icon"/></svg>',
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
```

### Verify / Commit
`flutter analyze`; commit `style: flat design-system bottom navigation`.

---

## Task 4 — Per-tab shell top bar

**File:** `lib/screens/main_shell.dart` (full rewrite of the widget tree; `_switchTab` + `AnimatedSwitcher` behavior unchanged)

The mock puts the page title and primary action in a per-tab top bar:

| Tab | Left | Right |
|---|---|---|
| 0 Home | avatar 40px + `Welcome back, {name}` (15 w800) / `CGPA & GPA tracker` (11.5 muted) | theme `SquareIconButton` |
| 1 GPA | `GPA Calculator` (20 w800) | `GhostButton('Add subject', add)` → `data.addGpaSubject()` |
| 2 CGPA | `CGPA Tracker` (20 w800) | `GhostButton('Add semester', add)` → `data.addSemester()` |
| 3 Data | `Saved Data` (20 w800) | – |
| 4 Settings | `Settings` (20 w800) | theme `SquareIconButton` |

Theme icon follows the mock: light mode shows `Icons.light_mode_outlined`, dark shows `Icons.dark_mode_outlined` (state indicator), both wired to `data.toggleDark()`. Name fallback when `userName` is empty: `Welcome back!` (the mock's sub line "Semester 4 · Spring 2026" has no data source → static `CGPA & GPA tracker`).

### Complete code (whole file)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_data.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/ui.dart';
import 'home_page.dart';
import 'gpa_page.dart';
import 'cgpa_page.dart';
import 'storage_page.dart';
import 'settings_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);

    final pages = [
      HomePage(onSwitchTab: _switchTab),
      const GpaPage(),
      const CgpaPage(),
      StoragePage(onGoToGpa: () => _switchTab(1)),
      const SettingsPage(),
    ];

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          _TopBar(index: _currentIndex),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: pages[_currentIndex],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int index;
  const _TopBar({required this.index});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final data = context.watch<AppData>();

    final themeIcon = data.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Row(
          children: [
            switch (index) {
              0 => ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: p.accentSoft,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.border),
                    ),
                    child: ClipOval(child: Image.asset(data.userAvatar, fit: BoxFit.cover)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.userName.trim().isEmpty
                              ? 'Welcome back!'
                              : 'Welcome back, ${data.userName.trim()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.fg),
                        ),
                        Text('CGPA & GPA tracker',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: p.muted)),
                      ],
                    ),
                  ),
                ],
              1 => ...[
                  Expanded(child: _TopTitle('GPA Calculator')),
                  GhostButton(label: 'Add subject', icon: Icons.add, onTap: data.addGpaSubject),
                ],
              2 => ...[
                  Expanded(child: _TopTitle('CGPA Tracker')),
                  GhostButton(label: 'Add semester', icon: Icons.add, onTap: data.addSemester),
                ],
              3 => const [Expanded(child: _TopTitle('Saved Data'))],
              _ => ...[
                  Expanded(child: _TopTitle('Settings')),
                  SquareIconButton(icon: themeIcon, onTap: data.toggleDark),
                ],
            },
            if (index == 0) ...[const SizedBox(width: 10), SquareIconButton(icon: themeIcon, onTap: data.toggleDark)],
          ],
        ),
      ),
    );
  }
}

class _TopTitle extends StatelessWidget {
  final String title;
  const _TopTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.fg));
  }
}
```

Note: `StoragePage` now requires `onGoToGpa` — Task 8 lands that parameter; **run Task 4 and Task 8 back-to-back** (analyze stays green only once both are in; if split, temporarily make the param optional `this.onGoToGpa` and complete it in Task 8).

### Verify / Commit
`flutter analyze`; commit `feat: per-tab top bar in main shell`.

---

## Task 5 — Home page

**File:** `lib/screens/home_page.dart` (full rewrite)

Structure (padding `EdgeInsets.fromLTRB(16, 4, 16, 95)`, keep `StaggeredAnimation` wrappers index 0..5 as today):

1. **Hero (inverse card)** — `Container` width ∞, `color: p.invBg`, radius 8, **no shadow**, padding 18, column start:
   - eyebrow `YOUR CGPA` — 10 w700, letterSpacing 0.18, `p.invEyebrow`
   - value row (baseline): value = `cgpa?.toStringAsFixed(2) ?? '—'` — 40 w800 tabular `p.invFg`; suffix `/4.00` — 13 w600 `p.invFg` @0.55 alpha
   - sub — 12 w500 `p.invFg` @0.7: cgpa != null
     ? `'Across ${data.semesterCount} semesters · ${data.totalCredits} credit hours earned'`
     : `'Add semester GPAs to see your CGPA'`
   - gap 14 → inline `PrimaryButton`-style accent button (bg `p.accent`, height 40, radius 8, padding h14, white 13 w700): `'Add grades'` + `Icons.arrow_forward` 14 → `onSwitchTab(1)`
   (character.png, wave painter, decorative circles are removed)
2. `SectionHeader('Your record')`
3. **Stats grid** — `GridView.count(crossAxisCount: 2, shrinkWrap, NeverScrollable, main/crossAxisSpacing 10, childAspectRatio 1.5)` of `StatTile`:
   - `AVG GPA` → cgpa 2dp or `—`; `SEMESTERS` → `data.semesterCount`; `SUBJECTS` → `data.subjectCount`; `CREDITS` → `data.totalCredits`
   (SVG/wave/pastel styling removed — mock uses plain bordered tiles)
4. **Motivation** — `UiCard` row: 32×32 tile (`accentSoft`, radius 8) with `Icons.edit_outlined` 17 `accentInk`, gap 12, text `GpaService.getMotivationMessage(cgpa)` verbatim — 12.5 w600 `p.fg`
5. `SectionHeader('Quick actions')` (drop the old non-functional "View all")
6. **Quick actions** — `GridView.count(2 cols, spacing 10, ratio 1.3)` of cards: `UiCard` tap → `onSwitchTab(n)`, column start:
   - 34×34 tile `accentSoft` radius 8 containing the existing SVG (`book.svg`, `graduation.svg`, `folder.svg`, `setting.svg`) 20px with `ColorFilter.mode(p.accentInk, srcIn)`
   - gap 10 title 13 w700 `p.fg`; gap 2 subtitle 11 w500 `p.muted`
   - rows: (`GPA calculator`, `${data.subjectCount} subjects`, tab 1), (`CGPA tracker`, `${data.semesterCount} semesters`, tab 2), (`Saved data`, `On device`, tab 3), (`Settings`, `Theme & data`, tab 4)

**Preserve:** `onSwitchTab` param, all four data-derived values, `getMotivationMessage(cgpa)`, tab targets 1/2/3/4.

### Verify / Commit
`flutter analyze`; commit `style: redesign home screen`.

---

## Task 6 — GPA page

**File:** `lib/screens/gpa_page.dart` (full rewrite)

**Delete:** `_PageHeader` and `_AddButton` (moved into the shell top bar, Task 4).

Structure (padding `EdgeInsets.fromLTRB(16, 4, 16, 95)`, `StaggeredAnimation` indices shift: subject i → `i + 0`, result → `length`):

For each subject, `_SubjectCard` = `UiCard` (padding 14, margin bottom 10):

1. Row: `IdxBadge('${index + 1}')`, gap 10, **name `TextField`** (borderless, 14 w700 `p.fg`, `isDense`, same `onChanged` building a new `GpaSubject` with id/name/marks/credits/isLab copied), gap 10, delete `InkWell` 30×30 `Icons.close` 16 — color `p.muted` when `canDelete`, `p.muted` @0.15 when not (guard `canDelete ? onDelete : null`)
2. gap 12 → `FieldLabel('Marks (out of ${isLab ? 50 : 100})')` (lab label colored `p.accent` instead of muted)
3. marks `TextField` — `keyboardType: TextInputType.numberWithOptions(decimal: true)`, **formatter `RegExp(r'^\d{0,3}\.?\d{0,1}$')` verbatim**, `decoration: fieldInput(context, hint: isLab ? '0 – 50' : '0 – 100', error: validation != null)`, style `numStyle(15, FontWeight.w700, p.fg)`, same `onChanged` rebuilding `GpaSubject`
4. if `GpaService.validateMarks(...) != null` → `InputError(message: <verbatim message>)` (replaces `errorText`; red → accent per mock)
5. **credits (non-lab only):** `FieldLabel('Credit hours')`, gap 8, row of five 40×40 chips gap 8, radius 8: active → bg `p.accent`, text white 14 w800; inactive → bg `p.field`, border `p.border`, text `p.muted` 14 w700; tap sets `credits` (same `GpaSubject` rebuild)
   **lab only:** `Container` (bg `p.accentSoft`, radius 8, padding 12) with text `Credit Hours: 1 (Lab)` 12 w700 `p.accentInk`
6. gap 12 → **Lab switch row** (min height 44, `UiCard`-less row on `p.field` bg radius 8 padding h14 v10): label `Lab Subject` 12.5 w600 `p.fg` + `Spacer` + On/Off text (`isLab ? 'On' : 'Off'`, 11.5 w600 `p.muted`) + gap 10 + `AppSwitch(value: isLab, onChanged:)` toggling `isLab` and resetting `credits: newLab ? 1 : credits` exactly as today
7. gap 12 → **footer row**: left meta 11 w600 `p.muted` — grade != null ? (isLab ? `'Lab · weight 1'` : `'Non-lab · weight $cr'`) : `'Fix marks to grade'`; right: grade != null ? `GradeChip(letter, gpa)` : text `'— pending'` 12 w600 `p.muted`

**Result panel** (after the list, when `gpaResult != null`): `ResultCard(eyebrow: 'Semester GPA', value: gpaResult.toStringAsFixed(2), progress: gpaResult / 4, message: GpaService.getGpaMessage(gpaResult))`.

**Preserve verbatim:** the GPA computation loop (`totalPts`/`totalCr`, lab `marks * 2` effective marks, `cr = isLab ? 1 : credits`), controller init/`didUpdateWidget` sync, `GpaService.getGradeFromMarks`, all validation messages via `validateMarks`, formatter regex.

### Verify / Commit
`flutter analyze`; commit `style: redesign GPA screen`.

---

## Task 7 — CGPA page

**File:** `lib/screens/cgpa_page.dart` (full rewrite)

**Delete:** `_PageHeader`, `_AddButton`.

Structure (same padding/stagger scheme as Task 6). Each `_SemesterCard` = `UiCard` (padding 14, margin bottom 10):

1. Row: `IdxBadge('${index + 1}')`, gap 10, name `TextField` (same `onChanged` semantics), gap 10, delete button (same enabled/disabled pattern)
2. gap 12 → **GPA input row**: `FieldLabel('Semester GPA')` (Flexible), gap 8, `TextField` width 84 (center-aligned text, `fieldInput`, formatter `RegExp(r'^\d{0,2}\.?\d{0,2}$')`, **auto-dot block kept verbatim** (`v.length == 2 && !v.contains('.')` → `v[0].v.substring(1)` with `_isFormatting` guard)), gap 6, suffix text `'/ 4.00'` 12 w600 `p.muted`
3. error → `InputError(GpaService.validateGpaInput(...) verbatim)`
4. helper `'Maximum GPA is 4.00'` 10.5 w500 `p.muted`, gap 8
5. when `valid`: row: `Text('Status', 11 w700 uppercase-ish letterSpacing muted)` + `Spacer` + `StatusPill(status: GpaService.getSemesterStatus(gpa), up: gpa >= 3.5)`

**Result panel:** `ResultCard(eyebrow: 'Cumulative CGPA', value: cgpa.toStringAsFixed(2), progress: cgpa / 4, message: 'Mean of ${data.semesterCount} saved semesters')` when `cgpa != null`.

**Preserve verbatim:** `double.tryParse` + 0..4 validity check, controller sync with `_isFormatting`, `removeSemester` cascade naming (lives in provider — untouched).

### Verify / Commit
`flutter analyze`; commit `style: redesign CGPA screen`.

---

## Task 8 — Storage (Data) page

**File:** `lib/screens/storage_page.dart` (full rewrite)

**New ctor:** `const StoragePage({super.key, this.onGoToGpa}); final VoidCallback? onGoToGpa;` (wired in Task 4).

**Delete:** `_PageHeader`, `_colors`, `_bgGrads` (pastel/gradient styling removed).

Structure (same padding; `StaggeredAnimation` kept):

1. If `hasData`: top row (right-aligned) `GhostButton(label: 'Clear All', icon: Icons.delete_outline, danger: true)` → `_showClearDialog(context, data)` (dialog **logic verbatim**: title `'Clear all saved data?'`, content `'This will clear all marks and GPA entries.'`, Cancel/Clear; restyle: `AlertDialog` auto-uses new radius-8 `dialogTheme`, Clear text style `color: p.danger` w700). `hasData` computed exactly as today (`marks.isNotEmpty` / `gpa.isNotEmpty` filters).
2. If `!hasData`: `EmptyState(icon: Icons.folder_outlined, title: 'No saved data yet', body: 'Start calculating to see results here!', buttonLabel: 'Add your first subject', onButton: onGoToGpa)`.
3. Else sections:
   - `SectionHeader('GPA records')` → for each GPA record: card row (`UiCard` padding 12, margin bottom 8):
     - leading 40×40 tile `accentSoft` radius 8, text `grade.letter` 14 w800 `accentInk`
     - gap 12, Expanded: name 13.5 w700 `p.fg`; meta 11 w500 `p.muted` — `'Marks: ${c.marks}/${c.isLab ? 50 : 100} · $cr cr'`
     - trailing value `grade.gpa.toStringAsFixed(1)` via `numStyle(15, w800, p.fg)` (neutral, not grade-colored)
     - computation verbatim: `effectiveMarks = isLab ? marks*2 : marks`, `cr = isLab ? 1 : credits`, skip when `grade == null`
   - `SectionHeader('CGPA records')` → rows: tile text `'S${i + 1}'`, name `s.name`, meta `'GPA entered'`, value `double.parse(s.gpa).toStringAsFixed(2)`
   - Drop the `🔬` emoji from names (lab status already shown by `/50` in meta).

### Verify / Commit
`flutter analyze`; commit `style: redesign storage screen`.

---

## Task 9 — Settings, Grade Reference, About

**File:** `lib/screens/settings_page.dart` (full rewrite; single file kept)

**Delete:** `_PageHeader` (already unused → also clears baseline warning), `_SettingsGroup` (unused), `_DarkToggle` gradient switch (replaced by `AppSwitch`).

Content (padding `EdgeInsets.fromLTRB(16, 4, 16, 95)`, `StaggeredAnimation` 0..n kept):

1. **Profile card** (`UiCard` padding 16): row — avatar `GestureDetector` 56×56 (circle, bg `accentSoft`, border 1 `p.border`, `ClipOval` + `Image.asset(data.userAvatar)`) → `_showAvatarPicker`; gap 14; Expanded column: name (`userName.isEmpty ? 'Student' : userName`) 16 w800 `p.fg`, tap → `_showNameEditor`; sub `'Tap the name to rename · max 20 characters'` 11 w500 `p.muted`; trailing `SquareIconButton(icon: Icons.edit_outlined, size: 40, onTap: _showNameEditor)`.
   Both pickers/dialogs keep their logic verbatim (avatar grid `AppData.avatars`, `setUserAvatar`; name dialog `maxLength: 20`, trim, ignore empty, `setUserName`) with restyle only: bottom sheet radius 8 top corners? (sheet keeps a small 24 top radius for gesture affordance — exception documented), selected avatar = border 2 `p.accent` + bg `p.accentSoft`; name dialog uses `fieldInput` + radius-8 theme `dialogTheme`.
2. `SectionHeader('Appearance')` → single-row `UiCard` (padding 0) with `SettingsRow(icon: Icons.dark_mode_outlined, label: 'Dark mode', desc: 'Toggle light/dark theme', trailing: Row[_OnOffText, gap 10, AppSwitch(value: isDark, onChanged: (v) => data.toggleDark())], onTap: () => data.toggleDark())` — keep both hit targets (row + switch) like today.
3. `SectionHeader('Data')` → one `UiCard` (padding 0) containing two `SettingsRow`s separated by `Divider(color: p.border)`:
   - `Icons.grade_outlined`, `'Grade Reference'`, `'Marks → GPA conversion table'` → `_openGradeReference`
   - `Icons.delete_outline`, `'Reset All Data'`, `'Clear everything permanently'` → `_showResetDialog` (verbatim strings; Reset action color `p.danger`)
4. `SectionHeader('About')` → one `UiCard` (padding 0):
   - `Icons.info_outline`, `'About'`, `'Developer info & version'` → `_openAbout`
   - `Icons.sd_card_outlined`, `'Storage'`, `'Local (SharedPreferences)'` as **desc**, trailing static text `'Local'`? → use desc `'Where your data lives'` + trailing `'Local'` 12 w500 muted, `onTap: null` (static row, non-tappable — matches mock's non-interactive row)

**Grade Reference page** (`_GradeReferencePage`): `Scaffold(bg: p.bg)` + `AppBar` (transparent, `centerTitle: true`, leading = 40×40 `SquareIconButton(Icons.arrow_back_ios_new)` → `Navigator.pop`, title 16 w800 `p.fg`). Body padding `fromLTRB(16, 0, 16, 30)`:
- `SectionHeader('Marks → GPA')`
- `UiCard(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4))`: header row (`Marks`/`Grade`/`GPA` 11 w700 uppercase muted, columns 60 / 50 / spacer) then one row per `GpaService.gradeMap` entry with bottom `Divider`: `'${g.minMarks}+'` 13.5 w700 `p.fg` tabular; letter pill — bg `Color(g.colorValue)`, radius 8, padding v4, width 50, centered text white 12 w800; `'${g.gpa.toStringAsFixed(1)}'` 13.5 w700 `p.fg` tabular (fix baseline `unnecessary_string_interpolations`/`prefer_interpolation` lints while here)
- Lab note: `UiCard` (bg `p.accentSoft`, border `p.accent` @0.35, padding 14) row: `Icons.science_outlined` 18 `p.accentInk`, gap 12, column: `'Lab Subject'` 13 w700 `p.fg` / `'Marks out of 50, credits fixed at 1'` 11.5 w500 `p.muted`

**About page** (`_AboutPage`): same `Scaffold`/`AppBar` pattern, title `'About'`. Body:
- logo tile 72×72 radius 8, bg `p.accentSoft`, border 1 `p.border`, `Image.asset('assets/logo2.png', width 44)`
- gap 12 `'MCKRU CGPA Calculator'` 16 w800 `p.fg`; gap 6 version pill (bg `p.accentSoft`, radius 8, padding h10 v4) `'v1.2.0'` 11.5 w700 `p.accentInk`
- `SectionHeader('Developer')` → `UiCard`: `developer_avatar.png` 48 circle + `'Jibran Khan Dehpal'` 14.5 w700 / `'Flutter Developer'` 11.5 w500 muted
- `SectionHeader('App info')` → `UiCard` with `_InfoRow` rows (restyled: label 12.5 w500 muted; value chip bg `p.field` border radius 8 text 11.5 w700 `p.fg`): Version `1.2.0`, Platform `Android & iOS`, Framework `Flutter`, Storage `Local (SharedPreferences)`
- `SectionHeader('Features')` → `UiCard` with `_FeatureItem`s (icon → Material icons in `p.accentInk` 16: `Icons.show_chart_outlined`, `Icons.science_outlined`, `Icons.save_outlined`, `Icons.dark_mode_outlined`, `Icons.person_outline`; text 13 w500 `p.fg`), same five strings verbatim

**Preserve verbatim:** dialog strings, navigation calls, `AppData.avatars`, name max length, all About copy.

### Verify / Commit
`flutter analyze`; commit `style: redesign settings, grade reference and about`.

---

## Task 10 — Splash screen

**File:** `lib/screens/splash_screen.dart` (full rewrite of build; keep the animation/timer logic)

**Keep verbatim:** `_controller` (1200 ms, scale `Interval(0.0, 0.6, elasticOut)`, opacity `Interval(0.0, 0.4)`), `Future.delayed(2500ms)` + `hasSeenOnboarding` → `MainShell` / `OnboardingScreen` `pushReplacement`, `mounted` guard, dispose.

**Replace visuals** (clouds/sparkles/wave/logo removed; also drops the two baseline `unused_import` warnings — remove `dart:math` and `app_theme` import if unneeded, keep `app_theme` only if `Palette` is used):

```dart
@override
Widget build(BuildContext context) {
  final p = Palette.of(context);
  return Scaffold(
    backgroundColor: p.bg,
    body: Stack(
      children: [
        Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Opacity(
              opacity: _opacityAnim.value,
              child: Transform.scale(scale: _scaleAnim.value, child: child),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(color: p.accentDeep, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.school_outlined, size: 34, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text('CGPA Calculator', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.fg)),
                const SizedBox(height: 6),
                Text('MCKRU · Version 1.2.0',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.muted, letterSpacing: 0.04)),
                const SizedBox(height: 26),
                SizedBox(
                  width: 150,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 0.64),
                    duration: const Duration(milliseconds: 1200),
                    curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                    builder: (context, value, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox(
                        height: 4,
                        child: Stack(
                          children: [
                            Container(height: 4, color: p.border),
                            FractionallySizedBox(
                              widthFactor: value,
                              child: Container(height: 4, color: p.accentDeep),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Loading your saved record…',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: p.muted)),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0, right: 0, bottom: 24,
          child: Text('Developed by Jibran Khan Dehpal',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: p.muted)),
        ),
      ],
    ),
  );
}
```

### Verify / Commit
`flutter analyze`; commit `style: minimal splash screen per design`.

---

## Task 11 — Onboarding screen

**File:** `lib/screens/onboarding_screen.dart` (visual rewrite; flow untouched — not mocked in HTML, restyled in the same language)

**Keep verbatim:** `_step`/`_next`/`_finish` logic (3 pages + name step, default `'Student'`, `finishOnboarding`, `pushReplacement(MainShell)`), `_nameController` maxLength 20, `AppData.avatars` grid selection, `_AnimatedFloat` (repeat), page titles/descs, button labels `'Next →'` / `"Let's Go 🚀"`.

**Restyle:**
- Page bg: `Palette.of(context).bg` (was hardcoded white) — `Scaffold(backgroundColor: p.bg)`, drop the inner `Container(color: Colors.white)`
- Step image: wrap in `UiCard` (padding 12, bg `p.surface`) containing `Image.asset(page.imagePath, width: 240, height: 240)`; remove the unused `bgColors` field from `_OnboardPage`
- Title 22 w800 `p.fg`; desc 13.5 w500 `p.muted` height 1.6
- Dots (4): active → width 24, height 6, radius 3, `p.accent`; inactive → 8×6 radius 3, `p.border`
- Next button: `PrimaryButton(expanded: true, label: ...)` (radius 8, no gradient/shadow)
- Name step: `FieldLabel('Your name')` + TextField via `fieldInput(context, hint: 'Enter your name…')`, centered text 16 w700
- Avatar grid tiles: 56px-ish cells (grid 4 cols, spacing 10), radius 8; selected → border 2 `p.accent` + bg `p.accentSoft`; unselected → border 1 `p.border` + bg `p.surface`
- `'Pick an avatar'` label → `FieldLabel`
- The `👋` step image container → `UiCard` circle-ish: keep 180px `Container` with bg `p.accentSoft`, radius 90 (round illustration exception), text `👋` 72 (emoji kept — decorative content, part of the flow's character)

### Verify / Commit
`flutter analyze`; commit `style: restyle onboarding to design language`.

---

## Task 12 — Cleanup, tests, final verification

**Files:** `lib/theme/app_theme.dart` (delete `AppColors`), `test/widget_test.dart` (replace), final `flutter analyze`.

### Steps
1. `grep -n "AppColors" lib` → rewrite any remaining reference to `Palette.of(context)` (should be none after Tasks 5–11); delete the `AppColors` class.
2. Replace `test/widget_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cgpa_calculator/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('splash renders, then routes to onboarding on first run', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('CGPA Calculator'), findsOneWidget);
    expect(find.text('MCKRU · Version 1.2.0'), findsOneWidget);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();

    expect(find.text('Track Your Grades'), findsOneWidget);
  });

  testWidgets('home tab shows hero and quick actions after onboarding', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'mckru_onboarded2': true,
      'mckru_name': 'Ali',
    });
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();

    expect(find.text('Welcome back, Ali'), findsOneWidget);
    expect(find.text('YOUR CGPA'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);

    // GPA tab via bottom nav, then the shell's Add subject button
    await tester.tap(find.text('GPA'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('GPA Calculator'), findsOneWidget);
    expect(find.text('Add subject'), findsOneWidget);
  });
}
```

Notes: **no `pumpAndSettle`** — onboarding's `_AnimatedFloat` repeats forever and StaggeredAnimation/Elastic curves make settle time out. Bounded pumps only. If `google_fonts` with `allowRuntimeFetching = false` still emits async font errors that fail the run, wrap the pumps with a `FlutterError.onError` filter for `GoogleFonts` messages or set `GoogleFonts.config.allowRuntimeFetching = true` (tests use a mocked HTTP client that returns 400, google_fonts then falls back to the default font without failing the test).

3. Final gates (must pass before declaring done):
   - `flutter analyze` → **0 issues** (baseline was 83; the rewrite removes all `withOpacity` infos and every warning)
   - `flutter test` → all green
   - Manual spot check if a device/emulator is available: `flutter run` → light + dark, all 5 tabs, add/remove subject, add/remove semester, clear all, reset all, onboarding on a fresh install.

### Commit
`chore: remove legacy palette, add smoke tests, fix analyzer issues`

---

## Execution notes

- **Task order is dependency-safe:** 1 → 2 → (3, 4+8 paired) → 5 → 6 → 7 → 9 → 10 → 11 → 12. Tasks 5–7, 9–11 are independent of each other (parallelizable via subagents after 1–4 land).
- **Commits:** plan assumes one commit per task; per project default we only commit when the user asks — confirm before running any `git commit`.
- **Design fidelity choices where the mock had no data:** hero sub-line, quick-action subtitles, storage meta text, status-pill left label, non-mocked screens (Storage detail, Onboarding, Grade Reference, About) — all specified above; no functional changes anywhere.
- **Out of scope:** `AppData`, `GpaService`, `main.dart`, `staggered_animation.dart`, assets, platform config.
