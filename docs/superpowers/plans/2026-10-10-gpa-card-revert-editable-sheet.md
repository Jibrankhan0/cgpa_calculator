# GPA Card Revert + Editable Sheet Table Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore the GPA page subject card to its pre-Excel-feature form (single Marks field /100, lab /50 with ×2, credits, lab toggle) and move component entry (Mid /25, Final /50, Sectional /25, Lab /50) into the Data page table as Excel-like editable cells.

**Architecture:** One entry mode per subject, decided by what the user last typed: typing the GPA card's Marks field switches the subject to legacy mode (sets `legacyMarks`, clears the four component fields); editing any component cell on the Data table switches it to component mode (sets that component, clears `legacyMarks`). `SheetCalc` already gives components precedence when present, so clearing the other side keeps display and math always consistent with the user's last input. The grade math stays untouched (`percentOf` = components sum / max, or legacy marks with lab ×2, → `GpaService.getGradeFromMarks`).

**Tech Stack:** Flutter 3.41.6 / Dart 3.11.4, provider, shared_preferences; no new dependencies.

**Spec:** `docs/superpowers/specs/2026-10-09-excel-semester-sheet-design.md` (amended by user decision 2026-10-10 — see Task 3)

**User decisions driving this plan:**
1. "GPA page waisa hi chahiye jaisa pehle tha" — GPA card reverts to single Marks field.
2. "Editable table (Data page) — Excel jaisa" — Mid/Final/Sectional/Lab typed directly in the Data table cells.

## Global Constraints

- **NO git commits anywhere in this plan (session-wide rule).** Every task ends with gates: `flutter analyze` (expect `No issues found!`) and `flutter test` (expect all green). Do not run any `git` command.
- Never modify: `lib/services/gpa_service.dart`, `lib/main.dart`, `lib/widgets/staggered_animation.dart`. (`app_data.dart` is NOT touched by this plan at all.)
- Grade math input is always a **percent 0–100** fed to `GpaService.getGradeFromMarks` — thresholds never change; all grading continues through `SheetCalc`.
- Mode-switch rule (binding): Marks edit on GPA card → `legacyMarks` set + `mid/finalMarks/sectional/lab` all cleared. Component cell edit on Data table → that component set + `legacyMarks` cleared (`''`).
- Prefs: only `mckru_sheet_v1` written (by existing `AppData`; this plan adds no keys).
- New dependencies: **none**.
- `.withValues(alpha:)` (never `withOpacity`).
- Overflow/input rules: numeric inputs digits-only `FilteringTextInputFormatter` + clamp-on-change; Marks field keeps the legacy decimal formatter `^\d{0,3}\.?\d{0,1}$`; names `maxLines: 1` + ellipsis; chips row horizontal `ListView`.
- GPA cards keep `StaggeredAnimation(index: i, child: AnimatedCardFrame(key: ValueKey(subject.id), ...))`, single-flight `_exitId`/`_exitSemesterId` delete flow, `_knownIds`/`_seededSemesterId` enter seeding, and `dispose()` finishing an in-flight exit.
- All tests currently in `test/widget_test.dart` stay in the suite; the exact rewrites are given verbatim below.

### File structure

| File | Responsibility | Tasks |
|---|---|---|
| `lib/screens/gpa_page.dart` | Revert subject card to single Marks field; mode-switch clearing | 1 |
| `test/widget_test.dart` | Count rewrites + marks-field test (Task 1); Data-edit test (Task 2) | 1, 2 |
| `lib/screens/storage_page.dart` | Editable component cells in the sheet table | 2 |
| `test/widget_test.dart` (same) | New Data-page editing test | 2 |
| `docs/superpowers/specs/...-design.md` | Append user-decision amendment note | 3 |

---

### Task 1: GPA page card reverts to single Marks field

**Files:**
- Modify: `lib/screens/gpa_page.dart`
- Modify: `test/widget_test.dart` (2 count assertions rewritten verbatim; 1 test rewritten verbatim)

