import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class ProfileNotificationsScreen extends StatefulWidget {
  const ProfileNotificationsScreen({super.key});
  @override
  State<ProfileNotificationsScreen> createState() => _ProfileNotificationsScreenState();
}

class _ProfileNotificationsScreenState extends State<ProfileNotificationsScreen> {
  static const _bg     = Color(0xFF07080F);
  static const _bg2    = Color(0xFF0D1120);
  static const _border = Color(0x12FFFFFF);
  static const _primary= Color(0xFF1A56FF);
  static const _muted  = Color(0x6BFFFFFF);
  static const _text   = Color(0xFFF0F4FF);

  final _db  = FirebaseFirestore.instance;
  String? _uid;

  // Toggle states
  bool _push   = false;
  bool _email  = false;
  bool _quiz   = false;
  bool _task   = false;
  bool _weekly = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _uid = AuthService.getUid();
    _loadSettings();
  }

  // ── Load toggle settings from Firestore ──
  Future<void> _loadSettings() async {
    if (_uid == null) return;
    final doc = await _db
        .collection('users').doc(_uid)
        .collection('notificationSettings').doc('prefs')
        .get();

    if (doc.exists) {
      final d = doc.data()!;
      setState(() {
        _push   = d['push']   ?? false;
        _email  = d['email']  ?? false;
        _quiz   = d['quiz']   ?? false;
        _task   = d['task']   ?? false;
        _weekly = d['weekly'] ?? false;
        _loaded = true;
      });
    } else {
      // First time — write defaults
      await _db
          .collection('users').doc(_uid)
          .collection('notificationSettings').doc('prefs')
          .set({'push': true, 'email': false, 'quiz': true, 'task': true, 'weekly': false});
      setState(() {
        _push = true; _quiz = true; _task = true; _loaded = true;
      });
    }
  }

  // ── Save single toggle to Firestore ──
  Future<void> _saveSetting(String key, bool val) async {
    if (_uid == null) return;
    await _db
        .collection('users').doc(_uid)
        .collection('notificationSettings').doc('prefs')
        .update({key: val});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('NOTIFICATIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: _primary)),
          const SizedBox(height: 8),
          const Text('Notification Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _text)),
          const SizedBox(height: 24),

          _label('Preferences'),

          if (!_loaded)
            const Center(child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFF1A56FF)),
            ))
          else ...[
            _toggle('Push Notifications', _push,   'push',   (v) => setState(() => _push   = v)),
            _toggle('Email Notifications', _email, 'email',  (v) => setState(() => _email  = v)),
            _toggle('Quiz Reminders',      _quiz,  'quiz',   (v) => setState(() => _quiz   = v)),
            _toggle('Task Reminders',      _task,  'task',   (v) => setState(() => _task   = v)),
            _toggle('Weekly Report',       _weekly,'weekly', (v) => setState(() => _weekly = v)),
          ],

          const SizedBox(height: 20),
          _label('Recent'),

          // ── Live Firestore stream ──
          if (_uid == null)
            const Text('Not logged in', style: TextStyle(color: Colors.redAccent))
          else
            StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('users').doc(_uid)
                  .collection('notifications')
                  .orderBy('createdAt', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1A56FF)));
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _bg2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: const Center(
                      child: Text('No notifications yet', style: TextStyle(color: Color(0x6BFFFFFF))),
                    ),
                  );
                }

                final docs = snap.data!.docs;
                return Column(
                  children: docs.map((doc) {
                    final n    = doc.data() as Map<String, dynamic>;
                    final read = n['read'] as bool? ?? true;
                    return GestureDetector(
                      onTap: () => _markRead(doc.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: read ? _bg2 : _primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: read ? _border : _primary.withOpacity(0.2)),
                        ),
                        child: Row(children: [
                          Text(n['icon'] ?? '🔔', style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: _text, fontSize: 13))),
                              if (!read) Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                              ),
                            ]),
                            Text(n['body'] ?? '', style: const TextStyle(fontSize: 11, color: _muted)),
                          ])),
                          const SizedBox(width: 8),
                          Text(_timeAgo(n['createdAt']), style: const TextStyle(fontSize: 10, color: _muted)),
                        ]),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ]),
      ),
    );
  }

  Future<void> _markRead(String docId) async {
    if (_uid == null) return;
    await _db
        .collection('users').doc(_uid)
        .collection('notifications').doc(docId)
        .update({'read': true});
  }

  String _timeAgo(dynamic timestamp) {
    if (timestamp == null) return '';
    final dt  = (timestamp as Timestamp).toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24)  return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _label(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primary, letterSpacing: 0.5)),
  );

  Widget _toggle(String title, bool val, String key, Function(bool) cb) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(color: _bg2, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
    child: SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      title: Text(title, style: const TextStyle(color: _text, fontWeight: FontWeight.w500, fontSize: 13)),
      value: val,
      activeColor: _primary,
      onChanged: (v) { cb(v); _saveSetting(key, v); },
    ),
  );
}