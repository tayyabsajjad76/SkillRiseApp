import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../career/career_screen.dart';
import '../insights/insights_screen.dart';
import '../learning/learning_screen.dart';
import '../quiz_screen.dart';
import 'home_theme.dart';
import 'widgets/home_topbar.dart';
import 'widgets/hero_banner.dart';
import 'widgets/stats_row.dart';
import 'widgets/quick_cards.dart';
import 'widgets/dashboard_bottom_nav.dart';

import '../login_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/notifications_screen.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int    _navIndex = 0;
  String _userName = 'Guest';
  bool   _loggedIn = false;

  // User profile data from Firestore
  Map<String, dynamic> _userProfile = {};

  // Real stats from Firestore
  int    _pendingTasks    = 0;
  int    _roadmapPercent  = 0;
  int    _doneCount       = 0;
  int    _totalMilestones = 0;
  double _quizAvg         = 0;
  int    _readinessPercent= 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ));
    _loadAll();
  }

  Future<void> _loadAll() async {
    final loggedIn = await AuthService.isLoggedIn();
    final name     = await AuthService.getUserName();
    final uid      = AuthService.getUid();

    setState(() {
      _loggedIn = loggedIn;
      _userName = loggedIn ? name : 'Guest';
    });

    if (uid == null) return;

    // Load profile
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final profile = doc.data() ?? {};

    // Load tasks
    final tasksSnap = await FirebaseFirestore.instance.collection('users').doc(uid).collection('tasks').get();
    final pending   = tasksSnap.docs.where((d) => d['done'] == false).length;

    // Load roadmap
    final roadmapSnap = await FirebaseFirestore.instance.collection('users').doc(uid).collection('roadmap').get();
    final total = roadmapSnap.docs.length;
    final done  = roadmapSnap.docs.where((d) => d['done'] == true).length;

    // Load quiz history (same logic as AnalyticsScreen)
    final quizSnap = await FirebaseFirestore.instance.collection('users').doc(uid).collection('quiz_history').get();
    final quizDocs = quizSnap.docs.map((d) => d.data()).toList();
    double quizAvg = 0;
    if (quizDocs.isNotEmpty) {
      final totalPct = quizDocs.fold<int>(0, (s, d) => s + ((d['percent'] ?? 0) as num).toInt());
      quizAvg = totalPct / quizDocs.length;
    }

    // Skill score: avg percent grouped by topic (same as AnalyticsScreen)
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

    // Load completed projects
    final projSnap = await FirebaseFirestore.instance.collection('users').doc(uid).collection('completedProjects').get();
    double projectsAvg = 0;
    if (projSnap.docs.isNotEmpty) {
      final totalScore = projSnap.docs.fold<int>(0, (s, d) => s + ((d.data()['score'] ?? 0) as num).toInt());
      projectsAvg = totalScore / projSnap.docs.length;
    }

    // Readiness = quiz 40% + skill 30% + projects 30% (same formula as AnalyticsScreen)
    final readiness = (quizAvg * 0.4) + (skillScore * 0.3) + (projectsAvg * 0.3);

    setState(() {
      _userProfile      = profile;
      _pendingTasks     = pending;
      _totalMilestones  = total;
      _doneCount        = done;
      _roadmapPercent   = total == 0 ? 0 : (done / total * 100).toInt();
      _quizAvg          = quizAvg;
      _readinessPercent = readiness.toInt();
    });
  }

  Future<void> _onLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  Widget _buildBody() {
    switch (_navIndex) {
      case 1: return LearningScreen(onChanged: _loadAll); // ✅ NEW — refreshes home stats instantly
      case 2: return ProfileScreen(onLogout: _onLogout);
      case 3: return const CareerScreen();
      case 4: return const InsightsScreen();
      default: return _buildDashboardHome();
    }
  }

  Widget _buildDashboardHome() {
    final goal      = _userProfile['goal'] as String? ?? '';
    final interests = (_userProfile['interests'] as List?)?.cast<String>() ?? [];
    final isNew     = _userProfile['onboarding_complete'] != true;

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: HeroBanner(
          userName     : _userName.split(' ').first,
          goal         : goal,
          interests    : interests,
          pendingTasks : _pendingTasks,
          isNewUser    : isNew,
          onTasksTap   : () => setState(() => _navIndex = 1),
          onInterviewTap: () {},
        ),
      ),

      SliverToBoxAdapter(
        child: StatsRow(
          roadmapPercent : _roadmapPercent,
          pendingTasks   : _pendingTasks,
          doneCount      : _doneCount,
          totalMilestones: _totalMilestones,
          quizAvg        : _quizAvg,
        ),
      ),

      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Quick Access', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: HT.textColor)),
            Text('See All', style: TextStyle(fontSize: 12, color: HT.primary, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),

      SliverToBoxAdapter(
        child: QuickCardsGrid(
          roadmapPercent: _roadmapPercent,
          interests     : interests,
          pendingTasks  : _pendingTasks,
          onNavigate    : (page) {
            switch (page) {
              case 'roadmap': setState(() => _navIndex = 1); break;
              case 'quiz':
                Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen()));
                break;
              case 'learning': setState(() => _navIndex = 1); break;
            }
          },
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HT.bg,
      resizeToAvoidBottomInset: false,
      body: Column(children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        HomeTopbar(
          userName: _userName.split(' ').first,
          readinessPercent: _readinessPercent,
          onNotification: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileNotificationsScreen())),
          onBack: _loggedIn ? _onLogout : () {},
        ),
        Expanded(child: _buildBody()),
      ]),
      bottomNavigationBar: DashboardBottomNav(
        selectedIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}