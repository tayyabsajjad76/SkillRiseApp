import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/ai_service.dart';

class LearningRoadmapScreen extends StatefulWidget {
  final VoidCallback? onChanged; // ✅ NEW
  const LearningRoadmapScreen({super.key, this.onChanged});
  @override
  State<LearningRoadmapScreen> createState() => _LearningRoadmapScreenState();
}

class _LearningRoadmapScreenState extends State<LearningRoadmapScreen> {
  static const _bg     = Color(0xFF07080F);
  static const _bg2    = Color(0xFF0D1120);
  static const _border = Color(0x12FFFFFF);
  static const _primary= Color(0xFF1A56FF);
  static const _accent = Color(0xFF00E5A0);
  static const _orange = Color(0xFFFF9500);
  static const _muted  = Color(0x6BFFFFFF);
  static const _text   = Color(0xFFF0F4FF);

  List<Map<String, dynamic>> _milestones = [];
  Map<String, dynamic> _userProfile      = {};
  bool _loading    = true;
  bool _generating = false;
  String? _error;

  double _quizAvg     = 0;
  double _projectsAvg = 0;
  double _readiness   = 0;

  final TextEditingController _topicCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final uid = AuthService.getUid();
    if (uid == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    _userProfile  = userDoc.data() ?? {};
    final snap    = await FirebaseFirestore.instance
        .collection('users').doc(uid).collection('roadmap')
        .orderBy('order').get();
    final interests = (_userProfile['interests'] as List?)?.join(', ') ?? '';
    _topicCtrl.text = interests;

    // Quiz history → quiz average + skill score (same logic as AnalyticsScreen)
    final quizSnap = await FirebaseFirestore.instance.collection('users').doc(uid).collection('quiz_history').get();
    final quizDocs = quizSnap.docs.map((d) => d.data()).toList();
    double quizAvg = 0;
    if (quizDocs.isNotEmpty) {
      final totalPct = quizDocs.fold<int>(0, (s, d) => s + ((d['percent'] ?? 0) as num).toInt());
      quizAvg = totalPct / quizDocs.length;
    }
    final Map<String, List<int>> topicScores = {};
    for (final d in quizDocs) {
      final topic   = (d['topic'] ?? 'General').toString();
      final percent = ((d['percent'] ?? 0) as num).toInt();
      topicScores.putIfAbsent(topic, () => []).add(percent);
    }
    double skillScore = 0;
    if (topicScores.isNotEmpty) {
      final avgs = topicScores.values.map((v) => v.reduce((a, b) => a + b) / v.length).toList();
      skillScore = avgs.reduce((a, b) => a + b) / avgs.length;
    }

    // Completed projects → projects average (same logic as AnalyticsScreen)
    final projSnap = await FirebaseFirestore.instance.collection('users').doc(uid).collection('completedProjects').get();
    double projectsAvg = 0;
    if (projSnap.docs.isNotEmpty) {
      final totalScore = projSnap.docs.fold<int>(0, (s, d) => s + ((d.data()['score'] ?? 0) as num).toInt());
      projectsAvg = totalScore / projSnap.docs.length;
    }

    // Readiness = quiz 40% + skill 30% + projects 30%
    final readiness = (quizAvg * 0.4) + (skillScore * 0.3) + (projectsAvg * 0.3);

    setState(() {
      _milestones  = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      _quizAvg     = quizAvg;
      _projectsAvg = projectsAvg;
      _readiness   = readiness;
      _loading     = false;
    });
  }

  Future<void> _toggleMilestone(Map<String, dynamic> m) async {
    final uid = AuthService.getUid();
    if (uid == null) return;
    final newDone = !(m['done'] as bool);
    await FirebaseFirestore.instance
        .collection('users').doc(uid).collection('roadmap').doc(m['id'])
        .update({'done': newDone});
    setState(() => m['done'] = newDone);
    widget.onChanged?.call(); // ✅ NEW — tells parent (Learning/Home) to refresh instantly
  }

  Future<void> _regenerate() async {
    final uid   = AuthService.getUid();
    if (uid == null) return;
    final topic = _topicCtrl.text.trim();
    if (topic.isEmpty) return;
    setState(() { _generating = true; _error = null; });
    try {
      final goal   = _userProfile['goal'] ?? '';
      final degree = _userProfile['degree'] ?? '';
      final prompt = '''
Generate a learning roadmap for:
- Degree: $degree
- Goal: $goal
- Topic: $topic

Respond ONLY with a JSON array. No explanation, no markdown, no backticks.
[{"title": "Step Title", "subtitle": "Brief description under 12 words", "done": false}]
Generate 8-10 steps beginner to advanced. Titles 3-5 words max.
''';
      final raw     = await AIService.ask(prompt);
      final cleaned = AIService.extractJsonArray(raw);
      final List<dynamic> steps = jsonDecode(cleaned);

      final old = await FirebaseFirestore.instance.collection('users').doc(uid).collection('roadmap').get();
      for (final d in old.docs) await d.reference.delete();

      final batch  = FirebaseFirestore.instance.batch();
      final colRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('roadmap');
      for (int i = 0; i < steps.length; i++) {
        final s = steps[i] as Map<String, dynamic>;
        batch.set(colRef.doc('step_$i'), {
          'title'   : s['title'] ?? '',
          'subtitle': s['subtitle'] ?? '',
          'done'    : false,
          'order'   : i,
        });
      }
      await batch.commit();
      await _loadData();
      widget.onChanged?.call(); // ✅ NEW — refresh parent after regenerate too
    } catch (e, stack) {
      debugPrint('Roadmap ERROR: $e\n$stack');
      setState(() { _error = 'Failed to generate. Try again.'; _generating = false; });
    }
  }