**Interfaces:**
- Consumes (unchanged): `AppData.activeSemester/subjects/updateSubject`, `SheetCalc.gradeOf(SubjectRecord)` (legacy path: `percentOf` returns `legacyMarks`, lab ×2), `GpaService.validateMarks(String, {bool isLab})`, `GpaService.getGradeFromMarks`, `fieldInput(BuildContext, {hint, error})`, `InputError`, `FieldLabel`, `GradeChip` from `ui.dart`.
- Produces (for Task 2/3): GPA card no longer contains component fields; `_SubjectCard._copyWith` gains `marks` (legacy-mode setter with component clearing) and drops `mid/finalMarks/sectional/lab` params; `_MarksField` class and `_clamp` deleted; the dead `semesterId` field on `_SubjectCard` removed.

- [ ] **Step 1: Rewrite the three affected tests first (RED)**

In `test/widget_test.dart`, apply these edits exactly:

1. Line ~171 (`GPA: deleting a subject waits for the exit animation`):

```dart
    expect(added, initial + 2,
        reason: 'new subject card contributes 2 text fields (name + marks)');
```
(replaces `expect(added, initial + 4, reason: 'new subject card contributes 4 text fields (name + mid + final + sectional)');`)

2. Line ~208 (`GPA: deleting the first card leaves the next card fully visible`):

```dart
    expect(tester.widgetList(find.byType(TextField)).length, 4,
        reason: 'two subject cards mounted, 2 fields each');
```
(replaces `expect(..., 8, reason: 'two subject cards mounted, 4 fields each');`)

3. Replace the whole test `GPA: component fields compute total and grade, clamped to max` (lines ~443-477) with:

```dart
  testWidgets('GPA: single marks field grades like before and validates max', (tester) async {
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

    final fields = find.byType(TextField); // [name, marks]
    await tester.enterText(fields.at(1), '75');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('B+ · 3.30'), findsOneWidget,
        reason: '75 marks grade like the old GPA page');

    await tester.enterText(fields.at(1), '150');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Marks must be 0-100'), findsOneWidget,
        reason: 'legacy validateMarks error still shows');
  });
```

- [ ] **Step 2: Run tests to confirm RED**

Run: `flutter test test/widget_test.dart --plain-name "GPA"`
Expected: the 3 edited tests FAIL (field counts + missing marks assertions); others in the filtered run pass.

- [ ] **Step 3: Revert `_SubjectCard` in `lib/screens/gpa_page.dart`**

3a. In `_SubjectCardState`: add a marks controller alongside the name controller:

```dart
  late TextEditingController _nameController;
  late TextEditingController _marksController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject.name);
    _marksController = TextEditingController(text: widget.subject.legacyMarks);
  }
```

In `didUpdateWidget`, add the legacy sync (after the name sync):

```dart
    if (oldWidget.subject.legacyMarks != widget.subject.legacyMarks &&
        widget.subject.legacyMarks != _marksController.text) {
      _marksController.text = widget.subject.legacyMarks;
    }
```

In `dispose`, add `_marksController.dispose();` before `super.dispose();`.

3b. Replace the entire `_copyWith` with:

```dart
  SubjectRecord _copyWith({String? name, String? marks, int? credits, bool? isLab}) {
    final typedMarks = marks != null;
    return SubjectRecord(
      id: widget.subject.id,
      name: name ?? widget.subject.name,
      credits: credits ?? widget.subject.credits,
      isLab: isLab ?? widget.subject.isLab,
      legacyMarks: marks ?? widget.subject.legacyMarks,
      // Typing marks switches the subject back to legacy mode: component
      // fields are cleared so SheetCalc grades from the marks just typed.
      mid: typedMarks ? '' : widget.subject.mid,
      finalMarks: typedMarks ? '' : widget.subject.finalMarks,
      sectional: typedMarks ? '' : widget.subject.sectional,
      lab: typedMarks ? '' : widget.subject.lab,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final isLab = widget.subject.isLab;
    final grade = SheetCalc.gradeOf(widget.subject);
    final cr = widget.subject.credits;
    final error = GpaService.validateMarks(widget.subject.legacyMarks, isLab: isLab);
```
(drops the `total`/`max`/`totalText` locals)

