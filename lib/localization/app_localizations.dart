// lib/localization/app_localizations.dart
// Handles English, Sinhala, and Tamil translations.

import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('si'), // Sinhala
    Locale('ta'), // Tamil
  ];

  static final Map<String, Map<String, String>> _strings = {
    'en': {
      // General
      'app_name': 'SL Study Assistant',
      'ok': 'OK',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'save': 'Save',
      'edit': 'Edit',
      'search': 'Search',
      'loading': 'Loading...',
      'no_data': 'No data found',
      'error': 'Error',
      'success': 'Success',
      'offline': 'You are offline',

      // Dashboard
      'dashboard': 'Dashboard',
      'welcome': 'Welcome back!',
      'study_streak': 'Study Streak',
      'days': 'days',
      'total_notes': 'Total Notes',
      'total_flashcards': 'Flashcards',
      'quizzes_taken': 'Quizzes Taken',
      'recent_activity': 'Recent Activity',
      'quick_access': 'Quick Access',

      // Notes
      'notes': 'Notes',
      'add_note': 'Add Note',
      'note_title': 'Note Title',
      'select_subject': 'Select Subject',
      'upload_file': 'Upload File',
      'no_notes': 'No notes yet. Upload your first note!',
      'bookmarked': 'Bookmarked',
      'last_opened': 'Last opened',

      // Textbooks
      'textbooks': 'Textbooks',
      'add_textbook': 'Add Textbook',
      'grade': 'Grade',
      'publisher': 'Publisher',
      'year': 'Year',
      'reading_progress': 'Reading Progress',
      'no_textbooks': 'No textbooks yet.',

      // Past Papers
      'past_papers': 'Past Papers',
      'ol': 'O/L',
      'al': 'A/L',
      'subject': 'Subject',
      'exam_year': 'Year',
      'language': 'Language',
      'download': 'Download',
      'downloaded': 'Downloaded',
      'marking_scheme': 'Marking Scheme',
      'no_papers': 'No past papers available.',

      // Downloads
      'downloads': 'Downloads',
      'downloading': 'Downloading',
      'paused': 'Paused',
      'completed': 'Completed',
      'failed': 'Failed',
      'pause': 'Pause',
      'resume': 'Resume',
      'retry': 'Retry',
      'no_downloads': 'No downloads yet.',

      // Quiz
      'quizzes': 'Quizzes',
      'create_quiz': 'Create Quiz',
      'start_quiz': 'Start Quiz',
      'quiz_result': 'Quiz Result',
      'score': 'Score',
      'time_taken': 'Time Taken',
      'difficulty': 'Difficulty',
      'easy': 'Easy',
      'medium': 'Medium',
      'hard': 'Hard',
      'next_question': 'Next',
      'submit_quiz': 'Submit',
      'no_quizzes': 'No quizzes yet. Create your first quiz!',
      'timed_mode': 'Timed Mode',
      'questions': 'Questions',

      // Flashcards
      'flashcards': 'Flashcards',
      'add_flashcard': 'Add Flashcard',
      'create_deck': 'Create Deck',
      'deck_name': 'Deck Name',
      'front': 'Front',
      'back': 'Back',
      'flip': 'Tap to flip',
      'correct': 'Correct',
      'incorrect': 'Incorrect',
      'review_complete': 'Review Complete!',
      'no_flashcards': 'No flashcards yet.',
      'cards_due': 'Cards Due',

      // OCR
      'ocr_scanner': 'OCR Scanner',
      'capture_image': 'Capture Image',
      'pick_image': 'Pick from Gallery',
      'extract_text': 'Extract Text',
      'extracted_text': 'Extracted Text',
      'save_as_note': 'Save as Note',
      'ocr_processing': 'Processing image...',

      // Search
      'search_hint': 'Search notes, books, papers...',
      'search_results': 'Search Results',
      'no_results': 'No results found for',

      // Settings
      'settings': 'Settings',
      'dark_mode': 'Dark Mode',
      'app_language': 'App Language',
      'english': 'English',
      'sinhala': 'සිංහල',
      'tamil': 'தமிழ்',
      'storage_info': 'Storage Information',
      'clear_cache': 'Clear Cache',
      'about': 'About',
      'version': 'Version',
      'wifi_only': 'Download on WiFi only',
    },

    'si': {
      // Sinhala translations
      'app_name': 'SL ශිෂ්‍ය සහායකයා',
      'ok': 'හරි',
      'cancel': 'අවලංගු කරන්න',
      'delete': 'මකන්න',
      'save': 'සුරකින්න',
      'edit': 'සංස්කරණය',
      'search': 'සොයන්න',
      'loading': 'පූරණය වෙමින්...',
      'no_data': 'දත්ත නොමැත',
      'error': 'දෝෂයකි',
      'success': 'සාර්ථකයි',
      'offline': 'ඔබ නොබැඳිව සිටී',
      'dashboard': 'ප්‍රධාන පිටුව',
      'welcome': 'නැවත සාදරයෙන් පිළිගනිමු!',
      'notes': 'සටහන්',
      'textbooks': 'පෙළ පොත්',
      'past_papers': 'පසුගිය ප්‍රශ්න පත්‍ර',
      'downloads': 'බාගැනීම්',
      'quizzes': 'ප්‍රශ්නාවලි',
      'flashcards': 'ෆ්ලෑෂ්කාඩ්',
      'settings': 'සැකසුම්',
      'search_hint': 'සොයන්න...',
      'dark_mode': 'අඳුරු මාදිලිය',
      'app_language': 'භාෂාව',
      'english': 'English',
      'sinhala': 'සිංහල',
      'tamil': 'தமிழ்',
      'score': 'ලකුණු',
      'difficulty': 'දුෂ්කරතාව',
      'easy': 'පහසු',
      'medium': 'මධ්‍යම',
      'hard': 'අපහසු',
      'subject': 'විෂය',
      'download': 'බාගන්න',
      'downloaded': 'බාගත කළා',
      'ol': 'සා.පෙළ',
      'al': 'උ.පෙළ',
    },

    'ta': {
      // Tamil translations
      'app_name': 'SL கல்வி உதவியாளர்',
      'ok': 'சரி',
      'cancel': 'ரத்து செய்',
      'delete': 'நீக்கு',
      'save': 'சேமி',
      'edit': 'திருத்து',
      'search': 'தேடு',
      'loading': 'ஏற்றுகிறது...',
      'no_data': 'தரவு இல்லை',
      'error': 'பிழை',
      'success': 'வெற்றி',
      'offline': 'நீங்கள் ஆஃப்லைனில் உள்ளீர்கள்',
      'dashboard': 'டாஷ்போர்டு',
      'welcome': 'மீண்டும் வரவேற்கிறோம்!',
      'notes': 'குறிப்புகள்',
      'textbooks': 'பாடப்புத்தகங்கள்',
      'past_papers': 'கடந்த கால தாள்கள்',
      'downloads': 'பதிவிறக்கங்கள்',
      'quizzes': 'வினாடி வினா',
      'flashcards': 'ஃப்ளாஷ்கார்டுகள்',
      'settings': 'அமைப்புகள்',
      'search_hint': 'தேடுங்கள்...',
      'dark_mode': 'இருண்ட பயன்முறை',
      'app_language': 'மொழி',
      'english': 'English',
      'sinhala': 'සිංහල',
      'tamil': 'தமிழ்',
      'score': 'மதிப்பெண்',
      'difficulty': 'கஷ்டம்',
      'easy': 'எளிது',
      'medium': 'நடுத்தரம்',
      'hard': 'கடினம்',
      'subject': 'பாடம்',
      'download': 'பதிவிறக்கு',
      'downloaded': 'பதிவிறக்கியது',
      'ol': 'O/L',
      'al': 'A/L',
    },
  };

  String translate(String key) {
    final langCode = locale.languageCode;
    final langMap = _strings[langCode] ?? _strings['en']!;
    return langMap[key] ?? _strings['en']![key] ?? key;
  }

  // Shorthand
  String t(String key) => translate(key);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
