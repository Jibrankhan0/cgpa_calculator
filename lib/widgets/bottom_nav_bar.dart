import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

  static const List<({String icon, String label})> _items = [
    (
      icon: 'M3.5 10.5 12 3.6l8.5 6.9M5.8 9.4V20h12.4V9.4',
      label: 'Home'
    ),
    (
      icon: 'M4 20V11M10 20V5M16 20v-6M21 20H3',
      label: 'GPA'
    ),
    (
      icon: 'M2.5 8.5 12 4.5l9.5 4-9.5 4-9.5-4zM6.5 10.7V15c0 1.5 2.5 2.8 5.5 2.8s5.5-1.3 5.5-2.8v-4.3',
      label: 'CGPA'
    ),
    (
      icon:
          'M3 7.5A2.5 2.5 0 0 1 5.5 5h3.2l2 2.6h7.8A2.5 2.5 0 0 1 21 10.1v6.4A2.5 2.5 0 0 1 18.5 19h-13A2.5 2.5 0 0 1 3 16.5v-9z',
      label: 'Data'
    ),
    (
      icon:
          'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM12 3.4v2M12 18.6v2M20.6 12h-2M5.4 12h-2M18.1 5.9l-1.4 1.4M7.3 16.7l-1.4 1.4M18.1 18.1l-1.4-1.4M7.3 7.3 5.9 5.9',
      label: 'Settings'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.tabbar,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (int i = 0; i < _items.length; i++) ...[
                  if (i > 0) const SizedBox(width: 2),
                  Expanded(
                    child: _NavItem(
                      icon: _items[i].icon,
                      label: _items[i].label,
                      isActive: currentIndex == i,
                      onTap: () => onTap(i),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem(
      {required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final color = isActive ? p.accentInk : p.muted;

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 16,
            height: 3,
            decoration: BoxDecoration(
              color: isActive ? p.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.string(
                  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="$icon"/></svg>',
                  width: 19,
                  height: 19,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: color,
                        letterSpacing: 0.19)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
