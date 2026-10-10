import 'package:flutter/material.dart';

class AnimatedCardFrame extends StatefulWidget {
  final Widget child;
  final bool animateEnter;
  final bool exiting;
  final VoidCallback? onExitComplete;

  const AnimatedCardFrame({
    super.key,
    required this.child,
    this.animateEnter = false,
    this.exiting = false,
    this.onExitComplete,
  });

  @override
  State<AnimatedCardFrame> createState() => _AnimatedCardFrameState();
}

class _AnimatedCardFrameState extends State<AnimatedCardFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _eased;
  bool _exitNotified = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.animateEnter ? 0.0 : 1.0,
    );
    _eased = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && widget.exiting && !_exitNotified) {
        _exitNotified = true;
        widget.onExitComplete?.call();
      }
    });
    if (widget.animateEnter) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedCardFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.exiting && !oldWidget.exiting) {
      _exitNotified = false;
      _controller.duration = const Duration(milliseconds: 280);
      _controller.reverse();
    } else if (!widget.exiting && oldWidget.exiting && !_exitNotified) {
      _controller.duration = const Duration(milliseconds: 300);
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _eased,
      builder: (context, child) {
        final v = _eased.value;
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: v,
            child: Opacity(
              opacity: v.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: widget.exiting
                    ? Offset(48 * (1 - v), 0)
                    : Offset(0, -14 * (1 - v)),
                child: child!,
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
