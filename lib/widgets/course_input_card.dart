import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/course.dart';
import '../providers/semester_provider.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';
import 'grade_badge.dart';

class CourseInputCard extends ConsumerStatefulWidget {
  final Course course;
  final SemesterNotifier? notifierOverride;

  const CourseInputCard({super.key, required this.course, this.notifierOverride});

  @override
  ConsumerState<CourseInputCard> createState() => _CourseInputCardState();
}

class _CourseInputCardState extends ConsumerState<CourseInputCard> {
  late TextEditingController _nameController;
  late TextEditingController _midController;
  late TextEditingController _finalController;
  late TextEditingController _sessionalController;
  late TextEditingController _totalController;
  late FocusNode _nameFocus;
  late FocusNode _midFocus;
  late FocusNode _finalFocus;
  late FocusNode _sessionalFocus;
  late FocusNode _totalFocus;

  SemesterNotifier get _notifier =>
      widget.notifierOverride ?? ref.read(semesterProvider.notifier);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.course.name);
    _midController = TextEditingController(
      text: widget.course.midMarks == 0 ? '' : widget.course.midMarks.toStringAsFixed(0),
    );
    _finalController = TextEditingController(
      text: widget.course.finalMarks == 0 ? '' : widget.course.finalMarks.toStringAsFixed(0),
    );
    _sessionalController = TextEditingController(
      text: widget.course.sessionalMarks == 0 ? '' : widget.course.sessionalMarks.toStringAsFixed(0),
    );
    _totalController = TextEditingController(
      text: widget.course.totalMarks == 0 ? '' : widget.course.totalMarks.toStringAsFixed(0),
    );

    _nameFocus = FocusNode();
    _midFocus = FocusNode();
    _finalFocus = FocusNode();
    _sessionalFocus = FocusNode();
    _totalFocus = FocusNode();

    _setupFocusListeners();
  }

  void _setupFocusListeners() {
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus && _nameController.text != widget.course.name) {
        _notifier.updateCourse(
              widget.course.id,
              name: _nameController.text,
            );
      }
    });

    _midFocus.addListener(() => _onMarksFocusLost('mid'));
    _finalFocus.addListener(() => _onMarksFocusLost('final'));
    _sessionalFocus.addListener(() => _onMarksFocusLost('sessional'));
    _totalFocus.addListener(() {
      if (!_totalFocus.hasFocus) {
        double val = double.tryParse(_totalController.text) ?? 0;
        if (val > 100) val = 100;
        if (val != widget.course.totalMarks) {
          _notifier.updateCourse(
            widget.course.id,
            totalMarks: val,
          );
        }
      }
    });
  }

  void _onMarksFocusLost(String type) {
    double val = 0;
    switch (type) {
      case 'mid':
        if (!_midFocus.hasFocus) val = double.tryParse(_midController.text) ?? 0;
        break;
      case 'final':
        if (!_finalFocus.hasFocus) val = double.tryParse(_finalController.text) ?? 0;
        break;
      case 'sessional':
        if (!_sessionalFocus.hasFocus) val = double.tryParse(_sessionalController.text) ?? 0;
        break;
    }
    if (val > 100) val = 100;

    switch (type) {
      case 'mid':
        _notifier.updateCourse(
              widget.course.id,
              midMarks: val,
              totalMarks: val + widget.course.finalMarks + widget.course.sessionalMarks,
            );
        break;
      case 'final':
        _notifier.updateCourse(
              widget.course.id,
              finalMarks: val,
              totalMarks: widget.course.midMarks + val + widget.course.sessionalMarks,
            );
        break;
      case 'sessional':
        _notifier.updateCourse(
              widget.course.id,
              sessionalMarks: val,
              totalMarks: widget.course.midMarks + widget.course.finalMarks + val,
            );
        break;
    }
  }

  @override
  void didUpdateWidget(CourseInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.course.name != widget.course.name && !_nameFocus.hasFocus) {
      _nameController.text = widget.course.name;
    }
    if (oldWidget.course.midMarks != widget.course.midMarks && !_midFocus.hasFocus) {
      _midController.text = widget.course.midMarks == 0 ? '' : widget.course.midMarks.toStringAsFixed(0);
    }
    if (oldWidget.course.finalMarks != widget.course.finalMarks && !_finalFocus.hasFocus) {
      _finalController.text = widget.course.finalMarks == 0 ? '' : widget.course.finalMarks.toStringAsFixed(0);
    }
    if (oldWidget.course.sessionalMarks != widget.course.sessionalMarks && !_sessionalFocus.hasFocus) {
      _sessionalController.text = widget.course.sessionalMarks == 0 ? '' : widget.course.sessionalMarks.toStringAsFixed(0);
    }
    if (oldWidget.course.totalMarks != widget.course.totalMarks && !_totalFocus.hasFocus) {
      _totalController.text = widget.course.totalMarks == 0 ? '' : widget.course.totalMarks.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _midFocus.dispose();
    _finalFocus.dispose();
    _sessionalFocus.dispose();
    _totalFocus.dispose();
    _nameController.dispose();
    _midController.dispose();
    _finalController.dispose();
    _sessionalController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  Widget _buildMarkField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: '0',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: TextStyle(color: AppTheme.textMuted),
              ),
              onChanged: (val) {
                double d = double.tryParse(val) ?? 0;
                if (d > 100) {
                  d = 100;
                  controller.text = '100';
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLab = widget.course.isPractical;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          borderColor: isLab
              ? AppTheme.accentPrimary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          child: Column(
            children: [
              // Top Row: Lab toggle + Course Name
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _notifier.updateCourse(
                            widget.course.id,
                            isPractical: !isLab,
                            creditHours: !isLab ? 1.0 : widget.course.creditHours,
                          );
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isLab
                            ? AppTheme.accentPrimary.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLab
                              ? AppTheme.accentPrimary.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Icon(
                        isLab ? Icons.science : Icons.science_outlined,
                        size: 20,
                        color: isLab ? AppTheme.accentPrimary : AppTheme.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      decoration: InputDecoration(
                        hintText: 'Course Name',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintStyle: TextStyle(
                          color: AppTheme.textMuted.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Middle Row: Marks fields
              Row(
                children: [
                  _buildMarkField(
                    label: 'MID',
                    controller: _midController,
                    focusNode: _midFocus,
                  ),
                  const SizedBox(width: 10),
                  _buildMarkField(
                    label: 'FINAL',
                    controller: _finalController,
                    focusNode: _finalFocus,
                  ),
                  const SizedBox(width: 10),
                  _buildMarkField(
                    label: 'SESSIONAL',
                    controller: _sessionalController,
                    focusNode: _sessionalFocus,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Bottom Row: Credits + Total + Grade + Delete
              Row(
                children: [
                  // Credits Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CREDITS',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: isLab
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  '1',
                                  style: TextStyle(
                                    color: AppTheme.accentPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : DropdownButton<double>(
                                value: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
                                        .contains(widget.course.creditHours)
                                    ? widget.course.creditHours
                                    : 3.0,
                                dropdownColor: AppTheme.bgGradientStart,
                                underline: const SizedBox(),
                                isDense: true,
                                icon: const Icon(
                                  Icons.expand_more,
                                  size: 16,
                                  color: AppTheme.textMuted,
                                ),
                                items: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0].map((e) {
                                  return DropdownMenuItem(
                                    value: e,
                                    child: Text(
                                      '${e.toInt()}',
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    _notifier.updateCourse(
                                          widget.course.id,
                                          creditHours: val,
                                        );
                                    HapticFeedback.selectionClick();
                                  }
                                },
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Total (editable)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.accentPrimary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: SizedBox(
                          width: 42,
                          child: TextField(
                            controller: _totalController,
                            focusNode: _totalFocus,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.accentPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 6),
                              hintStyle: TextStyle(color: AppTheme.textMuted),
                            ),
                            onChanged: (val) {
                              double d = double.tryParse(val) ?? 0;
                              if (d > 100) {
                                d = 100;
                                _totalController.text = '100';
                                _totalController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: _totalController.text.length),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Grade Badge
                  GradeBadge(grade: widget.course.grade),
                  const SizedBox(width: 12),
                  // Delete
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: AppTheme.textMuted,
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _notifier.removeCourse(
                            widget.course.id,
                          );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
