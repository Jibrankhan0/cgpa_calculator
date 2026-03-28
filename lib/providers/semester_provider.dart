import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/course.dart';
import '../models/semester.dart';
import '../models/semester_result.dart';
import '../services/gpa_service.dart';

enum CalculationMode { gpa, cgpa }

class SemesterState {
  final List<Semester> semesters;
  final int selectedIndex;
  final CalculationMode mode;

  SemesterState({
    required this.semesters,
    required this.selectedIndex,
    this.mode = CalculationMode.cgpa,
  });

  SemesterState copyWith({
    List<Semester>? semesters,
    int? selectedIndex,
    CalculationMode? mode,
  }) {
    return SemesterState(
      semesters: semesters ?? this.semesters,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      mode: mode ?? this.mode,
    );
  }

  Map<String, dynamic> toJson() => {
    'semesters': semesters.map((x) => x.toJson()).toList(),
    'selectedIndex': selectedIndex,
    'mode': mode.index,
  };

  factory SemesterState.fromJson(Map<String, dynamic> json) => SemesterState(
    semesters: List<Semester>.from(
      json['semesters'].map((x) => Semester.fromJson(x)),
    ),
    selectedIndex: json['selectedIndex'],
    mode: CalculationMode.values[json['mode'] ?? 1],
  );
}

final semesterProvider = NotifierProvider<SemesterNotifier, SemesterState>(() {
  return SemesterNotifier();
});

class SemesterNotifier extends Notifier<SemesterState> {
  String get storageKey => 'semester_cache_v1';

  @override
  SemesterState build() {
    return SemesterState(
      semesters: [
        Semester(
          id: const Uuid().v4(),
          name: 'Semester 1',
          courses: [
            Course(
              id: const Uuid().v4(),
              name: '',
              creditHours: 3.0,
              grade: 'A',
            ),
          ],
        ),
      ],
      selectedIndex: 0,
    );
  }

