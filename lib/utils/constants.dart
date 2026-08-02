// lib/utils/constants.dart

class AppConstants {
  // App Info
  static const String appName = 'SL Study Assistant';
  static const String appVersion = '1.0.0';

  // Sri Lankan subjects
  static const List<String> subjects = [
    'Mathematics',
    'Science',
    'Sinhala',
    'Tamil',
    'English',
    'History',
    'Geography',
    'Commerce',
    'Accounting',
    'Economics',
    'ICT',
    'Art',
    'Music',
    'Drama',
    'Health',
    'Buddhism',
    'Christianity',
    'Islam',
    'Hinduism',
  ];

  // O/L Subjects
  static const List<String> olSubjects = [
    'Mathematics',
    'Science',
    'Sinhala',
    'English',
    'History',
    'Geography',
    'Commerce',
    'ICT',
    'Art',
    'Health',
    'Buddhism',
  ];

  // A/L Stream subjects
  static const List<String> alScienceSubjects = [
    'Combined Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'ICT',
  ];

  static const List<String> alArtsSubjects = [
    'Sinhala',
    'English',
    'History',
    'Geography',
    'Logic & Scientific Method',
    'Political Science',
    'Economics',
  ];

  static const List<String> alCommerceSubjects = [
    'Business Studies',
    'Accounting',
    'Economics',
    'ICT',
  ];

  // Exam years available
  static final List<int> examYears = List.generate(
    15,
    (i) => DateTime.now().year - i,
  );

  // File types
  static const List<String> supportedFileTypes = ['pdf', 'txt', 'docx'];
  static const List<String> supportedImageTypes = ['jpg', 'jpeg', 'png'];

  // Storage keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyDownloadWifiOnly = 'download_wifi_only';

  // Sample past paper URLs (replace with real CDN in production)
  static const String pastPaperBaseUrl =
      'https://pastpapers.example.lk/papers';

  // Max file size (50MB)
  static const int maxFileSizeBytes = 50 * 1024 * 1024;

  // Quiz defaults
  static const int defaultQuizTimeLimit = 1800; // 30 minutes
  static const int defaultQuestionsPerQuiz = 10;

  // Flashcard spaced repetition intervals (days)
  static const Map<int, int> spacedRepetitionDays = {
    0: 1,  // New: review tomorrow
    1: 3,  // Easy: review in 3 days
    2: 7,  // Medium: review in a week
    3: 1,  // Hard: review tomorrow
  };
}