3c. Delete the `String _clamp(String v, int max) {...}` method entirely.

3d. Replace the `Wrap(spacing: 8, runSpacing: 8, children: [ _MarksField(... Mid ...), _MarksField(... Final ...), _MarksField(... Sectional ...), if (isLab) _MarksField(... Lab ...), ])` block (and its preceding `const SizedBox(height: 8),`) with:

```dart
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(child: FieldLabel(text: 'Marks')),
                SizedBox(
                  width: 96,
                  child: TextField(
                    controller: _marksController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}\.?\d{0,1}$')),
                    ],
                    decoration: fieldInput(context, hint: '0', error: error != null),
                    style: numStyle(14, FontWeight.w700, p.fg),
                    onChanged: (v) => widget.onChanged(_copyWith(marks: v)),
                  ),
                ),
                const SizedBox(width: 8),
                Text('/ ${isLab ? 50 : 100}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.muted)),
              ],
            ),
            if (error != null) InputError(message: error),
```

3e. In the footer Row, remove the total block:

```dart
                  if (totalText != null) ...[
                    Text(totalText, style: numStyle(12.5, FontWeight.w800, p.fg)),
                    const SizedBox(width: 8),
                  ],
```
(footer returns to: weight text in `Expanded` + `GradeChip` / `'— pending'` container — leave those untouched)

3f. Delete the whole `_MarksField` widget (`class _MarksField extends StatefulWidget` through its `State` class end).

3g. Remove the dead `semesterId` param: delete `final String semesterId;` from `_SubjectCard`, `required this.semesterId,` from its constructor, and `semesterId: active.id,` at the `_SubjectCard(...)` call site (~line 121).

- [ ] **Step 4: Run tests to verify GREEN**

Run: `flutter test test/widget_test.dart --plain-name "GPA"`
Expected: all GPA tests pass, including the rewritten `single marks field grades like before and validates max`.

- [ ] **Step 5: Full gates**

Run: `flutter analyze` → Expected `No issues found!`
Run: `flutter test` → Expected all green (33 tests).

---

### Task 2: Data page table becomes editable (component entry)

**Files:**
- Modify: `lib/screens/storage_page.dart`
- Modify: `test/widget_test.dart` (one new test appended)

**Interfaces:**
- Consumes (unchanged): `AppData.updateSubject(String semesterId, SubjectRecord updated)` (notifier; rebuilds watchers), `SheetCalc` (total/grade recompute automatically on rebuild), `SubjectRecord(id, name, credits, isLab, mid, finalMarks, sectional, lab, legacyMarks)` constructor.
- Produces: private `_CellField` stateful cell widget (controller-sync pattern mirroring the old `_MarksField`, plus direct clamp-write) and `_editComponent` helper (mode-switch clearing); passes `data` into `_SheetTable`.

- [ ] **Step 1: Write the failing test first (RED)**

Append before the final `}` of `test/widget_test.dart` (imports already include `dart:convert` and provider — no import changes needed):

```dart
  testWidgets('Data page: editing a component cell updates totals, clamps, and clears legacy marks',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'mckru_onboarded2': true,
      'mckru_name': 'Ali',
      'mckru_sheet_v1': jsonEncode([
        {
          'id': 'sem1',
          'name': 'Semester 1',
          'legacyGpa': '',
          'subjects': [
            {
              'id': 'a', 'name': 'Physics', 'credits': 3, 'isLab': false,
              'mid': '', 'final': '', 'sectional': '', 'lab': '', 'legacyMarks': '75'
            },
          ],
        }
      ]),
    });
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    await tester.tap(find.text('Data'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.text('75'), findsOneWidget,
        reason: 'legacy marks show in the Total column before any edit');

    final cells = find.byType(TextField); // [mid, final, sectional] (non-lab row)
    await tester.enterText(cells.at(0), '20');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('F'), findsOneWidget,
        reason: 'component edit cleared legacy marks, 20% totals to F');
    expect(find.text('75'), findsNothing,
        reason: 'legacy total replaced by component mode');

    await tester.enterText(cells.at(0), '999');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.widgetWithText(TextField, '25'), findsOneWidget,
        reason: 'mid clamps to its 25 max');
    expect(find.text('25'), findsWidgets, reason: 'total reflects clamped mid');
  });
```

