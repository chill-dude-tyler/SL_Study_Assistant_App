// lib/models/past_paper.dart

enum ExamType { ol, al, other }
enum PaperLanguage { english, sinhala, tamil }

class PastPaper {
  final String id;
  final String title;
  final String subject;
  final ExamType examType;
  final int year;
  final PaperLanguage language;
  final String? filePath;
  final String? markingSchemePath;
  final String? remoteUrl;
  final String? markingSchemeUrl;
  final bool isDownloaded;
  final int fileSize;
  final DateTime createdAt;

  PastPaper({
    required this.id,
    required this.title,
    required this.subject,
    required this.examType,
    required this.year,
    this.language = PaperLanguage.english,
    this.filePath,
    this.markingSchemePath,
    this.remoteUrl,
    this.markingSchemeUrl,
    this.isDownloaded = false,
    this.fileSize = 0,
    required this.createdAt,
  });

  factory PastPaper.fromMap(Map<String, dynamic> map) {
    return PastPaper(
      id: map['id'],
      title: map['title'],
      subject: map['subject'],
      examType: ExamType.values.firstWhere(
        (e) => e.name == map['exam_type'],
        orElse: () => ExamType.other,
      ),
      year: map['year'],
      language: PaperLanguage.values.firstWhere(
        (l) => l.name == map['language'],
        orElse: () => PaperLanguage.english,
      ),
      filePath: map['file_path'],
      markingSchemePath: map['marking_scheme_path'],
      remoteUrl: map['remote_url'],
      markingSchemeUrl: map['marking_scheme_url'],
      isDownloaded: (map['is_downloaded'] ?? 0) == 1,
      fileSize: map['file_size'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'exam_type': examType.name,
      'year': year,
      'language': language.name,
      'file_path': filePath,
      'marking_scheme_path': markingSchemePath,
      'remote_url': remoteUrl,
      'marking_scheme_url': markingSchemeUrl,
      'is_downloaded': isDownloaded ? 1 : 0,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get examTypeLabel {
    switch (examType) {
      case ExamType.ol: return 'O/L';
      case ExamType.al: return 'A/L';
      default: return 'Other';
    }
  }

  String get languageLabel {
    switch (language) {
      case PaperLanguage.sinhala: return 'සිංහල';
      case PaperLanguage.tamil: return 'தமிழ்';
      default: return 'English';
    }
  }
}
