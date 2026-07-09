import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'circular_progress_ring.dart';
import 'glass_card.dart';
import 'mini_stat_card.dart';

class HeroGpaCard extends StatelessWidget {
  final double gpa;
  final String label;
  final double totalCredits;
  final int courseCount;

  static final _labelStyle = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
  );

  static final _gpaStyle = GoogleFonts.lexend(
    fontSize: 44,
    fontWeight: FontWeight.bold,
    height: 1,
  );

  const HeroGpaCard({
    super.key,
    required this.gpa,
    required this.label,
    required this.totalCredits,
    required this.courseCount,
  });

  @override
  Widget build(BuildContext context) {
    final gpaColor = AppTheme.getGpaColor(gpa);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircularProgressRing(
            value: gpa,
            color: gpaColor,
            size: 88,
            strokeWidth: 8,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: _labelStyle.copyWith(
                    color: AppTheme.textMuted(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  gpa.toStringAsFixed(2),
                  style: _gpaStyle.copyWith(
                    color: gpaColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              MiniStatCard(
                label: 'Credits',
                value: totalCredits.toStringAsFixed(1),
              ),
              const SizedBox(height: 8),
              MiniStatCard(
                label: 'Courses',
                value: courseCount.toString(),
                valueColor: AppTheme.accentPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
