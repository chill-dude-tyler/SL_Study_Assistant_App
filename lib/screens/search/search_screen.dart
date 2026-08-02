// FILE: lib/screens/search/search_screen.dart
import 'package:flutter/material.dart';
import '../../services/search_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _service = SearchService();
  List<SearchResult> _results = [];
  bool _loading = false;
  String _query = '';

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _search(String q) async {
    setState(() { _query = q; _loading = true; });
    if (q.trim().isEmpty) { setState(() { _results = []; _loading = false; }); return; }
    final r = await _service.search(q);
    setState(() { _results = r; _loading = false; });
  }

  IconData _typeIcon(SearchResultType t) {
    switch (t) {
      case SearchResultType.note:      return Icons.note_alt_outlined;
      case SearchResultType.textbook:  return Icons.menu_book_outlined;
      case SearchResultType.pastPaper: return Icons.article_outlined;
      case SearchResultType.flashcard: return Icons.style_outlined;
      case SearchResultType.quiz:      return Icons.quiz_outlined;
    }
  }

  Color _typeColor(SearchResultType t) {
    switch (t) {
      case SearchResultType.note:      return AppTheme.primaryColor;
      case SearchResultType.textbook:  return AppTheme.successColor;
      case SearchResultType.pastPaper: return AppTheme.warningColor;
      case SearchResultType.flashcard: return AppTheme.secondaryColor;
      case SearchResultType.quiz:      return AppTheme.accentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _ctrl,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Search notes, textbooks, flashcards...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _ctrl.clear(); _search(''); })
                  : null,
            ),
            onChanged: _search,
            onSubmitted: _search,
          ),
        ),
        // Type filter chips
        if (_results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _typeChip('All', _results.length, null),
                  ...SearchResultType.values.map((t) {
                    final count = _results.where((r) => r.type == t).length;
                    return count > 0 ? _typeChip(t.name, count, t) : const SizedBox();
                  }),
                ],
              ),
            ),
          ),
        // Results
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _query.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.search, size: 64, color: theme.colorScheme.onBackground.withOpacity(0.2)),
                      const SizedBox(height: 12),
                      Text('Search your study content', style: theme.textTheme.bodyLarge),
                    ]))
                  : _results.isEmpty
                      ? Center(child: Text('No results for "$_query"', style: theme.textTheme.bodyMedium))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80, top: 8),
                          itemCount: _results.length,
                          itemBuilder: (_, i) {
                            final r = _results[i];
                            final color = _typeColor(r.type);
                            return ListTile(
                              leading: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                                child: Icon(_typeIcon(r.type), color: color, size: 20),
                              ),
                              title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                  child: Text(r.typeLabel, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
                                ),
                                if (r.subject != null) ...[
                                  const SizedBox(width: 6),
                                  Text(r.subject!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
                                ],
                              ]),
                              onTap: () => Helpers.showSnackBar(context, 'Opening ${r.title}...'),
                            );
                          },
                        ),
        ),
      ]),
    );
  }

  Widget _typeChip(String label, int count, SearchResultType? type) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text('$label ($count)', style: const TextStyle(fontSize: 11)),
        backgroundColor: type != null ? _typeColor(type).withOpacity(0.1) : null,
        side: BorderSide.none,
      ),
    );
  }
}
