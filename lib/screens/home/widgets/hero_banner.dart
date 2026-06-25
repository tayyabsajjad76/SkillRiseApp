import 'package:flutter/material.dart';
import '../home_theme.dart';

class HeroBanner extends StatelessWidget {
  final String userName;
  final String goal;
  final List<String> interests;
  final int pendingTasks;
  final bool isNewUser;
  final VoidCallback onTasksTap;
  final VoidCallback onInterviewTap;

  const HeroBanner({
    super.key,
    required this.userName,
    required this.goal,
    required this.interests,
    required this.pendingTasks,
    required this.isNewUser,
    required this.onTasksTap,
    required this.onInterviewTap,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _title {
    if (isNewUser) return 'Welcome to SkillRise, $userName! 🎉';
    return '$_greeting, $userName! 👋';
  }

  String get _subtitle {
    if (isNewUser) return 'Your AI-powered learning journey starts now. Complete your roadmap to get started!';
    if (goal.isEmpty) return '$pendingTasks tasks pending today. Keep pushing! 🚀';
    switch (goal) {
      case 'Get a Job':
        return '$pendingTasks tasks pending today. You\'re on track to land your dream job! 💼';
      case 'Freelance & Earn':
        return '$pendingTasks tasks pending today. Build skills that earn you money on Fiverr & Upwork! 💰';
      case 'Build Projects':
        return '$pendingTasks tasks pending today. Every task gets you closer to shipping your project! 🔨';
      case 'Start a Startup':
        return '$pendingTasks tasks pending today. Future founders learn every day! 🚀';
      default:
        return '$pendingTasks tasks pending today. Keep learning and growing! ⚡';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1535), Color(0xFF0A2060)],
        ),
        border: Border.all(color: const Color(0x331A56FF)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(children: [
        Positioned(
          right: -40, top: -60,
          child: Container(
            width: 220, height: 220,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [Color(0x261A56FF), Colors.transparent]),
            ),
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: HT.textColor)),
          const SizedBox(height: 6),
          Text(_subtitle, style: const TextStyle(fontSize: 13, color: HT.muted, height: 1.5)),
          if (interests.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 6, children: interests.take(3).map((i) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: HT.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(i, style: const TextStyle(color: Color(0xFF6EA8FF), fontSize: 10, fontWeight: FontWeight.w600)),
            )).toList()),
          ],
          const SizedBox(height: 20),
          Row(children: [
            Flexible(
              child: _HeroBtn(label: "Today's Tasks", icon: Icons.calendar_today_rounded, filled: true, onTap: onTasksTap),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: _HeroBtn(label: 'Mock Interview', icon: Icons.mic_rounded, filled: false, onTap: onInterviewTap),
            ),
          ]),
        ]),
      ]),
    );
  }
}

class _HeroBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _HeroBtn({required this.label, required this.icon, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? HT.accent : Colors.transparent,
          border: filled ? null : Border.all(color: HT.border),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: filled ? const Color(0xFF07080F) : HT.muted),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: filled ? const Color(0xFF07080F) : HT.muted)),
        ]),
      ),
    );
  }
}