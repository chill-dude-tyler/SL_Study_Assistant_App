// FILE: lib/screens/textbooks/textbooks_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/textbook.dart';
import '../../providers/textbook_provider.dart';
import '../../services/file_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/subject_chip.dart';
import 'textbook_reader_screen.dart';

class TextbooksScreen extends StatefulWidget {
  const TextbooksScreen({super.key});
  @override
  State<TextbooksScreen> createState() => _TextbooksScreenState();
}

class _TextbooksScreenState extends State<TextbooksScreen> {
  final _searchCtrl = TextEditingController();
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TextbookProvider>().loadTextbooks();
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _upload() async {
    final file = await FileService().pickDocument();
    if (file == null || file.path == null) return;
    String title = file.name.replaceAll(RegExp(r'\.\w+$'), '');
    String subject = AppConstants.subjects.first;
    String? grade; String? publisher;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _AddTextbookDialog(
        initialTitle: title,
        onConfirm: (t, s, g, p) { title = t; subject = s; grade = g; publisher = p; },
      ),
    );
    if (ok != true) return;
    setState(() => _uploading = true);
    try {
      final saved = await FileService().saveFile(file.path!, 'textbooks', '${Helpers.generateId()}_${file.name}');
      if (saved == null) throw Exception('Save failed');
      final tb = Textbook(
        id: Helpers.generateId(), title: title, subject: subject, grade: grade,
        filePath: saved, fileType: Helpers.getFileExtension(file.name),
        fileSize: file.size, publisher: publisher,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final success = await context.read<TextbookProvider>().addTextbook(tb);
      if (success && mounted) Helpers.showSnackBar(context, 'Textbook added!');
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Error: $e', isError: true);
    } finally { setState(() => _uploading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TextbookProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Textbooks'),
        actions: [IconButton(icon: const Icon(Icons.upload_file_outlined), onPressed: _uploading ? null : _upload)],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search textbooks...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); prov.setSearchQuery(''); })
                  : null,
            ),
            onChanged: prov.setSearchQuery,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: prov.subjects.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = prov.subjects[i]; final sel = prov.selectedSubject == s;
                return FilterChip(label: Text(s, style: const TextStyle(fontSize: 12)), selected: sel, onSelected: (_) => prov.setSubjectFilter(s));
              },
            ),
          ),
        ),
        Expanded(
          child: _uploading || prov.isLoading
              ? const Center(child: CircularProgressIndicator())
              : prov.textbooks.isEmpty
                  ? EmptyState(icon: Icons.menu_book_outlined, title: 'No textbooks yet', subtitle: 'Upload a PDF or TXT textbook', buttonLabel: 'Upload', onButtonTap: _upload)
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: prov.textbooks.length,
                      itemBuilder: (_, i) => _TextbookCard(tb: prov.textbooks[i]),
                    ),
        ),
      ]),
    );
  }
}

class _TextbookCard extends StatelessWidget {
  final Textbook tb;
  const _TextbookCard({required this.tb});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Helpers.getSubjectColor(tb.subject);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TextbookReaderScreen(textbook: tb))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 50, height: 60,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.menu_book, color: color, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tb.title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                SubjectChip(subject: tb.subject, small: true),
                if (tb.grade != null) ...[const SizedBox(width: 6), Text('Grade ${tb.grade}', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11))],
              ]),
              if (tb.totalPages > 0) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: LinearProgressIndicator(value: tb.readingProgress, minHeight: 4, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text('${(tb.readingProgress * 100).toInt()}%', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
                ]),
              ],
            ])),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () async {
                final ok = await Helpers.showConfirmDialog(context, title: 'Delete', content: 'Delete "${tb.title}"?', confirmText: 'Delete', isDestructive: true);
                if (ok && context.mounted) context.read<TextbookProvider>().deleteTextbook(tb.id);
              },
            ),
          ]),
        ),
      ),
    );
  }
}

class _AddTextbookDialog extends StatefulWidget {
  final String initialTitle;
  final void Function(String, String, String?, String?) onConfirm;
  const _AddTextbookDialog({required this.initialTitle, required this.onConfirm});
  @override State<_AddTextbookDialog> createState() => __AddTextbookDialogState();
}

class __AddTextbookDialogState extends State<_AddTextbookDialog> {
  late final _titleCtrl = TextEditingController(text: widget.initialTitle);
  final _gradeCtrl = TextEditingController();
  final _publisherCtrl = TextEditingController();
  String _subject = AppConstants.subjects.first;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add Textbook'),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: _subject, decoration: const InputDecoration(labelText: 'Subject'),
        items: AppConstants.subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: (v) => setState(() => _subject = v!),
      ),
      const SizedBox(height: 10),
      TextField(controller: _gradeCtrl, decoration: const InputDecoration(labelText: 'Grade (optional)')),
      const SizedBox(height: 10),
      TextField(controller: _publisherCtrl, decoration: const InputDecoration(labelText: 'Publisher (optional)')),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ElevatedButton(
        onPressed: () {
          widget.onConfirm(_titleCtrl.text.trim(), _subject,
            _gradeCtrl.text.trim().isEmpty ? null : _gradeCtrl.text.trim(),
            _publisherCtrl.text.trim().isEmpty ? null : _publisherCtrl.text.trim());
          Navigator.pop(context, true);
        },
        child: const Text('Add'),
      ),
    ],
  );
}
