import 'package:flutter/material.dart';
import '../home_theme.dart';

class StatsRow extends StatelessWidget {
  final int roadmapPercent;
  final int pendingTasks;
  final int doneCount;
  final int totalMilestones;
  final double quizAvg;

  const StatsRow({
    super.key,
    required this.roadmapPercent,
    required this.pendingTasks,
    required this.doneCount,
    required this.totalMilestones,
    required this.quizAvg,
  });

  static const _colors = [HT.accent, HT.warn, Color(0xFF6EA8FF), HT.purple];

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatItem(label: 'ROADMAP',       value: '$roadmapPercent%',          sub: '$doneCount/$totalMilestones done',   subIsUp: doneCount > 0),
      _StatItem(label: 'TASKS TODAY',   value: '$pendingTasks 📋',           sub: pendingTasks > 0 ? 'Pending' : 'All done! 🎉', subIsUp: false),
      _StatItem(label: 'QUIZ AVERAGE',  value: '${quizAvg.toInt()}%',        sub: quizAvg > 0 ? 'Keep it up!' : 'No quizzes yet', subIsUp: false),
      _StatItem(label: 'STREAK',        value: '🔥 1',                       sub: 'Day streak',                         subIsUp: false),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      child: Row(
        children: stats.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < stats.length - 1 ? 6 : 0),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: HT.bg2, border: Border.all(color: HT.border), borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.label, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w700, color: HT.muted, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(s.value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _colors[i])),
                const SizedBox(height: 2),
                Text(s.subIsUp ? s.sub : s.sub, style: const TextStyle(fontSize: 8, color: HT.muted)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatItem {
  final String label, value, sub;
  final bool subIsUp;
  const _StatItem({required this.label, required this.value, required this.sub, required this.subIsUp});
}