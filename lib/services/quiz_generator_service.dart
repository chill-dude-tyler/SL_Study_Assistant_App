// lib/services/quiz_generator_service.dart
// Rule-based quiz generator. Analyzes extracted text and creates questions.
// Modular design allows plugging in local AI models in future.

import '../models/quiz.dart';
import '../utils/helpers.dart';

class QuizGeneratorService {
  static final QuizGeneratorService _instance = QuizGeneratorService._();
  factory QuizGeneratorService() => _instance;
  QuizGeneratorService._();

  /// Generate a complete quiz from text content
  Future<Quiz> generateFromText({
    required String text,
    required String title,
    required String subject,
    QuizDifficulty difficulty = QuizDifficulty.medium,
    int questionCount = 10,
    String language = 'en',
    String? sourceId,
    String? sourceType,
  }) async {
    final questions = <QuizQuestion>[];
    final quizId = Helpers.generateId();

    // Extract sentences for question generation
    final sentences = _extractSentences(text);
    final keywords = _extractKeywords(text);
    final definitions = _extractDefinitions(text);

    // Mix different question types
    final mcqCount = (questionCount * 0.5).round();
    final tfCount = (questionCount * 0.3).round();
    final fillCount = questionCount - mcqCount - tfCount;

    // Generate MCQs
    questions.addAll(
      _generateMCQs(sentences, keywords, quizId, mcqCount, difficulty),
    );

    // Generate True/False
    questions.addAll(
      _generateTrueFalse(sentences, quizId, tfCount, difficulty),
    );

    // Generate Fill in the Blanks
    questions.addAll(
      _generateFillBlanks(definitions, keywords, quizId, fillCount, difficulty),
    );

    // Shuffle questions
    questions.shuffle();

    // Set order index
    for (var i = 0; i < questions.length; i++) {
      // Questions are final so we recreate with order
    }

    final quiz = Quiz(
      id: quizId,
      title: title,
      subject: subject,
      sourceId: sourceId,
      sourceType: sourceType,
      difficulty: difficulty,
      language: language,
      totalQuestions: questions.length,
      createdAt: DateTime.now(),
      questions: questions,
    );

    return quiz;
  }

  // ─── Text Processing ──────────────────────────────────────────────────────

  List<String> _extractSentences(String text) {
    // Split on sentence boundaries
    final rawSentences = text
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.length > 30 && s.split(' ').length > 5)
        .toList();

