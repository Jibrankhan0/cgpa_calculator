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

    return RepaintBoundary(
      child: GlassCard(
        glowColor: gpaColor,
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
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted(context),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    gpa.toStringAsFixed(2),
                    style: GoogleFonts.lexend(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color: gpaColor,
                      height: 1,
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
      ),
    );
  }
}
