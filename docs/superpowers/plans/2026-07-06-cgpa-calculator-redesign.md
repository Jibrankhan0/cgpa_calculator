# CGPA Calculator Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the CGPA Calculator app with dark premium UI, card-based marks entry, animated splash screen, and polished micro-interactions.

**Architecture:** Keep existing 2-screen structure (Home + Marks Sheet) and Riverpod state management. Replace UI layer entirely: new theme system, new widgets, card-based input replacing table, animated splash screen. No changes to models or providers.

**Tech Stack:** Flutter, Riverpod, Google Fonts, flutter_animate, SharedPreferences, uuid

## Global Constraints

- Flutter SDK ^3.8.1
- Existing packages only: flutter_animate, flutter_riverpod, google_fonts, shared_preferences, uuid
- No new dependencies required
- University-specific (MCKRU) - no universal grading system needed
- Existing models (Course, Semester, SemesterResult) unchanged
- Existing providers (semesterProvider, cgpaProvider, marksSheetProvider) unchanged
- Color palette: Primary #6366F1, Secondary #A855F7, Background #0A0E1A
- Fonts: Lexend (headings/numbers), Inter (body)

---

## Phase 1: Foundation (Theme + Base Widgets)

### Task 1: Rewrite App Theme

**Files:**
- Modify: `lib/theme/app_theme.dart`

**Interfaces:**
- Consumes: nothing
- Produces: `AppTheme` class with all color constants and `darkTheme` ThemeData

- [ ] **Step 1: Replace entire app_theme.dart with dark premium theme**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Background
  static const Color bgPrimary = Color(0xFF0A0E1A);
  static const Color bgGradientStart = Color(0xFF0F172A);

  // Surface
  static const Color surfaceGlass = Color(0x0FFFFFFF); // white 6%
  static const Color borderGlass = Color(0x1AFFFFFF); // white 10%

  // Accents
  static const Color accentPrimary = Color(0xFF6366F1);
  static const Color accentSecondary = Color(0xFFA855F7);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);

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
```

- [ ] **Step 2: Update main.dart to use new theme**

```dart
// lib/main.dart - replace theme line
theme: AppTheme.darkTheme,
```

- [ ] **Step 3: Run app to verify theme applies**

Run: `flutter run`
Expected: App loads with dark background (#0A0E1A)

---

### Task 2: Update MeshGradientBackground

**Files:**
- Modify: `lib/widgets/mesh_gradient_background.dart`

**Interfaces:**
- Consumes: AppTheme colors
- Produces: Updated `MeshGradientBackground` widget with dark premium gradient

- [ ] **Step 1: Replace mesh_gradient_background.dart**

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MeshGradientBackground extends StatelessWidget {
  final Widget child;

  const MeshGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.bgGradientStart,
                  AppTheme.bgPrimary,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Indigo glow top-left
                Positioned(
                  top: -120,
                  left: -80,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.accentPrimary.withValues(alpha: 0.15),
                          AppTheme.accentPrimary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Purple glow bottom-right
                Positioned(
                  bottom: -150,
                  right: -100,
                  child: Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.accentSecondary.withValues(alpha: 0.1),
                          AppTheme.accentSecondary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Subtle center glow
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.3,
                  left: MediaQuery.of(context).size.width * 0.3,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.accentPrimary.withValues(alpha: 0.05),
                          AppTheme.accentPrimary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(child: child),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify background renders correctly**

Run: `flutter run`
Expected: Dark gradient background with subtle indigo/purple glow orbs

---

### Task 3: Update GlassCard

**Files:**
- Modify: `lib/widgets/glass_card.dart`

**Interfaces:**
- Consumes: AppTheme colors
- Produces: Updated `GlassCard` with dark glassmorphism

- [ ] **Step 1: Replace glass_card.dart**

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final bool useBlur;
  final Color? color;
  final Color? glowColor;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.06,
    this.padding,
    this.borderRadius,
    this.borderColor,
    this.useBlur = true,
    this.color,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(20);

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withValues(alpha: opacity),
        borderRadius: radius,
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (useBlur) {
      content = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      );
    }

    return ClipRRect(borderRadius: radius, child: content);
  }
}
```

