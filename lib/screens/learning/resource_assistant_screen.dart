import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/ai_service.dart';

class ResourceAssistantScreen extends StatefulWidget {
  const ResourceAssistantScreen({super.key});
  @override
  State<ResourceAssistantScreen> createState() => _ResourceAssistantScreenState();
}

class _ResourceAssistantScreenState extends State<ResourceAssistantScreen> {
  static const _bg     = Color(0xFF07080F);
  static const _bg2    = Color(0xFF0D1120);
  static const _border = Color(0x12FFFFFF);
  static const _primary= Color(0xFF1A56FF);
  static const _muted  = Color(0x6BFFFFFF);
  static const _text   = Color(0xFFF0F4FF);

  static const _colors = [
    Color(0xFF1A56FF), Color(0xFFA855F7), Color(0xFFEF4444),
    Color(0xFFFF9500), Color(0xFF00E5A0), Color(0xFF6EA8FF),
  ];

  List<String> _interests = [];
  String       _topic     = '';
  bool         _loadingInterests = true;

  // topic → {videos: [...], docs: [...]}
  final Map<String, Map<String, List<_Res>>> _cache = {};
  bool _generatingTopic = false;

  @override
  void initState() {
    super.initState();
    _loadInterests();
  }

  Future<void> _loadInterests() async {
    final uid = AuthService.getUid();
    if (uid == null) return;
    final doc  = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    final interests = List<String>.from(data['interests'] ?? []);
    setState(() {
      _interests       = interests;
      _topic           = interests.isNotEmpty ? interests.first : '';
      _loadingInterests = false;
    });
    if (_topic.isNotEmpty) await _loadTopic(_topic);
  }

  Future<void> _loadTopic(String topic) async {
    // Already cached in memory
    if (_cache.containsKey(topic)) return;

    final uid = AuthService.getUid();
    if (uid == null) return;

    final topicKey = topic.replaceAll(' ', '_').replaceAll('&', 'and');

    // Check Firestore cache
    final snap = await FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('resources').doc(topicKey)
        .get();

    if (snap.exists) {
      final data    = snap.data()!;
      final videos  = _parseRes(data['videos'] ?? []);
      final docs    = _parseRes(data['docs']   ?? []);
      setState(() => _cache[topic] = {'videos': videos, 'docs': docs});
      return;
    }

    // Generate via AI
    setState(() => _generatingTopic = true);
    try {
      final prompt = '''
You are a learning resource curator. Generate real, working online resources for a student learning "$topic".

Respond ONLY with a JSON object. No explanation, no markdown, no backticks.
{
  "videos": [
    {"title": "Resource Name", "subtitle": "platform · type", "url": "https://..."}
  ],
  "docs": [
    {"title": "Resource Name", "subtitle": "domain · type", "url": "https://..."}
  ]
}

Rules:
- videos: 2-3 real YouTube channels or video courses (YouTube, Coursera videos, etc.)
- docs: 3-4 real documentation sites, article sites, or interactive learning platforms
- All URLs must be real and working
- Specific to "$topic" only
- No made-up URLs
''';

      final raw     = await AIService.ask(prompt);
      final cleaned = AIService.extractJsonObject(raw);
      final decoded = jsonDecode(cleaned) as Map<String, dynamic>;

      final videos = _parseResFromJson(decoded['videos'] ?? [], isDoc: false);
      final docs   = _parseResFromJson(decoded['docs']   ?? [], isDoc: true);

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('resources').doc(topicKey)
          .set({
        'videos': videos.map((r) => {'title': r.title, 'subtitle': r.subtitle, 'url': r.url, 'isDoc': false}).toList(),
        'docs'  : docs.map((r)   => {'title': r.title, 'subtitle': r.subtitle, 'url': r.url, 'isDoc': true}).toList(),
      });

      if (mounted) setState(() => _cache[topic] = {'videos': videos, 'docs': docs});
    } catch (e) {
      if (mounted) setState(() => _cache[topic] = {'videos': [], 'docs': []});
    } finally {
      if (mounted) setState(() => _generatingTopic = false);
    }
  }

  List<_Res> _parseRes(List<dynamic> list) {
    return list.asMap().entries.map((e) {
      final m     = e.value as Map<String, dynamic>;
      final isDoc = m['isDoc'] as bool? ?? true;
      final color = _colors[e.key % _colors.length];
      return _Res(
        m['title']    ?? '',
        m['subtitle'] ?? '',
        m['url']      ?? '',
        color,
        isDoc ? Icons.open_in_new_rounded : Icons.play_circle_filled,
        isDoc,
      );
    }).toList();
  }

