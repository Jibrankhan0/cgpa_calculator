import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/semester_provider.dart';
import '../services/gpa_service.dart';
import '../widgets/mesh_gradient_background.dart';
import '../widgets/glass_card.dart';

class MarksSheetScreen extends ConsumerStatefulWidget {
  const MarksSheetScreen({super.key});

  @override
  ConsumerState<MarksSheetScreen> createState() => _MarksSheetScreenState();
}

class _MarksSheetScreenState extends ConsumerState<MarksSheetScreen>
    with TickerProviderStateMixin {
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

    // Efficiently update/recreate TabController when semesters count changes or on first build
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
      // Sync controller if provider state changed externally
      _tabController!.animateTo(semesterState.selectedIndex);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Marks Sheet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Data Saved Locally',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.cyanAccent,
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.cyanAccent,
              size: 20,
            ),
            label: const Text(
              'SAVE',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.add_to_photos_rounded,
              color: Colors.cyanAccent,
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
                indicatorColor: Colors.cyanAccent,
                labelColor: Colors.cyanAccent,
                unselectedLabelColor: Colors.white38,
                tabs: semesterState.semesters
                    .map((s) => Tab(text: s.name))
                    .toList(),
              ),
      ),
      body: MeshGradientBackground(
        child: semesterState.semesters.isEmpty
            ? const Center(
                child: Text(
                  'No semesters added',
                  style: TextStyle(color: Colors.white38),
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: semesterState.semesters.map((semester) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      top: 100,
                      left: 16,
                      right: 16,
                      bottom: 100,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      semester.name,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.cyanAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (semesterState.semesters.length > 1)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_forever_rounded,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          _showDeleteSemesterDialog(
                                            context,
                                            semester.name,
                                          );
                                        },
                                        tooltip: 'Delete Semester',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 14,
                                      color: Colors.white38,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${semester.courses.length} Courses  •  ',
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'GPA: ${_calculateSemesterGpa(semester).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.cyanAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Overall CGPA Indicator
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'OVERALL CGPA',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  ref
                                      .watch(marksStatsProvider)
                                      .cgpa
                                      .toStringAsFixed(2),
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        GlassCard(
                          padding: EdgeInsets.zero,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 20, // Reduced for extra column
                              headingTextStyle: const TextStyle(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              dataTextStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              columns: const [
                                DataColumn(label: Text('COURSE')),
                                DataColumn(label: Text('CR')),
                                DataColumn(label: Text('MID')),
                                DataColumn(label: Text('FIN.')),
                                DataColumn(label: Text('SES.')),
                                DataColumn(label: Text('TOT.')),
                                DataColumn(label: Text('G')),
                                DataColumn(label: Text('')),
                              ],
                              rows: semester.courses.map((course) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      _CourseNameCell(
                                        name: course.name,
                                        onChanged: (val) => ref
                                            .read(marksSheetProvider.notifier)
                                            .updateCourse(course.id, name: val),
                                      ),
                                    ),
                                    DataCell(
                                      _CreditCell(
                                        credits: course.creditHours,
                                        onChanged: (val) => ref
                                            .read(marksSheetProvider.notifier)
                                            .updateCourse(
                                              course.id,
                                              creditHours: val,
                                            ),
                                      ),
                                    ),
                                    DataCell(
                                      _EditableCell(
                                        value: course.midMarks,
                                        onChanged: (val) {
                                          final newTotal =
                                              val +
                                              course.finalMarks +
                                              course.sessionalMarks;
                                          ref
                                              .read(marksSheetProvider.notifier)
                                              .updateCourse(
                                                course.id,
                                                midMarks: val,
                                                totalMarks: newTotal,
                                              );
                                        },
                                      ),
                                    ),
                                    DataCell(
                                      _EditableCell(
                                        value: course.finalMarks,
                                        onChanged: (val) {
                                          final newTotal =
                                              course.midMarks +
                                              val +
                                              course.sessionalMarks;
                                          ref
                                              .read(marksSheetProvider.notifier)
                                              .updateCourse(
                                                course.id,
                                                finalMarks: val,
                                                totalMarks: newTotal,
                                              );
                                        },
                                      ),
                                    ),
                                    DataCell(
                                      _EditableCell(
                                        value: course.sessionalMarks,
                                        onChanged: (val) {
                                          final newTotal =
                                              course.midMarks +
                                              course.finalMarks +
                                              val;
                                          ref
                                              .read(marksSheetProvider.notifier)
                                              .updateCourse(
                                                course.id,
                                                sessionalMarks: val,
                                                totalMarks: newTotal,
                                              );
                                        },
                                      ),
                                    ),
                                    DataCell(
                                      _EditableCell(
                                        value: course.totalMarks,
                                        isTotal: true,
                                        onChanged: (val) => ref
                                            .read(marksSheetProvider.notifier)
                                            .updateCourse(
                                              course.id,
                                              totalMarks: val,
                                            ),
                                      ),
                                    ),
                                    DataCell(
                                      _GradeCell(
                                        grade: course.grade,
                                        onChanged: (val) => ref
                                            .read(marksSheetProvider.notifier)
                                            .updateCourse(
                                              course.id,
                                              grade: val,
                                            ),
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          ref
                                              .read(marksSheetProvider.notifier)
                                              .removeCourse(course.id);
                                          HapticFeedback.mediumImpact();
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final idx = _tabController?.index ?? 0;
          ref.read(marksSheetProvider.notifier).addCourse(idx);
          HapticFeedback.lightImpact();
        },
        backgroundColor: Colors.cyanAccent.withOpacity(0.2),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.cyanAccent.withOpacity(0.5)),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.cyanAccent),
        label: const Text(
          'ADD COURSE',
          style: TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
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
        backgroundColor: const Color(0xFF1A1F3D),
        title: Text(
          'Delete $semesterName?',
          style: const TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will permanently remove all courses and marks for this semester.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () {
              final index = _tabController?.index ?? 0;
              ref.read(marksSheetProvider.notifier).removeSemester(index);
              Navigator.pop(context);
              HapticFeedback.heavyImpact();
            },
            child: const Text(
              'DELETE',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableCell extends StatefulWidget {
  final double value;
  final bool isTotal;
  final Function(double) onChanged;

  const _EditableCell({
    required this.value,
    this.isTotal = false,
    required this.onChanged,
  });

  @override
  State<_EditableCell> createState() => _EditableCellState();
}

class _EditableCellState extends State<_EditableCell> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value == 0
          ? ''
          : widget.value.toString().replaceAll('.0', ''),
    );
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        final d = double.tryParse(_controller.text) ?? 0;
        if (d != widget.value) {
          widget.onChanged(d);
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant _EditableCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      final text = widget.value == 0
          ? ''
          : widget.value.toString().replaceAll('.0', '');
      if (text != _controller.text) {
        _controller.text = text;
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        style: TextStyle(
          fontSize: 13,
          color: widget.isTotal ? Colors.cyanAccent : Colors.white,
          fontWeight: widget.isTotal ? FontWeight.bold : FontWeight.normal,
        ),
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: const TextStyle(color: Colors.white24),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onSubmitted: (val) {
          final d = double.tryParse(val) ?? 0;
          widget.onChanged(d);
        },
      ),
    );
  }
}

class _CourseNameCell extends StatefulWidget {
  final String name;
  final Function(String) onChanged;

  const _CourseNameCell({required this.name, required this.onChanged});

  @override
  State<_CourseNameCell> createState() => _CourseNameCellState();
}

class _CourseNameCellState extends State<_CourseNameCell> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.name);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _controller.text != widget.name) {
        widget.onChanged(_controller.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _CourseNameCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name && !_focusNode.hasFocus) {
      if (widget.name != _controller.text) {
        _controller.text = widget.name;
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: TextStyle(
          fontSize: 13,
          color: widget.name.isEmpty ? Colors.white38 : Colors.white,
          fontStyle: widget.name.isEmpty ? FontStyle.italic : FontStyle.normal,
        ),
        decoration: const InputDecoration(
          hintText: 'Course Name',
          hintStyle: TextStyle(
            color: Colors.white24,
            fontStyle: FontStyle.italic,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
        onSubmitted: (val) {
          widget.onChanged(val);
        },
      ),
    );
  }
}

class _GradeCell extends StatelessWidget {
  final String grade;
  final Function(String) onChanged;

  const _GradeCell({required this.grade, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      child: DropdownButton<String>(
        value: grade,
        dropdownColor: const Color(0xFF1A1F3D),
        underline: const SizedBox(),
        isExpanded: true,
        isDense: true,
        icon: const Icon(Icons.arrow_drop_down, size: 16),
        alignment: Alignment.center,
        items: GpaService.grades.map((e) {
          return DropdownMenuItem(
            value: e,
            child: Center(
              child: Text(
                e,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
              ),
            ),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            onChanged(val);
            HapticFeedback.selectionClick();
          }
        },
      ),
    );
  }
}

class _CreditCell extends StatelessWidget {
  final double credits;
  final ValueChanged<double> onChanged;

  const _CreditCell({required this.credits, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<double>(
      value: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0].contains(credits) ? credits : 3.0,
      dropdownColor: const Color(0xFF1A1F3D),
      underline: const SizedBox(),
      isDense: true,
      icon: const Icon(
        Icons.arrow_drop_down,
        size: 14,
        color: Colors.cyanAccent,
      ),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      items: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0].map((e) {
        return DropdownMenuItem(value: e, child: Text('${e.toInt()}'));
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          onChanged(val);
          HapticFeedback.selectionClick();
        }
      },
    );
  }
}
