import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../features/bible/models/bible_models.dart';
import '../../../features/bible/state/bible_store.dart';
import '../../../theme/theme_controller.dart';

class BibleReaderScreen extends StatefulWidget {
  const BibleReaderScreen({super.key});

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
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
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = <int, GlobalKey>{};

  String _bookName = '';
  int _chapter = 1;
  int _focusVerse = 0;
  String _incomingVerseText = '';
  String _incomingReference = '';
  bool _readingSavedForThisChapter = false;
  bool _routeExtraHandled = false;
  bool _focusScrollDone = false;

  @override
  void initState() {
    super.initState();
    _bootStore();
  }

  Future<void> _bootStore() async {
    _readingSavedForThisChapter = false;
    _focusScrollDone = false;

    await _store.init();

    if (_incomingReference.trim().isNotEmpty &&
        (_bookName.trim().isEmpty || _chapter < 1)) {
      _applyReference(_incomingReference);
    }

    if (!mounted) return;
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_routeExtraHandled) return;
    _routeExtraHandled = true;

    final state = GoRouterState.of(context);
    final query = state.uri.queryParameters;
    if (query.isNotEmpty) {
      _applyRouteExtra(query);
    }

    final extra = state.extra;
    if (extra is Map) {
      _applyRouteExtra(extra);
    }
  }

  void _applyRouteExtra(Map extra) {
    final rawBook = _readString(extra, <String>[
      'book',
      'bookName',
      'book_name',
    ]);

    final rawReference = _readString(extra, <String>[
      'ref',
      'reference',
      'bible_reference',
      'bibleReference',
      'sourceId',
      'source_id',
      'author',
    ]);

    final rawChapter = _readInt(extra, <String>[
      'chapter',
      'chapterNumber',
      'chapter_number',
    ]);

    final rawVerseNumber = _readInt(extra, <String>[
      'verseNumber',
      'verse_number',
      'verse',
      'verseStart',
      'verse_start',
      'startVerse',
      'start_verse',
      'focusVerse',
      'focus_verse',
      'scrollToVerse',
      'scroll_to_verse',
      'highlightVerse',
      'highlight_verse',
      'highlight',
    ]);

    final rawVerseValue = extra['verse'];
    final verseNumberFromVerse = rawVerseValue is num
        ? rawVerseValue.toInt()
        : int.tryParse(rawVerseValue?.toString().trim() ?? '');

    final verseText = _readString(extra, <String>[
      'verseText',
      'verse_text',
      'bibleVerseText',
      'bible_verse_text',
      'scriptureText',
      'scripture_text',
      'text',
      'quote',
    ]);

    _incomingVerseText = verseText;
    _incomingReference = rawReference;

    if (rawBook.isNotEmpty) {
      _bookName = rawBook;
      _chapter = rawChapter == null || rawChapter < 1 ? 1 : rawChapter;
      _focusVerse = rawVerseNumber ??
          (verseNumberFromVerse == null || verseNumberFromVerse < 1
              ? 0
              : verseNumberFromVerse);
      return;
    }

    if (rawReference.isNotEmpty) {
      _applyReference(rawReference);
    }
  }

  String _readString(Map source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;
      if (value is Map || value is Iterable) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  int? _readInt(Map source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value.toString().trim());
      if (parsed != null) return parsed;
    }
    return null;
  }

  void _applyReference(String reference) {
    final parsed = _parseReference(reference);
    if (parsed == null) return;

    _bookName = parsed.book;
    _chapter = parsed.chapter;
    _focusVerse = parsed.verse;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _store.dispose();
    super.dispose();
  }

  void _goToChapter({
    required String book,
    required int chapter,
    int verse = 0,
  }) {
    if (!mounted) return;

    _focusScrollDone = false;
    _readingSavedForThisChapter = false;
    _verseKeys.clear();

    context.pushReplacement(
      '/tools/bible/reader',
      extra: <String, dynamic>{
        'book': book,
        'bookName': book,
        'chapter': chapter,
        'verse': verse,
        'verseNumber': verse,
        'focusVerse': verse,
        'scrollToVerse': verse,
        'highlightVerse': verse,
      },
    );
  }

  Future<void> _openVerseActions(BibleVerse verse) async {
    final isLight = ThemeController.instance.isLightMode;

    final result = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  verse.reference,
                  style: TextStyle(
                    color: isLight ? const Color(0xFF1E1B16) : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  verse.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isLight
                        ? const Color(0xFF4C453A)
                        : Colors.white.withOpacity(0.82),
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _VerseActionTile(
                  isLight: isLight,
                  icon: Icons.copy_rounded,
                  label: 'Copy Verse',
                  onTap: () =>
                      Navigator.pop(context, _actionPayload('copy', verse)),
                ),
                _VerseActionTile(
                  isLight: isLight,
                  icon: Icons.note_add_rounded,
                  label: 'Add to Note',
                  onTap: () =>
                      Navigator.pop(context, _actionPayload('note', verse)),
                ),
                _VerseActionTile(
                  isLight: isLight,
                  icon: Icons.format_quote_rounded,
                  label: 'Make Quote',
                  onTap: () =>
                      Navigator.pop(context, _actionPayload('quote', verse)),
                ),
                _VerseActionTile(
                  isLight: isLight,
                  icon: _store.isBookmarked(verse)
                      ? Icons.bookmark_remove_rounded
                      : Icons.bookmark_rounded,
                  label: _store.isBookmarked(verse)
                      ? 'Remove Bookmark'
                      : 'Bookmark Verse',
                  onTap: () => Navigator.pop(
                    context,
                    _actionPayload('bookmark', verse),
                  ),
                ),
                _VerseActionTile(
                  isLight: isLight,
                  icon: Icons.share_rounded,
                  label: 'Share Verse',
                  onTap: () =>
                      Navigator.pop(context, _actionPayload('share', verse)),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || result == null) return;

    String action = '';
    String reference = verse.reference;
    String verseText = verse.text;

    if (result is String) {
      action = result.trim().toLowerCase();
    } else if (result is Map) {
      action = (result['action'] ?? '').toString().trim().toLowerCase();

      final incomingRef = (result['reference'] ?? '').toString().trim();
      final incomingVerse =
          (result['verseText'] ?? result['verse'] ?? '').toString().trim();

      if (incomingRef.isNotEmpty) {
        reference = incomingRef;
      }
      if (incomingVerse.isNotEmpty) {
        verseText = incomingVerse;
      }
    }

    if (action.isEmpty) return;

    final text = '$reference\n\n$verseText';

    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verse copied')),
      );
      return;
    }

    if (action == 'note') {
      context.push(
        '/tools/notes/editor',
        extra: <String, dynamic>{
          'insertScripture': <String, dynamic>{
            'ref': reference,
            'reference': reference,
            'verse': verseText,
          },
          'sourceType': 'bible',
          'sourceId': reference,
          'title': reference,
        },
      );
      return;
    }

    if (action == 'quote') {
      context.push(
        '/tools/quote',
        extra: <String, dynamic>{
          'designData': <String, dynamic>{
            'quote': verseText,
            'author': reference,
            'source_type': 'bible',
            'source_id': reference,
            'reference': reference,
          },
          'quote': verseText,
          'text': verseText,
          'author': reference,
          'reference': reference,
          'sourceType': 'bible',
          'sourceId': reference,
        },
      );
      return;
    }

    if (action == 'bookmark') {
      await _store.toggleBookmark(verse);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _store.isBookmarked(verse)
                ? 'Verse bookmarked'
                : 'Bookmark removed',
          ),
        ),
      );
      return;
    }

    if (action == 'share') {
      await Share.share(text);
    }
  }

  Map<String, dynamic> _actionPayload(String action, BibleVerse verse) {
    return <String, dynamic>{
      'action': action,
      'reference': verse.reference,
      'verseText': verse.text,
    };
  }

  Future<void> _persistReadingPositionIfNeeded(List<BibleVerse> verses) async {
    if (_readingSavedForThisChapter || verses.isEmpty) return;

    final verseToSave = _focusVerse > 0
        ? verses.firstWhere(
            (item) => item.verse == _focusVerse,
            orElse: () => verses.first,
          )
        : verses.first;

    _readingSavedForThisChapter = true;
    await _store.setLastReading(verseToSave);
    if (!mounted) return;
    setState(() {});
  }

  void _ensureFocusedVerseVisible(int verseIndex) {
    if (_focusVerse <= 0) return;
    if (_focusScrollDone) return;

    _focusScrollDone = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;

      final focusedContext = _verseKeys[_focusVerse]?.currentContext;
      if (focusedContext != null) {
        await Scrollable.ensureVisible(
          focusedContext,
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeOutCubic,
          alignment: 0.12,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        );
        return;
      }

      if (!_scrollController.hasClients) return;

      const estimatedTileHeight = 118.0;
      final targetOffset = verseIndex * estimatedTileHeight;
      final maxExtent = _scrollController.position.maxScrollExtent;
      final safeOffset = targetOffset.clamp(0.0, maxExtent);

      await _scrollController.animateTo(
        safeOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  _ParsedBibleReference? _parseReference(String value) {
    final input = value.trim();
    if (input.isEmpty) return null;

    final match = RegExp(r'^\s*([1-3]?\s*[A-Za-z ]+?)\s+(\d+):(\d+)\s*$')
        .firstMatch(input);
    if (match == null) return null;

    final rawBook =
        (match.group(1) ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    final chapter = int.tryParse(match.group(2) ?? '');
    final verse = int.tryParse(match.group(3) ?? '');

    if (rawBook.isEmpty || chapter == null || verse == null) return null;

    final resolvedBook = _resolveBookName(rawBook);
    if (resolvedBook == null) return null;

    return _ParsedBibleReference(
      book: resolvedBook,
      chapter: chapter,
      verse: verse,
    );
  }

  String? _resolveBookName(String input) {
    final normalizedInput =
        input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    const aliases = <String, String>{
      'gen': 'Genesis',
      'genesis': 'Genesis',
      'exo': 'Exodus',
      'exod': 'Exodus',
      'exodus': 'Exodus',
      'lev': 'Leviticus',
      'leviticus': 'Leviticus',
      'num': 'Numbers',
      'numbers': 'Numbers',
      'deut': 'Deuteronomy',
      'deuteronomy': 'Deuteronomy',
      'josh': 'Joshua',
      'joshua': 'Joshua',
      'judg': 'Judges',
      'judges': 'Judges',
      'ruth': 'Ruth',
      '1sam': '1 Samuel',
      '1samuel': '1 Samuel',
      '2sam': '2 Samuel',
      '2samuel': '2 Samuel',
      '1kings': '1 Kings',
      '2kings': '2 Kings',
      '1chronicles': '1 Chronicles',
      '2chronicles': '2 Chronicles',
      'ezra': 'Ezra',
      'neh': 'Nehemiah',
      'nehemiah': 'Nehemiah',
      'esth': 'Esther',
      'esther': 'Esther',
      'job': 'Job',
      'ps': 'Psalms',
      'psa': 'Psalms',
      'psalm': 'Psalms',
      'psalms': 'Psalms',
      'prov': 'Proverbs',
      'proverbs': 'Proverbs',
      'eccl': 'Ecclesiastes',
      'ecclesiastes': 'Ecclesiastes',
      'song': 'Song of Solomon',
      'songofsolomon': 'Song of Solomon',
      'isa': 'Isaiah',
      'isaiah': 'Isaiah',
      'jer': 'Jeremiah',
      'jeremiah': 'Jeremiah',
      'lam': 'Lamentations',
      'lamentations': 'Lamentations',
      'ezek': 'Ezekiel',
      'ezekiel': 'Ezekiel',
      'dan': 'Daniel',
      'daniel': 'Daniel',
      'hos': 'Hosea',
      'hosea': 'Hosea',
      'joel': 'Joel',
      'amos': 'Amos',
      'obad': 'Obadiah',
      'obadiah': 'Obadiah',
      'jonah': 'Jonah',
      'mic': 'Micah',
      'micah': 'Micah',
      'nah': 'Nahum',
      'nahum': 'Nahum',
      'hab': 'Habakkuk',
      'habakkuk': 'Habakkuk',
      'zeph': 'Zephaniah',
      'zephaniah': 'Zephaniah',
      'hag': 'Haggai',
      'haggai': 'Haggai',
      'zech': 'Zechariah',
      'zechariah': 'Zechariah',
      'mal': 'Malachi',
      'malachi': 'Malachi',
      'matt': 'Matthew',
      'matthew': 'Matthew',
      'mark': 'Mark',
      'luke': 'Luke',
      'john': 'John',
      'acts': 'Acts',
      'rom': 'Romans',
      'romans': 'Romans',
      '1cor': '1 Corinthians',
      '1corinthians': '1 Corinthians',
      '2cor': '2 Corinthians',
      '2corinthians': '2 Corinthians',
      'gal': 'Galatians',
      'galatians': 'Galatians',
      'eph': 'Ephesians',
      'ephesians': 'Ephesians',
      'phil': 'Philippians',
      'philippians': 'Philippians',
      'col': 'Colossians',
      'colossians': 'Colossians',
      '1thess': '1 Thessalonians',
      '1thessalonians': '1 Thessalonians',
      '2thess': '2 Thessalonians',
      '2thessalonians': '2 Thessalonians',
      '1tim': '1 Timothy',
      '1timothy': '1 Timothy',
      '2tim': '2 Timothy',
      '2timothy': '2 Timothy',
      'titus': 'Titus',
      'philem': 'Philemon',
      'philemon': 'Philemon',
      'heb': 'Hebrews',
      'hebrews': 'Hebrews',
      'jas': 'James',
      'james': 'James',
      '1pet': '1 Peter',
      '1peter': '1 Peter',
      '2pet': '2 Peter',
      '2peter': '2 Peter',
      '1john': '1 John',
      '2john': '2 John',
      '3john': '3 John',
      'jude': 'Jude',
      'rev': 'Revelation',
      'revelation': 'Revelation',
    };

    if (aliases.containsKey(normalizedInput)) {
      return aliases[normalizedInput];
    }

    for (final book in _store.books) {
      final normalizedBook =
          book.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (normalizedBook == normalizedInput) {
        return book.name;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final book = _store.findBook(_bookName);

    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final themedLight = ThemeController.instance.isLightMode;
        final canGoPrevious = _chapter > 1;

        return Scaffold(
          backgroundColor:
              themedLight ? const Color(0xFFF7F1E6) : const Color(0xFF070B18),
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
                        book == null
                            ? (_incomingReference.isEmpty
                                ? 'Bible Reader'
                                : _incomingReference)
                            : '${book.name} $_chapter',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      _store.translation,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      tooltip: themedLight ? 'Dark mode' : 'Light mode',
                      onPressed: () {
                        ThemeController.instance.toggleTheme();
                      },
                      icon: Icon(
                        themedLight
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
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
              : book == null
                  ? _SafeIncomingScriptureView(
                      isLight: themedLight,
                      reference: _incomingReference,
                      verseText: _incomingVerseText,
                    )
                  : FutureBuilder<List<BibleVerse>>(
                      future: _store.versesForChapter(
                        bookName: _bookName,
                        chapter: _chapter,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'Unable to load this chapter.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: themedLight
                                      ? const Color(0xFF1E1B16)
                                      : Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          );
                        }

                        final verses = snapshot.data ?? const <BibleVerse>[];
                        final canGoNext = verses.isNotEmpty;

                        if (verses.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _persistReadingPositionIfNeeded(verses);
                          });
                        }

                        if (_focusVerse > 0 && verses.isNotEmpty) {
                          final focusedIndex = verses.indexWhere(
                            (item) => item.verse == _focusVerse,
                          );

                          if (focusedIndex >= 0) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _ensureFocusedVerseVisible(focusedIndex);
                            });
                          }
                        }

                        return Column(
                          children: <Widget>[
                            Container(
                              margin: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: themedLight
                                    ? const Color(0xFFFFFBF4)
                                    : const Color(0xFF0E1430),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: themedLight
                                      ? const Color(0xFFE6D8C3)
                                      : Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      '${book.name} $_chapter',
                                      style: TextStyle(
                                        color: themedLight
                                            ? const Color(0xFF1E1B16)
                                            : Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: themedLight
                                          ? const Color(0xFFF2E8D8)
                                          : Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      themedLight
                                          ? 'Light Reader'
                                          : 'Dark Reader',
                                      style: TextStyle(
                                        color: themedLight
                                            ? const Color(0xFF4C453A)
                                            : Colors.white.withOpacity(0.82),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: verses.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                        ),
                                        child: Text(
                                          'No verses found for this chapter yet.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: themedLight
                                                ? const Color(0xFF5F5648)
                                                : Colors.white
                                                    .withOpacity(0.72),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.fromLTRB(
                                        14,
                                        0,
                                        14,
                                        18,
                                      ),
                                      itemCount: verses.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (context, index) {
                                        final verse = verses[index];
                                        final isFocused = _focusVerse > 0 &&
                                            verse.verse == _focusVerse;

                                        final verseKey = _verseKeys.putIfAbsent(
                                          verse.verse,
                                          () => GlobalKey(
                                            debugLabel:
                                                'bible-verse-${verse.verse}',
                                          ),
                                        );

                                        return KeyedSubtree(
                                          key: verseKey,
                                          child: _VerseTile(
                                            isLight: themedLight,
                                            verse: verse,
                                            focused: isFocused,
                                            onTap: () =>
                                                _openVerseActions(verse),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: canGoPrevious
                                          ? () => _goToChapter(
                                                book: book.name,
                                                chapter: _chapter - 1,
                                              )
                                          : null,
                                      icon:
                                          const Icon(Icons.arrow_back_rounded),
                                      label: const Text('Previous'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: themedLight
                                            ? const Color(0xFF3C3428)
                                            : Colors.white,
                                        side: BorderSide(
                                          color: themedLight
                                              ? const Color(0xFFE0D0BC)
                                              : Colors.white.withOpacity(0.22),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: canGoNext
                                          ? () => _goToChapter(
                                                book: book.name,
                                                chapter: _chapter + 1,
                                              )
                                          : null,
                                      icon: const Icon(
                                          Icons.arrow_forward_rounded),
                                      label: const Text('Next'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFFF2C96),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
        );
      },
    );
  }
}

class _ParsedBibleReference {
  final String book;
  final int chapter;
  final int verse;

  const _ParsedBibleReference({
    required this.book,
    required this.chapter,
    required this.verse,
  });
}

class _SafeIncomingScriptureView extends StatelessWidget {
  const _SafeIncomingScriptureView({
    required this.isLight,
    required this.reference,
    required this.verseText,
  });

  final bool isLight;
  final String reference;
  final String verseText;

  @override
  Widget build(BuildContext context) {
    final cleanRef = reference.trim();
    final cleanVerse = verseText.trim();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isLight
                  ? const Color(0xFFE6D8C3)
                  : Colors.white.withOpacity(0.10),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.menu_book_rounded,
                color: Color(0xFFFF2C96),
                size: 38,
              ),
              const SizedBox(height: 12),
              Text(
                cleanRef.isEmpty ? 'Scripture Reward' : cleanRef,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isLight ? const Color(0xFF1E1B16) : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (cleanVerse.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  cleanVerse,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isLight
                        ? const Color(0xFF4C453A)
                        : Colors.white.withOpacity(0.82),
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'The reference was opened safely. If this verse exists in the local Bible asset, it will open directly when the reference format is supported.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isLight
                      ? const Color(0xFF6B6256)
                      : Colors.white.withOpacity(0.56),
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerseTile extends StatelessWidget {
  const _VerseTile({
    required this.isLight,
    required this.verse,
    required this.focused,
    required this.onTap,
  });

  final bool isLight;
  final BibleVerse verse;
  final bool focused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = focused
        ? const Color(0xFFFF2C96)
        : (isLight ? const Color(0xFFE6D8C3) : Colors.white.withOpacity(0.08));

    final tileColor = focused
        ? (isLight ? const Color(0xFFFFF3F9) : const Color(0xFF18163A))
        : (isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430));

    final textColor =
        isLight ? const Color(0xFF2E2A24) : Colors.white.withOpacity(0.94);

    return Material(
      color: tileColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: focused ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: focused
                      ? const Color(0xFFFF2C96)
                      : (isLight
                          ? const Color(0xFFF2E8D8)
                          : Colors.white.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${verse.verse}',
                  style: TextStyle(
                    color: focused
                        ? Colors.white
                        : (isLight ? const Color(0xFF3C3428) : Colors.white),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  verse.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    height: 1.65,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerseActionTile extends StatelessWidget {
  const _VerseActionTile({
    required this.isLight,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool isLight;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Icon(
        icon,
        color: isLight ? const Color(0xFF3C3428) : Colors.white,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isLight ? const Color(0xFF1E1B16) : Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
