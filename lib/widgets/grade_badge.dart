import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradeBadge extends StatelessWidget {
  final String grade;

  const GradeBadge({super.key, required this.grade});

  Color _getGradeColor() {
    switch (grade) {
      case 'A':
      case 'A-':
        return AppTheme.success;
      case 'B+':
      case 'B':
      case 'B-':
        return const Color(0xFF3B82F6);
      case 'C+':
      case 'C':
        return AppTheme.warning;
      case 'C-':
      case 'D':
        return const Color(0xFFF97316);
      case 'F':
        return AppTheme.danger;
      default:
        return AppTheme.darkTextMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getGradeColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        grade,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
