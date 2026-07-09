import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/semester_result.dart';
import '../providers/semester_provider.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class SemesterCard extends ConsumerStatefulWidget {
  final SemesterResult semester;

  const SemesterCard({super.key, required this.semester});

  @override
  ConsumerState<SemesterCard> createState() => _SemesterCardState();
}

class _SemesterCardState extends ConsumerState<SemesterCard> {
  late TextEditingController _nameController;
  late TextEditingController _gpaController;
  late FocusNode _nameFocus;
  late FocusNode _gpaFocus;
  bool _isGpaFocused = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.semester.name);
    _gpaController = TextEditingController(
      text: widget.semester.gpa == 0 ? '' : widget.semester.gpa.toString(),
    );
    _nameFocus = FocusNode();
    _gpaFocus = FocusNode();

    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus && _nameController.text != widget.semester.name) {
        ref.read(cgpaProvider.notifier).updateSemester(
              widget.semester.id,
              name: _nameController.text,
            );
      }
    });

    _gpaFocus.addListener(() {
      _isGpaFocused = _gpaFocus.hasFocus;
      if (!_gpaFocus.hasFocus) {
        double gpa = double.tryParse(_gpaController.text) ?? 0;
        if (gpa > 4.0) {
          gpa = 4.0;
          _gpaController.text = '4.0';
        }
        if (gpa != widget.semester.gpa) {
          ref.read(cgpaProvider.notifier).updateSemester(
                widget.semester.id,
                gpa: gpa,
              );
        }
      }
    });
  }

  @override
  void didUpdateWidget(SemesterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.semester.name != widget.semester.name && !_nameFocus.hasFocus) {
      _nameController.text = widget.semester.name;
    }
    final formatted = widget.semester.gpa == 0 ? '' : widget.semester.gpa.toString();
    if (oldWidget.semester.gpa != widget.semester.gpa &&
        !_gpaFocus.hasFocus &&
        _gpaController.text != formatted) {
      _gpaController.text = formatted;
    }
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _gpaFocus.dispose();
    _nameController.dispose();
    _gpaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color fieldBg(bool focused) {
      if (isDark) return focused ? const Color(0x1A6366F1) : const Color(0x0DFFFFFF);
      return focused ? const Color(0x0D6366F1) : const Color(0x08000000);
    }

    Color fieldBorder(bool focused) {
      if (isDark) return focused ? const Color(0x4D6366F1) : const Color(0x14FFFFFF);
      return focused ? const Color(0x4D6366F1) : const Color(0x14000000);
    }

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.school_rounded, color: AppTheme.textMuted(context), size: 20),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: TextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  decoration: InputDecoration(
                    hintText: 'Semester Name',
                    border: InputBorder.none,
                    hintStyle: GoogleFonts.inter(
                      color: AppTheme.textMuted(context).withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: fieldBg(_isGpaFocused),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: fieldBorder(_isGpaFocused)),
                  ),
                  child: TextField(
                    controller: _gpaController,
                    focusNode: _gpaFocus,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'GPA',
                      border: InputBorder.none,
                      isDense: true,
                      hintStyle: GoogleFonts.inter(color: AppTheme.textMuted(context), fontSize: 13),
                    ),
                    style: GoogleFonts.inter(
                      color: AppTheme.accentPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    onChanged: (val) {
                      double gpa = double.tryParse(val) ?? 0;
                      if (gpa > 4.0) {
                        gpa = 4.0;
                        _gpaController.text = '4.0';
                        _gpaController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _gpaController.text.length),
                        );
                      }
                      ref.read(cgpaProvider.notifier).updateSemester(
                            widget.semester.id,
                            gpa: gpa,
                          );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: 20,
                    color: AppTheme.textMuted(context)),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(cgpaProvider.notifier).removeSemester(widget.semester.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
