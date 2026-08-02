// FILE: lib/screens/quiz/quiz_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/quiz.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/notes_provider.dart';
import '../../services/quiz_generator_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state.dart';
import 'quiz_screen.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});
  @override State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().loadQuizzes();
      context.read<QuizProvider>().loadResults();
    });
  }

  Future<void> _generateQuiz() async {
    // Pick a note to generate from
    final notes = context.read<NotesProvider>().notes;
    if (notes.isEmpty) {
      Helpers.showSnackBar(context, 'Upload a note first to generate a quiz', isError: true);
      return;
    }

    String? sourceText;
    String title = 'My Quiz';
    String subject = AppConstants.subjects.first;
    int qCount = AppConstants.defaultQuestionsPerQuiz;
    QuizDifficulty difficulty = QuizDifficulty.medium;
    bool timed = false;

    // Show config dialog
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _GenerateDialog(
        notes: notes,
        onConfirm: (text, t, s, q, d, tm) {
          sourceText = text; title = t; subject = s; qCount = q; difficulty = d; timed = tm;
        },
      ),
    );
    if (ok != true || sourceText == null) return;

    setState(() => _generating = true);
    try {
      final quiz = await QuizGeneratorService().generateFromText(
        text: sourceText!,
        title: title,
        subject: subject,
        difficulty: difficulty,
        questionCount: qCount,
        timeLimit: timed ? AppConstants.defaultQuizTimeLimit : 0,
      );
      final saved = await context.read<QuizProvider>().saveQuiz(quiz);
      if (saved && mounted) {
        Helpers.showSnackBar(context, 'Quiz "${quiz.title}" created with ${quiz.questions.length} questions!');
      }
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Generation failed: $e', isError: true);
    } finally {
      setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<QuizProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Quizzes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generating ? null : _generateQuiz,
        icon: _generating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome),
        label: Text(_generating ? 'Generating...' : 'Generate Quiz'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : prov.quizzes.isEmpty
              ? EmptyState(
                  icon: Icons.quiz_outlined,
                  title: 'No quizzes yet',
                  subtitle: 'Generate a quiz from your notes or textbooks',
                  buttonLabel: 'Generate Quiz',
                  onButtonTap: _generateQuiz,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
                  itemCount: prov.quizzes.length,
                  itemBuilder: (_, i) => _QuizCard(quiz: prov.quizzes[i]),
                ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final Quiz quiz;
  const _QuizCard({required this.quiz});

  Color _diffColor(QuizDifficulty d) {
    switch (d) {
      case QuizDifficulty.easy: return AppTheme.successColor;
      case QuizDifficulty.hard: return AppTheme.errorColor;
      default: return AppTheme.warningColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Helpers.getSubjectColor(quiz.subject);
    final diffColor = _diffColor(quiz.difficulty);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => QuizScreen(quiz: quiz)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.quiz, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(quiz.title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 15),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(quiz.subject, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: diffColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(quiz.difficulty.name.toUpperCase(),
                      style: TextStyle(color: diffColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                Text('${quiz.totalQuestions} Qs', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
                if (quiz.timeLimit > 0) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.timer_outlined, size: 12, color: theme.textTheme.bodyMedium?.color),
                  Text(Helpers.formatDuration(quiz.timeLimit), style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
                ],
              ]),
            ])),
            Column(children: [
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(quiz: quiz))),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                child: const Text('Start', style: TextStyle(fontSize: 13)),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () async {
                  final ok = await Helpers.showConfirmDialog(context,
                      title: 'Delete Quiz', content: 'Delete "${quiz.title}"?',
                      confirmText: 'Delete', isDestructive: true);
                  if (ok && context.mounted) context.read<QuizProvider>().deleteQuiz(quiz.id);
                },
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ─── Generate Quiz Dialog ─────────────────────────────────────────────────────
class _GenerateDialog extends StatefulWidget {
  final List notes;
  final void Function(String text, String title, String subject, int qCount, QuizDifficulty diff, bool timed) onConfirm;
  const _GenerateDialog({required this.notes, required this.onConfirm});
  @override State<_GenerateDialog> createState() => __GenerateDialogState();
}

class __GenerateDialogState extends State<_GenerateDialog> {
  int _noteIndex = 0;
  final _titleCtrl = TextEditingController(text: 'Quiz');
  int _qCount = 10;
  QuizDifficulty _diff = QuizDifficulty.medium;
  bool _timed = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate Quiz'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<int>(
            value: _noteIndex,
            decoration: const InputDecoration(labelText: 'Source Note'),
            items: widget.notes.asMap().entries.map((e) =>
                DropdownMenuItem(value: e.key, child: Text(e.value.title, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => setState(() => _noteIndex = v!),
          ),
          const SizedBox(height: 10),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Quiz Title')),
          const SizedBox(height: 10),
          Row(children: [
            const Text('Questions: '),
            Expanded(child: Slider(
              value: _qCount.toDouble(), min: 5, max: 30, divisions: 5,
              label: '$_qCount',
              onChanged: (v) => setState(() => _qCount = v.round()),
            )),
            Text('$_qCount'),
          ]),
          const SizedBox(height: 6),
          DropdownButtonFormField<QuizDifficulty>(
            value: _diff,
            decoration: const InputDecoration(labelText: 'Difficulty'),
            items: QuizDifficulty.values.map((d) => DropdownMenuItem(value: d,
                child: Text(d.name[0].toUpperCase() + d.name.substring(1)))).toList(),
            onChanged: (v) => setState(() => _diff = v!),
          ),
          SwitchListTile(
            title: const Text('Timed Mode'),
            value: _timed,
            onChanged: (v) => setState(() => _timed = v),
            contentPadding: EdgeInsets.zero,
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final note = widget.notes[_noteIndex];
            widget.onConfirm(
              note.extractedText ?? note.title,
              _titleCtrl.text.trim().isEmpty ? 'Quiz' : _titleCtrl.text.trim(),
              note.subject, _qCount, _diff, _timed,
            );
            Navigator.pop(context, true);
          },
          child: const Text('Generate'),
        ),
      ],
    );
  }
}
