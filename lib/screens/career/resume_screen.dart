import 'dart:convert';
import 'resume_download.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/ai_service.dart';
import 'dart:typed_data';

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key});
  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  static const _bg    = Color(0xFF07080F);
  static const _bg2   = Color(0xFF0D1120);
  static const _border= Color(0x12FFFFFF);
  static const _primary=Color(0xFF1A56FF);
  static const _accent= Color(0xFF00E5A0);
  static const _muted = Color(0x6BFFFFFF);
  static const _text  = Color(0xFFF0F4FF);

  final _nameCtrl    = TextEditingController();
  final _roleCtrl    = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _skillsCtrl  = TextEditingController();
  final _eduCtrl     = TextEditingController();
  final _projCtrl    = TextEditingController();

  String _pName    = 'Your Name';
  String _pRole    = 'Your Role';
  String _pContact = 'email · linkedin · city';
  String _pSkills  = '—';
  String _pEdu     = '—';
  List<String> _pProjects = ['Your projects will appear here'];

  bool _improving  = false;

  void _updatePreview() {
    setState(() {
      _pName    = _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Your Name';
      _pRole    = _roleCtrl.text.isNotEmpty ? _roleCtrl.text : 'Your Role';
      _pContact = _contactCtrl.text.isNotEmpty ? _contactCtrl.text : 'email · linkedin · city';
      _pSkills  = _skillsCtrl.text.isNotEmpty ? _skillsCtrl.text : '—';
      _pEdu     = _eduCtrl.text.isNotEmpty ? _eduCtrl.text : '—';
      _pProjects = _projCtrl.text
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      if (_pProjects.isEmpty) _pProjects = ['Your projects will appear here'];
    });
  }

  Future<void> _aiImprove() async {
    if (_nameCtrl.text.isEmpty && _skillsCtrl.text.isEmpty) {
      _showSnack('Fill in your details first.');
      return;
    }
    setState(() => _improving = true);
    try {
      final prompt = '''
You are a professional resume writer. Improve this resume content and return ONLY a JSON object with improved versions.

Current resume:
- Name: ${_nameCtrl.text}
- Role: ${_roleCtrl.text}
- Contact: ${_contactCtrl.text}
- Skills: ${_skillsCtrl.text}
- Education: ${_eduCtrl.text}
- Projects: ${_projCtrl.text}

Respond ONLY with a JSON object. No explanation, no markdown, no backticks.
{
  "role": "improved role title",
  "skills": "improved, polished skills list",
  "education": "improved education entry",
  "projects": "improved project 1\\nimproved project 2"
}

Keep name and contact unchanged. Make skills more professional and impactful. Improve project descriptions to sound more impressive.
''';
      final raw     = await AIService.ask(prompt);
      final cleaned = AIService.extractJsonObject(raw);
      final data    = jsonDecode(cleaned) as Map<String, dynamic>;

      setState(() {
        if (data['role'] != null)     { _roleCtrl.text    = data['role'];     }
        if (data['skills'] != null)   { _skillsCtrl.text  = data['skills'];   }
        if (data['education'] != null){ _eduCtrl.text     = data['education'];}
        if (data['projects'] != null) { _projCtrl.text    = data['projects']; }
      });
      _updatePreview();
      _showSnack('✅ Resume improved by AI!');
    } catch (e, stack) {
      debugPrint('AI Improve ERROR: $e\n$stack');
      _showSnack('Failed to improve. Try again.');
    } finally {
      setState(() => _improving = false);
    }
  }

  Future<void> _downloadPdf() async {
    _updatePreview();
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(_pName, style: pw.TextStyle(
                fontSize: 22, fontWeight: pw.FontWeight.bold,
                color: const PdfColor.fromInt(0xFF0A35CC),
              )),
              pw.SizedBox(height: 2),
              pw.Text(_pRole, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              pw.Text(_pContact, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              pw.SizedBox(height: 12),
              pw.Divider(color: const PdfColor.fromInt(0xFF0A35CC), thickness: 1),
              _pdfSection('SKILLS'),
              pw.Text(_pSkills, style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 8),
              _pdfSection('EDUCATION'),
              pw.Text(_pEdu, style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 8),
              _pdfSection('PROJECTS'),
              ..._pProjects.map((p) {
                final parts = p.split('—');
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Text('- ${parts[0].trim()}${parts.length > 1 ? " — ${parts[1].trim()}" : ""}',
                      style: const pw.TextStyle(fontSize: 11)),
                );
              }),
            ],
          );
        },
      ),
    );

    final bytes = await doc.save();
    await downloadResume(bytes);
  }

  pw.Widget _pdfSection(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(title, style: pw.TextStyle(
        fontSize: 9, fontWeight: pw.FontWeight.bold,
        letterSpacing: 1.2, color: const PdfColor.fromInt(0xFF0A35CC),
      )),
      pw.Divider(color: const PdfColor.fromInt(0xFF0A35CC), thickness: 1),
    ]),
  );

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF0D1120)),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _roleCtrl.dispose(); _contactCtrl.dispose();
    _skillsCtrl.dispose(); _eduCtrl.dispose(); _projCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('AI RESUME BUILDER', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: 1.2, color: _primary,
              )),
              const SizedBox(height: 6),
              const Text('Build Your Professional CV', style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w500, color: _text,
              )),
              const SizedBox(height: 4),
              const Text('AI fills your resume based on your platform activity. Edit and download as PDF.',
                  style: TextStyle(fontSize: 13, color: _muted, height: 1.6)),
              const SizedBox(height: 16),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // TOP: Edit form
                _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Flexible(child: Text('Edit Your Details', style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500, color: _text))),
                    GestureDetector(
                      onTap: _updatePreview,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(50)),
                        child: const Text('✨ Update', style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF07080F))),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _field('Full Name',               _nameCtrl,    hint: 'e.g. Ali Hassan'),
                  _field('Role / Title',            _roleCtrl,    hint: 'e.g. Full Stack Developer'),
                  _field('Contact Info',            _contactCtrl, hint: 'e.g. ali@email.com · linkedin.com/in/ali · Karachi, PK'),
                  _field('Skills',                  _skillsCtrl,  hint: 'e.g. JavaScript, React.js, Node.js, MongoDB'),
                  _field('Education',               _eduCtrl,     hint: 'e.g. BS Computer Science — FAST (2022–2026)'),
                  _field('Projects (one per line)', _projCtrl,    maxLines: 4,
                      hint: 'e.g. Portfolio Website — HTML/CSS/JS\nTodo App — React + Firebase'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _updatePreview,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(50)),
                      child: const Center(child: Text('🔄 Update Preview',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white))),
                    ),
                  ),
                ])),

                const SizedBox(height: 16),

                // BOTTOM: Preview + buttons
                _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Flexible(child: Text('Live CV Preview', style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500, color: _text))),
                    GestureDetector(
                      onTap: _downloadPdf,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: _accent.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Text('⬇ Download PDF',
                            style: TextStyle(fontSize: 11, color: _accent, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // White CV preview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_pName, style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0A35CC))),
                      Text(_pRole, style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
                      Text('📧 $_pContact', style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                      const SizedBox(height: 12),
                      _cvSection('SKILLS'),
                      Text(_pSkills, style: const TextStyle(fontSize: 12, color: Color(0xFF333333), height: 1.6)),
                      _cvSection('EDUCATION'),
                      Text(_pEdu, style: const TextStyle(fontSize: 12, color: Color(0xFF333333), height: 1.6)),
                      _cvSection('PROJECTS'),
                      ..._pProjects.map((p) {
                        final parts = p.split('—');
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: RichText(text: TextSpan(
                            style: const TextStyle(fontSize: 12, color: Color(0xFF333333), height: 1.6),
                            children: [
                              const TextSpan(text: '• '),
                              TextSpan(text: parts[0].trim(),
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              if (parts.length > 1)
                                TextSpan(text: ' — ${parts[1].trim()}'),
                            ],
                          )),
                        );
                      }),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // AI Improve btn
                  GestureDetector(
                    onTap: _improving ? null : _aiImprove,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _improving ? _accent.withOpacity(0.5) : _accent,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(child: _improving
                          ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF07080F)))
                          : const Text('🤖 AI Improve Resume', style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF07080F)))),
                    ),
                  ),
                ])),

              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cvSection(String title) => Container(
    margin: const EdgeInsets.only(top: 12, bottom: 6),
    padding: const EdgeInsets.only(bottom: 3),
    decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF0A35CC), width: 1.5))),
    child: Text(title, style: const TextStyle(
        fontSize: 9, fontWeight: FontWeight.w800,
        letterSpacing: 1.2, color: Color(0xFF0A35CC))),
  );

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
        color: _bg2, border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(16)),
    child: child,
  );

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1, String hint = ''}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5)),
          const SizedBox(height: 5),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            style: const TextStyle(color: _text, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0x40FFFFFF), fontSize: 12),
              filled: true, fillColor: const Color(0x0DFFFFFF),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _primary)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            ),
          ),
        ]),
      );
}