  Future<void> loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(storageKey);
      if (data != null) {
        state = SemesterState.fromJson(jsonDecode(data));
      }
    } catch (e) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(state.toJson()));
  }

  void setMode(CalculationMode mode) {
    state = state.copyWith(mode: mode);
    _save();
  }

  void addSemester() {
    final existingNumbers = state.semesters
        .map((s) {
          final match = RegExp(r'Semester (\d+)').firstMatch(s.name);
          return match != null ? int.tryParse(match.group(1)!) : null;
        })
        .whereType<int>()
        .toSet();

    int nextNum = 1;
    while (existingNumbers.contains(nextNum)) {
      nextNum++;
    }

    state = state.copyWith(
      semesters: [
        ...state.semesters,
        Semester(
          id: const Uuid().v4(),
          name: 'Semester $nextNum',
          courses: [
            Course(
              id: const Uuid().v4(),
              name: '',
              creditHours: 3.0,
              grade: 'A',
            ),
          ],
        ),
      ],
      selectedIndex: state.semesters.length,
    );
    _save();
  }

  void removeSemester(int index) {
    if (state.semesters.length > 1) {
      final newList = [...state.semesters];
      newList.removeAt(index);
      int newSelectedIndex = state.selectedIndex;
      if (newSelectedIndex >= newList.length) {
        newSelectedIndex = newList.length - 1;
      }
      state = state.copyWith(
        semesters: newList,
        selectedIndex: newSelectedIndex,
      );
      _save();
    }
  }

  void selectSemester(int index) {
    state = state.copyWith(selectedIndex: index);
    _save();
  }

  void addCourse(int semesterIndex) {
    final selectedSem = state.semesters[semesterIndex];
    final updatedSem = selectedSem.copyWith(
      courses: [
        ...selectedSem.courses,
        Course(
          id: const Uuid().v4(),
          name: '',
          creditHours: 3.0,
          grade: 'F',
          totalMarks: 0.0,
        ),
      ],
    );
    final newList = [...state.semesters];
    newList[semesterIndex] = updatedSem;
    state = state.copyWith(semesters: newList);
    _save();
  }

  void removeCourse(String courseId) {
    final newList = state.semesters.map((sem) {
      if (sem.courses.any((c) => c.id == courseId)) {
        return sem.copyWith(
          courses: sem.courses.where((c) => c.id != courseId).toList(),
        );
      }
      return sem;
    }).toList();
    state = state.copyWith(semesters: newList);
    _save();
  }

  void updateCourse(
    String courseId, {
    String? name,
    double? creditHours,
    String? grade,
    bool? isPractical,
    double? midMarks,
    double? finalMarks,
    double? sessionalMarks,
    double? totalMarks,
  }) {
    final newList = state.semesters.map((sem) {
      if (sem.courses.any((c) => c.id == courseId)) {
        return sem.copyWith(
          courses: sem.courses.map((c) {
            if (c.id == courseId) {
              String? newGrade = grade;
              double? newMid = midMarks;
              double? newFinal = finalMarks;
              double? newSessional = sessionalMarks;
              double? newTotal = totalMarks;

              if (totalMarks != null ||
                  midMarks != null ||
                  finalMarks != null ||
                  sessionalMarks != null ||
                  isPractical != null) {
                final calculatedTotal =
                    totalMarks ??
                    ((midMarks ?? c.midMarks) +
                        (finalMarks ?? c.finalMarks) +
                        (sessionalMarks ?? c.sessionalMarks));
                newGrade = GpaService.getGradeFromMarks(
                  calculatedTotal,
                  isPractical: isPractical ?? c.isPractical,
                );
              } else if (grade != null && grade != c.grade) {
                newTotal = GpaService.getRepresentativeMarks(
                  grade,
                  isPractical: isPractical ?? c.isPractical,
                );
                newMid = 0;
                newFinal = 0;
                newSessional = 0;
              }

              return c.copyWith(
                name: name,
                creditHours: creditHours,
                grade: newGrade,
                isPractical: isPractical,
                midMarks: newMid,
                finalMarks: newFinal,
                sessionalMarks: newSessional,
                totalMarks: newTotal,
              );
            }
            return c;
          }).toList(),
        );
      }
      return sem;
    }).toList();
    state = state.copyWith(semesters: newList);
    _save();
  }
}

class CgpaState {
  final List<SemesterResult> semesters;

  CgpaState({required this.semesters});

  CgpaState copyWith({List<SemesterResult>? semesters}) {
    return CgpaState(semesters: semesters ?? this.semesters);
  }

  Map<String, dynamic> toJson() => {
    'semesters': semesters.map((x) => x.toJson()).toList(),
  };

  factory CgpaState.fromJson(Map<String, dynamic> json) => CgpaState(
    semesters: List<SemesterResult>.from(
      json['semesters'].map((x) => SemesterResult.fromJson(x)),
    ),
  );
}

final cgpaProvider = NotifierProvider<CgpaNotifier, CgpaState>(() {
  return CgpaNotifier();
});

class CgpaNotifier extends Notifier<CgpaState> {
  String get storageKey => 'cgpa_cache_v1';

  @override
  CgpaState build() {
    return CgpaState(
      semesters: [
        SemesterResult(
          id: const Uuid().v4(),
          name: 'Semester 1',
          creditHours: 3.0,
          gpa: 3.0,
        ),
      ],
    );
  }

