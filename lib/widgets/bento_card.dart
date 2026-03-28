import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glass_card.dart';

class BentoCard extends StatelessWidget {
  final String title;
  final Widget content;
  final Color? glowColor;
  final bool isLarge;

  const BentoCard({
    super.key,
    required this.title,
    required this.content,
    this.glowColor,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor!.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: GlassCard(
        useBlur: false, // Efficiency: Disable blur on static summary cards
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white60,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Center(child: content),
          ],
        ),
      ),
    );
  }
}
