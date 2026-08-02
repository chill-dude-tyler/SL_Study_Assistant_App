// FILE: lib/app.dart
// Root MaterialApp with theme, locale, and navigation setup.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'utils/app_theme.dart';
import 'localization/app_localizations.dart';
import 'screens/main_navigation.dart';

class SLStudyApp extends StatelessWidget {
  const SLStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider  = context.watch<ThemeProvider>();
    final langProvider   = context.watch<LanguageProvider>();

    return MaterialApp(
      title: 'SL Study Assistant',
      debugShowCheckedModeBanner: false,

      // ── Theming ────────────────────────────────────────────────────
      theme:      AppTheme.lightTheme,
      darkTheme:  AppTheme.darkTheme,
      themeMode:  themeProvider.themeMode,

      // ── Localisation ───────────────────────────────────────────────
      locale: langProvider.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const MainNavigation(),
    );
  }
}
