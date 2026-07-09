# Performance Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Optimize CGPA Calculator Flutter app performance by fixing font recomputation, keystroke state churn, and anti-patterns.

**Architecture:** Incremental optimization approach - fix critical issues first, then high/medium/low priority items. Each task is self-contained and testable.

**Tech Stack:** Flutter, Dart, Riverpod, SharedPreferences, GoogleFonts

## Global Constraints

- Flutter SDK ^3.8.1
- Dart ^3.8.1
- Riverpod v3.2.1
- All changes must preserve existing functionality
- Test each change on device before proceeding

---

## Phase 1: Critical Performance Fixes

### Task 1: GoogleFonts Caching - course_input_card.dart

**Files:**
- Modify: `lib/widgets/course_input_card.dart`

**Interfaces:**
- Consumes: GoogleFonts.lexend(), GoogleFonts.inter()
- Produces: Cached TextStyle objects as static final fields

- [ ] **Step 1: Read the current file to understand structure**

Read `lib/widgets/course_input_card.dart` and identify all GoogleFonts calls.

- [ ] **Step 2: Add static final TextStyle fields at top of class**

Add these fields to `_CourseInputCardState` class:

```dart
static final _labelStyle = GoogleFonts.inter(
  fontSize: 11,
  fontWeight: FontWeight.w500,
  color: Colors.white54,
  letterSpacing: 0.5,
);

static final _inputStyle = GoogleFonts.inter(
  fontSize: 15,
  color: Colors.white,
);

static final _hintStyle = GoogleFonts.inter(
  fontSize: 15,
  color: Colors.white24,
);

static final _badgeStyle = GoogleFonts.lexend(
  fontSize: 13,
  fontWeight: FontWeight.w600,
);
```

- [ ] **Step 3: Replace inline GoogleFonts calls with cached versions**

Search and replace all `GoogleFonts.lexend(...)` and `GoogleFonts.inter(...)` calls in the build methods with the cached static fields.

- [ ] **Step 4: Run app and verify UI looks identical**

Run: `flutter run -d windows`
Verify: All text styles render correctly, no visual changes.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/course_input_card.dart
git commit -m "perf: cache GoogleFonts TextStyles in course_input_card.dart"
```

---

### Task 2: GoogleFonts Caching - semester_card.dart

**Files:**
- Modify: `lib/widgets/semester_card.dart`

**Interfaces:**
- Consumes: GoogleFonts.lexend(), GoogleFonts.inter()
- Produces: Cached TextStyle objects as static final fields

- [ ] **Step 1: Read the current file**

Read `lib/widgets/semester_card.dart` and identify all GoogleFonts calls.

- [ ] **Step 2: Add static final TextStyle fields**

Add to `_SemesterCardState` class:

```dart
static final _nameStyle = GoogleFonts.inter(
  fontSize: 13,
  color: Colors.white70,
);

static final _gpaStyle = GoogleFonts.lexend(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  color: Colors.white,
);

static final _labelStyle = GoogleFonts.inter(
  fontSize: 10,
  color: Colors.white38,
);
```

- [ ] **Step 3: Replace inline GoogleFonts calls**

Replace all inline calls with cached versions.

- [ ] **Step 4: Run app and verify**

Run: `flutter run -d windows`
Verify: Semester cards display correctly.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/semester_card.dart
git commit -m "perf: cache GoogleFonts TextStyles in semester_card.dart"
```

---

### Task 3: GoogleFonts Caching - home_screen.dart

**Files:**
- Modify: `lib/screens/home_screen.dart`

**Interfaces:**
- Consumes: GoogleFonts.lexend()
- Produces: Cached TextStyle objects

- [ ] **Step 1: Read the current file**

Read `lib/screens/home_screen.dart` and identify GoogleFonts calls.

- [ ] **Step 2: Add static final TextStyle fields**

Add to `_HomeScreenState` class:

```dart
static final _appBarTitleStyle = GoogleFonts.lexend(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: Colors.white,
);

static final _sectionHeaderStyle = GoogleFonts.lexend(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.2,
  color: Colors.white38,
);
```

- [ ] **Step 3: Replace inline GoogleFonts calls**

Replace all inline calls with cached versions.

- [ ] **Step 4: Run app and verify**

