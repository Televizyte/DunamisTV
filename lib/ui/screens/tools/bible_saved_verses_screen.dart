import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/bible/models/bible_models.dart';
import '../../../features/bible/state/bible_store.dart';

class BibleSavedVersesScreen extends StatefulWidget {
  const BibleSavedVersesScreen({super.key});

  @override
  State<BibleSavedVersesScreen> createState() => _BibleSavedVersesScreenState();
}

class _BibleSavedVersesScreenState extends State<BibleSavedVersesScreen> {
  static const _topGradient = LinearGradient(
    colors: <Color>[
      Color(0xFF1A1F5A),
      Color(0xFF5B1FA8),
      Color(0xFFB70E7C),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  final BibleStore _store = BibleStore();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await _store.init();
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  void _openVerse(BibleVerse verse) {
    context.push(
      '/tools/bible/reader',
      extra: <String, dynamic>{
        'book': verse.book,
        'chapter': verse.chapter,
        'verse': verse.verse,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = _store.isLightTheme;

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
                const Expanded(
                  child: Text(
                    'Saved Verses',
                    style: TextStyle(
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
          : _store.bookmarks.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Your bookmarked verses will appear here after you save them from the reader.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isLight
                            ? const Color(0xFF5F5648)
                            : Colors.white.withOpacity(0.74),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                  itemCount: _store.bookmarks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final verse = _store.bookmarks[index];
                    return _SavedVerseTile(
                      isLight: isLight,
                      verse: verse,
                      onTap: () => _openVerse(verse),
                      onRemove: () async {
                        await _store.toggleBookmark(verse);
                        if (!mounted) return;
                        setState(() {});
                      },
                    );
                  },
                ),
    );
  }
}

class _SavedVerseTile extends StatelessWidget {
  const _SavedVerseTile({
    required this.isLight,
    required this.verse,
    required this.onTap,
    required this.onRemove,
  });

  final bool isLight;
  final BibleVerse verse;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isLight
                  ? const Color(0xFFE6D8C3)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      verse.reference,
                      style: TextStyle(
                        color: isLight ? const Color(0xFF1E1B16) : Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      verse.text,
                      style: TextStyle(
                        color: isLight
                            ? const Color(0xFF4C453A)
                            : Colors.white.withOpacity(0.82),
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: onRemove,
                tooltip: 'Remove bookmark',
                icon: Icon(
                  Icons.bookmark_remove_rounded,
                  color: isLight ? const Color(0xFF3C3428) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
