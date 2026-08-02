// lib/models/quiz.dart

import 'dart:convert';

enum QuestionType { mcq, trueFalse, fillBlank, shortAnswer, matching }
enum QuizDifficulty { easy, medium, hard }

class QuizQuestion {
  final String id;
  final String quizId;
  final String questionText;
  final QuestionType questionType;
  final List<String>? options; // for MCQ
  final String correctAnswer;
  final String? explanation;
  final QuizDifficulty difficulty;
  final int marks;
  final int orderIndex;

  QuizQuestion({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.questionType,
    this.options,
    required this.correctAnswer,
    this.explanation,
    this.difficulty = QuizDifficulty.medium,
    this.marks = 1,
    this.orderIndex = 0,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'],
      quizId: map['quiz_id'],
      questionText: map['question_text'],
      questionType: QuestionType.values.firstWhere(
        (t) => t.name == map['question_type'],
        orElse: () => QuestionType.mcq,
      ),
      options: map['options'] != null
          ? List<String>.from(jsonDecode(map['options']))
          : null,
      correctAnswer: map['correct_answer'],
      explanation: map['explanation'],
      difficulty: QuizDifficulty.values.firstWhere(
        (d) => d.name == map['difficulty'],
        orElse: () => QuizDifficulty.medium,
      ),
      marks: map['marks'] ?? 1,
      orderIndex: map['order_index'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question_text': questionText,
      'question_type': questionType.name,
      'options': options != null ? jsonEncode(options) : null,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'difficulty': difficulty.name,
      'marks': marks,
      'order_index': orderIndex,
    };
  }
}

class Quiz {
  final String id;
  final String title;
  final String subject;
  final String? sourceId;
  final String? sourceType;
  final QuizDifficulty difficulty;
  final String language;
  final int timeLimit; // seconds, 0 = no limit
  final int totalQuestions;
  final DateTime createdAt;
  List<QuizQuestion> questions;

  Quiz({
    required this.id,
    required this.title,
    required this.subject,
    this.sourceId,
    this.sourceType,
    this.difficulty = QuizDifficulty.medium,
    this.language = 'en',
    this.timeLimit = 0,
    this.totalQuestions = 0,
    required this.createdAt,
    this.questions = const [],
  });

  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      id: map['id'],
      title: map['title'],
      subject: map['subject'],
      sourceId: map['source_id'],
      sourceType: map['source_type'],
      difficulty: QuizDifficulty.values.firstWhere(
        (d) => d.name == map['difficulty'],
        orElse: () => QuizDifficulty.medium,
      ),
      language: map['language'] ?? 'en',
      timeLimit: map['time_limit'] ?? 0,
      totalQuestions: map['total_questions'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'source_id': sourceId,
      'source_type': sourceType,
      'difficulty': difficulty.name,
      'language': language,
      'time_limit': timeLimit,
      'total_questions': totalQuestions,
      'created_at': createdAt.toIso8601String(),
    };
  }

  int get totalMarks =>
      questions.fold(0, (sum, q) => sum + q.marks);
}

class QuizResult {
  final String id;
  final String quizId;
  final int score;
  final int totalMarks;
  final double percentage;
  final int timeTaken; // seconds
  final Map<String, String> answers; // questionId -> answer
  final List<String> weakAreas;
  final DateTime completedAt;

  QuizResult({
    required this.id,
    required this.quizId,
    required this.score,
    required this.totalMarks,
    required this.percentage,
    required this.timeTaken,
    required this.answers,
    this.weakAreas = const [],
    required this.completedAt,
  });

  factory QuizResult.fromMap(Map<String, dynamic> map) {
    return QuizResult(
      id: map['id'],
      quizId: map['quiz_id'],
      score: map['score'],
      totalMarks: map['total_marks'],
      percentage: map['percentage'],
      timeTaken: map['time_taken'],
      answers: Map<String, String>.from(jsonDecode(map['answers'] ?? '{}')),
      weakAreas: map['weak_areas'] != null
          ? List<String>.from(jsonDecode(map['weak_areas']))
          : [],
      completedAt: DateTime.parse(map['completed_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quiz_id': quizId,
      'score': score,
      'total_marks': totalMarks,
      'percentage': percentage,
      'time_taken': timeTaken,
      'answers': jsonEncode(answers),
      'weak_areas': jsonEncode(weakAreas),
      'completed_at': completedAt.toIso8601String(),
    };
  }

  String get grade {
    if (percentage >= 75) return 'A';
    if (percentage >= 65) return 'B';
    if (percentage >= 55) return 'C';
    if (percentage >= 35) return 'S';
    return 'F';
  }
}
