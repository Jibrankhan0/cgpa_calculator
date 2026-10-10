# Light Mode Redesign — Warm & Creamy Neumorphic

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the CGPA Calculator's light mode from flat gray to warm, premium, Apple-like creamy neumorphic experience.

**Architecture:** Update color tokens in `app_theme.dart`, modify `GlassCard` to render neumorphic in light mode, and update all widget color references to use warm cream palette. Dark mode remains untouched.

**Tech Stack:** Flutter, Dart, Material 3, Google Fonts

## Global Constraints

- Dark mode must remain completely unchanged
- All existing functionality must work identically
- Indigo accent color (`#6366F1`) stays as primary accent
- Border radius conventions: 20px cards, 14px buttons, 12px inputs
- Google Fonts: Lexend for headings, Inter for body text

---

## Task 1: Update Light Theme Color Tokens

**Files:**
- Modify: `lib/theme/app_theme.dart:15-23` (light color constants)
- Modify: `lib/theme/app_theme.dart:108-155` (lightTheme ThemeData)

**Interfaces:**
- Consumes: None
- Produces: Updated `AppTheme.lightBgPrimary`, `lightBgGradientStart`, `lightBgGradientEnd`, `lightSurfaceGlass`, `lightBorderGlass`, `lightTextPrimary`, `lightTextSecondary`, `lightTextMuted` — all used by every widget in light mode

- [ ] **Step 1: Update light color constants**

Replace lines 15-23 in `lib/theme/app_theme.dart`:

```dart
// ========== LIGHT THEME COLORS ==========
static const Color lightBgPrimary = Color(0xFFFBF7F2);
static const Color lightBgGradientStart = Color(0xFFFFF8F0);
static const Color lightBgGradientEnd = Color(0xFFF5EDE4);
static const Color lightSurfaceGlass = Color(0xFFFDF8F3);
static const Color lightBorderGlass = Color(0xFFE8DDD2);
static const Color lightTextPrimary = Color(0xFF3D2E22);
static const Color lightTextSecondary = Color(0xFF6B5B4E);
static const Color lightTextMuted = Color(0xFFA89880);
```

- [ ] **Step 2: Add neumorphic shadow constants**

Add after line 23 (after `lightTextMuted`), before the SHARED COLORS section:

```dart
// ========== LIGHT MODE NEUMORPHIC SHADOWS ==========
static const Color lightShadowDark = Color(0xD4C4B0); // warm brown
static const Color lightShadowLight = Color(0xCCFFFA); // warm white
```

Wait — these need to be full Color values. Fix:

```dart
// ========== LIGHT MODE NEUMORPHIC SHADOWS ==========
static const Color lightShadowDark = Color(0xFFD4C4B0);
static const Color lightShadowLight = Color(0xFFFFFAF5);
```

- [ ] **Step 3: Update lightTheme scaffold background**

Replace line 112 in `lib/theme/app_theme.dart`:

```dart
scaffoldBackgroundColor: lightBgPrimary,
```

(This stays the same — just verifying it uses the new value)

- [ ] **Step 4: Update lightTheme colorScheme surface**

Replace line 116:

```dart
surface: lightBgPrimary,
```

(Also stays the same — verifies correctly)

- [ ] **Step 5: Verify lightTheme text colors**

Lines 119-154 should use `lightTextPrimary`, `lightTextSecondary`, `lightTextMuted` — these are already correct from the constant rename.

- [ ] **Step 6: Run app to verify no compile errors**

Run: `flutter run`
Expected: App builds and runs. Light mode now shows warm cream background with brown text.

- [ ] **Step 7: Commit**

```bash
git add lib/theme/app_theme.dart
git commit -m "feat: update light theme to warm cream color palette"
```

---

## Task 2: Update GlassCard for Neumorphic Light Mode

**Files:**
- Modify: `lib/widgets/glass_card.dart:29-77` (build method)

**Interfaces:**
- Consumes: `AppTheme.lightSurfaceGlass`, `AppTheme.lightShadowDark`, `AppTheme.lightShadowLight`, `AppTheme.lightBorderGlass` (from Task 1)
- Produces: `GlassCard` widget that renders neumorphic in light mode, glass in dark mode — used by HeroGpaCard, SemesterCard, CourseInputCard

- [ ] **Step 1: Replace GlassCard build method**