Run: `flutter run -d windows`
Verify: Home screen renders correctly.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/home_screen.dart
git commit -m "perf: cache GoogleFonts TextStyles in home_screen.dart"
```

---

### Task 4: GoogleFonts Caching - marks_sheet_screen.dart

**Files:**
- Modify: `lib/screens/marks_sheet_screen.dart`

**Interfaces:**
- Consumes: GoogleFonts.lexend(), GoogleFonts.inter()
- Produces: Cached TextStyle objects

- [ ] **Step 1: Read the current file**

Read `lib/screens/marks_sheet_screen.dart` and identify all GoogleFonts calls.

- [ ] **Step 2: Add static final TextStyle fields**

Add to `_MarksSheetScreenState` class:

```dart
static final _titleStyle = GoogleFonts.lexend(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: Colors.white,
);

static final _bodyStyle = GoogleFonts.inter(
  fontSize: 14,
  color: Colors.white70,
);

static final _headerStyle = GoogleFonts.lexend(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.2,
  color: Colors.white38,
);
```

- [ ] **Step 3: Replace inline GoogleFonts calls**

Replace all inline calls with cached versions.

- [ ] **Step 4: Run app and verify**

Run: `flutter run -d windows`
Verify: Marks sheet screen renders correctly.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/marks_sheet_screen.dart
git commit -m "perf: cache GoogleFonts TextStyles in marks_sheet_screen.dart"
```

---

### Task 5: GoogleFonts Caching - remaining widgets

**Files:**
- Modify: `lib/widgets/hero_gpa_card.dart`
- Modify: `lib/widgets/mode_selector.dart`
- Modify: `lib/widgets/grade_badge.dart`
- Modify: `lib/widgets/mini_stat_card.dart`
- Modify: `lib/widgets/gradient_button.dart`
- Modify: `lib/widgets/empty_state.dart`

**Interfaces:**
- Consumes: GoogleFonts.lexend(), GoogleFonts.inter()
- Produces: Cached TextStyle objects

- [ ] **Step 1: Process hero_gpa_card.dart**

Read file, add static final TextStyles, replace inline calls.

- [ ] **Step 2: Process mode_selector.dart**

Read file, add static final TextStyles, replace inline calls.

- [ ] **Step 3: Process grade_badge.dart**

Read file, add static final TextStyles, replace inline calls.

- [ ] **Step 4: Process mini_stat_card.dart**

Read file, add static final TextStyles, replace inline calls.

- [ ] **Step 5: Process gradient_button.dart**

Read file, add static final TextStyles, replace inline calls.

- [ ] **Step 6: Process empty_state.dart**

Read file, add static final TextStyles, replace inline calls.

- [ ] **Step 7: Run app and verify all screens**

Run: `flutter run -d windows`
Verify: All screens render correctly with no visual changes.

- [ ] **Step 8: Commit**

```bash
git add lib/widgets/hero_gpa_card.dart lib/widgets/mode_selector.dart lib/widgets/grade_badge.dart lib/widgets/mini_stat_card.dart lib/widgets/gradient_button.dart lib/widgets/empty_state.dart
git commit -m "perf: cache GoogleFonts TextStyles in remaining widgets"
```

---

### Task 6: Keystroke Debouncing - SemesterCard

**Files:**
- Modify: `lib/widgets/semester_card.dart`

**Interfaces:**
- Consumes: Timer, cgpaProvider
- Produces: Debounced onChanged handler

- [ ] **Step 1: Read the current file**

Read `lib/widgets/semester_card.dart` and understand the onChanged handler.

- [ ] **Step 2: Add Timer field and debounce logic**

Add field to `_SemesterCardState`:

```dart
Timer? _debounce;
```

- [ ] **Step 3: Update onChanged handler**

Replace the onChanged handler with debounced version:

```dart
onChanged: (value) {
  _debounce?.cancel();
  _debounce = Timer(Duration(milliseconds: 300), () {
    final gpa = double.tryParse(value);
    if (gpa != null && gpa >= 0 && gpa <= 4.0) {
      ref.read(cgpaProvider.notifier).updateSemester(
        id: widget.semester.id,
        name: widget.semester.name,
        gpa: gpa,
      );
    }
  });
},
```

- [ ] **Step 4: Add dispose method**

Add dispose method to cancel timer:

```dart
@override
void dispose() {
  _debounce?.cancel();
  _nameController.dispose();
  _gpaController.dispose();
  _nameFocus.dispose();
  _gpaFocus.dispose();
  super.dispose();
}
```

- [ ] **Step 5: Run app and test typing**

