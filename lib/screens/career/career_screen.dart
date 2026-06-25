import 'package:flutter/material.dart';
import 'interview_screen.dart';
import 'projects_screen.dart';
import 'resume_screen.dart';

class CareerScreen extends StatefulWidget {
  const CareerScreen({super.key});
  @override
  State<CareerScreen> createState() => _CareerScreenState();
}

class _CareerScreenState extends State<CareerScreen> {
  int _selectedIndex = 0;

  static const _bg    = Color(0xFF07080F);
  static const _bg2   = Color(0xFF0D1120);
  static const _border= Color(0x12FFFFFF);
  static const _primary= Color(0xFF1A56FF);
  static const _muted  = Color(0x6BFFFFFF);
  static const _text   = Color(0xFFF0F4FF);

  final List<_CareerNavItem> _navItems = const [
    _CareerNavItem(label: 'AI Mock Interview', icon: Icons.mic_none_rounded,   badge: null),
    _CareerNavItem(label: 'Projects',          icon: Icons.folder_open_rounded, badge: null),
    _CareerNavItem(label: 'Resume Builder',    icon: Icons.description_outlined,badge: null),
  ];

  final List<Widget> _screens = const [
    InterviewScreen(),
    ProjectsScreen(),
    ResumeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: _bg2,
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
                    color: selected ? _primary.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? _primary : _border),
                  ),
                  child: Row(children: [
                    Icon(item.icon, size: 16, color: selected ? _primary : _muted),
                    const SizedBox(width: 6),
                    Text(item.label, style: TextStyle(color: selected ? _text : _muted, fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
      Container(height: 1, color: _border),
      Expanded(child: Container(color: _bg, child: _screens[_selectedIndex])),
    ]);
  }
}

class _CareerNavItem {
  final String label;
  final IconData icon;
  final int? badge;
  const _CareerNavItem(
      {required this.label, required this.icon, this.badge});
}