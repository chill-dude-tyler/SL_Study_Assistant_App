// FILE: lib/screens/main_navigation.dart
// Bottom navigation controller that hosts all top-level screens.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization/app_localizations.dart';
import '../utils/app_theme.dart';

import 'dashboard/dashboard_screen.dart';
import 'notes/notes_screen.dart';
import 'textbooks/textbooks_screen.dart';
import 'past_papers/past_papers_screen.dart';
import 'downloads/downloads_screen.dart';
import 'quiz/quiz_list_screen.dart';
import 'flashcards/flashcards_screen.dart';
import 'ocr/ocr_screen.dart';
import 'search/search_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // All screens – order matches nav items
  static const List<Widget> _screens = [
    DashboardScreen(),
    NotesScreen(),
    TextbooksScreen(),
    PastPapersScreen(),
    DownloadsScreen(),
    QuizListScreen(),
    FlashcardsScreen(),
    OcrScreen(),
    SearchScreen(),
    SettingsScreen(),
  ];

  void setTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    // Primary bottom-nav items (first 5)
    final bottomItems = [
      BottomNavigationBarItem(
        icon: const Icon(Icons.dashboard_outlined),
        activeIcon: const Icon(Icons.dashboard),
        label: l.t('dashboard'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.note_alt_outlined),
        activeIcon: const Icon(Icons.note_alt),
        label: l.t('notes'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.menu_book_outlined),
        activeIcon: const Icon(Icons.menu_book),
        label: l.t('textbooks'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.article_outlined),
        activeIcon: const Icon(Icons.article),
        label: l.t('past_papers'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.more_horiz),
        activeIcon: const Icon(Icons.more_horiz),
        label: 'More',
      ),
    ];

    // For indexes >= 4 (More section), show "More" tab as active
    final navIndex = _selectedIndex >= 4 ? 4 : _selectedIndex;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Secondary actions bar when "More" is selected
          if (_selectedIndex >= 4)
            _SecondaryBar(
              selectedIndex: _selectedIndex,
              onSelect: setTab,
            ),
          BottomNavigationBar(
            currentIndex: navIndex,
            onTap: (i) {
              if (i == 4) {
                // Toggle More panel or go to first More screen
                setState(() => _selectedIndex = _selectedIndex >= 4 ? 4 : 4);
              } else {
                setState(() => _selectedIndex = i);
              }
            },
            items: bottomItems,
            type: BottomNavigationBarType.fixed,
          ),
        ],
      ),
    );
  }
}

// ─── Secondary bar shown when "More" tab is active ───────────────────────────
class _SecondaryBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onSelect;

  const _SecondaryBar({
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    final items = [
      _SecItem(4, Icons.download_outlined, Icons.download, l.t('downloads')),
      _SecItem(5, Icons.quiz_outlined, Icons.quiz, l.t('quizzes')),
      _SecItem(6, Icons.style_outlined, Icons.style, l.t('flashcards')),
      _SecItem(7, Icons.document_scanner_outlined, Icons.document_scanner, 'OCR'),
      _SecItem(8, Icons.search_outlined, Icons.search, l.t('search')),
      _SecItem(9, Icons.settings_outlined, Icons.settings, l.t('settings')),
    ];

    return Container(
      color: theme.bottomNavigationBarTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final active = selectedIndex == item.index;
          return GestureDetector(
            onTap: () => onSelect(item.index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active ? item.activeIcon : item.icon,
                  size: 22,
                  color: active
                      ? AppTheme.primaryColor
                      : theme.bottomNavigationBarTheme.unselectedItemColor,
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10,
                    color: active
                        ? AppTheme.primaryColor
                        : theme.bottomNavigationBarTheme.unselectedItemColor,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SecItem {
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _SecItem(this.index, this.icon, this.activeIcon, this.label);
}
