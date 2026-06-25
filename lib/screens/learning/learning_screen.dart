import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'learning_roadmap_screen.dart';
import 'daily_planner_screen.dart';
import 'weekly_knowledge_check_screen.dart';
import 'course_suggestions_screen.dart';
import 'resource_assistant_screen.dart';

class LearningScreen extends StatefulWidget {
  final VoidCallback? onChanged; // ✅ NEW
  const LearningScreen({super.key, this.onChanged});
  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  int _selectedIndex = 0;

  static const _bg2    = Color(0xFF0D1120);
  static const _border = Color(0x12FFFFFF);
  static const _primary= Color(0xFF1A56FF);
  static const _accent = Color(0xFF00E5A0);
  static const _warn   = Color(0xFFFF9500);
  static const _muted  = Color(0x6BFFFFFF);
  static const _text   = Color(0xFFF0F4FF);

  int    _roadmapPercent  = 0;
  int    _pendingTasks    = 0;
  int    _courseCount     = 0;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    final uid = AuthService.getUid();
    if (uid == null) return;

    final roadmapSnap = await FirebaseFirestore.instance.collection('users').doc(uid).collection('roadmap').get();
    final total = roadmapSnap.docs.length;
    final done  = roadmapSnap.docs.where((d) => d['done'] == true).length;

    final tasksSnap = await FirebaseFirestore.instance.collection('users').doc(uid).collection('tasks').get();
    final pending   = tasksSnap.docs.where((d) => d['done'] == false).length;

    final coursesSnap = await FirebaseFirestore.instance.collection('users').doc(uid).collection('courses').get();

    setState(() {
      _roadmapPercent = total == 0 ? 0 : (done / total * 100).toInt();
      _pendingTasks   = pending;
      _courseCount    = coursesSnap.docs.length;
    });

    widget.onChanged?.call(); // ✅ NEW — bubble up to HomeScreen so its stats refresh too
  }

  List<_LearningNavItem> get _navItems => [
    _LearningNavItem(label: 'Learning Roadmap',  icon: Icons.map_outlined,            badge: '$_roadmapPercent%', badgeColor: _accent),
    _LearningNavItem(label: 'Daily Planner',      icon: Icons.calendar_today_outlined, badge: _pendingTasks > 0 ? '$_pendingTasks' : null, badgeColor: _warn),
    _LearningNavItem(label: 'Quiz System',        icon: Icons.help_outline_rounded,    badge: null,  badgeColor: null),
    _LearningNavItem(label: 'Course Suggestions', icon: Icons.school_outlined,         badge: _courseCount > 0 ? '$_courseCount' : null, badgeColor: _primary),
    _LearningNavItem(label: 'Resource Assistant', icon: Icons.menu_book_outlined,      badge: null,  badgeColor: null),
  ];

  // ✅ CHANGED: from `const` field to a getter, so we can pass _loadBadges as onChanged
  List<Widget> get _screens => [
    LearningRoadmapScreen(onChanged: _loadBadges), // ✅ NEW
    const DailyPlannerScreen(),
    const WeeklyKnowledgeCheckScreen(),
    const CourseSuggestionsScreen(),
    const ResourceAssistantScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final item = _navItems[_selectedIndex];
    return Column(
      children: [
        // Top nav scrollable tabs
        Container(
          color: _bg2,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: List.generate(_navItems.length, (i) {
                final n = _navItems[i];
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
                      Icon(n.icon, size: 16, color: selected ? _primary : _muted),
                      const SizedBox(width: 6),
                      Text(n.label, style: TextStyle(
                        color: selected ? _text : _muted,
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      )),
                      if (n.badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: n.badgeColor!.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(n.badge!, style: TextStyle(color: n.badgeColor, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ]),
                  ),
                );
              }),
            ),
          ),
        ),
        Container(height: 1, color: _border),
        // Full screen content below
        Expanded(child: _screens[_selectedIndex]),
      ],
    );
  }
}

class _LearningNavItem {
  final String label;
  final IconData icon;
  final String? badge;
  final Color? badgeColor;
  const _LearningNavItem({required this.label, required this.icon, this.badge, this.badgeColor});
}