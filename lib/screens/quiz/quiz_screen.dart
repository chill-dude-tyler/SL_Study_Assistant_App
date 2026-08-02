// lib/screens/quiz/quiz_screen.dart
// Full quiz-taking experience with timer, answer tracking, and result.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/quiz.dart';
import '../../providers/quiz_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class QuizScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizScreen({super.key, required this.quiz});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  final Map<String, String> _answers = {};
  final TextEditingController _textCtrl = TextEditingController();
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _remainingSeconds = 0;
  bool _submitted = false;
  bool _answerRevealed = false;

  Quiz get quiz => widget.quiz;
  QuizQuestion get currentQuestion => quiz.questions[_currentIndex];
  bool get isLastQuestion => _currentIndex == quiz.questions.length - 1;

  @override
  void initState() {
    super.initState();
    if (quiz.timeLimit > 0) {
      _remainingSeconds = quiz.timeLimit;
    }
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _elapsedSeconds++;
        if (quiz.timeLimit > 0) {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            _submitQuiz();
          }
        }
      });
    });
  }

  void _selectAnswer(String answer) {
    if (_submitted) return;
    setState(() {
      _answers[currentQuestion.id] = answer;
      _answerRevealed = false;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < quiz.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _textCtrl.clear();
        _answerRevealed = false;
      });
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _textCtrl.text = _answers[currentQuestion.id] ?? '';
        _answerRevealed = false;
      });
    }
  }

  Future<void> _submitQuiz() async {
    _timer?.cancel();

    // Calculate score
    int score = 0;
    for (final q in quiz.questions) {
      final userAnswer = _answers[q.id] ?? '';
      if (userAnswer.toLowerCase().trim() ==
          q.correctAnswer.toLowerCase().trim()) {
        score += q.marks;
      }
    }

    final totalMarks = quiz.totalMarks;
    final percentage = totalMarks > 0 ? (score / totalMarks) * 100 : 0.0;

    // Analyze weak areas
    final weakAreas = <String>{};
    for (final q in quiz.questions) {
      final userAnswer = _answers[q.id] ?? '';
      if (userAnswer.toLowerCase().trim() !=
          q.correctAnswer.toLowerCase().trim()) {
        weakAreas.add(q.difficulty.name);
      }
    }

    final result = QuizResult(
      id: Helpers.generateId(),
      quizId: quiz.id,
      score: score,
      totalMarks: totalMarks,
      percentage: percentage,
      timeTaken: _elapsedSeconds,
      answers: Map<String, String>.from(_answers),
      weakAreas: weakAreas.toList(),
      completedAt: DateTime.now(),
    );

    await context.read<QuizProvider>().saveResult(result);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            quiz: quiz,
            result: result,
            answers: _answers,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = currentQuestion;
    final progress = (_currentIndex + 1) / quiz.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(quiz.title, overflow: TextOverflow.ellipsis),
        actions: [
          // Timer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _remainingSeconds < 60 && quiz.timeLimit > 0
                      ? AppTheme.errorColor.withOpacity(0.15)
                      : AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: _remainingSeconds < 60 && quiz.timeLimit > 0
                          ? AppTheme.errorColor
                          : AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      quiz.timeLimit > 0
                          ? Helpers.formatDuration(_remainingSeconds)
                          : Helpers.formatDuration(_elapsedSeconds),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _remainingSeconds < 60 && quiz.timeLimit > 0
                            ? AppTheme.errorColor
                            : AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.surface,
            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
            minHeight: 4,
          ),

          // Question counter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentIndex + 1} of ${quiz.questions.length}',
                  style: theme.textTheme.bodyMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _difficultyColor(q.difficulty).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    q.difficulty.name.toUpperCase(),
                    style: TextStyle(
                      color: _difficultyColor(q.difficulty),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Question content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question text
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        q.questionText,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Answer input based on type
                  _buildAnswerSection(q, theme),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Navigation buttons
          _buildNavButtons(theme),
        ],
      ),
    );
  }

  Widget _buildAnswerSection(QuizQuestion q, ThemeData theme) {
    switch (q.questionType) {
      case QuestionType.mcq:
      case QuestionType.trueFalse:
        return Column(
          children: (q.options ?? []).map((option) {
            final selected = _answers[q.id] == option;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _selectAnswer(option),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppTheme.primaryColor
                          : theme.colorScheme.onSurface.withOpacity(0.15),
                      width: selected ? 2 : 1,
                    ),
                    color: selected
                        ? AppTheme.primaryColor.withOpacity(0.08)
                        : theme.cardTheme.color,
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? AppTheme.primaryColor
                                : theme.colorScheme.onSurface.withOpacity(0.3),
                            width: 2,
                          ),
                          color: selected
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                        ),
                        child: selected
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );

      case QuestionType.fillBlank:
      case QuestionType.shortAnswer:
        return TextField(
          controller: _textCtrl,
          decoration: InputDecoration(
            hintText: q.questionType == QuestionType.fillBlank
                ? 'Enter the missing word...'
                : 'Write your answer...',
          ),
          maxLines: q.questionType == QuestionType.shortAnswer ? 4 : 1,
          onChanged: (value) => _selectAnswer(value),
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildNavButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousQuestion,
                child: const Text('Previous'),
              ),
            ),
          if (_currentIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isLastQuestion
                  ? () async {
                      final confirmed = await Helpers.showConfirmDialog(
                        context,
                        title: 'Submit Quiz',
                        content:
                            'You answered ${_answers.length}/${quiz.questions.length} questions. Submit?',
                        confirmText: 'Submit',
                      );
                      if (confirmed) _submitQuiz();
                    }
                  : _nextQuestion,
              child: Text(isLastQuestion ? 'Submit' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  Color _difficultyColor(QuizDifficulty d) {
    switch (d) {
      case QuizDifficulty.easy: return AppTheme.successColor;
      case QuizDifficulty.hard: return AppTheme.errorColor;
      default: return AppTheme.warningColor;
    }
  }
}

// ─── Quiz Result Screen ───────────────────────────────────────────────────────

class QuizResultScreen extends StatelessWidget {
  final Quiz quiz;
  final QuizResult result;
  final Map<String, String> answers;

  const QuizResultScreen({
    super.key,
    required this.quiz,
    required this.result,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradeColor = _gradeColor(result.grade);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Result'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Score circle
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      gradeColor.withOpacity(0.2),
                      gradeColor.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(color: gradeColor, width: 4),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      result.grade,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: gradeColor,
                      ),
                    ),
                    Text(
                      '${result.percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: gradeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stats row
            Row(
              children: [
                _StatTile(
                  icon: Icons.check_circle_outline,
                  label: 'Score',
                  value: '${result.score}/${result.totalMarks}',
                  color: AppTheme.successColor,
                ),
                const SizedBox(width: 12),
                _StatTile(
                  icon: Icons.timer_outlined,
                  label: 'Time',
                  value: Helpers.formatDuration(result.timeTaken),
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Review answers
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Review Answers',
                  style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: 12),

            ...quiz.questions.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value;
              final userAnswer = answers[q.id] ?? '(not answered)';
              final isCorrect = userAnswer.toLowerCase().trim() ==
                  q.correctAnswer.toLowerCase().trim();

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCorrect
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: isCorrect
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Q${i + 1}',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        Helpers.truncate(q.questionText, 100),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      if (!isCorrect)
                        Text(
                          'Your answer: $userAnswer',
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        'Correct: ${q.correctAnswer}',
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (q.explanation != null && !isCorrect) ...[
                        const SizedBox(height: 4),
                        Text(
                          q.explanation!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Quizzes'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(quiz: quiz),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A': return AppTheme.successColor;
      case 'B': return AppTheme.primaryColor;
      case 'C': return AppTheme.warningColor;
      case 'S': return const Color(0xFF6366F1);
      default: return AppTheme.errorColor;
    }
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
