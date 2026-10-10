import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

const double kRadius = 8;

TextStyle numStyle(double size, FontWeight weight, Color color) => TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

class UiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const UiCard({super.key, required this.child, this.padding = const EdgeInsets.all(12)});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: p.border),
      ),
      child: child,
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.muted, letterSpacing: 1.54),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool expanded;

  const PrimaryButton({super.key, required this.label, this.onTap, this.icon, this.expanded = false});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final btn = Material(
      color: p.accentDeep,
      borderRadius: BorderRadius.circular(kRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadius),
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 15, color: Colors.white), const SizedBox(width: 8)],
              Text(label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
    final gated = onTap == null ? Opacity(opacity: 0.45, child: btn) : btn;
    return expanded ? SizedBox(width: double.infinity, child: gated) : gated;
  }
}

class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool danger;

  const GhostButton({super.key, required this.label, this.onTap, this.icon, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final fg = danger ? p.danger : p.fg;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(kRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadius),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: danger ? p.danger.withValues(alpha: 0.4) : p.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 6)],
              Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  const SquareIconButton({super.key, required this.icon, this.onTap, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(kRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadius),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: p.border),
          ),
          child: Icon(icon, size: 19, color: p.fg),
        ),
      ),
    );
  }
}

class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AppSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: value ? p.accentSoft : p.field,
          border: Border.all(color: value ? p.accent : p.border),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(shape: BoxShape.circle, color: value ? p.accent : p.muted),
          ),
        ),
      ),
    );
  }
}

class IdxBadge extends StatelessWidget {
  final String text;
  const IdxBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(kRadius)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.accentInk)),
    );
  }
}

class GradeChip extends StatelessWidget {
  final String letter;
  final double gpa;
  const GradeChip({super.key, required this.letter, required this.gpa});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(kRadius)),
      child: Text(
        '$letter · ${gpa.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: p.accentInk,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String status;
  final bool up;
  const StatusPill({super.key, required this.status, required this.up});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: up ? p.accentSoft : p.field,
        borderRadius: BorderRadius.circular(kRadius),
        border: up ? null : Border.all(color: p.border),
      ),
      child: Text(status,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: up ? p.accentInk : p.muted)),
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Text(
      text.toUpperCase(),
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.muted, letterSpacing: 0.88),
    );
  }
}

class InputError extends StatelessWidget {
  final String message;
  const InputError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 14, color: p.accentInk),
          const SizedBox(width: 6),
          Expanded(
            child:
                Text(message, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.accentInk)),
          ),
        ],
      ),
    );
  }
}

InputDecoration fieldInput(BuildContext context, {String? hint, bool error = false}) {
  final p = Palette.of(context);
  OutlineInputBorder outline(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadius),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: error ? p.accentSoft : p.field,
    hintStyle: TextStyle(color: p.muted, fontWeight: FontWeight.w500),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: outline(error ? p.accent : p.border),
    enabledBorder: outline(error ? p.accent : p.border),
    focusedBorder: outline(p.accent, 1.5),
  );
}

class ResultCard extends StatelessWidget {
  final String eyebrow;
  final String value;
  final double? progress;
  final String? message;

  const ResultCard(
      {super.key, required this.eyebrow, required this.value, this.progress, this.message});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return UiCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: p.muted, letterSpacing: 1.8),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: numStyle(40, FontWeight.w800, p.accentInk)),
              const SizedBox(width: 8),
              Text('of 4.00', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.muted)),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: p.field,
                border: Border.all(color: p.border),
                borderRadius: BorderRadius.circular(999),
              ),
              child: SizedBox(
                height: 6,
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress!.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: p.muted, height: 1.45)),
          ],
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  const StatTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: numStyle(22, FontWeight.w800, p.fg)),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: p.muted, letterSpacing: 1.05),
          ),
        ],
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsRow(
      {super.key,
      required this.icon,
      required this.label,
      required this.desc,
      this.trailing,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(kRadius)),
              child: Icon(icon, size: 17, color: p.accentInk),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.fg)),
                  const SizedBox(height: 1),
                  Text(desc, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: p.muted)),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right, size: 15, color: p.muted),
          ],
        ),
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

class EmptyState extends StatelessWidget {
  final String title;
  final String body;
  final String? buttonLabel;
  final VoidCallback? onButton;

  const EmptyState(
      {super.key,
      required this.title,
      required this.body,
      this.buttonLabel,
      this.onButton});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(kRadius)),
            child: Icon(Icons.folder_outlined, size: 20, color: p.accentInk),
          ),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.fg)),
          const SizedBox(height: 4),
          Text(body,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: p.muted, height: 1.45)),
          if (buttonLabel != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(label: buttonLabel!, icon: Icons.add, onTap: onButton, expanded: true),
            ),
          ],
        ],
      ),
    );
  }
}
