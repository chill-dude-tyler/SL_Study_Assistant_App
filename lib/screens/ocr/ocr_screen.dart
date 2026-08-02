// FILE: lib/screens/ocr/ocr_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/note.dart';
import '../../providers/notes_provider.dart';
import '../../services/ocr_service.dart';
import '../../services/file_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});
  @override State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  String? _imagePath;
  String _extractedText = '';
  bool _processing = false;
  bool _saving = false;
  String _language = 'en';

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image, allowMultiple: false, withData: false,
      );
      if (result != null && result.files.single.path != null) {
        setState(() { _imagePath = result.files.single.path; _extractedText = ''; });
      }
    } catch (e) {
      Helpers.showSnackBar(context, 'Could not pick image', isError: true);
    }
  }

  Future<void> _extractText() async {
    if (_imagePath == null) return;
    setState(() { _processing = true; _extractedText = ''; });
    try {
      final result = await OcrService().extractText(_imagePath!, language: _language);
      setState(() => _extractedText = result.success ? result.text : (result.errorMessage ?? 'No text found'));
      if (!result.success && mounted) {
        Helpers.showSnackBar(context, result.errorMessage ?? 'OCR failed', isError: true);
      }
    } catch (e) {
      setState(() => _extractedText = 'OCR error: $e');
    } finally {
      setState(() => _processing = false);
    }
  }

  Future<void> _saveAsNote() async {
    if (_extractedText.isEmpty) return;
    String title = 'OCR Note ${DateTime.now().day}/${DateTime.now().month}';
    String subject = AppConstants.subjects.first;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _SaveNoteDialog(
        initialTitle: title,
        onConfirm: (t, s) { title = t; subject = s; },
      ),
    );
    if (ok != true) return;

    setState(() => _saving = true);
    try {
      // Save text to file
      final saved = await FileService().saveBytes(
        _extractedText.codeUnits,
        'notes',
        '${Helpers.generateId()}_ocr.txt',
      );
      if (saved == null) throw Exception('Failed to save');

      final note = Note(
        id: Helpers.generateId(),
        title: title, subject: subject,
        filePath: saved, fileType: 'txt',
        fileSize: _extractedText.length,
        extractedText: _extractedText,
        language: _language,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await context.read<NotesProvider>().addNote(note);
      if (mounted) Helpers.showSnackBar(context, 'Saved as note: $title');
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Save failed: $e', isError: true);
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('OCR Scanner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Language selector
          Row(children: [
            const Text('Language: ', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'en', label: Text('EN')),
                ButtonSegment(value: 'si', label: Text('SI')),
                ButtonSegment(value: 'ta', label: Text('TA')),
              ],
              selected: {_language},
              onSelectionChanged: (v) => setState(() => _language = v.first),
            ),
          ]),
          const SizedBox(height: 16),

          // Image preview area
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _imagePath != null
                      ? AppTheme.primaryColor
                      : theme.colorScheme.onSurface.withOpacity(0.15),
                  width: _imagePath != null ? 2 : 1,
                ),
              ),
              child: _imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(File(_imagePath!), fit: BoxFit.cover, width: double.infinity),
                    )
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 48,
                          color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      Text('Tap to pick an image', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text('JPG, PNG supported', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
                    ]),
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Pick Image'),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              onPressed: (_imagePath != null && !_processing) ? _extractText : null,
              icon: _processing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.document_scanner),
              label: Text(_processing ? 'Processing...' : 'Extract Text'),
            )),
          ]),
          const SizedBox(height: 20),

          // Extracted text
          if (_extractedText.isNotEmpty) ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Extracted Text', style: theme.textTheme.titleLarge),
              TextButton.icon(
                onPressed: _saving ? null : _saveAsNote,
                icon: const Icon(Icons.save_alt_outlined, size: 16),
                label: Text(_saving ? 'Saving...' : 'Save as Note'),
              ),
            ]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
              ),
              child: SelectableText(
                _extractedText,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saving ? null : _saveAsNote,
              icon: const Icon(Icons.save),
              label: const Text('Save as Note'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}

class _SaveNoteDialog extends StatefulWidget {
  final String initialTitle;
  final void Function(String, String) onConfirm;
  const _SaveNoteDialog({required this.initialTitle, required this.onConfirm});
  @override State<_SaveNoteDialog> createState() => __SaveNoteDialogState();
}

class __SaveNoteDialogState extends State<_SaveNoteDialog> {
  late final _ctrl = TextEditingController(text: widget.initialTitle);
  String _subject = AppConstants.subjects.first;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Save as Note'),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: _ctrl, decoration: const InputDecoration(labelText: 'Title')),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: _subject, decoration: const InputDecoration(labelText: 'Subject'),
        items: AppConstants.subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: (v) => setState(() => _subject = v!),
      ),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ElevatedButton(
        onPressed: () { widget.onConfirm(_ctrl.text.trim(), _subject); Navigator.pop(context, true); },
        child: const Text('Save'),
      ),
    ],
  );
}
