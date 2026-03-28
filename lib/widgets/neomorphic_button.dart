import 'package:flutter/material.dart';

class NeomorphicButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const NeomorphicButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.cyanAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.cyanAccent.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: child,
      ),
    );
  }
}
