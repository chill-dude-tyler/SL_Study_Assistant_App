// lib/providers/flashcard_provider.dart

import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../database/database_helper.dart';
import '../utils/constants.dart';

class FlashcardProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Flashcard> _flashcards = [];
  bool _isLoading = false;

  List<Flashcard> get flashcards => _flashcards;
  bool get isLoading => _isLoading;

  Map<String, List<Flashcard>> get deckMap {
    final map = <String, List<Flashcard>>{};
    for (final card in _flashcards) {
      map.putIfAbsent(card.deckName, () => []).add(card);
    }
    return map;
  }

  List<Flashcard> get dueCards =>
      _flashcards.where((c) => c.isDueForReview).toList();

  Future<void> loadFlashcards() async {
    _isLoading = true;
    notifyListeners();

    try {
      final maps = await _db.query(
        DatabaseHelper.tableFlashcards,
        orderBy: 'created_at DESC',
      );
      _flashcards = maps.map((m) => Flashcard.fromMap(m)).toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addFlashcard(Flashcard card) async {
    try {
      await _db.insert(DatabaseHelper.tableFlashcards, card.toMap());
      _flashcards.insert(0, card);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> addMultiple(List<Flashcard> cards) async {
    for (final card in cards) {
      await _db.insert(DatabaseHelper.tableFlashcards, card.toMap());
    }
    _flashcards.insertAll(0, cards);
    notifyListeners();
  }

  Future<void> recordReview(String id, bool wasCorrect) async {
    final index = _flashcards.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final card = _flashcards[index];
    card.timesReviewed++;
    if (wasCorrect) card.timesCorrect++;

    // Update difficulty based on correctness
    if (wasCorrect) {
      card.difficulty = (card.difficulty > 0) ? card.difficulty - 1 : 0;
    } else {
      card.difficulty = (card.difficulty < 3) ? card.difficulty + 1 : 3;
    }

    // Calculate next review date
    final daysUntilReview =
        AppConstants.spacedRepetitionDays[card.difficulty] ?? 1;
    final nextReview =
        DateTime.now().add(Duration(days: daysUntilReview));

    await _db.update(
      DatabaseHelper.tableFlashcards,
      {
        'difficulty': card.difficulty,
        'times_reviewed': card.timesReviewed,
        'times_correct': card.timesCorrect,
        'last_reviewed': DateTime.now().toIso8601String(),
        'next_review': nextReview.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    notifyListeners();
  }

  Future<bool> deleteFlashcard(String id) async {
    try {
      await _db.delete(
        DatabaseHelper.tableFlashcards,
        where: 'id = ?',
        whereArgs: [id],
      );
      _flashcards.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteDeck(String deckName) async {
    await _db.delete(
      DatabaseHelper.tableFlashcards,
      where: 'deck_name = ?',
      whereArgs: [deckName],
    );
    _flashcards.removeWhere((c) => c.deckName == deckName);
    notifyListeners();
  }

  List<Flashcard> getCardsByDeck(String deckName) =>
      _flashcards.where((c) => c.deckName == deckName).toList();
}
