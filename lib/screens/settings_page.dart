import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_data.dart';
import '../services/gpa_service.dart';
import '../theme/app_theme.dart';
import '../widgets/staggered_animation.dart';
import '../widgets/ui.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final data = context.watch<AppData>();
    final isDark = data.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StaggeredAnimation(index: 0, child: _ProfileSection(palette: p)),
          StaggeredAnimation(
            index: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader('Appearance'),
                UiCard(
                  padding: EdgeInsets.zero,
                  child: SettingsRow(
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark mode',
                    desc: 'Flips every screen instantly',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isDark ? 'On' : 'Off',
                          style: TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w600, color: p.muted),
                        ),
                        const SizedBox(width: 10),
                        AppSwitch(value: isDark, onChanged: (_) => data.toggleDark()),
                      ],
                    ),
                    onTap: () => data.toggleDark(),
                  ),
                ),
              ],
            ),
          ),
          StaggeredAnimation(
            index: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader('Data'),
                UiCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SettingsRow(
                        icon: Icons.table_chart_outlined,
                        label: 'Grade Reference',
                        desc: 'Marks → letter → GPA table',
                        onTap: () => _openGradeReference(context, isDark),
                      ),
                      Divider(color: p.border),
                      SettingsRow(
                        icon: Icons.refresh,
                        label: 'Reset All Data',
                        desc: 'Clears subjects and semesters',
                        onTap: () => _showResetDialog(context, data),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          StaggeredAnimation(
            index: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader('About'),
                UiCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SettingsRow(
                        icon: Icons.info_outline,
                        label: 'About this app',
                        desc: 'v1.3.0 · Jibran Khan Dehpal',
                        onTap: () => _openAbout(context, isDark),
                      ),
                      Divider(color: p.border),
                      SettingsRow(
                        icon: Icons.folder_outlined,
                        label: 'Storage',
                        desc: 'Saved on this device only',
                        trailing: Text(
                          'Local',
                          style:
                              TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, AppData data) {
    final p = Palette.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset everything?'),
        content: const Text('This will clear all data permanently including your name and avatar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              data.resetAll();
              Navigator.pop(ctx);
            },
            child: Text('Reset', style: TextStyle(color: p.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _openGradeReference(BuildContext context, bool isDark) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _GradeReferencePage(isDark: isDark)),
    );
  }

  void _openAbout(BuildContext context, bool isDark) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _AboutPage(isDark: isDark)),
    );
  }
}

// ─── Profile Section ──────────────────────────────────────────────

class _ProfileSection extends StatelessWidget {
  final Palette palette;
  const _ProfileSection({required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final data = context.watch<AppData>();

    return UiCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showAvatarPicker(context, data),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: p.accentSoft,
                shape: BoxShape.circle,
                border: Border.all(color: p.accent, width: 2),
              ),
              child: ClipOval(child: Image.asset(data.userAvatar, fit: BoxFit.cover)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: GestureDetector(
              onTap: () => _showNameEditor(context, data),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.userName.isEmpty ? 'Student' : data.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.fg),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap the name to rename · max 20 characters',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: p.muted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SquareIconButton(
            icon: Icons.edit_outlined,
            onTap: () => _showNameEditor(context, data),
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker(BuildContext context, AppData data) {
    final p = Palette.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: p.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Choose Avatar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.fg)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: AppData.avatars.length,
              itemBuilder: (context, index) {
                final avatar = AppData.avatars[index];
                final isSelected = avatar == data.userAvatar;
                return GestureDetector(
                  onTap: () {
                    data.setUserAvatar(avatar);
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: isSelected ? p.accentSoft : p.surface,
                      borderRadius: BorderRadius.circular(kRadius),
                      border: Border.all(
                        color: isSelected ? p.accent : p.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(avatar, fit: BoxFit.contain),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNameEditor(BuildContext context, AppData data) {
    final p = palette;
    final controller = TextEditingController(text: data.userName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change Name',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.fg)),
        content: TextField(
          controller: controller,
          maxLength: 20,
          autofocus: true,
          decoration: fieldInput(context, hint: 'Enter your name...'),
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: p.fg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: p.muted)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) data.setUserName(name);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ─── Grade Reference Page ─────────────────────────────────────────

class _GradeReferencePage extends StatelessWidget {
  final bool isDark;
  const _GradeReferencePage({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final p = isDark ? Palette.dark : Palette.light;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: SquareIconButton(
            icon: Icons.arrow_back_ios_new,
            size: 40,
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: Text('Grade Reference',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.fg)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader('Marks → GPA'),
            UiCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Text('MARKS',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: p.muted,
                                  letterSpacing: 0.06)),
                        ),
                        SizedBox(
                          width: 54,
                          child: Text('GRADE',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: p.muted,
                                  letterSpacing: 0.06)),
                        ),
                        const Spacer(),
                        Text('GPA',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: p.muted,
                                letterSpacing: 0.06)),
                      ],
                    ),
                  ),
                  ...GpaService.gradeMap.map(
                    (g) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: p.border)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: Text('${g.minMarks}+',
                                style: numStyle(13.5, FontWeight.w700, p.fg)),
                          ),
                          Container(
                            width: 44,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(g.colorValue),
                              borderRadius: BorderRadius.circular(kRadius),
                            ),
                            child: Center(
                              child: Text(g.letter,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                            ),
                          ),
                          const Spacer(),
                          Text(g.gpa.toStringAsFixed(1),
                              style: numStyle(13.5, FontWeight.w700, p.fg)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const SectionHeader('How GPA is calculated'),
            UiCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _formulaRow(
                    p,
                    '1 · Subject percentage',
                    'Non-lab marks are out of 100 · Lab marks are out of 50, then × 2\n'
                        'Data page: (mid + final + section) ÷ 100 × 100, with lab ÷ 150 × 100',
                  ),
                  _formulaRow(
                    p,
                    '2 · Grade points',
                    'From the table above — 85+ = 4.0 · 75+ = 3.3 · 70+ = 3.0 · 50+ = 1.0',
                  ),
                  _formulaRow(
                    p,
                    '3 · Semester GPA',
                    'Σ (grade points × credits) ÷ Σ credits · lab weight = 1',
                  ),
                  _formulaRow(
                    p,
                    '4 · CGPA',
                    'Σ semester GPAs ÷ number of entered semesters',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'Subjects without marks and semesters without a GPA are skipped.',
                      style: TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w500, color: p.muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.accentSoft,
                borderRadius: BorderRadius.circular(kRadius),
                border: Border.all(color: p.accent.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(Icons.science_outlined, size: 18, color: p.accentInk),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lab Subject',
                            style:
                                TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.fg)),
                        Text('Marks out of 50, credits fixed at 1',
                            style:
                                TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: p.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formulaRow(Palette p, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.fg)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: p.muted)),
        ],
      ),
    );
  }
}

