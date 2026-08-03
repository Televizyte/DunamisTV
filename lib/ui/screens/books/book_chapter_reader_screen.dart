import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../features/books/models/book_models.dart';
import '../../../features/books/services/books_service.dart';
import '../../../features/books/state/book_reader_progress_service.dart';
import '../../../services/ads_service.dart';
import '../../../theme/theme_controller.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';
import 'widgets/book_reader_settings_sheet.dart';
import 'widgets/book_reader_tools.dart';

class BookChapterReaderScreen extends StatefulWidget {
  final BookItem? initialBook;
  final BookChapter? initialChapter;
  final String bookId;
  final String chapterId;

  const BookChapterReaderScreen({
    super.key,
    this.initialBook,
    this.initialChapter,
    this.bookId = '',
    this.chapterId = '',
  });

  @override
  State<BookChapterReaderScreen> createState() =>
      _BookChapterReaderScreenState();
}

class _BookChapterReaderScreenState extends State<BookChapterReaderScreen> {
  final BooksService _service = BooksService();
  final PageController _pageController = PageController();
  final FlutterTts _tts = FlutterTts();

  BookItem? _book;
  BookChapter? _chapter;
  List<BookChapter> _chapters = const <BookChapter>[];
  BookReaderSettings _settings = const BookReaderSettings();
  bool _loading = true;
  String _error = '';
  int _pageIndex = 0;
  bool _focusMode = false;
  bool _ttsReady = false;
  bool _isSpeaking = false;
  bool _isPaused = false;
  String _ttsStatus = 'Ready';

  @override
  void initState() {
    super.initState();
    AdsService.instance.preloadInterstitial(tabKey: 'explore.books.reader');
    _book = widget.initialBook;
    _chapter = widget.initialChapter;
    _bootstrap();
  }

  @override
  void dispose() {
    _stopTts(silent: true);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final settings = await BookReaderProgressService.instance.loadSettings();
    if (mounted) setState(() => _settings = settings);
    await _configureTts();
    await _loadContent();
  }

