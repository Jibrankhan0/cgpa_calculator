import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cgpa_calculator/providers/data_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('DataProvider starts with empty semester list', () async {
    final provider = DataProvider();
    await provider.load();

    expect(provider.semesters, isEmpty);
  });

  test('DataProvider addSemester creates a semester with defaults', () async {
    final provider = DataProvider();
    await provider.load();

    provider.addSemester();

    expect(provider.semesters.length, 1);
    final sem = provider.semesters.first;
    expect(sem.name, 'Semester 1');
    expect(sem.subjects, isEmpty);
  });

  test('DataProvider removeSemester removes the semester', () async {
    final provider = DataProvider();
    await provider.load();
    provider.addSemester();
    provider.addSemester();
    final id = provider.semesters.last.id;

    provider.removeSemester(id);

    expect(provider.semesters.length, 1);
    expect(provider.semesters.any((s) => s.id == id), isFalse);
  });

  test('DataProvider renameSemester updates the semester name', () async {
    final provider = DataProvider();
    await provider.load();
    provider.addSemester();
    final id = provider.semesters.first.id;

    provider.renameSemester(id, 'Fall 2024');

    expect(provider.semesters.first.name, 'Fall 2024');
  });

  test('DataProvider addSubject creates a subject with component fields', () async {
    final provider = DataProvider();
    await provider.load();
    provider.addSemester();
    final semId = provider.semesters.first.id;

    provider.addSubject(semId);

    final sem = provider.semesters.first;
    expect(sem.subjects.length, 1);
    final sub = sem.subjects.first;
    expect(sub.name, 'Subject 1');
    expect(sub.credits, 3);
    expect(sub.isLab, false);
    expect(sub.mid, '');
    expect(sub.finalMarks, '');
    expect(sub.sectional, '');
    expect(sub.lab, '');
  });

  test('DataProvider updateSubject updates component fields', () async {
    final provider = DataProvider();
    await provider.load();
    provider.addSemester();
    final semId = provider.semesters.first.id;
    provider.addSubject(semId);
    final subId = provider.semesters.first.subjects.first.id;

    provider.updateSubject(semId, subId, 
      name: 'Physics', 
      mid: '20', 
      finalMarks: '40', 
      sectional: '15', 
      lab: '30',
      isLab: true,
    );

    final sub = provider.semesters.first.subjects.first;
    expect(sub.name, 'Physics');
    expect(sub.mid, '20');
    expect(sub.finalMarks, '40');
    expect(sub.sectional, '15');
    expect(sub.lab, '30');
    expect(sub.isLab, true);
  });

  test('DataProvider persists to SharedPreferences and reloads', () async {
    final provider1 = DataProvider();
    await provider1.load();
    provider1.addSemester();
    final semId = provider1.semesters.first.id;
    provider1.addSubject(semId);
    final subId = provider1.semesters.first.subjects.first.id;
    provider1.updateSubject(semId, subId, name: 'Chemistry', mid: '22', finalMarks: '45');

    final provider2 = DataProvider();
    await provider2.load();

    expect(provider2.semesters.length, 1);
    expect(provider2.semesters.first.name, 'Semester 1');
    expect(provider2.semesters.first.subjects.length, 1);
    expect(provider2.semesters.first.subjects.first.name, 'Chemistry');
    expect(provider2.semesters.first.subjects.first.mid, '22');
    expect(provider2.semesters.first.subjects.first.finalMarks, '45');
  });
}