import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final bool useBlur;
  final Color? color;
  final Color? glowColor;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.06,
    this.useBlur = false,
    this.padding,
    this.borderRadius,
    this.borderColor,
    this.color,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withValues(alpha: opacity),
        borderRadius: radius,
        border: Border.all(
          color: borderColor ?? const Color(0x14FFFFFF),
          width: 1,
        ),
        boxShadow: [
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          const BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );

    if (useBlur) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    return content;
  }
}
