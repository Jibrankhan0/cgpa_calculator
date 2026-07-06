import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/semester_provider.dart';
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
    final semester = ref.watch(
      semesterProvider.select((s) => s.semesters[selectedIndex]),
    );
    final cgpaState = ref.watch(cgpaProvider);
    final stats = ref.watch(gpaStatsProvider);

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
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset('assets/logo2.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'GPA',
              style: GoogleFonts.lexend(
                fontSize: 16,
                letterSpacing: 2,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'CALCULATOR',
              style: GoogleFonts.lexend(
                fontSize: 16,
                letterSpacing: 2,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
        actions: [
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
            const SizedBox(height: 20),
            ModeSelector(
              currentMode: mode,
              onChanged: (m) => ref.read(semesterProvider.notifier).setMode(m),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 24),
            HeroGpaCard(
              gpa: mode == CalculationMode.cgpa
                  ? stats.cgpa
                  : stats.semesterGpa,
              label: mode == CalculationMode.cgpa
                  ? 'OVERALL CGPA'
                  : 'SEMESTER GPA',
              totalCredits: stats.totalCredits,
              courseCount: semester.courses.length,
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 28),
            Text(
              mode == CalculationMode.cgpa ? 'SEMESTERS' : 'COURSES',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textMuted,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            if (mode == CalculationMode.cgpa) ...[
              if (cgpaState.semesters.isEmpty)
                const EmptyState(
                  icon: Icons.school_outlined,
                  title: 'No semesters yet',
                  subtitle: 'Add your first semester to start calculating',
                )
              else
                ...cgpaState.semesters.asMap().entries.map((entry) {
                  return SemesterCard(
                    key: ValueKey(entry.value.id),
                    semester: entry.value,
                  ).animate().fadeIn(
                        delay: Duration(milliseconds: 50 * entry.key),
                        duration: 300.ms,
                      ).slideY(begin: 0.05, end: 0);
                }),
            ] else ...[
              if (semester.courses.isEmpty)
                const EmptyState(
                  icon: Icons.book_outlined,
                  title: 'No courses yet',
                  subtitle: 'Add your first course to start calculating',
                )
              else
                ...semester.courses.asMap().entries.map((entry) {
                  return CourseInputCard(
                    key: ValueKey(entry.value.id),
                    course: entry.value,
                  ).animate().fadeIn(
                        delay: Duration(milliseconds: 50 * entry.key),
                        duration: 300.ms,
                      ).slideY(begin: 0.05, end: 0);
                }),
            ],
            const SizedBox(height: 24),
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
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    mode == CalculationMode.cgpa
                        ? 'ADD SEMESTER'
                        : 'ADD COURSE',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Text(
                    'Developed by',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'JIBRAN KHAN DEHPAL',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
