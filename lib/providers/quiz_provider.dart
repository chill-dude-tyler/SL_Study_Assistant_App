// lib/providers/quiz_provider.dart

import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../database/database_helper.dart';

class QuizProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Quiz> _quizzes = [];
  List<QuizResult> _results = [];
  bool _isLoading = false;

  List<Quiz> get quizzes => _quizzes;
  List<QuizResult> get results => _results;
  bool get isLoading => _isLoading;

  Future<void> loadQuizzes() async {
    _isLoading = true;
    notifyListeners();

    try {
      final maps = await _db.query(
        DatabaseHelper.tableQuizzes,
        orderBy: 'created_at DESC',
      );
      _quizzes = maps.map((m) => Quiz.fromMap(m)).toList();

      // Load questions for each quiz
      for (final quiz in _quizzes) {
        final qMaps = await _db.query(
          DatabaseHelper.tableQuizQuestions,
          where: 'quiz_id = ?',
          whereArgs: [quiz.id],
          orderBy: 'order_index ASC',
        );
        quiz.questions =
            qMaps.map((m) => QuizQuestion.fromMap(m)).toList();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveQuiz(Quiz quiz) async {
    try {
      await _db.insert(DatabaseHelper.tableQuizzes, quiz.toMap());
      for (final q in quiz.questions) {
        await _db.insert(DatabaseHelper.tableQuizQuestions, q.toMap());
      }
      _quizzes.insert(0, quiz);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> saveResult(QuizResult result) async {
    try {
      await _db.insert(DatabaseHelper.tableQuizResults, result.toMap());
      _results.insert(0, result);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadResults() async {
    final maps = await _db.query(
      DatabaseHelper.tableQuizResults,
      orderBy: 'completed_at DESC',
    );
    _results = maps.map((m) => QuizResult.fromMap(m)).toList();
    notifyListeners();
  }

  Future<List<QuizResult>> getResultsForQuiz(String quizId) async {
    final maps = await _db.query(
      DatabaseHelper.tableQuizResults,
      where: 'quiz_id = ?',
      whereArgs: [quizId],
      orderBy: 'completed_at DESC',
    );
    return maps.map((m) => QuizResult.fromMap(m)).toList();
  }

  Future<bool> deleteQuiz(String id) async {
    try {
      await _db.delete(
        DatabaseHelper.tableQuizzes,
        where: 'id = ?',
        whereArgs: [id],
      );
      _quizzes.removeWhere((q) => q.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  double get averageScore {
    if (_results.isEmpty) return 0;
    return _results.map((r) => r.percentage).reduce((a, b) => a + b) /
        _results.length;
  }
}