- [ ] **Step 2: Run test to confirm RED**

Run: `flutter test test/widget_test.dart --plain-name "Data page: editing"`
Expected: FAIL — `Found 0 widgets with TextField` (table cells are not TextFields yet) or first `expect` failure.

- [ ] **Step 3: Implement editable cells in `lib/screens/storage_page.dart`**

3a. Add import at top (after the existing material/provider imports):

```dart
import 'package:flutter/services.dart';
```

3b. In `_StoragePageState.build`, pass data into the table (~line 95):

```dart
              child: _SheetTable(semester: selected, palette: p, data: data),
```

3c. Change `_SheetTable` declaration to include `data`:

```dart
class _SheetTable extends StatelessWidget {
  final SemesterRecord semester;
  final Palette palette;
  final AppData data;

  const _SheetTable({required this.semester, required this.palette, required this.data});
```

3d. Add the mode-switch helper as a private function inside `storage_page.dart` (top-level below the page class, or a static on `_SheetTable` — top-level is fine):

```dart
SubjectRecord _editComponent(
  SubjectRecord sub, {
  String? mid,
  String? finalMarks,
  String? sectional,
  String? lab,
}) {
  return SubjectRecord(
    id: sub.id,
    name: sub.name,
    credits: sub.credits,
    isLab: sub.isLab,
    mid: mid ?? sub.mid,
    finalMarks: finalMarks ?? sub.finalMarks,
    sectional: sectional ?? sub.sectional,
    lab: lab ?? sub.lab,
    // Editing a component switches the subject to component mode: legacy
    // marks are cleared so SheetCalc grades only from what is typed here.
    legacyMarks: '',
  );
}
```

3e. In `_SheetTable.build`, replace the four component `_cell(...)` lines in the subject-row builder:

```dart
        _cell('${SheetCalc.creditsOf(sub)}', numeric: true),
        _editCell(sub, 2, 'mid', 25),
        _editCell(sub, 3, 'finalMarks', 50),
        _editCell(sub, 4, 'sectional', 25),
        sub.isLab
            ? _editCell(sub, 5, 'lab', 50)
            : _cell('—', numeric: true),
```
(the `mid/final/sectional/lab` `_cell(...)` lines are replaced by `_editCell(...)`; the CR, name, TOTAL, GRADE, and footer cells are unchanged)

Then add the `_editCell` builder method to `_SheetTable` (column numbers documented above match the `columnWidths` map: 2=MID 42, 3=FINAL 46, 4=SEC 42, 5=LAB 42):

```dart
  Widget _editCell(SubjectRecord sub, int column, String field, int max) {
    final String value;
    switch (field) {
      case 'mid':
        value = sub.mid;
      case 'finalMarks':
        value = sub.finalMarks;
      case 'sectional':
        value = sub.sectional;
      default:
        value = sub.lab;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
      child: Center(
        child: _CellField(
          key: ValueKey('${sub.id}_$field'),
          value: value,
          max: max,
          onSet: (v) => data.updateSubject(
            semester.id,
            _editComponent(
              sub,
              mid: field == 'mid' ? v : null,
              finalMarks: field == 'finalMarks' ? v : null,
              sectional: field == 'sectional' ? v : null,
              lab: field == 'lab' ? v : null,
            ),
          ),
        ),
      ),
    );
  }
```

3f. Append the `_CellField` widget at the bottom of `storage_page.dart`:

