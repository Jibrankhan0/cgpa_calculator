import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  static final _labelStyle = GoogleFonts.inter(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );

  static final _valueStyle = GoogleFonts.lexend(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  const MiniStatCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x0AFFFFFF) : const Color(0x0A000000),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0x14FFFFFF) : const Color(0x14000000),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: _labelStyle.copyWith(
              color: AppTheme.textMuted(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: _valueStyle.copyWith(
              color: valueColor ?? AppTheme.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}
