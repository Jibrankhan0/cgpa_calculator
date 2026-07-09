import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  static final _titleStyle = GoogleFonts.lexend(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static final _subtitleStyle = GoogleFonts.inter(
    fontSize: 13,
  );

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x0D6366F1),
                border: Border.all(
                  color: isDark ? const Color(0x1A6366F1) : const Color(0x1A6366F1),
                ),
              ),
              child: Icon(
                icon,
                size: 32,
                color: AppTheme.accentPrimary.withAlpha(180),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: _titleStyle.copyWith(
                color: AppTheme.textSecondary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: _subtitleStyle.copyWith(
                color: AppTheme.textMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