Replace the entire `build` method in `lib/widgets/glass_card.dart`:

```dart
@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final radius = borderRadius ?? BorderRadius.circular(16);

  if (isDark) {
    // Dark mode: Glass morphism (unchanged)
    final bgColor = (color ?? Colors.white).withValues(alpha: opacity);
    final border = borderColor ?? const Color(0x14FFFFFF);

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        border: Border.all(color: border, width: 1),
        boxShadow: [
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          const BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );

    if (useBlur) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    return content;
  } else {
    // Light mode: Neumorphic
    final surfaceColor = color ?? const Color(0xFFFDF8F3);
    final shadowDarkColor = borderColor ?? const Color(0xD4C4B0);
    final shadowLightColor = const Color(0xFFFFFAF5);

    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: radius,
        boxShadow: [
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          BoxShadow(
            color: shadowDarkColor.withValues(alpha: 0.25),
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: shadowLightColor.withValues(alpha: 0.8),
            offset: const Offset(-4, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: child,
    );
  }
}
```

- [ ] **Step 2: Run app to verify neumorphic cards appear in light mode**

Run: `flutter run`
Expected: Switch to light mode — cards now show soft warm neumorphic shadows instead of invisible glass.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/glass_card.dart
git commit -m "feat: add neumorphic rendering for light mode in GlassCard"
```

---

## Task 3: Update Mesh Gradient Background

**Files:**
- Modify: `lib/widgets/mesh_gradient_background.dart:11-28` (build method)

**Interfaces:**
- Consumes: `AppTheme.lightBgGradientStart`, `AppTheme.lightBgGradientEnd` (from Task 1)
- Produces: Updated background gradient for light mode — used by HomeScreen

- [ ] **Step 1: Update light mode gradient colors**

The gradient already uses `AppTheme.lightBgGradientStart` and `AppTheme.lightBgGradientEnd` which are now updated to warm colors. No code change needed — just verify.

Read `lib/widgets/mesh_gradient_background.dart` lines 20-22:

```dart
colors: isDark
    ? [AppTheme.darkBgGradientStart, AppTheme.darkBgPrimary]
    : [AppTheme.lightBgGradientStart, AppTheme.lightBgGradientEnd],
```

This already references the updated constants. No change needed.

- [ ] **Step 2: Run app to verify warm gradient background**

Run: `flutter run`
Expected: Light mode background shows warm peach-to-cream gradient.

- [ ] **Step 3: Commit**

(No commit needed — no code change)

---

## Task 4: Update Mini Stat Card

**Files:**
- Modify: `lib/widgets/mini_stat_card.dart:30-59` (build method)

**Interfaces:**
- Consumes: `AppTheme.lightTextMuted`, `AppTheme.lightTextPrimary` (from Task 1)
- Produces: Updated MiniStatCard with warm surface colors

- [ ] **Step 1: Update MiniStatCard surface colors**

Replace lines 32-39 in `lib/widgets/mini_stat_card.dart`:

```dart
return Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(
    color: isDark ? const Color(0x0AFFFFFF) : const Color(0xFFFDF8F3),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: isDark ? const Color(0x14FFFFFF) : const Color(0xFFE8DDD2),
    ),
  ),
```

- [ ] **Step 2: Run app to verify mini stat cards look correct**

Run: `flutter run`
Expected: Mini stat cards show warm ivory surface with warm border.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/mini_stat_card.dart
git commit -m "feat: update MiniStatCard to warm cream surface"
```

---

## Task 5: Update Mode Selector

**Files:**
- Modify: `lib/widgets/mode_selector.dart:26-41` (build method)

**Interfaces:**
- Consumes: `AppTheme.lightTextMuted`, `AppTheme.accentPrimary` (from Task 1)
- Produces: Updated ModeSelector with warm container colors

- [ ] **Step 1: Update ModeSelector container colors**

Replace lines 28-33 in `lib/widgets/mode_selector.dart`:

```dart
return Container(
  padding: const EdgeInsets.all(4),
  decoration: BoxDecoration(
    color: isDark ? const Color(0x0DFFFFFF) : const Color(0x0D000000),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: isDark ? const Color(0x14FFFFFF) : const Color(0x1A000000),
    ),
  ),
```

Note: The unselected tab text color (line 79) already references `AppTheme.lightTextMuted` which is now warm. Verify:

