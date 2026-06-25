import 'package:flutter/material.dart';

class ResumeScreen extends StatelessWidget {
  const ResumeScreen({super.key});

  static const _bg     = Color(0xFF07080F);
  static const _bg2    = Color(0xFF0D1120);
  static const _border = Color(0x12FFFFFF);
  static const _primary= Color(0xFF1A56FF);
  static const _muted  = Color(0x6BFFFFFF);
  static const _text   = Color(0xFFF0F4FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('MY RESUME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: _primary)),
              const SizedBox(height: 6),
              const Text('Your Resume', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _text)),
            ]),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Download PDF'),
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
          ]),
          const SizedBox(height: 24),

          _section('Personal Info', [
            _row(Icons.person_outline,      'Tayyab Sajjad'),
            _row(Icons.email_outlined,       'Tayyab12@example.com'),
            _row(Icons.phone_outlined,       '+92 300 1234567'),
            _row(Icons.location_on_outlined, 'Lahore, Pakistan'),
          ]),
          _section('Education', [
            _entry('BS Computer Science', 'University of Punjab', '2021 – 2025'),
          ]),
          _section('Skills', [
            Wrap(
              spacing: 8, runSpacing: 8,
              children: ['Flutter', 'Dart', 'Firebase', 'REST APIs', 'Git', 'UI/UX'].map((s) =>
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _primary.withOpacity(0.3)),
                    ),
                    child: Text(s, style: const TextStyle(color: _primary, fontSize: 12, fontWeight: FontWeight.w500)),
                  )).toList(),
            ),
          ]),
          _section('Experience', [
            _entry('Flutter Developer Intern', 'TechCorp Pvt Ltd', 'Jun 2024 – Aug 2024'),
          ]),
        ]),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
    width: double.infinity, margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: _bg2, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _primary)),
      const Divider(height: 16, color: Color(0x12FFFFFF)),
      ...children,
    ]),
  );

  Widget _row(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Icon(icon, size: 16, color: _muted),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontSize: 13, color: _text)),
    ]),
  );

  Widget _entry(String title, String sub, String date) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: _text)),
      Text(sub,   style: const TextStyle(color: _muted, fontSize: 13)),
      Text(date,  style: const TextStyle(color: _primary, fontSize: 12)),
    ]),
  );
}