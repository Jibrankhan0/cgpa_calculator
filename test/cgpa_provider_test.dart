import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cgpa_calculator/providers/cgpa_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('CgpaProvider starts with empty semester list', () async {
    final provider = CgpaProvider();
    await provider.load();

    expect(provider.semesters, isEmpty);
    expect(provider.cgpa, isNull);
  });

  test('CgpaProvider addSemester creates a semester with defaults', () async {
    final provider = CgpaProvider();
    await provider.load();

    provider.addSemester();

    expect(provider.semesters.length, 1);
    final sem = provider.semesters.first;
    expect(sem.name, 'Semester 1');
    expect(sem.gpa, 0.0);
  });

  test('CgpaProvider removeSemester removes the semester', () async {
    final provider = CgpaProvider();
    await provider.load();
    provider.addSemester();
    provider.addSemester();
    final id = provider.semesters.last.id;

    provider.removeSemester(id);

    expect(provider.semesters.length, 1);
    expect(provider.semesters.any((s) => s.id == id), isFalse);
  });

  test('CgpaProvider updateSemester updates the semester fields', () async {
    final provider = CgpaProvider();
    await provider.load();
    provider.addSemester();
    final id = provider.semesters.first.id;

    provider.updateSemester(id, name: 'Fall 2024', gpa: 3.5);

    final sem = provider.semesters.first;
    expect(sem.name, 'Fall 2024');
    expect(sem.gpa, 3.5);
  });

  test('CgpaProvider calculates CGPA as simple average of entered GPAs', () async {
    final provider = CgpaProvider();
    await provider.load();
    provider.addSemester(); // id1
    provider.addSemester(); // id2
    final id1 = provider.semesters[0].id;
    final id2 = provider.semesters[1].id;
    provider.updateSemester(id1, gpa: 4.0);
    provider.updateSemester(id2, gpa: 3.0);

    final cgpa = provider.cgpa;

    expect(cgpa, isNotNull);
    // (4.0 + 3.0) / 2 = 3.5
    expect(cgpa, closeTo(3.5, 0.01));

    // A freshly added semester (gpa 0.0, not yet entered) is excluded
    provider.addSemester();
    expect(provider.cgpa, closeTo(3.5, 0.01));
  });

  test('CgpaProvider persists to SharedPreferences and reloads', () async {
    final provider1 = CgpaProvider();
    await provider1.load();
    provider1.addSemester();
    final id = provider1.semesters.first.id;
    provider1.updateSemester(id, name: 'Fall 2024', gpa: 3.7);

    final provider2 = CgpaProvider();
    await provider2.load();

    expect(provider2.semesters.length, 1);
    expect(provider2.semesters.first.name, 'Fall 2024');
    expect(provider2.semesters.first.gpa, 3.7);
  });

  test('CgpaProvider ignores legacy credits key in stored JSON', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'mckru_cgpa_indep_v1':
          '{"semesters":[{"id":"s1","name":"Fall 2024","gpa":3.2,"credits":15}]}',
    });
    final provider = CgpaProvider();
    await provider.load();

    expect(provider.semesters.length, 1);
    expect(provider.semesters.first.gpa, 3.2);
    expect(provider.cgpa, closeTo(3.2, 0.01));
  });
}