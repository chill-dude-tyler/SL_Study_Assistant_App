// FILE: lib/providers/past_paper_provider.dart

import 'package:flutter/material.dart';
import '../models/past_paper.dart';
import '../database/database_helper.dart';

class PastPaperProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<PastPaper> _papers = [];
  bool _isLoading = false;

  // Active filters
  String _examType = 'All';   // All | ol | al
  String _subject  = 'All';
  int?   _year;
  String _language = 'All';

  List<PastPaper> get papers => _filtered;
  bool get isLoading => _isLoading;
  String get examTypeFilter => _examType;
  String get subjectFilter  => _subject;
  int?   get yearFilter     => _year;
  String get languageFilter => _language;

  List<PastPaper> get _filtered {
    var list = _papers;
    if (_examType != 'All') {
      list = list.where((p) => p.examType.name == _examType).toList();
    }
    if (_subject != 'All') {
      list = list.where((p) => p.subject == _subject).toList();
    }
    if (_year != null) {
      list = list.where((p) => p.year == _year).toList();
    }
    if (_language != 'All') {
      list = list.where((p) => p.language.name == _language).toList();
    }
    return list;
  }

  List<String> get subjects {
    final s = _papers.map((p) => p.subject).toSet().toList()..sort();
    return ['All', ...s];
  }

  List<int> get years {
    final y = _papers.map((p) => p.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return y;
  }

  Future<void> loadPapers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final maps = await _db.query(
        DatabaseHelper.tablePastPapers,
        orderBy: 'year DESC',
      );
      _papers = maps.map((m) => PastPaper.fromMap(m)).toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPaper(PastPaper paper) async {
    try {
      await _db.insert(DatabaseHelper.tablePastPapers, paper.toMap());
      _papers.insert(0, paper);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> markDownloaded(String id, String filePath) async {
    await _db.update(
      DatabaseHelper.tablePastPapers,
      {'is_downloaded': 1, 'file_path': filePath},
      where: 'id = ?',
      whereArgs: [id],
    );
    final i = _papers.indexWhere((p) => p.id == id);
    if (i != -1) {
      final old = _papers[i];
      _papers[i] = PastPaper(
        id: old.id,
        title: old.title,
        subject: old.subject,
        examType: old.examType,
        year: old.year,
        language: old.language,
        filePath: filePath,
        markingSchemePath: old.markingSchemePath,
        remoteUrl: old.remoteUrl,
        markingSchemeUrl: old.markingSchemeUrl,
        isDownloaded: true,
        fileSize: old.fileSize,
        createdAt: old.createdAt,
      );
      notifyListeners();
    }
  }

  Future<bool> deletePaper(String id) async {
    try {
      await _db.delete(DatabaseHelper.tablePastPapers,
          where: 'id = ?', whereArgs: [id]);
      _papers.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void setExamType(String v) { _examType = v; notifyListeners(); }
  void setSubject(String v)  { _subject  = v; notifyListeners(); }
  void setYear(int? v)       { _year     = v; notifyListeners(); }
  void setLanguage(String v) { _language = v; notifyListeners(); }

  void clearFilters() {
    _examType = 'All';
    _subject  = 'All';
    _year     = null;
    _language = 'All';
    notifyListeners();
  }

  /// Seed sample past papers for demo
  Future<void> seedSamplePapers() async {
    if (_papers.isNotEmpty) return;
    final samples = [
      PastPaper(id: '1', title: 'Mathematics O/L 2023', subject: 'Mathematics',
          examType: ExamType.ol, year: 2023, language: PaperLanguage.english,
          remoteUrl: 'https://example.lk/math_ol_2023.pdf',
          createdAt: DateTime.now()),
      PastPaper(id: '2', title: 'Science O/L 2023', subject: 'Science',
          examType: ExamType.ol, year: 2023, language: PaperLanguage.english,
          remoteUrl: 'https://example.lk/science_ol_2023.pdf',
          createdAt: DateTime.now()),
      PastPaper(id: '3', title: 'Sinhala O/L 2023 (සිංහල)', subject: 'Sinhala',
          examType: ExamType.ol, year: 2023, language: PaperLanguage.sinhala,
          remoteUrl: 'https://example.lk/sinhala_ol_2023.pdf',
          createdAt: DateTime.now()),
      PastPaper(id: '4', title: 'Combined Maths A/L 2022', subject: 'Combined Mathematics',
          examType: ExamType.al, year: 2022, language: PaperLanguage.english,
          remoteUrl: 'https://example.lk/combmaths_al_2022.pdf',
          createdAt: DateTime.now()),
      PastPaper(id: '5', title: 'Physics A/L 2022', subject: 'Physics',
          examType: ExamType.al, year: 2022, language: PaperLanguage.english,
          remoteUrl: 'https://example.lk/physics_al_2022.pdf',
          createdAt: DateTime.now()),
      PastPaper(id: '6', title: 'History O/L 2022 (தமிழ்)', subject: 'History',
          examType: ExamType.ol, year: 2022, language: PaperLanguage.tamil,
          remoteUrl: 'https://example.lk/history_ol_2022_ta.pdf',
          createdAt: DateTime.now()),
    ];
    for (final p in samples) {
      await addPaper(p);
    }
  }
}
