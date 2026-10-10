# Excel-style Semester Sheet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the flat subject/manual-GPA storage with a nested semesterâ†’subject records model (Mid 25 / Final 50 / Sectional 25 / Lab 50 components), auto-calculated CGPA, an Excel-like read-only sheet on the Data page, and real `.xlsx` export.

**Architecture:** Additive migration: a new `sheet` model (`SemesterRecord`/`SubjectRecord`) is introduced in `AppData` while the legacy model still exists; each page is switched to the sheet one task at a time; the legacy model is deleted only after every consumer moved. All math lives in a new pure `SheetCalc` that converts to percent and calls the untouched `GpaService.getGradeFromMarks`.

**Tech Stack:** Flutter 3.41.6 / Dart 3.11.4, provider, shared_preferences, existing ui.dart component kit; new deps only in Task 6: `excel`, `share_plus`, `path_provider` (via `flutter pub add`).

**Spec:** `docs/superpowers/specs/2026-10-09-excel-semester-sheet-design.md`

## Global Constraints

- **NO git commits anywhere in this plan (session-wide rule).** Every task ends with gates instead: `flutter analyze` (expect `No issues found!`) and `flutter test` (expect all green). Do not run any `git` command.
- Never modify: `lib/services/gpa_service.dart`, `lib/main.dart`, `lib/widgets/staggered_animation.dart`. (`app_data.dart` modification IS in scope â€” user-approved for this feature.)
- Grade math input is always a **percent 0â€“100** fed to the existing `GpaService.getGradeFromMarks` â€” grade thresholds never change.
- Prefs: existing keys `mckru_gpa2`, `mckru_cgpa2`, `mckru_dark2`, `mckru_onboarded2`, `mckru_name`, `mckru_avatar` keep their current meaning; **new key `mckru_sheet_v1`** holds the sheet JSON. Old keys are only read by migration and remain in prefs as backup (stop writing them in Task 5).
- New dependencies only as stated per task (`flutter pub add`), nothing else.
- `.withValues(alpha:)` (never `withOpacity`).
- Overflow rules (spec): horizontal `SingleChildScrollView` for tables with fixed column widths; names `maxLines: 1` + `TextOverflow.ellipsis` inside `Expanded`; card rows use `Expanded`/`Wrap` (no unbounded Row text); numeric inputs digits-only `FilteringTextInputFormatter` + clamp-on-change; chips row is a horizontal `ListView`.
- GPA cards must keep `StaggeredAnimation(index: i, child: AnimatedCardFrame(key: ValueKey(subject.id), ...))` wrapping, the single-flight `_exitId` delete flow, `_knownIds` enter-animation seeding, and `dispose()` finishing an in-flight exit (all carried over from the current `gpa_page.dart`).
- All tests currently in `test/widget_test.dart` must stay in the suite; Tasks 2â€“3 rewrite the counts/assertions that the new UI invalidates (shown verbatim below).

### File structure

| File | Responsibility | Tasks |
|---|---|---|
| `lib/services/sheet_calc.dart` (new) | Pure math: totals, percent, grades, semester GPA, CGPA | 1 |
| `lib/providers/app_data.dart` | Sheet models, migration, mutations, stats; legacy removed in 5 | 1, 5 |
| `test/app_data_test.dart` (new) | Migration + computation + mutation unit tests | 1 |
| `lib/widgets/semester_chips.dart` (new) | Horizontal semester chip selector (GPA + Data pages) | 2 |
| `lib/screens/gpa_page.dart` | Chips + component entry cards | 2 |
| `lib/screens/cgpa_page.dart` | Auto-calc semester list, name-only edit | 3 |
| `lib/screens/storage_page.dart` | Locked layout-C table + chips + export button | 4, 6 |
| `lib/screens/main_shell.dart` | Topbar `Add subject`/`Add semester` targets | 2, 3 |
| `lib/services/sheet_export.dart` (new) | Pure `.xlsx` builder | 6 |
| `test/sheet_export_test.dart` (new) | Builder output test | 6 |
| `test/widget_test.dart` | Widget suite (rewrites in 2â€“3, new tests 2/4) | 2, 3, 4 |

---

### Task 1: Sheet model, migration, computation

**Files:**
- Create: `lib/services/sheet_calc.dart`
- Modify: `lib/providers/app_data.dart`
- Test: `test/app_data_test.dart` (new file)

**Interfaces:**
- Consumes: existing `AppData.load()`, `GpaService.getGradeFromMarks(double)`.
- Produces (everything later tasks depend on, exact names):
  - `class SubjectRecord { final String id; String name; int credits; bool isLab; String mid; String finalMarks; String sectional; String lab; String legacyMarks; }` with `toJson()`/`fromJson()` (JSON keys: `id,name,credits,isLab,mid,final,sectional,lab,legacyMarks`).
  - `class SemesterRecord { final String id; String name; List<SubjectRecord> subjects; String legacyGpa; }` with `toJson()`/`fromJson()` (JSON keys: `id,name,subjects,legacyGpa`).
  - On `AppData`: `List<SemesterRecord> get sheet`, `String? get activeSemesterId`, `SemesterRecord get activeSemester`, `void setActiveSemester(String id)`, `void addSemesterRecord()`, `void removeSemesterRecord(String id)`, `void renameSemester(String id, String name)`, `void addSubject({String? semesterId})`, `void removeSubject(String semesterId, String subjectId)`, `void updateSubject(String semesterId, SubjectRecord updated)`.
  - `class SheetCalc` static API: `double subjectMax(SubjectRecord)`, `bool usesComponents(SubjectRecord)`, `double? totalOf(SubjectRecord)`, `double? percentOf(SubjectRecord)`, `GradeInfo? gradeOf(SubjectRecord)`, `double? semesterGpa(SemesterRecord)`, `double? cgpa(List<SemesterRecord>)`, `int creditsOf(SubjectRecord)`.

- [x] **Step 1: Write the failing unit tests**

