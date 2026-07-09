# Task 1 Fix Report Round 2 — Final

## Fixes Applied

### Fix 1: Focus visual feedback — added `setState()` in all focus listeners
Each focus listener now wraps the boolean update in `setState(() { ... })` so the widget rebuilds and decorations update.
- `_midFocus` listener (line 116)
- `_finalFocus` listener (line 120)
- `_sessionalFocus` listener (line 124)
- `_totalFocus` listener (line 128)

### Fix 2: Real-time total and grade updates in `_buildMarkField.onChanged`
`onChanged` now computes the sum from all three mark controllers, clamps to 100, and writes to `_totalController.text`. The build method computes `liveGrade` via `GpaService.getGradeFromMarks()` from the controllers, so `GradeBadge` always shows the projected grade.

### Fix 3: Total field focus highlight
Fixed by Fix 1 — `_totalFocus` listener now calls `setState(() { _isTotalFocused = ... })`, so the total field's background and border colors rebuild on focus change.

### Fix 4: `didUpdateWidget` — course.id change handling
Added `if (oldWidget.course.id != widget.course.id)` branch that disposes and reinitializes all controllers via `_disposeControllers()` / `_initControllers()`. Extracted these as helper methods shared with `initState` and `dispose`.

### Fix 5: Total calculation reads from controllers, not stale widget
`_onMarksFocusLost` now reads all three values from the controllers directly (`_midController.text`, `_finalController.text`, `_sessionalController.text`) instead of using `widget.course.midMarks` etc. Each value is clamped individually, then the total is computed and clamped to 100.

## Test Results

- `flutter analyze` — No issues found (7 pre-existing info-level warnings in `semester_provider.dart`, none in `course_input_card.dart`)
- `flutter run -d windows` — Visual testing could not be performed (Visual Studio toolchain not available in this environment). Static analysis confirms all types resolve, no missing imports, and no dead code.

## Scope Contained

Only the following changes were made to `lib/widgets/course_input_card.dart`:
1. Static final TextStyle fields (preserved from original caching commit)
2. Replacement of inline GoogleFonts calls with `.copyWith()` (preserved)
3. `setState()` in focus listeners for proper rebuild
4. Real-time total + grade computation in build and onChanged
5. `didUpdateWidget` course.id guard + controller reinit helpers
6. Import of `gpa_service.dart` for grade computation
