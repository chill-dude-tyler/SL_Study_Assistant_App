// FILE: lib/screens/past_papers/past_papers_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../models/past_paper.dart';
import '../../providers/past_paper_provider.dart';
import '../../services/download_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/subject_chip.dart';
import '../notes/note_reader_screen.dart';
import '../../models/note.dart';

class PastPapersScreen extends StatefulWidget {
  const PastPapersScreen({super.key});
  @override State<PastPapersScreen> createState() => _PastPapersScreenState();
}

class _PastPapersScreenState extends State<PastPapersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _hasNet = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<PastPaperProvider>();
      await prov.loadPapers();
      await prov.seedSamplePapers();
    });
    _checkNet();
  }

  Future<void> _checkNet() async {
    final c = await Connectivity().checkConnectivity();
    setState(() => _hasNet = c != ConnectivityResult.none);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PastPaperProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Papers'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilters),
          if (!_hasNet)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.wifi_off, color: Colors.orange, size: 20),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'O/L Papers'),
            Tab(text: 'A/L Papers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PaperList(examType: 'ol', hasNet: _hasNet),
          _PaperList(examType: 'al', hasNet: _hasNet),
        ],
      ),
    );
  }

  void _showFilters() {
    final prov = context.read<PastPaperProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FilterSheet(provider: prov),
    );
  }
}

class _PaperList extends StatelessWidget {
  final String examType;
  final bool hasNet;
  const _PaperList({required this.examType, required this.hasNet});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PastPaperProvider>();
    // Filter by exam type in view (provider filter may be 'All')
    final papers = prov.papers
        .where((p) => p.examType.name == examType)
        .toList();

    if (prov.isLoading) return const Center(child: CircularProgressIndicator());
    if (papers.isEmpty) {
      return EmptyState(
        icon: Icons.article_outlined,
        title: 'No ${examType.toUpperCase()} papers',
        subtitle: 'Sample papers will appear here',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, top: 8),
      itemCount: papers.length,
      itemBuilder: (_, i) => _PaperCard(paper: papers[i], hasNet: hasNet),
    );
  }
}

class _PaperCard extends StatelessWidget {
  final PastPaper paper;
  final bool hasNet;
  const _PaperCard({required this.paper, required this.hasNet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Helpers.getSubjectColor(paper.subject);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 46, height: 56,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.article, color: color, size: 22),
              Text(paper.year.toString().substring(2),
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(paper.title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 13),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              SubjectChip(subject: paper.subject, small: true),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(paper.languageLabel, style: const TextStyle(fontSize: 10)),
              ),
            ]),
          ])),
          const SizedBox(width: 8),
          // Download / Open button
          paper.isDownloaded
              ? TextButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Open'),
                  onPressed: () => _open(context, paper),
                )
              : TextButton.icon(
                  icon: Icon(
                    hasNet ? Icons.download_outlined : Icons.cloud_off,
                    size: 16,
                  ),
                  label: Text(hasNet ? 'Download' : 'Offline'),
                  onPressed: hasNet && paper.remoteUrl != null
                      ? () => _download(context, paper)
                      : null,
                  style: TextButton.styleFrom(
                    foregroundColor: hasNet ? AppTheme.primaryColor : Colors.grey,
                  ),
                ),
        ]),
      ),
    );
  }

  void _open(BuildContext context, PastPaper paper) {
    if (paper.filePath == null || !File(paper.filePath!).existsSync()) {
      Helpers.showSnackBar(context, 'File not found', isError: true);
      return;
    }
    // Reuse NoteReaderScreen with a minimal Note object
    final fakeNote = Note(
      id: paper.id,
      title: paper.title,
      subject: paper.subject,
      filePath: paper.filePath!,
      fileType: 'pdf',
      createdAt: paper.createdAt,
      updatedAt: paper.createdAt,
    );
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => NoteReaderScreen(note: fakeNote)));
  }

  Future<void> _download(BuildContext context, PastPaper paper) async {
    final dlService = context.read<DownloadService>();
    Helpers.showSnackBar(context, 'Download started for ${paper.title}');
    final id = await dlService.startDownload(
      title: paper.title,
      url: paper.remoteUrl!,
      sourceId: paper.id,
      sourceType: 'past_paper',
    );
    if (id == null && context.mounted) {
      Helpers.showSnackBar(context, 'Download failed – check your connection', isError: true);
    }
  }
}

class _FilterSheet extends StatefulWidget {
  final PastPaperProvider provider;
  const _FilterSheet({required this.provider});
  @override State<_FilterSheet> createState() => __FilterSheetState();
}

class __FilterSheetState extends State<_FilterSheet> {
  late String _lang = widget.provider.languageFilter;
  late String _subj = widget.provider.subjectFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Filter Papers', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        Text('Language', style: theme.textTheme.titleLarge?.copyWith(fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: ['All', 'english', 'sinhala', 'tamil'].map((l) {
          final label = l == 'All' ? 'All' : l == 'english' ? 'English' : l == 'sinhala' ? 'සිංහල' : 'தமிழ்';
          return ChoiceChip(label: Text(label), selected: _lang == l, onSelected: (_) => setState(() => _lang = l));
        }).toList()),
        const SizedBox(height: 16),
        Text('Subject', style: theme.textTheme.titleLarge?.copyWith(fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: widget.provider.subjects.take(8).map((s) {
          return ChoiceChip(label: Text(s, style: const TextStyle(fontSize: 12)), selected: _subj == s, onSelected: (_) => setState(() => _subj = s));
        }).toList()),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () { widget.provider.clearFilters(); Navigator.pop(context); },
            child: const Text('Clear'),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: () {
              widget.provider.setLanguage(_lang);
              widget.provider.setSubject(_subj);
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          )),
        ]),
      ]),
    );
  }
}