Create `test/app_data_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cgpa_calculator/providers/app_data.dart';
import 'package:cgpa_calculator/services/sheet_calc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('migration', () {
    test('legacy flat subjects and manual semesters migrate into the sheet', () async {
      SharedPreferences.setMockInitialValues({
        'mckru_gpa2': jsonEncode([
          {'id': 's1', 'name': 'Physics', 'marks': '78', 'credits': 3, 'isLab': false},
          {'id': 's2', 'name': 'Chem Lab', 'marks': '45', 'credits': 1, 'isLab': true},
        ]),
        'mckru_cgpa2': jsonEncode([
          {'id': 'sem1', 'name': 'Semester 1', 'gpa': '3.50'},
          {'id': 'sem2', 'name': 'Semester 2', 'gpa': '3.20'},
        ]),
      });
      final data = AppData();
      await data.load();

      expect(data.sheet.length, 2);
      expect(data.sheet[0].subjects.length, 2);
      expect(data.sheet[0].subjects[0].name, 'Physics');
      expect(data.sheet[0].subjects[0].legacyMarks, '78');
      expect(data.sheet[0].subjects[1].isLab, isTrue);
      expect(data.sheet[0].legacyGpa, '3.50');
      expect(data.sheet[1].subjects, isEmpty);
      expect(data.sheet[1].legacyGpa, '3.20');
    });

    test('migration is idempotent once mckru_sheet_v1 exists', () async {
      SharedPreferences.setMockInitialValues({
        'mckru_sheet_v1': jsonEncode([
          {
            'id': 'x',
            'name': 'Semester 1',
            'legacyGpa': '',
            'subjects': [
              {
                'id': 'a',
                'name': 'Kept',
                'credits': 3,
                'isLab': false,
                'mid': '10',
                'final': '40',
                'sectional': '20',
                'lab': '',
                'legacyMarks': ''
              }
            ],
          }
        ]),
        'mckru_gpa2': jsonEncode([
          {'id': 'old', 'name': 'Old', 'marks': '50', 'credits': 3, 'isLab': false}
        ]),
      });
      final data = AppData();
      await data.load();

      expect(data.sheet.single.subjects.single.name, 'Kept');
    });

    test('fresh start yields one semester with one subject', () async {
      SharedPreferences.setMockInitialValues({});
      final data = AppData();
      await data.load();

      expect(data.sheet, hasLength(1));
      expect(data.sheet.single.name, 'Semester 1');
      expect(data.sheet.single.subjects.single.name, 'Subject 1');
    });
  });

  group('computation', () {
    SubjectRecord theory({String mid = '', String fin = '', String sec = ''}) =>
        SubjectRecord(id: 't', name: 'T', mid: mid, finalMarks: fin, sectional: sec);

    test('theory subject percent is out of 100', () {
      final s = theory(mid: '20', fin: '40', sec: '15');
      expect(SheetCalc.subjectMax(s), 100);
      expect(SheetCalc.totalOf(s), 75);
      expect(SheetCalc.percentOf(s), 75);
      expect(SheetCalc.gradeOf(s)!.letter, 'B+');
    });

    test('lab subject percent is out of 150', () {
      final s = SubjectRecord(
          id: 'l', name: 'L', isLab: true, mid: '18', finalMarks: '39', sectional: '20', lab: '45');
      expect(SheetCalc.subjectMax(s), 150);
      expect(SheetCalc.totalOf(s), 122);
      expect(SheetCalc.percentOf(s), closeTo(81.333, 0.01));
      expect(SheetCalc.gradeOf(s)!.letter, 'A-');
    });

    test('legacy subjects keep the old scale (lab x2)', () {
      final theoryLegacy = SubjectRecord(id: 'a', name: 'A', legacyMarks: '78');
      final labLegacy = SubjectRecord(id: 'b', name: 'B', isLab: true, legacyMarks: '45');
      expect(SheetCalc.totalOf(theoryLegacy), 78);
      expect(SheetCalc.percentOf(theoryLegacy), 78);
      expect(SheetCalc.percentOf(labLegacy), 90);
      expect(SheetCalc.totalOf(SubjectRecord(id: 'c', name: 'C')), isNull);
    });

    test('semester gpa is credits-weighted with lab at 1 credit', () {
      final sem = SemesterRecord(id: 's', name: 'S', subjects: [
        theory(mid: '20', fin: '40', sec: '15'), // 75 -> B+ 3.3, 3 cr
        SubjectRecord(id: 'l', name: 'L', isLab: true, mid: '20', finalMarks: '45', sectional: '25',
            lab: '50'), // 140/150 -> 93.3 -> A 4.0, 1 cr
      ]);
      expect(SheetCalc.semesterGpa(sem), closeTo((3.3 * 3 + 4.0 * 1) / 4, 0.001));
    });

    test('semester gpa falls back to legacy gpa when there are no graded subjects', () {
      final legacyOnly = SemesterRecord(id: 's', name: 'S', legacyGpa: '3.20');
      expect(SheetCalc.semesterGpa(legacyOnly), 3.20);
      expect(SheetCalc.semesterGpa(SemesterRecord(id: 'e', name: 'E')), isNull);
    });

    test('cgpa averages non-null semester gpas', () {
      final cgpa = SheetCalc.cgpa([
        SemesterRecord(id: 'a', name: 'A', legacyGpa: '3.00'),
        SemesterRecord(id: 'b', name: 'B', legacyGpa: '3.50'),
        SemesterRecord(id: 'c', name: 'C'),
      ]);
      expect(cgpa, closeTo(3.25, 0.001));
    });
  });

  group('mutations', () {
    test('addSubject names per semester count; removeSubject guards length', () async {
      SharedPreferences.setMockInitialValues({});
      final data = AppData();
      await data.load();

      data.addSubject();
      expect(data.sheet.single.subjects.map((s) => s.name),
          ['Subject 1', 'Subject 2']);

      data.removeSubject(data.sheet.single.id, data.sheet.single.subjects.first.id);
      expect(data.sheet.single.subjects, hasLength(1),
          reason: 'last subject must never be removable');
    });

    test('removeSemesterRecord renumbers only untouched default names', () async {
      SharedPreferences.setMockInitialValues({});
      final data = AppData();
      await data.load();
      data.addSemesterRecord();
      data.addSemesterRecord();
      data.renameSemester(data.sheet[1].id, 'MySem');

      data.removeSemesterRecord(data.sheet[1].id);

      expect(data.sheet.map((s) => s.name), ['Semester 1', 'Semester 2'],
          reason: 'custom name survived and sits at index 1, still default-renumbered around');
    });

    test('clearAll wipes values but keeps structure; resetAll resets everything', () async {
      SharedPreferences.setMockInitialValues({});
      final data = AppData();
      await data.load();
      data.updateSubject(data.sheet.single.id,
          SubjectRecord(id: data.sheet.single.subjects.single.id, name: 'Physics', mid: '20'));

      data.clearAll();
      expect(data.sheet.single.subjects.single.name, 'Physics');
      expect(data.sheet.single.subjects.single.mid, '');

      data.resetAll();
      expect(data.sheet, hasLength(1));
      expect(data.sheet.single.subjects.single.name, 'Subject 1');
    });
  });
}
```

- [x] **Step 2: Run tests, verify they FAIL**

Run: `flutter test test/app_data_test.dart`
Expected: FAIL â€” `SubjectRecord`/`SheetCalc` undefined (compile errors).

- [x] **Step 3: Create `lib/services/sheet_calc.dart`**

```dart
import '../providers/app_data.dart';
import 'gpa_service.dart';

class SheetCalc {
  static double subjectMax(SubjectRecord s) => s.isLab ? 150.0 : 100.0;

  static bool usesComponents(SubjectRecord s) =>
      s.mid.isNotEmpty ||
      s.finalMarks.isNotEmpty ||
      s.sectional.isNotEmpty ||
      s.lab.isNotEmpty;

  static double? totalOf(SubjectRecord s) {
    if (usesComponents(s)) {
      double t = 0;
      t += double.tryParse(s.mid) ?? 0;
      t += double.tryParse(s.finalMarks) ?? 0;
      t += double.tryParse(s.sectional) ?? 0;
      if (s.isLab) t += double.tryParse(s.lab) ?? 0;
      return t;
    }
    if (s.legacyMarks.isNotEmpty) return double.tryParse(s.legacyMarks);
    return null;
  }

  static double? percentOf(SubjectRecord s) {
    if (usesComponents(s)) {
      return totalOf(s)! / subjectMax(s) * 100;
    }
    if (s.legacyMarks.isNotEmpty) {
      final v = double.tryParse(s.legacyMarks);
      if (v == null) return null;
      return s.isLab ? v * 2 : v;
    }
    return null;
  }

  static GradeInfo? gradeOf(SubjectRecord s) {
    final p = percentOf(s);
    if (p == null) return null;
    return GpaService.getGradeFromMarks(p);
  }

  static int creditsOf(SubjectRecord s) => s.isLab ? 1 : s.credits;

  static double? semesterGpa(SemesterRecord s) {
    double pts = 0;
    int cr = 0;
    for (final sub in s.subjects) {
      final g = gradeOf(sub);
      if (g == null) continue;
      pts += g.gpa * creditsOf(sub);
      cr += creditsOf(sub);
    }
    if (cr > 0) return pts / cr;
    final legacy = double.tryParse(s.legacyGpa);
    if (legacy != null && legacy >= 0 && legacy <= 4) return legacy;
    return null;
  }

  static double? cgpa(List<SemesterRecord> sheet) {
    double total = 0;
    int count = 0;
    for (final s in sheet) {
      final g = semesterGpa(s);
      if (g != null) {
        total += g;
        count++;
      }
    }
    if (count == 0) return null;
    return total / count;
  }
}
```

- [x] **Step 4: Extend `lib/providers/app_data.dart`**

4a. After `class SemesterGpa { ... }` (line ~60), insert the two new model classes:

