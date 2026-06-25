import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({Key? key}) : super(key: key);
  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  bool _loading = true;

  // XP & Level
  int    _xp            = 0;
  int    _level         = 1;
  int    _xpForNext     = 1000;
  String _levelTitle    = 'Beginner';

  // Badges
  bool _badgeFirstProject   = false;
  bool _badgeFirstInterview = false;
  bool _badgeQuizMaster     = false;
  bool _badgeCareerReady    = false;
  bool _badge7DayStreak     = false;
  bool _badgeResumePro      = false;

  // Leaderboard
  List<_LeaderEntry> _leaderboard = [];
  String _currentUid = '';
  int    _myRank     = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final uid = AuthService.getUid();
    if (uid == null) return;
    _currentUid = uid;

    final db = FirebaseFirestore.instance;

    // ── Current user data ──
    final userDoc  = await db.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? {};

    // Quiz history
    final quizSnap = await db
        .collection('users').doc(uid)
        .collection('quiz_history').get();
    final quizDocs = quizSnap.docs.map((d) => d.data()).toList();

    // Completed projects
    final projSnap = await db
        .collection('users').doc(uid)
        .collection('completedProjects').get();
    final projDocs = projSnap.docs.map((d) => d.data()).toList();

    // ── Calculate XP ──
    int xp = 0;
    for (final q in quizDocs) {
      xp += ((q['percent'] ?? 0) as num).toInt() * 10;
    }
    for (final p in projDocs) {
      xp += ((p['score'] ?? 0) as num).toInt() * 20;
    }

    // ── Save XP to Firestore so leaderboard stays in sync ──
    await db.collection('users').doc(uid).update({'xp': xp});

    // ── Level from XP ──
    final levelData = _getLevelData(xp);

    // ── Badge conditions ──
    bool badgeFirstProject   = projDocs.isNotEmpty;
    bool badgeFirstInterview = quizDocs.isNotEmpty;
    bool badgeQuizMaster     = quizDocs.any((q) => ((q['percent'] ?? 0) as num).toInt() >= 90);
    bool badge7DayStreak     = _check7DayStreak(quizDocs);

    // Readiness = quiz avg 40% + project avg 30% + skill 30%
    double quizAvg = 0;
    if (quizDocs.isNotEmpty) {
      quizAvg = quizDocs.fold<int>(0, (s, d) => s + ((d['percent'] ?? 0) as num).toInt()) / quizDocs.length;
    }
    double projAvg = 0;
    if (projDocs.isNotEmpty) {
      projAvg = projDocs.fold<int>(0, (s, d) => s + ((d['score'] ?? 0) as num).toInt()) / projDocs.length;
    }
    final readiness = (quizAvg * 0.4) + (projAvg * 0.3) + (quizAvg * 0.3);
    bool badgeCareerReady = readiness >= 90;
    bool badgeResumePro   = userData['resumeDownloaded'] == true;

