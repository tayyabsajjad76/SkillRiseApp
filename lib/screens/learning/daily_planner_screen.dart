import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class DailyPlannerScreen extends StatefulWidget {
  const DailyPlannerScreen({super.key});
  @override
  State<DailyPlannerScreen> createState() => _DailyPlannerScreenState();
}

class _DailyPlannerScreenState extends State<DailyPlannerScreen> {
  static const _bg     = Color(0xFF07080F);
  static const _bg2    = Color(0xFF0D1120);
  static const _border = Color(0x12FFFFFF);
  static const _primary= Color(0xFF1A56FF);
  static const _accent = Color(0xFF00E5A0);
  static const _warn   = Color(0xFFFF9500);
  static const _muted  = Color(0x6BFFFFFF);
  static const _text   = Color(0xFFF0F4FF);

  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final uid = AuthService.getUid();
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('users').doc(uid).collection('tasks')
        .orderBy('order').get();
    setState(() {
      _tasks   = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      _loading = false;
    });
  }

  Future<void> _toggleTask(Map<String, dynamic> t) async {
    final uid = AuthService.getUid();
    if (uid == null) return;
    final newDone = !(t['done'] as bool);
    await FirebaseFirestore.instance
        .collection('users').doc(uid).collection('tasks').doc(t['id'])
        .update({'done': newDone});
    setState(() => t['done'] = newDone);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _accent));
    final pending   = _tasks.where((t) => t['done'] == false).toList();
    final completed = _tasks.where((t) => t['done'] == true).toList();

    return Container(
      color: _bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('DAILY PLANNER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: _primary)),
          const SizedBox(height: 8),
          const Text('Today\'s Tasks', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _text)),
          const SizedBox(height: 6),
          Text('${completed.length} / ${_tasks.length} completed today', style: const TextStyle(color: _muted, fontSize: 14)),
          const SizedBox(height: 24),
          if (_tasks.isEmpty)
            Center(child: Column(children: const [
              Text('📋', style: TextStyle(fontSize: 48)),
              SizedBox(height: 12),
              Text('No tasks yet.\nComplete onboarding to generate tasks.', style: TextStyle(color: _muted, fontSize: 13), textAlign: TextAlign.center),
            ])),
          if (pending.isNotEmpty) ...[_sectionLabel('Pending', _warn), const SizedBox(height: 10), ...pending.map((t) => _taskTile(t)), const SizedBox(height: 20)],
          if (completed.isNotEmpty) ...[_sectionLabel('Completed', _accent), const SizedBox(height: 10), ...completed.map((t) => _taskTile(t))],
        ]),
      ),
    );
  }

  Widget _sectionLabel(String label, Color color) => Row(children: [
    Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600)),
  ]);

  Widget _taskTile(Map<String, dynamic> t) {
    final done = t['done'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _bg2, borderRadius: BorderRadius.circular(12), border: Border.all(color: done ? _accent.withOpacity(0.15) : _border)),
      child: Row(children: [
        GestureDetector(
          onTap: () => _toggleTask(t),
          child: Container(
            width: 22, height: 22,
            decoration: BoxDecoration(shape: BoxShape.circle, color: done ? _accent.withOpacity(0.15) : Colors.transparent, border: Border.all(color: done ? _accent : _border, width: 1.5)),
            child: done ? const Icon(Icons.check, color: _accent, size: 13) : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(t['title'] ?? '', style: TextStyle(color: done ? _muted : _text, fontSize: 14, decoration: done ? TextDecoration.lineThrough : null, decorationColor: _muted))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: _primary.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
          child: Text(t['tag'] ?? '', style: const TextStyle(color: Color(0xFF6EA8FF), fontSize: 10, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}