  Future<void> _configureTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(_settings.speechRate.clamp(0.25, 0.85));
      await _tts.setPitch(_settings.speechPitch.clamp(0.75, 1.35));
      await _tts.awaitSpeakCompletion(false);
      _tts.setStartHandler(() {
        if (!mounted) return;
        setState(() {
          _ttsReady = true;
          _isSpeaking = true;
          _isPaused = false;
          _ttsStatus = 'Reading';
        });
      });
      _tts.setCompletionHandler(() {
        if (!mounted) return;
        setState(() {
          _isSpeaking = false;
          _isPaused = false;
          _ttsStatus = 'Finished';
        });
      });
      _tts.setCancelHandler(() {
        if (!mounted) return;
        setState(() {
          _isSpeaking = false;
          _isPaused = false;
          _ttsStatus = 'Stopped';
        });
      });
      _tts.setPauseHandler(() {
        if (!mounted) return;
        setState(() {
          _isSpeaking = false;
          _isPaused = true;
          _ttsStatus = 'Paused';
        });
      });
      if (mounted) {
        setState(() {
          _ttsReady = true;
          _ttsStatus = 'Ready';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _ttsReady = false;
          _ttsStatus = 'Text-to-speech is not available on this device.';
        });
      }
    }
  }

  Future<void> _loadContent() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      BookItem? book = _book;
      BookChapter? chapter = _chapter;

      final requestedBookId = widget.bookId.trim().isNotEmpty
          ? widget.bookId.trim()
          : (book?.identifier ?? '');

      if (requestedBookId.isNotEmpty) {
        try {
          book = await _service.fetchBook(requestedBookId);
        } catch (_) {
          if (book == null) rethrow;
        }
      }

      List<BookChapter> freshChapters = book?.toc ?? const <BookChapter>[];
      if (book != null) {
        try {
          final endpointChapters =
              await _service.fetchBookChapters(book.identifier);
          if (endpointChapters.isNotEmpty) freshChapters = endpointChapters;
        } catch (_) {}
      }

      final requestedChapterId = widget.chapterId.trim().isNotEmpty
          ? widget.chapterId.trim()
          : (chapter?.identifier ?? '');

      if (book != null && requestedChapterId.isNotEmpty) {
        chapter = await _service.fetchChapter(
          bookIdOrSlug: book.identifier,
          chapterIdOrSlug: requestedChapterId,
        );
      }

      if (chapter != null && chapter.bodyHtml.trim().isEmpty && book != null) {
        chapter = await _service.fetchChapter(
          bookIdOrSlug: book.identifier,
          chapterIdOrSlug: chapter.identifier,
        );
      }

      if (!mounted) return;
      setState(() {
        _book = book;
        _chapter = chapter;
        _chapters = freshChapters;
        _loading = false;
        _pageIndex = 0;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_pageController.hasClients) return;
        try {
          _pageController.jumpToPage(0);
        } catch (_) {}
      });

      _saveProgress();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _saveProgress() async {
    final book = _book;
    final chapter = _chapter;
    if (book == null || chapter == null) return;
    await BookReaderProgressService.instance.saveProgress(
      bookId: book.identifier,
      chapterId: chapter.identifier,
      pageIndex: _pageIndex,
    );
  }

  String get _plainText {
    final chapter = _chapter;
    if (chapter == null) return '';
    final html = chapter.bodyHtml.trim();
    if (html.isEmpty) return '';
    return _stripHtml(html);
  }

  List<_BookReaderPage> _buildPages(BookItem book, BookChapter chapter) {
    final rawHtml = chapter.bodyHtml.trim();
    if (rawHtml.isEmpty) {
      return <_BookReaderPage>[
        _BookReaderPage.html('<p>Content is not available yet.</p>')
      ];
    }

    final spec = BookPageSizeSpec.fromBackend(book.bookPageSize);
    final html = _normalizeHtmlForPage(rawHtml);
    final blocks = _extractReadableHtmlBlocks(html);
    if (blocks.isEmpty) return <_BookReaderPage>[_BookReaderPage.html(html)];

    final fontFactor = (_settings.fontSize / 16.0).clamp(0.72, 2.05);
    final lineFactor = (_settings.lineHeight / 1.55).clamp(0.82, 1.70);
    final shapeFactor = _shapeWordsFactor(spec.aspectRatio);
    final pageBudget =
        (spec.baseWords * 2.05 * shapeFactor / (fontFactor * lineFactor))
            .clamp(120, 420)
            .round();

    final pages = <_BookReaderPage>[];
    final buffer = StringBuffer();
    var weight = 0;

    void flush() {
      final pageHtml = buffer.toString().trim();
      if (pageHtml.isEmpty) return;
      pages.add(_BookReaderPage.html(pageHtml));
      buffer.clear();
      weight = 0;
    }

    for (final block in blocks) {
      final blockWeight = _estimateHtmlBlockWeight(block);
      if (weight > 0 && weight + blockWeight > pageBudget) flush();
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln(block);
      weight += blockWeight;
    }
    flush();

    return pages.isEmpty
        ? <_BookReaderPage>[_BookReaderPage.html(html)]
        : pages;
  }

  String _normalizeHtmlForPage(String html) {
    return html
        .replaceAll(
            RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '<br>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _extractReadableHtmlBlocks(String html) {
    final blocks = <String>[];
    final blockExp = RegExp(
      r'''<(h[1-6]|p|blockquote|ul|ol|figure|img|div)[^>]*>[\s\S]*?</\1>|<img[^>]*>''',
      caseSensitive: false,
    );

    for (final match in blockExp.allMatches(html)) {
      final block = match.group(0)?.trim() ?? '';
      if (block.isNotEmpty) blocks.add(block);
    }

    if (blocks.isNotEmpty) return blocks;
    final plain = _stripHtml(html).trim();
    if (plain.isEmpty) return const <String>[];
    return <String>['<p>${_escapeHtml(plain)}</p>'];
  }

  int _estimateHtmlBlockWeight(String html) {
    final lower = html.toLowerCase();
    final words = _stripHtml(html)
        .split(RegExp(r'\s+'))
        .where((e) => e.trim().isNotEmpty)
        .length;
    if (lower.contains('<img')) return math.max(80, words + 80);
    if (lower.contains('<h1') || lower.contains('<h2'))
      return math.max(18, words + 14);
    if (lower.contains('<h3') || lower.contains('<h4'))
      return math.max(14, words + 10);
    if (lower.contains('<blockquote')) return math.max(22, words + 16);
    return math.max(8, words + 5);
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  double _shapeWordsFactor(double aspectRatio) {
    if (aspectRatio > 1.2) return 0.78;
    if (aspectRatio > 0.95) return 0.82;
    if (aspectRatio < 0.68) return 0.88;
    return 1.0;
  }

  TextStyle _readerTextStyle(
      {required BookItem book, required bool isLight, required bool paper}) {
    final resolvedFont = _resolvedFont(book);
    return TextStyle(
      color: paper
          ? _pageTextColor(book, isLight)
          : (isLight
              ? const Color(0xFF1E1B16)
              : Colors.white.withOpacity(0.88)),
      fontSize: _settings.fontSize,
      height: _settings.lineHeight,
      fontFamily: resolvedFont == 'serif' ? 'Georgia' : null,
      fontWeight: FontWeight.w500,
    );
  }

  String _resolvedFont(BookItem book) {
    final local = _settings.fontFamily.trim().toLowerCase();
    if (local.isNotEmpty && local != 'backend') return local;
    return book.resolvedReaderFont;
  }

  String _resolvedPageTheme(BookItem book) {
    final local = _settings.pageTheme.trim().toLowerCase();
    if (local.isNotEmpty && local != 'backend') return local;
    return book.resolvedPageTheme;
  }

  Color _pageColor(BookItem book, bool isLight) {
    final theme = _resolvedPageTheme(book);
    switch (theme) {
      case 'dark':
      case 'night':
        return const Color(0xFF171A25);
      case 'white':
      case 'clean':
        return Colors.white;
      case 'sepia':
      case 'warm':
        return const Color(0xFFF4E6CC);
      case 'classic':
      default:
        return isLight ? const Color(0xFFFFFBF4) : const Color(0xFF171A25);
    }
  }

  Color _pageTextColor(BookItem book, bool isLight) {
    final theme = _resolvedPageTheme(book);
    if (theme == 'dark' || theme == 'night')
      return Colors.white.withOpacity(0.90);
    if (theme == 'white' ||
        theme == 'clean' ||
        theme == 'sepia' ||
        theme == 'warm') {
      return const Color(0xFF1E1B16);
    }
    return isLight ? const Color(0xFF1E1B16) : Colors.white.withOpacity(0.90);
  }

  Future<void> _openSettings() async {
    final book = _book;
    final next = await showBookReaderSettingsSheet(
      context: context,
      settings: _settings,
      backendFont: book?.resolvedReaderFont ?? 'serif',
      backendTheme: book?.resolvedPageTheme ?? 'classic',
      backendPageSize: book?.pageSizeLabel ?? 'Standard Book 6×9',
    );
    if (next == null) return;

    setState(() {
      _settings = next;
      _pageIndex = 0;
    });

    await BookReaderProgressService.instance.saveSettings(next);
    await _configureTts();
    await _saveProgress();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pageController.hasClients) return;
      try {
        _pageController.jumpToPage(0);
      } catch (_) {}
    });
  }

  String _currentReaderActionText() {
    final book = _book;
    final chapter = _chapter;
    if (book == null || chapter == null) return '';

    if (_settings.readingMode == BookReadingMode.pages) {
      final pages = _buildPages(book, chapter);
      if (pages.isNotEmpty && _pageIndex >= 0 && _pageIndex < pages.length) {
        final current = _stripHtml(pages[_pageIndex].html).trim();
        if (current.isNotEmpty) return current;
      }
    }
    return _plainText.trim();
  }

  String _currentReaderActionLabel() {
    return _settings.readingMode == BookReadingMode.pages
        ? 'Current page'
        : 'Chapter';
  }

  Future<void> _copyChapter() async {
    final text = _currentReaderActionText();
    if (text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_currentReaderActionLabel()} copied')));
  }

  void _shareChapter() {
    final book = _book;
    final chapter = _chapter;
    if (book == null || chapter == null) return;
    final text = _currentReaderActionText();
    if (text.trim().isEmpty) return;
    Share.share(
        '${book.title}\n${chapter.title}\n\n$text\n\nShared from Book Reader');
  }

  void _sendToNotes() {
    final book = _book;
    final chapter = _chapter;
    if (book == null || chapter == null) return;
    context.push('/tools/notes/editor', extra: {
      'title': '${book.title} — ${chapter.title}',
      'prefill': _currentReaderActionText(),
      'sourceType': _settings.readingMode == BookReadingMode.pages
          ? 'book.page'
          : 'book.chapter',
      'sourceId': '${book.identifier}/${chapter.identifier}',
    });
  }

  void _sendToQuoteCreator() {
    final book = _book;
    final chapter = _chapter;
    if (book == null || chapter == null) return;
    final text = _currentReaderActionText();
    final prefill =
        text.length > 320 ? '${text.substring(0, 320).trim()}...' : text;
    context.push('/tools/quote', extra: {
      'designData': {
        'quote': prefill,
        'author': book.authorName.trim().isEmpty ? book.title : book.authorName,
        'reference': chapter.title,
        'source_type': _settings.readingMode == BookReadingMode.pages
            ? 'book.page'
            : 'book.chapter',
        'source_id': '${book.identifier}/${chapter.identifier}',
      },
    });
  }

  Future<void> _speakCurrentPortion({bool chapterWide = false}) async {
    final text =
        chapterWide ? _plainText.trim() : _currentReaderActionText().trim();
    if (text.isEmpty) return;
    try {
      await _configureTts();
      await _tts.stop();
      await _tts.speak(text);
      if (mounted) {
        setState(() {
          _isSpeaking = true;
          _isPaused = false;
          _ttsStatus = 'Reading';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Read Aloud could not start: $e')),
      );
    }
  }

  Future<void> _pauseTts() async {
    try {
      await _tts.pause();
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _isPaused = true;
          _ttsStatus = 'Paused';
        });
      }
    } catch (_) {
      await _stopTts();
    }
  }

  Future<void> _stopTts({bool silent = false}) async {
    try {
      await _tts.stop();
    } catch (_) {}
    if (!mounted || silent) return;
    setState(() {
      _isSpeaking = false;
      _isPaused = false;
      _ttsStatus = 'Stopped';
    });
  }

  void _openListenControls() {
    final isLight = ThemeController.instance.isLightMode;
    final bg = isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0D1228);
    final titleColor = isLight ? const Color(0xFF1E1B16) : Colors.white;
    final subColor =
        isLight ? const Color(0xFF6B6256) : Colors.white.withOpacity(0.70);
    final scope = _currentReaderActionLabel();

    Widget action(
        {required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap}) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Icon(icon, color: titleColor),
        title: Text(title,
            style: TextStyle(color: titleColor, fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle,
            style: TextStyle(color: subColor, fontWeight: FontWeight.w600)),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
      );
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.82),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          top: false,
          child: ListView(
            primary: false,
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isLight
                        ? const Color(0xFFD2C2AC)
                        : Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Read Aloud',
                  style: TextStyle(
                      color: titleColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(_ttsReady ? 'Status: $_ttsStatus' : _ttsStatus,
                  style:
                      TextStyle(color: subColor, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              action(
                icon: Icons.play_arrow_rounded,
                title: 'Read $scope',
                subtitle: 'Listen to what is currently displayed.',
                onTap: () => _speakCurrentPortion(),
              ),
              action(
                icon: Icons.menu_book_rounded,
                title: 'Read Full Chapter',
                subtitle: 'Listen from the beginning of this chapter.',
                onTap: () => _speakCurrentPortion(chapterWide: true),
              ),
              if (_isSpeaking)
                action(
                  icon: Icons.pause_rounded,
                  title: 'Pause',
                  subtitle: 'Pause the current reading voice.',
                  onTap: _pauseTts,
                ),
              if (_isPaused)
                action(
                  icon: Icons.play_circle_fill_rounded,
                  title: 'Resume / Restart',
                  subtitle:
                      'Continue by restarting the selected reading portion.',
                  onTap: () => _speakCurrentPortion(),
                ),
              action(
                icon: Icons.stop_rounded,
                title: 'Stop',
                subtitle: 'Stop the reading voice.',
                onTap: _stopTts,
              ),
              action(
                icon: Icons.tune_rounded,
                title: 'Voice Settings',
                subtitle: 'Adjust speech speed and pitch.',
                onTap: _openSettings,
              ),
            ],
          ),
        );
      },
    );
  }

  void _openFocusActions() {
    final isLight = ThemeController.instance.isLightMode;
    final bg = isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0D1228);
    final titleColor = isLight ? const Color(0xFF1E1B16) : Colors.white;
    final subColor =
        isLight ? const Color(0xFF6B6256) : Colors.white.withOpacity(0.70);
    final scope = _currentReaderActionLabel();

    Widget action(
        {required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap}) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Icon(icon, color: titleColor),
        title: Text(title,
            style: TextStyle(color: titleColor, fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle,
            style: TextStyle(color: subColor, fontWeight: FontWeight.w600)),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
      );
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.82),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          top: false,
          child: ListView(
            primary: false,
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isLight
                        ? const Color(0xFFD2C2AC)
                        : Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Reader Actions',
                  style: TextStyle(
                      color: titleColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                _settings.readingMode == BookReadingMode.pages
                    ? 'Actions will use the current page.'
                    : 'Actions will use the current chapter.',
                style: TextStyle(color: subColor, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              action(
                  icon: Icons.record_voice_over_rounded,
                  title: 'Listen to $scope',
                  subtitle: 'Use device text-to-speech.',
                  onTap: _openListenControls),
              action(
                  icon: Icons.copy_rounded,
                  title: 'Copy $scope',
                  subtitle: 'Copy the readable text to clipboard.',
                  onTap: _copyChapter),
              action(
                  icon: Icons.share_rounded,
                  title: 'Share $scope',
                  subtitle: 'Share only what you are currently reading.',
                  onTap: _shareChapter),
              action(
                  icon: Icons.note_add_rounded,
                  title: '$scope to Notes',
                  subtitle: 'Save this reading portion inside Notes.',
                  onTap: _sendToNotes),
              action(
                  icon: Icons.format_quote_rounded,
                  title: '$scope to Quote',
                  subtitle: 'Create a quote from this reading portion.',
                  onTap: _sendToQuoteCreator),
              action(
                  icon: Icons.tune_rounded,
                  title: 'Reader Settings',
                  subtitle:
                      'Change page mode, font, theme, spacing, and voice.',
                  onTap: _openSettings),
            ],
          ),
        );
      },
    );
  }

  void _openToc(bool isLight) {
    final book = _book;
    final chapters =
        _chapters.isNotEmpty ? _chapters : (book?.toc ?? const <BookChapter>[]);
    if (book == null || chapters.isEmpty) return;
    final bg = isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0D1228);
    final titleColor = isLight ? const Color(0xFF1E1B16) : Colors.white;
    final subColor =
        isLight ? const Color(0xFF6B6256) : Colors.white.withOpacity(0.58);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              Text('Table of Contents',
                  style: TextStyle(
                      color: titleColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              ...chapters.map((chapter) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(chapter.title,
                      style: TextStyle(
                          color: titleColor, fontWeight: FontWeight.w800)),
                  subtitle: Text('${chapter.estimatedReadingMinutes} min read',
                      style: TextStyle(color: subColor)),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color:
                          isLight ? const Color(0xFF6B6256) : Colors.white70),
                  onTap: () {
                    Navigator.pop(context);
                    _stopTts(silent: true);
                    context.pushReplacement('/tools/books/chapter',
                        extra: {'book': book, 'chapter': chapter});
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _goRelativeChapter(int delta) async {
    final book = _book;
    final chapter = _chapter;
    final chapters =
        _chapters.isNotEmpty ? _chapters : (book?.toc ?? const <BookChapter>[]);
    if (book == null || chapter == null || chapters.isEmpty) return;
    final current = chapters.indexWhere(
        (e) => e.identifier == chapter.identifier || e.id == chapter.id);
    if (current < 0) return;
    final next = current + delta;
    if (next < 0 || next >= chapters.length) return;

    await AdsService.instance
        .trackAndMaybeShowInterstitial(context, tabKey: 'explore.books.reader');
    if (!mounted) return;
    await _stopTts(silent: true);
    context.pushReplacement('/tools/books/chapter',
        extra: {'book': book, 'chapter': chapters[next]});
  }

  bool _hasRelativeChapter(int delta) {
    final book = _book;
    final chapter = _chapter;
    final chapters =
        _chapters.isNotEmpty ? _chapters : (book?.toc ?? const <BookChapter>[]);
    if (book == null || chapter == null || chapters.isEmpty) return false;
    final current = chapters.indexWhere(
        (e) => e.identifier == chapter.identifier || e.id == chapter.id);
    if (current < 0) return false;
    final next = current + delta;
    return next >= 0 && next < chapters.length;
  }

  List<_BookReaderPage> _currentPages() {
    final book = _book;
    final chapter = _chapter;
    if (book == null || chapter == null) return const <_BookReaderPage>[];
    return _buildPages(book, chapter);
  }

  Future<void> _goPreviousReaderStep() async {
    if (_settings.readingMode == BookReadingMode.pages) {
      final pages = _currentPages();
      if (pages.isNotEmpty && _pageIndex > 0) {
        await _animateToReaderPage(_pageIndex - 1);
        return;
      }
    }
    await _goRelativeChapter(-1);
  }

  Future<void> _goNextReaderStep() async {
    if (_settings.readingMode == BookReadingMode.pages) {
      final pages = _currentPages();
      if (pages.isNotEmpty && _pageIndex < pages.length - 1) {
        await _animateToReaderPage(_pageIndex + 1);
        return;
      }
    }
    await _goRelativeChapter(1);
  }

  Future<void> _animateToReaderPage(int targetPage) async {
    if (!mounted) return;
    setState(() => _pageIndex = targetPage);
    await _saveProgress();
    if (!_pageController.hasClients) return;
    try {
      if (_settings.pageAnimation == BookPageAnimation.off) {
        _pageController.jumpToPage(targetPage);
        return;
      }
      await _pageController.animateToPage(targetPage,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final isLight = ThemeController.instance.isLightMode;
        final book = _book;
        final chapter = _chapter;
        final titleColor = isLight ? const Color(0xFF1E1B16) : Colors.white;
        final subColor =
            isLight ? const Color(0xFF6B6256) : Colors.white.withOpacity(0.64);
        final readerPages = book != null && chapter != null
            ? _buildPages(book, chapter)
            : const <_BookReaderPage>[];
        final isPageMode = _settings.readingMode == BookReadingMode.pages;
        final hasPreviousReaderStep =
            isPageMode ? _pageIndex > 0 : _hasRelativeChapter(-1);
        final hasNextReaderStep = isPageMode
            ? _pageIndex < readerPages.length - 1
            : _hasRelativeChapter(1);

        return Scaffold(
          appBar: _focusMode
              ? null
              : DxmTopBar(
                  title: chapter?.title ?? 'Book Reader',
                  showBack: true,
                  showMenu: true,
                  onRefresh: _loadContent,
                  actions: [
                    IconButton(
                      tooltip: 'Focus reader',
                      onPressed: () => setState(() => _focusMode = true),
                      icon: const Icon(Icons.fullscreen_rounded,
                          color: Colors.white),
                    ),
                    IconButton(
                      tooltip: 'Table of contents',
                      onPressed: () => _openToc(isLight),
                      icon: const Icon(Icons.list_alt_rounded,
                          color: Colors.white),
                    ),
                  ],
                ),
          bottomNavigationBar: const SafeArea(
              top: false,
              child: BannerAdWidget(tabKey: 'explore.books.reader')),
          floatingActionButton: _focusMode
              ? SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'book-reader-focus-actions',
                        backgroundColor: const Color(0xFF2A1B67),
                        foregroundColor: Colors.white,
                        onPressed: _openFocusActions,
                        child: const Icon(Icons.more_horiz_rounded),
                      ),
                      const SizedBox(height: 10),
                      FloatingActionButton.small(
                        heroTag: 'book-reader-focus-exit',
                        backgroundColor: const Color(0xFFFF2C96),
                        foregroundColor: Colors.white,
                        onPressed: () => setState(() => _focusMode = false),
                        child: const Icon(Icons.fullscreen_exit_rounded),
                      ),
                    ],
                  ),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
          body: GradientPageBackground(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? _ErrorView(
                        error: _error, onRetry: _loadContent, isLight: isLight)
                    : book == null || chapter == null
                        ? _ErrorView(
                            error: 'Book chapter is not available.',
                            onRetry: _loadContent,
                            isLight: isLight)
                        : Column(
                            children: [
                              if (!_focusMode)
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 12, 16, 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              book.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: subColor,
                                                  fontSize: 12.4,
                                                  fontWeight: FontWeight.w800),
                                            ),
                                          ),
                                          if (_isSpeaking || _isPaused)
                                            _MiniPageBadge(
                                                label: _ttsStatus,
                                                isLight: isLight),
                                          if (_settings.readingMode ==
                                              BookReadingMode.pages) ...[
                                            const SizedBox(width: 6),
                                            _MiniPageBadge(
                                                label: book.pageSizeLabel,
                                                isLight: isLight),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        chapter.title,
                                        style: TextStyle(
                                            color: titleColor,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            height: 1.1),
                                      ),
                                      const SizedBox(height: 10),
                                      BookReaderTools(
                                        isLight: isLight,
                                        onCopy: _copyChapter,
                                        onShare: _shareChapter,
                                        onNotes: _sendToNotes,
                                        onQuote: _sendToQuoteCreator,
                                        onSettings: _openSettings,
                                        onListen: _openListenControls,
                                      ),
                                    ],
                                  ),
                                ),
                              Expanded(
                                child: _settings.readingMode ==
                                        BookReadingMode.pages
                                    ? _PageReader(
                                        book: book,
                                        chapterTitle: chapter.title,
                                        pages: readerPages,
                                        controller: _pageController,
                                        settings: _settings,
                                        textStyle: _readerTextStyle(
                                            book: book,
                                            isLight: isLight,
                                            paper: true),
                                        pageColor: _pageColor(book, isLight),
                                        pageTextColor:
                                            _pageTextColor(book, isLight),
                                        isLight: isLight,
                                        isFocusMode: _focusMode,
                                        index: _pageIndex,
                                        canPrevious: hasPreviousReaderStep,
                                        canNext: hasNextReaderStep,
                                        onPrevious: _goPreviousReaderStep,
                                        onNext: _goNextReaderStep,
                                        onChanged: (value) {
                                          setState(() => _pageIndex = value);
                                          _saveProgress();
                                        },
                                      )
                                    : _ScrollReader(
                                        html: chapter.bodyHtml,
                                        plainFallback: _plainText,
                                        textStyle: _readerTextStyle(
                                            book: book,
                                            isLight: isLight,
                                            paper: false),
                                        isLight: isLight,
                                      ),
                              ),
                              if (!_focusMode &&
                                  _settings.readingMode !=
                                      BookReadingMode.pages)
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: hasPreviousReaderStep
                                              ? _goPreviousReaderStep
                                              : null,
                                          icon: const Icon(
                                              Icons.chevron_left_rounded),
                                          label: Text(isPageMode
                                              ? 'Previous Page'
                                              : 'Previous'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: isLight
                                                ? const Color(0xFF1E1B16)
                                                : Colors.white,
                                            side: BorderSide(
                                                color: isLight
                                                    ? const Color(0xFFE0D0BC)
                                                    : Colors.white
                                                        .withOpacity(0.22)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: hasNextReaderStep
                                              ? _goNextReaderStep
                                              : null,
                                          icon: const Icon(
                                              Icons.chevron_right_rounded),
                                          label: Text(isPageMode
                                              ? 'Next Page'
                                              : 'Next'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: isLight
                                                ? const Color(0xFF1E1B16)
                                                : Colors.white,
                                            side: BorderSide(
                                                color: isLight
                                                    ? const Color(0xFFE0D0BC)
                                                    : Colors.white
                                                        .withOpacity(0.22)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
          ),
        );
      },
    );
  }

  String _stripHtml(String value) {
    return value
        .replaceAll(
            RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<img[^>]*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<h[1-6][^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'")
        .replaceAll('&ldquo;', '“')
        .replaceAll('&rdquo;', '”')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n[ \t]+'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}

class _ScrollReader extends StatelessWidget {
  final String html;
  final String plainFallback;
  final TextStyle textStyle;
  final bool isLight;

  const _ScrollReader({
    required this.html,
    required this.plainFallback,
    required this.textStyle,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final panel =
        isLight ? const Color(0xFFFFFBF4) : Colors.white.withOpacity(0.055);
    final border =
        isLight ? const Color(0xFFE6D8C3) : Colors.white.withOpacity(0.08);

    return SelectionArea(
      child: ListView(
        primary: false,
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: border),
            ),
            child: html.trim().isNotEmpty
                ? HtmlWidget(html, textStyle: textStyle)
                : Text(
                    plainFallback.isEmpty
                        ? 'Content is not available yet.'
                        : plainFallback,
                    style: textStyle),
          ),
        ],
      ),
    );
  }
}

