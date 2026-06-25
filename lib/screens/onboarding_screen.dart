import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/ai_service.dart';
import 'home/home_screen.dart';

class OnboardingFormScreen extends StatefulWidget {
  const OnboardingFormScreen({super.key});
  @override
  State<OnboardingFormScreen> createState() => _OnboardingFormScreenState();
}

class _OnboardingFormScreenState extends State<OnboardingFormScreen> {
  static const _bg     = Color(0xFF07080F);
  static const _bg2    = Color(0xFF0D1120);
  static const _border = Color(0x12FFFFFF);
  static const _primary= Color(0xFF1A56FF);
  static const _accent = Color(0xFF00E5A0);
  static const _muted  = Color(0x6BFFFFFF);
  static const _text   = Color(0xFFF0F4FF);

  final PageController _pageCtrl = PageController();
  int    _page        = 0;
  bool   _saving      = false;
  String _loadingMsg  = 'Saving your profile...';

  String _degree      = '';
  String _goal        = '';
  final List<String> _interests = [];
  String _hoursPerDay = '';

  final _degrees      = ['Computer Science', 'Software Engineering', 'Data Science', 'Business/Management', 'Design', 'Other'];
  final _goals        = ['Get a Job', 'Freelance & Earn', 'Build Projects', 'Learn for Fun', 'Start a Startup'];
  final _allInterests = ['Web Development', 'Mobile Apps', 'AI & Machine Learning', 'Cybersecurity', 'Data Science', 'UI/UX Design', 'DevOps', 'Blockchain'];
  final _hours        = ['< 1 hour', '1-2 hours', '2-4 hours', '4+ hours'];

  // ── AI Generation ─────────────────────────────────────

  Future<void> _generateAndSaveRoadmap(String uid) async {
    setState(() => _loadingMsg = '🗺️ Generating your roadmap...');
    final prompt = '''
You are an expert learning coach. Generate a personalized learning roadmap.

User profile:
- Degree: $_degree
- Goal: $_goal
- Interests: ${_interests.join(', ')}
- Daily learning time: $_hoursPerDay

Respond ONLY with a JSON array. No explanation, no markdown, no backticks.
Format exactly:
[
  {"title": "Step Title", "subtitle": "Brief description under 12 words", "done": false}
]

Generate 8-10 steps from beginner to advanced, specific to their interests and goal. Titles 3-5 words max.
''';
    try {
      final raw     = await AIService.ask(prompt);
      final cleaned = AIService.extractJsonArray(raw);
      final List<dynamic> steps = jsonDecode(cleaned);
      final batch = FirebaseFirestore.instance.batch();
      final colRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('roadmap');
      for (int i = 0; i < steps.length; i++) {
        final s = steps[i] as Map<String, dynamic>;
        batch.set(colRef.doc('step_\$i'), {
          'title'   : s['title'] ?? 'Step \${i + 1}',
          'subtitle': s['subtitle'] ?? '',
          'done'    : false,
          'order'   : i,
        });
      }
      await batch.commit();
    } catch (e, stack) { debugPrint('Roadmap gen ERROR: \$e\n\$stack'); }
  }

  Future<void> _generateAndSaveTasks(String uid) async {
    setState(() => _loadingMsg = '📋 Planning your daily tasks...');
    final prompt = '''
Generate daily learning tasks for a student.

Profile:
- Degree: $_degree
- Goal: $_goal
- Interests: ${_interests.join(', ')}
- Daily time: $_hoursPerDay

Respond ONLY with a JSON array. No explanation, no markdown, no backticks.
Format exactly:
[
  {"title": "Task title", "tag": "ShortTag", "done": false}
]

Generate 4-6 tasks matching their interests and time. Tag max 6 chars (e.g. React, CSS, Node, Python).
''';
    try {
      final raw     = await AIService.ask(prompt);
      final cleaned = AIService.extractJsonArray(raw);
      final List<dynamic> tasks = jsonDecode(cleaned);
      final batch   = FirebaseFirestore.instance.batch();
      final colRef  = FirebaseFirestore.instance.collection('users').doc(uid).collection('tasks');
      for (int i = 0; i < tasks.length; i++) {
        final t = tasks[i] as Map<String, dynamic>;
        batch.set(colRef.doc('task_$i'), {
          'title': t['title'] ?? 'Task ${i + 1}',
          'tag'  : t['tag']   ?? '',
          'done' : false,
          'order': i,
        });
      }
      await batch.commit();
    } catch (e, stack) { debugPrint('Tasks gen ERROR: \$e\n\$stack'); }
  }

