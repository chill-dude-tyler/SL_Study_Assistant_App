// lib/screens/notes/notes_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/note.dart';
import '../../providers/notes_provider.dart';
import '../../services/file_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../localization/app_localizations.dart';
import 'note_reader_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesProvider>().loadNotes();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Upload Note ──────────────────────────────────────────────────────────

  Future<void> _uploadNote() async {
    final file = await FileService().pickDocument();
    if (file == null) return;

    // Check file size
    if ((file.size) > AppConstants.maxFileSizeBytes) {
      Helpers.showSnackBar(context, 'File too large (max 50MB)', isError: true);
      return;
    }

    // Show title & subject dialog
    String title = file.name.replaceAll(RegExp(r'\.\w+$'), '');
    String subject = AppConstants.subjects.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _UploadDialog(
        initialTitle: title,
        onConfirm: (t, s) {
          title = t;
          subject = s;
          Navigator.pop(ctx, true);
        },
      ),
    );

    if (confirmed != true || file.path == null) return;

    setState(() => _isUploading = true);

    try {
      // Save file locally
      final savedPath = await FileService().saveFile(
        file.path!,
        'notes',
        '${Helpers.generateId()}_${file.name}',
      );

      if (savedPath == null) throw Exception('Failed to save file');

      final note = Note(
        id: Helpers.generateId(),
        title: title,
        subject: subject,
        filePath: savedPath,
        fileType: Helpers.getFileExtension(file.name),
        fileSize: file.size,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await context.read<NotesProvider>().addNote(note);
      if (success && mounted) {
        Helpers.showSnackBar(context, 'Note uploaded successfully!');
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Upload failed: $e', isError: true);
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final provider = context.watch<NotesProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('notes')),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            onPressed: _isUploading ? null : _uploadNote,
            tooltip: l.t('add_note'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Filter Bar ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: l.t('search_hint'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              provider.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                  onChanged: provider.setSearchQuery,
                ),
                const SizedBox(height: 10),
                // Subject filter chips
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.subjects.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final sub = provider.subjects[i];
                      final selected = provider.selectedSubject == sub;
                      return FilterChip(
                        label: Text(sub),
                        selected: selected,
                        onSelected: (_) => provider.setSubjectFilter(sub),
                        selectedColor:
                            AppTheme.primaryColor.withOpacity(0.15),
                        checkmarkColor: AppTheme.primaryColor,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Notes List ──────────────────────────────────────────────
          Expanded(
            child: _isUploading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Uploading note...'),
                      ],
                    ),
                  )
                : provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.notes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.note_alt_outlined,
                                  size: 64,
                                  color: theme.colorScheme.onBackground
                                      .withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(l.t('no_notes'),
                                    style: theme.textTheme.bodyLarge),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _uploadNote,
                                  icon: const Icon(Icons.upload_file),
                                  label: Text(l.t('add_note')),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: provider.notes.length,
                            itemBuilder: (ctx, index) =>
                                _NoteCard(note: provider.notes[index]),
                          ),
          ),
        ],
      ),
    );
  }
}

// ─── Note Card ────────────────────────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  final Note note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Helpers.getSubjectColor(note.subject);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.read<NotesProvider>().updateLastOpened(note.id);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NoteReaderScreen(note: note),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // File type icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Helpers.getFileIcon(note.fileType),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            note.subject,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          note.formattedSize,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    if (note.lastOpened != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Opened ${Helpers.timeAgo(note.lastOpened!)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      note.isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_outline,
                      color: note.isBookmarked
                          ? AppTheme.warningColor
                          : null,
                      size: 20,
                    ),
                    onPressed: () =>
                        context.read<NotesProvider>().toggleBookmark(note.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () async {
                      final confirmed = await Helpers.showConfirmDialog(
                        context,
                        title: 'Delete Note',
                        content:
                            'Are you sure you want to delete "${note.title}"?',
                        confirmText: 'Delete',
                        isDestructive: true,
                      );
                      if (confirmed && context.mounted) {
                        context.read<NotesProvider>().deleteNote(note.id);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Upload Dialog ────────────────────────────────────────────────────────────

class _UploadDialog extends StatefulWidget {
  final String initialTitle;
  final void Function(String title, String subject) onConfirm;

  const _UploadDialog({
    required this.initialTitle,
    required this.onConfirm,
  });

  @override
  State<_UploadDialog> createState() => __UploadDialogState();
}

class __UploadDialogState extends State<_UploadDialog> {
  late TextEditingController _titleCtrl;
  String _selectedSubject = AppConstants.subjects.first;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Note'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedSubject,
            decoration: const InputDecoration(labelText: 'Subject'),
            items: AppConstants.subjects
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _selectedSubject = v!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () =>
              widget.onConfirm(_titleCtrl.text.trim(), _selectedSubject),
          child: const Text('Upload'),
        ),
      ],
    );
  }
}
