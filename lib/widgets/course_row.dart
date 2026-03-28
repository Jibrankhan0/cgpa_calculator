import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course.dart';
import '../providers/semester_provider.dart';
import '../services/gpa_service.dart';
import 'glass_card.dart';

class CourseRow extends ConsumerStatefulWidget {
  final Course course;

  const CourseRow({super.key, required this.course});

  @override
  ConsumerState<CourseRow> createState() => _CourseRowState();
}

class _CourseRowState extends ConsumerState<CourseRow> {
  late TextEditingController _nameController;
  late TextEditingController _marksController;
  late FocusNode _nameFocus;
  late FocusNode _marksFocus;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.course.name);
    _marksController = TextEditingController(
      text: widget.course.totalMarks == 0
          ? ''
          : widget.course.totalMarks.toString().replaceAll('.0', ''),
    );

    _nameFocus = FocusNode();
    _marksFocus = FocusNode();

    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus && _nameController.text != widget.course.name) {
        ref
            .read(semesterProvider.notifier)
            .updateCourse(widget.course.id, name: _nameController.text);
      }
    });

    _marksFocus.addListener(() {
      if (!_marksFocus.hasFocus) {
        final marks = double.tryParse(_marksController.text) ?? 0;
        if (marks != widget.course.totalMarks) {
          ref
              .read(semesterProvider.notifier)
              .updateCourse(widget.course.id, totalMarks: marks);
        }
      }
    });
  }

  @override
  void didUpdateWidget(CourseRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.course.name != widget.course.name &&
        _nameController.text != widget.course.name &&
        !_nameFocus.hasFocus) {
      _nameController.text = widget.course.name;
    }
    final formattedMarks = widget.course.totalMarks == 0
        ? ''
        : widget.course.totalMarks.toString().replaceAll('.0', '');
    if (oldWidget.course.totalMarks != widget.course.totalMarks &&
        _marksController.text != formattedMarks &&
        !_marksFocus.hasFocus) {
      _marksController.text = formattedMarks;
    }
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _marksFocus.dispose();
    _nameController.dispose();
    _marksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        useBlur: false, // Efficiency: many rows don't need blur
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        borderColor: _isDeleting ? Colors.redAccent : null,
        opacity: _isDeleting ? 0.3 : 0.1,
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                ref
                    .read(semesterProvider.notifier)
                    .updateCourse(
                      widget.course.id,
                      isPractical: !widget.course.isPractical,
                      creditHours: !widget.course.isPractical
                          ? 1.0
                          : widget.course.creditHours,
                    );
                HapticFeedback.lightImpact();
              },
              icon: Icon(
                widget.course.isPractical
                    ? Icons.science
                    : Icons.science_outlined,
                size: 18,
                color: widget.course.isPractical
                    ? Colors.cyanAccent
                    : Colors.white24,
              ),
              tooltip: 'Practical Mode',
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    decoration: InputDecoration(
                      hintText: 'Course Name',
                      border: InputBorder.none,
                      hintStyle: const TextStyle(color: Colors.white38),
                      suffix: widget.course.isPractical
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.cyanAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.cyanAccent.withOpacity(0.3),
                                ),
                              ),
                              child: const Text(
                                'LAB',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    onSubmitted: (val) {
                      ref
                          .read(semesterProvider.notifier)
                          .updateCourse(widget.course.id, name: val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Credits
            Expanded(
              flex: 1,
              child: widget.course.isPractical
                  ? const Center(
                      child: Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : DropdownButton<double>(
                      value:
                          [
                            1.0,
                            2.0,
                            3.0,
                            4.0,
                            5.0,
                            6.0,
                          ].contains(widget.course.creditHours)
                          ? widget.course.creditHours
                          : 3.0,
                      dropdownColor: const Color(0xFF1A1F3D),
                      underline: const SizedBox(),
                      isExpanded: true,
                      isDense: true,
                      icon: const Icon(Icons.arrow_drop_down, size: 16),
                      alignment: Alignment.center,
                      items: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0].map((e) {
                        return DropdownMenuItem(
                          value: e,
                          child: Center(
                            child: Text(
                              '${e.toInt()}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(semesterProvider.notifier)
                              .updateCourse(widget.course.id, creditHours: val);
                          HapticFeedback.selectionClick();
                        }
                      },
                    ),
            ),
            const SizedBox(width: 8),
            // Marks
            Expanded(
              flex: 1,
              child: TextField(
                controller: _marksController,
                focusNode: _marksFocus,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '0',
                  border: InputBorder.none,
                  isDense: true,
                  hintStyle: TextStyle(color: Colors.white12, fontSize: 12),
                ),
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                onSubmitted: (val) {
                  final marks = double.tryParse(val) ?? 0;
                  ref
                      .read(semesterProvider.notifier)
                      .updateCourse(widget.course.id, totalMarks: marks);
                },
              ),
            ),
            const SizedBox(width: 8),
            // Grade
            Expanded(
              flex: 1,
              child: DropdownButton<String>(
                value: widget.course.grade,
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
                        ),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(semesterProvider.notifier)
                        .updateCourse(widget.course.id, grade: val);
                    HapticFeedback.selectionClick();
                  }
                },
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: _isDeleting ? Colors.redAccent : Colors.white24,
              ),
              onPressed: () async {
                setState(() => _isDeleting = true);
                HapticFeedback.mediumImpact();
                await Future.delayed(const Duration(milliseconds: 300));
                if (mounted) {
                  ref
                      .read(semesterProvider.notifier)
                      .removeCourse(widget.course.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
