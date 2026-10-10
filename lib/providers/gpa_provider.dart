import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/gpa_service.dart';

class GpaSubject {
  final String id;
  String name;
  int credits;
  bool isLab;
  String legacyMarks;

  GpaSubject({
    required this.id,
    required this.name,
    required this.credits,
    required this.isLab,
    required this.legacyMarks,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'credits': credits,
        'isLab': isLab,
        'legacyMarks': legacyMarks,
      };

  static GpaSubject fromJson(Map<String, dynamic> json) => GpaSubject(
        id: json['id'] as String,
        name: json['name'] as String,
        credits: json['credits'] as int,
        isLab: json['isLab'] as bool,
        legacyMarks: json['legacyMarks'] as String,
      );
}

class GpaProvider extends ChangeNotifier {
  static const _storageKey = 'mckru_gpa_indep_v1';

  String _semesterName = 'Semester 1';
  final List<GpaSubject> _subjects = [];

  String get semesterName => _semesterName;
  List<GpaSubject> get subjects => List.unmodifiable(_subjects);

  double? get gpa {
    if (_subjects.isEmpty) return null;
    double totalPoints = 0;
    int totalCredits = 0;
    for (final s in _subjects) {
      final grade = _gradeOf(s);
      if (grade == null) continue;
      totalPoints += grade.gpa * _creditsOf(s);
      totalCredits += _creditsOf(s);
    }
    if (totalCredits == 0) return null;
    return totalPoints / totalCredits;
  }

  int _creditsOf(GpaSubject s) => s.isLab ? 1 : s.credits;

  double? _percentOf(GpaSubject s) {
    if (s.legacyMarks.isEmpty) return null;
    final v = double.tryParse(s.legacyMarks);
    if (v == null) return null;
    return s.isLab ? v * 2 : v;
  }

  GradeInfo? _gradeOf(GpaSubject s) {
    final p = _percentOf(s);
    if (p == null) return null;
    return GpaService.getGradeFromMarks(p);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null) return;
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      _semesterName = data['semesterName'] as String? ?? 'Semester 1';
      final list = data['subjects'] as List<dynamic>?;
      if (list != null) {
        _subjects
          ..clear()
          ..addAll(list.map((e) => GpaSubject.fromJson(e as Map<String, dynamic>)));
      }
    } catch (_) {
      // ignore corrupt data
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'semesterName': _semesterName,
      'subjects': _subjects.map((e) => e.toJson()).toList(),
    };
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  int _idCounter = 0;

  String _generateId() => 'gpa_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  void addSubject() {
    _subjects.add(GpaSubject(
      id: _generateId(),
      name: 'Subject ${_subjects.length + 1}',
      credits: 3,
      isLab: false,
      legacyMarks: '',
    ));
    _save();
    notifyListeners();
  }

  void removeSubject(String id) {
    if (_subjects.length <= 1) return;
    _subjects.removeWhere((s) => s.id == id);
    _save();
    notifyListeners();
  }

  void updateSubject(String id, {String? name, int? credits, bool? isLab, String? legacyMarks}) {
    final idx = _subjects.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    final s = _subjects[idx];
    s.name = name ?? s.name;
    s.credits = credits ?? s.credits;
    s.isLab = isLab ?? s.isLab;
    s.legacyMarks = legacyMarks ?? s.legacyMarks;
    _save();
    notifyListeners();
  }

  void setSemesterName(String name) {
    _semesterName = name;
    _save();
    notifyListeners();
  }
}