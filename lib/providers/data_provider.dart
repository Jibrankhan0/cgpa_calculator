import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataSubject {
  final String id;
  String name;
  int credits;
  bool isLab;
  String mid;
  String finalMarks;
  String sectional;
  String lab;

  DataSubject({
    required this.id,
    required this.name,
    required this.credits,
    required this.isLab,
    required this.mid,
    required this.finalMarks,
    required this.sectional,
    required this.lab,
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
      };

  static DataSubject fromJson(Map<String, dynamic> json) => DataSubject(
        id: json['id'] as String,
        name: json['name'] as String,
        credits: json['credits'] as int,
        isLab: json['isLab'] as bool,
        mid: json['mid'] as String,
        finalMarks: json['final'] as String,
        sectional: json['sectional'] as String,
        lab: json['lab'] as String,
      );
}

class DataSemester {
  final String id;
  String name;
  final List<DataSubject> subjects;

  DataSemester({
    required this.id,
    required this.name,
    required this.subjects,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subjects': subjects.map((e) => e.toJson()).toList(),
      };

  static DataSemester fromJson(Map<String, dynamic> json) => DataSemester(
        id: json['id'] as String,
        name: json['name'] as String,
        subjects: (json['subjects'] as List<dynamic>)
            .map((e) => DataSubject.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DataProvider extends ChangeNotifier {
  static const _storageKey = 'mckru_data_indep_v1';

  final List<DataSemester> _semesters = [];

  List<DataSemester> get semesters => List.unmodifiable(_semesters);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null) return;
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final list = data['semesters'] as List<dynamic>?;
      if (list != null) {
        _semesters
          ..clear()
          ..addAll(list.map((e) => DataSemester.fromJson(e as Map<String, dynamic>)));
      }
    } catch (_) {
      // ignore corrupt data
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'semesters': _semesters.map((e) => e.toJson()).toList(),
    };
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  int _idCounter = 0;

  String _generateId() => 'data_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  void addSemester() {
    _semesters.add(DataSemester(
      id: _generateId(),
      name: 'Semester ${_semesters.length + 1}',
      subjects: [],
    ));
    _save();
    notifyListeners();
  }

  void removeSemester(String id) {
    if (_semesters.length <= 1) return;
    _semesters.removeWhere((s) => s.id == id);
    _save();
    notifyListeners();
  }

  void renameSemester(String id, String name) {
    final idx = _semesters.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    _semesters[idx].name = name;
    _save();
    notifyListeners();
  }

  void addSubject(String semesterId) {
    final semIdx = _semesters.indexWhere((s) => s.id == semesterId);
    if (semIdx == -1) return;
    _semesters[semIdx].subjects.add(DataSubject(
      id: _generateId(),
      name: 'Subject ${_semesters[semIdx].subjects.length + 1}',
      credits: 3,
      isLab: false,
      mid: '',
      finalMarks: '',
      sectional: '',
      lab: '',
    ));
    _save();
    notifyListeners();
  }

  void removeSubject(String semesterId, String subjectId) {
    final semIdx = _semesters.indexWhere((s) => s.id == semesterId);
    if (semIdx == -1) return;
    if (_semesters[semIdx].subjects.length <= 1) return;
    _semesters[semIdx].subjects.removeWhere((s) => s.id == subjectId);
    _save();
    notifyListeners();
  }

  void updateSubject(String semesterId, String subjectId, {
    String? name,
    int? credits,
    bool? isLab,
    String? mid,
    String? finalMarks,
    String? sectional,
    String? lab,
  }) {
    final semIdx = _semesters.indexWhere((s) => s.id == semesterId);
    if (semIdx == -1) return;
    final subIdx = _semesters[semIdx].subjects.indexWhere((s) => s.id == subjectId);
    if (subIdx == -1) return;
    final s = _semesters[semIdx].subjects[subIdx];
    s.name = name ?? s.name;
    s.credits = credits ?? s.credits;
    s.isLab = isLab ?? s.isLab;
    s.mid = mid ?? s.mid;
    s.finalMarks = finalMarks ?? s.finalMarks;
    s.sectional = sectional ?? s.sectional;
    s.lab = lab ?? s.lab;
    _save();
    notifyListeners();
  }

  void clearAll() {
    _semesters.clear();
    _save();
    notifyListeners();
  }
}