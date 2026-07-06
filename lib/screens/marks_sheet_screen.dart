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
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(marksSheetProvider.notifier).loadFromLocal(),
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semesterState = ref.watch(marksSheetProvider);
    final stats = ref.watch(marksStatsProvider);

    if (_tabController == null ||
        _tabController!.length != semesterState.semesters.length) {
      final oldIndex = _tabController?.index ?? semesterState.selectedIndex;
      _tabController?.dispose();
      _tabController = TabController(
        length: semesterState.semesters.length,
        vsync: this,
        initialIndex: oldIndex.clamp(0, semesterState.semesters.length - 1),
      );
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) {
          ref
              .read(marksSheetProvider.notifier)
              .selectSemester(_tabController!.index);
        }
      });
    } else if (_tabController!.index != semesterState.selectedIndex) {
      _tabController!.animateTo(semesterState.selectedIndex);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Marks Sheet',
          style: GoogleFonts.lexend(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf_rounded,
              color: AppTheme.danger,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              final stats = ref.read(marksStatsProvider);
              PdfService.generateMarksSheet(
                semesters: semesterState.semesters,
                overallCGPA: stats.cgpa.toStringAsFixed(2),
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
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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
              style: GoogleFonts.inter(
                color: AppTheme.accentPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
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
        bottom: semesterState.semesters.isEmpty
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppTheme.accentPrimary,
                labelColor: AppTheme.accentPrimary,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.lexend(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: GoogleFonts.lexend(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: semesterState.semesters
                    .map((s) => Tab(text: s.name.toUpperCase()))
                    .toList(),
              ),
      ),
      body: MeshGradientBackground(
        child: semesterState.semesters.isEmpty
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
                children: semesterState.semesters.map((semester) {
                  final semesterGpa = _calculateSemesterGpa(semester);
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
                                            semester.name,
                                            style: GoogleFonts.lexend(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (semesterState.semesters.length > 1)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: AppTheme.danger,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _showDeleteSemesterDialog(
                                              context,
                                              semester.name,
                                            ),
                                            tooltip: 'Delete Semester',
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints(),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          size: 14,
                                          color: AppTheme.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${semester.courses.length} Courses  •  ',
                                          style: GoogleFonts.inter(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          'GPA: ${semesterGpa.toStringAsFixed(2)}',
                                          style: GoogleFonts.inter(
                                            color: AppTheme.accentPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
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
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textMuted,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Text(
                                    stats.cgpa.toStringAsFixed(2),
                                    style: GoogleFonts.lexend(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          AppTheme.getGpaColor(stats.cgpa),
                                    ),
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
                            color: const Color(0x146366F1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0x266366F1),
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Marks Sheet — Data Store',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Store your course marks here. This data will be used to calculate GPA.',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (semester.courses.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: EmptyState(
                              icon: Icons.book_outlined,
                              title: 'No courses yet',
                              subtitle:
                                  'Tap + to add your first course',
                            ),
                          )
                        else
                          ...semester.courses
                              .asMap()
                              .entries
                              .map((entry) {
                            return CourseInputCard(
                              key: ValueKey(entry.value.id),
                              course: entry.value,
                              notifierOverride:
                                  ref.read(marksSheetProvider.notifier),
                            );
                          }),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
      floatingActionButton: semesterState.semesters.isEmpty
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
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
    );
  }

  double _calculateSemesterGpa(dynamic semester) {
    double credits = 0;
    double points = 0;
    for (final course in semester.courses) {
      final p = GpaService.getPoints(course.grade);
      points += p * course.creditHours;
      credits += course.creditHours;
    }
    return credits > 0 ? points / credits : 0.0;
  }

  void _showDeleteSemesterDialog(BuildContext context, String semesterName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgGradientStart,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderGlass),
        ),
        title: Text(
          'Delete $semesterName?',
          style: GoogleFonts.lexend(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will permanently remove all courses and marks for this semester.',
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.inter(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final index = _tabController?.index ?? 0;
              ref.read(marksSheetProvider.notifier).removeSemester(index);
              Navigator.pop(context);
              HapticFeedback.heavyImpact();
            },
            child: Text(
              'DELETE',
              style: GoogleFonts.inter(
                color: AppTheme.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