class _PageReader extends StatelessWidget {
  final BookItem book;
  final String chapterTitle;
  final List<_BookReaderPage> pages;
  final PageController controller;
  final BookReaderSettings settings;
  final TextStyle textStyle;
  final Color pageColor;
  final Color pageTextColor;
  final bool isLight;
  final bool isFocusMode;
  final int index;
  final bool canPrevious;
  final bool canNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<int> onChanged;

  const _PageReader({
    required this.book,
    required this.chapterTitle,
    required this.pages,
    required this.controller,
    required this.settings,
    required this.textStyle,
    required this.pageColor,
    required this.pageTextColor,
    required this.isLight,
    required this.isFocusMode,
    required this.index,
    required this.canPrevious,
    required this.canNext,
    required this.onPrevious,
    required this.onNext,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final indicatorColor =
        isLight ? const Color(0xFF6B6256) : Colors.white.withOpacity(0.72);
    final spec = BookPageSizeSpec.fromBackend(book.bookPageSize);
    final bottomIndicatorHeight = isFocusMode ? 26.0 : 30.0;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = math.max(
                  240.0, constraints.maxWidth - (isFocusMode ? 8 : 10));
              final availableHeight = math.max(
                320.0,
                constraints.maxHeight -
                    bottomIndicatorHeight -
                    (isFocusMode ? 2 : 4),
              );
              final maxReaderWidth = isFocusMode ? 980.0 : 760.0;
              final widthByHeight = availableHeight * spec.aspectRatio;
              final pageWidth = math.min(
                  math.min(availableWidth, widthByHeight), maxReaderWidth);
              final safePageWidth = math.max(240.0, pageWidth);
              final pageHeight =
                  math.min(availableHeight, safePageWidth / spec.aspectRatio);
              final horizontalPadding = isFocusMode ? 2.0 : 4.0;
              final verticalPadding = isFocusMode ? 2.0 : 4.0;

              return Stack(
                children: [
                  PageView.builder(
                    controller: controller,
                    physics: const PageScrollPhysics(),
                    itemCount: pages.length,
                    onPageChanged: onChanged,
                    itemBuilder: (context, pageIndex) {
                      final page = pages[pageIndex];
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          verticalPadding,
                          horizontalPadding,
                          verticalPadding,
                        ),
                        child: Center(
                          child: SizedBox(
                            width: safePageWidth,
                            height: pageHeight,
                            child: _BookPageCard(
                              page: page,
                              pageNumber: pageIndex + 1,
                              totalPages: pages.length,
                              bookTitle: book.title,
                              chapterTitle: chapterTitle,
                              pageLabel: spec.label,
                              pageColor: pageColor,
                              pageTextColor: pageTextColor,
                              textStyle: textStyle,
                              compact: isFocusMode,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned.fill(
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: canPrevious ? onPrevious : null,
                            child: const SizedBox.expand(),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: canNext ? onNext : null,
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isFocusMode)
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: bottomIndicatorHeight,
                      child: Center(
                        child: _PageStepButton(
                          icon: Icons.chevron_left_rounded,
                          enabled: canPrevious,
                          onTap: onPrevious,
                          isLight: isLight,
                        ),
                      ),
                    ),
                  if (!isFocusMode)
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: bottomIndicatorHeight,
                      child: Center(
                        child: _PageStepButton(
                          icon: Icons.chevron_right_rounded,
                          enabled: canNext,
                          onTap: onNext,
                          isLight: isLight,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        SizedBox(
          height: bottomIndicatorHeight,
          child: Center(
            child: Text(
              'Page ${index + 1} of ${pages.length}   ${spec.label}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: indicatorColor.withOpacity(isFocusMode ? 0.58 : 0.78),
                fontWeight: FontWeight.w800,
                fontSize: isFocusMode ? 11 : 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PageStepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final bool isLight;

  const _PageStepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: (isLight ? Colors.white : const Color(0xFF11152A))
          .withOpacity(enabled ? 0.82 : 0.28),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 22,
            color: enabled
                ? (isLight ? const Color(0xFF2A1B67) : Colors.white)
                : (isLight ? const Color(0xFFB8AB9D) : Colors.white38),
          ),
        ),
      ),
    );
  }
}

class _BookPageCard extends StatelessWidget {
  final _BookReaderPage page;
  final int pageNumber;
  final int totalPages;
  final String bookTitle;
  final String chapterTitle;
  final String pageLabel;
  final Color pageColor;
  final Color pageTextColor;
  final TextStyle textStyle;
  final bool compact;

  const _BookPageCard({
    required this.page,
    required this.pageNumber,
    required this.totalPages,
    required this.bookTitle,
    required this.chapterTitle,
    required this.pageLabel,
    required this.pageColor,
    required this.pageTextColor,
    required this.textStyle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final padX = compact ? 18.0 : 22.0;
    final padTop = compact ? 16.0 : 20.0;
    final padBottom = compact ? 12.0 : 16.0;

    return Container(
      padding: EdgeInsets.fromLTRB(padX, padTop, padX, padBottom),
      decoration: BoxDecoration(
        color: pageColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6D8C3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 22,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  bookTitle.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: pageTextColor.withOpacity(0.54),
                      fontWeight: FontWeight.w900,
                      fontSize: 10.5,
                      letterSpacing: 0.8),
                ),
              ),
              Text('$pageNumber / $totalPages',
                  style: TextStyle(
                      color: pageTextColor.withOpacity(0.54),
                      fontWeight: FontWeight.w900,
                      fontSize: 10.5)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRect(
              child: SingleChildScrollView(
                primary: false,
                physics: const BouncingScrollPhysics(),
                child: SelectionArea(
                  child: HtmlWidget(
                    page.html,
                    textStyle: textStyle,
                    customStylesBuilder: (element) {
                      final tag = element.localName?.toLowerCase() ?? '';
                      if (tag == 'img') {
                        return {
                          'max-width': '100%',
                          'height': 'auto',
                          'border-radius': '14px',
                          'margin': '14px 0'
                        };
                      }
                      if (tag == 'h1' || tag == 'h2') {
                        return {
                          'font-size': '${textStyle.fontSize! * 1.45}px',
                          'line-height': '1.2',
                          'margin': '14px 0 8px'
                        };
                      }
                      if (tag == 'h3' || tag == 'h4') {
                        return {
                          'font-size': '${textStyle.fontSize! * 1.22}px',
                          'line-height': '1.25',
                          'margin': '12px 0 7px'
                        };
                      }
                      if (tag == 'p') return {'margin': '0 0 12px'};
                      return null;
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(pageLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: pageTextColor.withOpacity(0.44),
                  fontWeight: FontWeight.w800,
                  fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _BookReaderPage {
  final String html;
  const _BookReaderPage._({required this.html});
  factory _BookReaderPage.html(String html) => _BookReaderPage._(html: html);
}

class _MiniPageBadge extends StatelessWidget {
  final String label;
  final bool isLight;

  const _MiniPageBadge({required this.label, required this.isLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color:
            isLight ? const Color(0xFFF2E8D8) : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: isLight
                ? const Color(0xFFE0D0BC)
                : Colors.white.withOpacity(0.12)),
      ),
      child: Text(label,
          style: TextStyle(
              color: isLight ? const Color(0xFF6B6256) : Colors.white70,
              fontWeight: FontWeight.w900,
              fontSize: 10.5)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final bool isLight;

  const _ErrorView(
      {required this.error, required this.onRetry, required this.isLight});

  @override
  Widget build(BuildContext context) {
    final panel =
        isLight ? const Color(0xFFFFFBF4) : Colors.white.withOpacity(0.055);
    final border =
        isLight ? const Color(0xFFE6D8C3) : Colors.white.withOpacity(0.08);
    final titleColor = isLight ? const Color(0xFF1E1B16) : Colors.white;
    final subColor =
        isLight ? const Color(0xFF6B6256) : Colors.white.withOpacity(0.76);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: border)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: titleColor, size: 36),
              const SizedBox(height: 10),
              Text(error,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: subColor,
                      height: 1.4,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
