import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CgpaSemester {
  final String id;
  String name;
  double gpa;

  CgpaSemester({
    required this.id,
    required this.name,
    required this.gpa,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'gpa': gpa,
      };

  static CgpaSemester fromJson(Map<String, dynamic> json) => CgpaSemester(
        id: json['id'] as String,
        name: json['name'] as String,
        gpa: (json['gpa'] as num).toDouble(),
      );
}

class CgpaProvider extends ChangeNotifier {
  static const _storageKey = 'mckru_cgpa_indep_v1';

  final List<CgpaSemester> _semesters = [];

  List<CgpaSemester> get semesters => List.unmodifiable(_semesters);

  double? get cgpa {
    final entered = _semesters.where((s) => s.gpa > 0).toList();
    if (entered.isEmpty) return null;
    final sum = entered.fold<double>(0, (a, s) => a + s.gpa);
    return sum / entered.length;
  }

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
          ..addAll(list.map((e) => CgpaSemester.fromJson(e as Map<String, dynamic>)));
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

  String _generateId() => 'cgpa_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  void addSemester() {
    _semesters.add(CgpaSemester(
      id: _generateId(),
      name: 'Semester ${_semesters.length + 1}',
      gpa: 0.0,
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

  void updateSemester(String id, {String? name, double? gpa}) {
    final idx = _semesters.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    final s = _semesters[idx];
    s.name = name ?? s.name;
    s.gpa = gpa ?? s.gpa;
    _save();
    notifyListeners();
  }
}