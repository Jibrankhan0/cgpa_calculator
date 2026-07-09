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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(16);

    final bgColor = isDark
        ? (color ?? Colors.white).withValues(alpha: opacity)
        : (color ?? Colors.white).withValues(alpha: 0.7);

    final border = borderColor ?? (isDark
        ? const Color(0x14FFFFFF)
        : const Color(0x14000000));

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        border: Border.all(color: border, width: 1),
        boxShadow: [
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: isDark ? 0.08 : 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          BoxShadow(
            color: isDark
                ? const Color(0x14000000)
                : const Color(0x0D000000),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
