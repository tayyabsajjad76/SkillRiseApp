import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';

class CourseSuggestionsScreen extends StatefulWidget {
  const CourseSuggestionsScreen({super.key});
  @override
  State<CourseSuggestionsScreen> createState() => _CourseSuggestionsScreenState();
}

class _CourseSuggestionsScreenState extends State<CourseSuggestionsScreen> {
  static const _bg     = Color(0xFF07080F);
  static const _bg2    = Color(0xFF0D1120);
  static const _border = Color(0x12FFFFFF);
  static const _primary= Color(0xFF1A56FF);
  static const _accent = Color(0xFF00E5A0);
  static const _muted  = Color(0x6BFFFFFF);
  static const _text   = Color(0xFFF0F4FF);

  static const _colors = [Color(0xFFFF9500), Color(0xFF00E5A0), Color(0xFF1A56FF), Color(0xFFA855F7)];

  List<Map<String, dynamic>> _courses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final uid = AuthService.getUid();
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('users').doc(uid).collection('courses')
        .orderBy('order').get();
    setState(() {
      _courses = snap.docs.map((d) => d.data()).toList();
      _loading = false;
    });
  }

  Future<void> _openCourse(String title) async {
    final url = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(title)}');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5A0)));

    return Container(
      color: _bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('COURSE SUGGESTIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: _primary)),
          const SizedBox(height: 8),
          const Text('Recommended For You', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _text)),
          const SizedBox(height: 6),
          const Text('AI-picked courses based on your interests and goal.', style: TextStyle(color: _muted, fontSize: 14)),
          const SizedBox(height: 24),
          if (_courses.isEmpty)
            Center(child: Column(children: const [
              Text('🎓', style: TextStyle(fontSize: 48)),
              SizedBox(height: 12),
              Text('No courses yet.\nComplete onboarding to get recommendations.', style: TextStyle(color: _muted, fontSize: 13), textAlign: TextAlign.center),
            ])),
          ..._courses.asMap().entries.map((e) {
            final i = e.key;
            final c = e.value;
            final color = _colors[i % _colors.length];
            return GestureDetector(
              onTap: () => _openCourse(c['title'] ?? ''),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: _bg2, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 44, height: 44,
                        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.play_circle_outline_rounded, color: color, size: 22)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c['title'] ?? '', style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(c['platform'] ?? '', style: const TextStyle(color: _muted, fontSize: 12)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text('💡 ${c['reason'] ?? ''}', style: TextStyle(color: color, fontSize: 11)),
                      ),
                    ])),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_ios_rounded, color: _muted, size: 14),
                  ]),
                ),
              ),
            );
          }),
        ]),
      ),
    );
  }
}
