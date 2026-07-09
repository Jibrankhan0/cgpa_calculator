import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/semester_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/mesh_gradient_background.dart';
import '../widgets/mode_selector.dart';
import '../widgets/hero_gpa_card.dart';
import '../widgets/semester_card.dart';
import '../widgets/course_input_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/empty_state.dart';
import 'marks_sheet_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(semesterProvider.notifier).loadFromLocal());
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(semesterProvider.select((s) => s.mode));
    final selectedIndex = ref.watch(
      semesterProvider.select((s) => s.selectedIndex),
    );
    final courseCount = ref.watch(
      semesterProvider.select((s) => s.semesters[selectedIndex].courses.length),
    );
    final courses = ref.watch(
      semesterProvider.select((s) => s.semesters[selectedIndex].courses),
    );
    final cgpaSemesters = ref.watch(
      cgpaProvider.select((s) => s.semesters),
    );
    final stats = ref.watch(gpaStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x336366F1),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset('assets/logo2.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'GPA',
              style: GoogleFonts.lexend(
                fontSize: 16,
                letterSpacing: 2,
                color: AppTheme.textPrimary(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'CALCULATOR',
              style: GoogleFonts.lexend(
                fontSize: 16,
                letterSpacing: 2,
                color: AppTheme.textMuted(context),
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: AppTheme.accentPrimary,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggle();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.table_chart_rounded,
              color: AppTheme.accentPrimary,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MarksSheetScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: MeshGradientBackground(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 16),
            ModeSelector(
              currentMode: mode,
              onChanged: (m) => ref.read(semesterProvider.notifier).setMode(m),
            ),
            const SizedBox(height: 20),
            HeroGpaCard(
              gpa: mode == CalculationMode.cgpa
                  ? stats.cgpa
                  : stats.semesterGpa,
              label: mode == CalculationMode.cgpa
                  ? 'OVERALL CGPA'
                  : 'SEMESTER GPA',
              totalCredits: stats.totalCredits,
              courseCount: courseCount,
            ),
            const SizedBox(height: 24),
            Text(
              'SEMESTERS',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted(context),
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (mode == CalculationMode.cgpa) ...[
              if (cgpaSemesters.isEmpty)
                const EmptyState(
                  icon: Icons.school_outlined,
                  title: 'No semesters yet',
                  subtitle: 'Add your first semester to start calculating',
                )
              else
                ...cgpaSemesters.map((entry) {
                  return SemesterCard(
                    key: ValueKey(entry.id),
                    semester: entry,
                  );
                }),
            ] else ...[
              if (courses.isEmpty)
                const EmptyState(
                  icon: Icons.book_outlined,
                  title: 'No courses yet',
                  subtitle: 'Add your first course to start calculating',
                )
              else
                ...courses.map((entry) {
                  return CourseInputCard(
                    key: ValueKey(entry.id),
                    course: entry,
                  );
                }),
            ],
            const SizedBox(height: 20),
            GradientButton(
              onPressed: () {
                if (mode == CalculationMode.cgpa) {
                  ref.read(cgpaProvider.notifier).addSemester();
                } else {
                  ref.read(semesterProvider.notifier).addCourse(selectedIndex);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'ADD',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text(
                    'Developed by',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted(context),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'JIBRAN KHAN DEHPAL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary(context),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
