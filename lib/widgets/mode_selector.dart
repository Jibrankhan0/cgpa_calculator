import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/semester_provider.dart';
import '../theme/app_theme.dart';

class ModeSelector extends StatelessWidget {
  final CalculationMode currentMode;
  final Function(CalculationMode) onChanged;

  const ModeSelector({
    super.key,
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x0DFFFFFF) : const Color(0x0D000000),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0x14FFFFFF) : const Color(0x14000000),
        ),
      ),
      child: Row(
        children: [
          _buildTab(CalculationMode.gpa, 'GPA (Single)', isDark),
          _buildTab(CalculationMode.cgpa, 'CGPA (Multi)', isDark),
        ],
      ),
    );
  }

  Widget _buildTab(CalculationMode mode, String label, bool isDark) {
    final isSelected = currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [AppTheme.accentPrimary, AppTheme.accentSecondary],
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x4D6366F1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
