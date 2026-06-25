import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/ai_service.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});
  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  static const _bg2    = Color(0xFF0D1120);
  static const _border = Color(0x12FFFFFF);
  static const _primary= Color(0xFF1A56FF);
  static const _accent = Color(0xFF00E5A0);
  static const _warn   = Color(0xFFFF9500);
  static const _muted  = Color(0x6BFFFFFF);
  static const _text   = Color(0xFFF0F4FF);

  // ── User ──
  Map<String, dynamic> _userProfile = {};

  // ── Current Project (Firebase se) ──
  String _projectTitle    = '';
  String _projectDesc     = '';
  double _currentProgress = 0.0;
  int    _dueInDays       = 7;
  bool   _loadingProject  = true;
  bool   _generatingProject = false;

  // ── Requirements ──
  List<String> _requirements      = [];
  String       _requirementsSummary = '';
  bool         _loadingReqs       = false;

  // ── Hints ──
  List<String> _hints        = [];
  bool         _loadingHints = false;
  int          _hintIndex    = 0;

  // ── Completed Projects (Firebase se) ──
  List<Map<String, dynamic>> _completed = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ── Load everything ──
  Future<void> _loadAll() async {
    final uid = AuthService.getUid();
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!mounted) return;

    final data = doc.data() ?? {};
    _userProfile    = data;

    // Current project from Firebase
    final cp = data['currentProject'] as Map<String, dynamic>?;
    if (cp != null && (cp['title'] ?? '').toString().isNotEmpty) {
      setState(() {
        _projectTitle    = cp['title']    ?? '';
        _projectDesc     = cp['desc']     ?? '';
        _currentProgress = (cp['progress'] ?? 0.0).toDouble();
        _dueInDays       = (cp['dueInDays'] ?? 7).toInt();
        _loadingProject  = false;
      });
    } else {
      // No project → AI generate karo
      await _generateNewProject();
    }

    // Completed projects
    final snap = await FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('completedProjects')
        .orderBy('week')
        .get();
    if (!mounted) return;
    setState(() {
      _completed = snap.docs.map((d) => d.data()).toList();
    });
  }

  String get _userContext {
    final interests = (_userProfile['interests'] as List?)?.join(', ') ?? '';
    final goal      = _userProfile['goal']   ?? '';
    final degree    = _userProfile['degree'] ?? '';
    return 'Degree: $degree | Goal: $goal | Interests: $interests';
  }

  // ── AI: Generate new project ──
  Future<void> _generateNewProject() async {
    setState(() { _generatingProject = true; _loadingProject = true; });
    try {
      final prompt = '''
You are a senior developer. Generate a project for a student based on their profile.

Student profile: $_userContext

IMPORTANT: Project must match student interests EXACTLY.
If interests include Mobile Apps → Flutter/Dart project
If interests include Web Dev → React/Node project
If interests include AI/ML → Python AI project
If goal is Freelance → include client-ready deliverable

Respond ONLY with a JSON object. No explanation, no markdown, no backticks.
{
  "title": "Project title (5-8 words)",
  "desc": "One sentence description of what to build (max 20 words)",
  "dueInDays": 7
}
''';
      final raw     = await AIService.ask(prompt);
      final cleaned = AIService.extractJsonObject(raw);
      final decoded = jsonDecode(cleaned);
      if (!mounted) return;

      if (decoded is Map) {
        final title = decoded['title']?.toString() ?? 'Build a Project';
        final desc  = decoded['desc']?.toString()  ?? 'A project tailored to your interests.';
        final days  = (decoded['dueInDays'] ?? 7).toInt();

        // Save to Firebase
        final uid = AuthService.getUid();
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'currentProject': {
              'title'    : title,
              'desc'     : desc,
              'dueInDays': days,
              'progress' : 0.0,
            }
          });
        }

        setState(() {
          _projectTitle    = title;
          _projectDesc     = desc;
          _dueInDays       = days;
          _currentProgress = 0.0;
          _requirements    = [];
          _hints           = [];
          _hintIndex       = 0;
        });
      }
    } catch (e) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() { _generatingProject = false; _loadingProject = false; });
    }
  }

  // ── AI: Fetch Requirements ──
  Future<void> _fetchRequirements() async {
    setState(() { _loadingReqs = true; _requirements = []; _requirementsSummary = ''; });
    try {
      final prompt = '''
You are a senior developer. Generate project requirements for a student.

Student profile: $_userContext
Project: $_projectTitle
Description: $_projectDesc

IMPORTANT: Requirements must be STRICTLY tailored to student interests and goal.
If interests include Mobile Apps, use Flutter/Dart — NOT generic Node.js or web dev.
If goal is Freelance, include client-ready and deployment steps.
Match everything to: $_userContext

Respond ONLY with a JSON object. No explanation, no markdown, no backticks.
{
  "summary": "One short sentence describing the project (max 8 words, no tech tags)",
  "requirements": ["Requirement 1", "Requirement 2"]
}
Generate 6-8 clear, actionable requirements.
''';
      final raw     = await AIService.ask(prompt);
      final cleaned = AIService.extractJsonObject(raw);
      final decoded = jsonDecode(cleaned);
      if (!mounted) return;
      if (decoded is Map) {
        final list = decoded['requirements'] as List? ?? [];
        setState(() {
          _requirementsSummary = decoded['summary']?.toString() ?? '';
          _requirements = list.map((e) => e.toString()).toList();
        });
      } else {
        setState(() => _requirements = ['Could not parse. Tap Regenerate.']);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _requirements = ['Failed to load. Try again.']);
    } finally {
      if (mounted) setState(() => _loadingReqs = false);
    }
  }

  // ── AI: Fetch Hints ──
  Future<void> _fetchHints() async {
    setState(() { _loadingHints = true; _hints = []; _hintIndex = 0; });
    try {
      final prompt = '''
You are a senior developer helping a student. Generate progressive hints.

Student profile: $_userContext
Project: $_projectTitle
Description: $_projectDesc

Respond ONLY with a JSON array of 5 hint strings. No explanation, no markdown, no backticks.
Each hint practical, specific, progressively more detailed. Start easy, end implementation-level.
''';
      final raw     = await AIService.ask(prompt);
      final cleaned = AIService.extractJsonArray(raw);
      final decoded = jsonDecode(cleaned);
      if (!mounted) return;
      if (decoded is List) {
        setState(() => _hints = decoded.map((e) => e.toString()).toList());
      } else {
        setState(() => _hints = ['Could not parse hint. Try again.']);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _hints = ['Failed to load hint. Try again.']);
    } finally {
      if (mounted) setState(() => _loadingHints = false);
    }
  }

  // ── Show Requirements Dialog ──
  void _showRequirements() async {
    if (_requirements.isEmpty) await _fetchRequirements();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF0D1120),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Project Requirements', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _text)),
                GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: _muted, size: 20)),
              ]),
              const SizedBox(height: 6),
              Text(
                _requirementsSummary.isNotEmpty ? _requirementsSummary : _projectTitle,
                style: const TextStyle(fontSize: 12, color: _primary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              if (_loadingReqs)
                const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(color: _primary, strokeWidth: 2)))
              else
                ..._requirements.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                        width: 22, height: 22,
                        margin: const EdgeInsets.only(right: 10, top: 1),
                        decoration: BoxDecoration(
                            color: _primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6)),
                        child: Center(child: Text('${e.key + 1}', style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700, color: _primary)))),
                    Expanded(child: Text(e.value, style: const TextStyle(
                        fontSize: 13, color: _text, height: 1.5))),
                  ]),
                )),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await _fetchRequirements();
                      if (mounted) _showRequirements();
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                            border: Border.all(color: _primary.withOpacity(0.4)),
                            borderRadius: BorderRadius.circular(50)),
                        child: const Center(child: Text('🔄 Regenerate', style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: _primary)))))),
                const SizedBox(width: 10),
                Expanded(child: GestureDetector(
                    onTap: () async {
                      // Got it → save requirements to Firebase
                      final uid = AuthService.getUid();
                      if (uid != null && _requirements.isNotEmpty) {
                        await FirebaseFirestore.instance
                            .collection('users').doc(uid)
                            .update({'currentProject.requirements': _requirements});
                      }
                      if (mounted) Navigator.pop(context);
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                            color: _primary, borderRadius: BorderRadius.circular(50)),
                        child: const Center(child: Text('Got it!', style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)))))),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ── Show Hint Dialog ──
  void _showHint() async {
    if (_hints.isEmpty) await _fetchHints();
    if (!mounted) return;

    final hint         = _hints[_hintIndex % _hints.length];
    final displayIndex = _hintIndex + 1;
    setState(() => _hintIndex++);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF0D1120),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('💡 Hint', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _warn)),
                GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: _muted, size: 20)),
              ]),
              const SizedBox(height: 16),
              if (_loadingHints)
                const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(color: _warn, strokeWidth: 2)))
              else
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: _warn.withOpacity(0.08),
                        border: Border.all(color: _warn.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(hint, style: const TextStyle(
                        fontSize: 13, color: _text, height: 1.6))),
              const SizedBox(height: 8),
              Text('Hint $displayIndex of ${_hints.length}',
                  style: const TextStyle(fontSize: 11, color: _muted)),
              const SizedBox(height: 16),
              GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                          color: _warn.withOpacity(0.15),
                          border: Border.all(color: _warn.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(50)),
                      child: const Center(child: Text('Thanks!', style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: _warn))))),
            ],
          ),
        ),
      ),
    );
  }

  // ── Submit Repo → AI Score ──
  Future<void> _openGitHub() async {
    final repoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF0D1120),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Submit Your Repo', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _text)),
              const SizedBox(height: 6),
              const Text('Paste your GitHub repo URL. AI will evaluate and score your project.',
                  style: TextStyle(fontSize: 12, color: _muted, height: 1.5)),
              const SizedBox(height: 16),
              TextField(
                controller: repoCtrl,
                autofocus: true,
                style: const TextStyle(color: _text, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'https://github.com/username/repo',
                  hintStyle: const TextStyle(color: _muted, fontSize: 12),
                  filled: true, fillColor: const Color(0x0DFFFFFF),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _accent)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final repoUrl = repoCtrl.text.trim();
                  if (repoUrl.isEmpty) return;
                  Navigator.pop(context);
                  await _evaluateAndSubmit(repoUrl);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      color: _accent, borderRadius: BorderRadius.circular(50)),
                  child: const Center(child: Text('Submit & Get Score →', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF07080F)))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _evaluating = false;

  Future<void> _evaluateAndSubmit(String repoUrl) async {
    setState(() => _evaluating = true);

    try {
      final reqText = _requirements.isNotEmpty
          ? _requirements.join('\n')
          : 'General project requirements';

      final prompt = '''
You are a senior developer evaluating a student project submission.

Project: $_projectTitle
Description: $_projectDesc
Requirements:
$reqText

Student submitted repo: $repoUrl

Based on the repo URL and project requirements, evaluate the project and give a realistic score.
Consider: project complexity, alignment with requirements, and the student profile.

Respond ONLY with a JSON object. No explanation, no markdown, no backticks.
{
  "score": 75,
  "feedback": "One or two sentences of constructive feedback."
}
''';

      final raw     = await AIService.ask(prompt);
      final cleaned = AIService.extractJsonObject(raw);
      final decoded = jsonDecode(cleaned);

      final score    = (decoded['score'] ?? 70).toInt();
      final feedback = decoded['feedback']?.toString() ?? 'Good work!';

      final uid = AuthService.getUid();
      if (uid != null) {
        final now  = DateTime.now();
        final week = 'Week ${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';

        // Save to completedProjects
        await FirebaseFirestore.instance
            .collection('users').doc(uid)
            .collection('completedProjects')
            .add({
          'title'   : _projectTitle,
          'desc'    : _projectDesc,
          'repoUrl' : repoUrl,
          'score'   : score,
          'feedback': feedback,
          'week'    : week,
        });

        // Set progress to 100% and clear currentProject
        await FirebaseFirestore.instance
            .collection('users').doc(uid)
            .update({'currentProject': {}});
      }

      if (!mounted) return;

      // Show score dialog
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: const Color(0xFF0D1120),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(score >= 80 ? '🏆' : score >= 60 ? '👍' : '💪',
                    style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('$score / 100',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: _accent)),
                const SizedBox(height: 8),
                Text(feedback,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: _muted, height: 1.5)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _loadAll(); // reload with new project
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                        color: _primary, borderRadius: BorderRadius.circular(50)),
                    child: const Center(child: Text('Get Next Project →', style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evaluation failed. Try again.'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _evaluating = false);
    }
  }

  Future<void> _launchGitHub(String username) async {
    final uri = Uri.parse('https://github.com/$username');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text('PROJECT WORKSHOP', style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              letterSpacing: 1.2, color: _primary)),
          const SizedBox(height: 6),
          const Text('Real-World Projects', style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w500, color: _text)),
          const SizedBox(height: 4),
          const Text(
              'AI-generated bi-weekly projects with auto-evaluation. Building your portfolio one project at a time.',
              style: TextStyle(fontSize: 13, color: _muted, height: 1.6)),
          const SizedBox(height: 20),

          // ── Current Project ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: const Color(0x0FFF9500),
                border: Border.all(color: const Color(0x33FF9500)),
                borderRadius: BorderRadius.circular(16)),
            child: _loadingProject
                ? Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(children: [
                const CircularProgressIndicator(color: _warn, strokeWidth: 2),
                const SizedBox(height: 12),
                Text(
                  _generatingProject ? 'AI generating your project...' : 'Loading project...',
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ]),
            ))
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Flexible(child: Text('CURRENT PROJECT — DUE IN $_dueInDays DAYS',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: _warn, letterSpacing: 1.0))),
                  const SizedBox(width: 8),
                  _badge('${(_currentProgress * 100).toInt()}%', _warn),
                ]),
                const SizedBox(height: 8),
                Text(_projectTitle,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _text)),
                const SizedBox(height: 8),
                Text(_projectDesc,
                    style: const TextStyle(fontSize: 13, color: _muted, height: 1.6)),
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Progress', style: TextStyle(fontSize: 12, color: _muted)),
                  Text('${(_currentProgress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 12, color: _text)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                        value: _currentProgress, minHeight: 7,
                        backgroundColor: const Color(0x12FFFFFF),
                        valueColor: const AlwaysStoppedAnimation<Color>(_warn))),
                const SizedBox(height: 16),
                Column(children: [
                  Row(children: [
                    Expanded(child: _actionBtn('</> View Requirements', _primary, Colors.white, onTap: _showRequirements)),
                    const SizedBox(width: 8),
                    Expanded(child: _actionBtn('💡 Get Hint', Colors.transparent, _muted, outlined: true, onTap: _showHint)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _actionBtn(_evaluating ? '⏳ Evaluating...' : '⬆ Submit Repo', _accent, const Color(0xFF07080F), onTap: _evaluating ? null : _openGitHub)),
                    const SizedBox(width: 8),
                    Expanded(child: _actionBtn(
                      _generatingProject ? '⏳ Generating...' : '🔄 New Project',
                      Colors.transparent, _warn, outlined: true,
                      onTap: _generatingProject ? null : _generateNewProject,
                    )),
                  ]),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Completed Projects ──
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Completed Projects', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: _text)),
            _badge('${_completed.length} Done', _accent),
          ]),
          const SizedBox(height: 14),

          if (_completed.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text('No completed projects yet.', style: const TextStyle(color: _muted, fontSize: 13)),
            ))
          else
            ..._completed.map((p) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: _bg2, border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p['title']?.toString() ?? '', style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: _text)),
                    const SizedBox(height: 6),
                    Row(children: [
                      _badge('Completed', _accent),
                      const SizedBox(width: 8),
                      Text(p['week']?.toString() ?? '',
                          style: const TextStyle(fontSize: 11, color: _muted)),
                    ]),
                  ])),
                  Text('${p['score'] ?? 0}/100', style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: _accent)),
                ]),
                const SizedBox(height: 10),
                Text(p['desc']?.toString() ?? '', style: const TextStyle(
                    fontSize: 12, color: _muted, height: 1.6)),
              ]),
            )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(50)),
      child: Text(text, style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700, color: color)));

  Widget _actionBtn(String label, Color bg, Color fg,
      {bool outlined = false, VoidCallback? onTap}) =>
      GestureDetector(
          onTap: onTap,
          child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                  color: outlined ? Colors.transparent : bg,
                  border: outlined ? Border.all(color: _border) : null,
                  borderRadius: BorderRadius.circular(50)),
              child: Center(child: Text(label, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: fg)))));
}
