import 'package:flutter/material.dart';

class MockInterviewScreen extends StatelessWidget {
  const MockInterviewScreen({super.key});

  static const _bg     = Color(0xFF07080F);
  static const _bg2    = Color(0xFF0D1120);
  static const _border = Color(0x12FFFFFF);
  static const _primary= Color(0xFF1A56FF);
  static const _muted  = Color(0x6BFFFFFF);
  static const _text   = Color(0xFFF0F4FF);

  static const List<Map<String, dynamic>> _interviews = [
    {'title': 'Flutter Developer', 'level': 'Junior', 'duration': '30 min', 'questions': 10, 'color': Color(0xFF4F46E5), 'icon': '📱'},
    {'title': 'React Native Dev',  'level': 'Mid',    'duration': '45 min', 'questions': 15, 'color': Color(0xFF7C3AED), 'icon': '⚛️'},
    {'title': 'System Design',     'level': 'Senior', 'duration': '60 min', 'questions': 8,  'color': Color(0xFF0EA5E9), 'icon': '🏗️'},
    {'title': 'Data Structures',   'level': 'Junior', 'duration': '40 min', 'questions': 20, 'color': Color(0xFF10B981), 'icon': '🧩'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('MOCK INTERVIEWS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: _primary)),
          const SizedBox(height: 8),
          const Text('Practice Sessions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _text)),
          const SizedBox(height: 6),
          const Text('AI-powered interview practice with instant feedback.', style: TextStyle(color: _muted, fontSize: 14)),
          const SizedBox(height: 24),

          ..._interviews.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _bg2, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: (item['color'] as Color).withOpacity(0.2)),
            ),
            child: Row(children: [
              Text(item['icon'], style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['title'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _text)),
                Text(item['level'], style: TextStyle(color: item['color'] as Color, fontWeight: FontWeight.w500, fontSize: 12)),
                const SizedBox(height: 4),
                Text('${item['questions']} Questions · ${item['duration']}', style: const TextStyle(color: _muted, fontSize: 12)),
              ])),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: (item['color'] as Color).withOpacity(0.15),
                  foregroundColor: item['color'] as Color,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Start', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ]),
          )),
        ]),
      ),
    );
  }
}