```dart
color: isSelected
    ? Colors.white
    : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
```

This is correct. No change needed for text color.

- [ ] **Step 2: Run app to verify mode selector looks correct**

Run: `flutter run`
Expected: Mode selector shows warm container with proper contrast.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/mode_selector.dart
git commit -m "feat: update ModeSelector to warm container colors"
```

---

## Task 6: Update Semester Card Fields

**Files:**
- Modify: `lib/widgets/semester_card.dart:113-121` (fieldBg and fieldBorder functions)

**Interfaces:**
- Consumes: `AppTheme.textMuted`, `AppTheme.textPrimary`, `AppTheme.accentPrimary` (from Task 1)
- Produces: Updated SemesterCard input fields with warm colors

- [ ] **Step 1: Update field background and border colors**

Replace lines 113-121 in `lib/widgets/semester_card.dart`:

```dart
Color fieldBg(bool focused) {
  if (isDark) return focused ? const Color(0x1A6366F1) : const Color(0x0DFFFFFF);
  return focused ? const Color(0x0D6366F1) : const Color(0x08000000);
}

Color fieldBorder(bool focused) {
  if (isDark) return focused ? const Color(0x4D6366F1) : const Color(0x14FFFFFF);
  return focused ? const Color(0x4D6366F1) : const Color(0x1A000000);
}
```

Note: These already handle light mode with appropriate colors. The `0x08000000` (black 3%) and `0x1A000000` (black 10%) work well on warm cream backgrounds. No change needed.

- [ ] **Step 2: Run app to verify semester card fields look correct**

Run: `flutter run`
Expected: Semester card input fields show proper contrast on warm background.

- [ ] **Step 3: Commit**

(No commit needed — no code change)

---

## Task 7: Update Course Input Card Fields

**Files:**
- Modify: `lib/widgets/course_input_card.dart:204-216` (fieldBg and fieldBorder functions)
- Modify: `lib/widgets/course_input_card.dart:239-241` (borderColor)

**Interfaces:**
- Consumes: `AppTheme.textMuted`, `AppTheme.textPrimary`, `AppTheme.accentPrimary` (from Task 1)
- Produces: Updated CourseInputCard with warm field colors

- [ ] **Step 1: Update field background and border colors**

Replace lines 204-216 in `lib/widgets/course_input_card.dart`:

```dart
Color _fieldBg(bool isDark, bool focused) {
  if (isDark) {
    return focused ? const Color(0x1A6366F1) : const Color(0x0DFFFFFF);
  }
  return focused ? const Color(0x0D6366F1) : const Color(0x08000000);
}

Color _fieldBorder(bool isDark, bool focused) {
  if (isDark) {
    return focused ? const Color(0x4D6366F1) : const Color(0x14FFFFFF);
  }
  return focused ? const Color(0x4D6366F1) : const Color(0x1A000000);
}
```

No change needed — these already handle light mode correctly.

- [ ] **Step 2: Update course card border color**

Replace lines 239-241 in `lib/widgets/course_input_card.dart`:

```dart
borderColor: isLab
    ? const Color(0x336366F1)
    : (isDark ? const Color(0x1AFFFFFF) : const Color(0x1A000000)),
```

This already handles light mode. No change needed.

- [ ] **Step 3: Run app to verify course input card looks correct**

Run: `flutter run`
Expected: Course input card shows warm fields with proper contrast.

- [ ] **Step 4: Commit**

(No commit needed — no code change)

---

## Task 8: Update Empty State

**Files:**
- Modify: `lib/widgets/empty_state.dart:36-50` (build method)

**Interfaces:**
- Consumes: `AppTheme.textSecondary`, `AppTheme.textMuted`, `AppTheme.accentPrimary` (from Task 1)
- Produces: Updated EmptyState with warm circle container

- [ ] **Step 1: Update empty state circle container**

Replace lines 36-50 in `lib/widgets/empty_state.dart`:

```dart
Container(
  width: 72,
  height: 72,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: const Color(0x0D6366F1),
    border: Border.all(
      color: isDark ? const Color(0x1A6366F1) : const Color(0x1A6366F1),
    ),
  ),
  child: Icon(
    icon,
    size: 32,
    color: AppTheme.accentPrimary.withAlpha(180),
  ),
),
```

This already works on warm background. The `0x0D6366F1` (indigo 5%) looks good on cream. No change needed.

- [ ] **Step 2: Run app to verify empty state looks correct**

Run: `flutter run`
Expected: Empty state circle shows warm indigo tint on cream background.

- [ ] **Step 3: Commit**

(No commit needed — no code change)

---

## Task 9: Update Circular Progress Ring Track

**Files:**
- Modify: `lib/widgets/circular_progress_ring.dart:72-75` (build method)

**Interfaces:**
- Consumes: None (uses local isDark check)
- Produces: Updated CircularProgressRing with warm track color in light mode

- [ ] **Step 1: Update track color for light mode**

Replace lines 72-75 in `lib/widgets/circular_progress_ring.dart`:

```dart
@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final track = widget.trackColor ??
      (isDark ? const Color(0x1AFFFFFF) : const Color(0x14D4C4B0));
