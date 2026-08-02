// FILE: lib/providers/textbook_provider.dart

import 'package:flutter/material.dart';
import '../models/textbook.dart';
import '../database/database_helper.dart';

class TextbookProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Textbook> _textbooks = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedSubject = 'All';

  List<Textbook> get textbooks => _filtered;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedSubject => _selectedSubject;

  List<Textbook> get _filtered {
    var list = _textbooks;
    if (_selectedSubject != 'All') {
      list = list.where((t) => t.subject == _selectedSubject).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.subject.toLowerCase().contains(q) ||
              (t.grade?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return list;
  }

  List<String> get subjects {
    final s = _textbooks.map((t) => t.subject).toSet().toList()..sort();
    return ['All', ...s];
  }

  Future<void> loadTextbooks() async {
    _isLoading = true;
    notifyListeners();
    try {
      final maps = await _db.query(
        DatabaseHelper.tableTextbooks,
        orderBy: 'updated_at DESC',
      );
      _textbooks = maps.map((m) => Textbook.fromMap(m)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTextbook(Textbook tb) async {
    try {
      await _db.insert(DatabaseHelper.tableTextbooks, tb.toMap());
      _textbooks.insert(0, tb);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<void> updateProgress(String id, int page) async {
    final i = _textbooks.indexWhere((t) => t.id == id);
    if (i == -1) return;
    await _db.update(
      DatabaseHelper.tableTextbooks,
      {'current_page': page, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    // Rebuild immutable object with updated page
    final old = _textbooks[i];
    _textbooks[i] = Textbook(
      id: old.id,
      title: old.title,
      subject: old.subject,
      grade: old.grade,
      filePath: old.filePath,
      fileType: old.fileType,
      fileSize: old.fileSize,
      totalPages: old.totalPages,
      currentPage: page,
      language: old.language,
      publisher: old.publisher,
      year: old.year,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<bool> deleteTextbook(String id) async {
    try {
      await _db.delete(DatabaseHelper.tableTextbooks,
          where: 'id = ?', whereArgs: [id]);
      _textbooks.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setSubjectFilter(String s) {
    _selectedSubject = s;
    notifyListeners();
  }
}
