# Task 1 Report: GPA page card reverts to single Marks field

**Status:** DONE
**Date:** 2026-10-10

## What I implemented

Followed the brief's TDD order exactly: test rewrites (Step 1) → RED (Step 2) → implementation (Step 3) → GREEN (Step 4) → full gates (Step 5).

### Step 1 — Test rewrites in `test/widget_test.dart` (applied verbatim)
1. `GPA: deleting a subject waits for the exit animation`: `expect(added, initial + 4, ...)` → `expect(added, initial + 2, reason: 'new subject card contributes 2 text fields (name + marks)')`.
2. `GPA: deleting the first card leaves the next card fully visible`: field count `8` → `4`, reason `'two subject cards mounted, 2 fields each'`.
3. Replaced test `GPA: component fields compute total and grade, clamped to max` (lines ~443-477) with `GPA: single marks field grades like before and validates max` verbatim from the brief (one character adapted — see Deviation 1).

### Step 3 — Revert of `_SubjectCard` in `lib/screens/gpa_page.dart`
- **3a:** Added `_marksController` (init from `widget.subject.legacyMarks`), legacy sync block in `didUpdateWidget` (after name sync), `_marksController.dispose()` before `super.dispose()`.
- **3b:** Replaced `_copyWith` with the `({String? name, String? marks, int? credits, bool? isLab})` version — `typedMarks` clears `mid/finalMarks/sectional/lab` so typing marks switches back to legacy mode; replaced build locals with `grade`/`cr`/`error = GpaService.validateMarks(widget.subject.legacyMarks, isLab: isLab)` (dropped `total`/`max`/`totalText`).
- **3c:** Deleted `String _clamp(String v, int max)` entirely.
- **3d:** Replaced the `Wrap(... 4x _MarksField ...)` block (with its preceding `SizedBox(height: 8)`) with the single Marks `Row` (FieldLabel + 96-wide TextField + `/ 100` or `/ 50` suffix) plus `if (error != null) InputError(message: error)`.
- **3e:** Removed the `totalText` block from the footer Row (footer now: weight text in `Expanded` + `GradeChip` / `'— pending'`, untouched).
- **3f:** Deleted `class _MarksField` + `class _MarksFieldState` (whole widget).
- **3g:** Removed dead `semesterId`: field, constructor param, and `semesterId: active.id,` at the call site.

`lib/screens/storage_page.dart` untouched (Task 2). Read-only files (`gpa_service.dart`, `main.dart`, `staggered_animation.dart`) untouched. No git commands run.

## TDD Evidence

### RED
Command: `flutter test test/widget_test.dart --plain-name "GPA"` (after test rewrites, before implementation)

Failing output excerpt (full capture: `%TEMP%\opencode\red_gpa.txt`):
```
Expected: <6>
  Actual: <8>
new subject card contributes 2 text fields (name + marks)
00:09 +1 -1: GPA: deleting a subject waits for the exit animation [E]
...
Expected: <4>
  Actual: <8>
00:11 +1 -2: GPA: deleting the first card leaves the next card fully visible [E]
...
00:18 +6 -2: GPA: single marks field grades like before and validates max
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "B+ · 3.30": []>
75 marks grade like the old GPA page
00:20 +6 -3: GPA: single marks field grades like before and validates max [E]
00:20 +6 -3: Some tests failed.
```
**Why expected:** exactly the 3 edited tests failed — old card still mounts 4 fields/card (so `initial+2`, `4`, and marks-lookup asserts cannot hold); the other 6 GPA-filtered tests passed.

### GREEN (first run — surfaced Deviation 1)
Command: `flutter test test/widget_test.dart --plain-name "GPA"` (after Step 3)
```
00:10 +8: GPA: single marks field grades like before and validates max
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Marks must be 0-100": []>
legacy validateMarks error still shows
00:10 +8 -1: Some tests failed.
```
Grade assertion (`B+ · 3.30`) already passed; only the ASCII-hyphen mismatch failed → fixed per Deviation 1.

### GREEN (final)
Command: `flutter test test/widget_test.dart --plain-name "GPA"`
```
00:03 +1: GPA: deleting a subject waits for the exit animation
00:04 +2: GPA: deleting the first card leaves the next card fully visible
...
00:08 +8: GPA: single marks field grades like before and validates max
00:09 +9: (tearDownAll)
00:09 +9: All tests passed!
```
**9/9 GPA-filtered tests pass** (includes the 3 rewritten tests).

## Final gates

`flutter analyze`:
```
Analyzing cgpa_calculator...
No issues found! (ran in 127.1s)
```

`flutter test`:
```
00:20 +29: ... GPA: single marks field grades like before and validates max
00:22 +32: ... Data page: empty sheet renders empty state instead of crashing
00:22 +33: (tearDownAll)
00:22 +33: All tests passed!
```
**33/33 tests passing, analyze: No issues found!**

## Files changed
- `test/widget_test.dart` — 3 test edits (2 count assertions + 1 full test rewrite).
- `lib/screens/gpa_page.dart` — `_SubjectCard` reverted to single Marks field (506 → 404 lines).

## Deviations from the brief
1. **Error-string dash (brief vs. read-only code):** the brief's new test asserts `find.text('Marks must be 0-100')` with ASCII hyphen U+002D, but `lib/services/gpa_service.dart:65` (never-modify file) returns `'Marks must be 0–100'` with EN DASH U+2013 (verified byte-level: service char = U+2013, brief char = U+002D). The brief said apply edits exactly, but this is a genuine conflict with actual code, so I applied the test verbatim first (RED confirmed), then after the first GREEN run proved the mismatch (0 widgets found), changed the single character in the test to U+2013 (verified byte-level in the test file). `gpa_service.dart` unchanged. This is the only content deviation.
2. **Edit slip, self-corrected (no net deviation):** while applying Step 3e I accidentally *inserted* a duplicate `totalText` block (my `grade != null` anchor matched inside the footer's `Text(...)` widget). I caught it immediately on read-back and fixed it with a follow-up edit restoring the exact footer the brief specifies (weight text + GradeChip/'— pending', no `totalText`). Final code matches brief 3e exactly; both the interim file state and the fix are documented here.
3. **Line shifts:** brief's line hints were accurate for the test file (~171, ~208, ~443-477 all matched). In `gpa_page.dart` line numbers shifted as edits landed (506 → 404 lines); all content edits matched the brief's described anchors (Wrap block + preceding `SizedBox(height: 8)`, `_MarksField` class boundaries, `semesterId` at ~line 121 call site).

## Self-review findings
- Verified final `lib/screens/gpa_page.dart` line-by-line: no remaining references to `totalText`, `_MarksField`, `_clamp`, or `semesterId`; footer matches brief ("footer returns to: weight text in Expanded + GradeChip / '— pending'").
- `_copyWith` contract per brief: gains `marks` (legacy setter + component clearing), drops `mid/finalMarks/sectional/lab` params — ready for Task 2/3.
- Controller lifecycle: `_marksController` created in `initState`, synced in `didUpdateWidget` (guarded both by value-change and text mismatch), disposed in `dispose`.
- Decimal input formatter `^\d{0,3}\.?\d{0,1}$` + `numberWithOptions(decimal: true)` exactly as brief; `validateMarks` errors render via `InputError` and tint the field via `fieldInput(error: true)`.
- Read-only files untouched; `storage_page.dart` untouched; no git commands executed (edits left unstaged).
- Full suite (16 widget + 17 unit tests across 3 files) green: 33/33.
