// lib/screens/dashboard/dashboard_screen.dart
// Main home screen showing stats, quick access, and recent activity.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/database_helper.dart';
import '../../providers/notes_provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import '../../localization/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, int> _stats = {};
  bool _statsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await DatabaseHelper().getStatistics();
    if (mounted) {
      setState(() {
        _stats = stats;
        _statsLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.secondaryColor,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.school,
                                    color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.t('welcome'),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    l.t('app_name'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Stats Row ──────────────────────────────────────────
                  _buildStatsSection(context, l),
                  const SizedBox(height: 24),

                  // ── Quick Access ───────────────────────────────────────
                  Text(
                    l.t('quick_access'),
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildQuickAccessGrid(context, l),
                  const SizedBox(height: 24),

                  // ── Study Tips ─────────────────────────────────────────
                  _buildStudyTipCard(context),
                  const SizedBox(height: 80), // nav bar space
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, AppLocalizations l) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          icon: Icons.note_alt_outlined,
          label: l.t('notes'),
          value: _stats['notes']?.toString() ?? '0',
          color: AppTheme.primaryColor,
        ),
        _StatCard(
          icon: Icons.menu_book_outlined,
          label: l.t('textbooks'),
          value: _stats['textbooks']?.toString() ?? '0',
          color: AppTheme.successColor,
        ),
        _StatCard(
          icon: Icons.style_outlined,
          label: l.t('flashcards'),
          value: _stats['flashcards']?.toString() ?? '0',
          color: AppTheme.secondaryColor,
        ),
        _StatCard(
          icon: Icons.quiz_outlined,
          label: l.t('quizzes'),
          value: _stats['quizzes']?.toString() ?? '0',
          color: AppTheme.warningColor,
        ),
      ],
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context, AppLocalizations l) {
    final items = [
      _QuickAccessItem(
        icon: Icons.upload_file_outlined,
        label: 'Upload Note',
        color: AppTheme.primaryColor,
        onTap: () => _navigate(context, 1),
      ),
      _QuickAccessItem(
        icon: Icons.download_outlined,
        label: 'Past Papers',
        color: AppTheme.accentColor,
        onTap: () => _navigate(context, 3),
      ),
      _QuickAccessItem(
        icon: Icons.quiz_outlined,
        label: 'Take Quiz',
        color: AppTheme.warningColor,
        onTap: () => _navigate(context, 5),
      ),
      _QuickAccessItem(
        icon: Icons.style_outlined,
        label: 'Flashcards',
        color: AppTheme.secondaryColor,
        onTap: () => _navigate(context, 6),
      ),
      _QuickAccessItem(
        icon: Icons.document_scanner_outlined,
        label: 'OCR Scan',
        color: AppTheme.successColor,
        onTap: () => _navigate(context, 7),
      ),
      _QuickAccessItem(
        icon: Icons.search_outlined,
        label: 'Search',
        color: const Color(0xFF0EA5E9),
        onTap: () => _navigate(context, 8),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _QuickAccessCard(item: item);
      },
    );
  }

  Widget _buildStudyTipCard(BuildContext context) {
    final tips = [
      'Review your notes within 24 hours for better retention.',
      'Use the Pomodoro technique: 25 min study, 5 min break.',
      'Flashcards help remember key definitions. Review daily!',
      'Practice past papers to understand the exam pattern.',
      'Group study can improve understanding by 30%.',
    ];

    final tip = tips[DateTime.now().day % tips.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF1A56DB)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 Study Tip',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    // Find the MainNavigationScreen and switch tab
    final mainNav = context.findAncestorStateOfType<_MainNavState>();
    mainNav?.setTab(index);
  }
}

// Placeholder for nav access — handled in main_navigation
abstract class _MainNavState extends State {
  void setTab(int index);
}

// ─── Stat Card Widget ─────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Access Item ────────────────────────────────────────────────────────

class _QuickAccessItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _QuickAccessItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickAccessCard extends StatelessWidget {
  final _QuickAccessItem item;

  const _QuickAccessCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
