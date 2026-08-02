// lib/models/note.dart

class Note {
  final String id;
  final String title;
  final String subject;
  final String filePath;
  final String fileType; // pdf, txt, docx
  final int fileSize;
  final String? extractedText;
  final String language;
  final bool isBookmarked;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastOpened;

  Note({
    required this.id,
    required this.title,
    required this.subject,
    required this.filePath,
    required this.fileType,
    this.fileSize = 0,
    this.extractedText,
    this.language = 'en',
    this.isBookmarked = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastOpened,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      subject: map['subject'],
      filePath: map['file_path'],
      fileType: map['file_type'],
      fileSize: map['file_size'] ?? 0,
      extractedText: map['extracted_text'],
      language: map['language'] ?? 'en',
      isBookmarked: (map['is_bookmarked'] ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      lastOpened: map['last_opened'] != null
          ? DateTime.parse(map['last_opened'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'file_path': filePath,
      'file_type': fileType,
      'file_size': fileSize,
      'extracted_text': extractedText,
      'language': language,
      'is_bookmarked': isBookmarked ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_opened': lastOpened?.toIso8601String(),
    };
  }

  Note copyWith({
    String? title,
    String? subject,
    String? extractedText,
    String? language,
    bool? isBookmarked,
    DateTime? lastOpened,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      filePath: filePath,
      fileType: fileType,
      fileSize: fileSize,
      extractedText: extractedText ?? this.extractedText,
      language: language ?? this.language,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastOpened: lastOpened ?? this.lastOpened,
    );
  }

  /// Human-readable file size
  String get formattedSize {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