  Future<void> loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(storageKey);
      if (data != null) {
        state = CgpaState.fromJson(jsonDecode(data));
      }
    } catch (e) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(state.toJson()));
  }

  void addSemester() {
    final existingNumbers = state.semesters
        .map((s) {
          final match = RegExp(r'Semester (\d+)').firstMatch(s.name);
          return match != null ? int.tryParse(match.group(1)!) : null;
        })
        .whereType<int>()
        .toSet();

    int nextNum = 1;
    while (existingNumbers.contains(nextNum)) {
      nextNum++;
    }

    state = state.copyWith(
      semesters: [
        ...state.semesters,
        SemesterResult(
          id: const Uuid().v4(),
          name: 'Semester $nextNum',
          creditHours: 3.0,
          gpa: 0.0,
        ),
      ],
    );
    _save();
  }

  void removeSemester(String id) {
    if (state.semesters.length > 1) {
      state = state.copyWith(
        semesters: state.semesters.where((s) => s.id != id).toList(),
      );
      _save();
    }
  }

  void updateSemester(
    String id, {
    String? name,
    double? creditHours,
    double? gpa,
  }) {
    state = state.copyWith(
      semesters: state.semesters.map((s) {
        if (s.id == id) {
          return s.copyWith(name: name, creditHours: creditHours, gpa: gpa);
        }
        return s;
      }).toList(),
    );
    _save();
  }
}

final marksSheetProvider = NotifierProvider<MarksSheetNotifier, SemesterState>(
  () {
    return MarksSheetNotifier();
  },
);

class MarksSheetNotifier extends SemesterNotifier {
  @override
  String get storageKey => 'marks_sheet_cache_v1';

  @override
  SemesterState build() {
    return SemesterState(
      semesters: [
        Semester(
          id: const Uuid().v4(),
          name: 'Semester 1',
          courses: [
            Course(
              id: const Uuid().v4(),
              name: '',
              creditHours: 3.0,
              grade: 'A',
              totalMarks: 85.0,
            ),
          ],
        ),
      ],
      selectedIndex: 0,
    );
  }
}

final gpaStatsProvider = Provider((ref) {
  final mode = ref.watch(semesterProvider.select((s) => s.mode));

  if (mode == CalculationMode.cgpa) {
    final cgpaState = ref.watch(cgpaProvider);
    double totalGpa = 0;

    for (final sem in cgpaState.semesters) {
      totalGpa += sem.gpa;
    }

    final int numSemesters = cgpaState.semesters.length;
    // The user specified: for 4 semesters, sum GPAs and divide by 16.
    // Mathematically, (Sum / 16) is out of 1.0. To keep CGPA out of 4.0,
    // (Sum / 16) * 4 = Sum / 4. Thus we divide the sum by the number of semesters.
    final cgpa = numSemesters > 0 ? totalGpa / numSemesters : 0.0;

    return (
      cgpa: cgpa,
      semesterGpa: 0.0,
      totalCredits: 0.0,
      qualityPoints: totalGpa,
    );
  } else {
    final semesterState = ref.watch(semesterProvider);
    return _calculateStats(semesterState);
  }
});

final marksStatsProvider = Provider((ref) {
  final semesterState = ref.watch(marksSheetProvider);
  return _calculateStats(semesterState);
});

dynamic _calculateStats(SemesterState semesterState) {
  double totalCreditsAll = 0;
  double totalQualityPointsAll = 0;
  double selectedSemesterCredits = 0;
  double selectedSemesterQualityPoints = 0;

  for (int i = 0; i < semesterState.semesters.length; i++) {
    final sem = semesterState.semesters[i];
    double semCredits = 0;
    double semPoints = 0;
    for (final course in sem.courses) {
      final points = GpaService.getPoints(course.grade);
      semPoints += points * course.creditHours;
      semCredits += course.creditHours;
    }
    totalCreditsAll += semCredits;
    totalQualityPointsAll += semPoints;
    if (i == semesterState.selectedIndex) {
      selectedSemesterCredits = semCredits;
      selectedSemesterQualityPoints = semPoints;
    }
  }

  final cgpa = totalCreditsAll > 0
      ? totalQualityPointsAll / totalCreditsAll
      : 0.0;
  final semesterGpa = selectedSemesterCredits > 0
      ? selectedSemesterQualityPoints / selectedSemesterCredits
      : 0.0;

  return (
    cgpa: cgpa,
    semesterGpa: semesterGpa,
    totalCredits: totalCreditsAll,
    qualityPoints: totalQualityPointsAll,
  );
}
