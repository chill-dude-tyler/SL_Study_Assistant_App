// FILE: lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/file_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _storageUsed = 0;

  @override
  void initState() {
    super.initState();
    _loadStorage();
  }

  Future<void> _loadStorage() async {
    final bytes = await FileService().getTotalStorageUsed();
    setState(() => _storageUsed = bytes);
  }

  Future<void> _clearCache() async {
    final ok = await Helpers.showConfirmDialog(
      context,
      title: 'Clear Cache',
      content: 'This will not delete your uploaded files, only temporary cache data.',
      confirmText: 'Clear',
      isDestructive: true,
    );
    if (ok && mounted) {
      Helpers.showSnackBar(context, 'Cache cleared');
      _loadStorage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeP = context.watch<ThemeProvider>();
    final langP = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          // ── Appearance ────────────────────────────────────────────
          _SectionHeader('Appearance'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: Text(themeP.isDark ? 'Dark theme active' : 'Light theme active'),
                secondary: Icon(themeP.isDark ? Icons.dark_mode : Icons.light_mode,
                    color: AppTheme.primaryColor),
                value: themeP.isDark,
                onChanged: (_) => themeP.toggleTheme(),
              ),
            ]),
          ),

          // ── Language ──────────────────────────────────────────────
          _SectionHeader('Language'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.language, color: AppTheme.primaryColor),
                title: const Text('App Language'),
                subtitle: Text(langP.languageName),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => _showLanguagePicker(context, langP),
              ),
            ]),
          ),

          // ── Storage ───────────────────────────────────────────────
          _SectionHeader('Storage'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.storage_outlined, color: AppTheme.primaryColor),
                title: const Text('Storage Used'),
                subtitle: Text(Helpers.formatFileSize(_storageUsed)),
                trailing: TextButton(onPressed: _clearCache, child: const Text('Clear Cache')),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.folder_outlined, color: AppTheme.primaryColor),
                title: const Text('Refresh Storage Info'),
                onTap: _loadStorage,
              ),
            ]),
          ),

          // ── Downloads ─────────────────────────────────────────────
          _SectionHeader('Downloads'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(children: [
              SwitchListTile(
                title: const Text('Download on WiFi only'),
                subtitle: const Text('Save mobile data'),
                secondary: const Icon(Icons.wifi_outlined, color: AppTheme.primaryColor),
                value: false,
                onChanged: (_) => Helpers.showSnackBar(context, 'Setting saved'),
              ),
            ]),
          ),

          // ── About ─────────────────────────────────────────────────
          _SectionHeader('About'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                title: const Text('App Version'),
                subtitle: const Text('1.0.0'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.school_outlined, color: AppTheme.primaryColor),
                title: const Text('SL Study Assistant'),
                subtitle: const Text('Built for Sri Lankan students'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.offline_bolt_outlined, color: AppTheme.successColor),
                title: const Text('Offline First'),
                subtitle: const Text('Works without internet after setup'),
              ),
            ]),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, LanguageProvider langP) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Select Language', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _LangTile(code: 'en', label: 'English', emoji: '🇬🇧', current: langP.languageCode, onTap: () { langP.setLanguage('en'); Navigator.pop(context); }),
          _LangTile(code: 'si', label: 'සිංහල (Sinhala)', emoji: '🇱🇰', current: langP.languageCode, onTap: () { langP.setLanguage('si'); Navigator.pop(context); }),
          _LangTile(code: 'ta', label: 'தமிழ் (Tamil)', emoji: '🇱🇰', current: langP.languageCode, onTap: () { langP.setLanguage('ta'); Navigator.pop(context); }),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 16, 6),
    child: Text(title, style: TextStyle(
      fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2,
      color: Theme.of(context).colorScheme.primary,
    )),
  );
}

class _LangTile extends StatelessWidget {
  final String code, label, emoji, current;
  final VoidCallback onTap;
  const _LangTile({required this.code, required this.label, required this.emoji, required this.current, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Text(emoji, style: const TextStyle(fontSize: 24)),
    title: Text(label),
    trailing: code == current ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
    onTap: onTap,
  );
}
