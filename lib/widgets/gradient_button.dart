import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.accentPrimary, AppTheme.accentSecondary],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4D6366F1),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
