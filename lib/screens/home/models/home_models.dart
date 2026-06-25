class StatItem {
  final String label;
  final String value;
  final String sub;
  final bool subIsUp;
  final int colorType;

  const StatItem({
    required this.label,
    required this.value,
    required this.sub,
    this.subIsUp = false,
    required this.colorType,
  });
}

class QuickCard {
  final String emoji;
  final String title;
  final String subtitle;
  final double? progress;
  final String? badgeText;
  final int badgeType;
  final String page;

  const QuickCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.progress,
    this.badgeText,
    this.badgeType = 0,
    required this.page,
  });
}

const homeStats = [
  StatItem(label: 'READINESS SCORE', value: '87%',  sub: '↑5% this week',  subIsUp: true,  colorType: 0),
  StatItem(label: 'DAY STREAK',      value: '14 🔥', sub: 'Keep it up!',                    colorType: 1),
  StatItem(label: 'QUIZ AVERAGE',    value: '78%',   sub: '↑12% last week', subIsUp: true,  colorType: 2),
  StatItem(label: 'PROJECTS DONE',   value: '12',    sub: 'Next due in 3 days',              colorType: 3),
];

const quickCards = [
  QuickCard(
    emoji: '🗺️', title: 'Learning Roadmap',
    subtitle: '68% complete — 3 milestones left',
    progress: 0.68, page: 'roadmap',
  ),
  QuickCard(
    emoji: '📝', title: 'Weekly Quiz',
    subtitle: 'JavaScript async/await · 15 questions',
    badgeText: 'Due in 2 days', badgeType: 0, page: 'quiz',
  ),
  QuickCard(
    emoji: '🔨', title: 'Active Project',
    subtitle: 'REST API with Node.js — 40% done',
    progress: 0.40, page: 'projects',
  ),
];
