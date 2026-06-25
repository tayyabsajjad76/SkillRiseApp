import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/ai_service.dart';

class WeeklyKnowledgeCheckScreen extends StatefulWidget {
  const WeeklyKnowledgeCheckScreen({super.key});
  @override
  State<WeeklyKnowledgeCheckScreen> createState() => _WeeklyKnowledgeCheckState();
}

class _WeeklyKnowledgeCheckState extends State<WeeklyKnowledgeCheckScreen> {
  static const _bg     = Color(0xFF07080F);
  static const _bg2    = Color(0xFF0D1120);
  static const _bg3    = Color(0xFF111827);
  static const _border = Color(0x12FFFFFF);
  static const _primary= Color(0xFF1A56FF);
  static const _accent = Color(0xFF00E5A0);
  static const _muted  = Color(0x6BFFFFFF);
  static const _text   = Color(0xFFF0F4FF);

  final _topicCtrl = TextEditingController();
  int  _currentQ   = 0;
  int  _score      = 0;
  int? _selected;
  bool _answered   = false;
  bool _loading    = false;

  List<_QuizQuestion> _questions  = [];
  List<_PastQuiz>     _pastQuizzes = [];
  List<String>        _userInterests = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = AuthService.getUid();
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    setState(() {
      _userInterests = List<String>.from(data['interests'] ?? []);
      if (_userInterests.isNotEmpty) _topicCtrl.text = _userInterests.first;
    });

    // Load past quizzes
    final snap = await FirebaseFirestore.instance
        .collection('users').doc(uid).collection('quiz_history')
        .orderBy('date', descending: true).limit(4).get();
    setState(() {
      _pastQuizzes = snap.docs.map((d) => _PastQuiz(d['topic'] ?? '', '${d['percent'] ?? 0}%')).toList();
    });

