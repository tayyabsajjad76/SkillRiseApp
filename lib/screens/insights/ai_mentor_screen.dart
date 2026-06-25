import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/ai_service.dart';

class AiMentorScreen extends StatefulWidget {
  const AiMentorScreen({Key? key}) : super(key: key);
  @override
  State<AiMentorScreen> createState() => _AiMentorScreenState();
}

class _AiMentorScreenState extends State<AiMentorScreen> {
  final _controller       = TextEditingController();
  final _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  String _userName      = '';
  String _userGoal      = '';
  String _userInterests = '';
  String _userDegree    = '';

  final List<String> _quickPrompts = [
    '💡 What should I study today?',
    '🔥 Give me a motivational boost!',
    '🎯 Am I on track for my goal?',
    '🎤 Common interview questions?',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserAndInit();
  }

  Future<void> _loadUserAndInit() async {
    final uid = AuthService.getUid();
    if (uid == null) return;
    final doc  = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    _userName      = data['name']?.toString() ?? 'there';
    _userGoal      = data['goal']?.toString() ?? '';
    _userDegree    = data['degree']?.toString() ?? '';
    _userInterests = (data['interests'] as List?)?.join(', ') ?? '';
    setState(() {
      _messages.add(_ChatMessage(
        text: '👋 Hey ${_userName.split(' ').first}! I\'m your AI Mentor. Ask me anything about your learning, career, or get a motivational boost!',
        isUser: false,
      ));
    });
  }

  String get _systemPrompt => '''
You are SR-AI Mentor, a friendly and encouraging AI learning companion.

Student profile:
- Name: $_userName
- Degree: $_userDegree
- Goal: $_userGoal
- Interests: $_userInterests

Your role:
- Give personalized advice based on their profile
- Be encouraging, concise, and practical
- Keep responses under 100 words
- Use emojis occasionally to be friendly
- Always relate advice to their specific goal and interests
''';

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text.trim(), isUser: true));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();
    try {
      final history = _messages
          .where((m) => m.text != _messages.first.text)
          .map((m) => '${m.isUser ? "User" : "Mentor"}: ${m.text}')
          .join('\n');
      final prompt = '$_systemPrompt\n\nConversation so far:\n$history\n\nRespond to the latest message. Be helpful, concise, encouraging.';
      final response = await AIService.ask(prompt);
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: response.trim(), isUser: false));
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(const _ChatMessage(text: 'Sorry, I had trouble responding. Please try again! 🙏', isUser: false));
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF07080F),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header (fixed) ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('AI MENTOR CHAT', style: TextStyle(
                color: Color(0xFF1A56FF), fontSize: 10,
                fontWeight: FontWeight.w700, letterSpacing: 1.4)),
            const SizedBox(height: 6),
            const Text('Your 24/7 AI Companion', style: TextStyle(
                color: Color(0xFFF0F4FF), fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            const Text('Ask anything — learning, career, or motivation.',
                style: TextStyle(color: Color(0x6BFFFFFF), fontSize: 13, height: 1.5)),
          ]),
        ),

        // ── Chat box (Expanded — takes all remaining space) ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D1120),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x12FFFFFF)),
              ),
              child: Column(children: [
                // Chat header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0x12FFFFFF)))),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                          color: const Color(0xFF1E40AF),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Center(child: Text('🤖', style: TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 12),
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text('SR-AI Mentor', style: TextStyle(color: Color(0xFFF0F4FF), fontSize: 15, fontWeight: FontWeight.w600)),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.circle, color: Color(0xFF10B981), size: 9),
                        SizedBox(width: 4),
                        Text('Online', style: TextStyle(color: Color(0xFF10B981), fontSize: 12)),
                      ]),
                    ]),
                  ]),
                ),

                // Messages list — Expanded fills space
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (_isTyping && i == _messages.length) return _TypingIndicator();
                      return _ChatBubble(message: _messages[i]);
                    },
                  ),
                ),

                // Input bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0x12FFFFFF)))),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Color(0xFFF0F4FF), fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Ask your AI mentor anything...',
                          hintStyle: TextStyle(color: Color(0x6BFFFFFF), fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4),
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _sendMessage(_controller.text),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                            color: const Color(0xFF1A56FF),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.send, color: Colors.white, size: 18),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),

        // ── Quick prompts (fixed height at bottom) ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFF0D1120),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x12FFFFFF))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Quick Prompts', style: TextStyle(
                  color: Color(0xFFF0F4FF), fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              // 2x2 grid — saves vertical space
              Row(children: [
                Expanded(child: _promptBtn(_quickPrompts[0])),
                const SizedBox(width: 8),
                Expanded(child: _promptBtn(_quickPrompts[1])),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _promptBtn(_quickPrompts[2])),
                const SizedBox(width: 8),
                Expanded(child: _promptBtn(_quickPrompts[3])),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _promptBtn(String p) => GestureDetector(
    onTap: () => _sendMessage(p),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      decoration: BoxDecoration(
          color: const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x12FFFFFF))),
      child: Text(p, style: const TextStyle(color: Color(0xFFF0F4FF), fontSize: 12), textAlign: TextAlign.center),
    ),
  );
}

class _ChatMessage {
  final String text;
  final bool isUser;
  const _ChatMessage({required this.text, required this.isUser});
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
          mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser) ...[
              Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                      color: const Color(0xFF1E40AF),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Center(child: Text('🤖', style: TextStyle(fontSize: 15)))),
              const SizedBox(width: 8),
            ],
            Flexible(
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                        color: message.isUser ? const Color(0xFF1A56FF) : const Color(0xFF1C2333),
                        borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            topRight: const Radius.circular(14),
                            bottomLeft: Radius.circular(message.isUser ? 14 : 2),
                            bottomRight: Radius.circular(message.isUser ? 2 : 14))),
                    child: Text(message.text, style: const TextStyle(
                        color: Colors.white, fontSize: 14, height: 1.6)))),
          ]));
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
                color: const Color(0xFF1E40AF),
                borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 15)))),
        const SizedBox(width: 8),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: const Color(0xFF1C2333),
                borderRadius: BorderRadius.circular(12)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              _Dot(delay: 0),
              SizedBox(width: 4),
              _Dot(delay: 150),
              SizedBox(width: 4),
              _Dot(delay: 300),
            ])),
      ]));
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(_ctrl);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
      opacity: _anim,
      child: Container(width: 7, height: 7,
          decoration: const BoxDecoration(color: Colors.white54, shape: BoxShape.circle)));
}
