// lib/models/flashcard.dart

class Flashcard {
  final String id;
  final String deckName;
  final String subject;
  final String frontText;
  final String backText;
  final String? frontImagePath;
  final String? backImagePath;
  int difficulty; // 0=new, 1=easy, 2=medium, 3=hard
  int timesReviewed;
  int timesCorrect;
  final DateTime? lastReviewed;
  final DateTime? nextReview;
  final String? sourceId;
  final String? sourceType;
  final String language;
  final DateTime createdAt;

  Flashcard({
    required this.id,
    required this.deckName,
    required this.subject,
    required this.frontText,
    required this.backText,
    this.frontImagePath,
    this.backImagePath,
    this.difficulty = 0,
    this.timesReviewed = 0,
    this.timesCorrect = 0,
    this.lastReviewed,
    this.nextReview,
    this.sourceId,
    this.sourceType,
    this.language = 'en',
    required this.createdAt,
  });

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'],
      deckName: map['deck_name'],
      subject: map['subject'],
      frontText: map['front_text'],
      backText: map['back_text'],
      frontImagePath: map['front_image_path'],
      backImagePath: map['back_image_path'],
      difficulty: map['difficulty'] ?? 0,
      timesReviewed: map['times_reviewed'] ?? 0,
      timesCorrect: map['times_correct'] ?? 0,
      lastReviewed: map['last_reviewed'] != null
          ? DateTime.parse(map['last_reviewed'])
          : null,
      nextReview: map['next_review'] != null
          ? DateTime.parse(map['next_review'])
          : null,
      sourceId: map['source_id'],
      sourceType: map['source_type'],
      language: map['language'] ?? 'en',
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deck_name': deckName,
      'subject': subject,
      'front_text': frontText,
      'back_text': backText,
      'front_image_path': frontImagePath,
      'back_image_path': backImagePath,
      'difficulty': difficulty,
      'times_reviewed': timesReviewed,
      'times_correct': timesCorrect,
      'last_reviewed': lastReviewed?.toIso8601String(),
      'next_review': nextReview?.toIso8601String(),
      'source_id': sourceId,
      'source_type': sourceType,
      'language': language,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get accuracy =>
      timesReviewed > 0 ? timesCorrect / timesReviewed : 0.0;

  bool get isDueForReview {
    if (nextReview == null) return true;
    return DateTime.now().isAfter(nextReview!);
  }
}
