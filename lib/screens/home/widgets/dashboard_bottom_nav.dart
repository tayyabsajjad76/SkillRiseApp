import 'package:flutter/material.dart';
import '../home_theme.dart';

class DashboardBottomNav extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const DashboardBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(icon: Icons.home_outlined,          activeIcon: Icons.home_rounded,            label: 'Home'),
    _NavItem(icon: Icons.menu_book_outlined,      activeIcon: Icons.menu_book_rounded,       label: 'Learning'),
    _NavItem(icon: Icons.person_outline_rounded,  activeIcon: Icons.person_rounded,          label: 'Profile'),
    _NavItem(icon: Icons.work_outline_rounded,    activeIcon: Icons.work_rounded,            label: 'Career'),
    _NavItem(icon: Icons.insights_outlined,       activeIcon: Icons.insights_rounded,        label: 'Insights'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: HT.bg2,
        border: Border(top: BorderSide(color: HT.border)),
      ),
      child: Row(
        children: _items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final active = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0x261A56FF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      active ? item.activeIcon : item.icon,
                      size: 20,
                      color: active ? HT.primary : HT.muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: active ? HT.primary : HT.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}