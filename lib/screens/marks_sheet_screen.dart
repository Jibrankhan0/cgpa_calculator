import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/semester_provider.dart';
import '../services/gpa_service.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mesh_gradient_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/course_input_card.dart';
import '../widgets/empty_state.dart';

class MarksSheetScreen extends ConsumerStatefulWidget {
  const MarksSheetScreen({super.key});

  @override
  ConsumerState<MarksSheetScreen> createState() => _MarksSheetScreenState();
}

class _MarksSheetScreenState extends ConsumerState<MarksSheetScreen>
    with SingleTickerProviderStateMixin {
  // Cached GoogleFonts base TextStyles — avoids re-resolving font family on every build.
  // Dynamic colors are applied via .copyWith() at usage sites.
  static final _appBarTitleStyle = GoogleFonts.lexend(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static final _snackBarTextStyle = GoogleFonts.inter(
    fontWeight: FontWeight.w600,
  );

  static final _saveButtonStyle = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
  );

  static final _tabLabelStyle = GoogleFonts.lexend(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static final _tabUnselectedLabelStyle = GoogleFonts.lexend(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static final _addCourseButtonStyle = GoogleFonts.inter(
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
  );

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(marksSheetProvider.notifier).loadFromLocal(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final semCount = ref.read(marksSheetProvider).semesters.length;
    if (_tabController == null || _tabController!.length != semCount) {
      final oldIndex = _tabController?.index ?? ref.read(marksSheetProvider).selectedIndex;
      _tabController?.dispose();
      _tabController = TabController(
        length: semCount,
        vsync: this,
        initialIndex: oldIndex.clamp(0, semCount - 1),
      );
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) {
          ref.read(marksSheetProvider.notifier).selectSemester(_tabController!.index);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semCount = ref.watch(
      marksSheetProvider.select((s) => s.semesters.length),
    );
    final semesterSelectedIndex = ref.watch(
      marksSheetProvider.select((s) => s.selectedIndex),
    );
    final semesterNames = ref.watch(
      marksSheetProvider.select((s) => s.semesters.map((x) => x.name).toList()),
    );
    if (_tabController != null && _tabController!.index != semesterSelectedIndex) {
      _tabController!.animateTo(semesterSelectedIndex);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppTheme.textPrimary(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Marks Sheet',
          style: _appBarTitleStyle.copyWith(color: AppTheme.textPrimary(context)),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf_rounded,
              color: AppTheme.danger,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              final allSemesters = ref.read(marksSheetProvider).semesters;
              final s = ref.read(marksStatsProvider);
              PdfService.generateMarksSheet(
                semesters: allSemesters,
                overallCGPA: s.cgpa.toStringAsFixed(2),
              );
            },
            tooltip: 'Download PDF',
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Data Saved Locally',
                    style: _snackBarTextStyle.copyWith(color: Colors.white),
                  ),
                  backgroundColor: AppTheme.accentPrimary,
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppTheme.accentPrimary,
              size: 20,
            ),
            label: Text(
              'SAVE',
              style: _saveButtonStyle.copyWith(color: AppTheme.accentPrimary),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(
              Icons.add_to_photos_rounded,
              color: AppTheme.accentPrimary,
            ),
            onPressed: () {
              ref.read(marksSheetProvider.notifier).addSemester();
              HapticFeedback.mediumImpact();
            },
            tooltip: 'Add Semester',
          ),
          const SizedBox(width: 8),
        ],
        bottom: semCount == 0
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppTheme.accentPrimary,
                labelColor: AppTheme.accentPrimary,
                unselectedLabelColor: AppTheme.textMuted(context),
                indicatorWeight: 3,
                labelStyle: _tabLabelStyle,
                unselectedLabelStyle: _tabUnselectedLabelStyle,
                tabs: semesterNames
                    .map((name) => Tab(text: name.toUpperCase()))
                    .toList(),
              ),
      ),
      body: MeshGradientBackground(
        child: semCount == 0
            ? const Padding(
                padding: EdgeInsets.only(top: 120),
                child: EmptyState(
                  icon: Icons.school_outlined,
                  title: 'No semesters yet',
                  subtitle: 'Tap + to add your first semester',
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: List.generate(semCount, (index) {
                  return _SemesterTab(semesterIndex: index);
                }),
              ),
      ),
      floatingActionButton: semCount == 0
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                final idx = _tabController?.index ?? 0;
                ref.read(marksSheetProvider.notifier).addCourse(idx);
                HapticFeedback.lightImpact();
              },
              backgroundColor: AppTheme.accentPrimary,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'ADD COURSE',
                style: _addCourseButtonStyle.copyWith(color: Colors.white),
              ),
            ),
    );
  }
}

