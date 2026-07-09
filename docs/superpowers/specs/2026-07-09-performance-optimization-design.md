# Performance Optimization Design Spec

**Date:** 2026-07-09
**Author:** opencode
**Status:** Approved

## Overview

Comprehensive performance optimization for the CGPA Calculator Flutter app. The app currently has multiple performance issues including font recomputation on every build, unnecessary state updates during typing, and anti-patterns that cause memory overhead.

## Current Issues Summary

### Critical
1. GoogleFonts called 64 times in build() methods - recomputes font on every rebuild
2. GPA keystroke triggers full Riverpod state update via onChanged
3. GlobalKey anti-pattern for triggering child setState()

### High
4. RepaintBoundary on static widgets (MeshGradientBackground, HeroGpaCard, SemesterCard)
5. gpaStatsProvider watches full state causing unnecessary recalculations
6. TabController created inside build() method

### Medium
7. SharedPreferences.getInstance() called on every save
8. print() statements in production code
9. O(n*m) course lookup in _SemesterTab
10. _saveTimer not cancelled in notifier dispose()

### Low
11. Dead dependency: flutter_animate
12. Dead widget: semester_selector.dart
13. Dead asset: logo_mckru.jpg
14. Dead conditional in empty_state.dart

## Design

### Phase 1: Critical Performance Fixes

#### 1.1 GoogleFonts Caching
**Files affected:** All widget files (64 occurrences)

**Solution:** Cache TextStyle objects as static final fields in each widget class.

**Before:**
```dart
Text('Hello', style: GoogleFonts.lexend(fontSize: 24))
```

**After:**
```dart
static final _titleStyle = GoogleFonts.lexend(fontSize: 24);

// In build():
Text('Hello', style: _titleStyle)
```

**Impact:** Eliminates font recomputation on every rebuild. TextStyle objects are created once and reused.

#### 1.2 Keystroke Debouncing
**File:** `lib/widgets/semester_card.dart`

**Solution:** Add 300ms debounce to onChanged handler.

**Before:**
```dart
onChanged: (value) {
  ref.read(cgpaProvider.notifier).updateSemester(...);
}
```

**After:**
```dart
Timer? _debounce;

onChanged: (value) {
  _debounce?.cancel();
  _debounce = Timer(Duration(milliseconds: 300), () {
    ref.read(cgpaProvider.notifier).updateSemester(...);
  });
}

@override
void dispose() {
  _debounce?.cancel();
  super.dispose();
}
```

**Impact:** Reduces unnecessary Riverpod state updates by ~90% during typing.

#### 1.3 GlobalKey Anti-Pattern Fix
**File:** `lib/widgets/course_input_card.dart`

**Solution:** Replace GlobalKey with ValueNotifier for grade value.

**Before:**
```dart
final GlobalKey<_GradeBadgeLiveState> _gradeKey = GlobalKey();

_gradeKey.currentState?.setState(() {});
```

**After:**
```dart
final ValueNotifier<String> _gradeNotifier = ValueNotifier('');

// Pass grade to widget:
ValueListenableBuilder<String>(
  valueListenable: _gradeNotifier,
  builder: (context, grade, _) => GradeBadge(grade: grade),
)

// Update grade:
_gradeNotifier.value = calculatedGrade;
```

**Impact:** Proper reactive data flow, no fragile GlobalKey, better testability.

### Phase 2: High Priority Fixes

#### 2.1 RepaintBoundary Optimization
**Files:** `mesh_gradient_background.dart`, `hero_gpa_card.dart`, `semester_card.dart`

**Solution:** Remove RepaintBoundary from static widgets. Keep on CourseInputCard.

**Impact:** Reduces GPU layer overhead on low-end devices.

#### 2.2 Stats Provider Optimization
**File:** `lib/providers/semester_provider.dart`

**Solution:**
1. Add .select() to gpaStatsProvider to watch only necessary data
2. Type the _calculateStats return value

**Before:**
```dart
final gpaStatsProvider = Provider<GpaStats>((ref) {
  final state = ref.watch(semesterProvider); // Watches everything
  ...
});
```