```dart
class SubjectRecord {
  final String id;
  String name;
  int credits;
  bool isLab;
  String mid;
  String finalMarks;
  String sectional;
  String lab;
  String legacyMarks;

  SubjectRecord({
    required this.id,
    required this.name,
    this.credits = 3,
    this.isLab = false,
    this.mid = '',
    this.finalMarks = '',
    this.sectional = '',
    this.lab = '',
    this.legacyMarks = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'credits': credits,
        'isLab': isLab,
        'mid': mid,
        'final': finalMarks,
        'sectional': sectional,
        'lab': lab,
        'legacyMarks': legacyMarks,
      };

  factory SubjectRecord.fromJson(Map<String, dynamic> json) => SubjectRecord(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        credits: json['credits'] as int? ?? 3,
        isLab: json['isLab'] as bool? ?? false,
        mid: json['mid'] as String? ?? '',
        finalMarks: json['final'] as String? ?? '',
        sectional: json['sectional'] as String? ?? '',
        lab: json['lab'] as String? ?? '',
        legacyMarks: json['legacyMarks'] as String? ?? '',
      );
}

class SemesterRecord {
  final String id;
  String name;
  List<SubjectRecord> subjects;
  String legacyGpa;

  SemesterRecord({
    required this.id,
    required this.name,
    List<SubjectRecord>? subjects,
    this.legacyGpa = '',
  }) : subjects = subjects ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'legacyGpa': legacyGpa,
        'subjects': subjects.map((e) => e.toJson()).toList(),
      };

  factory SemesterRecord.fromJson(Map<String, dynamic> json) => SemesterRecord(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Semester',
        legacyGpa: json['legacyGpa'] as String? ?? '',
        subjects: ((json['subjects'] as List?) ?? [])
            .map((e) => SubjectRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
```

4b. In `class AppData`, add imports/fields after `List<SemesterGpa> _semesters = [];`:

```dart
  List<SemesterRecord> _sheet = [];
  String? _activeSemesterId;
```

and getters after `List<SemesterGpa> get semesters => _semesters;`:

```dart
  List<SemesterRecord> get sheet => _sheet;
  String? get activeSemesterId => _activeSemesterId;
```

4c. In `load()`, after the profile reads (`_userAvatar = ...`) and **before** the existing `mckru_gpa2` block, insert:

```dart
    final sheetJson = prefs.getString('mckru_sheet_v1');
    if (sheetJson != null) {
      _sheet = (jsonDecode(sheetJson) as List)
          .map((e) => SemesterRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _sheet = _migrateLegacy(prefs);
      await prefs.setString(
          'mckru_sheet_v1', jsonEncode(_sheet.map((e) => e.toJson()).toList()));
    }
    if (_sheet.isEmpty) {
      _sheet = [SemesterRecord(id: generateId(), name: 'Semester 1')];
    }
    if (_sheet.first.subjects.isEmpty) {
      _sheet.first.subjects.add(SubjectRecord(id: generateId(), name: 'Subject 1'));
    }
```

Add the private helper as a method of `AppData` (e.g. directly under `load()`):

```dart
  List<SemesterRecord> _migrateLegacy(SharedPreferences prefs) {
    final result = <SemesterRecord>[];
    final cg = prefs.getString('mckru_cgpa2');
    if (cg != null) {
      for (final e in jsonDecode(cg) as List) {
        final map = e as Map<String, dynamic>;
        result.add(SemesterRecord(
          id: generateId(),
          name: map['name'] as String? ?? 'Semester',
          legacyGpa: map['gpa'] as String? ?? '',
        ));
      }
    }
    if (result.isEmpty) {
      result.add(SemesterRecord(id: generateId(), name: 'Semester 1'));
    }
    final g = prefs.getString('mckru_gpa2');
    if (g != null) {
      for (final e in jsonDecode(g) as List) {
        final map = e as Map<String, dynamic>;
        result.first.subjects.add(SubjectRecord(
          id: map['id'] as String? ?? generateId(),
          name: map['name'] as String? ?? 'Subject',
          credits: map['credits'] as int? ?? 3,
          isLab: map['isLab'] as bool? ?? false,
          legacyMarks: map['marks'] as String? ?? '',
        ));
      }
    }
    return result;
  }
```

4d. In `_save()`, add (keep the existing two `mckru_gpa2`/`mckru_cgpa2` writes for now â€” removed in Task 5):

```dart
    await prefs.setString(
        'mckru_sheet_v1', jsonEncode(_sheet.map((e) => e.toJson()).toList()));
```

4e. Add the sheet mutation API as a new section just above `// Stats`:

```dart
  // â”€â”€ Semester sheet â”€â”€
  SemesterRecord get activeSemester {
    for (final s in _sheet) {
      if (s.id == _activeSemesterId) return s;
    }
    return _sheet.first; // load() guarantees at least one
  }

  void setActiveSemester(String id) {
    _activeSemesterId = id;
    notifyListeners();
  }

  void addSemesterRecord() {
    final sem = SemesterRecord(
      id: generateId(),
      name: 'Semester ${_sheet.length + 1}',
      subjects: [SubjectRecord(id: generateId(), name: 'Subject 1')],
    );
    _sheet.add(sem);
    _activeSemesterId = sem.id;
    _debounceSave();
    notifyListeners();
  }

  void removeSemesterRecord(String id) {
    if (_sheet.length <= 1) return;
    _sheet.removeWhere((s) => s.id == id);
    final defaults = RegExp(r'^Semester \d+$');
    for (int i = 0; i < _sheet.length; i++) {
      if (defaults.hasMatch(_sheet[i].name)) {
        _sheet[i].name = 'Semester ${i + 1}';
      }
    }
    if (_activeSemesterId == id) _activeSemesterId = _sheet.first.id;
    _debounceSave();
    notifyListeners();
  }

  void renameSemester(String id, String name) {
    final i = _sheet.indexWhere((s) => s.id == id);
    if (i == -1) return;
    _sheet[i].name = name;
    _debounceSave();
    notifyListeners();
  }

  void addSubject({String? semesterId}) {
    final sem = _findSemester(semesterId) ?? activeSemester;
    sem.subjects.add(
        SubjectRecord(id: generateId(), name: 'Subject ${sem.subjects.length + 1}'));
    _debounceSave();
    notifyListeners();
  }

  void removeSubject(String semesterId, String subjectId) {
    final sem = _findSemester(semesterId);
    if (sem == null || sem.subjects.length <= 1) return;
    sem.subjects.removeWhere((s) => s.id == subjectId);
    _debounceSave();
    notifyListeners();
  }

  void updateSubject(String semesterId, SubjectRecord updated) {
    final sem = _findSemester(semesterId);
    if (sem == null) return;
    final i = sem.subjects.indexWhere((s) => s.id == updated.id);
    if (i == -1) return;
    sem.subjects[i] = updated;
    _debounceSave();
    notifyListeners();
  }

  SemesterRecord? _findSemester(String? id) {
    if (id == null) return null;
    for (final s in _sheet) {
      if (s.id == id) return s;
    }
    return null;
  }
```

4f. Replace the bodies of the existing stats getters (`import 'sheet_calc'` via relative path: add `import '../services/sheet_calc.dart';` at the top of `app_data.dart`):

```dart
  double? get cgpa => SheetCalc.cgpa(_sheet);

  int get semesterCount =>
      _sheet.where((s) => SheetCalc.semesterGpa(s) != null).length;

  int get subjectCount => _sheet
      .expand((s) => s.subjects)
      .where((s) => SheetCalc.totalOf(s) != null)
      .length;

  int get totalCredits => _sheet
      .expand((s) => s.subjects)
      .where((s) => SheetCalc.gradeOf(s) != null)
      .fold(0, (sum, s) => sum + SheetCalc.creditsOf(s));
```

(`avgGpa` stays `=> cgpa;`.)

4g. In `clearAll()`, add:

```dart
    for (final sem in _sheet) {
      for (final s in sem.subjects) {
        s.mid = '';
        s.finalMarks = '';
        s.sectional = '';
        s.lab = '';
        s.legacyMarks = '';
      }
      sem.legacyGpa = '';
    }
```

In `resetAll()`, add:

```dart
    _sheet = [SemesterRecord(id: generateId(), name: 'Semester 1')];
    _sheet.first.subjects.add(SubjectRecord(id: generateId(), name: 'Subject 1'));
    _activeSemesterId = null;
```

- [x] **Step 5: Run the new tests, verify they PASS**

Run: `flutter test test/app_data_test.dart`
Expected: all groups PASS.

- [x] **Step 6: Run gates**

