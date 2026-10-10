# Independent Pages: GPA / CGPA / Data

**Goal:** Make all three pages fully independent — no shared AppData, no cross-page data flow, no shared semester selection.

Each page owns its own storage and logic:

| Page | Responsibility | Storage |
|------|----------------|---------|
| GPA | One active semester, subjects with marks → computes GPA | `mckru_gpa_indep_v1` (semester + subjects) |
| CGPA | Manual list of semesters (name, GPA, credits) → computes cumulative CGPA | `mckru_cgpa_indep_v1` (list of semesters) |
| Data | Excel-like: semesters → subjects (with labs) → pure reference storage | `mckru_data_indep_v1` (semesters with subject tables) |

## Global Constraints

- NO git commits
- Gates: `flutter analyze` → clean, `flutter test` → all green
- Never modify: `lib/services/gpa_service.dart`, `lib/main.dart`, `lib/widgets/staggered_animation.dart`
- Each page uses its own provider/state, no shared `AppData` between pages
- `withValues(alpha:)` not `withOpacity`
- Digits-only + clamp inputs
- TDD: write failing test first, then implement

## Task 1: GPA Page Independent

**Files:** `lib/screens/gpa_page.dart`, new `lib/providers/gpa_provider.dart`, `test/widget_test.dart` (GPA tests)

- [ ] Remove `AppData` dependency from GPA page
- [ ] Create `GpaProvider` with:
  - `SemesterRecord` (name, subjects[id, name, credits, isLab, legacyMarks])
  - `addSubject`, `removeSubject`, `updateSubject`, `setSemesterName`
  - `calculateGpa()` using `SheetCalc`/`GpaService`
  - Persists to `mckru_gpa_indep_v1` in SharedPreferences
- [ ] GPA page UI: semester name edit, subjects list (name, marks field, credits chip, lab toggle), add/remove subject, GPA result
- [ ] No semester chips/switching — single semester at a time (or simple semester rename)
- [ ] Tests: add/remove subject, marks validation, GPA calculation

## Task 2: CGPA Page Independent

**Files:** `lib/screens/cgpa_page.dart`, new `lib/providers/cgpa_provider.dart`, `test/widget_test.dart` (CGPA tests)

- [ ] Remove `AppData` dependency from CGPA page
- [ ] Create `CgpaProvider` with:
  - List of `CgpaSemester` (id, name, gpa, credits)
  - `addSemester`, `removeSemester`, `updateSemester(name, gpa, credits)`
  - `calculateCgpa()` = Σ(gpa×credits) / Σcredits
  - Persists to `mckru_cgpa_indep_v1`
- [ ] CGPA page UI: list of semesters (name, GPA, credits editable), add/remove, shows cumulative CGPA
- [ ] Tests: add/remove semester, CGPA math, persistence

## Task 3: Data Page Independent (Excel-like Storage)

**Files:** `lib/screens/storage_page.dart`, new `lib/providers/data_provider.dart`, `test/widget_test.dart` (Data tests)

- [ ] Remove `AppData` dependency from Data page
- [ ] Create `DataProvider` with:
  - `DataSemester` (id, name, subjects[id, name, credits, isLab, mid, final, sectional, lab])
  - `addSemester`, `removeSemester`, `renameSemester`
  - `addSubject(semesterId)`, `removeSubject(semesterId, subjectId)`, `updateSubject(semesterId, subject)`
  - Persists to `mckru_data_indep_v1`
- [ ] Data page UI: semester chips (local selection), table with columns: Name, CR, Mid/25, Final/50, Sec/25, Lab/50, Total, Grade — editable cells, lab row only when isLab
- [ ] No GPA/CGPA calculation here — just storage
- [ ] Tests: semester CRUD, subject CRUD, table edits persist

## Task 4: Cleanup & Verification

**Files:** `lib/providers/app_data.dart` (remove sheet logic, keep only onboarding/user prefs), `lib/main.dart` (provide three providers), `test/widget_test.dart` (all tests pass)

- [ ] `AppData` keeps only: onboarding, user name, avatar
- [ ] `main.dart` wraps with `ChangeNotifierProvider<GpaProvider>`, `ChangeNotifierProvider<CgpaProvider>`, `ChangeNotifierProvider<DataProvider>`
- [ ] Run full test suite (35 → ~50 tests), analyze clean
- [ ] Restart web server 8750, verify HTTP 200