    return rawSentences.take(100).toList();
  }

  List<String> _extractKeywords(String text) {
    // Simple keyword extraction: find capitalized words and frequently used terms
    final words = text
        .split(RegExp(r'\s+'))
        .map((w) => w.replaceAll(RegExp(r'[^\w]'), ''))
        .where((w) => w.length > 4)
        .toList();

    // Count frequency
    final freq = <String, int>{};
    for (final word in words) {
      freq[word.toLowerCase()] = (freq[word.toLowerCase()] ?? 0) + 1;
    }

    // Return top keywords by frequency
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(50).map((e) => e.key).toList();
  }

  Map<String, String> _extractDefinitions(String text) {
    // Look for "X is Y", "X refers to Y", "X means Y" patterns
    final definitions = <String, String>{};
    final patterns = [
      RegExp(r'(\w+(?:\s\w+)?)\s+is\s+([^.]+)', caseSensitive: false),
      RegExp(r'(\w+(?:\s\w+)?)\s+refers to\s+([^.]+)', caseSensitive: false),
      RegExp(r'(\w+(?:\s\w+)?)\s+means\s+([^.]+)', caseSensitive: false),
      RegExp(r'(\w+(?:\s\w+)?)\s+is defined as\s+([^.]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches.take(20)) {
        final term = match.group(1)?.trim() ?? '';
        final def = match.group(2)?.trim() ?? '';
        if (term.isNotEmpty && def.isNotEmpty && term.length < 50) {
          definitions[term] = def;
        }
      }
    }

    return definitions;
  }

  // ─── MCQ Generation ───────────────────────────────────────────────────────

  List<QuizQuestion> _generateMCQs(
    List<String> sentences,
    List<String> keywords,
    String quizId,
    int count,
    QuizDifficulty difficulty,
  ) {
    final questions = <QuizQuestion>[];
    final used = <int>{};

    for (var i = 0; i < sentences.length && questions.length < count; i++) {
      if (used.contains(i)) continue;

      final sentence = sentences[i];
      final words = sentence.split(' ');

      // Find a "important" word to blank out (nouns, keywords)
      int targetIndex = -1;
      for (var j = 0; j < words.length; j++) {
        final w = words[j].replaceAll(RegExp(r'[^\w]'), '');
        if (w.length > 4 && keywords.contains(w.toLowerCase())) {
          targetIndex = j;
          break;
        }
      }

      if (targetIndex == -1) continue;

      final correctWord =
          words[targetIndex].replaceAll(RegExp(r'[^\w]'), '');
      if (correctWord.isEmpty) continue;

      // Generate distractors from keywords
      final distractors = keywords
          .where((k) => k.toLowerCase() != correctWord.toLowerCase())
          .take(3)
          .toList();

      if (distractors.length < 3) continue;

      final options = [correctWord, ...distractors]..shuffle();

      questions.add(QuizQuestion(
        id: Helpers.generateId(),
        quizId: quizId,
        questionText:
            'Which word correctly completes the following statement?\n\n"${sentence.replaceFirst(words[targetIndex], '______')}"',
        questionType: QuestionType.mcq,
        options: options,
        correctAnswer: correctWord,
        explanation:
            'The correct answer is "$correctWord". This can be found in the study material.',
        difficulty: difficulty,
        marks: difficulty == QuizDifficulty.hard ? 2 : 1,
        orderIndex: questions.length,
      ));

      used.add(i);
    }

    return questions;
  }

  // ─── True/False Generation ────────────────────────────────────────────────

  List<QuizQuestion> _generateTrueFalse(
    List<String> sentences,
    String quizId,
    int count,
    QuizDifficulty difficulty,
  ) {
    final questions = <QuizQuestion>[];

    for (var i = 0; i < sentences.length && questions.length < count; i++) {
      final sentence = sentences[i];
      if (sentence.length < 40) continue;

      final isTrue = questions.length % 2 == 0;
      String questionText;

      if (isTrue) {
        // Use original sentence as true statement
        questionText = sentence;
      } else {
        // Modify sentence to make it false by replacing a keyword
        final words = sentence.split(' ');
        final word = words.firstWhere(
          (w) => w.length > 4,
          orElse: () => '',
        );
        questionText = word.isNotEmpty
            ? sentence.replaceFirst(word, 'NOT $word')
            : sentence;
      }

      questions.add(QuizQuestion(
        id: Helpers.generateId(),
        quizId: quizId,
        questionText: 'True or False: $questionText',
        questionType: QuestionType.trueFalse,
        options: ['True', 'False'],
        correctAnswer: isTrue ? 'True' : 'False',
        explanation: isTrue
            ? 'This statement is TRUE based on the study material.'
            : 'This statement is FALSE.',
        difficulty: difficulty,
        marks: 1,
        orderIndex: questions.length,
      ));
    }

    return questions;
  }

  // ─── Fill in Blanks Generation ────────────────────────────────────────────

  List<QuizQuestion> _generateFillBlanks(
    Map<String, String> definitions,
    List<String> keywords,
    String quizId,
    int count,
    QuizDifficulty difficulty,
  ) {
    final questions = <QuizQuestion>[];
    final entries = definitions.entries.take(count).toList();

    for (final entry in entries) {
      questions.add(QuizQuestion(
        id: Helpers.generateId(),
        quizId: quizId,
        questionText:
            'Fill in the blank:\n\n"______ ${entry.value}"',
        questionType: QuestionType.fillBlank,
        correctAnswer: entry.key,
        explanation:
            '"${entry.key}" ${entry.value}',
        difficulty: difficulty,
        marks: difficulty == QuizDifficulty.hard ? 2 : 1,
        orderIndex: questions.length,
      ));
    }

    // If not enough definitions, generate from keywords
    if (questions.length < count) {
      for (final kw in keywords.take(count - questions.length)) {
        questions.add(QuizQuestion(
          id: Helpers.generateId(),
          quizId: quizId,
          questionText:
              'Complete the term: "${kw.substring(0, kw.length ~/ 2)}______"',
          questionType: QuestionType.fillBlank,
          correctAnswer: kw,
          difficulty: difficulty,
          marks: 1,
          orderIndex: questions.length,
        ));
      }
    }

    return questions;
  }

  /// Generate flashcards from text
  Future<List<Map<String, String>>> generateFlashcardPairs(
    String text,
    int count,
  ) async {
    final pairs = <Map<String, String>>[];
    final definitions = _extractDefinitions(text);
    final sentences = _extractSentences(text);

    // Use definitions first
    for (final entry in definitions.entries.take(count)) {
      pairs.add({'front': 'What is ${entry.key}?', 'back': entry.value});
    }

    // Fill rest with key sentences
    for (final sentence in sentences.take(count - pairs.length)) {
      final words = sentence.split(' ');
      if (words.length > 6) {
        pairs.add({
          'front': words.take(words.length ~/ 2).join(' ') + '...',
          'back': sentence,
        });
      }
    }

    return pairs.take(count).toList();
  }
}