  List<_Res> _parseResFromJson(List<dynamic> list, {required bool isDoc}) {
    return list.asMap().entries.map((e) {
      final m     = e.value as Map<String, dynamic>;
      final color = _colors[e.key % _colors.length];
      return _Res(
        m['title']    ?? '',
        m['subtitle'] ?? '',
        m['url']      ?? '',
        color,
        isDoc ? Icons.open_in_new_rounded : Icons.play_circle_filled,
        isDoc,
      );
    }).toList();
  }

  Future<void> _launch(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _switchTopic(String topic) async {
    setState(() => _topic = topic);
    await _loadTopic(topic);
  }

  Future<void> _regenerate() async {
    final uid = AuthService.getUid();
    if (uid == null || _topic.isEmpty) return;
    final topicKey = _topic.replaceAll(' ', '_').replaceAll('&', 'and');
    // Delete Firestore cache
    await FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('resources').doc(topicKey)
        .delete();
    _cache.remove(_topic);
    await _loadTopic(_topic);
  }

  List<_Res> get _videos => _cache[_topic]?['videos'] ?? [];
  List<_Res> get _docs   => _cache[_topic]?['docs']   ?? [];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('RESOURCE ASSISTANT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: _primary)),
            if (_topic.isNotEmpty && !_generatingTopic)
              GestureDetector(
                onTap: _regenerate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: _primary.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('🔄 Refresh', style: TextStyle(color: _primary, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
          ]),
          const SizedBox(height: 8),
          const Text('Current Learning Materials', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _text)),
          const SizedBox(height: 6),
          const Text('AI-curated resources for your interests. Tap a topic to switch.', style: TextStyle(color: _muted, fontSize: 13)),
          const SizedBox(height: 16),

          if (_loadingInterests)
            const Center(child: CircularProgressIndicator(color: _primary))
          else ...[
            // Topic chips
            Wrap(spacing: 8, runSpacing: 8, children: _interests.map((i) => GestureDetector(
              onTap: () => _switchTopic(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _topic == i ? _primary.withOpacity(0.15) : _bg2.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _topic == i ? _primary : _border),
                ),
                child: Text(i, style: TextStyle(
                  color: _topic == i ? const Color(0xFF6EA8FF) : _muted,
                  fontSize: 12,
                  fontWeight: _topic == i ? FontWeight.w600 : FontWeight.normal,
                )),
              ),
            )).toList()),
            const SizedBox(height: 24),

            if (_topic.isEmpty)
              const Center(child: Text('Complete onboarding to see resources.', style: TextStyle(color: _muted, fontSize: 13)))
            else if (_generatingTopic)
              Center(child: Column(children: [
                const SizedBox(height: 40),
                const CircularProgressIndicator(color: _primary, strokeWidth: 2),
                const SizedBox(height: 16),
                Text('AI finding best resources for $_topic...', style: const TextStyle(color: _muted, fontSize: 13)),
              ]))
            else
              Column(children: [
                // Videos panel
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: _bg2, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [
                      Text('📹', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Text('Video Tutorials', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 16),
                    if (_videos.isEmpty)
                      const Text('No videos found.', style: TextStyle(color: _muted, fontSize: 13))
                    else
                      ..._videos.map((r) => _resTile(r)),
                  ]),
                ),
                const SizedBox(height: 16),
                // Docs panel
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: _bg2, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [
                      Text('📄', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Text('Docs & Articles', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 16),
                    if (_docs.isEmpty)
                      const Text('No docs found.', style: TextStyle(color: _muted, fontSize: 13))
                    else
                      ..._docs.map((r) => _resTile(r)),
                  ]),
                ),
              ]),
          ],
        ]),
      ),
    );
  }

  Widget _resTile(_Res r) {
    return GestureDetector(
      onTap: () => _launch(r.url),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: r.color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: r.color.withOpacity(0.2)),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: r.color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(r.icon, color: r.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.title, style: TextStyle(color: r.color, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(r.subtitle, style: const TextStyle(color: _muted, fontSize: 11)),
            ])),
            const SizedBox(width: 8),
            const Icon(Icons.open_in_new_rounded, color: _muted, size: 15),
          ]),
        ),
      ),
    );
  }
}

class _Res {
  final String title, subtitle, url;
  final Color color;
  final IconData icon;
  final bool isDoc;
  const _Res(this.title, this.subtitle, this.url, this.color, this.icon, this.isDoc);
}