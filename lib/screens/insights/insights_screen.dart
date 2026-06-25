import 'package:flutter/material.dart';
import 'analytics_screen.dart';
import 'badges_screen.dart';
import 'ai_mentor_screen.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({Key? key}) : super(key: key);

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  int _selectedIndex = 0;

  final List<_InsightsNavItem> _navItems = [
    _InsightsNavItem(
      label: 'Analytics',
      icon: Icons.show_chart,
      badge: null,
    ),
    _InsightsNavItem(
      label: 'Badges & Levels',
      icon: Icons.emoji_events_outlined,
      badge: 4,
    ),
    _InsightsNavItem(
      label: 'AI Mentor Chat',
      icon: Icons.smart_toy_outlined,
      badge: null,
    ),
  ];

  final List<Widget> _screens = const [
    AnalyticsScreen(),
    BadgesScreen(),
    AiMentorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: const Color(0xFF0D1117),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final selected = _selectedIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF1C2333) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? Colors.white24 : const Color(0xFF1C2333)),
                  ),
                  child: Row(children: [
                    Icon(item.icon, size: 16, color: selected ? Colors.white : const Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Text(item.label, style: TextStyle(color: selected ? Colors.white : const Color(0xFF6B7280), fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                    if (item.badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(10)),
                        child: Text('${item.badge}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
      Container(height: 1, color: const Color(0xFF1C2333)),
      Expanded(child: _screens[_selectedIndex]),
    ]);
  }
}

class _InsightsNavItem {
  final String label;
  final IconData icon;
  final int? badge;
  const _InsightsNavItem(
      {required this.label, required this.icon, this.badge});
}