Run: `flutter run -d windows`
Test: Type quickly in GPA field, verify no lag, data saves after pause.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/semester_card.dart
git commit -m "perf: add debounce to SemesterCard GPA input"
```

---

## Phase 2: High Priority Fixes

### Task 7: Remove RepaintBoundary from Static Widgets

**Files:**
- Modify: `lib/widgets/mesh_gradient_background.dart`
- Modify: `lib/widgets/hero_gpa_card.dart`
- Modify: `lib/widgets/semester_card.dart`

**Interfaces:**
- Consumes: RepaintBoundary widget
- Produces: Optimized widget tree

- [ ] **Step 1: Read mesh_gradient_background.dart**

Read file and locate RepaintBoundary wrapper.

- [ ] **Step 2: Remove RepaintBoundary from mesh_gradient_background.dart**

Remove the RepaintBoundary wrapper, keep the Container.

- [ ] **Step 3: Read hero_gpa_card.dart**

Read file and locate RepaintBoundary wrapper.

- [ ] **Step 4: Remove RepaintBoundary from hero_gpa_card.dart**

Remove the RepaintBoundary wrapper, keep the content.

- [ ] **Step 5: Read semester_card.dart**

Read file and locate RepaintBoundary wrapper.

- [ ] **Step 6: Remove RepaintBoundary from semester_card.dart**

Remove the RepaintBoundary wrapper, keep the content.

- [ ] **Step 7: Run app and verify**

Run: `flutter run -d windows`
Verify: All screens render correctly, no visual changes.

- [ ] **Step 8: Commit**

```bash
git add lib/widgets/mesh_gradient_background.dart lib/widgets/hero_gpa_card.dart lib/widgets/semester_card.dart
git commit -m "perf: remove RepaintBoundary from static widgets"
```

---

### Task 8: Type the Stats Return Value

**Files:**
- Modify: `lib/providers/semester_provider.dart`

**Interfaces:**
- Consumes: _calculateStats function
- Produces: Typed GpaStats record

- [ ] **Step 1: Read the current file**

Read `lib/providers/semester_provider.dart` and locate _calculateStats function.

- [ ] **Step 2: Define typed record**

Add typed record definition before the function:

```dart
typedef GpaStats = ({
  double cgpa,
  double semesterGpa,
  int totalCredits,
  double qualityPoints,
});
```

- [ ] **Step 3: Update _calculateStats signature**

Change function signature to return typed record:

```dart
GpaStats _calculateStats(List<Semester> semesters) {
  // ... existing implementation
  return (
    cgpa: calculatedCgpa,
    semesterGpa: calculatedSemesterGpa,
    totalCredits: totalCredits,
    qualityPoints: qualityPoints,
  );
}
```

- [ ] **Step 4: Update callers**

Update all callers to use typed record fields instead of dynamic access.

- [ ] **Step 5: Run app and verify**

Run: `flutter run -d windows`
Verify: GPA calculations work correctly.

- [ ] **Step 6: Commit**

```bash
git add lib/providers/semester_provider.dart
git commit -m "perf: type _calculateStats return value as GpaStats record"
```

---

### Task 9: TabController Lifecycle Fix

**Files:**
- Modify: `lib/screens/marks_sheet_screen.dart`

**Interfaces:**
- Consumes: TabController, marksSheetProvider
- Produces: Properly lifecycle-managed TabController

- [ ] **Step 1: Read the current file**

Read `lib/screens/marks_sheet_screen.dart` and locate TabController creation in build().

- [ ] **Step 2: Move TabController to didChangeDependencies()**

Remove TabController creation from build() and add to didChangeDependencies():

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final semCount = ref.read(marksSheetProvider).semesters.length;
  if (_tabController == null || _tabController!.length != semCount) {
    final oldIndex = _tabController?.index ?? ref.read(marksSheetProvider).selectedIndex;
    _tabController?.dispose();
    _tabController = TabController(
      length: semCount,
      vsync: this,
      initialIndex: oldIndex.clamp(0, semCount - 1),
    );
    _tabController!.addListener(() {
      if (!_tabController!.indexIsChanging) {
        ref.read(marksSheetProvider.notifier).selectSemester(_tabController!.index);
      }
    });
  }
}
```

- [ ] **Step 3: Update build() to use existing _tabController**

Remove the TabController creation logic from build(), keep only the usage.

- [ ] **Step 4: Run app and verify**

