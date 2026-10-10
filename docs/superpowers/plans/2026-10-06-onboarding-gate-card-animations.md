# Onboarding Name/Avatar Gate + Card Create/Delete Animations â€” Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** (1) Block first-time app entry until the user explicitly types a name and picks an avatar (with live avatar preview), and (2) animate subject/semester card create (slide+grow+fade) and delete (slide+fade+collapse) exactly like approved demo option A.

**Architecture:** Feature 1 tightens the existing onboarding name step: the "Let's Go ðŸš€" button is disabled (`onTap: null` + dimmed) until name is non-empty and an avatar was tapped; the preview circle shows the picked avatar instead of ðŸ‘‹. Feature 2 adds one reusable `AnimatedCardFrame` wrapper (pure Flutter `AnimationController` + `Align(heightFactor:)` + `ClipRect`); pages track enter/exit by subject/semester **id**, delay the actual provider delete until the exit animation completes, and finish any in-flight delete on `dispose()` (pages are destroyed on every tab switch by `MainShell`'s `AnimatedSwitcher`).

**Tech Stack:** Flutter 3.41.6 / Dart 3.11.4, provider, flutter_test. Windows + PowerShell.

**Specs:**
- `docs/superpowers/specs/2026-10-06-onboarding-name-avatar-gate-design.md`
- `docs/superpowers/specs/2026-10-06-card-create-delete-animation-design.md`

## Global Constraints

- **NO git commits** (session-wide rule). Every task gates with `flutter analyze` + `flutter test` instead of commit steps.
- **Never modify:** `lib/providers/app_data.dart`, `lib/services/gpa_service.dart`, `lib/main.dart`, `lib/widgets/staggered_animation.dart`.
- **No new dependencies** â€” allowed packages only: provider, shared_preferences, flutter_svg, google_fonts.
- Prefs keys stay exactly: `mckru_gpa2`, `mckru_cgpa2`, `mckru_dark2`, `mckru_onboarded2`, `mckru_name`, `mckru_avatar`.
- Splash stays 2500 ms; tab order 0=Home,1=GPA,2=CGPA,3=Data,4=Settings; validation messages/formatters untouched.
- `StaggeredAnimation` must keep wrapping every subject/semester card (current usage pattern: `StaggeredAnimation(index: i, child: â€¦)`).
- All commands run from `C:\All Flutter Project\cgpa_calculator`.
- Test file stays `test/widget_test.dart` (existing convention). `setUpAll` already sets `SharedPreferences.setMockInitialValues({})` and `GoogleFonts.config.allowRuntimeFetching = false`; each test still calls `setMockInitialValues` itself.
- Fact: fresh install seeds exactly **one** GPA subject ("Subject 1") and **one** semester ("Semester 1") in `loadFromLocal`. Both have `id` from `generateId()`. `removeGpaSubject`/`removeSemester` no-op when length â‰¤ 1 (`canDelete` mirrors this).
- Fact: `Add subject` / `Add semester` are `GhostButton`s in `main_shell.dart` `_TopBar` (they mutate the provider directly). Page swap uses `AnimatedSwitcher` 200 ms fade â†’ tests must pump â‰¥ 300 ms after a tab tap, and page `State` is destroyed on tab switch.

---

### Task 1: Onboarding name/avatar gate (failing test first)

**Files:**
- Modify: `test/widget_test.dart` (new test + imports)
- Modify: `lib/screens/onboarding_screen.dart` (lines ~18, 53â€“59, 142, 179â€“195, 170)
- Modify: `lib/widgets/ui.dart` (`PrimaryButton.build`, lines 61â€“85)

**Interfaces:**
- Consumes: existing `AppData.finishOnboarding(String name, String avatar)` (unchanged), `PrimaryButton({required label, onTap, icon, expanded})`.
- Produces: `PrimaryButton` renders dimmed (`Opacity 0.45`) and non-tappable whenever `onTap == null`; onboarding `_canFinish` gate (private). No other task depends on this.

- [x] **Step 1: Add imports to `test/widget_test.dart`**

```dart
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cgpa_calculator/main.dart';
import 'package:cgpa_calculator/widgets/ui.dart';
```

- [x] **Step 2: Add the failing test (append inside `main()` after the second test)**

```dart
  testWidgets('onboarding requires name and avatar before entering app', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next â†’'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text("What's Your Name?"), findsOneWidget);

    final letsGo = find.widgetWithText(PrimaryButton, "Let's Go ðŸš€");
    bool isDisabled() => tester
        .widget<InkWell>(find.descendant(of: letsGo, matching: find.byType(InkWell)))
        .onTap ==
        null;

    expect(isDisabled(), isTrue, reason: 'Let\'s Go must start disabled');

    await tester.enterText(find.byType(TextField).first, 'Ali');
    await tester.pump();
    expect(isDisabled(), isTrue, reason: 'still disabled until an avatar is picked');

    await tester.ensureVisible(letsGo);
    await tester.pump();
    await tester.tap(letsGo);
    await tester.pump();
    expect(find.text("What's Your Name?"), findsOneWidget,
        reason: 'tapping the disabled button must not enter the app');

    final firstAvatar = find.byType(Image).first;
    await tester.ensureVisible(firstAvatar);
    await tester.pump();
    await tester.tap(firstAvatar);
    await tester.pump();
    expect(isDisabled(), isFalse, reason: 'name + avatar chosen -> enabled');

    await tester.ensureVisible(letsGo);
    await tester.pump();
    await tester.tap(letsGo);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Welcome back, Ali'), findsOneWidget);
  });
```

- [x] **Step 3: Run the test, verify it FAILS**

Run: `flutter test --plain-name "onboarding requires name and avatar before entering app"`
Expected: FAIL â€” `expect(isDisabled(), isTrue)` at the first gate (today the button is always enabled).

- [x] **Step 4: Implement â€” `lib/widgets/ui.dart` `PrimaryButton.build`**

Replace the last two lines of `build` (after `final btn = Material(â€¦);`) so the whole method body ends with:

```dart
    final btn = Material(
      color: p.accentDeep,
      borderRadius: BorderRadius.circular(kRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadius),
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 15, color: Colors.white), const SizedBox(width: 8)],
              Text(label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
    final gated = onTap == null ? Opacity(opacity: 0.45, child: btn) : btn;
    return expanded ? SizedBox(width: double.infinity, child: gated) : gated;
```

(Only the `gated` lines are new; keep the existing `btn` exactly as-is. `EmptyState`'s button already renders only when a label exists â€” if it is ever called with `onButton: null` it now dims, which is correct.)

- [x] **Step 5: Implement â€” `lib/screens/onboarding_screen.dart`**

1. Change the field (line ~18):

```dart
  String? _selectedAvatar;
```

2. Replace `_finish` (lines ~53â€“59) with:

```dart
  bool get _canFinish =>
      _selectedAvatar != null && _nameController.text.trim().isNotEmpty;

  void _finish() {
    final name = _nameController.text.trim();
    final avatar = _selectedAvatar;
    if (name.isEmpty || avatar == null) return;
    context.read<AppData>().finishOnboarding(name, avatar);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }
```

3. In `_buildNameStep`, replace the preview circle's child (currently `child: const Center(child: Text('ðŸ‘‹', â€¦))`) with:

```dart
                  child: _selectedAvatar == null
                      ? const Center(child: Text('ðŸ‘‹', style: TextStyle(fontSize: 72)))
                      : Padding(
                          padding: const EdgeInsets.all(18),
                          child: Image.asset(_selectedAvatar!, fit: BoxFit.contain),
                        ),
```

(The surrounding `Container(width: 160, height: 160, decoration: accentSoft/circle/border, â€¦)` stays unchanged.)

4. In `_buildNameInput`, add `onChanged` to the `TextField`:

```dart
        TextField(
          controller: _nameController,
          textAlign: TextAlign.center,
          maxLength: 20,
          onChanged: (_) => setState(() {}),
          decoration: fieldInput(context, hint: 'Enter your name...'),
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: p.fg),
        ),
```

5. Change the button (line ~170):

```dart
              PrimaryButton(label: "Let's Go ðŸš€", expanded: true, onTap: _canFinish ? _finish : null),
```

- [x] **Step 6: Run the new test, verify PASS**

Run: `flutter test --plain-name "onboarding requires name and avatar before entering app"`
Expected: PASS

- [x] **Step 7: Full gates**

Run: `flutter analyze` â†’ Expected: `No issues found!`
Run: `flutter test` â†’ Expected: `All tests passed!` (3/3)

---

### Task 2: `AnimatedCardFrame` widget (failing test first)

**Files:**
- Create: `lib/widgets/animated_card_frame.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: Flutter only (`AnimationController`, `CurvedAnimation`, `ClipRect`, `Align`, `Opacity`, `Transform.translate`).
- Produces (used by Tasks 3â€“4):

```dart
AnimatedCardFrame({
  Key? key,
  required Widget child,
  bool animateEnter = false,   // read ONCE at initState
  bool exiting = false,        // false -> true starts the exit
  VoidCallback? onExitComplete, // fired once when exit reaches height 0
})
```

- Enter (~300 ms, `Curves.easeOut`): heightFactor 0â†’1, `translateY âˆ’14â†’0`, opacity 0â†’1.
- Exit (~280 ms, `Curves.easeOut`): heightFactor 1â†’0, `translateX 0â†’+48`, opacity 1â†’0, then `onExitComplete()`.
- If `exiting` flips back to `false` before completion (defensive path), the frame restores to full height.

- [x] **Step 1: Add the failing test (append inside `main()`)**

```dart
  testWidgets('AnimatedCardFrame grows in on demand and collapses out calling onExitComplete',
      (tester) async {
    Widget build({bool animateEnter = false, bool exiting = false, VoidCallback? onExit}) {
      return MaterialApp(
        home: Scaffold(
          body: AnimatedCardFrame(
            animateEnter: animateEnter,
            exiting: exiting,
            onExitComplete: onExit,
            child: const SizedBox(width: 200, height: 100, child: Text('card')),
          ),
        ),
      );
    }

    await tester.pumpWidget(build(animateEnter: true));
    final h0 = tester.getSize(find.byType(AnimatedCardFrame)).height;
    expect(h0, lessThan(1), reason: 'enter starts at zero height');

    await tester.pump(const Duration(milliseconds: 320));
    final h1 = tester.getSize(find.byType(AnimatedCardFrame)).height;
    expect(h1, greaterThan(99), reason: 'enter finishes at natural height');

    var completed = false;
    await tester.pumpWidget(build(exiting: true, onExit: () => completed = true));
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pump();
    expect(completed, isTrue, reason: 'onExitComplete fires after exit animation');
    expect(tester.getSize(find.byType(AnimatedCardFrame)).height, lessThan(1));
  });
```

Add import at top of `test/widget_test.dart` (next to the Task 1 import):

```dart
import 'package:cgpa_calculator/widgets/animated_card_frame.dart';
```

- [x] **Step 2: Run the test, verify it FAILS**

Run: `flutter test --plain-name "AnimatedCardFrame grows in on demand"`
Expected: FAIL â€” compile error: `AnimatedCardFrame` isn't defined.

- [x] **Step 3: Create `lib/widgets/animated_card_frame.dart`**

```dart
import 'package:flutter/material.dart';

class AnimatedCardFrame extends StatefulWidget {
  final Widget child;
  final bool animateEnter;
  final bool exiting;
  final VoidCallback? onExitComplete;

  const AnimatedCardFrame({
    super.key,
    required this.child,
    this.animateEnter = false,
    this.exiting = false,
    this.onExitComplete,
  });

  @override
  State<AnimatedCardFrame> createState() => _AnimatedCardFrameState();
}

class _AnimatedCardFrameState extends State<AnimatedCardFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _eased;
  bool _exitNotified = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.animateEnter ? 0.0 : 1.0,
    );
    _eased = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && widget.exiting && !_exitNotified) {
        _exitNotified = true;
        widget.onExitComplete?.call();
      }
    });
    if (widget.animateEnter) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedCardFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.exiting && !oldWidget.exiting) {
      _exitNotified = false;
      _controller.duration = const Duration(milliseconds: 280);
      _controller.reverse();
    } else if (!widget.exiting && oldWidget.exiting && !_exitNotified) {
      _controller.duration = const Duration(milliseconds: 300);
      _controller.forward();
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
      animation: _eased,
      builder: (context, child) {
        final v = _eased.value;
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: v,
            child: Opacity(
              opacity: v.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: widget.exiting
                    ? Offset(48 * (1 - v), 0)
                    : Offset(0, -14 * (1 - v)),
                child: child!,
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
```

- [x] **Step 4: Run the test, verify PASS**

Run: `flutter test --plain-name "AnimatedCardFrame grows in on demand"`
Expected: PASS

- [x] **Step 5: Full gates**

Run: `flutter analyze` â†’ Expected: `No issues found!`
Run: `flutter test` â†’ Expected: `All tests passed!` (4/4)

---

### Task 3: GPA page â€” enter/exit integration (failing test first)

**Files:**
- Modify: `lib/screens/gpa_page.dart` (class shell + list builder; `_SubjectCard` untouched)
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `AnimatedCardFrame` (Task 2), `AppData.gpaSubjects` (`GpaSubject.id`), `removeGpaSubject(int index)` (index-based; no-op if â‰¤ 1), `addGpaSubject()` (called by topbar button).
- Produces: none (end-user behavior; Task 4 copies the pattern for semesters).

- [x] **Step 1: Add the failing test (append inside `main()`)**

```dart
  testWidgets('GPA: deleting a subject waits for the exit animation', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'mckru_onboarded2': true,
      'mckru_name': 'Ali',
    });
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    await tester.tap(find.text('GPA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    final fields = find.byType(TextField);
    final initial = tester.widgetList(fields).length;

    await tester.tap(find.text('Add subject'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    final added = tester.widgetList(fields).length;
    expect(added, initial + 2, reason: 'new subject card contributes 2 text fields');

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pump();
    expect(
      tester.widgetList(fields).length,
      added,
      reason: 'card must stay mounted while the exit animation runs',
    );

    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(tester.widgetList(fields).length, initial, reason: 'provider delete happens after exit');
  });
```

- [x] **Step 2: Run the test, verify it FAILS**

Run: `flutter test --plain-name "GPA: deleting a subject waits"`
Expected: FAIL â€” after the `ðŸ—‘` tap the card is removed immediately (current code calls `data.removeGpaSubject(i)` straight away), so the "stays mounted" expectation gets `initial` instead of `added`.

- [x] **Step 3: Implement â€” convert `GpaPage` to stateful (replace lines 10â€“64 of `gpa_page.dart`)**

Add imports at the top:

```dart
import 'dart:async';

import '../widgets/animated_card_frame.dart';
```

(`dart:async` first, then the existing imports, then `../widgets/animated_card_frame.dart` alongside the other `../widgets/` imports â€” keep alphabetical order with `staggered_animation.dart` and `ui.dart`.)

Replace the whole `class GpaPage extends StatelessWidget { â€¦ }` (through its closing brace, line 64) with:

```dart
class GpaPage extends StatefulWidget {
  const GpaPage({super.key});

  @override
  State<GpaPage> createState() => _GpaPageState();
}

class _GpaPageState extends State<GpaPage> {
  AppData? _data;
  Set<String> _knownIds = <String>{};
  bool _seeded = false;
  String? _enterId;
  String? _exitId;
  Timer? _enterTimer;

  @override
  void dispose() {
    _enterTimer?.cancel();
    final id = _exitId;
    final data = _data;
    if (id != null && data != null) {
      final idx = data.gpaSubjects.indexWhere((s) => s.id == id);
      if (idx != -1) data.removeGpaSubject(idx);
    }
    super.dispose();
  }

  void _completeExit(String id) {
    final data = _data;
    if (data == null) return;
    final idx = data.gpaSubjects.indexWhere((s) => s.id == id);
    if (idx != -1) data.removeGpaSubject(idx);
    if (mounted) setState(() => _exitId = null);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    _data = context.read<AppData>();

    final ids = data.gpaSubjects.map((s) => s.id).toSet();
    if (_seeded) {
      final added = ids.difference(_knownIds);
      if (added.isNotEmpty) {
        _enterId = added.first;
        _enterTimer?.cancel();
        _enterTimer = Timer(const Duration(milliseconds: 400), () {
          if (mounted) setState(() => _enterId = null);
        });
      }
    }
    _knownIds = ids;
    _seeded = true;

    double totalPts = 0;
    int totalCr = 0;
    for (final card in data.gpaSubjects) {
      final marks = double.tryParse(card.marks);
      if (marks == null || card.marks.isEmpty) continue;
      final effectiveMarks = card.isLab ? marks * 2 : marks;
      final grade = GpaService.getGradeFromMarks(effectiveMarks);
      if (grade == null) continue;
      final cr = card.isLab ? 1 : card.credits;
      totalPts += grade.gpa * cr;
      totalCr += cr;
    }

    final gpaResult = totalCr > 0 ? totalPts / totalCr : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        children: [
          ...List.generate(data.gpaSubjects.length, (i) {
            final subject = data.gpaSubjects[i];
            return StaggeredAnimation(
              index: i,
              child: AnimatedCardFrame(
                animateEnter: subject.id == _enterId,
                exiting: subject.id == _exitId,
                onExitComplete: () => _completeExit(subject.id),
                child: _SubjectCard(
                  index: i,
                  subject: subject,
                  canDelete: data.gpaSubjects.length > 1,
                  onDelete: () {
                    if (_exitId == null) setState(() => _exitId = subject.id);
                  },
                  onChanged: (updated) => data.updateGpaSubject(i, updated),
                ),
              ),
            );
          }),
          if (gpaResult != null) ...[
            const SizedBox(height: 10),
            StaggeredAnimation(
              index: data.gpaSubjects.length,
              child: ResultCard(
                eyebrow: 'Semester GPA',
                value: gpaResult.toStringAsFixed(2),
                progress: gpaResult / 4,
                message: GpaService.getGpaMessage(gpaResult),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

Everything after line 64 (`class _SubjectCard â€¦`, `_CreditChip`) stays byte-identical.

- [x] **Step 4: Run the test, verify PASS**

Run: `flutter test --plain-name "GPA: deleting a subject waits"`
Expected: PASS

- [x] **Step 5: Full gates**

Run: `flutter analyze` â†’ Expected: `No issues found!`
Run: `flutter test` â†’ Expected: `All tests passed!` (5/5)

---

### Task 4: CGPA page â€” semester enter/exit integration (failing test first)

**Files:**
- Modify: `lib/screens/cgpa_page.dart` (class shell + list builder; `_SemesterCard` untouched)
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `AnimatedCardFrame` (Task 2), `AppData.semesters` (`SemesterGpa.id`), `removeSemester(int index)` (no-op if â‰¤ 1; renumbers "Semester N" **after** the actual removal), `addSemester()`.
- Produces: none.

- [x] **Step 1: Add the failing test (append inside `main()`)**

```dart
  testWidgets('CGPA: deleting a semester waits for the exit animation', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'mckru_onboarded2': true,
      'mckru_name': 'Ali',
    });
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    await tester.tap(find.text('CGPA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    final fields = find.byType(TextField);
    final initial = tester.widgetList(fields).length;

    await tester.tap(find.text('Add semester'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    final added = tester.widgetList(fields).length;
    expect(added, initial + 2, reason: 'new semester card contributes 2 text fields');

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pump();
    expect(
      tester.widgetList(fields).length,
      added,
      reason: 'card must stay mounted while the exit animation runs',
    );

    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(tester.widgetList(fields).length, initial, reason: 'provider delete happens after exit');
    await tester.pump(const Duration(milliseconds: 500));
  });
```

- [x] **Step 2: Run the test, verify it FAILS**

Run: `flutter test --plain-name "CGPA: deleting a semester waits"`
Expected: FAIL â€” same reason as Task 3 (instant provider removal).

- [x] **Step 3: Implement â€” convert `CgpaPage` to stateful (replace lines 10â€“51 of `cgpa_page.dart`)**

Add imports at the top (same placement rules as Task 3):

```dart
import 'dart:async';

import '../widgets/animated_card_frame.dart';
```

Replace the whole `class CgpaPage extends StatelessWidget { â€¦ }` (through its closing brace, line 51) with:

```dart
class CgpaPage extends StatefulWidget {
  const CgpaPage({super.key});

  @override
  State<CgpaPage> createState() => _CgpaPageState();
}

class _CgpaPageState extends State<CgpaPage> {
  AppData? _data;
  Set<String> _knownIds = <String>{};
  bool _seeded = false;
  String? _enterId;
  String? _exitId;
  Timer? _enterTimer;

  @override
  void dispose() {
    _enterTimer?.cancel();
    final id = _exitId;
    final data = _data;
    if (id != null && data != null) {
      final idx = data.semesters.indexWhere((s) => s.id == id);
      if (idx != -1) data.removeSemester(idx);
    }
    super.dispose();
  }

  void _completeExit(String id) {
    final data = _data;
    if (data == null) return;
    final idx = data.semesters.indexWhere((s) => s.id == id);
    if (idx != -1) data.removeSemester(idx);
    if (mounted) setState(() => _exitId = null);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    _data = context.read<AppData>();

    final ids = data.semesters.map((s) => s.id).toSet();
    if (_seeded) {
      final added = ids.difference(_knownIds);
      if (added.isNotEmpty) {
        _enterId = added.first;
        _enterTimer?.cancel();
        _enterTimer = Timer(const Duration(milliseconds: 400), () {
          if (mounted) setState(() => _enterId = null);
        });
      }
    }
    _knownIds = ids;
    _seeded = true;

    final cgpa = data.cgpa;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        children: [
          ...List.generate(data.semesters.length, (i) {
            final semester = data.semesters[i];
            return StaggeredAnimation(
              index: i,
              child: AnimatedCardFrame(
                animateEnter: semester.id == _enterId,
                exiting: semester.id == _exitId,
                onExitComplete: () => _completeExit(semester.id),
                child: _SemesterCard(
                  index: i,
                  semester: semester,
                  canDelete: data.semesters.length > 1,
                  onDelete: () {
                    if (_exitId == null) setState(() => _exitId = semester.id);
                  },
                  onChanged: (updated) => data.updateSemester(i, updated),
                ),
              ),
            );
          }),
          if (cgpa != null) ...[
            const SizedBox(height: 10),
            StaggeredAnimation(
              index: data.semesters.length,
              child: ResultCard(
                eyebrow: 'Cumulative CGPA',
                value: cgpa.toStringAsFixed(2),
                progress: cgpa / 4,
                message:
                    'Mean of ${data.semesterCount} saved semesters Â· autosaves 500 ms after you stop typing.',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

Everything after line 51 (`class _SemesterCard â€¦`) stays byte-identical (formatters/validation untouched).

- [x] **Step 4: Run the test, verify PASS**

Run: `flutter test --plain-name "CGPA: deleting a semester waits"`
Expected: PASS

- [x] **Step 5: Full gates**

Run: `flutter analyze` â†’ Expected: `No issues found!`
Run: `flutter test` â†’ Expected: `All tests passed!` (6/6)

---

### Task 5: Final verification

**Files:** none (verification only).

**Interfaces:**
- Consumes: Tasks 1â€“4.
- Produces: green gates + visual confirmation for the user.

- [x] **Step 1: Full automated gates**

Run: `flutter analyze` â†’ Expected: `No issues found!`
Run: `flutter test` â†’ Expected: `All tests passed!` (6/6)

- [x] **Step 2: Visual check for the user**

Run: `flutter run -d web-server --web-port=8750 --no-hot` (or let the user run on their device â€” launcher/animation behavior must be checked on a real rebuild, hot restart is fine for animations).

Manually verify:
1. Fresh profile â†’ onboarding: at the name step "Let's Go ðŸš€" is dimmed; typing a name alone keeps it dimmed; picking an avatar lights it up; the big circle shows the picked avatar live.
2. GPA tab â†’ `Add subject`: new card slides down + grows in; `ðŸ—‘`: card slides right + collapses, siblings shift smoothly; quick add/delete in a row does not desync (idx badges renumber as before).
3. CGPA tab â†’ same for semesters.
4. Delete the only subject â†’ `ðŸ—‘` stays disabled (`canDelete`), no animation triggered.

- [x] **Step 3: Report**

Summarize results (analyze/test counts + visual checklist). **No commits** â€” leave changes staged in the working tree per session rule.

## Amendments (post-implementation, ratified after final whole-plan review)

1. **Keyed card frames (Critical fix).** The plan's unkeyed `List.generate` builders + `AnimatedCardFrame.didUpdateWidget`'s restore branch gated on `!_exitNotified` meant that after deleting any non-last card, Flutter's positional child reuse handed the exited frame State (`value = 0`, `_exitNotified = true`) to the next card, collapsing it to height 0 permanently. Fix (Task 3/4 code amended): `key: ValueKey(subject.id)` / `key: ValueKey(semester.id)` on the `AnimatedCardFrame` call sites. Verified RED (survivor height 0.0) → GREEN via two new geometry regression tests.
2. **Test harness pumps.** `await tester.pump(const Duration(milliseconds: 500));` after final expects drains the unmodifiable 500 ms `_debounceSave` timer (AppData is never-modify). Controller-approved.
3. **Final gate counts supersede plan text:** `flutter analyze` clean, `flutter test` 8/8 (plan expected 6/6 before the two regression tests).
