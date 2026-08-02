// lib/providers/notes_provider.dart

import 'package:flutter/material.dart';
import '../models/note.dart';
import '../database/database_helper.dart';

class NotesProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Note> _notes = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedSubject = 'All';

  List<Note> get notes => _filteredNotes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedSubject => _selectedSubject;

  List<Note> get _filteredNotes {
    var result = _notes;
    if (_selectedSubject != 'All') {
      result = result.where((n) => n.subject == _selectedSubject).toList();
    }
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((n) =>
              n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              n.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (n.extractedText?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
          .toList();
    }
    return result;
  }

  List<Note> get bookmarkedNotes =>
      _notes.where((n) => n.isBookmarked).toList();

  List<String> get subjects {
    final all = _notes.map((n) => n.subject).toSet().toList()..sort();
    return ['All', ...all];
  }

  Future<void> loadNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final maps = await _db.query(
        DatabaseHelper.tableNotes,
        orderBy: 'updated_at DESC',
      );
      _notes = maps.map((m) => Note.fromMap(m)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addNote(Note note) async {
    try {
      await _db.insert(DatabaseHelper.tableNotes, note.toMap());
      _notes.insert(0, note);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> updateNote(Note note) async {
    try {
      await _db.update(
        DatabaseHelper.tableNotes,
        note.toMap(),
        where: 'id = ?',
        whereArgs: [note.id],
      );
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) _notes[index] = note;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> deleteNote(String id) async {
    try {
      await _db.delete(
        DatabaseHelper.tableNotes,
        where: 'id = ?',
        whereArgs: [id],
      );
      _notes.removeWhere((n) => n.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<void> toggleBookmark(String id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final note = _notes[index].copyWith(
      isBookmarked: !_notes[index].isBookmarked,
    );
    await updateNote(note);
  }

  Future<void> updateLastOpened(String id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final note = _notes[index].copyWith(lastOpened: DateTime.now());
    await updateNote(note);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSubjectFilter(String subject) {
    _selectedSubject = subject;
    notifyListeners();
  }
}
