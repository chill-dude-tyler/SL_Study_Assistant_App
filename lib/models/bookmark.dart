// FILE: lib/models/bookmark.dart

class Bookmark {
  final String id;
  final String sourceId;
  final String sourceType; // note | textbook | past_paper
  final String title;
  final int pageNumber;
  final String? note;
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.sourceId,
    required this.sourceType,
    required this.title,
    this.pageNumber = 0,
    this.note,
    required this.createdAt,
  });

  factory Bookmark.fromMap(Map<String, dynamic> map) => Bookmark(
        id: map['id'],
        sourceId: map['source_id'],
        sourceType: map['source_type'],
        title: map['title'],
        pageNumber: map['page_number'] ?? 0,
        note: map['note'],
        createdAt: DateTime.parse(map['created_at']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'source_id': sourceId,
        'source_type': sourceType,
        'title': title,
        'page_number': pageNumber,
        'note': note,
        'created_at': createdAt.toIso8601String(),
      };
}
