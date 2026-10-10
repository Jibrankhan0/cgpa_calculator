# Design: Excel-style Semester Sheet (Saved Data rework)

**Date:** 2026-10-09
**Status:** Approved in brainstorming (layout C locked via visual companion; sections 1–2 approved)

## Problem

The Data page currently shows flat GPA records (subject + total marks) and manually typed semester GPA entries. The user wants a true records system: all semesters (8+) saved locally, shown as an Excel-like sheet with full per-subject breakdown — Mid /25, Final /50, Sectional /25, and Lab /50 when the subject has a lab — plus a real `.xlsx` export. The current model cannot represent this (no component marks, no subject→semester nesting).

## Decisions (from clarifying questions)

1. **Entry model:** Mid /25 + Final /50 + Sectional /25 entered separately per subject; total = sum. Lab subject additionally has Lab /50 → max /150.
2. **Nesting (Option A):** Subjects live inside semesters. GPA page edits the selected semester. CGPA becomes an auto-calculated list — manual GPA typing is removed.
3. **Marks scheme:** Mid 25, Final 50, Sectional 25 (= /100 theory); lab adds 50 (= /150 for lab subjects).
4. **Legacy data:** migrate (flat subjects → Semester 1; old manual semesters → legacy-GPA semesters).
5. **Export:** in-app Excel-like table **plus** real `.xlsx` export (deps: `excel`, `share_plus`).
6. **Semester selector:** chips row at the top of the GPA page + `+ Add`.
7. **Data page layout:** **C — semester chips + one table**, styled like the app (light, clean, cards, blue accent), confirmed visually in the mockup `data-sheet-v2.html`.
8. **Overflow safety (explicit user requirement):** no pixel overflow anywhere (details under "Overflow rules").

## Data model

`lib/providers/app_data.dart` is rewritten for this feature (user-approved; the never-modify constraint is lifted for this file only for this feature). `gpa_service.dart`, `main.dart`, `staggered_animation.dart` stay untouched.

```dart
class SubjectRecord {
  final String id;
  String name;
  int credits;          // default 3
  bool isLab;
  String mid;           // '' or digits, max 25
  String finalMarks;    // '' or digits, max 50
  String sectional;     // '' or digits, max 25
  String lab;           // '' or digits, max 50 (only meaningful when isLab)
  String legacyMarks;   // migrated pre-sheet records only; '' for new subjects
}

class SemesterRecord {
  final String id;
  String name;                    // 'Semester 1'..N default
  List<SubjectRecord> subjects;
  String legacyGpa;               // migrated manual entries only; '' otherwise
}
```

- Storage: new SharedPreferences key **`mckru_sheet_v1`** (JSON list of `SemesterRecord`). The 500 ms debounced save stays.
- `AppData` exposes `List<SemesterRecord> semesters`; existing mutation APIs are reworked to the new shape (add/remove/rename semester, add/remove/update subject within a semester).
- Prefs keys for profile/theme/onboarding (`mckru_dark2`, `mckru_onboarded2`, `mckru_name`, `mckru_avatar`) unchanged.
- Default names: new semester = `Semester ${n+1}`, new subject = `Subject ${n+1}` (per-semester count). Deleting a semester renumbers **only** names still matching `^Semester \d+$` (custom names survive — same guard introduced for the earlier name-clobber fix). Subject names are never renumbered (existing behavior).
- Old keys `mckru_gpa2` / `mckru_cgpa2` remain in prefs untouched after migration (backup).

### Computation (GpaService untouched)

