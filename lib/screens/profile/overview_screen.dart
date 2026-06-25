import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  // ── Colors (match app theme) ──────────────────────────────
  static const _bg     = Color(0xFF07080F);
  static const _bg2    = Color(0xFF0D1120);
  static const _border = Color(0x12FFFFFF);
  static const _primary= Color(0xFF1A56FF);
  static const _muted  = Color(0x6BFFFFFF);
  static const _text   = Color(0xFFF0F4FF);

  // ── State ─────────────────────────────────────────────────
  bool   _loading = true;

  // user fields
  String _name        = 'Guest';
  String _email       = '';
  String _degree      = '';
  String _goal        = '';
  String _photoURL    = '';
  int    _xp          = 0;
  List<String> _interests = [];

  // stats
  int _coursesCount = 0;
  int _tasksCount   = 0;
  int _quizzesCount = 0;

  // current project
  String _projectTitle    = '';
  String _projectDesc     = '';
  int    _projectDueInDays= 0;
  double _projectProgress = 0.0;

  // recent activity
  List<_ActivityItem> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Load all data from Firestore ──────────────────────────
  Future<void> _loadData() async {
    final uid = AuthService.getUid();
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    final db = FirebaseFirestore.instance;

    try {
      // 1. Main user document
      final userDoc = await db.collection('users').doc(uid).get();
      final u = userDoc.data() ?? {};

      // 2. Subcollection counts
      final coursesSnap = await db.collection('users').doc(uid).collection('courses').get();
      final tasksSnap   = await db.collection('users').doc(uid).collection('tasks').get();
      final quizSnap    = await db.collection('users').doc(uid).collection('quiz_history').get();

      // 3. Recent quiz activity (latest 2)
      final recentQuiz = await db
          .collection('users').doc(uid)
          .collection('quiz_history')
          .orderBy('date', descending: true)
          .limit(2)
          .get();

      // 4. Recent tasks (latest 2)
      final recentTasks = await db
          .collection('users').doc(uid)
          .collection('tasks')
          .limit(2)
          .get();

      // Build activity list
      final activities = <_ActivityItem>[];

      for (final doc in recentQuiz.docs) {
        final d     = doc.data();
        final topic = d['topic']?.toString() ?? 'Quiz';
        final pct   = d['percent']?.toString() ?? '0';
        final date  = DateTime.tryParse(d['date']?.toString() ?? '');
        activities.add(_ActivityItem(
          icon : Icons.psychology_rounded,
          color: const Color(0xFFEC4899),
          title: 'Completed $topic Quiz',
          sub  : '$pct% score',
          time : date != null ? _timeAgo(date) : '',
        ));
      }

      for (final doc in recentTasks.docs) {
        final d      = doc.data();
        final title  = d['title']?.toString() ?? 'Task';
        final status = d['status']?.toString() ?? 'In progress';
        activities.add(_ActivityItem(
          icon : Icons.check_circle_rounded,
          color: const Color(0xFF22C55E),
          title: title,
          sub  : status,
          time : '',
        ));
      }

      // Parse currentProject
      final cp = u['currentProject'] as Map<String, dynamic>? ?? {};

      if (!mounted) return;
      setState(() {
        _name         = u['name']?.toString() ?? 'Guest';
        _email        = u['email']?.toString() ?? '';
        _degree       = u['degree']?.toString() ?? '';
        _goal         = u['goal']?.toString() ?? '';
        _photoURL     = u['photoURL']?.toString() ?? '';
        _xp           = (u['xp'] as num?)?.toInt() ?? 0;
        _interests    = List<String>.from(u['interests'] ?? []);

        _coursesCount = coursesSnap.docs.length;
        _tasksCount   = tasksSnap.docs.length;
        _quizzesCount = quizSnap.docs.length;

        _projectTitle    = cp['title']?.toString() ?? '';
        _projectDesc     = cp['desc']?.toString() ?? '';
        _projectDueInDays= (cp['dueInDays'] as num?)?.toInt() ?? 0;
        _projectProgress = (cp['progress'] as num?)?.toDouble() ?? 0.0;

        _recentActivity = activities.take(4).toList();
        _loading        = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A56FF)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          const Text('PROFILE', style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              letterSpacing: 1.4, color: _primary)),
          const SizedBox(height: 8),
          const Text('Your Profile', style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: _text)),
          const SizedBox(height: 4),
          const Text('View your stats and account details.',
              style: TextStyle(color: _muted, fontSize: 13)),
          const SizedBox(height: 24),

          // ── Avatar card ──────────────────────────────
          _buildAvatarCard(),
          const SizedBox(height: 16),

          // ── XP + interests row ───────────────────────
          if (_xp > 0 || _interests.isNotEmpty) ...[
            _buildXpInterestsRow(),
            const SizedBox(height: 16),
          ],

          // ── Stats ────────────────────────────────────
          Row(children: [
            _statCard('$_coursesCount', 'Courses',  Icons.menu_book_rounded,   const Color(0xFF6366F1)),
            const SizedBox(width: 12),
            _statCard('$_tasksCount',   'Tasks',    Icons.check_circle_rounded, const Color(0xFF22C55E)),
            const SizedBox(width: 12),
            _statCard('$_quizzesCount', 'Quizzes',  Icons.psychology_rounded,  const Color(0xFFEC4899)),
          ]),
          const SizedBox(height: 16),

          // ── Current project ──────────────────────────
          if (_projectTitle.isNotEmpty) ...[
            _buildProjectCard(),
            const SizedBox(height: 16),
          ],

          // ── Recent activity ──────────────────────────
          _buildActivityCard(),
        ]),
      ),
    );
  }

  // ── Avatar Card ───────────────────────────────────────────
  Widget _buildAvatarCard() {
    final initial = _name.isNotEmpty ? _name[0].toUpperCase() : 'G';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        // Avatar: photo or initial
        CircleAvatar(
          radius: 38,
          backgroundColor: Colors.white.withOpacity(0.2),
          backgroundImage: _photoURL.isNotEmpty ? NetworkImage(_photoURL) : null,
          child: _photoURL.isEmpty
              ? Text(initial, style: const TextStyle(
              color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold))
              : null,
        ),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_name, style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          if (_email.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(_email, style: TextStyle(
                color: Colors.white.withOpacity(0.75), fontSize: 12)),
          ],
          if (_degree.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(_degree, style: TextStyle(
                color: Colors.white.withOpacity(0.65), fontSize: 12)),
          ],
          if (_goal.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('🎯 $_goal', style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
            ),
          ],
        ])),
      ]),
    );
  }

  // ── XP + Interests ────────────────────────────────────────
  Widget _buildXpInterestsRow() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // XP card
      if (_xp > 0)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _bg2, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Column(children: [
            const Text('⚡', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text('$_xp', style: const TextStyle(
                color: Color(0xFFFBBF24), fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('XP', style: TextStyle(color: _muted, fontSize: 11)),
          ]),
        ),
      if (_xp > 0 && _interests.isNotEmpty) const SizedBox(width: 12),
      // Interests
      if (_interests.isNotEmpty)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _bg2, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Interests', style: TextStyle(
                  color: _muted, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: _interests.map((i) =>
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _primary.withOpacity(0.3)),
                    ),
                    child: Text(i, style: const TextStyle(
                        color: _primary, fontSize: 11, fontWeight: FontWeight.w500)),
                  ),
              ).toList()),
            ]),
          ),
        ),
    ]);
  }

  // ── Stat Card ─────────────────────────────────────────────
  Widget _statCard(String value, String label, IconData icon, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _bg2, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Column(children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
          ]),
        ),
      );

  // ── Current Project Card ──────────────────────────────────
  Widget _buildProjectCard() {
    final pct = (_projectProgress * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bg2, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🚀', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          const Text('Current Project', style: TextStyle(
              color: _muted, fontSize: 11, fontWeight: FontWeight.w600,
              letterSpacing: 0.8)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Due in $_projectDueInDays days',
                style: const TextStyle(color: Colors.orange, fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 10),
        Text(_projectTitle, style: const TextStyle(
            color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
        if (_projectDesc.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(_projectDesc, style: const TextStyle(color: _muted, fontSize: 12),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _projectProgress,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A56FF)),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('$pct%', style: const TextStyle(
              color: _primary, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  // ── Recent Activity Card ──────────────────────────────────
  Widget _buildActivityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bg2, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Recent Activity', style: TextStyle(
            color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        if (_recentActivity.isEmpty)
          const Text('No activity yet. Start a quiz or task!',
              style: TextStyle(color: _muted, fontSize: 13))
        else
          ..._recentActivity.map((a) => _activityRow(a)),
      ]),
    );
  }

  Widget _activityRow(_ActivityItem a) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: a.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(a.icon, size: 18, color: a.color),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(a.title, style: const TextStyle(
            color: _text, fontSize: 13, fontWeight: FontWeight.w500)),
        Text(a.sub, style: const TextStyle(color: _muted, fontSize: 11)),
      ])),
      if (a.time.isNotEmpty)
        Text(a.time, style: const TextStyle(color: _muted, fontSize: 11)),
    ]),
  );
}

// ── Data class ────────────────────────────────────────────────
class _ActivityItem {
  final IconData icon;
  final Color    color;
  final String   title, sub, time;
  const _ActivityItem({
    required this.icon, required this.color,
    required this.title, required this.sub, required this.time,
  });
}
