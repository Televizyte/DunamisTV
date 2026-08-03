import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../theme/theme_controller.dart';
import '../data/bible_catalog.dart';
import '../models/bible_models.dart';

enum BibleReaderThemeMode {
  dark,
  light,
}

class BibleStore extends ChangeNotifier {
  BibleStore._internal();

  static final BibleStore instance = BibleStore._internal();

  factory BibleStore() => instance;

  static const String _prefsBookmarksKey = 'bible_bookmarks_v1';
  static const String _prefsRecentKey = 'bible_recent_verses_v1';
  static const String _prefsReadingKey = 'bible_last_reading_v1';

  static const String _legacyBibleAssetPath = 'assets/bible/kjv_bible.json';

  final List<BibleBook> _books = <BibleBook>[];
  final List<BibleVerse> _bookmarks = <BibleVerse>[];
  final List<BibleVerse> _recentVerses = <BibleVerse>[];

  final Map<String, BibleBook> _loadedBooks = <String, BibleBook>{};
  final Map<String, String> _bookFiles = <String, String>{};
  final Map<String, BibleBook> _legacyBooks = <String, BibleBook>{};

  bool _loading = true;
  bool _initialized = false;
  bool _legacyLoaded = false;

  String _translation = 'KJV';
  String? _errorMessage;
  BibleReadingPosition? _lastReading;

  Future<void>? _initFuture;

  bool get loading => _loading;
  bool get initialized => _initialized;
  String get translation => _translation;
  String? get errorMessage => _errorMessage;
  BibleReadingPosition? get lastReading => _lastReading;

  BibleReaderThemeMode get readerThemeMode =>
      ThemeController.instance.isLightMode
          ? BibleReaderThemeMode.light
          : BibleReaderThemeMode.dark;

  bool get isLightTheme => ThemeController.instance.isLightMode;

  List<BibleBook> get books => List<BibleBook>.unmodifiable(_books);
  List<BibleVerse> get bookmarks => List<BibleVerse>.unmodifiable(_bookmarks);
  List<BibleVerse> get recentVerses =>
      List<BibleVerse>.unmodifiable(_recentVerses);

  List<BibleBook> get oldTestamentBooks => _books
      .where((book) => book.testament.toLowerCase() == 'old')
      .toList(growable: false);

  List<BibleBook> get newTestamentBooks => _books
      .where((book) => book.testament.toLowerCase() == 'new')
      .toList(growable: false);

  Future<void> init() {
    if (_initialized) {
      return Future<void>.value();
    }

    if (_initFuture != null) {
      return _initFuture!;
    }

    _initFuture = _performInit();
    return _initFuture!;
  }

