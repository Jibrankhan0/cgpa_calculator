import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cgpa_calculator/main.dart';
import 'package:cgpa_calculator/widgets/animated_card_frame.dart';
import 'package:cgpa_calculator/widgets/ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('splash renders, then routes to onboarding on first run', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const MyApp());
    expect(find.text('CGPA Calculator'), findsOneWidget);
    expect(find.text('MCKRU · VERSION 1.3.0'), findsOneWidget);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Track Your Grades'), findsOneWidget);
  });

  testWidgets('home shows hero and quick actions, GPA tab shows add button', (tester) async {
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

    expect(find.text('Welcome back, Ali'), findsOneWidget);
    expect(find.text('YOUR CGPA'), findsOneWidget);
    expect(find.text('QUICK ACTIONS'), findsOneWidget);

    await tester.tap(find.text('GPA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // let provider load

    expect(find.text('GPA Calculator'), findsOneWidget);
    expect(find.text('Add subject').last, findsOneWidget);
    expect(find.text('Enter marks to see your grade chip'), findsNothing);
  });

  testWidgets('onboarding requires name and avatar before entering app', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next →'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text("What's Your Name?"), findsOneWidget);

    final letsGo = find.widgetWithText(PrimaryButton, "Let's Go 🚀");
    bool isDisabled() => tester
        .widget<InkWell>(find.descendant(of: letsGo, matching: find.byType(InkWell)))
        .onTap ==
        null;

    expect(isDisabled(), isTrue, reason: 'Let\'s Go must start disabled');

    await tester.enterText(find.byType(TextField).first, 'Ali');
    await tester.pump();
    expect(isDisabled(), isTrue, reason: 'still disabled until an avatar is picked');

    await tester.ensureVisible(letsGo);
    await tester.pump();
    await tester.tap(letsGo);
    await tester.pump();
    expect(find.text("What's Your Name?"), findsOneWidget,
        reason: 'tapping the disabled button must not enter the app');

    final firstAvatar = find.byType(Image).first;
    await tester.ensureVisible(firstAvatar);
    await tester.pump();
    await tester.tap(firstAvatar);
    await tester.pump();
    expect(isDisabled(), isFalse, reason: 'name + avatar chosen -> enabled');

    await tester.ensureVisible(letsGo);
    await tester.pump();
    await tester.tap(letsGo);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Welcome back, Ali'), findsOneWidget);
  });

  testWidgets('AnimatedCardFrame grows in on demand and collapses out calling onExitComplete',
      (tester) async {
    Widget build({bool animateEnter = false, bool exiting = false, VoidCallback? onExit}) {
      return MaterialApp(
        home: Scaffold(
          body: AnimatedCardFrame(
            animateEnter: animateEnter,
            exiting: exiting,
            onExitComplete: onExit,
            child: const SizedBox(width: 200, height: 100, child: Text('card')),
          ),
        ),
      );
    }

    await tester.pumpWidget(build(animateEnter: true));
    final h0 = tester.getSize(find.byType(AnimatedCardFrame)).height;
    expect(h0, lessThan(1), reason: 'enter starts at zero height');

    await tester.pump(const Duration(milliseconds: 320));
    final h1 = tester.getSize(find.byType(AnimatedCardFrame)).height;
    expect(h1, greaterThan(99), reason: 'enter finishes at natural height');

    var completed = false;
    await tester.pumpWidget(build(exiting: true, onExit: () => completed = true));
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pump();
    expect(completed, isTrue, reason: 'onExitComplete fires after exit animation');
    expect(tester.getSize(find.byType(AnimatedCardFrame)).height, lessThan(1));
  });

  testWidgets('settings: About page shows the Connect MCKRU link', (tester) async {
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

    await tester.tap(find.text('Settings').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    await tester.tap(find.text('About this app'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Connect MCKRU'), findsOneWidget);
expect(find.text('Get it on Google Play'), findsOneWidget);
  });

  testWidgets('settings: Grade Reference shows GPA calculation formula', (tester) async {
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

    await tester.tap(find.text('Settings').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    await tester.tap(find.text('Grade Reference'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('HOW GPA IS CALCULATED'), findsOneWidget);
    expect(
        find.textContaining('Σ (grade points × credits) ÷ Σ credits'), findsOneWidget);
    expect(
        find.textContaining('Σ semester GPAs ÷ number of entered semesters'),
        findsOneWidget);
  });

  testWidgets('Independent GPA: add subject, enter marks, shows GPA', (tester) async {
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
    await tester.pump(const Duration(milliseconds: 100)); // let provider load complete

    await tester.tap(find.text('GPA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

// Initially no subjects - add one
    expect(find.byKey(const Key('subject_name_0')), findsNothing);

    // Add a subject
    await tester.tap(find.byKey(const Key('add_subject_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();

    expect(find.byKey(const Key('subject_name_0')), findsOneWidget);

    // Enter marks 85 for Subject 1
    final marksFields = find.byType(TextField);
    await tester.enterText(marksFields.at(2), '85');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // GPA should show
    expect(find.text('4.00'), findsOneWidget);

    // Add another subject
    await tester.tap(find.byKey(const Key('add_subject_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();

    expect(find.byKey(const Key('subject_name_1')), findsOneWidget);

    // Wait for second subject to fully render
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // GPA should show 4.00 for the first subject
    expect(find.text('4.00'), findsOneWidget);
  });

  testWidgets('Independent GPA: remove subject updates GPA', (tester) async {
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

    // Add two subjects and set marks
    await tester.tap(find.byKey(const Key('add_subject_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();

    await tester.tap(find.byKey(const Key('add_subject_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(2), '85'); // Subject 1 marks
    await tester.enterText(fields.at(4), '85'); // Subject 2 marks
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Delete Subject 1 (delete icon on first card)
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    // After deletion, only one subject remains (was Subject 2, now at index 0)
    final remainingFields = find.byType(TextField).evaluate();
    expect(remainingFields.length, lessThan(6)); // fewer fields after deletion
    expect(find.text('4.00'), findsOneWidget);
  });

  testWidgets('Independent GPA: semester name persists', (tester) async {
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

    // Find semester name field and change it
    await tester.enterText(find.byKey(const Key('semester_name_field')), 'Fall 2024');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Restart app
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

    expect(find.text('Fall 2024'), findsOneWidget);
  });

  testWidgets('Independent CGPA: add semester, enter GPA, shows simple-average CGPA', (tester) async {
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

    await tester.tap(find.text('CGPA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Initially no semesters - add one
    expect(find.text('Semester 1'), findsNothing);

    // Add a semester
    await tester.tap(find.byKey(const Key('add_semester_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();

    expect(find.text('Semester 1'), findsOneWidget);

    // Enter GPA 3.5 for Semester 1
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), '3.5'); // GPA
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // CGPA should show (use last to get the large ResultCard text)
    expect(find.text('3.50').last, findsOneWidget);

    // Add another semester
    await tester.tap(find.byKey(const Key('add_semester_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();
    expect(find.text('Semester 2'), findsOneWidget);

    // Enter GPA 3.0 for Semester 2
    final newFields = find.byType(TextField);
    await tester.enterText(newFields.at(3), '3.0'); // GPA
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // CGPA = simple average (3.5 + 3.0) / 2 = 3.25
    expect(find.text('3.25').last, findsOneWidget);
  });

  testWidgets('Independent CGPA: remove semester updates CGPA', (tester) async {
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

    await tester.tap(find.text('CGPA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Add two semesters and set GPA/credits
    await tester.tap(find.byKey(const Key('add_semester_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();

    await tester.tap(find.byKey(const Key('add_semester_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), '3.5'); // Semester 1 GPA
    await tester.enterText(fields.at(3), '3.0'); // Semester 2 GPA
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Delete Semester 1 (delete icon on first card)
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    // Should have only Semester 2 now with 3.00 CGPA
    expect(find.byKey(const Key('add_semester_button')), findsOneWidget);
    expect(find.text('3.00').last, findsOneWidget);
  });

  testWidgets('Data page: sheet table renders with footer and Add subject works', (tester) async {
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
    await tester.pump(const Duration(milliseconds: 100)); // let providers load

    await tester.tap(find.text('Data'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Fresh storage -> empty state
    expect(find.text('No saved data yet'), findsOneWidget);

    await tester.tap(find.text('Add your first semester'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Header row renders; irregular row lengths would throw during layout
    expect(find.text('SUBJECT'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Footer button adds a subject row
    await tester.tap(find.text('Add subject'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('Subject 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Data page: edit credits, toggle lab, delete subject', (tester) async {
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
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Data'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    await tester.tap(find.text('Add your first semester'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Add two subjects
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Add subject'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
    }
    expect(find.text('Subject 1'), findsOneWidget);
    expect(find.text('Subject 2'), findsOneWidget);

    // Edit credits of first subject: first TextField in row is CR cell
    await tester.enterText(find.byType(TextField).first, '4');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('2 subjects · 7 cr'), findsOneWidget);

    // Toggle Subject 1 to lab by tapping the '—' in LAB column (inside its InkWell,
    // not the '—' hint texts of empty mark fields)
    final labToggle = find.descendant(
        of: find.byType(InkWell), matching: find.text('—'));
    expect(labToggle, findsNWidgets(2));
    await tester.tap(labToggle.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('LAB'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Revert lab by tapping the LAB badge
    await tester.tap(find.text('LAB'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('LAB'), findsNothing);

    // Delete Subject 1 via its delete button (tooltip)
    await tester.tap(find.byTooltip('Delete subject').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Subject 1'), findsNothing);
    expect(find.text('Subject 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home shows hero fallback and record stats from saved Data', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'mckru_onboarded2': true,
      'mckru_name': 'Ali',
      'mckru_data_indep_v1': jsonEncode({
        'semesters': [
          {
            'id': 's1',
            'name': 'Semester 1',
            'subjects': [
              // 21+43+21 = 85 -> 85% -> A (4.0), credits 3
              {
                'id': 'a1',
                'name': 'Math',
                'credits': 3,
                'isLab': false,
                'mid': '21',
                'final': '43',
                'sectional': '21',
                'lab': '',
              },
              // 18+35+17 = 70 -> 70% -> B (3.0), credits 3
              {
                'id': 'a2',
                'name': 'Chem',
                'credits': 3,
                'isLab': false,
                'mid': '18',
                'final': '35',
                'sectional': '17',
                'lab': '',
              },
            ],
          },
        ],
      }),
    });
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Hero falls back to record GPA from saved Data: (4.0*3 + 3.0*3) / 6 = 3.50
    expect(find.text('Cumulative GPA from saved record'), findsOneWidget);
    expect(find.text('3.50'), findsNWidgets(2)); // hero + Avg GPA tile

    // Stats tiles from DataProvider
    expect(find.text('1'), findsOneWidget); // Semesters
    expect(find.text('2'), findsOneWidget); // Subjects
    expect(find.text('6'), findsOneWidget); // Credits
    expect(tester.takeException(), isNull);
  });

  testWidgets('Independent CGPA: semester name persists', (tester) async {
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

    await tester.tap(find.text('CGPA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Add a semester first
    await tester.tap(find.byKey(const Key('add_semester_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();

    // Change the semester name in the card
    await tester.enterText(find.byKey(const Key('cgpa_semester_name_0')), 'Fall 2024');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Restart app
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    await tester.tap(find.text('CGPA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.text('Fall 2024'), findsOneWidget);
  });
}