  int get _doneCount => _milestones.where((m) => m['done'] == true).length;

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5A0)));

    final interests = (_userProfile['interests'] as List?)?.join(', ') ?? 'your interests';
    final goal      = _userProfile['goal'] ?? 'your goal';

    return Container(
      color: _bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('LEARNING PATH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: _primary)),
          const SizedBox(height: 8),
          const Text('Your Personalized Roadmap', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _text)),
          const SizedBox(height: 4),
          Text('AI-built for $goal · $interests', style: const TextStyle(color: _muted, fontSize: 13)),
          const SizedBox(height: 20),

          // Topic input + regenerate
          Row(children: [
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              decoration: BoxDecoration(color: _bg2, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
              child: TextField(
                controller: _topicCtrl,
                style: const TextStyle(color: _text, fontSize: 13),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter any topic (e.g. Python, UI/UX, Blockchain...)',
                  hintStyle: TextStyle(color: _muted, fontSize: 13),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
              ),
            )),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _generating ? null : _regenerate,
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: _generating ? _primary.withOpacity(0.5) : _primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _generating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('🤖', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(_generating ? 'Generating...' : 'Regenerate',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              ),
            ),
          ]),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],
          const SizedBox(height: 24),

          // ── Milestones ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _bg2, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Milestones', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _primary.withOpacity(0.3)),
                  ),
                  child: Text('$_doneCount / ${_milestones.length} Done',
                      style: const TextStyle(color: Color(0xFF6EA8FF), fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 16),
              if (_milestones.isEmpty)
                const Center(child: Text('No roadmap yet. Click Regenerate.', style: TextStyle(color: _muted, fontSize: 13))),
              ..._milestones.asMap().entries.map((e) {
                final i      = e.key;
                final m      = e.value;
                final done   = m['done'] == true;
                final isLast = i == _milestones.length - 1;
                return IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 36, child: Column(children: [
                      GestureDetector(
                        onTap: () => _toggleMilestone(m),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: done ? _accent.withOpacity(0.15) : _primary.withOpacity(0.12),
                            border: Border.all(color: done ? _accent : _border, width: 1.5),
                          ),
                          child: Center(child: done
                              ? const Icon(Icons.check, color: _accent, size: 15)
                              : Text('${i+1}', style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700))),
                        ),
                      ),
                      if (!isLast)
                        Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 2), color: done ? _accent.withOpacity(0.3) : _border)),
                    ])),
                    const SizedBox(width: 12),
                    Expanded(child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(m['title'] ?? '', style: TextStyle(color: done ? _text : _muted, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(m['subtitle'] ?? '', style: const TextStyle(color: _muted, fontSize: 12)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: done ? _accent.withOpacity(0.12) : _primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(done ? 'Completed' : 'Upcoming',
                              style: TextStyle(color: done ? _accent : _muted, fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    )),
                  ]),
                );
              }),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Overall Progress ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _bg2, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Overall Progress', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _progressRow('Roadmap', _milestones.isEmpty ? 0 : _doneCount / _milestones.length,
                  '${_milestones.isEmpty ? 0 : (_doneCount / _milestones.length * 100).toInt()}%', _accent),
              const SizedBox(height: 12),
              _progressRow('Quizzes Passed', _quizAvg / 100, '${_quizAvg.toInt()}%', _accent),
              const SizedBox(height: 12),
              _progressRow('Projects Done',  _projectsAvg / 100, '${_projectsAvg.toInt()}%', _orange),
              const SizedBox(height: 12),
              _progressRow('Interview Ready', _readiness / 100, '${_readiness.toInt()}%', const Color(0xFFA855F7)),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Skill Badges ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _bg2, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Skill Badges', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ...(_userProfile['interests'] as List? ?? []).map((interest) {
                  final earned = _doneCount > 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: earned ? _accent.withOpacity(0.1) : Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: earned ? _accent.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
                    ),
                    child: Text('$interest ${earned ? '✓' : '✗'}',
                        style: TextStyle(color: earned ? _accent : Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                  );
                }),
              ]),
            ]),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _progressRow(String label, double value, String display, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
        Text(display, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: value, minHeight: 7,
          backgroundColor: const Color(0x12FFFFFF),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    ]);
  }
}