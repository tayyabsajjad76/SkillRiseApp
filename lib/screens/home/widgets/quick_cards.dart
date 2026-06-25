import 'package:flutter/material.dart';
import '../home_theme.dart';

class QuickCardsGrid extends StatelessWidget {
  final int roadmapPercent;
  final List<String> interests;
  final int pendingTasks;
  final void Function(String page) onNavigate;

  const QuickCardsGrid({
    super.key,
    required this.roadmapPercent,
    required this.interests,
    required this.pendingTasks,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final topic = interests.isNotEmpty ? interests.first : 'Programming';
    final cards = [
      _QCard(
        emoji   : '🗺️',
        title   : 'Learning Roadmap',
        subtitle: '$roadmapPercent% complete — keep going!',
        progress: roadmapPercent / 100,
        page    : 'roadmap',
      ),
      _QCard(
        emoji    : '📝',
        title    : 'Weekly Quiz',
        subtitle : '$topic · AI-generated questions',
        badgeText: '$pendingTasks tasks pending',
        badgeType: 0,
        page     : 'quiz',
      ),
      _QCard(
        emoji   : '📚',
        title   : 'Continue Learning',
        subtitle: interests.isNotEmpty ? interests.join(' · ') : 'Start your learning journey',
        progress: roadmapPercent / 100,
        page    : 'learning',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: cards.map((c) => _QuickCard(card: c, onTap: () => onNavigate(c.page))).toList(),
      ),
    );
  }
}

class _QCard {
  final String emoji, title, subtitle, page;
  final double? progress;
  final String? badgeText;
  final int badgeType;
  const _QCard({required this.emoji, required this.title, required this.subtitle, required this.page, this.progress, this.badgeText, this.badgeType = 0});
}

class _QuickCard extends StatelessWidget {
  final _QCard card;
  final VoidCallback onTap;
  const _QuickCard({required this.card, required this.onTap});

  static const _badgeColors = [HT.warn, Color(0xFF6EA8FF), HT.accent];
  static const _badgeBg     = [Color(0x1FFF9500), Color(0x1F1A56FF), Color(0x1F00E5A0)];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: HT.bg2, border: Border.all(color: HT.border), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: const Color(0x0AFFFFFF), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(card.emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(card.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: HT.textColor)),
            const SizedBox(height: 4),
            Text(card.subtitle, style: const TextStyle(fontSize: 12, color: HT.muted, height: 1.5)),
            const SizedBox(height: 10),
            if (card.progress != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: card.progress,
                  minHeight: 6,
                  backgroundColor: const Color(0x12FFFFFF),
                  valueColor: AlwaysStoppedAnimation<Color>(card.progress! > 0.5 ? HT.accent : HT.warn),
                ),
              )
            else if (card.badgeText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _badgeBg[card.badgeType],
                  border: Border.all(color: _badgeColors[card.badgeType].withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(card.badgeText!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _badgeColors[card.badgeType])),
              ),
          ])),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: HT.muted, size: 20),
        ]),
      ),
    );
  }
}