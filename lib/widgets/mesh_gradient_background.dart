import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MeshGradientBackground extends StatelessWidget {
  final Widget child;

  const MeshGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.bgGradientStart,
                  AppTheme.bgPrimary,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Indigo glow top-left
                Positioned(
                  top: -120,
                  left: -80,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.accentPrimary.withValues(alpha: 0.15),
                          AppTheme.accentPrimary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Purple glow bottom-right
                Positioned(
                  bottom: -150,
                  right: -100,
                  child: Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.accentSecondary.withValues(alpha: 0.1),
                          AppTheme.accentSecondary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Subtle center glow
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.3,
                  left: MediaQuery.of(context).size.width * 0.3,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.accentPrimary.withValues(alpha: 0.05),
                          AppTheme.accentPrimary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(child: child),
      ],
    );
  }
}
