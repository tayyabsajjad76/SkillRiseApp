import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _loading = true;

  // Stats
  double _quizAvg      = 0;
  double _skillScore   = 0;
  double _projectsAvg  = 0;
  double _readiness    = 0;

  // Weekly scores (last 6 quizzes)
  List<_BarData> _weeklyBars = [];

  // Skill mastery (topic → avg percent)
  List<_SkillData> _skills = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final uid = AuthService.getUid();
    if (uid == null) return;

    final db = FirebaseFirestore.instance;

    // ── Quiz History ──
    final quizSnap = await db
        .collection('users').doc(uid)
        .collection('quiz_history')
        .orderBy('date', descending: false)
        .get();

    final quizDocs = quizSnap.docs.map((d) => d.data()).toList();

    // Quiz average
    double quizAvg = 0;
    if (quizDocs.isNotEmpty) {
      final total = quizDocs.fold<int>(0, (s, d) => s + ((d['percent'] ?? 0) as num).toInt());
      quizAvg = total / quizDocs.length;
    }

    // Weekly bars — last 6 quizzes
    final last6 = quizDocs.length > 6 ? quizDocs.sublist(quizDocs.length - 6) : quizDocs;
    final bars = last6.asMap().entries.map((e) {
      final pct = ((e.value['percent'] ?? 0) as num).toInt();
      final colors = [
        const Color(0xFF3B82F6),
        const Color(0xFF3B82F6),
        const Color(0xFF10B981),
        const Color(0xFF10B981),
        const Color(0xFFA855F7),
        const Color(0xFFA855F7),
      ];
      return _BarData('Wk ${e.key + 1}', pct, colors[e.key % colors.length]);
    }).toList();

    // Skill mastery — group by topic, avg percent
    final Map<String, List<int>> topicScores = {};
    for (final d in quizDocs) {
      final topic   = (d['topic'] ?? 'General').toString();
      final percent = ((d['percent'] ?? 0) as num).toInt();
      topicScores.putIfAbsent(topic, () => []).add(percent);
    }
    final skills = topicScores.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      Color color;
      if (avg >= 80) color = const Color(0xFF10B981);
      else if (avg >= 60) color = const Color(0xFF3B82F6);
      else if (avg >= 40) color = const Color(0xFFF59E0B);
      else color = const Color(0xFFEF4444);
      return _SkillData(e.key, avg / 100, color, '${avg.toInt()}%');
    }).toList();

    // Skill score = avg of all skill masteries
    double skillScore = 0;
    if (skills.isNotEmpty) {
      skillScore = skills.fold(0.0, (s, e) => s + e.percent * 100) / skills.length;
    }

    // ── Completed Projects ──
    final projSnap = await db
        .collection('users').doc(uid)
        .collection('completedProjects')
        .get();
    double projectsAvg = 0;
    if (projSnap.docs.isNotEmpty) {
      final total = projSnap.docs.fold<int>(0, (s, d) => s + ((d.data()['score'] ?? 0) as num).toInt());
      projectsAvg = total / projSnap.docs.length;
    }

    // ── Readiness = weighted average ──
    // quiz 40% + skill 30% + project 30%
    final readiness = (quizAvg * 0.4) + (skillScore * 0.3) + (projectsAvg * 0.3);

    if (!mounted) return;
    setState(() {
      _quizAvg     = quizAvg;
      _skillScore  = skillScore;
      _projectsAvg = projectsAvg;
      _readiness   = readiness;
      _weeklyBars  = bars;
      _skills      = skills;
      _loading     = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1117),
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text('ANALYTICS', style: TextStyle(
                color: Color(0xFF3B82F6), fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 1.4)),
            const SizedBox(height: 8),
            const Text('Your Learning Insights', style: TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
                _readiness >= 80
                    ? "Track performance across quizzes, projects, and skills. AI predicts you'll be job-ready soon! 🎉"
                    : "Track performance across quizzes, projects, and skills. Keep going — you're making progress!",
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
            const SizedBox(height: 24),

            // Stat Cards
            Column(children: [
              Row(children: [
                _StatCard(label: 'QUIZ AVERAGE', value: '${_quizAvg.toInt()}%', valueColor: const Color(0xFF3B82F6), trend: _quizAvg >= 70 ? '↑ Good performance' : 'Keep practicing!', trendColor: _quizAvg >= 70 ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                const SizedBox(width: 12),
                _StatCard(label: 'SKILL SCORE', value: '${_skillScore.toInt()}%', valueColor: const Color(0xFF10B981), trend: _skillScore >= 70 ? '↑ Strong skills' : 'Take more quizzes!', trendColor: _skillScore >= 70 ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _StatCard(label: 'PROJECTS AVG', value: _projectsAvg > 0 ? '${_projectsAvg.toInt()}/100' : '—', valueColor: const Color(0xFFF59E0B), trend: _projectsAvg > 0 ? 'Average grade' : 'No projects yet', trendColor: const Color(0xFF6B7280)),
                const SizedBox(width: 12),
                _StatCard(label: 'READINESS', value: '${_readiness.toInt()}%', valueColor: const Color(0xFFA855F7), trend: _readiness >= 80 ? '↑ Job ready!' : '↑ Keep going!', trendColor: const Color(0xFF10B981)),
              ]),
            ]),
            const SizedBox(height: 24),

            // Charts Row
            Column(children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF161B27), borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Text('📊 ', style: TextStyle(fontSize: 16)),
                    Text('Weekly Quiz Scores', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 24),
                  _weeklyBars.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Text('No quiz data yet.\nTake a quiz to see scores!', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13), textAlign: TextAlign.center)))
                      : _WeeklyBarChart(bars: _weeklyBars),
                ]),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF161B27), borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Text('🎯 ', style: TextStyle(fontSize: 16)),
                    Text('Skill Mastery', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 20),
                  if (_skills.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Text('No skills tracked yet.\nTake quizzes on different topics!', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13), textAlign: TextAlign.center)))
                  else
                    ..._skills.map((s) => Padding(padding: const EdgeInsets.only(bottom: 14), child: _SkillBar(label: s.topic, percent: s.percent, color: s.color, display: s.display))),
                ]),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Data Models ──
