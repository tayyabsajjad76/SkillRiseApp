import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/ai_service.dart';

class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key});
  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  static const _bg2   = Color(0xFF0D1120);
  static const _bg3   = Color(0xFF131929);
  static const _border= Color(0x12FFFFFF);
  static const _primary=Color(0xFF1A56FF);
  static const _accent= Color(0xFF00E5A0);
  static const _warn  = Color(0xFFFF9500);
  static const _purple= Color(0xFFA855F7);
  static const _muted = Color(0x6BFFFFFF);
  static const _text  = Color(0xFFF0F4FF);

  final _topicCtrl  = TextEditingController();
  final _answerCtrl = TextEditingController();

  String _question      = "Enter a topic and click 'Generate Question' to start!";
  String _feedback      = '';
  bool   _hasFeedback   = false;
  bool   _evaluating    = false;
  bool   _generatingQ   = false;

  int _commScore = 0, _techScore = 0, _confScore = 0;
  int _sessionsCompleted = 5;

  int    _totalSessions = 0;
  double _avgTech = 0.0, _avgComm = 0.0;

  // ── AI: Generate Question from topic ──
  Future<void> _generateQuestion() async {
    final topic = _topicCtrl.text.trim();
    if (topic.isEmpty) {
      setState(() => _question = 'Please enter a topic first!');
      return;
    }
    setState(() { _generatingQ = true; });
    try {
      final prompt = '''
You are a technical interviewer. Generate ONE interview question about: $topic

The question should be:
- Clear and specific
- Suitable for a mid-level developer
- Require explanation, not just yes/no

Respond ONLY with the question text. No numbering, no quotes, no extra text.
''';
      final q = await AIService.ask(prompt);
      if (!mounted) return;
      setState(() {
        _question    = q.trim();
        _feedback    = '';
        _hasFeedback = false;
        _answerCtrl.clear();
        _commScore = 0; _techScore = 0; _confScore = 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _question = 'Failed to generate question. Try again.');
    } finally {
      if (mounted) setState(() => _generatingQ = false);
    }
  }

  void _newQuestion() {
    _generateQuestion();
  }

  void _skip() {
    setState(() {
      _feedback    = '';
      _hasFeedback = false;
      _answerCtrl.clear();
      _commScore = 0; _techScore = 0; _confScore = 0;
    });
    if (_topicCtrl.text.trim().isNotEmpty) {
      _generateQuestion();
    }
  }

  // ── AI: Evaluate Answer ──
  Future<void> _submitAnswer() async {
    final answer = _answerCtrl.text.trim();
    if (answer.isEmpty) return;
    if (_question.contains('Enter a topic') || _question.contains('Please enter')) return;

    setState(() { _evaluating = true; _hasFeedback = false; _feedback = ''; });

    try {
      final prompt = '''
You are a strict but fair technical interviewer. Evaluate this interview answer.

Question: $_question
Candidate Answer: $answer

Score on 3 dimensions (integer 0-10 each):
- communication: How clear, structured, and articulate is the answer?
- technical: How technically correct and complete is the answer?
- confidence: How confident and well-thought-out does the answer sound?

Respond ONLY with this exact JSON. No markdown, no backticks, no extra text:
{"communication":7,"technical":8,"confidence":6,"strength":"one sentence","improve":"one sentence","tip":"one sentence"}
''';

      final raw = await AIService.ask(prompt);
      if (!mounted) return;

      // Extract JSON safely
      final start = raw.indexOf('{');
      final end   = raw.lastIndexOf('}') + 1;
      if (start == -1 || end == 0) throw Exception('No JSON');

      final cleaned = raw.substring(start, end);
      final decoded = jsonDecode(cleaned) as Map<String, dynamic>;

      final comm = (decoded['communication'] ?? 0);
      final tech = (decoded['technical']     ?? 0);
      final conf = (decoded['confidence']    ?? 0);

      final commInt = comm is int ? comm : (comm as num).toInt();
      final techInt = tech is int ? tech : (tech as num).toInt();
      final confInt = conf is int ? conf : (conf as num).toInt();

      final strength = decoded['strength']?.toString() ?? '';
      final improve  = decoded['improve']?.toString()  ?? '';
      final tip      = decoded['tip']?.toString()      ?? '';

      _totalSessions++;
      _avgTech = ((_avgTech * (_totalSessions - 1)) + techInt) / _totalSessions;
      _avgComm = ((_avgComm * (_totalSessions - 1)) + commInt) / _totalSessions;

      setState(() {
        _commScore   = commInt;
        _techScore   = techInt;
        _confScore   = confInt;
        _hasFeedback = true;
        _feedback    = '✅ Strength: $strength\n\n⚠️ Improve: $improve\n\n💡 Tip: $tip';
        _sessionsCompleted = (_sessionsCompleted < 8) ? _sessionsCompleted + 1 : 8;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedback    = 'Could not evaluate answer. Try again.';
        _hasFeedback = true;
      });
    } finally {
      if (mounted) setState(() => _evaluating = false);
    }
  }

  @override
  void dispose() { _topicCtrl.dispose(); _answerCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text('AI MOCK INTERVIEW', style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              letterSpacing: 1.2, color: _primary)),
          const SizedBox(height: 6),
          const Text('Practice Interview Sessions', style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w500, color: _text)),
          const SizedBox(height: 4),
          const Text('AI interviewer asks you real questions and gives instant feedback.',
              style: TextStyle(fontSize: 13, color: _muted, height: 1.6)),
          const SizedBox(height: 20),

          // ── Main card ──
          _card(child: Column(children: [
            // Avatar
            Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [_primary, _purple]),
                    border: Border.all(color: _primary.withOpacity(0.4), width: 2)),
                child: const Center(child: Text('🤖', style: TextStyle(fontSize: 28)))),
            const SizedBox(height: 10),
            const Text('SR-AI Interviewer', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: _text)),
            const Text('Technical Round · Full Stack Developer',
                style: TextStyle(fontSize: 12, color: _muted)),
            const SizedBox(height: 20),

            // Topic input + Generate Question
            Row(children: [
              Expanded(child: TextField(
                controller: _topicCtrl,
                style: const TextStyle(color: _text, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. React, Node.js, System Design...',
                  hintStyle: const TextStyle(color: _muted, fontSize: 12),
                  filled: true, fillColor: const Color(0x0DFFFFFF),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primary)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              )),
              const SizedBox(width: 10),
              GestureDetector(
                  onTap: _generatingQ ? null : _generateQuestion,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                        color: _generatingQ ? _primary.withOpacity(0.5) : _primary,
                        borderRadius: BorderRadius.circular(50)),
                    child: _generatingQ
                        ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('🎯 Generate Question', style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  )),
            ]),
            const SizedBox(height: 14),

            // Question box
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0x0AFFFFFF),
                    border: Border(left: BorderSide(color: _primary, width: 3)),
                    borderRadius: BorderRadius.circular(12)),
                child: Text('💬 Q: $_question', style: const TextStyle(
                    fontSize: 13, color: _text, height: 1.65))),
            const SizedBox(height: 14),

            // Answer box
            TextField(
              controller: _answerCtrl,
              maxLines: 5,
              style: const TextStyle(color: _text, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Type your answer here...',
                hintStyle: const TextStyle(color: _muted, fontSize: 12),
                filled: true, fillColor: const Color(0x0DFFFFFF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primary)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 14),

            // Submit + New Question + Skip
            Row(children: [
              _evaluating
                  ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                      color: _accent.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(50)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF07080F))),
                    SizedBox(width: 8),
                    Text('Evaluating...', style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF07080F))),
                  ]))
                  : _btn('▶ Submit Answer', _accent, const Color(0xFF07080F), _submitAnswer),
              // _outlineBtn('🔄 New Question', _newQuestion),
              _outlineBtn('⏭ Skip', _skip),
            ]),
            const SizedBox(height: 16),

            // Score cards
            Row(children: [
              _scoreCard('Communication', _commScore, _accent),
              const SizedBox(width: 10),
              _scoreCard('Technical', _techScore, const Color(0xFF6EA8FF)),
              const SizedBox(width: 10),
              _scoreCard('Confidence', _confScore, _warn),
            ]),
          ])),
          const SizedBox(height: 16),

          // ── AI Feedback (upar) ──
          _card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cardHeader('AI Feedback', null),
              if (_evaluating)
                const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(color: _primary, strokeWidth: 2)))
              else
                Text(
                    _hasFeedback
                        ? _feedback
                        : 'Submit an answer to get AI feedback on your response.',
                    style: const TextStyle(fontSize: 13, color: _muted, height: 1.7)),
            ],
          )),
          const SizedBox(height: 16),

          // ── Session Progress (neeche) ──
          _card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cardHeader('Session Progress', null),
              _progRow('Sessions Completed', '$_sessionsCompleted / 8',
                  _sessionsCompleted / 8, _purple),
              const SizedBox(height: 12),
              _statRow('Avg Technical',
                  _totalSessions > 0 ? '${_avgTech.toStringAsFixed(1)}/10' : '—',
                  const Color(0xFF6EA8FF)),
              _statRow('Avg Communication',
                  _totalSessions > 0 ? '${_avgComm.toStringAsFixed(1)}/10' : '—',
                  _accent),
              _statRow('Confidence Trend', '↑ Improving', _accent),
            ],
          )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _bg2, border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(16)),
      child: child);

  Widget _cardHeader(String title, String? badge) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: _text)),
        if (badge != null) _badgeWidget(badge, _accent),
      ]));

  Widget _btn(String label, Color bg, Color fg, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(50)),
              child: Text(label, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: fg))));

  Widget _outlineBtn(String label, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(50)),
              child: Text(label, style: const TextStyle(fontSize: 12, color: _muted))));

  Widget _scoreCard(String label, int score, Color color) => Expanded(
      child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _bg3, border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Text(score > 0 ? '$score/10' : '—',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: _muted),
                textAlign: TextAlign.center),
          ])));

  Widget _progRow(String label, String val, double progress, Color color) => Column(children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
      Text(val, style: const TextStyle(fontSize: 12, color: _text)),
    ]),
    const SizedBox(height: 6),
    ClipRRect(borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(value: progress, minHeight: 6,
            backgroundColor: const Color(0x12FFFFFF),
            valueColor: AlwaysStoppedAnimation<Color>(color))),
  ]);

  Widget _statRow(String label, String val, Color color) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
        Text(val, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]));

  Widget _badgeWidget(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(50)),
      child: Text(text, style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700, color: color)));
}