  Future<void> _generateAndSaveCourses(String uid) async {
    setState(() => _loadingMsg = '🎓 Finding best courses for you...');
    final prompt = '''
Recommend online courses for a student.

Profile:
- Degree: $_degree
- Goal: $_goal
- Interests: ${_interests.join(', ')}

Respond ONLY with a JSON array. No explanation, no markdown, no backticks.
Format exactly:
[
  {"title": "Course Title", "platform": "Platform Name", "reason": "Why this course fits them"}
]

Generate 3-4 real courses from Udemy, Coursera, freeCodeCamp, YouTube etc. Match their goal and interests.
''';
    try {
      final raw     = await AIService.ask(prompt);
      final cleaned = AIService.extractJsonArray(raw);
      final List<dynamic> courses = jsonDecode(cleaned);
      final batch   = FirebaseFirestore.instance.batch();
      final colRef  = FirebaseFirestore.instance.collection('users').doc(uid).collection('courses');
      for (int i = 0; i < courses.length; i++) {
        final c = courses[i] as Map<String, dynamic>;
        batch.set(colRef.doc('course_$i'), {
          'title'   : c['title']    ?? '',
          'platform': c['platform'] ?? '',
          'reason'  : c['reason']   ?? '',
          'order'   : i,
        });
      }
      await batch.commit();
    } catch (e, stack) { debugPrint('Courses gen ERROR: \$e\n\$stack'); }
  }

  // ── Save ─────────────────────────────────────────────

  Future<void> _save() async {
    setState(() { _saving = true; _loadingMsg = 'Saving your profile...'; });
    try {
      final uid = AuthService.getUid();
      if (uid != null) {
        // Save profile
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'degree'             : _degree,
          'goal'               : _goal,
          'interests'          : _interests,
          'hours_per_day'      : _hoursPerDay,
          'onboarding_complete': true,
        });

        // AI generate all 3 in parallel
        await Future.wait([
          _generateAndSaveRoadmap(uid),
          _generateAndSaveTasks(uid),
          _generateAndSaveCourses(uid),
        ]);
      }
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      setState(() => _saving = false);
    }
  }

  // ── Navigation ────────────────────────────────────────

  void _next() {
    if (_page < 3) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _save();
    }
  }

  bool get _canNext {
    switch (_page) {
      case 0: return _degree.isNotEmpty;
      case 1: return _goal.isNotEmpty;
      case 2: return _interests.isNotEmpty;
      case 3: return _hoursPerDay.isNotEmpty;
      default: return false;
    }
  }

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_saving) return _buildLoadingScreen();
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Step ${_page + 1} of 4', style: const TextStyle(color: _muted, fontSize: 12)),
                Text('${((_page + 1) / 4 * 100).toInt()}%', style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_page + 1) / 4,
                  minHeight: 4,
                  backgroundColor: _border,
                  valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                _buildPage(emoji: '🎓', title: 'What are you studying?',  subtitle: 'We\'ll personalize your roadmap based on your field.', child: _buildChoices(_degrees, _degree, (v) => setState(() => _degree = v))),
                _buildPage(emoji: '🎯', title: 'What\'s your main goal?', subtitle: 'This helps us focus on what matters most for you.',     child: _buildChoices(_goals, _goal, (v) => setState(() => _goal = v))),
                _buildPage(emoji: '💡', title: 'Pick your interests',     subtitle: 'Choose one or more topics you want to master.',         child: _buildMultiChoices()),
                _buildPage(emoji: '⏱',  title: 'Daily learning time?',    subtitle: 'We\'ll plan tasks that fit your schedule.',             child: _buildChoices(_hours, _hoursPerDay, (v) => setState(() => _hoursPerDay = v))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _canNext ? _next : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  disabledBackgroundColor: _primary.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(_page == 3 ? 'Get Started 🚀' : 'Next →',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const CircularProgressIndicator(color: _accent, strokeWidth: 2),
          const SizedBox(height: 24),
          Text(_loadingMsg, style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Setting up your personalized experience...', style: TextStyle(color: _muted, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _buildPage({required String emoji, required String title, required String subtitle, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(color: _text, fontSize: 22, fontWeight: FontWeight.bold, height: 1.3)),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: _muted, fontSize: 13, height: 1.5)),
        const SizedBox(height: 24),
        Expanded(child: SingleChildScrollView(child: child)),
      ]),
    );
  }

  Widget _buildChoices(List<String> options, String selected, void Function(String) onSelect) {
    return Column(
      children: options.map((o) => GestureDetector(
        onTap: () => onSelect(o),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected == o ? _primary.withOpacity(0.15) : _bg2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected == o ? _primary : _border),
          ),
          child: Row(children: [
            Expanded(child: Text(o, style: TextStyle(
              color: selected == o ? _text : _muted, fontSize: 14,
              fontWeight: selected == o ? FontWeight.w600 : FontWeight.normal,
            ))),
            if (selected == o) const Icon(Icons.check_circle_rounded, color: _primary, size: 18),
          ]),
        ),
      )).toList(),
    );
  }

  Widget _buildMultiChoices() {
    return Wrap(
      spacing: 10, runSpacing: 10,
      children: _allInterests.map((o) {
        final sel = _interests.contains(o);
        return GestureDetector(
          onTap: () => setState(() => sel ? _interests.remove(o) : _interests.add(o)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? _accent.withOpacity(0.12) : _bg2,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: sel ? _accent : _border),
            ),
            child: Text(o, style: TextStyle(
              color: sel ? _accent : _muted, fontSize: 13,
              fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
            )),
          ),
        );
      }).toList(),
    );
  }
}