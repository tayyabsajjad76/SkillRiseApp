import 'package:flutter/material.dart';

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final List<QuizQuestion> _questions = [
    QuizQuestion(
      question: 'What does HTML stand for?',
      options: [
        'Hyper Text Markup Language',
        'High Tech Modern Language',
        'Hyper Transfer Markup Loader',
        'None of above',
      ],
      correctIndex: 0,
    ),
    QuizQuestion(
      question: 'Which widget is used for scrollable list in Flutter?',
      options: ['Column', 'Row', 'ListView', 'Stack'],
      correctIndex: 2,
    ),
    QuizQuestion(
      question: 'What is the purpose of "pubspec.yaml"?',
      options: [
        'Run the app',
        'Manage dependencies',
        'Store images',
        'Define routes',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      question: 'Which language does Flutter use?',
      options: ['Kotlin', 'Swift', 'Dart', 'Java'],
      correctIndex: 2,
    ),
    QuizQuestion(
      question: 'What does CSS stand for?',
      options: [
        'Computer Style Sheet',
        'Cascading Style Sheet',
        'Creative Style System',
        'Code Styling Script',
      ],
      correctIndex: 1,
    ),
  ];

  int _currentQuestion = 0;
  int? _selectedAnswer;
  bool _answered = false;
  int _score = 0;
  bool _quizDone = false;

  void _selectAnswer(int index) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (index == _questions[_currentQuestion].correctIndex) _score++;
    });
  }

  void _next() {
    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      setState(() => _quizDone = true);
    }
  }

  void _restart() {
    setState(() {
      _currentQuestion = 0;
      _selectedAnswer = null;
      _answered = false;
      _score = 0;
      _quizDone = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Weekly Quiz',
          style: TextStyle(
            color: Color(0xFF1E1B4B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _quizDone ? _buildResult() : _buildQuiz(),
    );
  }

  Widget _buildQuiz() {
    final q = _questions[_currentQuestion];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentQuestion + 1) / _questions.length,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF4F46E5)),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_currentQuestion + 1}/${_questions.length}',
                style: const TextStyle(
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Question ${_currentQuestion + 1}',
                    style: const TextStyle(
                      color: Color(0xFF4F46E5),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  q.question,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1B4B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(q.options.length, (i) => _buildOption(i, q)),
          const SizedBox(height: 16),
          if (_answered)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _currentQuestion == _questions.length - 1
                      ? 'See Results'
                      : 'Next Question',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOption(int i, QuizQuestion q) {
    Color borderColor = Colors.transparent;
    Color bgColor = Colors.white;
    Color textColor = const Color(0xFF1E1B4B);
    IconData? icon;

    if (_answered) {
      if (i == q.correctIndex) {
        borderColor = Colors.green;
        bgColor = Colors.green.withOpacity(0.08);
        textColor = Colors.green[700]!;
        icon = Icons.check_circle;
      } else if (i == _selectedAnswer) {
        borderColor = Colors.red;
        bgColor = Colors.red.withOpacity(0.08);
        textColor = Colors.red[700]!;
        icon = Icons.cancel;
      }
    } else if (_selectedAnswer == i) {
      borderColor = const Color(0xFF4F46E5);
      bgColor = const Color(0xFFEEF2FF);
      textColor = const Color(0xFF4F46E5);
    }

    return GestureDetector(
      onTap: () => _selectAnswer(i),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                q.options[i],
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            if (icon != null)
              Icon(
                icon,
                color: i == q.correctIndex ? Colors.green : Colors.red,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final pct = (_score / _questions.length * 100).toInt();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              pct >= 80 ? '🏆' : pct >= 50 ? '👍' : '😅',
              style: const TextStyle(fontSize: 72),
            ),
            const SizedBox(height: 16),
            Text(
              pct >= 80 ? 'Excellent!' : pct >= 50 ? 'Good Job!' : 'Keep Practicing!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You scored $_score out of ${_questions.length}',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 24),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$pct%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _restart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}