class _BarData {
  final String label;
  final int value;
  final Color color;
  const _BarData(this.label, this.value, this.color);
}

class _SkillData {
  final String topic, display;
  final double percent;
  final Color color;
  const _SkillData(this.topic, this.percent, this.color, this.display);
}

// ── Widgets ──
class _StatCard extends StatelessWidget {
  final String label, value, trend;
  final Color valueColor, trendColor;
  const _StatCard({
    required this.label, required this.value, required this.valueColor,
    required this.trend, required this.trendColor});

  @override
  Widget build(BuildContext context) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFF161B27), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(
              color: Color(0xFF6B7280), fontSize: 11,
              fontWeight: FontWeight.w600, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(
              color: valueColor, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(trend, style: TextStyle(color: trendColor, fontSize: 12)),
        ]),
      ));
}

class _WeeklyBarChart extends StatelessWidget {
  final List<_BarData> bars;
  const _WeeklyBarChart({required this.bars});

  @override
  Widget build(BuildContext context) => SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: bars.map((b) {
          final h = (b.value / 100) * 120.0;
          return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text('${b.value}%', style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Container(width: 36, height: h,
                decoration: BoxDecoration(color: b.color, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 6),
            Text(b.label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
          ]);
        }).toList(),
      ));
}

class _SkillBar extends StatelessWidget {
  final String label, display;
  final double percent;
  final Color color;
  const _SkillBar({required this.label, required this.percent,
    required this.color, required this.display});

  @override
  Widget build(BuildContext context) => Column(children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(child: Text(label, style: const TextStyle(
          color: Color(0xFFD1D5DB), fontSize: 13),
          overflow: TextOverflow.ellipsis)),
      Text(display, style: TextStyle(
          color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
    const SizedBox(height: 6),
    ClipRRect(borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
            value: percent, backgroundColor: const Color(0xFF2D3748),
            valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 8)),
  ]);
}




