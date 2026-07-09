import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/course.dart';
import '../providers/semester_provider.dart';
import '../services/gpa_service.dart';
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
  // Cached GoogleFonts base TextStyles — avoids re-resolving font family on every build.
  // Dynamic colors are applied via .copyWith() at usage sites.
  static final _labelBase = GoogleFonts.inter(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static final _markLabelBase = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static final _inputBase = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static final _totalStyle = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: AppTheme.accentPrimary,
  );

  static final _hintBase = GoogleFonts.inter(
    fontSize: 14,
  );

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

  final ValueNotifier<bool> _isMidFocused = ValueNotifier(false);
  final ValueNotifier<bool> _isFinalFocused = ValueNotifier(false);
  final ValueNotifier<bool> _isSessionalFocused = ValueNotifier(false);
  final ValueNotifier<bool> _isTotalFocused = ValueNotifier(false);

  double _localMid = 0;
  double _localFinal = 0;
  double _localSessional = 0;
  double _localTotal = 0;
  bool _isPractical = false;

  SemesterNotifier get _notifier =>
      widget.notifierOverride ?? ref.read(semesterProvider.notifier);

  String _localGrade() {
    if (_localTotal <= 0) return 'F';
    return GpaService.getGradeFromMarks(_localTotal, isPractical: _isPractical);
  }

  @override
  void initState() {
    super.initState();
    _initControllers(widget.course);
    _nameFocus = FocusNode();
    _midFocus = FocusNode();
    _finalFocus = FocusNode();
    _sessionalFocus = FocusNode();
    _totalFocus = FocusNode();
    _setupFocusListeners();
  }

  void _initControllers(Course course) {
    _nameController = TextEditingController(text: course.name);
    _midController = TextEditingController(
      text: course.midMarks == 0 ? '' : course.midMarks.toStringAsFixed(0),
    );
    _finalController = TextEditingController(
      text: course.finalMarks == 0 ? '' : course.finalMarks.toStringAsFixed(0),
    );
    _sessionalController = TextEditingController(
      text: course.sessionalMarks == 0 ? '' : course.sessionalMarks.toStringAsFixed(0),
    );
    _totalController = TextEditingController(
      text: course.totalMarks == 0 ? '' : course.totalMarks.toStringAsFixed(0),
    );
    _localMid = course.midMarks;
    _localFinal = course.finalMarks;
    _localSessional = course.sessionalMarks;
    _localTotal = course.totalMarks;
    _isPractical = course.isPractical;
  }

  @override
  void didUpdateWidget(CourseInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.course.id != widget.course.id) {
      _disposeControllers();
      _initControllers(widget.course);
    } else if (!_midFocus.hasFocus && _localMid != widget.course.midMarks) {
      _localMid = widget.course.midMarks;
      _midController.text = widget.course.midMarks == 0 ? '' : widget.course.midMarks.toStringAsFixed(0);
    } else if (!_finalFocus.hasFocus && _localFinal != widget.course.finalMarks) {
      _localFinal = widget.course.finalMarks;
      _finalController.text = widget.course.finalMarks == 0 ? '' : widget.course.finalMarks.toStringAsFixed(0);
    } else if (!_sessionalFocus.hasFocus && _localSessional != widget.course.sessionalMarks) {
      _localSessional = widget.course.sessionalMarks;
      _sessionalController.text = widget.course.sessionalMarks == 0 ? '' : widget.course.sessionalMarks.toStringAsFixed(0);
    } else if (!_totalFocus.hasFocus && _localTotal != widget.course.totalMarks) {
      _localTotal = widget.course.totalMarks;
      _totalController.text = widget.course.totalMarks == 0 ? '' : widget.course.totalMarks.toStringAsFixed(0);
    }
    if (oldWidget.course.isPractical != widget.course.isPractical) {
      _isPractical = widget.course.isPractical;
    }
  }

  void _disposeControllers() {
    _nameController.dispose();
    _midController.dispose();
    _finalController.dispose();
    _sessionalController.dispose();
    _totalController.dispose();
  }

  void _setupFocusListeners() {
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus && _nameController.text != widget.course.name) {
        _notifier.updateCourse(widget.course.id, name: _nameController.text);
      }
    });
    _midFocus.addListener(() {
      _isMidFocused.value = _midFocus.hasFocus;
      if (!_midFocus.hasFocus) {
        _notifier.updateCourse(widget.course.id, midMarks: _localMid,
            totalMarks: _localMid + _localFinal + _localSessional);
      }
    });
    _finalFocus.addListener(() {
      _isFinalFocused.value = _finalFocus.hasFocus;
      if (!_finalFocus.hasFocus) {
        _notifier.updateCourse(widget.course.id, finalMarks: _localFinal,
            totalMarks: _localMid + _localFinal + _localSessional);
      }
    });
    _sessionalFocus.addListener(() {
      _isSessionalFocused.value = _sessionalFocus.hasFocus;
      if (!_sessionalFocus.hasFocus) {
        _notifier.updateCourse(widget.course.id, sessionalMarks: _localSessional,
            totalMarks: _localMid + _localFinal + _localSessional);
      }
    });
    _totalFocus.addListener(() {
      _isTotalFocused.value = _totalFocus.hasFocus;
      if (!_totalFocus.hasFocus) {
        _notifier.updateCourse(widget.course.id, totalMarks: _localTotal);
      }
    });
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _midFocus.dispose();
    _finalFocus.dispose();
    _sessionalFocus.dispose();
    _totalFocus.dispose();
    _disposeControllers();
    _isMidFocused.dispose();
    _isFinalFocused.dispose();
    _isSessionalFocused.dispose();
    _isTotalFocused.dispose();
    super.dispose();
  }

  Color _fieldBg(bool isDark, bool focused) {
    if (isDark) {
      return focused ? const Color(0x1A6366F1) : const Color(0x0DFFFFFF);
    }
    return focused ? const Color(0x0D6366F1) : const Color(0x08000000);
  }

  Color _fieldBorder(bool isDark, bool focused) {
    if (isDark) {
      return focused ? const Color(0x4D6366F1) : const Color(0x14FFFFFF);
    }
    return focused ? const Color(0x4D6366F1) : const Color(0x14000000);
  }

  void _onMarksChanged(String type, double val) {
    switch (type) {
      case 'mid':
        _localMid = val;
        _localTotal = val + _localFinal + _localSessional;
        break;
      case 'final':
        _localFinal = val;
        _localTotal = _localMid + val + _localSessional;
        break;
      case 'sessional':
        _localSessional = val;
        _localTotal = _localMid + _localFinal + val;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          borderColor: _isPractical
              ? const Color(0x336366F1)
              : (isDark ? const Color(0x1AFFFFFF) : const Color(0x1A000000)),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _isPractical = !_isPractical;
                      _notifier.updateCourse(widget.course.id,
                          isPractical: _isPractical,
                          creditHours: _isPractical ? 1.0 : widget.course.creditHours);
                      setState(() {});
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isPractical ? const Color(0x266366F1) : _fieldBg(isDark, false),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isPractical ? const Color(0x4D6366F1) : _fieldBorder(isDark, false),
                        ),
                      ),
                      child: Icon(
                        _isPractical ? Icons.science : Icons.science_outlined,
                        size: 20,
                        color: _isPractical ? AppTheme.accentPrimary : AppTheme.textMuted(context),
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
                        hintStyle: _hintBase.copyWith(
                          color: AppTheme.textMuted(context).withValues(alpha: 0.6),
                        ),
                      ),
                      style: _inputBase.copyWith(
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildMarkField(
                    label: 'MID',
                    controller: _midController,
                    focusNode: _midFocus,
                    focusNotifier: _isMidFocused,
                    isDark: isDark,
                    type: 'mid',
                  ),
                  const SizedBox(width: 10),
                  _buildMarkField(
                    label: 'FINAL',
                    controller: _finalController,
                    focusNode: _finalFocus,
                    focusNotifier: _isFinalFocused,
                    isDark: isDark,
                    type: 'final',
                  ),
                  const SizedBox(width: 10),
                  _buildMarkField(
                    label: 'SES.',
                    controller: _sessionalController,
                    focusNode: _sessionalFocus,
                    focusNotifier: _isSessionalFocused,
                    isDark: isDark,
                    type: 'sessional',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CREDITS', style: _labelBase.copyWith(
                        color: AppTheme.textMuted(context),
                      )),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: _fieldBg(isDark, false),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _fieldBorder(isDark, false)),
                        ),
                        child: _isPractical
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text('1', style: TextStyle(
                                  color: AppTheme.accentPrimary,
                                  fontWeight: FontWeight.w800, fontSize: 14,
                                )),
                              )
                            : DropdownButton<double>(
                                value: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
                                        .contains(widget.course.creditHours)
                                    ? widget.course.creditHours : 3.0,
                                dropdownColor: isDark
                                    ? AppTheme.darkBgGradientStart
                                    : AppTheme.lightBgGradientStart,
                                underline: const SizedBox(),
                                isDense: true,
                                icon: Icon(Icons.expand_more, size: 16,
                                    color: AppTheme.textMuted(context)),
                                items: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0].map((e) {
                                  return DropdownMenuItem(value: e, child: Text(
                                    '${e.toInt()}', style: TextStyle(
                                      color: AppTheme.textPrimary(context),
                                      fontWeight: FontWeight.w600),
                                  ));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    _notifier.updateCourse(widget.course.id, creditHours: val);
                                    HapticFeedback.selectionClick();
                                  }
                                },
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL', style: _labelBase.copyWith(
                        color: AppTheme.textMuted(context),
                      )),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0x196366F1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x336366F1)),
                        ),
                        child: SizedBox(
                          width: 42,
                          child: TextField(
                            controller: _totalController,
                            focusNode: _totalFocus,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: _totalStyle,
                            decoration: InputDecoration(
                              hintText: '0',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 6),
                              hintStyle: _hintBase.copyWith(color: AppTheme.textMuted(context)),
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
                              _localTotal = d;
                              _gradeKey.currentState?.setState(() {});
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _GradeBadgeLive(gradeGetter: _localGrade, key: _gradeKey),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, size: 20,
                        color: AppTheme.textMuted(context)),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _notifier.removeCourse(widget.course.id);
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

  final GlobalKey<_GradeBadgeLiveState> _gradeKey = GlobalKey();

  Widget _buildMarkField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required ValueNotifier<bool> focusNotifier,
    required bool isDark,
    required String type,
  }) {
    return Expanded(
      child: ValueListenableBuilder<bool>(
        valueListenable: focusNotifier,
        builder: (context, isFocused, _) {
          return Column(
            children: [
              Text(label, style: _markLabelBase.copyWith(
                color: isFocused ? AppTheme.accentPrimary : AppTheme.textMuted(context),
              )),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: _fieldBg(isDark, isFocused),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _fieldBorder(isDark, isFocused)),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: _inputBase.copyWith(
                    color: AppTheme.textPrimary(context),
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: _hintBase.copyWith(color: AppTheme.textMuted(context)),
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
                    _onMarksChanged(type, d);
                    _totalController.text = _localTotal == 0 ? '' : _localTotal.toStringAsFixed(0);
                    _gradeKey.currentState?.setState(() {});
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GradeBadgeLive extends StatefulWidget {
  final String Function() gradeGetter;
  const _GradeBadgeLive({required this.gradeGetter, super.key});
  @override
  State<_GradeBadgeLive> createState() => _GradeBadgeLiveState();
}

class _GradeBadgeLiveState extends State<_GradeBadgeLive> {
  @override
  Widget build(BuildContext context) {
    final grade = widget.gradeGetter();
    return GradeBadge(grade: grade);
  }
}
