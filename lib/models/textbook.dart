// lib/models/textbook.dart

class Textbook {
  final String id;
  final String title;
  final String subject;
  final String? grade;
  final String filePath;
  final String fileType;
  final int fileSize;
  final int totalPages;
  final int currentPage;
  final String language;
  final String? publisher;
  final int? year;
  final DateTime createdAt;
  final DateTime updatedAt;

  Textbook({
    required this.id,
    required this.title,
    required this.subject,
    this.grade,
    required this.filePath,
    required this.fileType,
    this.fileSize = 0,
    this.totalPages = 0,
    this.currentPage = 0,
    this.language = 'en',
    this.publisher,
    this.year,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Textbook.fromMap(Map<String, dynamic> map) {
    return Textbook(
      id: map['id'],
      title: map['title'],
      subject: map['subject'],
      grade: map['grade'],
      filePath: map['file_path'],
      fileType: map['file_type'],
      fileSize: map['file_size'] ?? 0,
      totalPages: map['total_pages'] ?? 0,
      currentPage: map['current_page'] ?? 0,
      language: map['language'] ?? 'en',
      publisher: map['publisher'],
      year: map['year'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'grade': grade,
      'file_path': filePath,
      'file_type': fileType,
      'file_size': fileSize,
      'total_pages': totalPages,
      'current_page': currentPage,
      'language': language,
      'publisher': publisher,
      'year': year,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double get readingProgress =>
      totalPages > 0 ? currentPage / totalPages : 0.0;

  String get formattedSize {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
