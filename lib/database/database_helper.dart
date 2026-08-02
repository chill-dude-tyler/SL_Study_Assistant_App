// lib/database/database_helper.dart
// Central SQLite database manager for the SL Study Assistant app.
// Handles creation, migration, and all CRUD operations.

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Singleton pattern
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const String _dbName = 'sl_study_assistant.db';
  static const int _dbVersion = 1;

  // ─── Table Names ─────────────────────────────────────────────────────────
  static const String tableNotes = 'notes';
  static const String tableTextbooks = 'textbooks';
  static const String tableExtractedText = 'extracted_text';
  static const String tablePastPapers = 'past_papers';
  static const String tableDownloads = 'downloads';
  static const String tableFlashcards = 'flashcards';
  static const String tableQuizzes = 'quizzes';
  static const String tableQuizQuestions = 'quiz_questions';
  static const String tableQuizResults = 'quiz_results';
  static const String tableBookmarks = 'bookmarks';
  static const String tableSettings = 'settings';

  // ─── Get Database ─────────────────────────────────────────────────────────
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        // Enable foreign keys
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ─── Create Tables ────────────────────────────────────────────────────────
  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      // Notes table
      await txn.execute('''
        CREATE TABLE $tableNotes (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          subject TEXT NOT NULL,
          file_path TEXT NOT NULL,
          file_type TEXT NOT NULL,
          file_size INTEGER DEFAULT 0,
          extracted_text TEXT,
          language TEXT DEFAULT 'en',
          is_bookmarked INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          last_opened TEXT
        )
      ''');

      // Textbooks table
      await txn.execute('''
        CREATE TABLE $tableTextbooks (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          subject TEXT NOT NULL,
          grade TEXT,
          file_path TEXT NOT NULL,
          file_type TEXT NOT NULL,
          file_size INTEGER DEFAULT 0,
          total_pages INTEGER DEFAULT 0,
          current_page INTEGER DEFAULT 0,
          language TEXT DEFAULT 'en',
          publisher TEXT,
          year INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Extracted text table (for OCR and PDF text)
      await txn.execute('''
        CREATE TABLE $tableExtractedText (
          id TEXT PRIMARY KEY,
          source_id TEXT NOT NULL,
          source_type TEXT NOT NULL,
          page_number INTEGER DEFAULT 0,
          content TEXT NOT NULL,
          language TEXT DEFAULT 'en',
          created_at TEXT NOT NULL
        )
      ''');

      // Past papers table
      await txn.execute('''
        CREATE TABLE $tablePastPapers (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          subject TEXT NOT NULL,
          exam_type TEXT NOT NULL,
          year INTEGER NOT NULL,
          language TEXT DEFAULT 'en',
          file_path TEXT,
          marking_scheme_path TEXT,
          remote_url TEXT,
          marking_scheme_url TEXT,
          is_downloaded INTEGER DEFAULT 0,
          file_size INTEGER DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');

      // Downloads table
      await txn.execute('''
        CREATE TABLE $tableDownloads (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          url TEXT NOT NULL,
          file_path TEXT,
          file_size INTEGER DEFAULT 0,
          downloaded_bytes INTEGER DEFAULT 0,
          status TEXT DEFAULT 'pending',
          progress REAL DEFAULT 0.0,
          error_message TEXT,
          source_id TEXT,
          source_type TEXT,
          created_at TEXT NOT NULL,
          completed_at TEXT
        )
      ''');

      // Flashcards table
      await txn.execute('''
        CREATE TABLE $tableFlashcards (
          id TEXT PRIMARY KEY,
          deck_name TEXT NOT NULL,
          subject TEXT NOT NULL,
          front_text TEXT NOT NULL,
          back_text TEXT NOT NULL,
          front_image_path TEXT,
          back_image_path TEXT,
          difficulty INTEGER DEFAULT 0,
          times_reviewed INTEGER DEFAULT 0,
          times_correct INTEGER DEFAULT 0,
          last_reviewed TEXT,
          next_review TEXT,
          source_id TEXT,
          source_type TEXT,
          language TEXT DEFAULT 'en',
          created_at TEXT NOT NULL
        )
      ''');

      // Quizzes table
      await txn.execute('''
        CREATE TABLE $tableQuizzes (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          subject TEXT NOT NULL,
          source_id TEXT,
          source_type TEXT,
          difficulty TEXT DEFAULT 'medium',
          language TEXT DEFAULT 'en',
          time_limit INTEGER DEFAULT 0,
          total_questions INTEGER DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');

      // Quiz Questions table
      await txn.execute('''
        CREATE TABLE $tableQuizQuestions (
          id TEXT PRIMARY KEY,
          quiz_id TEXT NOT NULL,
          question_text TEXT NOT NULL,
          question_type TEXT NOT NULL,
          options TEXT,
          correct_answer TEXT NOT NULL,
          explanation TEXT,
          difficulty TEXT DEFAULT 'medium',
          marks INTEGER DEFAULT 1,
          order_index INTEGER DEFAULT 0,
          FOREIGN KEY (quiz_id) REFERENCES $tableQuizzes(id) ON DELETE CASCADE
        )
      ''');

      // Quiz Results table
      await txn.execute('''
        CREATE TABLE $tableQuizResults (
          id TEXT PRIMARY KEY,
          quiz_id TEXT NOT NULL,
          score INTEGER DEFAULT 0,
          total_marks INTEGER DEFAULT 0,
          percentage REAL DEFAULT 0.0,
          time_taken INTEGER DEFAULT 0,
          answers TEXT,
          weak_areas TEXT,
          completed_at TEXT NOT NULL,
          FOREIGN KEY (quiz_id) REFERENCES $tableQuizzes(id) ON DELETE CASCADE
        )
      ''');

      // Bookmarks table
      await txn.execute('''
        CREATE TABLE $tableBookmarks (
          id TEXT PRIMARY KEY,
          source_id TEXT NOT NULL,
          source_type TEXT NOT NULL,
          title TEXT NOT NULL,
          page_number INTEGER DEFAULT 0,
          note TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      // Settings table
      await txn.execute('''
        CREATE TABLE $tableSettings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Insert default settings
      final now = DateTime.now().toIso8601String();
      await txn.insert(tableSettings, {
        'key': 'theme_mode', 'value': 'light', 'updated_at': now
      });
      await txn.insert(tableSettings, {
        'key': 'language', 'value': 'en', 'updated_at': now
      });
      await txn.insert(tableSettings, {
        'key': 'download_wifi_only', 'value': 'false', 'updated_at': now
      });
      await txn.insert(tableSettings, {
        'key': 'auto_backup', 'value': 'false', 'updated_at': now
      });
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here
  }

  // ─── Generic CRUD ─────────────────────────────────────────────────────────

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
    List<String>? columns,
  }) async {
    final db = await database;
    return await db.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data,
        where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? args,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, args);
  }

  // ─── Settings ─────────────────────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final result = await query(tableSettings,
        where: 'key = ?', whereArgs: [key]);
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    await insert(tableSettings, {
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── Full-text Search ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> searchAll(String query) async {
    final db = await database;
    final q = '%$query%';

    final notes = await db.rawQuery('''
      SELECT id, title, subject, 'note' as type FROM $tableNotes
      WHERE title LIKE ? OR subject LIKE ? OR extracted_text LIKE ?
    ''', [q, q, q]);

    final textbooks = await db.rawQuery('''
      SELECT id, title, subject, 'textbook' as type FROM $tableTextbooks
      WHERE title LIKE ? OR subject LIKE ?
    ''', [q, q]);

    final papers = await db.rawQuery('''
      SELECT id, title, subject, 'past_paper' as type FROM $tablePastPapers
      WHERE title LIKE ? OR subject LIKE ?
    ''', [q, q]);

    final flashcards = await db.rawQuery('''
      SELECT id, front_text as title, subject, 'flashcard' as type
      FROM $tableFlashcards
      WHERE front_text LIKE ? OR back_text LIKE ? OR subject LIKE ?
    ''', [q, q, q]);

    return [...notes, ...textbooks, ...papers, ...flashcards];
  }

  // ─── Statistics ───────────────────────────────────────────────────────────

  Future<Map<String, int>> getStatistics() async {
    final db = await database;

    final notesCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableNotes')) ?? 0;
    final textbooksCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableTextbooks')) ?? 0;
    final papersCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tablePastPapers')) ?? 0;
    final flashcardsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableFlashcards')) ?? 0;
    final quizzesCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableQuizzes')) ?? 0;

    return {
      'notes': notesCount,
      'textbooks': textbooksCount,
      'pastPapers': papersCount,
      'flashcards': flashcardsCount,
      'quizzes': quizzesCount,
    };
  }

  // ─── Close DB ─────────────────────────────────────────────────────────────

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
