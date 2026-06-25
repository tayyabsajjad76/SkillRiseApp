import 'package:flutter/material.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});
  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _msgCtrl = TextEditingController();

  static const _bg     = Color(0xFF07080F);
  static const _bg2    = Color(0xFF0D1120);
  static const _border = Color(0x12FFFFFF);
  static const _primary= Color(0xFF1A56FF);
  static const _muted  = Color(0x6BFFFFFF);
  static const _text   = Color(0xFFF0F4FF);

  static const _faqs = [
    {'q': 'How do I reset my password?',     'a': 'Go to Settings > Change Password and follow the steps.'},
    {'q': 'How are quiz scores calculated?', 'a': 'Each correct answer earns 1 point. Final score shown as percentage.'},
    {'q': 'Can I retake a quiz?',            'a': 'Yes! You can retake any quiz unlimited times.'},
    {'q': 'How do I download my resume?',    'a': 'Go to My Resume and tap the Download PDF button.'},
    {'q': 'How do I contact support?',       'a': 'Use the contact form below or email support@learnapp.com'},
  ];

  @override
  void dispose() { _msgCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('HELP & SUPPORT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: _primary)),
          const SizedBox(height: 8),
          const Text('How can we help?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _text)),
          const SizedBox(height: 6),
          const Text('We usually reply within 24 hours.', style: TextStyle(color: _muted, fontSize: 14)),
          const SizedBox(height: 24),

          const Text('FAQs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
          const SizedBox(height: 12),
          ..._faqs.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: _bg2, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              iconColor: _primary, collapsedIconColor: _muted,
              title: Text(e['q']!, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: _text)),
              children: [
                Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(e['a']!, style: const TextStyle(color: _muted, fontSize: 13, height: 1.5))),
              ],
            ),
          )),

          const SizedBox(height: 20),
          const Text('Send a Message', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _bg2, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
            child: Column(children: [
              TextField(
                controller: _msgCtrl, maxLines: 4,
                style: const TextStyle(color: _text),
                decoration: InputDecoration(
                  hintText: 'Describe your issue...', hintStyle: const TextStyle(color: _muted),
                  filled: true, fillColor: _bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (_msgCtrl.text.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Message sent! We'll reply within 24 hours."), backgroundColor: _primary));
                      _msgCtrl.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Send Message', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}