    // Auto generate quiz on first load
    if (_userInterests.isNotEmpty) _generateQuiz(topic: _userInterests.first);
  }

  Future<void> _generateQuiz({String? topic}) async {
    final t = topic ?? _topicCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() { _loading = true; _currentQ = 0; _score = 0; _selected = null; _answered = false; _questions = []; });

    try {
      final prompt = '''
Generate a quiz about: "$t"

Respond ONLY with a JSON array. No explanation, no markdown, no backticks.
[
  {
    "question": "Question text?",
    "options": ["A. option", "B. option", "C. option", "D. option"],
    "correctIndex": 1,
    "topic": "$t"
  }
]
Generate exactly 5 questions, multiple choice with 4 options each. correctIndex is 0-based.
''';
      final raw     = await AIService.ask(prompt);
      final cleaned = AIService.extractJsonArray(raw);
      final List<dynamic> qs = jsonDecode(cleaned);
      setState(() {
        _questions = qs.map((q) => _QuizQuestion(
          question    : q['question'] ?? '',
          options     : List<String>.from(q['options'] ?? []),
          correctIndex: q['correctIndex'] ?? 0,
          topic       : q['topic'] ?? t,
        )).toList();
        _loading = false;
      });
    } catch (e, stack) {
      debugPrint('Quiz ERROR: $e\n$stack');
      setState(() => _loading = false);
    }
  }

  Future<void> _saveQuizResult() async {
    final uid = AuthService.getUid();
    if (uid == null || _questions.isEmpty) return;
    final percent = (_score / _questions.length * 100).toInt();
    await FirebaseFirestore.instance
        .collection('users').doc(uid).collection('quiz_history')
        .add({'topic': _topicCtrl.text.trim(), 'score': _score, 'total': _questions.length, 'percent': percent, 'date': DateTime.now().toIso8601String()});

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final oldXp = ((snap.data()?['xp'] ?? 0) as num).toInt();
      tx.update(userRef, {'xp': oldXp + (percent * 10)});
    });

    setState(() => _pastQuizzes.insert(0, _PastQuiz(_topicCtrl.text.trim(), '$percent%')));
  }

  void _selectOption(int idx) {
    if (_answered || _questions.isEmpty) return;
    setState(() {
      _selected = idx;
      _answered = true;
      if (idx == _questions[_currentQ].correctIndex) _score++;
    });
  }

  void _next() {
    if (_currentQ < _questions.length - 1) {
      setState(() { _currentQ++; _selected = null; _answered = false; });
    } else {
      _saveQuizResult();
    }
  }

  double get _thisQuizPercent => _questions.isEmpty ? 0 : _score / _questions.length;

  @override
  void dispose() { _topicCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return Container(
      color: _bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('QUIZ SYSTEM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: _primary)),
          const SizedBox(height: 8),
          const Text('Weekly Knowledge Check', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _text)),
          const SizedBox(height: 4),
          const Text('AI-generated quiz based on your interests. Generate anytime!', style: TextStyle(color: _muted, fontSize: 13)),
          const SizedBox(height: 20),

          // Interest chips
          if (_userInterests.isNotEmpty) ...[
            Wrap(spacing: 8, runSpacing: 8, children: _userInterests.map((i) => GestureDetector(
              onTap: () { _topicCtrl.text = i; _generateQuiz(topic: i); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _primary.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: _primary.withOpacity(0.3))),
                child: Text(i, style: const TextStyle(color: Color(0xFF6EA8FF), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            )).toList()),
            const SizedBox(height: 14),
          ],

          Row(children: [
            Expanded(
              child: Container(
                height: 46,
                decoration: BoxDecoration(color: _bg2, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
                child: TextField(
                  controller: _topicCtrl,
                  style: const TextStyle(color: _text, fontSize: 13),
                  decoration: const InputDecoration(hintText: 'e.g. React Hooks, Python, CSS Flexbox...', hintStyle: TextStyle(color: _muted, fontSize: 13), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _generateQuiz(),
              child: Container(
                height: 46, padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Text('🤖', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Text('Generate Quiz', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          isWide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 3, child: _buildQuestionCard()),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildRightPanel()),
          ])
              : Column(children: [_buildQuestionCard(), const SizedBox(height: 16), _buildRightPanel()]),
        ]),
      ),
    );
  }

  Widget _buildQuestionCard() {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: _bg2, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
        child: const Center(child: Column(children: [
          CircularProgressIndicator(color: _primary),
          SizedBox(height: 14),
          Text('Generating quiz...', style: TextStyle(color: _muted, fontSize: 13)),
        ])),
      );
    }
    if (_questions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: _bg2, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
        child: const Center(child: Text('Tap a topic chip or enter topic above to generate quiz.', style: TextStyle(color: _muted, fontSize: 13), textAlign: TextAlign.center)),
      );
    }

    final q      = _questions[_currentQ];
    final isLast = _currentQ == _questions.length - 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _bg2, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Question ${_currentQ + 1} of ${_questions.length}', style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _primary.withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: Text(q.topic, style: const TextStyle(color: Color(0xFF6EA8FF), fontSize: 11, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 16),
        Text(q.question, style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w500, height: 1.4)),
        const SizedBox(height: 16),
        ...List.generate(q.options.length, (i) => _buildOption(i, q)),
        const SizedBox(height: 16),
        Row(children: [
          Text('Score: $_score / ${_currentQ + (_answered ? 1 : 0)}', style: const TextStyle(color: _muted, fontSize: 13)),
          const Spacer(),
          if (_answered && !isLast)
            GestureDetector(onTap: _next, child: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8), decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(20)), child: const Text('Next →', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)))),
          if (_answered && isLast)
            GestureDetector(onTap: _next, child: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8), decoration: BoxDecoration(color: _accent.withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: Text('Done! $_score/${_questions.length}', style: const TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w600)))),
        ]),
      ]),
    );
  }

  Widget _buildOption(int i, _QuizQuestion q) {
    Color borderColor = _border;
    Color bgColor     = Colors.transparent;
    Color textColor   = _text;
    if (_answered) {
      if (i == q.correctIndex) { borderColor = _accent; bgColor = _accent.withOpacity(0.08); textColor = _accent; }
      else if (i == _selected)  { borderColor = Colors.redAccent; bgColor = Colors.redAccent.withOpacity(0.08); textColor = Colors.redAccent; }
    } else if (_selected == i)  { borderColor = _primary; bgColor = _primary.withOpacity(0.08); }
    return GestureDetector(
      onTap: () => _selectOption(i),
      child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)), child: Text(q.options[i], style: TextStyle(color: textColor, fontSize: 13))),
    );
  }

  Widget _buildRightPanel() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: _bg2, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Quiz Stats', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          _buildStatRow('This Quiz', '${(_thisQuizPercent * 100).toStringAsFixed(0)}%', isAccent: false, showBar: true, barValue: _thisQuizPercent),
          const SizedBox(height: 8),
          _buildStatRow('All-Time Average', '${_pastQuizzes.isEmpty ? 0 : _pastQuizzes.map((p) => int.tryParse(p.score.replaceAll('%', '')) ?? 0).reduce((a, b) => a + b) ~/ _pastQuizzes.length}%', isAccent: false),
          const SizedBox(height: 8),
          _buildStatRow('Quizzes Completed', '${_pastQuizzes.length}', isAccent: false),
        ]),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: _bg2, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Past Quizzes', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          if (_pastQuizzes.isEmpty) const Text('No quizzes yet. Take one!', style: TextStyle(color: _muted, fontSize: 13)),
          ..._pastQuizzes.take(4).map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Text(p.title, style: const TextStyle(color: _muted, fontSize: 13)),
              const Spacer(),
              Text(p.score, style: const TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          )),
        ]),
      ),
    ]);
  }

  Widget _buildStatRow(String label, String value, {bool isAccent = false, bool showBar = false, double barValue = 0}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
        const Spacer(),
        Text(value, style: TextStyle(color: isAccent ? _accent : _text, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
      if (showBar) ...[
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: barValue, minHeight: 4, backgroundColor: _bg3, valueColor: AlwaysStoppedAnimation<Color>(barValue > 0 ? _accent : _muted))),
      ],
    ]);
  }
}

class _QuizQuestion {
  final String question, topic;
  final List<String> options;
  final int correctIndex;
  const _QuizQuestion({required this.question, required this.topic, required this.options, required this.correctIndex});
}

class _PastQuiz {
  final String title, score;
  const _PastQuiz(this.title, this.score);
}
