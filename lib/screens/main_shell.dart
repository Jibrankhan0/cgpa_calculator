import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_data.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/ui.dart';
import 'home_page.dart';
import 'gpa_page.dart';
import 'cgpa_page.dart';
import 'storage_page.dart';
import 'settings_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);

    final pages = [
      HomePage(onSwitchTab: _switchTab),
      const GpaPage(),
      const CgpaPage(),
      const StoragePage(),
      const SettingsPage(),
    ];

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          _TopBar(index: _currentIndex),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: Alignment.topLeft,
                fit: StackFit.passthrough,
                children: <Widget>[
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              ),
              child: pages[_currentIndex],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int index;
  const _TopBar({required this.index});

  static const List<String> _titles = [
    '',
    'GPA Calculator',
    'CGPA Tracker',
    'Saved Data',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final data = context.watch<AppData>();

    final themeIcon = data.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined;

    final List<Widget> actions = switch (index) {
      0 || 4 => [SquareIconButton(icon: themeIcon, onTap: data.toggleDark)],
      _ => <Widget>[],
    };

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: Row(
          children: [
            if (index == 0) ...[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: p.accentSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: Color.alphaBlend(p.accent.withValues(alpha: 0.26), p.border)),
                ),
                child: ClipOval(child: Image.asset(data.userAvatar, fit: BoxFit.cover)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.userName.trim().isEmpty
                          ? 'Welcome back!'
                          : 'Welcome back, ${data.userName.trim()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.fg),
                    ),
                    Text(
                      'CGPA & GPA tracker',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: p.muted),
                    ),
                  ],
                ),
              ),
            ] else
              Expanded(
                child: Text(
                  _titles[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.fg, letterSpacing: -0.4),
                ),
              ),
            ...actions,
          ],
        ),
      ),
    );
  }
}