- **Subject total:** sum of filled components. Theory max 100; lab subject max 150 (Mid+Final+Sectional+Lab).
- **Legacy subject:** components empty → total = `legacyMarks` (max follows isLab as before: lab 50 else 100).
- **Grade:** `percent = total / max * 100` → existing `GpaService.getGradeFromMarks(percent)`.
- **Semester GPA:** credits-weighted as today — `sum(grade.gpa * cr) / sum(cr)` where `cr = isLab ? 1 : credits`; only subjects whose total parses and grades non-null count.
- **CGPA:** average of semester GPAs that have a computable value (same spirit as today's `cgpa` getter). Semesters with only `legacyGpa` use that value.
- **Semester GPA display value:** computed GPA if subjects exist, else `legacyGpa`.

### Migration (runs once, inside `load()` when `mckru_sheet_v1` is absent)

1. Read `mckru_cgpa2` → each old semester becomes `SemesterRecord(name, subjects: [], legacyGpa: <old gpa>)`. If none, start with one default `Semester 1`.
2. Read `mckru_gpa2` → each old flat subject becomes a `SubjectRecord` appended to **semesters[0].subjects** with `legacyMarks = old.marks`, other component fields `''`.
3. Save `mckru_sheet_v1`. Old keys left in place.
4. Idempotent: if `mckru_sheet_v1` exists, old keys are never read again.

## Pages

### GPA page (entry)

- Top: **semester chips** — one per `SemesterRecord` + `+ Add` (adds a semester, selects it). Chips horizontally scrollable past ~6. Selected-chip state is GPA-page-local `String? _selectedSemesterId` defaulting to the first semester; falls back to first semester if the selected one is deleted.
- Subject card (keep `StaggeredAnimation` + `AnimatedCardFrame` enter/exit exactly as today):
  - Row 1: idx badge, name field, lab toggle chip, 🗑 (delete gated by `length > 1`, exit animation flow unchanged — `_exitId`/`onExitComplete` per subject id).
  - Row 2: compact numeric fields **Mid /25 · Final /50 · Sectional /25** (+ **Lab /50** only when `isLab`), digits-only input.
  - Row 3: live total (`84/100` or `122/150`), grade chip, credits control (existing pattern).
- `Add subject` topbar GhostButton adds to the selected semester.
- GPA footer/result card: computed semester GPA (existing `ResultCard`).

### CGPA page (auto)

- Header `ResultCard`: **Total CGPA** (auto).
- Per-semester cards: **name field (rename only — the single editable control on this page)**, subject count, computed GPA (or legacy), 🗑 delete with the same exit-animation flow (single-flight by semester id). No marks/GPA inputs.
- `Add semester` topbar button adds a semester (same provider method as chips).

### Data page (locked layout C)

- Top row: SectionHeader "Saved data"-style label + **Export Excel** GhostButton.
- **Semester chips** (independent selection state from GPA page; default first semester). The Data page stays read-only — no `+ Add` chip here (adding semesters happens on the GPA/CGPA pages).
- Read-only table inside a `UiCard`, exactly the approved mockup (`data-sheet-v2.html`):
  - Columns: SUBJECT | CR | MID /25 | FINAL /50 | SEC /25 | LAB /50 | TOTAL | GRADE
  - Header row: tiny uppercase muted labels with /max sublabels.
  - Rows: name (ellipsis), centered numbers, grade pill; `—` for empty components; non-lab rows show `—` for LAB.
  - Footer row: semester name · subject/credit summary · GPA pill (blue).
  - Lab subjects show a small green `LAB` badge after the name.
- Empty state stays (first-subject CTA). `Clear All` dialog stays (clears all marks/GPA values; semester and subject structure is kept, matching today's semantics).
- Legacy GPA-only semesters: table shows one row of `—` components with the legacy GPA in the footer (subject count text: "legacy GPA entry").

### Export (.xlsx)

- New deps: **`excel`**, **`share_plus`** (plus `path_provider` only if required for a temp file).
- Flow: build workbook in memory — one sheet per semester named `Sem 1`… (Excel 31-char/sanitized), header row + subject rows + blank + footer GPA row; a final `Summary` sheet with per-semester GPA + CGPA. Write to a temp `.xlsx`, then `share_plus` share sheet (user picks where to save/send). Fully local; no network.

## Overflow rules (user requirement)

- Every table is inside a horizontal `SingleChildScrollView` with fixed column min-widths (table min-width ≈ 520 px).
- Subject/semester names: `maxLines: 1`, `TextOverflow.ellipsis`, inside `Expanded`.
- Card rows: all text zones wrapped in `Expanded`/`Flexible` — no `Row` with unbounded text.
- Numeric fields: `inputFormatters: [FilteringTextInputFormatter.digitsOnly]` + max-value clamping on save (mid ≤ 25, final ≤ 50, sectional ≤ 25, lab ≤ 50); fields use compact `SizedBox` widths.
- Chips row: horizontal scroll when chips exceed width.
- No fixed-height containers around text; grade pills use padding-only sizing.

## Testing & gates

- Unit: migration (flat + manual → new shape; idempotency), total/percent/grade (theory /100, lab /150, legacy total), semester GPA weighting, CGPA average.
- Widget: chips switch subject lists; add/delete subject keeps enter/exit animation behavior (existing 11 tests keep passing); CGPA page has no input fields; Data table renders components/`—`/footer; export button present; xlsx builder produces expected sheet/row counts (pure function test, no share invocation).
- Gates: `flutter analyze` + `flutter test`; visual checklist for the user after server restart. **No git commits** (session rule).

## Out of scope

- Editing subjects directly from the Data page (read-only; entry happens on GPA page) (superseded by the Amendment below).
- CSV export, cloud sync, per-component max configuration.
- Changing grade thresholds or `GpaService` logic.

## Amendment (2026-10-10, user decision)

- GPA page subject card reverts to the pre-sheet single Marks field (out of 100; lab out of 50 with ×2) — component fields are removed from the card.
- Component entry (Mid /25, Final /50, Sectional /25, Lab /50) is done by editing cells directly in the Data page table (Excel-like editable cells).
- One entry mode per subject: typing Marks clears component fields; editing a component cell clears `legacyMarks`.
