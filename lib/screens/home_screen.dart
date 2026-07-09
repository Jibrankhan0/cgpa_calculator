import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/course.dart';
import '../models/semester_result.dart';
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
  static final _appBarTitleBoldStyle = GoogleFonts.lexend(
    fontSize: 16,
    letterSpacing: 2,
    fontWeight: FontWeight.w900,
  );

  static final _appBarTitleLightStyle = GoogleFonts.lexend(
    fontSize: 16,
    letterSpacing: 2,
    fontWeight: FontWeight.w300,
  );

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    Future.microtask(() => ref.read(semesterProvider.notifier).loadFromLocal());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _getItemCount(CalculationMode mode, List<SemesterResult> cgpaSemesters, List<Course> courses) {
    // Header items: spacer + ModeSelector + spacer + HeroGpaCard + spacer + section header + spacer
    int count = 7;
    
    if (mode == CalculationMode.cgpa) {
      count += cgpaSemesters.isEmpty ? 1 : cgpaSemesters.length;
    } else {
      count += courses.isEmpty ? 1 : courses.length;
    }
    
    // Footer items: spacer + Button + spacer + footer text + spacer
    count += 7;
    
    return count;
  }

  Widget _buildItem(
    int index,
    CalculationMode mode,
    int selectedIndex,
    int courseCount,
    List<Course> courses,
    List<SemesterResult> cgpaSemesters,
    GpaStats stats,
    bool isDark,
  ) {
    // Header items
    if (index == 0) return const SizedBox(height: 16);
    if (index == 1) {
      return ModeSelector(
        currentMode: mode,
        onChanged: (m) => ref.read(semesterProvider.notifier).setMode(m),
      );
    }
    if (index == 2) return const SizedBox(height: 20);
    if (index == 3) {
      return HeroGpaCard(
        gpa: mode == CalculationMode.cgpa ? stats.cgpa : stats.semesterGpa,
        label: mode == CalculationMode.cgpa ? 'OVERALL CGPA' : 'SEMESTER GPA',
        totalCredits: stats.totalCredits,
        courseCount: courseCount,
      );
    }
    if (index == 4) return const SizedBox(height: 24);
    if (index == 5) {
      return Text(
        'SEMESTERS',
        style: TextStyle(
          fontSize: 11,
          color: AppTheme.textMuted(context),
          letterSpacing: 1.5,
          fontWeight: FontWeight.w800,
        ),
      );
    }
    if (index == 6) return const SizedBox(height: 12);

    // Content items
    int contentIndex = index - 7;
    int contentCount = mode == CalculationMode.cgpa ? cgpaSemesters.length : courses.length;

    if (contentCount == 0) {
      if (contentIndex == 0) {
        return EmptyState(
          icon: mode == CalculationMode.cgpa ? Icons.school_outlined : Icons.book_outlined,
          title: mode == CalculationMode.cgpa ? 'No semesters yet' : 'No courses yet',
          subtitle: mode == CalculationMode.cgpa
              ? 'Add your first semester to start calculating'
              : 'Add your first course to start calculating',
        );
      }
    } else {
      if (contentIndex < contentCount) {
        if (mode == CalculationMode.cgpa) {
          final entry = cgpaSemesters[contentIndex];
          return SemesterCard(
            key: ValueKey(entry.id),
            semester: entry,
          );
        } else {
          final entry = courses[contentIndex];
          return CourseInputCard(
            key: ValueKey(entry.id),
            course: entry,
          );
        }
      }
      contentIndex -= contentCount;
    }

    // Footer items
    int footerIndex = contentIndex;
    if (contentCount == 0) footerIndex -= 1; // Account for empty state
    
    if (footerIndex == 0) return const SizedBox(height: 20);
    if (footerIndex == 1) {
      return GradientButton(
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
      );
    }
    if (footerIndex == 2) return const SizedBox(height: 24);
    if (footerIndex == 3) {
      return Center(
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
      );
    }
    if (footerIndex == 4) return const SizedBox(height: 32);

    return const SizedBox.shrink();
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
              style: _appBarTitleBoldStyle.copyWith(color: AppTheme.textPrimary(context)),
            ),
            const SizedBox(width: 4),
            Text(
              'CALCULATOR',
              style: _appBarTitleLightStyle.copyWith(color: AppTheme.textMuted(context)),
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
        child: ListView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _getItemCount(mode, cgpaSemesters, courses),
          itemBuilder: (context, index) {
            return _buildItem(index, mode, selectedIndex, courseCount, courses, cgpaSemesters, stats, isDark);
          },
        ),
      ),
    );
  }
}