Run: `flutter analyze` â†’ Expected: `No issues found!`
Run: `flutter test` â†’ Expected: entire suite green (old `widget_test.dart` unchanged).

---

### Task 2: GPA page â€” semester chips + component entry

**Files:**
- Create: `lib/widgets/semester_chips.dart`
- Modify: `lib/screens/gpa_page.dart`, `lib/screens/main_shell.dart:91`, `test/widget_test.dart`
- Test: rewrites/new tests inside `test/widget_test.dart`

**Interfaces:**
- Consumes: Task 1 (`data.sheet`, `data.activeSemester`, `data.setActiveSemester`, `data.addSemesterRecord`, `data.addSubject`, `data.removeSubject`, `data.updateSubject`, `SheetCalc.*`).
- Produces: `SemesterChips({super.key, required List<String> labels, required int selectedIndex, required ValueChanged<int> onSelect, VoidCallback? onAdd})` for Task 4; topbar `Add subject` now calls `data.addSubject()`.

- [x] **Step 1: Write the failing widget tests**

In `test/widget_test.dart`, make these existing-test edits first (part of the failing state â€” new UI doesn't exist yet):

1. In `'GPA: deleting a subject waits for the exit animation'` change:
   - `expect(added, initial + 2, reason: 'new subject card contributes 2 text fields');` â†’
   ```dart
   expect(added, initial + 4, reason: 'new subject card contributes 4 text fields (name + mid + final + sectional)');
   ```
2. In `'GPA: a newly added card grows in instead of popping at full height'` change:
   - `expect(tester.widgetList(find.byType(TextField)).length, 4, reason: 'two subject cards mounted');` â†’
   ```dart
   expect(tester.widgetList(find.byType(TextField)).length, 8, reason: 'two subject cards mounted, 4 fields each');
   ```

Then append these two NEW tests before the final `}` of `main()`:

```dart
  testWidgets('GPA: chips switch semesters and each keeps its own subjects', (tester) async {
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

    await tester.enterText(find.byType(TextField).first, 'Algebra');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('+'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Subject 1'), findsWidgets,
        reason: 'new semester opened with its own default subject card');

    await tester.tap(find.text('Semester 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.widgetWithText(TextField, 'Algebra'), findsOneWidget,
        reason: 'semester 1 kept the renamed subject');

    await tester.tap(find.text('Semester 2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.widgetWithText(TextField, 'Algebra'), findsNothing);
  });

  testWidgets('GPA: component fields compute total and grade, clamped to max', (tester) async {
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

    final fields = find.byType(TextField); // [name, mid, final, sectional]
    await tester.enterText(fields.at(1), '20');
    await tester.pump();
    await tester.enterText(fields.at(2), '40');
    await tester.pump();
    await tester.enterText(fields.at(3), '15');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('75/100'), findsOneWidget, reason: 'live total shows sum/max');
    expect(find.text('B+'), findsOneWidget, reason: 'grade chip reflects 75%');

    await tester.enterText(fields.at(1), '999');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.widgetWithText(TextField, '25'), findsOneWidget,
        reason: 'mid clamps to its 25 max');
  });
```

- [x] **Step 2: Run tests, verify they FAIL**

Run: `flutter test --plain-name "GPA:"`
Expected: FAIL â€” `+` chip / `75/100` not found (and count mismatches).

- [x] **Step 3: Create `lib/widgets/semester_chips.dart`**

```dart
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SemesterChips extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onAdd;

  const SemesterChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final count = labels.length + (onAdd == null ? 0 : 1);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          if (i >= labels.length) {
            return InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.field,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: p.border),
                ),
                child: Text('+',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: p.muted)),
              ),
            );
          }
          final active = i == selectedIndex;
          return InkWell(
            onTap: () => onSelect(i),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? p.accent : p.field,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: active ? p.accent : p.border),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : p.muted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

- [x] **Step 4: Rewrite `lib/screens/gpa_page.dart`**

Keep the file's imports as-is plus add:

```dart
import '../services/sheet_calc.dart';
import '../widgets/semester_chips.dart';
```

Replace `class _GpaPageState` fields/dispose/`_completeExit`/`build` with exactly:

```dart
class _GpaPageState extends State<GpaPage> {
  AppData? _data;
  Set<String> _knownIds = <String>{};
  String? _seededSemesterId;
  bool _seeded = false;
  String? _enterId;
  String? _exitId;
  String? _exitSemesterId;
  Timer? _enterTimer;

  @override
  void dispose() {
    _enterTimer?.cancel();
    final id = _exitId;
    final semId = _exitSemesterId;
    final data = _data;
    if (id != null && semId != null && data != null) {
      data.removeSubject(semId, id);
    }
    super.dispose();
  }

  void _completeExit(String id) {
    final data = _data;
    if (data == null) return;
    final semId = _exitSemesterId;
    if (semId != null) data.removeSubject(semId, id);
    if (mounted) {
      setState(() {
        _exitId = null;
        _exitSemesterId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    _data = context.read<AppData>();

    final active = data.activeSemester;
    final subjects = active.subjects;

    final ids = subjects.map((s) => s.id).toSet();
    if (_seeded && _seededSemesterId == active.id) {
      final added = ids.difference(_knownIds);
      if (added.isNotEmpty) {
        _enterId = added.first;
        _enterTimer?.cancel();
        _enterTimer = Timer(const Duration(milliseconds: 400), () {
          if (mounted) setState(() => _enterId = null);
        });
      }
    } else if (_seeded) {
      _enterTimer?.cancel();
      _enterId = null;
    }
    _knownIds = ids;
    _seededSemesterId = active.id;
    _seeded = true;

    double totalPts = 0;
    int totalCr = 0;
    for (final card in subjects) {
      final grade = SheetCalc.gradeOf(card);
      if (grade == null) continue;
      final cr = SheetCalc.creditsOf(card);
      totalPts += grade.gpa * cr;
      totalCr += cr;
    }
    final gpaResult = totalCr > 0 ? totalPts / totalCr : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SemesterChips(
            labels: data.sheet.map((s) => s.name).toList(),
            selectedIndex: data.sheet.indexOf(active),
            onSelect: (i) => data.setActiveSemester(data.sheet[i].id),
            onAdd: data.addSemesterRecord,
          ),
          const SizedBox(height: 10),
          ...List.generate(subjects.length, (i) {
            final subject = subjects[i];
            return StaggeredAnimation(
              index: i,
              child: AnimatedCardFrame(
                key: ValueKey(subject.id),
                animateEnter: subject.id == _enterId,
                exiting: subject.id == _exitId,
                onExitComplete: () => _completeExit(subject.id),
                child: _SubjectCard(
                  index: i,
                  subject: subject,
                  canDelete: subjects.length > 1,
                  semesterId: active.id,
                  onDelete: () {
                    if (_exitId == null) {
                      setState(() {
                        _exitId = subject.id;
                        _exitSemesterId = active.id;
                      });
                    }
                  },
                  onChanged: (updated) => data.updateSubject(active.id, updated),
                ),
              ),
            );
          }),
          if (gpaResult != null) ...[
            const SizedBox(height: 10),
            StaggeredAnimation(
              index: subjects.length,
              child: ResultCard(
                eyebrow: 'Semester GPA',
                value: gpaResult.toStringAsAsSafe,
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

**Correction â€” use `gpaResult.toStringAsFixed(2)` for `value:` (not the placeholder above).**

Replace `_SubjectCard`/`_SubjectCardState` entirely with:

```dart
class _SubjectCard extends StatefulWidget {
  final int index;
  final SubjectRecord subject;
  final bool canDelete;
  final String semesterId;
  final VoidCallback onDelete;
  final ValueChanged<SubjectRecord> onChanged;

  const _SubjectCard({
    required this.index,
    required this.subject,
    required this.canDelete,
    required this.semesterId,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject.name);
  }

  @override
  void didUpdateWidget(covariant _SubjectCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subject.name != widget.subject.name) {
      _nameController.text = widget.subject.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  SubjectRecord _copyWith({
    String? name,
    String? mid,
    String? finalMarks,
    String? sectional,
    String? lab,
    int? credits,
    bool? isLab,
  }) {
    return SubjectRecord(
      id: widget.subject.id,
      name: name ?? widget.subject.name,
      credits: credits ?? widget.subject.credits,
      isLab: isLab ?? widget.subject.isLab,
      mid: mid ?? widget.subject.mid,
      finalMarks: finalMarks ?? widget.subject.finalMarks,
      sectional: sectional ?? widget.subject.sectional,
      lab: lab ?? widget.subject.lab,
      legacyMarks: widget.subject.legacyMarks,
    );
  }

  String _clamp(String v, int max) {
    if (v.isEmpty) return '';
    final n = int.tryParse(v);
    if (n == null) return '';
    return n > max ? '$max' : v;
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final isLab = widget.subject.isLab;
    final grade = SheetCalc.gradeOf(widget.subject);
    final total = SheetCalc.totalOf(widget.subject);
    final max = SheetCalc.subjectMax(widget.subject);
    final cr = widget.subject.credits;
    final totalText = total == null ? null : '${total.toInt()}/${max.toInt()}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: UiCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IdxBadge(text: '${widget.index + 1}'.padLeft(2, '0')),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      filled: false,
                    ),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.fg),
                    onChanged: (v) => widget.onChanged(_copyWith(name: v)),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: InkWell(
                    onTap: widget.canDelete ? widget.onDelete : null,
                    borderRadius: BorderRadius.circular(kRadius),
                    child: Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: widget.canDelete ? p.muted : p.muted.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MarksField(
                  label: 'Mid',
                  hint: '/25',
                  width: 62,
                  value: widget.subject.mid,
                  max: 25,
                  onSet: (v) => widget.onChanged(_copyWith(mid: _clamp(v, 25))),
                ),
                _MarksField(
                  label: 'Final',
                  hint: '/50',
                  width: 62,
                  value: widget.subject.finalMarks,
                  max: 50,
                  onSet: (v) => widget.onChanged(_copyWith(finalMarks: _clamp(v, 50))),
                ),
                _MarksField(
                  label: 'Sectional',
                  hint: '/25',
                  width: 62,
                  value: widget.subject.sectional,
                  max: 25,
                  onSet: (v) => widget.onChanged(_copyWith(sectional: _clamp(v, 25))),
                ),
                if (isLab)
                  _MarksField(
                    label: 'Lab',
                    hint: '/50',
                    width: 62,
                    value: widget.subject.lab,
                    max: 50,
                    onSet: (v) => widget.onChanged(_copyWith(lab: _clamp(v, 50))),
                  ),
              ],
            ),
            if (!isLab) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(child: FieldLabel(text: 'Credit hours')),
                  for (int c = 1; c <= 5; c++) ...[
                    if (c > 1) const SizedBox(width: 6),
                    _CreditChip(
                      value: c,
                      active: c == cr,
                      onTap: () => widget.onChanged(_copyWith(credits: c)),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(child: FieldLabel(text: 'Lab')),
                Text(
                  isLab ? 'On' : 'Off',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.muted),
                ),
                const SizedBox(width: 8),
                AppSwitch(
                  value: isLab,
                  onChanged: (v) => widget.onChanged(
                    _copyWith(isLab: v, credits: v ? 1 : widget.subject.credits),
                  ),
                ),
              ],
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      grade != null
                          ? (isLab ? 'Lab Â· weight 1' : 'Non-lab Â· weight $cr')
                          : 'Fix marks to grade',
                      style:
                          TextStyle(fontSize: 11.5, fontWeight: FontWeight.w400, color: p.muted),
                    ),
                  ),
                  if (totalText != null) ...[
                    Text(totalText, style: numStyle(12.5, FontWeight.w800, p.fg)),
                    const SizedBox(width: 8),
                  ],
                  grade != null
                      ? GradeChip(letter: grade.letter, gpa: grade.gpa)
                      : Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.field,
                            borderRadius: BorderRadius.circular(kRadius),
                            border: Border.all(color: p.border),
                          ),
                          child: Text('â€” pending',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700, color: p.muted)),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarksField extends StatefulWidget {
  final String label;
  final String hint;
  final double width;
  final String value;
  final int max;
  final ValueChanged<String> onSet;

  const _MarksField({
    required this.label,
    required this.hint,
    required this.width,
    required this.value,
    required this.max,
    required this.onSet,
  });

  @override
  State<_MarksField> createState() => _MarksFieldState();
}

class _MarksFieldState extends State<_MarksField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _MarksField oldWidget) {
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
      width: widget.width + 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.label} ${widget.hint}',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: p.muted)),
          const SizedBox(height: 3),
          SizedBox(
            width: widget.width,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: fieldInput(context, hint: '0'),
              style: numStyle(14, FontWeight.w700, p.fg),
              onChanged: widget.onSet,
            ),
          ),
        ],
      ),
    );
  }
}
```

`_CreditChip` stays unchanged. Remove now-unused imports if `flutter analyze` flags them (e.g. `gpa_service.dart` is still used by `GpaService.getGpaMessage` in `build` â€” keep it).

- [x] **Step 5: Switch the topbar button**

In `lib/screens/main_shell.dart:91` replace:

```dart
      1 => [GhostButton(label: 'Add subject', icon: Icons.add, onTap: data.addGpaSubject)],
```

with:

```dart
      1 => [GhostButton(label: 'Add subject', icon: Icons.add, onTap: data.addSubject)],
```

- [x] **Step 6: Run the GPA tests, verify they PASS**

Run: `flutter test --plain-name "GPA:"`
Expected: all GPA tests PASS (including the two rewritten + two new).

- [x] **Step 7: Run gates**

Run: `flutter analyze` â†’ Expected: `No issues found!`
Run: `flutter test` â†’ Expected: all tests green (CGPA/Data tests unchanged so far; note the CGPA tests still exercise the legacy page and must still pass â€” the legacy semester model is untouched).

---

### Task 3: CGPA page â€” auto-calculated semester list

**Files:**
- Modify: `lib/screens/cgpa_page.dart`, `lib/screens/main_shell.dart:92`, `test/widget_test.dart`
- Test: rewrites inside `test/widget_test.dart`

**Interfaces:**
- Consumes: Task 1 (`data.sheet`, `SheetCalc.semesterGpa`, `SheetCalc.cgpa`, `data.renameSemester`, `data.removeSemesterRecord`, `data.addSemesterRecord`, `data.semesterCount`).
- Produces: topbar `Add semester` now calls `data.addSemesterRecord`.

- [x] **Step 1: Rewrite the failing tests**

In `test/widget_test.dart`:

1. In `'CGPA: deleting a semester waits for the exit animation'` change:
   ```dart
   expect(added, initial + 2, reason: 'new semester card contributes 2 text fields');
   ```
   to:
   ```dart
   expect(added, initial + 1, reason: 'new semester card contributes 1 text field (name only)');
   ```
2. In `'CGPA: custom semester name survives deleting another semester'` change the same expectation line the same way (`initial + 1`, reason `'new semester card contributes 1 text field (name only)'`). Its `enterText(find.byType(TextField).first, 'MySem')` keeps working â€” the name field is the only field per card now.

- [x] **Step 2: Run tests, verify they FAIL**

Run: `flutter test --plain-name "CGPA:"`
Expected: FAIL â€” old cards still have a GPA input, so counts are `initial + 2`.

- [x] **Step 3: Rewrite `lib/screens/cgpa_page.dart` state + card**

Keep the stateful shell (`_enterId`, `_exitId`, `_knownIds` seeding, `_enterTimer`, `dispose()`) **exactly as it is** â€” only the types change from `SemesterGpa` to `SemesterRecord` and the GPA input disappears. Full replacement for the state class and `_SemesterCard` (the `build` list stays structurally identical to today):

```dart
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
      final idx = data.sheet.indexWhere((s) => s.id == id);
      if (idx != -1) data.removeSemesterRecord(id);
    }
    super.dispose();
  }

  void _completeExit(String id) {
    final data = _data;
    if (data == null) return;
    data.removeSemesterRecord(id);
    if (mounted) setState(() => _exitId = null);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    _data = context.read<AppData>();
    final sheet = data.sheet;

    final ids = sheet.map((s) => s.id).toSet();
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

    final cgpa = SheetCalc.cgpa(sheet);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        children: [
          ...List.generate(sheet.length, (i) {
            final semester = sheet[i];
            return StaggeredAnimation(
              index: i,
              child: AnimatedCardFrame(
                key: ValueKey(semester.id),
                animateEnter: semester.id == _enterId,
                exiting: semester.id == _exitId,
                onExitComplete: () => _completeExit(semester.id),
                child: _SemesterCard(
                  index: i,
                  semester: semester,
                  canDelete: sheet.length > 1,
                  onDelete: () {
                    if (_exitId == null) setState(() => _exitId = semester.id);
                  },
                  onRename: (name) => data.renameSemester(semester.id, name),
                ),
              ),
            );
          }),
          if (cgpa != null) ...[
            const SizedBox(height: 10),
            StaggeredAnimation(
              index: sheet.length,
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

Add imports if missing: `import 'dart:async';`, `import '../services/sheet_calc.dart';`.

New `_SemesterCard` (name-only, delete flow intact):

```dart
class _SemesterCard extends StatefulWidget {
  final int index;
  final SemesterRecord semester;
  final bool canDelete;
  final VoidCallback onDelete;
  final ValueChanged<String> onRename;

  const _SemesterCard({
    required this.index,
    required this.semester,
    required this.canDelete,
    required this.onDelete,
    required this.onRename,
  });

  @override
  State<_SemesterCard> createState() => _SemesterCardState();
}

class _SemesterCardState extends State<_SemesterCard> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.semester.name);
  }

  @override
  void didUpdateWidget(covariant _SemesterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.semester.name != widget.semester.name &&
        widget.semester.name != _nameController.text) {
      _nameController.text = widget.semester.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final gpa = SheetCalc.semesterGpa(widget.semester);
    final subjectCount = widget.semester.subjects.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: UiCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IdxBadge(text: '${widget.index + 1}'.padLeft(2, '0')),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      filled: false,
                    ),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.fg),
                    onChanged: widget.onRename,
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: InkWell(
                    onTap: widget.canDelete ? widget.onDelete : null,
                    borderRadius: BorderRadius.circular(kRadius),
                    child: Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: widget.canDelete ? p.muted : p.muted.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.semester.legacyGpa.isNotEmpty && subjectCount == 0
                        ? 'Legacy GPA entry'
                        : '$subjectCount subject${subjectCount == 1 ? '' : 's'}',
                    style:
                        TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: p.muted),
                  ),
                ),
                gpa != null
                    ? GradeChip(letter: gpa.toStringAsFixed(2), gpa: gpa)
                    : Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: p.field,
                          borderRadius: BorderRadius.circular(kRadius),
                          border: Border.all(color: p.border),
                        ),
                        child: Text('â€” pending',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700, color: p.muted)),
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

Note: `GradeChip(letter: gpa.toStringAsFixed(2), gpa: gpa)` shows the numeric GPA in the chip (check `GradeChip`'s layout in `ui.dart` â€” if the chip hardcodes letter-sized styling that looks wrong for a number, instead render the existing pending-style `Container` with `Text(gpa.toStringAsFixed(2), style: numStyle(13, FontWeight.w800, p.accentInk))` inside `Container(color: p.accentSoft, ...)`; pick whichever compiles cleanly and keeps the row from overflowing).

- [x] **Step 4: Switch the topbar button**

In `lib/screens/main_shell.dart:92` replace:

```dart
      2 => [GhostButton(label: 'Add semester', icon: Icons.add, onTap: data.addSemester)],
```

with:

```dart
      2 => [GhostButton(label: 'Add semester', icon: Icons.add, onTap: data.addSemesterRecord)],
```

- [x] **Step 5: Run the CGPA tests, verify they PASS**

Run: `flutter test --plain-name "CGPA:"`
Expected: PASS.

- [x] **Step 6: Run gates**

Run: `flutter analyze` â†’ Expected: `No issues found!`
Run: `flutter test` â†’ Expected: all green.

---

### Task 4: Data page â€” layout-C sheet table

**Files:**
- Modify: `lib/screens/storage_page.dart` (full rewrite of build; keep `_showClearDialog`)
- Test: new test in `test/widget_test.dart`

**Interfaces:**
- Consumes: `data.sheet`, `SheetCalc.totalOf/gradeOf/semesterGpa`, `SemesterChips` (Task 2), `data.clearAll`.
- Produces: `StoragePage` becomes StatefulWidget; Task 6 adds the Export button into the header `Row`.

- [x] **Step 1: Write the failing widget test**

Append to `test/widget_test.dart` before the final `}`:

```dart
  testWidgets('Data page: renders the semester sheet table', (tester) async {
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
              'mid': '20', 'final': '40', 'sectional': '15', 'lab': '', 'legacyMarks': ''
            },
            {
              'id': 'b', 'name': 'Chem Lab', 'credits': 1, 'isLab': true,
              'mid': '18', 'final': '39', 'sectional': '20', 'lab': '45', 'legacyMarks': ''
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

    expect(find.text('Physics'), findsOneWidget);
    expect(find.text('Chem Lab'), findsOneWidget);
    expect(find.text('LAB'), findsOneWidget, reason: 'lab badge on the lab subject');
    expect(find.text('75'), findsOneWidget, reason: 'theory total column');
    expect(find.text('122'), findsOneWidget, reason: 'lab total column');
    expect(find.text('Semester 1'), findsWidgets, reason: 'chip + footer');
    expect(find.text('Clear All'), findsOneWidget);
  });
```

Add `import 'dart:convert';` at the very top of `test/widget_test.dart` (first import line).

Sanity values used by the test: Physics 20+40+15 = **75**; Chem Lab 18+39+20+45 = **122**.

- [x] **Step 2: Run test, verify it FAILS**

Run: `flutter test --plain-name "Data page:"`
Expected: FAIL â€” old card list has no `Physics`/`LAB` texts.

- [x] **Step 3: Rewrite `lib/screens/storage_page.dart`**

Keep the imports (add `import 'dart:async';` only if needed â€” it is not; add `import '../services/sheet_calc.dart';` and `import '../widgets/semester_chips.dart';`). Full new file body:

```dart
class StoragePage extends StatefulWidget {
  final VoidCallback? onGoToGpa;
  const StoragePage({super.key, this.onGoToGpa});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  String? _selectedSemesterId;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final data = context.watch<AppData>();
    final sheet = data.sheet;

    if (_selectedSemesterId == null ||
        !sheet.any((s) => s.id == _selectedSemesterId)) {
      _selectedSemesterId = sheet.isNotEmpty ? sheet.first.id : null;
    }
    final selected = sheet.firstWhere((s) => s.id == _selectedSemesterId,
        orElse: () => sheet.first);

    final hasData = sheet.any((s) =>
        s.legacyGpa.isNotEmpty ||
        s.subjects.any((sub) => SheetCalc.totalOf(sub) != null));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!hasData)
            StaggeredAnimation(
              index: 0,
              child: EmptyState(
                title: 'No saved data yet',
                body: 'Start calculating to see results here!',
                buttonLabel: 'Add your first subject',
                onButton: widget.onGoToGpa,
              ),
            )
          else ...[
            StaggeredAnimation(
              index: 0,
              child: Row(
                children: [
                  const Expanded(child: SectionHeader('Saved data')),
                  GhostButton(
                    label: 'Clear All',
                    icon: Icons.delete_outline,
                    danger: true,
                    onTap: () => _showClearDialog(context, data),
                  ),
                ],
              ),
            ),
            StaggeredAnimation(
              index: 1,
              child: SemesterChips(
                labels: sheet.map((s) => s.name).toList(),
                selectedIndex: sheet.indexOf(selected),
                onSelect: (i) => setState(() => _selectedSemesterId = sheet[i].id),
              ),
            ),
            const SizedBox(height: 10),
            StaggeredAnimation(
              index: 2,
              child: UiCard(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: _SheetTable(semester: selected, palette: p),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context, AppData data) {
    final p = Palette.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all saved data?'),
        content: const Text('This will clear all marks and GPA entries.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              data.clearAll();
              Navigator.pop(ctx);
            },
            child: Text('Clear', style: TextStyle(color: p.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
```

Append the table widget at the end of the file:

```dart
class _SheetTable extends StatelessWidget {
  final SemesterRecord semester;
  final Palette palette;

  const _SheetTable({required this.semester, required this.palette});

  static const double _nameW = 130;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final gpa = SheetCalc.semesterGpa(semester);

    const headStyle = TextStyle(
        fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: .4);

    TableRow headerRow = TableRow(children: [
      _cell('SUBJECT', head: true),
      _cell('CR', head: true),
      _cell('MID\n/25', head: true),
      _cell('FINAL\n/50', head: true),
      _cell('SEC\n/25', head: true),
      _cell('LAB\n/50', head: true),
      _cell('TOTAL', head: true),
      _cell('GRADE', head: true),
    ]);

    final rows = <TableRow>[headerRow];
    for (final sub in semester.subjects) {
      final total = SheetCalc.totalOf(sub);
      final grade = SheetCalc.gradeOf(sub);
      rows.add(TableRow(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Row(
            children: [
              Flexible(
                child: Text(sub.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w700, color: p.fg)),
              ),
              if (sub.isLab) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFF5E9),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text('LAB',
                      style: TextStyle(
                          fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
                ),
              ],
            ],
          ),
        ),
        _cell('${SheetCalc.creditsOf(sub)}', numeric: true),
        _cell(sub.mid.isEmpty ? 'â€”' : sub.mid, numeric: true),
        _cell(sub.finalMarks.isEmpty ? 'â€”' : sub.finalMarks, numeric: true),
        _cell(sub.sectional.isEmpty ? 'â€”' : sub.sectional, numeric: true),
        _cell(sub.isLab && sub.lab.isNotEmpty ? sub.lab : 'â€”', numeric: true,
            accent: sub.isLab && sub.lab.isNotEmpty),
        _cell(total == null ? 'â€”' : '${total.toInt()}', numeric: true, bold: true),
        _cell(grade?.letter ?? 'â€”', numeric: true, pill: grade != null),
      ]));
    }

    final creditSum =
        semester.subjects.fold(0, (a, s) => a + SheetCalc.creditsOf(s));
    rows.add(TableRow(children: [
      Container(
        padding: const EdgeInsets.only(top: 10, right: 4),
        child: Text(semester.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: p.fg)),
      ),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            '${semester.subjects.length} subjects Â· $creditSum cr',
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500, color: p.muted),
          ),
        ),
      ),
      const TableCell(child: SizedBox()),
      const TableCell(child: SizedBox()),
      const TableCell(child: SizedBox()),
      const TableCell(child: SizedBox()),
      const TableCell(child: SizedBox()),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: p.accent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(gpa != null ? gpa.toStringAsFixed(2) : 'â€”',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ),
      ),
    ]));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 470),
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(_nameW),
                1: FixedColumnWidth(30),
                2: FixedColumnWidth(42),
                3: FixedColumnWidth(46),
                4: FixedColumnWidth(42),
                5: FixedColumnWidth(42),
                6: FixedColumnWidth(48),
                7: FlexColumnWidth(),
              },
              children: rows,
            ),
          ),
        ),
      ],
    );
  }

  Widget _cell(
    String text, {
    bool head = false,
    bool numeric = false,
    bool bold = false,
    bool pill = false,
    bool accent = false,
  }) {
    final p = palette;
    Widget child;
    if (pill) {
      child = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: p.accentSoft,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: p.accentInk)),
      );
    } else {
      child = Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: numeric ? TextAlign.center : TextAlign.left,
        style: head
            ? const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF94A3B8),
                letterSpacing: .4)
            : TextStyle(
                fontSize: 11,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: accent
                    ? const Color(0xFF16A34A)
                    : (numeric ? const Color(0xFF334155) : p.fg)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
      child: numeric ? Center(child: child) : child,
    );
  }
}
```

Footer `semester G F A` cell: if `gpa == null` the pill shows `â€”` (compile-safe). Remove `_StorageItem` (no longer referenced).

- [x] **Step 4: Run test, verify it PASSES**

Run: `flutter test --plain-name "Data page:"`
Expected: PASS.

- [x] **Step 5: Run gates**

Run: `flutter analyze` â†’ Expected: `No issues found!`
Run: `flutter test` â†’ Expected: all green.

---

### Task 5: Retire the legacy model

**Files:**
- Modify: `lib/providers/app_data.dart`
- Test: full suite; fix any straggler references the grep finds.

**Interfaces:**
- Consumes: Tasks 1â€“4 (every page now reads `sheet`).
- Produces: `AppData` exposes only the sheet API; old keys are no longer written.

- [x] **Step 1: Find every legacy reference**

Run:

```powershell
Select-String -Path "lib\*.dart","lib\**\*.dart","test\*.dart" -Pattern "gpaSubjects|GpaSubject|SemesterGpa[^R]|\baddGpaSubject\b|\bremoveGpaSubject\b|\bupdateGpaSubject\b|\baddSemester\(|\bremoveSemester\(|\bupdateSemester\(|data\.semesters\b|\.subjectCount\b" | Select-Object Path, LineNumber, Line
```

Expected known sites: none in `lib/screens/*` (already migrated); `app_data.dart` definitions themselves; `home_page.dart` uses `data.cgpa`, `data.semesterCount`, `data.totalCredits` (all reimplemented in Task 1 â€” safe). If `subjectCount` is used anywhere, replace its usage with `data.subjectCount` semantics unchanged (already reimplemented).

- [x] **Step 2: Delete legacy code from `app_data.dart`**

- Delete `class GpaSubject` and `class SemesterGpa` entirely.
- Delete fields `List<GpaSubject> _gpaSubjects` and `List<SemesterGpa> _semesters` and their getters `gpaSubjects`/`semesters`.
- Delete methods `addGpaSubject`, `removeGpaSubject`, `updateGpaSubject`, `addSemester`, `removeSemester`, `updateSemester`.
- In `load()`: delete the `mckru_gpa2` parse block, its default-seed block (`_gpaSubjects = [GpaSubject...]`), and the `mckru_cgpa2` parse block + its default-seed block. **Keep `_migrateLegacy` untouched** â€” it reads the raw strings only.
- In `_save()`: delete the `mckru_gpa2` and `mckru_cgpa2` `setString` lines. Keep `mckru_sheet_v1`, `mckru_dark2`, `mckru_onboarded2`, `mckru_name`, `mckru_avatar`.
- In `clearAll()`: delete the legacy loops (`for (final c in _gpaSubjects)...`, `for (final s in _semesters)...`) â€” keep the sheet loop.
- In `resetAll()`: delete `_gpaSubjects = [...]` and `_semesters = [...]` lines â€” keep the sheet reset.

- [x] **Step 3: Re-run the reference grep**

Run the same `Select-String` from Step 1.
Expected: only harmless matches (e.g. `SemesterGpa` substring inside `SemesterRecord` matches `SemesterGpa[^R]`? â€” it will not: `SemesterGpa` is not a substring of `SemesterRecord`. Zero matches expected; if any remain, fix them.)

- [x] **Step 4: Run gates**

Run: `flutter analyze` â†’ Expected: `No issues found!`
Run: `flutter test` â†’ Expected: all green (migration tests still pass â€” they read old keys only during first migration).

---

### Task 6: Excel (.xlsx) export

**Files:**
- Create: `lib/services/sheet_export.dart`, `test/sheet_export_test.dart`
- Modify: `pubspec.yaml` (via `flutter pub add`), `lib/screens/storage_page.dart` (header button)
- Test: `test/sheet_export_test.dart` (new)

**Interfaces:**
- Consumes: `data.sheet`, `data.cgpa`, `SemesterRecord`/`SubjectRecord`, `SheetCalc.*`.
- Produces: `Uint8List buildSheetXlsx(List<SemesterRecord> sheet, {double? cgpa})` in `lib/services/sheet_export.dart`.

- [x] **Step 1: Add dependencies**

Run: `flutter pub add excel share_plus path_provider`
Expected: `Changed N dependencies!` (no resolution errors).

- [x] **Step 2: Write the failing test**

Create `test/sheet_export_test.dart`:

```dart
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cgpa_calculator/providers/app_data.dart';
import 'package:cgpa_calculator/services/sheet_export.dart';

void main() {
  test('buildSheetXlsx produces one sheet per semester plus a Summary', () {
    final bytes = buildSheetXlsx(
      [
        SemesterRecord(id: '1', name: 'Semester 1', subjects: [
          SubjectRecord(
              id: 'a', name: 'Physics', mid: '20', finalMarks: '40', sectional: '15'),
          SubjectRecord(
              id: 'b', name: 'Chem Lab', isLab: true, mid: '18', finalMarks: '39',
              sectional: '20', lab: '45'),
        ]),
        SemesterRecord(id: '2', name: 'Semester 2', legacyGpa: '3.20'),
      ],
      cgpa: 3.40,
    );

    expect(bytes, isNotEmpty);
    final wb = Excel.decodeBytes(bytes);
    expect(wb.tables.keys, containsAll(['Sem 1', 'Sem 2', 'Summary']));
    expect(wb['Sem 1']!.rows.length, greaterThanOrEqualTo(4));
    expect(wb['Sem 1']!.rows[1][0]!.value.toString(), 'Physics');
    expect(wb['Summary']!.rows.length, greaterThanOrEqualTo(3));
  });
}
```

- [x] **Step 3: Run test, verify it FAILS**

Run: `flutter test test/sheet_export_test.dart`
Expected: FAIL â€” `sheet_export.dart` undefined.

- [x] **Step 4: Create `lib/services/sheet_export.dart`**

```dart
import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../providers/app_data.dart';
import 'sheet_calc.dart';

Uint8List buildSheetXlsx(List<SemesterRecord> sheet, {double? cgpa}) {
  final wb = Excel.createExcel();
  for (final defaultName in ['Sheet1', 'Sheet']) {
    if (wb.tables.containsKey(defaultName)) {
      wb.delete(defaultName);
    }
  }

  for (var i = 0; i < sheet.length; i++) {
    final sem = sheet[i];
    final ws = wb['Sem ${i + 1}'];
    ws.appendRow([
      TextCellValue('Subject'),
      TextCellValue('Cr'),
      TextCellValue('Mid /25'),
      TextCellValue('Final /50'),
      TextCellValue('Sec /25'),
      TextCellValue('Lab /50'),
      TextCellValue('Total'),
      TextCellValue('Grade'),
    ]);
    for (final sub in sem.subjects) {
      final total = SheetCalc.totalOf(sub);
      final grade = SheetCalc.gradeOf(sub);
      ws.appendRow([
        TextCellValue(sub.name),
        IntCellValue(SheetCalc.creditsOf(sub)),
        TextCellValue(sub.mid.isEmpty ? '-' : sub.mid),
        TextCellValue(sub.finalMarks.isEmpty ? '-' : sub.finalMarks),
        TextCellValue(sub.sectional.isEmpty ? '-' : sub.sectional),
        TextCellValue(!sub.isLab || sub.lab.isEmpty ? '-' : sub.lab),
        TextCellValue(total == null ? '-' : '${total.toInt()}'),
        TextCellValue(grade?.letter ?? '-'),
      ]);
    }
    ws.appendRow([TextCellValue('')]);
    final gpa = SheetCalc.semesterGpa(sem);
    ws.appendRow([
      TextCellValue(sem.name),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('GPA'),
      TextCellValue(gpa == null ? '-' : gpa.toStringAsFixed(2)),
    ]);
  }

  final summary = wb['Summary'];
  summary.appendRow([TextCellValue('Semester'), TextCellValue('GPA')]);
  for (var i = 0; i < sheet.length; i++) {
    final gpa = SheetCalc.semesterGpa(sheet[i]);
    summary.appendRow([
      TextCellValue(sheet[i].name),
      TextCellValue(gpa == null ? '-' : gpa.toStringAsFixed(2)),
    ]);
  }
  summary.appendRow([
    TextCellValue('CGPA'),
    TextCellValue(cgpa == null ? '-' : cgpa.toStringAsFixed(2)),
  ]);

  final bytes = wb.encode();
  return Uint8List.fromList(bytes ?? const []);
}
```

If the resolved `excel` package version rejects any API above (`TextCellValue`, `appendRow`, `Excel.decodeBytes`), adapt to that version's documented equivalents keeping the same row layout â€” the test defines the contract.

- [x] **Step 5: Run test, verify it PASSES**

Run: `flutter test test/sheet_export_test.dart`
Expected: PASS.

- [x] **Step 6: Add the Export button on the Data page**

In `lib/screens/storage_page.dart`, add imports:

```dart
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/sheet_export.dart';
```

Replace the header `Row` inside the `hasData` branch with:

```dart
            StaggeredAnimation(
              index: 0,
              child: Row(
                children: [
                  const Expanded(child: SectionHeader('Saved data')),
                  GhostButton(
                    label: 'Export Excel',
                    icon: Icons.download_outlined,
                    onTap: () => _exportSheet(context, data),
                  ),
                  const SizedBox(width: 8),
                  GhostButton(
                    label: 'Clear All',
                    icon: Icons.delete_outline,
                    danger: true,
                    onTap: () => _showClearDialog(context, data),
                  ),
                ],
              ),
            ),
```

Add the handler to `_StoragePageState`:

```dart
  Future<void> _exportSheet(BuildContext context, AppData data) async {
    try {
      final bytes = buildSheetXlsx(data.sheet, cgpa: data.cgpa);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/mckru_semester_sheet.xlsx');
      await file.writeAsBytes(bytes, flush: true);
      // share_plus >= 11: SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', name: 'mckru_semester_sheet.xlsx')],
        subject: 'MCKRU semester sheet',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not export the sheet')));
      }
    }
  }
```

If `Share.shareXFiles` is removed in the resolved `share_plus` version, use the `SharePlus.instance.share(ShareParams(files: [...]))` call shown in the comment â€” one or the other must compile; the try/catch stays.

- [x] **Step 7: Add a button-presence widget test**

Append to `test/widget_test.dart`:

```dart
  testWidgets('Data page: export button is present when there is data', (tester) async {
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
              'mid': '20', 'final': '40', 'sectional': '15', 'lab': '', 'legacyMarks': ''
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

    expect(find.text('Export Excel'), findsOneWidget);
  });
```

- [x] **Step 8: Run gates**

Run: `flutter analyze` â†’ Expected: `No issues found!`
Run: `flutter test` â†’ Expected: all green.

---

### Task 7: Final verification

**Files:** none (verification only).

**Interfaces:**
- Consumes: Tasks 1â€“6.
- Produces: green gates + user visual checklist.

- [x] **Step 1: Full automated gates**

Run: `flutter analyze` â†’ Expected: `No issues found!`
Run: `flutter test` â†’ Expected: all tests green.

- [x] **Step 2: Restart the dev server**

Kill any listener on port 8750, then start:

```powershell
Start-Process -FilePath "flutter" -ArgumentList "run","-d","web-server","--web-port=8750","--no-hot" -WorkingDirectory "C:\All Flutter Project\cgpa_calculator" -WindowStyle Hidden -RedirectStandardOutput "run_web.log" -RedirectStandardError "run_web.err.log"
```

Verify `http://127.0.0.1:8750` returns HTTP 200.

- [x] **Step 3: Hand the user the visual checklist**

1. GPA page: semester chips switch lists; `+` adds a semester; subject card shows Mid /25, Final /50, Sectional /25 (Lab /50 appears when Lab toggled); live total + grade chip update while typing; add/delete animations still smooth; **no overflow** at smallest phone width (rotate/resize check).
2. CGPA page: Total CGPA header auto-computed; semester cards show subject count + GPA; rename via name field; delete animates out.
3. Data page: chips + table matches the approved mockup (components, `â€”` cells, LAB badge, footer GPA pill); horizontal scroll inside the table only.
4. Export Excel â†’ share sheet opens with `mckru_semester_sheet.xlsx`; open the file and check `Sem 1` + `Summary` sheets.
5. Fresh profile (clear app data) â†’ onboarding still works; old data (if any) migrated with marks visible in the table.

- [x] **Step 4: Report**

Summarize analyze/test counts + checklist for the user. **No commits** â€” leave changes staged per session rule.
