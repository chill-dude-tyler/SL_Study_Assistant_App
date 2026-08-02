// FILE: lib/screens/flashcards/flashcards_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/flashcard.dart';
import '../../providers/flashcard_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});
  @override State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashcardProvider>().loadFlashcards();
    });
  }

  void _addCard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddCardSheet(),
    );
  }

  void _startDeck(String deckName) {
    final cards = context.read<FlashcardProvider>().getCardsByDeck(deckName);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FlashcardReviewScreen(deckName: deckName, cards: cards)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<FlashcardProvider>();
    final theme = Theme.of(context);
    final decks = prov.deckMap;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          if (prov.dueCards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                icon: const Icon(Icons.notification_important_outlined, size: 16),
                label: Text('${prov.dueCards.length} due'),
                onPressed: () {
                  if (decks.isNotEmpty) _startDeck(decks.keys.first);
                },
              ),
            ),
          IconButton(icon: const Icon(Icons.add), onPressed: _addCard),
        ],
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : decks.isEmpty
              ? EmptyState(
                  icon: Icons.style_outlined,
                  title: 'No flashcards yet',
                  subtitle: 'Create your first flashcard deck',
                  buttonLabel: 'Add Flashcard',
                  onButtonTap: _addCard,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
                  itemCount: decks.length,
                  itemBuilder: (_, i) {
                    final deckName = decks.keys.elementAt(i);
                    final cards = decks[deckName]!;
                    final dueCount = cards.where((c) => c.isDueForReview).length;
                    return _DeckCard(
                      deckName: deckName,
                      cardCount: cards.length,
                      dueCount: dueCount,
                      onStudy: () => _startDeck(deckName),
                      onDelete: () async {
                        final ok = await Helpers.showConfirmDialog(context,
                            title: 'Delete Deck', content: 'Delete deck "$deckName" and all its cards?',
                            confirmText: 'Delete', isDestructive: true);
                        if (ok && context.mounted) prov.deleteDeck(deckName);
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ─── Deck Card ────────────────────────────────────────────────────────────────
class _DeckCard extends StatelessWidget {
  final String deckName;
  final int cardCount;
  final int dueCount;
  final VoidCallback onStudy;
  final VoidCallback onDelete;
  const _DeckCard({required this.deckName, required this.cardCount, required this.dueCount, required this.onStudy, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Helpers.getSubjectColor(deckName);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onStudy,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.style, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(deckName, style: theme.textTheme.titleLarge?.copyWith(fontSize: 15)),
              const SizedBox(height: 4),
              Row(children: [
                Text('$cardCount cards', style: theme.textTheme.bodyMedium),
                if (dueCount > 0) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.warningColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text('$dueCount due', style: TextStyle(color: AppTheme.warningColor, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ]),
            ])),
            Column(children: [
              ElevatedButton(
                onPressed: onStudy,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                child: const Text('Study', style: TextStyle(fontSize: 13)),
              ),
              IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: onDelete),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ─── Add Card Sheet ───────────────────────────────────────────────────────────
class _AddCardSheet extends StatefulWidget {
  @override State<_AddCardSheet> createState() => __AddCardSheetState();
}

class __AddCardSheetState extends State<_AddCardSheet> {
  final _deckCtrl = TextEditingController();
  final _frontCtrl = TextEditingController();
  final _backCtrl = TextEditingController();
  String _subject = AppConstants.subjects.first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('New Flashcard', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        TextField(controller: _deckCtrl, decoration: const InputDecoration(labelText: 'Deck Name')),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _subject, decoration: const InputDecoration(labelText: 'Subject'),
          items: AppConstants.subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _subject = v!),
        ),
        const SizedBox(height: 10),
        TextField(controller: _frontCtrl, maxLines: 3,
            decoration: const InputDecoration(labelText: 'Front (Question)')),
        const SizedBox(height: 10),
        TextField(controller: _backCtrl, maxLines: 3,
            decoration: const InputDecoration(labelText: 'Back (Answer)')),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: () async {
              if (_frontCtrl.text.trim().isEmpty || _backCtrl.text.trim().isEmpty) return;
              final deck = _deckCtrl.text.trim().isEmpty ? _subject : _deckCtrl.text.trim();
              final card = Flashcard(
                id: Helpers.generateId(), deckName: deck, subject: _subject,
                frontText: _frontCtrl.text.trim(), backText: _backCtrl.text.trim(),
                createdAt: DateTime.now(),
              );
              await context.read<FlashcardProvider>().addFlashcard(card);
              if (context.mounted) {
                Helpers.showSnackBar(context, 'Flashcard added!');
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          )),
        ]),
        const SizedBox(height: 16),
      ]),
    );
  }
}

