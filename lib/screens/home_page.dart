import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/cgpa_provider.dart';
import '../providers/data_provider.dart';
import '../services/gpa_service.dart';
import '../theme/app_theme.dart';
import '../widgets/staggered_animation.dart';
import '../widgets/ui.dart';

class HomePage extends StatelessWidget {
  final ValueChanged<int> onSwitchTab;
  const HomePage({super.key, required this.onSwitchTab});

  static double? recordGpa(DataProvider data) {
    double points = 0;
    double credits = 0;
    for (final sem in data.semesters) {
      for (final sub in sem.subjects) {
        var total = (double.tryParse(sub.mid) ?? 0) +
            (double.tryParse(sub.finalMarks) ?? 0) +
            (double.tryParse(sub.sectional) ?? 0);
        if (sub.isLab) total += double.tryParse(sub.lab) ?? 0;
        if (total <= 0) continue;
        final max = sub.isLab ? 150.0 : 100.0;
        final grade = GpaService.getGradeFromMarks(total / max * 100);
        if (grade == null) continue;
        final cr = sub.isLab ? 1.0 : sub.credits.toDouble();
        points += grade.gpa * cr;
        credits += cr;
      }
    }
    if (credits == 0) return null;
    return points / credits;
  }

  @override
  Widget build(BuildContext context) {
    final cgpaProvider = context.watch<CgpaProvider>();
    final dataProvider = context.watch<DataProvider>();
    final cgpa = cgpaProvider.cgpa;
    final record = recordGpa(dataProvider);
    final hero = cgpa ?? record;
    final heroSubtitle = cgpa != null
        ? 'Your cumulative CGPA'
        : record != null
            ? 'Cumulative GPA from saved record'
            : 'Add semester GPAs to see your CGPA';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggeredAnimation(
            index: 0,
            child: _HeroCard(cgpa: hero, subtitle: heroSubtitle, onSwitchTab: onSwitchTab),
          ),
          StaggeredAnimation(
            index: 1,
            child: const SectionHeader('Your record'),
          ),
          StaggeredAnimation(
            index: 2,
            child: _StatsGrid(data: dataProvider, avg: record ?? cgpa),
          ),
          const SizedBox(height: 10),
          StaggeredAnimation(
            index: 3,
            child: _MotivationStrip(cgpa: hero),
          ),
          StaggeredAnimation(
            index: 4,
            child: const SectionHeader('Quick actions'),
          ),
          StaggeredAnimation(
            index: 5,
            child: _QuickActions(onSwitchTab: onSwitchTab),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Card ────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final double? cgpa;
  final String subtitle;
  final ValueChanged<int> onSwitchTab;
  const _HeroCard({required this.cgpa, required this.subtitle, required this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.invBg,
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR CGPA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: p.invEyebrow,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                cgpa != null ? cgpa!.toStringAsFixed(2) : '—',
                style: numStyle(46, FontWeight.w800, p.invFg),
              ),
              const SizedBox(width: 8),
              Text(
                '/ 4.00',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: p.invFg.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: p.invFg.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: p.accentDeep,
            borderRadius: BorderRadius.circular(kRadius),
            child: InkWell(
              onTap: () => onSwitchTab(1),
              borderRadius: BorderRadius.circular(kRadius),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Add grades',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 15, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Grid ───────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final DataProvider data;
  final double? avg;
  const _StatsGrid({required this.data, required this.avg});

  @override
  Widget build(BuildContext context) {
    final semesters = data.semesters.length;
    var subjects = 0;
    var credits = 0;
    for (final sem in data.semesters) {
      subjects += sem.subjects.length;
      for (final sub in sem.subjects) {
        credits += sub.isLab ? 1 : sub.credits;
      }
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: StatTile(label: 'Avg GPA', value: avg != null ? avg!.toStringAsFixed(2) : '—')),
            const SizedBox(width: 8),
            Expanded(child: StatTile(label: 'Semesters', value: '$semesters')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: StatTile(label: 'Subjects', value: '$subjects')),
            const SizedBox(width: 8),
            Expanded(child: StatTile(label: 'Credits', value: '$credits')),
          ],
        ),
      ],
    );
  }
}

// ─── Motivation Strip ─────────────────────────────────────────────
class _MotivationStrip extends StatelessWidget {
  final double? cgpa;
  const _MotivationStrip({required this.cgpa});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final msg = GpaService.getMotivationMessage(cgpa);
    final breakIdx = msg.indexOf(RegExp(r'[.!?]'));
    final lead = breakIdx >= 0 && breakIdx < msg.length - 1 ? msg.substring(0, breakIdx + 1) : msg;
    final rest = breakIdx >= 0 && breakIdx < msg.length - 1 ? msg.substring(breakIdx + 1) : '';

    return UiCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration:
                BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(kRadius)),
            child: Icon(Icons.wb_sunny_outlined, size: 15, color: p.accentInk),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: p.fg, height: 1.45),
                children: [
                  TextSpan(text: lead, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (rest.isNotEmpty) TextSpan(text: rest),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final ValueChanged<int> onSwitchTab;
  const _QuickActions({required this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickCard(
                title: 'GPA calculator',
                subtitle: 'Add subjects & marks',
                icon: 'M4 20V11M10 20V5M16 20v-6M21 20H3',
                onTap: () => onSwitchTab(1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickCard(
                title: 'CGPA tracker',
                subtitle: 'Add semester GPAs',
                icon: 'M2.5 8.5 12 4.5l9.5 4-9.5 4-9.5-4zM6.5 10.7V15c0 1.5 2.5 2.8 5.5 2.8s5.5-1.3 5.5-2.8v-4.3',
                onTap: () => onSwitchTab(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _QuickCard(
                title: 'Saved data',
                subtitle: 'Excel-style sheets',
                icon:
                    'M3 7.5A2.5 2.5 0 0 1 5.5 5h3.2l2 2.6h7.8A2.5 2.5 0 0 1 21 10.1v6.4A2.5 2.5 0 0 1 18.5 19h-13A2.5 2.5 0 0 1 3 16.5v-9z',
                onTap: () => onSwitchTab(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickCard(
                title: 'Settings',
                subtitle: 'Theme & data',
                icon:
                    'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM12 3.4v2M12 18.6v2M20.6 12h-2M5.4 12h-2M18.1 5.9l-1.4 1.4M7.3 16.7l-1.4 1.4M18.1 18.1l-1.4-1.4M7.3 7.3 5.9 5.9',
                onTap: () => onSwitchTab(4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final VoidCallback onTap;

  const _QuickCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration:
                  BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(kRadius)),
              child: Center(
                child: SvgPicture.string(
                  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="$icon"/></svg>',
                  width: 17,
                  height: 17,
                  colorFilter: ColorFilter.mode(p.accentInk, BlendMode.srcIn),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.fg),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w400, color: p.muted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: p.muted),
          ],
        ),
      ),
    );
  }
}