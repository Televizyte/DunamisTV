import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/bible/models/bible_models.dart';
import '../../../features/bible/state/bible_store.dart';

class BibleBooksScreen extends StatefulWidget {
  const BibleBooksScreen({super.key});

  @override
  State<BibleBooksScreen> createState() => _BibleBooksScreenState();
}

class _BibleBooksScreenState extends State<BibleBooksScreen> {
  static const _topGradient = LinearGradient(
    colors: <Color>[
      Color(0xFF1A1F5A),
      Color(0xFF5B1FA8),
      Color(0xFFB70E7C),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  final BibleStore _store = BibleStore.instance;
  String _testament = 'old';
  bool _routeExtraHandled = false;

  @override
  void initState() {
    super.initState();
    _bootStore();
  }

  Future<void> _bootStore() async {
    await _store.init();
    if (!mounted) return;
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_routeExtraHandled) return;
    _routeExtraHandled = true;

    final extra = GoRouterState.of(context).extra;
    if (extra is Map && extra['testament'] != null) {
      _testament = extra['testament'].toString().toLowerCase() == 'new'
          ? 'new'
          : 'old';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _openBook(BibleBook book) {
    context.push(
      '/tools/bible/chapters',
      extra: <String, dynamic>{
        'book': book.name,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = _store.isLightTheme;
    final books = _testament == 'new'
        ? _store.newTestamentBooks
        : _store.oldTestamentBooks;

    return Scaffold(
      backgroundColor:
          isLight ? const Color(0xFFF7F1E6) : const Color(0xFF070B18),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(gradient: _topGradient),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: Text(
                    _testament == 'new' ? 'New Testament' : 'Old Testament',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: isLight ? 'Dark mode' : 'Light mode',
                  onPressed: () async {
                    await _store.toggleReaderTheme();
                    if (!mounted) return;
                    setState(() {});
                  },
                  icon: Icon(
                    isLight ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
      body: _store.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _SegmentChip(
                          isLight: isLight,
                          selected: _testament == 'old',
                          label: 'Old Testament',
                          onTap: () => setState(() => _testament = 'old'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SegmentChip(
                          isLight: isLight,
                          selected: _testament == 'new',
                          label: 'New Testament',
                          onTap: () => setState(() => _testament = 'new'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                    itemCount: books.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return _BookTile(
                        isLight: isLight,
                        book: book,
                        onTap: () => _openBook(book),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.isLight,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool isLight;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? const Color(0xFFFF2C96)
        : (isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430));

    final textColor = selected
        ? Colors.white
        : (isLight ? const Color(0xFF1E1B16) : Colors.white);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : (isLight
                      ? const Color(0xFFE6D8C3)
                      : Colors.white.withOpacity(0.08)),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({
    required this.isLight,
    required this.book,
    required this.onTap,
  });

  final bool isLight;
  final BibleBook book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLight
                  ? const Color(0xFFE6D8C3)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isLight
                      ? const Color(0xFFF2E8D8)
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: isLight ? const Color(0xFF3C3428) : Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      book.name,
                      style: TextStyle(
                        color: isLight
                            ? const Color(0xFF1E1B16)
                            : Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${book.chapterCount} chapters',
                      style: TextStyle(
                        color: isLight
                            ? const Color(0xFF5F5648)
                            : Colors.white.withOpacity(0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isLight ? const Color(0xFF6B6256) : Colors.white70,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
