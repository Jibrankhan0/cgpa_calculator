import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cgpa_calculator/providers/gpa_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('GpaProvider starts with empty semester and no subjects', () async {
    final provider = GpaProvider();
    await provider.load();

    expect(provider.semesterName, 'Semester 1');
    expect(provider.subjects, isEmpty);
    expect(provider.gpa, isNull);
  });

  test('GpaProvider addSubject creates a subject with defaults', () async {
    final provider = GpaProvider();
    await provider.load();

    provider.addSubject();

    expect(provider.subjects.length, 1);
    final sub = provider.subjects.first;
    expect(sub.name, 'Subject 1');
    expect(sub.credits, 3);
    expect(sub.isLab, false);
    expect(sub.legacyMarks, '');
  });

  test('GpaProvider removeSubject removes the subject', () async {
    final provider = GpaProvider();
    await provider.load();
    provider.addSubject();
    provider.addSubject();
    final id = provider.subjects.last.id;

    provider.removeSubject(id);

    expect(provider.subjects.length, 1);
    expect(provider.subjects.any((s) => s.id == id), isFalse);
  });

  test('GpaProvider updateSubject updates the subject fields', () async {
    final provider = GpaProvider();
    await provider.load();
    provider.addSubject();
    final id = provider.subjects.first.id;

    provider.updateSubject(id, name: 'Physics', credits: 4, isLab: true, legacyMarks: '85');

    final sub = provider.subjects.first;
    expect(sub.name, 'Physics');
    expect(sub.credits, 4);
    expect(sub.isLab, true);
    expect(sub.legacyMarks, '85');
  });

  test('GpaProvider calculates GPA correctly from subjects', () async {
    final provider = GpaProvider();
    await provider.load();
    provider.addSubject(); // id1
    provider.addSubject(); // id2
    final id1 = provider.subjects[0].id;
    final id2 = provider.subjects[1].id;
    provider.updateSubject(id1, credits: 3, isLab: false, legacyMarks: '85'); // A = 4.0
    provider.updateSubject(id2, credits: 2, isLab: true, legacyMarks: '45'); // lab 45*2=90 -> A = 4.0

    final gpa = provider.gpa;

    expect(gpa, isNotNull);
    // (4.0*3 + 4.0*2) / (3+2) = 4.0
    expect(gpa, closeTo(4.0, 0.01));
  });

  test('GpaProvider persists to SharedPreferences and reloads', () async {
    final provider1 = GpaProvider();
    await provider1.load();
    provider1.addSubject();
    final id = provider1.subjects.first.id;
    provider1.updateSubject(id, name: 'Math', legacyMarks: '90');

    final provider2 = GpaProvider();
    await provider2.load();

    expect(provider2.semesterName, 'Semester 1');
    expect(provider2.subjects.length, 1);
    expect(provider2.subjects.first.name, 'Math');
    expect(provider2.subjects.first.legacyMarks, '90');
  });

  test('GpaProvider semester name can be changed and persists', () async {
    final provider1 = GpaProvider();
    await provider1.load();
    provider1.setSemesterName('Fall 2024');

    final provider2 = GpaProvider();
    await provider2.load();

    expect(provider2.semesterName, 'Fall 2024');
  });
}