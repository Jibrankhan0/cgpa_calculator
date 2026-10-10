import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../services/gpa_service.dart';
import '../theme/app_theme.dart';
import '../widgets/semester_chips.dart';
import '../widgets/staggered_animation.dart';
import '../widgets/ui.dart';

class StoragePage extends StatefulWidget {
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  String? _selectedSemesterId;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final provider = context.watch<DataProvider>();
    final sheet = provider.semesters;

    if (sheet.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        child: StaggeredAnimation(
          index: 0,
          child: EmptyState(
            title: 'No saved data yet',
            body: 'Add a semester and subjects to store your marks.',
            buttonLabel: 'Add your first semester',
            onButton: () => context.read<DataProvider>().addSemester(),
          ),
        ),
      );
    }

    if (_selectedSemesterId == null ||
        !sheet.any((s) => s.id == _selectedSemesterId)) {
      _selectedSemesterId = sheet.first.id;
    }
    final selected = sheet.firstWhere((s) => s.id == _selectedSemesterId,
        orElse: () => sheet.first);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StaggeredAnimation(
            index: 0,
            child: Row(
              children: [
                const Expanded(child: SectionHeader('Saved data')),
                GhostButton(
                  label: 'Export Excel',
                  icon: Icons.download_outlined,
                  onTap: () => _exportSheet(context, provider),
                ),
                const SizedBox(width: 8),
                GhostButton(
                  label: 'Clear All',
                  icon: Icons.delete_outline,
                  danger: true,
                  onTap: () => _showClearDialog(context, provider),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StaggeredAnimation(
            index: 1,
            child: SemesterChips(
              labels: sheet.map((s) => s.name).toList(),
              selectedIndex: sheet.indexOf(selected),
              onSelect: (i) => setState(() => _selectedSemesterId = sheet[i].id),
              onAdd: () => context.read<DataProvider>().addSemester(),
            ),
          ),
const SizedBox(height: 20),
          StaggeredAnimation(
            index: 2,
            child: UiCard(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: _SheetTable(semester: selected, palette: p, provider: provider),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportSheet(BuildContext context, DataProvider provider) async {
    final buf = StringBuffer('Semester,Subject,CR,MID,FINAL,SEC,LAB,LAB(Y/N)\n');
    for (final sem in provider.semesters) {
      for (final sub in sem.subjects) {
        buf.writeln([
          sem.name,
          sub.name,
          sub.credits,
          sub.mid.isEmpty ? '-' : sub.mid,
          sub.finalMarks.isEmpty ? '-' : sub.finalMarks,
          sub.sectional.isEmpty ? '-' : sub.sectional,
          sub.isLab && sub.lab.isNotEmpty ? sub.lab : '-',
          sub.isLab ? 'Y' : 'N',
        ].join(','));
      }
    }
    final csv = buf.toString();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${provider.semesters.length} semesters ready to copy'),
          action: SnackBarAction(
            label: 'Copy CSV',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV copied to clipboard')),
                );
              }
            },
          ),
        ),
      );
    }
  }

  

  void _showClearDialog(BuildContext context, DataProvider provider) {
    final p = Palette.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all saved data?'),
        content: const Text('This will clear all semesters and subjects.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.clearAll();
              Navigator.pop(ctx);
            },
            child: Text('Clear', style: TextStyle(color: p.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SheetTable extends StatelessWidget {
  final DataSemester semester;
  final Palette palette;
  final DataProvider provider;

  const _SheetTable({required this.semester, required this.palette, required this.provider});

  static const double _nameW = 130;

  @override
  Widget build(BuildContext context) {
    final p = palette;

    TableRow headerRow = TableRow(children: [
      _cell('SUBJECT', head: true),
      _cell('CR', head: true),
      _cell('MID\n/25', head: true),
      _cell('FINAL\n/50', head: true),
      _cell('SEC\n/25', head: true),
      _cell('LAB\n/50', head: true),
      _cell('TOTAL', head: true),
      _cell('GRADE', head: true),
    ]);

    final rows = <TableRow>[headerRow];
    for (final sub in semester.subjects) {
      final total = _totalOf(sub);
      final grade = _gradeOf(sub);
      rows.add(TableRow(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Row(
            children: [
              Flexible(
                child: Text(sub.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.fg)),
              ),
              if (sub.isLab) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => provider.updateSubject(semester.id, sub.id, isLab: false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFF5E9),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text('LAB',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline, size: 14, color: Colors.grey),
                  onPressed: () => _deleteSubject(context, sub.id),
                  tooltip: 'Delete subject',
                ),
              ),
            ],
          ),
        ),
        _editCell(sub, 'credits', 10),
        _editCell(sub, 'mid', 25),
        _editCell(sub, 'final', 50),
        _editCell(sub, 'sectional', 25),
        sub.isLab
            ? _editCell(sub, 'lab', 50)
            : _labToggleCell(sub),
        _cell(total == null ? '—' : '${total.toInt()}', numeric: true, bold: true),
        _cell(grade?.letter ?? '—', numeric: true, pill: grade != null),
]));
    }
 
    final creditSum = semester.subjects.fold(0, (a, s) => a + _creditsOf(s));
    rows.add(TableRow(children: [
      Padding(
        padding: const EdgeInsets.only(top: 10, right: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(semester.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: p.fg)),
            const SizedBox(height: 2),
            Text('${semester.subjects.length} subjects · $creditSum cr',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500, color: p.muted)),
          ],
        ),
      ),
      const TableCell(child: SizedBox()),
      const TableCell(child: SizedBox()),
      const TableCell(child: SizedBox()),
      const TableCell(child: SizedBox()),
      const TableCell(child: SizedBox()),
      const TableCell(child: SizedBox()),
      const TableCell(child: SizedBox()),
    ]));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 470),
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(_nameW),
                1: FixedColumnWidth(30),
                2: FixedColumnWidth(42),
                3: FixedColumnWidth(46),
                4: FixedColumnWidth(42),
                5: FixedColumnWidth(42),
                6: FixedColumnWidth(48),
                7: FlexColumnWidth(),
              },
              children: rows,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: p.accent,
          borderRadius: BorderRadius.circular(7),
          child: InkWell(
            onTap: () => provider.addSubject(semester.id),
            borderRadius: BorderRadius.circular(7),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Add subject',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  int _creditsOf(DataSubject s) => s.isLab ? 1 : s.credits;

  double? _totalOf(DataSubject s) {
    double t = 0;
    t += double.tryParse(s.mid) ?? 0;
    t += double.tryParse(s.finalMarks) ?? 0;
    t += double.tryParse(s.sectional) ?? 0;
    if (s.isLab) t += double.tryParse(s.lab) ?? 0;
    return t > 0 ? t : null;
  }

  double? _percentOf(DataSubject s) {
    final total = _totalOf(s);
    if (total == null) return null;
    final max = s.isLab ? 150.0 : 100.0;
    return total / max * 100;
  }

  GradeInfo? _gradeOf(DataSubject s) {
    final p = _percentOf(s);
    if (p == null) return null;
    return GpaService.getGradeFromMarks(p);
  }

  void _deleteSubject(BuildContext context, String subjectId) {
    if (semester.subjects.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the last subject')),
      );
      return;
    }
    provider.removeSubject(semester.id, subjectId);
  }

  Widget _labToggleCell(DataSubject sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
      child: Center(
        child: InkWell(
          onTap: () => provider.updateSubject(semester.id, sub.id, isLab: true),
          borderRadius: BorderRadius.circular(6),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            child: Text('—',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
          ),
        ),
      ),
    );
  }

  Widget _editCell(DataSubject sub, String field, int max) {
    String value;
    switch (field) {
      case 'mid':
        value = sub.mid;
        break;
      case 'final':
        value = sub.finalMarks;
        break;
      case 'sectional':
        value = sub.sectional;
        break;
      case 'credits':
        value = sub.credits.toString();
        break;
      default:
        value = sub.lab;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
      child: Center(
        child: _CellField(
          key: ValueKey('${sub.id}_$field'),
          value: value,
          max: max,
          onSet: (v) => provider.updateSubject(
            semester.id,
            sub.id,
            mid: field == 'mid' ? v : null,
            finalMarks: field == 'final' ? v : null,
            sectional: field == 'sectional' ? v : null,
            lab: field == 'lab' ? v : null,
            credits: field == 'credits' ? int.tryParse(v) : null,
          ),
        ),
      ),
    );
  }

  Widget _cell(
    String text, {
    bool head = false,
    bool numeric = false,
    bool bold = false,
    bool pill = false,
    bool accent = false,
  }) {
    final p = palette;
    Widget child;
    if (pill) {
      child = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: p.accentSoft,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: p.accentInk)),
      );
    } else {
      child = Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: numeric ? TextAlign.center : TextAlign.left,
        style: head
            ? const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF94A3B8),
                letterSpacing: .4)
            : TextStyle(
                fontSize: 11,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: accent
                    ? const Color(0xFF16A34A)
                    : (numeric ? const Color(0xFF334155) : palette.fg)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
      child: numeric ? Center(child: child) : child,
    );
  }
}

class _CellField extends StatefulWidget {
  final String value;
  final int max;
  final ValueChanged<String> onSet;

  const _CellField({super.key, required this.value, required this.max, required this.onSet});

  @override
  State<_CellField> createState() => _CellFieldState();
}

class _CellFieldState extends State<_CellField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _CellField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: TextField(
        controller: _controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
          hintText: '—',
          hintStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Palette.of(context).muted),
        ),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF334155)),
        onChanged: (v) {
          var out = v;
          final n = int.tryParse(v);
          if (v.isNotEmpty && (n == null || n > widget.max)) {
            out = n == null ? '' : '${widget.max}';
          }
          widget.onSet(out);
          if (out != v) {
            _controller.text = out;
            _controller.selection = TextSelection.collapsed(offset: out.length);
          }
        },
      ),
    );
  }
}