  Future<void> _performInit() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _loadIndex();
      await _loadSavedState();
      _initialized = true;
    } catch (e) {
      _errorMessage = e.toString();

      try {
        await _loadLegacyBibleAsPrimary();
        await _loadSavedState();
        _initialized = true;
      } catch (_) {
        // Keep original error message.
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadIndex() async {
    _books.clear();
    _bookFiles.clear();

    try {
      final raw = await rootBundle.loadString(bibleIndexPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      _translation = (decoded['translation'] ?? 'KJV').toString();

      final rawBooks = decoded['books'] as List<dynamic>? ?? <dynamic>[];

      for (final item in rawBooks) {
        final map = item as Map<String, dynamic>;
        final name = (map['name'] ?? '').toString().trim();
        final testament = (map['testament'] ?? '').toString().trim();
        final file = (map['file'] ?? '').toString().trim();
        final abbreviation = (map['abbreviation'] ?? '').toString().trim();

        if (name.isEmpty) {
          continue;
        }

        final canonicalName = canonicalizeBibleBookName(name);

        if (file.isNotEmpty) {
          _bookFiles[canonicalName] = file;
        }

        _books.add(
          BibleBook(
            name: canonicalName,
            abbreviation: abbreviation,
            testament: testament,
            chapters: const <List<String>>[],
          ),
        );
      }

      await _loadLegacyBibleMetadataFallback();

      if (_books.isEmpty) {
        await _loadLegacyBibleAsPrimary();
      }
    } catch (_) {
      await _loadLegacyBibleAsPrimary();
    }
  }

  Future<void> _loadLegacyBibleMetadataFallback() async {
    if (_legacyLoaded) return;

    try {
      final raw = await rootBundle.loadString(_legacyBibleAssetPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      final translation = (decoded['translation'] ?? '').toString().trim();
      if (translation.isNotEmpty) {
        _translation = translation;
      }

      final rawBooks = decoded['books'] as List<dynamic>? ?? <dynamic>[];
      final parsed = rawBooks
          .map((item) => BibleBook.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);

      _legacyBooks
        ..clear()
        ..addEntries(
          parsed.map(
            (book) => MapEntry(
              canonicalizeBibleBookName(book.name),
              book,
            ),
          ),
        );

      _legacyLoaded = true;

      if (_books.isEmpty) {
        _books.addAll(parsed);
        return;
      }

      for (var i = 0; i < _books.length; i++) {
        final meta = _books[i];
        final legacy = _legacyBooks[canonicalizeBibleBookName(meta.name)];
        if (legacy == null) continue;

        _books[i] = BibleBook(
          name: meta.name,
          abbreviation: meta.abbreviation.isNotEmpty
              ? meta.abbreviation
              : legacy.abbreviation,
          testament:
              meta.testament.isNotEmpty ? meta.testament : legacy.testament,
          chapters: legacy.chapters,
        );
      }
    } catch (_) {
      // Keep index-based metadata if legacy file is unavailable.
    }
  }

  Future<void> _loadLegacyBibleAsPrimary() async {
    final raw = await rootBundle.loadString(_legacyBibleAssetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    _translation = (decoded['translation'] ?? 'KJV').toString();

    final rawBooks = decoded['books'] as List<dynamic>? ?? <dynamic>[];
    final parsed = rawBooks
        .map((item) => BibleBook.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    _books
      ..clear()
      ..addAll(parsed);

    _bookFiles.clear();

    _legacyBooks
      ..clear()
      ..addEntries(
        parsed.map(
          (book) => MapEntry(
            canonicalizeBibleBookName(book.name),
            book,
          ),
        ),
      );

    _legacyLoaded = true;
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();

    final bookmarkStrings =
        prefs.getStringList(_prefsBookmarksKey) ?? <String>[];
    _bookmarks
      ..clear()
      ..addAll(
        bookmarkStrings
            .map((item) {
              try {
                return BibleVerse.decode(item);
              } catch (_) {
                return null;
              }
            })
            .whereType<BibleVerse>(),
      );

    final recentStrings = prefs.getStringList(_prefsRecentKey) ?? <String>[];
    _recentVerses
      ..clear()
      ..addAll(
        recentStrings
            .map((item) {
              try {
                return BibleVerse.decode(item);
              } catch (_) {
                return null;
              }
            })
            .whereType<BibleVerse>(),
      );

    final readingString = prefs.getString(_prefsReadingKey);
    if (readingString != null && readingString.trim().isNotEmpty) {
      try {
        _lastReading = BibleReadingPosition.fromJson(
          jsonDecode(readingString) as Map<String, dynamic>,
        );
      } catch (_) {
        _lastReading = null;
      }
    }
  }

  Future<BibleBook?> _loadBook(String input) async {
    final canonical = canonicalizeBibleBookName(input);

    if (_loadedBooks.containsKey(canonical)) {
      return _loadedBooks[canonical];
    }

    final fileName = _bookFiles[canonical];
    if (fileName != null && fileName.isNotEmpty) {
      try {
        final raw = await rootBundle.loadString(getBookAssetPath(fileName));
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final book = BibleBook.fromJson(decoded);

        _loadedBooks[canonical] = book;
        return book;
      } catch (_) {
        // Fall through to legacy fallback below.
      }
    }

    if (!_legacyLoaded) {
      await _loadLegacyBibleAsPrimary();
    }

    final legacyBook = _legacyBooks[canonical];
    if (legacyBook != null) {
      _loadedBooks[canonical] = legacyBook;
      return legacyBook;
    }

    return null;
  }

  Future<void> setReaderTheme(BibleReaderThemeMode mode) async {
    await ThemeController.instance.setThemeMode(
      mode == BibleReaderThemeMode.light ? ThemeMode.light : ThemeMode.dark,
    );
    notifyListeners();
  }

  Future<void> toggleReaderTheme() async {
    await ThemeController.instance.toggleTheme();
    notifyListeners();
  }

  BibleBook? findBook(String input) {
    final canonical = canonicalizeBibleBookName(input);

    for (final book in _books) {
      if (canonicalizeBibleBookName(book.name).toLowerCase() ==
          canonical.toLowerCase()) {
        return book;
      }
    }

    return _legacyBooks[canonical];
  }

  Future<BibleBook?> getLoadedBook(String input) async {
    return _loadBook(input);
  }

  Future<int> chapterCountForBook(String bookName) async {
    final book = await _loadBook(bookName);
    return book?.chapterCount ?? 0;
  }

  Future<List<BibleVerse>> versesForChapter({
    required String bookName,
    required int chapter,
  }) async {
    final book = await _loadBook(bookName);
    if (book == null) return const <BibleVerse>[];

    return book.versesForChapter(
      chapter: chapter,
      translation: _translation,
    );
  }

  Future<BibleVerse?> verseByReference(String reference) async {
    final parsed = parseReference(reference);
    if (parsed == null) return null;

    final verses = await versesForChapter(
      bookName: parsed.book,
      chapter: parsed.chapter,
    );

    for (final verse in verses) {
      if (verse.verse == parsed.verse) {
        return verse;
      }
    }

    return null;
  }

  Future<List<BibleSearchResult>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const <BibleSearchResult>[];

    final direct = await verseByReference(trimmed);
    if (direct != null) {
      return <BibleSearchResult>[
        BibleSearchResult(verse: direct, matchIndex: 0),
      ];
    }

    final normalized = trimmed.toLowerCase();
    final results = <BibleSearchResult>[];

    for (final meta in _books) {
      final loadedBook = await _loadBook(meta.name);
      if (loadedBook == null) continue;

      for (var chapterIndex = 0;
          chapterIndex < loadedBook.chapters.length;
          chapterIndex++) {
        final chapter = chapterIndex + 1;
        final verses = loadedBook.versesForChapter(
          chapter: chapter,
          translation: _translation,
        );

        for (final verse in verses) {
          final haystack = verse.text.toLowerCase();
          final matchIndex = haystack.indexOf(normalized);
          if (matchIndex >= 0) {
            results.add(
              BibleSearchResult(
                verse: verse,
                matchIndex: matchIndex,
              ),
            );
          }
        }
      }
    }

    return results;
  }

  bool isBookmarked(BibleVerse verse) {
    return _bookmarks.contains(verse);
  }

  Future<void> toggleBookmark(BibleVerse verse) async {
    final exists = isBookmarked(verse);
    if (exists) {
      _bookmarks.remove(verse);
    } else {
      _bookmarks.insert(0, verse);
    }

    await _persistBookmarks();
    notifyListeners();
  }

  Future<void> addRecentVerse(BibleVerse verse) async {
    _recentVerses.remove(verse);
    _recentVerses.insert(0, verse);

    if (_recentVerses.length > 24) {
      _recentVerses.removeRange(24, _recentVerses.length);
    }

    await _persistRecentVerses();
    notifyListeners();
  }

  Future<void> setLastReading(BibleVerse verse) async {
    _lastReading = BibleReadingPosition.fromVerse(verse);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsReadingKey,
      jsonEncode(_lastReading!.toJson()),
    );

    await addRecentVerse(verse);
    notifyListeners();
  }

  Future<void> clearRecentVerses() async {
    _recentVerses.clear();
    await _persistRecentVerses();
    notifyListeners();
  }

  Future<void> _persistBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsBookmarksKey,
      _bookmarks.map((item) => item.encode()).toList(growable: false),
    );
  }

  Future<void> _persistRecentVerses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsRecentKey,
      _recentVerses.map((item) => item.encode()).toList(growable: false),
    );
  }
}

class ParsedBibleReference {
  const ParsedBibleReference({
    required this.book,
    required this.chapter,
    required this.verse,
  });

  final String book;
  final int chapter;
  final int verse;
}

ParsedBibleReference? parseReference(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final match = RegExp(
    r'^((?:[1-3]\s*)?[A-Za-z]+(?:\s+[A-Za-z]+)*)\s+(\d{1,3}):(\d{1,3})$',
  ).firstMatch(trimmed);

  if (match == null) return null;

  final rawBook = (match.group(1) ?? '').trim();
  final chapter = int.tryParse(match.group(2) ?? '');
  final verse = int.tryParse(match.group(3) ?? '');

  if (rawBook.isEmpty || chapter == null || verse == null) return null;

  return ParsedBibleReference(
    book: canonicalizeBibleBookName(rawBook),
    chapter: chapter,
    verse: verse,
  );
}
