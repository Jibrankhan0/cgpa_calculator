import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SemesterChips extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onAdd;

  const SemesterChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final count = labels.length + (onAdd == null ? 0 : 1);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          if (i >= labels.length) {
            return InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.field,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: p.border),
                ),
                child: Text('+',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: p.muted)),
              ),
            );
          }
          final active = i == selectedIndex;
          return InkWell(
            onTap: () => onSelect(i),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? p.accent : p.field,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: active ? p.accent : p.border),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : p.muted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