```

Change `0x14000000` to `0x14D4C4B0` for warm brown track.

Wait — the current code uses `0x14000000` (black 8%). Let me update to warm brown:

```dart
final track = widget.trackColor ??
    (isDark ? const Color(0x1AFFFFFF) : const Color(0x26D4C4B0));
```

Using `0x26D4C4B0` (warm brown at 15%) for better visibility.

- [ ] **Step 2: Run app to verify progress ring track looks correct**

Run: `flutter run`
Expected: GPA ring shows warm brown track in light mode.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/circular_progress_ring.dart
git commit -m "feat: update CircularProgressRing track to warm brown"
```

---

## Task 10: Update Gradient Button Shadow

**Files:**
- Modify: `lib/widgets/gradient_button.dart:30-35` (boxShadow)

**Interfaces:**
- Consumes: `AppTheme.accentPrimary`, `AppTheme.accentSecondary` (unchanged)
- Produces: Updated GradientButton with warmer shadow

- [ ] **Step 1: Update button shadow color**

Replace lines 30-35 in `lib/widgets/gradient_button.dart`:

```dart
boxShadow: const [
  BoxShadow(
    color: Color(0x4D6366F1),
    blurRadius: 16,
    offset: Offset(0, 6),
  ),
],
```

Change `0x4D6366F1` (indigo 30%) — this already looks warm on cream. No change needed.

- [ ] **Step 2: Run app to verify button shadow looks correct**

Run: `flutter run`
Expected: Button shadow looks warm and premium on cream background.

- [ ] **Step 3: Commit**

(No commit needed — no code change)

---

## Task 11: Update Splash Screen

**Files:**
- Modify: `lib/screens/splash_screen.dart:91-98` (gradient)

**Interfaces:**
- Consumes: `AppTheme.lightBgGradientStart`, `AppTheme.lightBgGradientEnd` (from Task 1)
- Produces: Updated SplashScreen with warm gradient in light mode

- [ ] **Step 1: Verify splash screen uses updated gradient**

Read lines 91-98 in `lib/screens/splash_screen.dart`:

```dart
gradient: LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: isDark
      ? [AppTheme.darkBgGradientStart, AppTheme.darkBgPrimary]
      : [AppTheme.lightBgGradientStart, AppTheme.lightBgGradientEnd],
),
```

This already references the updated constants. No change needed.

- [ ] **Step 2: Run app to verify splash screen shows warm gradient**

Run: `flutter run`
Expected: Splash screen shows warm peach-to-cream gradient in light mode.

- [ ] **Step 3: Commit**

(No commit needed — no code change)

---

## Task 12: Full Verification

**Files:**
- None (verification only)

**Interfaces:**
- Consumes: All previous tasks
- Produces: Verified working light mode

- [ ] **Step 1: Run full app in light mode**

Run: `flutter run`
Test all screens:
- Splash screen: warm gradient ✓
- Home screen: warm background, neumorphic cards ✓
- Hero GPA card: neumorphic with warm track ✓
- Mode selector: warm container ✓
- Course input cards: warm fields ✓
- Semester cards: warm fields ✓
- Mini stat cards: warm surface ✓
- Empty state: warm circle ✓
- Add course button: warm shadow ✓
- Theme toggle: works correctly ✓
- Dark mode: completely unchanged ✓

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze`
Expected: No errors, no warnings

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "feat: complete light mode warm neumorphic redesign"
```
