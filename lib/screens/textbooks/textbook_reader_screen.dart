// FILE: lib/screens/textbooks/textbook_reader_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../models/textbook.dart';
import '../../providers/textbook_provider.dart';
import '../../utils/app_theme.dart';

class TextbookReaderScreen extends StatefulWidget {
  final Textbook textbook;
  const TextbookReaderScreen({super.key, required this.textbook});
  @override State<TextbookReaderScreen> createState() => _TextbookReaderScreenState();
}

class _TextbookReaderScreenState extends State<TextbookReaderScreen> {
  final _key = GlobalKey<SfPdfViewerState>();
  final _ctrl = PdfViewerController();
  bool _showBar = true;
  int _cur = 1, _total = 0;

  @override
  void initState() {
    super.initState();
    // Resume from last saved page
    if (widget.textbook.currentPage > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ctrl.jumpToPage(widget.textbook.currentPage);
      });
    }
  }

  @override
  void dispose() {
    // Save reading progress
    context.read<TextbookProvider>().updateProgress(widget.textbook.id, _cur);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tb = widget.textbook;
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: _showBar
          ? AppBar(
              title: Text(tb.title, overflow: TextOverflow.ellipsis),
              backgroundColor: Colors.grey[850],
              actions: [
                if (_total > 0)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('$_cur / $_total',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: () => setState(() => _showBar = !_showBar),
        child: File(tb.filePath).existsSync()
            ? SfPdfViewer.file(
                File(tb.filePath),
                key: _key,
                controller: _ctrl,
                onDocumentLoaded: (d) => setState(() => _total = d.document.pages.count),
                onPageChanged: (d) => setState(() => _cur = d.newPageNumber),
                enableDoubleTapZooming: true,
                enableTextSelection: true,
                pageLayoutMode: PdfPageLayoutMode.continuous,
              )
            : const Center(child: Text('File not found.', style: TextStyle(color: Colors.white70))),
      ),
      bottomNavigationBar: _showBar && _total > 1
          ? Container(
              color: Colors.grey[850],
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(children: [
                IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: _cur > 1 ? () => _ctrl.previousPage() : null),
                Expanded(
                  child: Slider(
                    value: _cur.toDouble(),
                    min: 1, max: _total.toDouble(),
                    divisions: _total > 1 ? _total - 1 : 1,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) => _ctrl.jumpToPage(v.round()),
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: _cur < _total ? () => _ctrl.nextPage() : null),
              ]),
            )
          : null,
    );
  }
}