- [ ] **Step 2: Verify glass cards render on dark background**

Run: `flutter run`
Expected: Cards show translucent glass effect on dark background

---

## Phase 2: New Widgets

### Task 4: Create CircularProgressRing Widget

**Files:**
- Create: `lib/widgets/circular_progress_ring.dart`

**Interfaces:**
- Consumes: double value (0.0-4.0), Color color
- Produces: Animated circular progress ring widget

- [ ] **Step 1: Create circular_progress_ring.dart**

```dart
import 'dart:math';
import 'package:flutter/material.dart';

class CircularProgressRing extends StatefulWidget {
  final double value;
  final double maxValue;
  final Color color;
  final double size;
  final double strokeWidth;

  const CircularProgressRing({
    super.key,
    required this.value,
    this.maxValue = 4.0,
    required this.color,
    this.size = 100,
    this.strokeWidth = 8,
  });

  @override
  State<CircularProgressRing> createState() => _CircularProgressRingState();
}

class _CircularProgressRingState extends State<CircularProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.value / widget.maxValue,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(CircularProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value / widget.maxValue,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: _animation.value,
              color: widget.color,
              strokeWidth: widget.strokeWidth,
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
```

- [ ] **Step 2: Verify ring renders and animates**

Add temporary usage in home_screen, verify animation on load.

---

### Task 5: Create GradeBadge Widget

**Files:**
- Create: `lib/widgets/grade_badge.dart`

**Interfaces:**
- Consumes: String grade
- Produces: Colored pill badge showing grade

