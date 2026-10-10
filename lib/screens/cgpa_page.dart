import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/cgpa_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_card_frame.dart';
import '../widgets/staggered_animation.dart';
import '../widgets/ui.dart';

class CgpaPage extends StatefulWidget {
  const CgpaPage({super.key});

  @override
  State<CgpaPage> createState() => _CgpaPageState();
}

class _CgpaPageState extends State<CgpaPage> {
  CgpaProvider? _provider;
  Set<String> _knownIds = <String>{};
  bool _seeded = false;
  String? _enterId;
  String? _exitId;
  Timer? _enterTimer;

  @override
  void dispose() {
    _enterTimer?.cancel();
    final id = _exitId;
    final provider = _provider;
    if (id != null && provider != null) {
      provider.removeSemester(id);
    }
    super.dispose();
  }

  void _completeExit(String id) {
    final provider = _provider;
    if (provider == null) return;
    provider.removeSemester(id);
    if (mounted) setState(() => _exitId = null);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CgpaProvider>();
    _provider = context.read<CgpaProvider>();

    final semesters = provider.semesters;

    final ids = semesters.map((s) => s.id).toSet();
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
        children: [
          ...List.generate(semesters.length, (i) {
            final semester = semesters[i];
            return StaggeredAnimation(
              index: i,
              child: AnimatedCardFrame(
                key: ValueKey(semester.id),
                animateEnter: semester.id == _enterId,
                exiting: semester.id == _exitId,
                onExitComplete: () => _completeExit(semester.id),
                child: _SemesterCard(
                  index: i,
                  semester: semester,
                  canDelete: semesters.length > 1,
                  onDelete: () {
                    if (_exitId == null) setState(() => _exitId = semester.id);
                  },
                  onChanged: (updated) => provider.updateSemester(
                    semester.id,
                    name: updated.name,
                    gpa: updated.gpa,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          StaggeredAnimation(
            index: semesters.length,
            child: UiCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add semester', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  IconButton(
                    key: const Key('add_semester_button'),
                    icon: const Icon(Icons.add_circle_outline, size: 28),
                    onPressed: () => provider.addSemester(),
                    tooltip: 'Add semester',
                  ),
                ],
              ),
            ),
          ),
          if (provider.cgpa != null) ...[
            const SizedBox(height: 10),
            StaggeredAnimation(
              index: semesters.length + 1,
              child: ResultCard(
                eyebrow: 'Cumulative CGPA',
                value: provider.cgpa!.toStringAsFixed(2),
                progress: provider.cgpa! / 4,
                message: 'Average of ${semesters.length} semester${semesters.length == 1 ? '' : 's'}.',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SemesterCard extends StatefulWidget {
  final int index;
  final CgpaSemester semester;
  final bool canDelete;
  final VoidCallback onDelete;
  final ValueChanged<CgpaSemester> onChanged;

  const _SemesterCard({
    required this.index,
    required this.semester,
    required this.canDelete,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<_SemesterCard> createState() => _SemesterCardState();
}

class _SemesterCardState extends State<_SemesterCard> {
  late TextEditingController _nameController;
  late TextEditingController _gpaController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.semester.name);
    _gpaController = TextEditingController(text: widget.semester.gpa.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(covariant _SemesterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.semester.name != widget.semester.name &&
        widget.semester.name != _nameController.text) {
      _nameController.text = widget.semester.name;
    }
    if (oldWidget.semester.gpa != widget.semester.gpa &&
        widget.semester.gpa.toStringAsFixed(2) != _gpaController.text) {
      _gpaController.text = widget.semester.gpa.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gpaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final gpa = widget.semester.gpa;

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
                    key: Key('cgpa_semester_name_${widget.index}'),
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
                      CgpaSemester(
                        id: widget.semester.id,
                        name: v,
                        gpa: widget.semester.gpa,
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
              children: [
                const Expanded(child: FieldLabel(text: 'GPA')),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: _gpaController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d{0,1}\.?\d{0,2}$')),
                    ],
                    decoration: fieldInput(context, hint: '0.00'),
                    style: numStyle(14, FontWeight.w700, p.fg),
                    onChanged: (v) {
                      final g = double.tryParse(v);
                      if (g != null && g >= 0 && g <= 4) {
                        widget.onChanged(
                          CgpaSemester(
                            id: widget.semester.id,
                            name: widget.semester.name,
                            gpa: g,
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text('/ 4.00', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.muted)),
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
                      gpa > 0
                          ? 'GPA ${gpa.toStringAsFixed(2)} · included in CGPA'
                          : 'Enter GPA to include in CGPA',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w400, color: p.muted),
                    ),
                  ),
                  gpa > 0
                      ? Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.accentSoft,
                            borderRadius: BorderRadius.circular(kRadius),
                          ),
                          child: Text(gpa.toStringAsFixed(2),
                              style: numStyle(13, FontWeight.w800, p.accentInk)),
                        )
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
}