// ─── About Page ───────────────────────────────────────────────────

class _AboutPage extends StatelessWidget {
  final bool isDark;
  const _AboutPage({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final p = isDark ? Palette.dark : Palette.light;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: SquareIconButton(
            icon: Icons.arrow_back_ios_new,
            size: 40,
            onTap: () => Navigator.pop(context),
          ),
        ),
        title:
            Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.fg)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : p.accentSoft,
                  borderRadius: BorderRadius.circular(kRadius),
                  border: Border.all(color: p.border),
                ),
                child: SvgPicture.asset(
                  'assets/logo for calculatot.svg',
                  width: 52,
                  height: 52,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text('MCKRU CGPA Calculator',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.fg)),
            ),
            const SizedBox(height: 6),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: p.accentSoft,
                  borderRadius: BorderRadius.circular(kRadius),
                ),
                child: Text('v1.3.0',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.accentInk)),
              ),
            ),
            const SectionHeader('Developer'),
            UiCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: ClipOval(child: Image.asset('assets/developer_avatar.png', fit: BoxFit.cover)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Jibran Khan Dehpal',
                                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.fg)),
                            Text('Flutter Developer',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: p.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(color: p.border),
                  SettingsRow(
                    icon: Icons.open_in_new,
                    label: 'Connect MCKRU',
                    desc: 'Get it on Google Play',
                    onTap: () => launchUrl(
                      Uri.parse(
                          'https://play.google.com/store/apps/details?id=com.mckru.connect&pcampaignid=web_share'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader('App info'),
            UiCard(
              child: Column(
                children: [
                  _InfoRow(label: 'Version', value: '1.3.0', palette: p),
                  _InfoRow(label: 'Platform', value: 'Android & iOS', palette: p),
                  _InfoRow(label: 'Framework', value: 'Flutter', palette: p),
                  _InfoRow(label: 'Storage', value: 'Local (SharedPreferences)', palette: p),
                ],
              ),
            ),
            const SectionHeader('Features'),
            UiCard(
              child: Column(
                children: [
                  _FeatureItem(icon: Icons.show_chart_outlined, text: 'GPA & CGPA Calculation', palette: p),
                  _FeatureItem(icon: Icons.science_outlined, text: 'Lab Subject Support', palette: p),
                  _FeatureItem(icon: Icons.save_outlined, text: 'Local Data Storage', palette: p),
                  _FeatureItem(icon: Icons.dark_mode_outlined, text: 'Dark Mode', palette: p),
                  _FeatureItem(icon: Icons.person_outline, text: 'Customizable Profile', palette: p),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Palette palette;

  const _InfoRow({required this.label, required this.value, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: p.muted)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: p.field,
              borderRadius: BorderRadius.circular(kRadius),
              border: Border.all(color: p.border),
            ),
            child: Text(value, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.fg)),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Palette palette;

  const _FeatureItem({required this.icon, required this.text, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: p.accentInk),
          const SizedBox(width: 10),
          Expanded(
            child:
                Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: p.fg)),
          ),
        ],
      ),
    );
  }
}