Run: `flutter run -d windows`
Verify: Tab navigation works correctly, no visual glitches.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/marks_sheet_screen.dart
git commit -m "perf: move TabController to didChangeDependencies lifecycle"
```

---

## Phase 3: Medium Priority Fixes

### Task 10: SharedPreferences Caching

**Files:**
- Modify: `lib/providers/semester_provider.dart`

**Interfaces:**
- Consumes: SharedPreferences
- Produces: Cached SharedPreferences instance

- [ ] **Step 1: Read the current file**

Read `lib/providers/semester_provider.dart` and locate SharedPreferences usage.

- [ ] **Step 2: Add cached instance getter**

Add helper method to each notifier:

```dart
SharedPreferences? _prefs;

Future<SharedPreferences> _getPrefs() async {
  _prefs ??= await SharedPreferences.getInstance();
  return _prefs!;
}
```

- [ ] **Step 3: Update _save methods**

Replace `SharedPreferences.getInstance()` calls with `_getPrefs()`:

```dart
Timer(Duration(milliseconds: 500), () async {
  final prefs = await _getPrefs();
  final json = state.toJson();
  await prefs.setString('semester_cache_v1', jsonEncode(json));
});
```

- [ ] **Step 4: Run app and verify persistence**

Run: `flutter run -d windows`
Verify: Data saves and loads correctly on app restart.

- [ ] **Step 5: Commit**

```bash
git add lib/providers/semester_provider.dart
git commit -m "perf: cache SharedPreferences instance in providers"
```

---

### Task 11: Remove print() Statements

**Files:**
- Modify: `lib/providers/semester_provider.dart`

**Interfaces:**
- Consumes: print() statements
- Produces: Clean production code

- [ ] **Step 1: Read the current file**

Read `lib/providers/semester_provider.dart` and locate print() statements.

- [ ] **Step 2: Remove print() statements**

Remove or replace with debugPrint() on lines 88 and 314:

```dart
// Before:
print('Error loading from local: $e');

// After: (remove entirely or use debugPrint for debug builds only)
debugPrint('Error loading from local: $e');
```

- [ ] **Step 3: Run app and verify**

Run: `flutter run -d windows`
Verify: App loads data correctly, no console errors.

- [ ] **Step 4: Commit**

```bash
git add lib/providers/semester_provider.dart
git commit -m "chore: remove print() statements from production code"
```

---

### Task 12: Course Lookup Optimization

**Files:**
- Modify: `lib/screens/marks_sheet_screen.dart`

**Interfaces:**
- Consumes: marksSheetProvider, course lookup
- Produces: O(1) course lookup via Map

- [ ] **Step 1: Read the current file**

Read `lib/screens/marks_sheet_screen.dart` and locate the O(n*m) firstWhere lookup.

- [ ] **Step 2: Create course lookup map**

In the _SemesterTab build method, create a map before the lookup:

```dart
final courseMap = {
  for (var s in ref.read(marksSheetProvider).semesters)
    for (var c in s.courses) c.id: c
};
```

- [ ] **Step 3: Replace firstWhere with map lookup**

Replace:
```dart
course = ref.read(marksSheetProvider).semesters
    .expand((s) => s.courses)
    .firstWhere((c) => c.id == courseId);
```

With:
```dart
course = courseMap[courseId];
```

- [ ] **Step 4: Run app and verify**

Run: `flutter run -d windows`
Verify: Marks sheet displays correctly with course data.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/marks_sheet_screen.dart
git commit -m "perf: optimize course lookup with Map instead of firstWhere"
```

---

### Task 13: Timer Dispose in Notifiers

**Files:**
- Modify: `lib/providers/semester_provider.dart`

**Interfaces:**
- Consumes: _saveTimer, dispose() lifecycle
- Produces: Properly disposed timers

- [ ] **Step 1: Read the current file**

Read `lib/providers/semester_provider.dart` and locate _saveTimer fields.

- [ ] **Step 2: Add dispose() to SemesterNotifier**

Add dispose method:

```dart
@override
void dispose() {
  _saveTimer?.cancel();
  super.dispose();
}
```

- [ ] **Step 3: Add dispose() to CgpaNotifier**

Add dispose method:

```dart
@override
void dispose() {
  _saveTimer?.cancel();
  super.dispose();
}
```

- [ ] **Step 4: Add dispose() to MarksSheetNotifier**

Add dispose method:

```dart
@override
void dispose() {
  _saveTimer?.cancel();
  super.dispose();
}
```

- [ ] **Step 5: Run app and verify**

Run: `flutter run -d windows`
Verify: App functions correctly, no timer-related errors.

- [ ] **Step 6: Commit**

```bash
git add lib/providers/semester_provider.dart
git commit -m "perf: add dispose() to cancel _saveTimer in notifiers"
```

---

## Phase 4: Cleanup

### Task 14: Remove Dead Dependency