**After:**
```dart
final gpaStatsProvider = Provider<GpaStats>((ref) {
  final mode = ref.watch(semesterProvider.select((s) => s.mode));
  if (mode == SemesterMode.gpa) {
    final semesters = ref.watch(semesterProvider.select((s) => s.semesters));
    ...
  } else {
    final semesters = ref.watch(cgpaProvider.select((s) => s.semesters));
    ...
  }
});
```

**Impact:** Prevents unnecessary recalculations when unrelated state changes.

#### 2.3 TabController Lifecycle Fix
**File:** `lib/screens/marks_sheet_screen.dart`

**Solution:** Move TabController creation to didChangeDependencies().

**Before:**
```dart
@override
Widget build(BuildContext context) {
  if (_tabController == null || _tabController!.length != semCount) {
    _tabController?.dispose();
    _tabController = TabController(length: semCount, vsync: this);
  }
  ...
}
```

**After:**
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final semCount = ref.read(marksSheetProvider).semesters.length;
  if (_tabController == null || _tabController!.length != semCount) {
    _tabController?.dispose();
    _tabController = TabController(length: semCount, vsync: this);
    _tabController!.addListener(() { ... });
  }
}
```

**Impact:** Prevents potential memory leaks and visual glitches.

### Phase 3: Medium Priority Fixes

#### 3.1 SharedPreferences Optimization
**File:** `lib/providers/semester_provider.dart`

**Solution:** Cache SharedPreferences instance.

**Before:**
```dart
Timer(Duration(milliseconds: 500), () async {
  final prefs = await SharedPreferences.getInstance();
  ...
});
```

**After:**
```dart
SharedPreferences? _prefs;

Future<SharedPreferences> getPrefs() async {
  _prefs ??= await SharedPreferences.getInstance();
  return _prefs!;
}

Timer(Duration(milliseconds: 500), () async {
  final prefs = await getPrefs();
  ...
});
```

**Impact:** Reduces async overhead on repeated saves.

#### 3.2 Remove print() Statements
**File:** `lib/providers/semester_provider.dart` (lines 88, 314)

**Solution:** Replace with debugPrint() or remove entirely.

**Impact:** Cleaner production logs, no debug noise.

#### 3.3 Course Lookup Optimization
**File:** `lib/screens/marks_sheet_screen.dart`

**Solution:** Replace O(n*m) firstWhere with Map lookup.

**Before:**
```dart
course = ref.read(marksSheetProvider).semesters
    .expand((s) => s.courses)
    .firstWhere((c) => c.id == courseId);
```

**After:**
```dart
// Create map once in build():
final courseMap = {
  for (var s in ref.read(marksSheetProvider).semesters)
    for (var c in s.courses) c.id: c
};

// Use map lookup:
course = courseMap[courseId];
```

**Impact:** O(1) lookup instead of O(n*m).

#### 3.4 Timer Dispose
**File:** `lib/providers/semester_provider.dart`

**Solution:** Add dispose() method to notifiers.

**Before:**
```dart
class SemesterNotifier extends Notifier<SemesterState> {
  Timer? _saveTimer;
  // No dispose
}
```

**After:**
```dart
class SemesterNotifier extends Notifier<SemesterState> {
  Timer? _saveTimer;

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
```

**Impact:** Prevents timer firing after disposal.

### Phase 4: Cleanup

#### 4.1 Dead Code Removal
- Remove `flutter_animate` from pubspec.yaml
- Delete `lib/widgets/semester_selector.dart`
- Delete `assets/logo_mckru.jpg`
- Fix dead conditional in `empty_state.dart`

#### 4.2 Production Code Cleanup
- Remove all print() statements
- Add error handling UI for SharedPreferences load failures

## Testing Strategy

1. **Manual testing:** Run app on device, verify smooth animations, no lag during typing
2. **Performance profiling:** Use Flutter DevTools to verify reduced rebuild counts
3. **Memory profiling:** Check for memory leaks after repeated navigation
4. **Build verification:** Ensure app builds successfully on all platforms

## Success Criteria

1. App runs smoothly without lag during GPA/CGPA input
2. No unnecessary widget rebuilds visible in Flutter DevTools
3. Memory usage stable during extended use
4. No visual regressions in UI
5. All existing functionality preserved

## Risk Assessment

- **Low risk:** Most changes are localized optimizations
- **Medium risk:** TabController lifecycle change needs careful testing
- **Mitigation:** Test each phase independently before proceeding
