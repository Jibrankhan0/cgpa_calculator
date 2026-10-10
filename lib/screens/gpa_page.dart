import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/gpa_provider.dart';
import '../services/gpa_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_card_frame.dart';
import '../widgets/staggered_animation.dart';
import '../widgets/ui.dart';

class GpaPage extends StatefulWidget {
  const GpaPage({super.key});

  @override
  State<GpaPage> createState() => _GpaPageState();
}

class _GpaPageState extends State<GpaPage> {
  GpaProvider? _provider;
  Set<String> _knownIds = <String>{};
  bool _seeded = false;
  String? _enterId;
  String? _exitId;
  Timer? _enterTimer;
  late TextEditingController _semesterNameController;

  @override
  void initState() {
    super.initState();
    _semesterNameController = TextEditingController();
  }

  @override
  void dispose() {
    _enterTimer?.cancel();
    _semesterNameController.dispose();
    final id = _exitId;
    final provider = _provider;
    if (id != null && provider != null) {
      provider.removeSubject(id);
    }
    super.dispose();
  }

  void _completeExit(String id) {
    final provider = _provider;
    if (provider == null) return;
    provider.removeSubject(id);
    if (mounted) {
      setState(() => _exitId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GpaProvider>();
    _provider = context.read<GpaProvider>();

    _semesterNameController.text = provider.semesterName;

    final subjects = provider.subjects;

    final ids = subjects.map((s) => s.id).toSet();
    if (_seeded) {
      final added = ids.difference(_knownIds);
      if (added.isNotEmpty) {
        _enterId = added.first;
        _enterTimer?.cancel();
        _enterTimer = Timer(const Duration(milliseconds: 400), () {
          if (mounted) setState(() => _enterId = null);
        });
      }
    } else {
      _enterTimer?.cancel();
      _enterId = null;
    }
    _knownIds = ids;
    _seeded = true;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: SectionHeader('Semester')),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  key: const Key('semester_name_field'),
                  controller: _semesterNameController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                  ),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  onChanged: (v) => provider.setSemesterName(v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(subjects.length, (i) {
            final subject = subjects[i];
            return StaggeredAnimation(
              index: i,
              child: AnimatedCardFrame(
                key: ValueKey(subject.id),
                animateEnter: subject.id == _enterId,
                exiting: subject.id == _exitId,
                onExitComplete: () => _completeExit(subject.id),
                child: _SubjectCard(
                  index: i,
                  subject: subject,
                  canDelete: subjects.length > 1,
                  onDelete: () {
                    if (_exitId == null) {
                      setState(() => _exitId = subject.id);
                    }
                  },
                  onChanged: (updated) => provider.updateSubject(
                    subject.id,
                    name: updated.name,
                    credits: updated.credits,
                    isLab: updated.isLab,
                    legacyMarks: updated.legacyMarks,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          StaggeredAnimation(
            index: subjects.length,
            child: UiCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add subject', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  IconButton(
                    key: const Key('add_subject_button'),
                    icon: const Icon(Icons.add_circle_outline, size: 28),
                    onPressed: () => provider.addSubject(),
                    tooltip: 'Add subject',
                  ),
                ],
              ),
            ),
          ),
          if (provider.gpa != null) ...[
            const SizedBox(height: 10),
            StaggeredAnimation(
              index: subjects.length + 1,
              child: ResultCard(
                eyebrow: 'Semester GPA',
                value: provider.gpa!.toStringAsFixed(2),
                progress: provider.gpa! / 4,
                message: GpaService.getGpaMessage(provider.gpa!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubjectCard extends StatefulWidget {
  final int index;
  final GpaSubject subject;
  final bool canDelete;
  final VoidCallback onDelete;
  final ValueChanged<GpaSubject> onChanged;

  const _SubjectCard({
    required this.index,
    required this.subject,
    required this.canDelete,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard> {
  late TextEditingController _nameController;
  late TextEditingController _marksController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject.name);
    _marksController = TextEditingController(text: widget.subject.legacyMarks);
  }

  @override
  void didUpdateWidget(covariant _SubjectCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subject.name != widget.subject.name &&
        widget.subject.name != _nameController.text) {
      _nameController.text = widget.subject.name;
    }
    if (oldWidget.subject.legacyMarks != widget.subject.legacyMarks &&
        widget.subject.legacyMarks != _marksController.text) {
      _marksController.text = widget.subject.legacyMarks;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _marksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final isLab = widget.subject.isLab;
    final grade = _gradeOf(widget.subject);
    final cr = widget.subject.credits;
    final displayValue = widget.subject.legacyMarks;
    final error = GpaService.validateMarks(displayValue, isLab: isLab);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: UiCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IdxBadge(text: '${widget.index + 1}'.padLeft(2, '0')),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    key: Key('subject_name_${widget.index}'),
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      filled: false,
                    ),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.fg),
                    onChanged: (v) => widget.onChanged(
                      GpaSubject(
                        id: widget.subject.id,
                        name: v,
                        credits: widget.subject.credits,
                        isLab: widget.subject.isLab,
                        legacyMarks: widget.subject.legacyMarks,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: InkWell(
                    onTap: widget.canDelete ? widget.onDelete : null,
                    borderRadius: BorderRadius.circular(kRadius),
                    child: Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: widget.canDelete ? p.muted : p.muted.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(child: FieldLabel(text: 'Marks')),
                SizedBox(
                  width: 96,
                  child: TextField(
                    controller: _marksController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}\.?\d{0,1}$')),
                    ],
                    decoration: fieldInput(context, hint: '0', error: error != null),
                    style: numStyle(14, FontWeight.w700, p.fg),
                    onChanged: (v) => widget.onChanged(
                      GpaSubject(
                        id: widget.subject.id,
                        name: widget.subject.name,
                        credits: widget.subject.credits,
                        isLab: widget.subject.isLab,
                        legacyMarks: v,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('/ ${isLab ? 50 : 100}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.muted)),
              ],
            ),
            if (error != null) InputError(message: error),
            if (!isLab) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(child: FieldLabel(text: 'Credit hours')),
                  for (int c = 1; c <= 5; c++) ...[
                    if (c > 1) const SizedBox(width: 6),
                    _CreditChip(
                      value: c,
                      active: c == cr,
                      onTap: () => widget.onChanged(
                        GpaSubject(
                          id: widget.subject.id,
                          name: widget.subject.name,
                          credits: c,
                          isLab: widget.subject.isLab,
                          legacyMarks: widget.subject.legacyMarks,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(child: FieldLabel(text: 'Lab')),
                Text(
                  isLab ? 'On' : 'Off',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.muted),
                ),
                const SizedBox(width: 8),
                AppSwitch(
                  value: isLab,
                  onChanged: (v) => widget.onChanged(
                    GpaSubject(
                      id: widget.subject.id,
                      name: widget.subject.name,
                      credits: v ? 1 : widget.subject.credits,
                      isLab: v,
                      legacyMarks: widget.subject.legacyMarks,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      grade != null
                          ? (isLab ? 'Lab · weight 1' : 'Non-lab · weight $cr')
                          : 'Fix marks to grade',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w400, color: p.muted),
                    ),
                  ),
                  grade != null
                      ? GradeChip(letter: grade.letter, gpa: grade.gpa)
                      : Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.field,
                            borderRadius: BorderRadius.circular(kRadius),
                            border: Border.all(color: p.border),
                          ),
                          child: Text('— pending',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.muted)),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  GradeInfo? _gradeOf(GpaSubject s) {
    if (s.legacyMarks.isEmpty) return null;
    final v = double.tryParse(s.legacyMarks);
    if (v == null) return null;
    final pct = s.isLab ? v * 2 : v;
    return GpaService.getGradeFromMarks(pct);
  }
}

class _CreditChip extends StatelessWidget {
  final int value;
  final bool active;
  final VoidCallback onTap;

  const _CreditChip({required this.value, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Material(
      color: active ? p.accentSoft : p.field,
      borderRadius: BorderRadius.circular(kRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadius),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: active ? p.accent : p.border),
          ),
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? p.accentInk : p.fg,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}