```dart
class _CellField extends StatefulWidget {
  final String value;
  final int max;
  final ValueChanged<String> onSet;

  const _CellField({super.key, required this.value, required this.max, required this.onSet});

  @override
  State<_CellField> createState() => _CellFieldState();
}

class _CellFieldState extends State<_CellField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _CellField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return SizedBox(
      width: 40,
      child: TextField(
        controller: _controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
          hintText: '—',
          hintStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: p.muted),
        ),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF334155)),
        onChanged: (v) {
          var out = v;
          final n = int.tryParse(v);
          if (v.isNotEmpty && (n == null || n > widget.max)) {
            out = n == null ? '' : '${widget.max}';
          }
          widget.onSet(out);
          if (out != v) {
            _controller.text = out;
            _controller.selection = TextSelection.collapsed(offset: out.length);
          }
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify GREEN**

Run: `flutter test test/widget_test.dart --plain-name "Data page"`
Expected: all 4 Data-page tests pass (render, export button, empty state, new editing test).

- [ ] **Step 5: Full gates**

Run: `flutter analyze` → Expected `No issues found!`
Run: `flutter test` → Expected all green (34 tests).

---

### Task 3: Final verification + spec amendment + server + device

**Files:**
- Modify: `docs/superpowers/specs/2026-10-09-excel-semester-sheet-design.md` (append only)
- No code files.

- [ ] **Step 1: Full automated gates**

Run: `flutter analyze` → Expected `No issues found!`
Run: `flutter test` → Expected all green (34 tests).

- [ ] **Step 2: Append the amendment note to the spec**

Append at the end of `docs/superpowers/specs/2026-10-09-excel-semester-sheet-design.md`:

```markdown

## Amendment (2026-10-10, user decision)

- GPA page subject card reverts to the pre-sheet single Marks field (out of 100; lab out of 50 with ×2) — component fields are removed from the card.
- Component entry (Mid /25, Final /50, Sectional /25, Lab /50) is done by editing cells directly in the Data page table (Excel-like editable cells).
- One entry mode per subject: typing Marks clears component fields; editing a component cell clears `legacyMarks`.
```

- [ ] **Step 3: Restart the web dev server**

Kill any listener on port 8750, then start:

```powershell
Start-Process -FilePath "flutter" -ArgumentList "run","-d","web-server","--web-port=8750","--no-hot" -WorkingDirectory "C:\All Flutter Project\cgpa_calculator" -WindowStyle Hidden -RedirectStandardOutput "run_web.log" -RedirectStandardError "run_web.err.log"
```
Verify `http://127.0.0.1:8750` returns HTTP 200.

- [ ] **Step 4: Reinstall on the Vivo phone**

Kill the existing `flutter run` process (device e925f74a), then:

```powershell
Start-Process -FilePath "flutter" -ArgumentList "run","-d","e925f74a" -WorkingDirectory "C:\All Flutter Project\cgpa_calculator" -WindowStyle Hidden -RedirectStandardOutput "run_vivo.log" -RedirectStandardError "run_vivo.err.log"
```
Wait for install; confirm `run_vivo.log` shows the app launching (no BUILD FAILED).

- [ ] **Step 5: Hand the user the visual checklist**

1. GPA page: har card mein sirf **Marks** field (`/ 100`, lab pe `/ 50`), credit chips, lab toggle, footer grade chip — bilkul pehle jaisa; `150` likhne pe error; components wale subject ka marks field empty ho (Data pe type kiya hai toh).
2. Data page: table ke MID/FINAL/SEC/LAB cells mein seedha type karein (digits only, clamp: 25/50/25/50); TOTAL + GRADE live update; marks field edit karne pe wapas component cells clear.
3. CGPA page + Export Excel: unchanged, still working.
4. No overflow at smallest phone width; `flutter analyze`/`flutter test` green.

- [ ] **Step 6: Report**

Summarize analyze/test counts + checklist. **No commits** — leave changes staged per session rule.
