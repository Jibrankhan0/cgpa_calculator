import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    if (oldWidget.semester.name != widget.semester.name &&
        !_nameFocus.hasFocus) {
      _nameController.text = widget.semester.name;
    }
    final formatted = widget.semester.gpa == 0
        ? ''
        : widget.semester.gpa.toString();
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.school_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: TextField(
                controller: _nameController,
                focusNode: _nameFocus,
                decoration: InputDecoration(
                  hintText: 'Semester Name',
                  border: InputBorder.none,
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
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: TextField(
                  controller: _gpaController,
                  focusNode: _gpaFocus,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: 'GPA',
                    border: InputBorder.none,
                    isDense: true,
                    hintStyle: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  style: const TextStyle(
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
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: AppTheme.textMuted,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                ref.read(cgpaProvider.notifier).removeSemester(widget.semester.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
