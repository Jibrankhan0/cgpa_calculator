import 'dart:ui';
import 'package:flutter/material.dart';

class MeshGradientBackground extends StatelessWidget {
  final Widget child;

  const MeshGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Isolated Background layer
        RepaintBoundary(
          child: Stack(
            children: [
              // Base dark background
              Container(color: const Color(0xFF0A0E21)),
              // Deep Indigo Glow
              Positioned(
                top: -100,
                left: -100,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF3F51B5).withValues(alpha: 0.3),
                        const Color(0xFF3F51B5).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Cyan Glow
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
                        const Color(0xFF00E5FF).withValues(alpha: 0.2),
                        const Color(0xFF00E5FF).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Frosted overlay - Replaced expensive BackdropFilter with a simple color overlay
              Container(color: const Color(0xFF0A0E21).withValues(alpha: 0.4)),
            ],
          ),
        ),

        // Content
        SafeArea(child: child),
      ],
    );
  }
}
