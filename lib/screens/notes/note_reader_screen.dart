// lib/screens/notes/note_reader_screen.dart
// Opens PDF/text files using SyncFusion PDF Viewer.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../models/note.dart';
import '../../utils/app_theme.dart';

class NoteReaderScreen extends StatefulWidget {
  final Note note;

  const NoteReaderScreen({super.key, required this.note});

  @override
  State<NoteReaderScreen> createState() => _NoteReaderScreenState();
}

class _NoteReaderScreenState extends State<NoteReaderScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final PdfViewerController _pdfController = PdfViewerController();
  bool _showToolbar = true;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = widget.note;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: _showToolbar
          ? AppBar(
              title: Text(
                note.title,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                // Page indicator
                if (_totalPages > 0)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                // Search in PDF
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _pdfViewerKey.currentState
                      ?.openBookmarkView(),
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: () => setState(() => _showToolbar = !_showToolbar),
        child: _buildContent(note),
      ),
      // Page navigation bar
      bottomNavigationBar: _showToolbar && _totalPages > 1
          ? _buildPageNav()
          : null,
    );
  }

  Widget _buildContent(Note note) {
    if (note.fileType == 'txt') {
      return _TextReader(filePath: note.filePath);
    }

    if (!File(note.filePath).existsSync()) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.white54),
            SizedBox(height: 12),
            Text(
              'File not found.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return SfPdfViewer.file(
      File(note.filePath),
      key: _pdfViewerKey,
      controller: _pdfController,
      onDocumentLoaded: (details) {
        setState(() => _totalPages = details.document.pages.count);
      },
      onPageChanged: (details) {
        setState(() => _currentPage = details.newPageNumber);
      },
      enableDoubleTapZooming: true,
      enableTextSelection: true,
      pageLayoutMode: PdfPageLayoutMode.continuous,
    );
  }

  Widget _buildPageNav() {
    return Container(
      color: Colors.grey[850],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.first_page, color: Colors.white),
            onPressed: _currentPage > 1
                ? () => _pdfController.jumpToPage(1)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: _currentPage > 1
                ? () => _pdfController.previousPage()
                : null,
          ),
          Expanded(
            child: Slider(
              value: _currentPage.toDouble(),
              min: 1,
              max: _totalPages.toDouble(),
              divisions: _totalPages - 1,
              label: 'Page $_currentPage',
              activeColor: AppTheme.primaryColor,
              onChanged: (v) {
                _pdfController.jumpToPage(v.round());
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: _currentPage < _totalPages
                ? () => _pdfController.nextPage()
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.last_page, color: Colors.white),
            onPressed: _currentPage < _totalPages
                ? () => _pdfController.jumpToPage(_totalPages)
                : null,
          ),
        ],
      ),
    );
  }
}

// ─── Text File Reader ─────────────────────────────────────────────────────────

class _TextReader extends StatefulWidget {
  final String filePath;

  const _TextReader({required this.filePath});

  @override
  State<_TextReader> createState() => __TextReaderState();
}

class __TextReaderState extends State<_TextReader> {
  String? _content;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    try {
      final file = File(widget.filePath);
      final content = await file.readAsString();
      setState(() {
        _content = content;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _content = 'Error reading file: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: SelectableText(
        _content ?? '',
        style: const TextStyle(
          fontSize: 15,
          height: 1.6,
          color: Colors.white,
        ),
      ),
    );
  }
}
