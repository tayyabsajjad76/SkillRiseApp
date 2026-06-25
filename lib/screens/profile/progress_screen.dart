import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  static const _bg     = Color(0xFF07080F);
  static const _bg2    = Color(0xFF0D1120);
  static const _border = Color(0x12FFFFFF);
  static const _primary= Color(0xFF1A56FF);
  static const _muted  = Color(0x6BFFFFFF);
  static const _text   = Color(0xFFF0F4FF);

  static const _barColors = [
    Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF0EA5E9),
    Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEF4444),
  ];

  bool _loading = true;

  double        _overall   = 0;
  int           _tasksDone = 0;
  int           _tasksTotal= 0;
  int           _quizDone  = 0;
  int           _quizTotal = 0;
  double        _avgScore  = 0;
  List<_Course> _courses   = [];
  List<bool>    _streak    = List.filled(7, false);

  @override
  void initState() { super.initState(); _logToday(); _load(); }

  Future<void> _load() async {
    final uid = AuthService.getUid();
    if (uid == null) { setState(() => _loading = false); return; }

    final db = FirebaseFirestore.instance;

    final results = await Future.wait([
      db.collection('users').doc(uid).collection('courses').orderBy('order').get(),
      db.collection('users').doc(uid).collection('tasks').get(),
      db.collection('users').doc(uid).collection('quiz_history').get(),
      db.collection('users').doc(uid).collection('roadmap').get(),
    ]);

    // ── Roadmap → overall % ──
    final roadmapSnap = results[3] as QuerySnapshot;
    final roadmapTotal = roadmapSnap.docs.length;
    final roadmapDone  = roadmapSnap.docs.where((d) => (d.data() as Map)['done'] == true).length;
    final overall = roadmapTotal == 0 ? 0.0 : roadmapDone / roadmapTotal;

    // ── Courses (title/platform from Firestore, progress from roadmap) ──
    final coursesSnap = results[0] as QuerySnapshot;
    final courses = coursesSnap.docs.asMap().entries.map((e) {
      final data = e.value.data() as Map<String, dynamic>;
      return _Course(
        title   : data['title']    ?? e.value.id,
        platform: data['platform'] ?? '',
        progress: overall,          // use roadmap-based progress for all courses
        color   : _barColors[e.key % _barColors.length],
      );
    }).toList();

    // ── Tasks ──
    final tasksSnap = results[1] as QuerySnapshot;
    final tasksDone = tasksSnap.docs
        .where((d) => (d.data() as Map)['done'] == true)
        .length;

    // ── Quiz history ──
    final quizSnap  = results[2] as QuerySnapshot;
    final quizDocs  = quizSnap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
    final quizDone  = quizDocs.where((d) => ((d['score'] as num?) ?? 0) > 0).length;
    final percents  = quizDocs.map((d) => (d['percent'] as num?)?.toDouble() ?? 0.0).toList();
    final avgScore  = percents.isEmpty ? 0.0
        : percents.reduce((a, b) => a + b) / percents.length;

    // ── Activity / streak ──
    final activityDoc = await db.collection('users').doc(uid).get();
    final rawDates = ((activityDoc.data()?['activityDates']) as List<dynamic>? ?? [])
        .map((e) => e.toString()).toSet();

    final today = DateTime.now();
    final streak = List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final key = '${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}';
      return rawDates.contains(key);
    });

    setState(() {
      _courses    = courses;
      _overall    = overall;
      _tasksDone  = tasksDone;
      _tasksTotal = tasksSnap.docs.length;
      _quizDone   = quizDone;
      _quizTotal  = quizSnap.docs.length;
      _avgScore   = avgScore;
      _streak     = streak;
      _loading    = false;
    });
  }

  Future<void> _logToday() async {
    final uid = AuthService.getUid();
    if (uid == null) return;
    final today = DateTime.now();
    final key = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    await FirebaseFirestore.instance
        .collection('users').doc(uid)
        .set({'activityDates': FieldValue.arrayUnion([key])},
        SetOptions(merge: true));
  }

  List<String> _buildDayLabels() {
    const names = ['M','T','W','T','F','S','S'];
    final today = DateTime.now();
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return names[day.weekday - 1];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A56FF)));

    final dayLabels = _buildDayLabels();

    return Container(
      color: _bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('PROGRESS REPORT',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 1.4, color: _primary)),
          const SizedBox(height: 8),
          const Text('Your Progress',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _text)),
          const SizedBox(height: 24),

          // ── Stat cards ──
          Row(children: [
            _statCard('${(_overall * 100).toInt()}%',  'Overall',  const Color(0xFF4F46E5)),
            const SizedBox(width: 12),
            _statCard('$_tasksDone/$_tasksTotal',       'Tasks',    const Color(0xFF10B981)),
            const SizedBox(width: 12),
            _statCard('${_avgScore.toInt()}%',          'Avg Score',const Color(0xFF7C3AED)),
          ]),
          const SizedBox(height: 20),

          // ── Quiz count row ──
          if (_quizTotal > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _bg2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quizzes Completed',
                      style: TextStyle(color: _text, fontWeight: FontWeight.w600)),
                  Text('$_quizDone / $_quizTotal',
                      style: const TextStyle(color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ],

          // ── Course bars ──
          if (_courses.isEmpty)
            Center(child: Text('No courses yet.',
                style: TextStyle(color: _muted)))
          else
            ..._courses.map((c) => _bar(
              '${c.title}${c.platform.isNotEmpty ? " · ${c.platform}" : ""}',
              c.progress, c.color,
            )),

          const SizedBox(height: 20),

          // ── Weekly streak ──
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: [
              const Text('Weekly Streak 🔥',
                  style: TextStyle(color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (i) {
                  final done  = _streak[i];
                  final label = dayLabels[i];
                  return Column(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: done ? Colors.white : Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text(
                        done ? '✓' : label,
                        style: TextStyle(
                            color: done ? const Color(0xFF4F46E5) : Colors.white,
                            fontSize: 12, fontWeight: FontWeight.bold),
                      )),
                    ),
                    const SizedBox(height: 4),
                    Text(label, style: const TextStyle(
                        color: Colors.white70, fontSize: 11)),
                  ]);
                }),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _statCard(String val, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _bg2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border)),
      child: Column(children: [
        Text(val,   style: TextStyle(fontSize: 18,
            fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
      ]),
    ),
  );

  Widget _bar(String title, double value, Color color) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(title, style: const TextStyle(
            fontWeight: FontWeight.w600, color: _text),
            overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Text('${(value * 100).toInt()}%',
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: value, minHeight: 8,
          backgroundColor: Colors.white.withOpacity(0.05),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    ]),
  );
}

class _Course {
  final String title;
  final String platform;
  final double progress;
  final Color  color;
  const _Course({required this.title, required this.platform,
    required this.progress, required this.color});
}