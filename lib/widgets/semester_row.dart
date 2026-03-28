import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/semester_result.dart';
import '../providers/semester_provider.dart';
import 'glass_card.dart';

class SemesterRow extends ConsumerStatefulWidget {
  final SemesterResult semester;

  const SemesterRow({super.key, required this.semester});

  @override
  ConsumerState<SemesterRow> createState() => _SemesterRowState();
}

class _SemesterRowState extends ConsumerState<SemesterRow> {
  late TextEditingController _nameController;
  late TextEditingController _gpaController;
  late FocusNode _nameFocus;
  late FocusNode _gpaFocus;
  bool _isDeleting = false;

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
      if (!_nameFocus.hasFocus &&
          _nameController.text != widget.semester.name) {
        ref
            .read(cgpaProvider.notifier)
            .updateSemester(widget.semester.id, name: _nameController.text);
      }
    });

    _gpaFocus.addListener(() {
      if (!_gpaFocus.hasFocus) {
        final gpa = double.tryParse(_gpaController.text) ?? 0;
        if (gpa != widget.semester.gpa) {
          ref
              .read(cgpaProvider.notifier)
              .updateSemester(widget.semester.id, gpa: gpa);
        }
      }
    });
  }

  @override
  void didUpdateWidget(SemesterRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.semester.name != widget.semester.name &&
        _nameController.text != widget.semester.name &&
        !_nameFocus.hasFocus) {
      _nameController.text = widget.semester.name;
    }
    final formattedGpa = widget.semester.gpa == 0
        ? ''
        : widget.semester.gpa.toString();
    if (oldWidget.semester.gpa != widget.semester.gpa &&
        _gpaController.text != formattedGpa &&
        !_gpaFocus.hasFocus) {
      _gpaController.text = formattedGpa;
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
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        useBlur: false, // Efficiency
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        borderColor: _isDeleting ? Colors.redAccent : null,
        opacity: _isDeleting ? 0.3 : 0.1,
        child: Row(
          children: [
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
                    decoration: const InputDecoration(
                      hintText: 'Semester Name',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.white38),
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    onSubmitted: (val) {
                      ref
                          .read(cgpaProvider.notifier)
                          .updateSemester(widget.semester.id, name: val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // GPA
            Expanded(
              flex: 4,
              child: TextField(
                controller: _gpaController,
                focusNode: _gpaFocus,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'GPA',
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
                  final gpa = double.tryParse(val) ?? 0;
                  ref
                      .read(cgpaProvider.notifier)
                      .updateSemester(widget.semester.id, gpa: gpa);
                },
              ),
            ),
            const SizedBox(width: 8),
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
                      .read(cgpaProvider.notifier)
                      .removeSemester(widget.semester.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