// ── Leaderboard: xp field se seedha read ──
    final allUsers = await db.collection('users').get();
    final entries  = <_LeaderEntry>[];

    for (final doc in allUsers.docs) {
      final data   = doc.data();
      final name   = data['name']?.toString() ?? 'User';
      final userXp = ((data['xp'] ?? 0) as num).toInt();
      entries.add(_LeaderEntry(uid: doc.id, name: name, xp: userXp, isYou: doc.id == uid));
    }

    // Sort by XP desc
    entries.sort((a, b) => b.xp.compareTo(a.xp));

    // Find my rank
    int myRank = entries.indexWhere((e) => e.uid == uid) + 1;

    // Top 3 + current user (if not in top 3)
    List<_LeaderEntry> leaderboard = entries.take(3).toList();
    if (myRank > 3) {
      final me = entries.firstWhere((e) => e.uid == uid);
      leaderboard.add(me);
    }

    if (!mounted) return;
    setState(() {
      _xp            = xp;
      _level         = levelData['level'] as int;
      _xpForNext     = levelData['xpForNext'] as int;
      _levelTitle    = levelData['title'] as String;
      _badgeFirstProject   = badgeFirstProject;
      _badgeFirstInterview = badgeFirstInterview;
      _badgeQuizMaster     = badgeQuizMaster;
      _badgeCareerReady    = badgeCareerReady;
      _badge7DayStreak     = badge7DayStreak;
      _badgeResumePro      = badgeResumePro;
      _leaderboard         = leaderboard;
      _myRank              = myRank;
      _loading             = false;
    });
  }

  // ── 7-day streak check ──
  bool _check7DayStreak(List<Map<String, dynamic>> quizDocs) {
    if (quizDocs.length < 7) return false;
    final dates = quizDocs
        .map((d) => DateTime.tryParse(d['date']?.toString() ?? ''))
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort();
    if (dates.length < 7) return false;
    int streak = 1;
    for (int i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        streak++;
        if (streak >= 7) return true;
      } else {
        streak = 1;
      }
    }
    return false;
  }

  // ── Level calculation ──
  Map<String, dynamic> _getLevelData(int xp) {
    const levels = [
      {'min': 0,     'max': 500,   'level': 1, 'title': 'Beginner'},
      {'min': 500,   'max': 1000,  'level': 2, 'title': 'Learner'},
      {'min': 1000,  'max': 2000,  'level': 3, 'title': 'Explorer'},
      {'min': 2000,  'max': 3000,  'level': 4, 'title': 'Builder'},
      {'min': 3000,  'max': 4500,  'level': 5, 'title': 'Maker'},
      {'min': 4500,  'max': 6000,  'level': 6, 'title': 'Achiever'},
      {'min': 6000,  'max': 8000,  'level': 7, 'title': 'Rising Star'},
      {'min': 8000,  'max': 10000, 'level': 8, 'title': 'Expert'},
      {'min': 10000, 'max': 15000, 'level': 9, 'title': 'Master'},
      {'min': 15000, 'max': 99999, 'level': 10,'title': 'Legend'},
    ];
    for (final l in levels.reversed) {
      if (xp >= (l['min'] as int)) {
        return {'level': l['level'], 'xpForNext': l['max'], 'title': l['title']};
      }
    }
    return {'level': 1, 'xpForNext': 500, 'title': 'Beginner'};
  }

  String _rankIcon(int rank) {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '⭐';
  }

  int get _earnedCount => [
    _badgeFirstProject, _badgeFirstInterview, _badgeQuizMaster,
    _badge7DayStreak, _badgeCareerReady, _badgeResumePro,
  ].where((b) => b).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1117),
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BADGES & LEVELS', style: TextStyle(
                color: Color(0xFF3B82F6), fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 1.4)),
            const SizedBox(height: 8),
            const Text('Your Achievements', style: TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
                'Level up, earn badges, and climb the leaderboard. Every milestone is celebrated!',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
            const SizedBox(height: 24),


// WITH:
            Column(children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF161B27), borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Level Progress', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF2D1F00), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF59E0B))),
                      child: Row(children: [
                        Text('Level $_level ', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 13, fontWeight: FontWeight.w600)),
                        const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star, color: Color(0xFFF59E0B), size: 56),
                    const SizedBox(width: 12),
                    Text('$_level', style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.bold)),
                  ])),
                  Center(child: Text(_levelTitle, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14))),
                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('XP to Level ${_level + 1}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                    Text('$_xp / $_xpForNext', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: (_xp / _xpForNext).clamp(0.0, 1.0), backgroundColor: const Color(0xFF2D3748), valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)), minHeight: 10)),
                  const SizedBox(height: 6),
                  Text('$_xp XP earned total', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(10)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('LEADERBOARD', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
                      const SizedBox(height: 12),
                      ..._leaderboard.asMap().entries.map((e) {
                        final rank = e.key + 1;
                        final entry = e.value;
                        final isYou = entry.isYou;
                        final displayRank = isYou && _myRank > 3 ? _myRank : rank;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: isYou ? const Color(0xFF2D2000) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                            child: Row(children: [
                              Text(_rankIcon(displayRank), style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(isYou ? 'You (${entry.name.split(' ').first})' : entry.name, style: TextStyle(color: isYou ? Colors.white : const Color(0xFFD1D5DB), fontSize: 13, fontWeight: isYou ? FontWeight.w600 : FontWeight.normal))),
                              Text(isYou && _myRank > 3 ? '${entry.xp} XP · #$_myRank' : '${entry.xp} XP', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 13, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        );
                      }),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF161B27), borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Earned Badges', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(10)), child: Text('$_earnedCount / 6', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                  ]),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12, mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                    children: [
                      _BadgeCard(icon: '🏆', label: 'First Project', sub: 'Submit first project', earned: _badgeFirstProject),
                      _BadgeCard(icon: '🔥', label: '7-Day Streak', sub: '7 days in a row', earned: _badge7DayStreak),
                      _BadgeCard(icon: '🎤', label: 'First Interview', sub: 'Take a quiz', earned: _badgeFirstInterview),
                      _BadgeCard(icon: '⭐', label: 'Quiz Master', sub: 'Score 90%+ on quiz', earned: _badgeQuizMaster),
                      _BadgeCard(icon: '🚀', label: 'Career Ready', sub: 'Reach 90% readiness', earned: _badgeCareerReady),
                      _BadgeCard(icon: '📄', label: 'Resume Pro', sub: 'Download your CV', earned: _badgeResumePro),
                    ],
                  ),
                ]),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _LeaderEntry {
  final String uid, name;
  final int xp;
  final bool isYou;
  const _LeaderEntry({required this.uid, required this.name, required this.xp, required this.isYou});
}

class _BadgeCard extends StatelessWidget {
  final String icon, label, sub;
  final bool earned;
  const _BadgeCard({required this.icon, required this.label, required this.sub, required this.earned});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: earned ? const Color(0xFF2D3748) : const Color(0xFF1C2333))),
      child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(icon, style: TextStyle(
            fontSize: 18, color: earned ? null : const Color(0xFF374151))),
        const SizedBox(height: 5),
        Text(label, textAlign: TextAlign.center, style: TextStyle(
            color: earned ? Colors.white : const Color(0xFF4B5563),
            fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(sub, textAlign: TextAlign.center, style: TextStyle(
            color: earned ? const Color(0xFF6B7280) : const Color(0xFF374151),
            fontSize: 8)),
      ]));
}