// ─── Flashcard Review Screen ──────────────────────────────────────────────────
class FlashcardReviewScreen extends StatefulWidget {
  final String deckName;
  final List<Flashcard> cards;
  const FlashcardReviewScreen({super.key, required this.deckName, required this.cards});
  @override State<FlashcardReviewScreen> createState() => _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends State<FlashcardReviewScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  bool _flipped = false;
  int _correct = 0;
  int _incorrect = 0;
  late AnimationController _animCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _flipAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: pi / 2).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -pi / 2, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
    ]).animate(_animCtrl);
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  void _flip() {
    if (_flipped) _animCtrl.reverse();
    else _animCtrl.forward();
    setState(() => _flipped = !_flipped);
  }

  void _answer(bool correct) {
    context.read<FlashcardProvider>().recordReview(widget.cards[_index].id, correct);
    if (correct) _correct++; else _incorrect++;
    if (_index < widget.cards.length - 1) {
      setState(() { _index++; _flipped = false; _animCtrl.reset(); });
    } else {
      _showComplete();
    }
  }

  void _showComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Review Complete! 🎉'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Correct: $_correct', style: const TextStyle(color: AppTheme.successColor, fontSize: 16, fontWeight: FontWeight.bold)),
          Text('Incorrect: $_incorrect', style: const TextStyle(color: AppTheme.errorColor, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Accuracy: ${widget.cards.isNotEmpty ? ((_correct / widget.cards.length) * 100).toStringAsFixed(0) : 0}%'),
        ]),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('Done')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() { _index = 0; _correct = 0; _incorrect = 0; _flipped = false; _animCtrl.reset(); });
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = widget.cards[_index];
    final progress = (_index + 1) / widget.cards.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deckName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: progress, minHeight: 4),
        ),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${_index + 1} / ${widget.cards.length}', style: theme.textTheme.bodyMedium),
            Row(children: [
              Icon(Icons.check_circle, color: AppTheme.successColor, size: 16),
              Text(' $_correct  ', style: TextStyle(color: AppTheme.successColor)),
              Icon(Icons.cancel, color: AppTheme.errorColor, size: 16),
              Text(' $_incorrect', style: TextStyle(color: AppTheme.errorColor)),
            ]),
          ]),
        ),
        // Flip card
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GestureDetector(
              onTap: _flip,
              child: AnimatedBuilder(
                animation: _flipAnim,
                builder: (_, child) => Transform(
                  transform: Matrix4.identity()..rotateY(_flipAnim.value),
                  alignment: Alignment.center,
                  child: child,
                ),
                child: Card(
                  elevation: 8,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _flipped
                            ? [const Color(0xFF10B981), const Color(0xFF059669)]
                            : [AppTheme.primaryColor, AppTheme.secondaryColor],
                      ),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(_flipped ? Icons.lightbulb : Icons.help_outline,
                          color: Colors.white70, size: 32),
                      const SizedBox(height: 12),
                      Text(_flipped ? 'ANSWER' : 'QUESTION',
                          style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _flipped ? card.backText : card.frontText,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Tap to flip', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Answer buttons (only after flip)
        if (_flipped)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _answer(false),
                icon: const Icon(Icons.close, color: AppTheme.errorColor),
                label: const Text('Incorrect', style: TextStyle(color: AppTheme.errorColor)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.errorColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              )),
              const SizedBox(width: 16),
              Expanded(child: ElevatedButton.icon(
                onPressed: () => _answer(true),
                icon: const Icon(Icons.check),
                label: const Text('Correct'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              )),
            ]),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _flip,
                icon: const Icon(Icons.flip),
                label: const Text('Flip to see answer'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ),
      ]),
    );
  }
}