**Files:**
- Modify: `pubspec.yaml`

**Interfaces:**
- Consumes: pubspec.yaml
- Produces: Cleaned dependencies

- [ ] **Step 1: Read pubspec.yaml**

Read `pubspec.yaml` and locate flutter_animate dependency.

- [ ] **Step 2: Remove flutter_animate**

Remove the following line from dependencies:

```yaml
flutter_animate: ^4.5.2
```

- [ ] **Step 3: Run flutter pub get**

Run: `flutter pub get`

- [ ] **Step 4: Run app and verify**

Run: `flutter run -d windows`
Verify: App builds and runs correctly.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: remove unused flutter_animate dependency"
```

---

### Task 15: Remove Dead Widget

**Files:**
- Delete: `lib/widgets/semester_selector.dart`

**Interfaces:**
- Consumes: semester_selector.dart
- Produces: Removed dead code

- [ ] **Step 1: Verify widget is unused**

Search for imports of semester_selector.dart:
```
grep -r "semester_selector" lib/
```

- [ ] **Step 2: Delete the file**

Delete `lib/widgets/semester_selector.dart`

- [ ] **Step 3: Run app and verify**

Run: `flutter run -d windows`
Verify: App builds and runs correctly.

- [ ] **Step 4: Commit**

```bash
git rm lib/widgets/semester_selector.dart
git commit -m "chore: remove unused SemesterSelector widget"
```

---

### Task 16: Remove Dead Asset

**Files:**
- Delete: `assets/logo_mckru.jpg`
- Modify: `pubspec.yaml`

**Interfaces:**
- Consumes: logo_mckru.jpg, pubspec.yaml
- Produces: Removed dead asset

- [ ] **Step 1: Verify asset is unused**

Search for references to logo_mckru.jpg:
```
grep -r "logo_mckru" lib/
```

- [ ] **Step 2: Delete the asset file**

Delete `assets/logo_mckru.jpg`

- [ ] **Step 3: Update pubspec.yaml if needed**

If the asset is listed in pubspec.yaml assets section, remove it.

- [ ] **Step 4: Run app and verify**

Run: `flutter run -d windows`
Verify: App builds and runs correctly.

- [ ] **Step 5: Commit**

```bash
git rm assets/logo_mckru.jpg
git commit -m "chore: remove unused logo_mckru.jpg asset"
```

---

### Task 17: Fix Dead Conditional in empty_state.dart

**Files:**
- Modify: `lib/widgets/empty_state.dart`

**Interfaces:**
- Consumes: empty_state.dart
- Produces: Fixed conditional

- [ ] **Step 1: Read the current file**

Read `lib/widgets/empty_state.dart` and locate the dead conditional.

- [ ] **Step 2: Fix the conditional**

Replace:
```dart
color: isDark ? const Color(0x0D6366F1) : const Color(0x0D6366F1),
```

With:
```dart
color: const Color(0x0D6366F1),
```

- [ ] **Step 3: Run app and verify**

Run: `flutter run -d windows`
Verify: Empty state displays correctly.

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/empty_state.dart
git commit -m "chore: fix dead conditional in empty_state.dart"
```

---

## Final Verification

### Task 18: Full App Testing

**Files:**
- All modified files

**Interfaces:**
- Consumes: All previous tasks
- Produces: Verified optimized app

- [ ] **Step 1: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors or warnings.

- [ ] **Step 2: Run app on device**

Run: `flutter run -d windows`
Test all features:
- Splash screen animation
- GPA mode - add/edit courses
- CGPA mode - add/edit semesters
- Marks sheet - enter marks, calculate grades
- PDF export
- Theme toggle (dark/light)
- Data persistence (restart app)

- [ ] **Step 3: Performance verification**

Use Flutter DevTools to verify:
- Reduced widget rebuilds
- No unnecessary state updates during typing
- Stable memory usage

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "perf: complete performance optimization"
```

---

## Summary

**Total Tasks:** 18
**Estimated Time:** 2-3 hours
**Impact:** Significant performance improvement across the app

**Critical Fixes:**
- GoogleFonts caching (64 occurrences)
- Keystroke debouncing
- GlobalKey anti-pattern fix

**High Priority:**
- RepaintBoundary optimization
- Stats provider optimization
- TabController lifecycle fix

**Medium Priority:**
- SharedPreferences caching
- Print statement removal
- Course lookup optimization
- Timer dispose

**Cleanup:**
- Dead dependency removal
- Dead widget removal
- Dead asset removal
- Dead conditional fix
