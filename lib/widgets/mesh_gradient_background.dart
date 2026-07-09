import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MeshGradientBackground extends StatelessWidget {
  final Widget child;

  const MeshGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [AppTheme.darkBgGradientStart, AppTheme.darkBgPrimary]
                  : [AppTheme.lightBgGradientStart, AppTheme.lightBgPrimary],
            ),
          ),
        ),
        SafeArea(child: child),
      ],
    );
  }
}
