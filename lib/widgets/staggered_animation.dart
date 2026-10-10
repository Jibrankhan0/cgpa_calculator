import 'package:flutter/material.dart';

class StaggeredAnimation extends StatefulWidget {
  final int index;
  final Duration duration;
  final int staggerDelayMs;
  final Widget child;

  const StaggeredAnimation({
    super.key,
    required this.index,
    this.duration = const Duration(milliseconds: 350),
    this.staggerDelayMs = 50,
    required this.child,
  });

  @override
  State<StaggeredAnimation> createState() => _StaggeredAnimationState();
}

class _StaggeredAnimationState extends State<StaggeredAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    final delayMs = widget.staggerDelayMs * widget.index;
    final startRatio = (delayMs / widget.duration.inMilliseconds).clamp(0.0, 1.0);
    final endRatio = ((delayMs + 250) / widget.duration.inMilliseconds).clamp(0.0, 1.0);

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(startRatio, endRatio, curve: Curves.elasticOut),
    ));

    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(startRatio, endRatio, curve: Curves.easeOut),
    ));

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(startRatio, endRatio, curve: Curves.easeOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnim.value,
          child: Transform.translate(
            offset: _slideAnim.value,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}
