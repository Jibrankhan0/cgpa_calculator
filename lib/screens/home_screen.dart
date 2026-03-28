import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/semester_provider.dart';
import '../widgets/mesh_gradient_background.dart';
import '../widgets/bento_card.dart';
import '../widgets/course_row.dart';
import '../widgets/neomorphic_button.dart';
import '../widgets/semester_row.dart';
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

  Color _getGpaColor(double gpa) {
    if (gpa >= 3.5) return Colors.greenAccent;
    if (gpa >= 2.5) return Colors.amberAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    // Watch only top-level state needed for the main layout
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
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/new_logo3.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              mode == CalculationMode.gpa ? 'GPA' : 'CGPA',
              style: GoogleFonts.lexend(
                fontSize: 16,
                letterSpacing: 2,
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'CALCULATOR',
              style: GoogleFonts.lexend(
                fontSize: 16,
                letterSpacing: 2,
                color: Colors.white.withOpacity(0.4),
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.table_chart_outlined,
              color: Colors.cyanAccent,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MarksSheetScreen()),
            ),
            tooltip: 'View Marks Sheet',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: MeshGradientBackground(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 20),
                _buildModeSelector(mode),
                const SizedBox(height: 24),
                _buildBentoGrid(stats, mode),
                const SizedBox(height: 32),
                if (mode == CalculationMode.cgpa) ...[
                  const Text(
                    'SEMESTERS',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white30,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSemesterHeader(),
                  const SizedBox(height: 8),
                  ...cgpaState.semesters.map((sem) {
                    return SemesterRow(key: ValueKey(sem.id), semester: sem);
                  }),
                ] else ...[
                  const Text(
                    'COURSES',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white30,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCourseHeader(),
                  const SizedBox(height: 8),
                  ...semester.courses.asMap().entries.map((entry) {
                    final course = entry.value;
                    return CourseRow(key: ValueKey(course.id), course: course);
                  }),
                ],
                const SizedBox(height: 24),
                NeomorphicButton(
                  onPressed: () {
                    if (mode == CalculationMode.cgpa) {
                      ref.read(cgpaProvider.notifier).addSemester();
                    } else {
                      ref
                          .read(semesterProvider.notifier)
                          .addCourse(selectedIndex);
                    }
                    HapticFeedback.mediumImpact();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, color: Colors.cyanAccent),
                      const SizedBox(width: 8),
                      Text(
                        mode == CalculationMode.cgpa
                            ? 'ADD SEMESTER'
                            : 'ADD COURSE',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Developed by',
                        style: GoogleFonts.lexend(
                          fontSize: 10,
                          color: Colors.white24,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'JIBRAN KHAN DEHPAL',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white38,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector(CalculationMode currentMode) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          _buildModeButton(CalculationMode.gpa, 'GPA (Single)', currentMode),
          _buildModeButton(CalculationMode.cgpa, 'CGPA (Multi)', currentMode),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    CalculationMode mode,
    String label,
    CalculationMode currentMode,
  ) {
    final isSelected = currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(semesterProvider.notifier).setMode(mode);
          HapticFeedback.selectionClick();
        },
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.cyanAccent.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.cyanAccent : Colors.white38,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBentoGrid(dynamic stats, CalculationMode mode) {
    return RepaintBoundary(
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: BentoCard(
              title: mode == CalculationMode.cgpa
                  ? 'OVERALL CGPA'
                  : 'SEMESTER GPA',
              glowColor: _getGpaColor(
                mode == CalculationMode.cgpa ? stats.cgpa : stats.semesterGpa,
              ),
              content: Text(
                (mode == CalculationMode.cgpa ? stats.cgpa : stats.semesterGpa)
                    .toStringAsFixed(2),
                style: GoogleFonts.lexend(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _getGpaColor(
                    mode == CalculationMode.cgpa
                        ? stats.cgpa
                        : stats.semesterGpa,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                if (mode != CalculationMode.cgpa)
                  BentoCard(
                    title: 'CREDITS',
                    content: Text(
                      stats.totalCredits.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const SizedBox(width: 48), // Space for lab icon
          const Expanded(
            flex: 4,
            child: Text(
              'COURSE',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'C',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'M',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'G',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 44), // Space for delete icon
        ],
      ),
    );
  }

  Widget _buildSemesterHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(width: 4),
          Expanded(
            flex: 4,
            child: Text(
              'SEMESTER',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Center(
              child: Text(
                'GPA',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 52), // Delete icon space
        ],
      ),
    );
  }
}