- [ ] **Step 1: Create grade_badge.dart**

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradeBadge extends StatelessWidget {
  final String grade;

  const GradeBadge({super.key, required this.grade});

  Color _getGradeColor() {
    switch (grade) {
      case 'A':
      case 'A-':
        return AppTheme.success;
      case 'B+':
      case 'B':
      case 'B-':
        return const Color(0xFF3B82F6); // Blue
      case 'C+':
      case 'C':
        return AppTheme.warning;
      case 'C-':
      case 'D':
        return const Color(0xFFF97316); // Orange
      case 'F':
        return AppTheme.danger;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getGradeColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        grade,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
```

---

### Task 6: Create MiniStatCard Widget

**Files:**
- Create: `lib/widgets/mini_stat_card.dart`

**Interfaces:**
- Consumes: String label, String value, Color? valueColor
- Produces: Small stat display card

- [ ] **Step 1: Create mini_stat_card.dart**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const MiniStatCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.lexend(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### Task 7: Create GradientButton Widget

**Files:**
- Create: `lib/widgets/gradient_button.dart`

**Interfaces:**
- Consumes: VoidCallback onPressed, Widget child
- Produces: Gradient action button with glow

- [ ] **Step 1: Create gradient_button.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.accentPrimary, AppTheme.accentSecondary],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentPrimary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
```

---

### Task 8: Create EmptyState Widget

**Files:**
- Create: `lib/widgets/empty_state.dart`

**Interfaces:**
- Consumes: IconData icon, String title, String subtitle
- Produces: Centered empty state display

- [ ] **Step 1: Create empty_state.dart**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppTheme.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### Task 9: Create ModeSelector Widget

**Files:**
- Create: `lib/widgets/mode_selector.dart`

**Interfaces:**
- Consumes: CalculationMode currentMode, Function(CalculationMode) onChanged
- Produces: Animated pill toggle for GPA/CGPA mode

- [ ] **Step 1: Create mode_selector.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/semester_provider.dart';
import '../theme/app_theme.dart';

class ModeSelector extends StatelessWidget {
  final CalculationMode currentMode;
  final Function(CalculationMode) onChanged;

  const ModeSelector({
    super.key,
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _buildTab(CalculationMode.gpa, 'GPA (Single)'),
          _buildTab(CalculationMode.cgpa, 'CGPA (Multi)'),
        ],
      ),
    );
  }

  Widget _buildTab(CalculationMode mode, String label) {
    final isSelected = currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [AppTheme.accentPrimary, AppTheme.accentSecondary],
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.accentPrimary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## Phase 3: Hero CGPA Card

### Task 10: Create HeroGpaCard Widget

**Files:**
- Create: `lib/widgets/hero_gpa_card.dart`
- Modify: `lib/widgets/mini_stat_card.dart` (minor adjustments if needed)

**Interfaces:**
- Consumes: double gpa, String label, double totalCredits, int courseCount
- Produces: Full-width hero card with progress ring + number + stats

- [ ] **Step 1: Create hero_gpa_card.dart**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'circular_progress_ring.dart';
import 'glass_card.dart';
import 'mini_stat_card.dart';

class HeroGpaCard extends StatelessWidget {
  final double gpa;
  final String label;
  final double totalCredits;
  final int courseCount;

  const HeroGpaCard({
    super.key,
    required this.gpa,
    required this.label,
    required this.totalCredits,
    required this.courseCount,
  });

  @override
  Widget build(BuildContext context) {
    final gpaColor = AppTheme.getGpaColor(gpa);

    return GlassCard(
      glowColor: gpaColor,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Progress Ring
          CircularProgressRing(
            value: gpa,
            color: gpaColor,
            size: 90,
            strokeWidth: 7,
          ),
          const SizedBox(width: 20),
          // GPA Number
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  gpa.toStringAsFixed(2),
                  style: GoogleFonts.lexend(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: gpaColor,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          // Mini Stats
          Column(
            children: [
              MiniStatCard(
                label: 'Credits',
                value: totalCredits.toStringAsFixed(1),
              ),
              const SizedBox(height: 8),
              MiniStatCard(
                label: 'Courses',
                value: courseCount.toString(),
                valueColor: AppTheme.accentPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## Phase 4: Splash Screen

### Task 11: Create SplashScreen

**Files:**
- Create: `lib/screens/splash_screen.dart`
- Modify: `lib/main.dart` (set initial route)

**Interfaces:**
- Consumes: nothing
- Produces: Animated splash screen → navigates to HomeScreen

- [ ] **Step 1: Create splash_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _textSlide;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _textSlide = Tween<double>(begin: 10.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 1800));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.bgGradientStart, AppTheme.bgPrimary],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentPrimary.withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo2.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            // App Name
            AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return Opacity(
                  opacity: _textOpacity.value,
                  child: Transform.translate(
                    offset: Offset(0, _textSlide.value),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'GPA',
                              style: GoogleFonts.lexend(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'CALCULATOR',
                              style: GoogleFonts.lexend(
                                fontSize: 24,
                                fontWeight: FontWeight.w300,
                                color: AppTheme.textMuted,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'MCKRU University',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.accentPrimary,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Update main.dart to start with SplashScreen**

```dart
// lib/main.dart
home: const SplashScreen(),
```

- [ ] **Step 3: Verify splash animation sequence**

Run: `flutter run`
Expected: Logo scales in → App name fades in → Tagline appears → Navigates to home

---

## Phase 5: Home Screen Redesign

### Task 12: Rewrite HomeScreen

**Files:**
- Modify: `lib/screens/home_screen.dart`
- Delete: `lib/widgets/bento_card.dart` (replaced by HeroGpaCard)
- Delete: `lib/widgets/neomorphic_button.dart` (replaced by GradientButton)
- Delete: `lib/widgets/course_row.dart` (replaced by CourseInputCard)
- Delete: `lib/widgets/semester_row.dart` (replaced by SemesterCard)

**Interfaces:**
- Consumes: semesterProvider, cgpaProvider, gpaStatsProvider
- Produces: Complete redesigned home screen

- [ ] **Step 1: Create new home_screen.dart**

This is the largest task. The complete home screen with:
- ModeSelector
- HeroGpaCard
- Semester cards (CGPA mode) / Course cards (GPA mode)
- GradientButton for add
- Empty states
- Staggered animations

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/semester_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/mesh_gradient_background.dart';
import '../widgets/mode_selector.dart';
import '../widgets/hero_gpa_card.dart';
import '../widgets/semester_card.dart';
import '../widgets/course_input_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/empty_state.dart';
import 'marks_sheet_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(semesterProvider.notifier).loadFromLocal());
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(semesterProvider.select((s) => s.mode));
    final selectedIndex = ref.watch(
      semesterProvider.select((s) => s.selectedIndex),
    );
    final semester = ref.watch(
      semesterProvider.select((s) => s.semesters[selectedIndex]),
    );
    final cgpaState = ref.watch(cgpaProvider);
    final stats = ref.watch(gpaStatsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset('assets/logo2.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'GPA',
              style: GoogleFonts.lexend(
                fontSize: 16,
                letterSpacing: 2,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'CALCULATOR',
              style: GoogleFonts.lexend(
                fontSize: 16,
                letterSpacing: 2,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.table_chart_rounded,
              color: AppTheme.accentPrimary,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MarksSheetScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: MeshGradientBackground(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 20),
            // Mode Selector
            ModeSelector(
              currentMode: mode,
              onChanged: (m) => ref.read(semesterProvider.notifier).setMode(m),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 24),
            // Hero CGPA Card
            HeroGpaCard(
              gpa: mode == CalculationMode.cgpa
                  ? stats.cgpa
                  : stats.semesterGpa,
              label: mode == CalculationMode.cgpa
                  ? 'OVERALL CGPA'
                  : 'SEMESTER GPA',
              totalCredits: stats.totalCredits,
              courseCount: semester.courses.length,
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 28),
            // Section Header
            Text(
              mode == CalculationMode.cgpa ? 'SEMESTERS' : 'COURSES',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textMuted,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            // Semester or Course List
            if (mode == CalculationMode.cgpa) ...[
              if (cgpaState.semesters.isEmpty)
                const EmptyState(
                  icon: Icons.school_outlined,
                  title: 'No semesters yet',
                  subtitle: 'Add your first semester to start calculating',
                )
              else
                ...cgpaState.semesters.asMap().entries.map((entry) {
                  return SemesterCard(
                    key: ValueKey(entry.value.id),
                    semester: entry.value,
                  ).animate().fadeIn(
                        delay: Duration(milliseconds: 50 * entry.key),
                        duration: 300.ms,
                      ).slideY(begin: 0.05, end: 0);
                }),
            ] else ...[
              if (semester.courses.isEmpty)
                const EmptyState(
                  icon: Icons.book_outlined,
                  title: 'No courses yet',
                  subtitle: 'Add your first course to start calculating',
                )
              else
                ...semester.courses.asMap().entries.map((entry) {
                  return CourseInputCard(
                    key: ValueKey(entry.value.id),
                    course: entry.value,
                  ).animate().fadeIn(
                        delay: Duration(milliseconds: 50 * entry.key),
                        duration: 300.ms,
                      ).slideY(begin: 0.05, end: 0);
                }),
            ],
            const SizedBox(height: 24),
            // Add Button
            GradientButton(
              onPressed: () {
                if (mode == CalculationMode.cgpa) {
                  ref.read(cgpaProvider.notifier).addSemester();
                } else {
                  ref.read(semesterProvider.notifier).addCourse(selectedIndex);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    mode == CalculationMode.cgpa
                        ? 'ADD SEMESTER'
                        : 'ADD COURSE',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
            const SizedBox(height: 32),
            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'Developed by',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'JIBRAN KHAN DEHPAL',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
```

---

### Task 13: Create SemesterCard Widget

**Files:**
- Create: `lib/widgets/semester_card.dart`

**Interfaces:**
- Consumes: SemesterResult semester
- Produces: Semester row card with editable name + GPA input

- [ ] **Step 1: Create semester_card.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/semester_result.dart';
import '../providers/semester_provider.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class SemesterCard extends ConsumerStatefulWidget {
  final SemesterResult semester;

  const SemesterCard({super.key, required this.semester});

  @override
  ConsumerState<SemesterCard> createState() => _SemesterCardState();
}

class _SemesterCardState extends ConsumerState<SemesterCard> {
  late TextEditingController _nameController;
  late TextEditingController _gpaController;
  late FocusNode _nameFocus;
  late FocusNode _gpaFocus;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.semester.name);
    _gpaController = TextEditingController(
      text: widget.semester.gpa == 0 ? '' : widget.semester.gpa.toString(),
    );
    _nameFocus = FocusNode();
    _gpaFocus = FocusNode();

    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus && _nameController.text != widget.semester.name) {
        ref.read(cgpaProvider.notifier).updateSemester(
              widget.semester.id,
              name: _nameController.text,
            );
      }
    });

    _gpaFocus.addListener(() {
      if (!_gpaFocus.hasFocus) {
        double gpa = double.tryParse(_gpaController.text) ?? 0;
        if (gpa > 4.0) {
          gpa = 4.0;
          _gpaController.text = '4.0';
        }
        if (gpa != widget.semester.gpa) {
          ref.read(cgpaProvider.notifier).updateSemester(
                widget.semester.id,
                gpa: gpa,
              );
        }
      }
    });
  }

  @override
  void didUpdateWidget(SemesterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.semester.name != widget.semester.name &&
        !_nameFocus.hasFocus) {
      _nameController.text = widget.semester.name;
    }
    final formatted = widget.semester.gpa == 0
        ? ''
        : widget.semester.gpa.toString();
    if (oldWidget.semester.gpa != widget.semester.gpa &&
        !_gpaFocus.hasFocus &&
        _gpaController.text != formatted) {
      _gpaController.text = formatted;
    }
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _gpaFocus.dispose();
    _nameController.dispose();
    _gpaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.school_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: TextField(
                controller: _nameController,
                focusNode: _nameFocus,
                decoration: InputDecoration(
                  hintText: 'Semester Name',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: AppTheme.textMuted.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: TextField(
                  controller: _gpaController,
                  focusNode: _gpaFocus,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: 'GPA',
                    border: InputBorder.none,
                    isDense: true,
                    hintStyle: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  style: const TextStyle(
                    color: AppTheme.accentPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  onChanged: (val) {
                    double gpa = double.tryParse(val) ?? 0;
                    if (gpa > 4.0) {
                      gpa = 4.0;
                      _gpaController.text = '4.0';
                      _gpaController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _gpaController.text.length),
                      );
                    }
                    ref.read(cgpaProvider.notifier).updateSemester(
                          widget.semester.id,
                          gpa: gpa,
                        );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: AppTheme.textMuted,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                ref.read(cgpaProvider.notifier).removeSemester(widget.semester.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### Task 14: Create CourseInputCard Widget

**Files:**
- Create: `lib/widgets/course_input_card.dart`

**Interfaces:**
- Consumes: Course course
- Produces: Card-based marks entry (replaces old CourseRow)

- [ ] **Step 1: Create course_input_card.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/course.dart';
import '../providers/semester_provider.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';
import 'grade_badge.dart';

class CourseInputCard extends ConsumerStatefulWidget {
  final Course course;

  const CourseInputCard({super.key, required this.course});

  @override
  ConsumerState<CourseInputCard> createState() => _CourseInputCardState();
}

class _CourseInputCardState extends ConsumerState<CourseInputCard> {
  late TextEditingController _nameController;
  late TextEditingController _midController;
  late TextEditingController _finalController;
  late TextEditingController _sessionalController;
  late FocusNode _nameFocus;
  late FocusNode _midFocus;
  late FocusNode _finalFocus;
  late FocusNode _sessionalFocus;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.course.name);
    _midController = TextEditingController(
      text: widget.course.midMarks == 0 ? '' : widget.course.midMarks.toStringAsFixed(0),
    );
    _finalController = TextEditingController(
      text: widget.course.finalMarks == 0 ? '' : widget.course.finalMarks.toStringAsFixed(0),
    );
    _sessionalController = TextEditingController(
      text: widget.course.sessionalMarks == 0 ? '' : widget.course.sessionalMarks.toStringAsFixed(0),
    );

    _nameFocus = FocusNode();
    _midFocus = FocusNode();
    _finalFocus = FocusNode();
    _sessionalFocus = FocusNode();

    _setupFocusListeners();
  }

  void _setupFocusListeners() {
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus && _nameController.text != widget.course.name) {
        ref.read(semesterProvider.notifier).updateCourse(
              widget.course.id,
              name: _nameController.text,
            );
      }
    });

    _midFocus.addListener(() => _onMarksFocusLost('mid'));
    _finalFocus.addListener(() => _onMarksFocusLost('final'));
    _sessionalFocus.addListener(() => _onMarksFocusLost('sessional'));
  }

  void _onMarksFocusLost(String type) {
    double val = 0;
    switch (type) {
      case 'mid':
        if (!_midFocus.hasFocus) val = double.tryParse(_midController.text) ?? 0;
        break;
      case 'final':
        if (!_finalFocus.hasFocus) val = double.tryParse(_finalController.text) ?? 0;
        break;
      case 'sessional':
        if (!_sessionalFocus.hasFocus) val = double.tryParse(_sessionalController.text) ?? 0;
        break;
    }
    if (val > 100) val = 100;

    final newTotal = widget.course.midMarks + widget.course.finalMarks + widget.course.sessionalMarks;
    switch (type) {
      case 'mid':
        ref.read(semesterProvider.notifier).updateCourse(
              widget.course.id,
              midMarks: val,
              totalMarks: val + widget.course.finalMarks + widget.course.sessionalMarks,
            );
        break;
      case 'final':
        ref.read(semesterProvider.notifier).updateCourse(
              widget.course.id,
              finalMarks: val,
              totalMarks: widget.course.midMarks + val + widget.course.sessionalMarks,
            );
        break;
      case 'sessional':
        ref.read(semesterProvider.notifier).updateCourse(
              widget.course.id,
              sessionalMarks: val,
              totalMarks: widget.course.midMarks + widget.course.finalMarks + val,
            );
        break;
    }
  }

  @override
  void didUpdateWidget(CourseInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.course.name != widget.course.name && !_nameFocus.hasFocus) {
      _nameController.text = widget.course.name;
    }
    if (oldWidget.course.midMarks != widget.course.midMarks && !_midFocus.hasFocus) {
      _midController.text = widget.course.midMarks == 0 ? '' : widget.course.midMarks.toStringAsFixed(0);
    }
    if (oldWidget.course.finalMarks != widget.course.finalMarks && !_finalFocus.hasFocus) {
      _finalController.text = widget.course.finalMarks == 0 ? '' : widget.course.finalMarks.toStringAsFixed(0);
    }
    if (oldWidget.course.sessionalMarks != widget.course.sessionalMarks && !_sessionalFocus.hasFocus) {
      _sessionalController.text = widget.course.sessionalMarks == 0 ? '' : widget.course.sessionalMarks.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _midFocus.dispose();
    _finalFocus.dispose();
    _sessionalFocus.dispose();
    _nameController.dispose();
    _midController.dispose();
    _finalController.dispose();
    _sessionalController.dispose();
    super.dispose();
  }

  Widget _buildMarkField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: '0',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: TextStyle(color: AppTheme.textMuted),
              ),
              onChanged: (val) {
                double d = double.tryParse(val) ?? 0;
                if (d > 100) {
                  d = 100;
                  controller.text = '100';
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLab = widget.course.isPractical;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderColor: isLab
            ? AppTheme.accentPrimary.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.1),
        child: Column(
          children: [
            // Top Row: Lab toggle + Course Name
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    ref.read(semesterProvider.notifier).updateCourse(
                          widget.course.id,
                          isPractical: !isLab,
                          creditHours: !isLab ? 1.0 : widget.course.creditHours,
                        );
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isLab
                          ? AppTheme.accentPrimary.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isLab
                            ? AppTheme.accentPrimary.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Icon(
                      isLab ? Icons.science : Icons.science_outlined,
                      size: 20,
                      color: isLab ? AppTheme.accentPrimary : AppTheme.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    decoration: InputDecoration(
                      hintText: 'Course Name',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintStyle: TextStyle(
                        color: AppTheme.textMuted.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Middle Row: Marks fields
            Row(
              children: [
                _buildMarkField(
                  label: 'MID',
                  controller: _midController,
                  focusNode: _midFocus,
                ),
                const SizedBox(width: 10),
                _buildMarkField(
                  label: 'FINAL',
                  controller: _finalController,
                  focusNode: _finalFocus,
                ),
                const SizedBox(width: 10),
                _buildMarkField(
                  label: 'SESSIONAL',
                  controller: _sessionalController,
                  focusNode: _sessionalFocus,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Bottom Row: Credits + Total + Grade + Delete
            Row(
              children: [
                // Credits Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CREDITS',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: isLab
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                '1',
                                style: TextStyle(
                                  color: AppTheme.accentPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : DropdownButton<double>(
                              value: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
                                      .contains(widget.course.creditHours)
                                  ? widget.course.creditHours
                                  : 3.0,
                              dropdownColor: AppTheme.bgGradientStart,
                              underline: const SizedBox(),
                              isDense: true,
                              icon: const Icon(
                                Icons.expand_more,
                                size: 16,
                                color: AppTheme.textMuted,
                              ),
                              items: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0].map((e) {
                                return DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    '${e.toInt()}',
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  ref.read(semesterProvider.notifier).updateCourse(
                                        widget.course.id,
                                        creditHours: val,
                                      );
                                  HapticFeedback.selectionClick();
                                }
                              },
                            ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Total
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.accentPrimary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        widget.course.totalMarks.toStringAsFixed(0),
                        style: const TextStyle(
                          color: AppTheme.accentPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Grade Badge
                GradeBadge(grade: widget.course.grade),
                const SizedBox(width: 12),
                // Delete
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppTheme.textMuted,
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(semesterProvider.notifier).removeCourse(
                          widget.course.id,
                        );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Phase 6: Marks Sheet Redesign

### Task 15: Rewrite MarksSheetScreen

**Files:**
- Modify: `lib/screens/marks_sheet_screen.dart`

**Interfaces:**
- Consumes: marksSheetProvider, marksStatsProvider
- Produces: Complete redesigned marks sheet with card-based input

- [ ] **Step 1: Rewrite marks_sheet_screen.dart**

Replace the entire DataTable-based layout with card-based CourseInputCard widgets, proper semester tabs, and empty states. Follow same pattern as home screen but with tab navigation between semesters.

Key changes:
- Remove DataTable entirely
- Use TabBar with custom styled tabs
- Each semester tab shows list of CourseInputCard widgets
- Add empty state when no courses
- Refined info banner
- Proper spacing and padding

---

## Phase 7: Cleanup

### Task 16: Remove Deprecated Widgets

**Files:**
- Delete: `lib/widgets/bento_card.dart`
- Delete: `lib/widgets/neomorphic_button.dart`
- Delete: `lib/widgets/course_row.dart`
- Delete: `lib/widgets/semester_row.dart`

- [ ] **Step 1: Remove old widget files**

```bash
rm lib/widgets/bento_card.dart
rm lib/widgets/neomorphic_button.dart
rm lib/widgets/course_row.dart
rm lib/widgets/semester_row.dart
```

- [ ] **Step 2: Verify no remaining imports reference deleted files**

Run: `grep -r "bento_card\|neomorphic_button\|course_row\|semester_row" lib/`
Expected: No results

---

### Task 17: Final Verification

- [ ] **Step 1: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors, warnings acceptable

- [ ] **Step 2: Run app on emulator/device**

Run: `flutter run`
Expected: All screens work correctly, animations smooth, no crashes

- [ ] **Step 3: Test all flows**
- Splash → Home transition
- GPA/CGPA mode switching
- Add/delete semesters
- Add/delete courses
- Marks entry (mid, final, sessional)
- Grade calculation
- Marks Sheet navigation
- Save functionality

---

## Summary

| Phase | Tasks | Files Created | Files Modified | Files Deleted |
|-------|-------|---------------|----------------|---------------|
| 1: Foundation | 3 | 0 | 3 | 0 |
| 2: New Widgets | 6 | 6 | 0 | 0 |
| 3: Hero Card | 1 | 1 | 0 | 0 |
| 4: Splash | 1 | 1 | 1 | 0 |
| 5: Home | 3 | 2 | 1 | 0 |
| 6: Marks Sheet | 1 | 0 | 1 | 0 |
| 7: Cleanup | 2 | 0 | 0 | 4 |
| **Total** | **17** | **10** | **6** | **4** |
