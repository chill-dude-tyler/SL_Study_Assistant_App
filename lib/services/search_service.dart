// FILE: lib/services/search_service.dart
// Full-text search across all content types stored in SQLite.

import '../database/database_helper.dart';

enum SearchResultType { note, textbook, pastPaper, flashcard, quiz }

class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final SearchResultType type;
  final String? subject;

  SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.subject,
  });

  String get typeLabel {
    switch (type) {
      case SearchResultType.note:      return 'Note';
      case SearchResultType.textbook:  return 'Textbook';
      case SearchResultType.pastPaper: return 'Past Paper';
      case SearchResultType.flashcard: return 'Flashcard';
      case SearchResultType.quiz:      return 'Quiz';
    }
  }
}

class SearchService {
  static final SearchService _instance = SearchService._();
  factory SearchService() => _instance;
  SearchService._();

  final DatabaseHelper _db = DatabaseHelper();

  /// Search all content types for [query].
  Future<List<SearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final results = await _db.searchAll(query);
    return results.map((row) {
      final type = _parseType(row['type'] as String? ?? '');
      return SearchResult(
        id: row['id'] as String,
        title: row['title'] as String? ?? '',
        subtitle: row['subject'] as String? ?? '',
        type: type,
        subject: row['subject'] as String?,
      );
    }).toList();
  }

  /// Search within a specific type only.
  Future<List<SearchResult>> searchByType(
    String query,
    SearchResultType type,
  ) async {
    final all = await search(query);
    return all.where((r) => r.type == type).toList();
  }

  SearchResultType _parseType(String s) {
    switch (s) {
      case 'textbook':  return SearchResultType.textbook;
      case 'past_paper': return SearchResultType.pastPaper;
      case 'flashcard': return SearchResultType.flashcard;
      case 'quiz':      return SearchResultType.quiz;
      default:          return SearchResultType.note;
    }
  }
}
