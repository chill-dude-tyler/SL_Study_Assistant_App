// lib/providers/language_provider.dart

import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  final DatabaseHelper _db = DatabaseHelper();

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final value = await _db.getSetting('language');
    if (value != null) {
      _locale = Locale(value);
      notifyListeners();
    }
  }

  Future<void> setLanguage(String code) async {
    _locale = Locale(code);
    await _db.setSetting('language', code);
    notifyListeners();
  }

  String get languageName {
    switch (_locale.languageCode) {
      case 'si': return 'සිංහල';
      case 'ta': return 'தமிழ்';
      default: return 'English';
    }
  }
}