class _SemesterTab extends ConsumerWidget {
  // Cached GoogleFonts base TextStyles — avoids re-resolving font family on every build.
  // Dynamic colors are applied via .copyWith() at usage sites.
  static final _semesterNameStyle = GoogleFonts.lexend(
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static final _courseCountStyle = GoogleFonts.inter(
    fontSize: 12,
  );

  static final _semesterGpaStyle = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static final _overallCgpaLabelStyle = GoogleFonts.inter(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );

  static final _overallCgpaValueStyle = GoogleFonts.lexend(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  static final _dataStoreTitleStyle = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  static final _dataStoreSubtitleStyle = GoogleFonts.inter(
    fontSize: 11,
    height: 1.4,
  );

  static final _dialogTitleStyle = GoogleFonts.lexend(
    fontWeight: FontWeight.w600,
  );

  static final _dialogContentStyle = GoogleFonts.inter();

  static final _dialogCancelStyle = GoogleFonts.inter(
    fontWeight: FontWeight.w600,
  );

  static final _dialogDeleteStyle = GoogleFonts.inter(
    fontWeight: FontWeight.w700,
  );

  final int semesterIndex;

  const _SemesterTab({required this.semesterIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semesterName = ref.watch(
      marksSheetProvider.select((s) => s.semesters[semesterIndex].name),
    );
    final courseIds = ref.watch(
      marksSheetProvider.select((s) =>
          s.semesters[semesterIndex].courses.map((c) => c.id).toList()),
    );
    final totalSemesters = ref.watch(
      marksSheetProvider.select((s) => s.semesters.length),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double semesterGpa = 0;
    double overallCgpa = 0;
    final semState = ref.read(marksSheetProvider);
    if (semesterIndex < semState.semesters.length) {
      double credits = 0;
      double points = 0;
      for (final course in semState.semesters[semesterIndex].courses) {
        final p = GpaService.getPoints(course.grade);
        points += p * course.creditHours;
        credits += course.creditHours;
      }
      semesterGpa = credits > 0 ? points / credits : 0.0;
    }
    {
      double totalCredits = 0;
      double totalPoints = 0;
      for (final sem in semState.semesters) {
        for (final course in sem.courses) {
          final p = GpaService.getPoints(course.grade);
          totalPoints += p * course.creditHours;
          totalCredits += course.creditHours;
        }
      }
      overallCgpa = totalCredits > 0 ? totalPoints / totalCredits : 0.0;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: 100,
        left: 16,
        right: 16,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              semesterName,
                              style: _semesterNameStyle.copyWith(color: AppTheme.textPrimary(context)),
                            ),
                          ),
                          if (totalSemesters > 1)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppTheme.danger,
                                size: 20,
                              ),
                              onPressed: () =>
                                  _showDeleteSemesterDialog(
                                context,
                                ref,
                                semesterName,
                              ),
                              tooltip: 'Delete Semester',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: AppTheme.textMuted(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${courseIds.length} Courses  •  ',
                            style: _courseCountStyle.copyWith(color: AppTheme.textSecondary(context)),
                          ),
                          Text(
                            'GPA: ${semesterGpa.toStringAsFixed(2)}',
                            style: _semesterGpaStyle.copyWith(color: AppTheme.accentPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'OVERALL CGPA',
                      style: _overallCgpaLabelStyle.copyWith(color: AppTheme.textMuted(context)),
                    ),
                    Text(
                      overallCgpa.toStringAsFixed(2),
                      style: _overallCgpaValueStyle.copyWith(color: AppTheme.getGpaColor(overallCgpa)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0x146366F1)
                  : const Color(0x0D6366F1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0x266366F1)
                    : const Color(0x1A6366F1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.storage_rounded,
                  color: AppTheme.accentPrimary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Marks Sheet — Data Store',
                        style: _dataStoreTitleStyle.copyWith(color: AppTheme.textPrimary(context)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Store your course marks here. This data will be used to calculate GPA.',
                        style: _dataStoreSubtitleStyle.copyWith(color: AppTheme.textSecondary(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (courseIds.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: EmptyState(
                icon: Icons.book_outlined,
                title: 'No courses yet',
                subtitle: 'Tap + to add your first course',
              ),
            )
          else
            ...() {
              final courseMap = {
                for (var s in ref.read(marksSheetProvider).semesters)
                  for (var c in s.courses) c.id: c
              };
              return courseIds.map((courseId) {
                final course = courseMap[courseId]!;
                return CourseInputCard(
                  key: ValueKey(courseId),
                  course: course,
                  notifierOverride:
                      ref.read(marksSheetProvider.notifier),
                );
              });
            }(),
        ],
      ),
    );
  }

  void _showDeleteSemesterDialog(BuildContext context, WidgetRef ref, String semesterName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkBgGradientStart : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? AppTheme.darkBorderGlass : const Color(0x14000000),
          ),
        ),
        title: Text(
          'Delete $semesterName?',
          style: _dialogTitleStyle.copyWith(color: AppTheme.textPrimary(context)),
        ),
        content: Text(
          'This will permanently remove all courses and marks for this semester.',
          style: _dialogContentStyle.copyWith(color: AppTheme.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: _dialogCancelStyle.copyWith(color: AppTheme.textMuted(context)),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(marksSheetProvider.notifier).removeSemester(semesterIndex);
              Navigator.pop(context);
              HapticFeedback.heavyImpact();
            },
            child: Text(
              'DELETE',
              style: _dialogDeleteStyle.copyWith(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
  }
}
