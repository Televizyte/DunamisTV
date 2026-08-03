import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/books/models/book_models.dart';
import '../../../features/books/services/books_service.dart';
import '../../../services/ads_service.dart';
import '../../../theme/theme_controller.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';
import 'widgets/designed_book_cover.dart';

class BookDetailScreen extends StatefulWidget {
  final BookItem? initialBook;
  final String bookId;

  const BookDetailScreen({
    super.key,
    this.initialBook,
    this.bookId = '',
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final BooksService _service = BooksService();

  bool _loading = false;
  String _error = '';
  BookItem? _book;
  List<BookChapter> _chapters = const <BookChapter>[];

  @override
  void initState() {
    super.initState();
    AdsService.instance.preloadInterstitial(tabKey: 'explore.books.detail');
    _book = widget.initialBook;
    _loadBookIfNeeded();
  }

  Future<void> _loadBookIfNeeded() async {
    final id = widget.bookId.trim().isNotEmpty
        ? widget.bookId.trim()
        : (_book?.identifier ?? '');
    if (id.isEmpty) return;

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final freshBook = await _service.fetchBook(id);
      var freshChapters = freshBook.toc;

      try {
        final endpointChapters = await _service.fetchBookChapters(
          freshBook.identifier,
        );
        if (endpointChapters.isNotEmpty) freshChapters = endpointChapters;
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _book = freshBook;
        _chapters = freshChapters;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openChapter(BookChapter chapter) async {
    final book = _book;
    if (book == null) return;

    await AdsService.instance.trackAndMaybeShowInterstitial(
      context,
      tabKey: 'explore.books.detail',
    );
    if (!mounted) return;

    context.push(
      '/tools/books/chapter',
      extra: {'book': book, 'chapter': chapter},
    );
  }

  Future<void> _openRead() async {
    final book = _book;
    if (book == null) return;

    await AdsService.instance.trackAndMaybeShowInterstitial(
      context,
      tabKey: 'explore.books.detail',
    );
    if (!mounted) return;

    if (book.isLocked) {
      _showLockedMessage();
      return;
    }

    if (book.isExternal && book.externalUrl.trim().isNotEmpty) {
      context.push('/web',
          extra: {'title': book.title, 'url': book.externalUrl.trim()});
      return;
    }

    if (book.isPdf) {
      final url = book.fileUrl.trim().isNotEmpty
          ? book.fileUrl.trim()
          : book.externalUrl.trim();
      if (url.isNotEmpty) {
        context.push('/web', extra: {'title': book.title, 'url': url});
      } else {
        _showMessage('PDF file is not available yet.');
      }
      return;
    }

    final chapters = _chapters.isNotEmpty ? _chapters : book.toc;
    if (chapters.isNotEmpty) {
      _openChapter(chapters.first);
    } else {
      _showMessage('No chapters have been published for this book yet.');
    }
  }

  Future<void> _openListen() async {
    final book = _book;
    if (book == null) return;
    if (book.isLocked) {
      _showLockedMessage();
      return;
    }
    final chapters = _chapters.isNotEmpty ? _chapters : book.toc;
    if (chapters.isEmpty) {
      _showMessage('No chapters have been published for listening yet.');
      return;
    }

    await AdsService.instance.trackAndMaybeShowInterstitial(
      context,
      tabKey: 'explore.books.detail',
    );
    if (!mounted) return;

    context.push(
      '/tools/books/chapter',
      extra: {'book': book, 'chapter': chapters.first},
    );
  }

  void _showLockedMessage() {
    _showMessage(
        'This book is locked. Premium/token access will be connected later.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final isLight = ThemeController.instance.isLightMode;
        final book = _book;
        final displayChapters = _chapters.isNotEmpty
            ? _chapters
            : (book?.toc ?? const <BookChapter>[]);

        return Scaffold(
          appBar: DxmTopBar(
            title: book?.title ?? 'Book Details',
            showBack: true,
            showMenu: true,
            onRefresh: _loadBookIfNeeded,
          ),
          bottomNavigationBar: const SafeArea(
            top: false,
            child: BannerAdWidget(tabKey: 'explore.books.detail'),
          ),
          body: GradientPageBackground(
            child: RefreshIndicator(
              onRefresh: _loadBookIfNeeded,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 92),
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(minHeight: 4),
                    ),
                  if (_error.isNotEmpty)
                    _InfoPanel(
                      icon: Icons.error_outline_rounded,
                      title: 'Book could not load',
                      subtitle: _error,
                      isLight: isLight,
                    )
                  else if (book == null)
                    _InfoPanel(
                      icon: Icons.auto_stories_rounded,
                      title: 'Book not found',
                      subtitle: 'Open this book again from the Library.',
                      isLight: isLight,
                    )
                  else ...[
                    _BookHero(
                      book: book,
                      isLight: isLight,
                      chapterCount: displayChapters.length,
                    ),
                    const SizedBox(height: 16),
                    _ActionsPanel(
                      book: book,
                      onRead: _openRead,
                      onListen: _openListen,
                      isLight: isLight,
                    ),
                    if (book.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _DescriptionPanel(
                          text: book.description, isLight: isLight),
                    ],
                    const SizedBox(height: 16),
                    _TocPanel(
                      book: book,
                      chapters: displayChapters,
                      isLight: isLight,
                      onChapterTap: (chapter) {
                        if (book.isLocked) {
                          _showLockedMessage();
                        } else {
                          _openChapter(chapter);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BookHero extends StatelessWidget {
  final BookItem book;
  final bool isLight;
  final int chapterCount;

  const _BookHero({
    required this.book,
    required this.isLight,
    required this.chapterCount,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isLight ? const Color(0xFF1E1B16) : Colors.white;
    final subColor =
        isLight ? const Color(0xFF6B6256) : Colors.white.withOpacity(0.74);

    return _Panel(
      isLight: isLight,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: DesignedBookCover(
              book: book,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 22,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (book.subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    book.subtitle,
                    style: TextStyle(
                      color: subColor,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (book.authorName.trim().isNotEmpty)
                  Text(
                    'By ${book.authorName}',
                    style: TextStyle(
                      color: isLight
                          ? const Color(0xFF4C453A)
                          : Colors.white.withOpacity(0.86),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _Badge(book.bookType.toUpperCase(), isLight: isLight),
                    _Badge(book.accessType.toUpperCase(), isLight: isLight),
                    _Badge(
                        '${chapterCount > 0 ? chapterCount : book.chapterCount} CHAPTERS',
                        isLight: isLight),
                    _Badge('${book.estimatedReadingMinutes} MIN',
                        isLight: isLight),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsPanel extends StatelessWidget {
  final BookItem book;
  final VoidCallback onRead;
  final VoidCallback onListen;
  final bool isLight;

  const _ActionsPanel({
    required this.book,
    required this.onRead,
    required this.onListen,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final label = book.isExternal
        ? 'Open Book'
        : book.isPdf
            ? 'Open PDF'
            : book.isLocked
                ? 'View Access'
                : 'Start Reading';

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onRead,
            icon: Icon(
                book.isLocked ? Icons.lock_rounded : Icons.menu_book_rounded),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2C96),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onListen,
            icon: const Icon(Icons.record_voice_over_rounded),
            label: const Text('Listen'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isLight ? const Color(0xFF1E1B16) : Colors.white,
              side: BorderSide(
                color: isLight
                    ? const Color(0xFFE0D0BC)
                    : Colors.white.withOpacity(0.20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}

class _DescriptionPanel extends StatelessWidget {
  final String text;
  final bool isLight;

  const _DescriptionPanel({required this.text, required this.isLight});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      isLight: isLight,
      child: Text(
        text,
        style: TextStyle(
          color: isLight
              ? const Color(0xFF4C453A)
              : Colors.white.withOpacity(0.78),
          fontSize: 14,
          height: 1.55,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TocPanel extends StatelessWidget {
  final BookItem book;
  final List<BookChapter> chapters;
  final ValueChanged<BookChapter> onChapterTap;
  final bool isLight;

  const _TocPanel({
    required this.book,
    required this.chapters,
    required this.onChapterTap,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isLight ? const Color(0xFF1E1B16) : Colors.white;
    final subColor =
        isLight ? const Color(0xFF6B6256) : Colors.white.withOpacity(0.64);

    return _Panel(
      isLight: isLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Table of Contents',
            style: TextStyle(
                color: titleColor, fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (chapters.isEmpty)
            Text(
              'No chapters available yet.',
              style: TextStyle(color: subColor, fontWeight: FontWeight.w600),
            )
          else
            ...chapters.asMap().entries.map((entry) {
              final index = entry.key;
              final chapter = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onChapterTap(chapter),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isLight
                          ? const Color(0xFFF7F1E6)
                          : Colors.white.withOpacity(0.045),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLight
                            ? const Color(0xFFE6D8C3)
                            : Colors.white.withOpacity(0.07),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isLight
                                ? const Color(0xFFFFFBF4)
                                : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                                color: titleColor, fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chapter.title,
                                style: TextStyle(
                                  color: titleColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${chapter.estimatedReadingMinutes} min • ${chapter.wordCount} words',
                                style: TextStyle(
                                  color: subColor,
                                  fontSize: 11.6,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: isLight
                                ? const Color(0xFF6B6256)
                                : Colors.white70),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final bool isLight;
  final EdgeInsetsGeometry padding;

  const _Panel({
    required this.child,
    required this.isLight,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color:
            isLight ? const Color(0xFFFFFBF4) : Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE6D8C3)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: child,
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLight;

  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isLight ? const Color(0xFF1E1B16) : Colors.white;
    final subColor =
        isLight ? const Color(0xFF6B6256) : Colors.white.withOpacity(0.66);

    return _Panel(
      isLight: isLight,
      child: Column(
        children: [
          Icon(icon, color: titleColor, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: titleColor, fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: subColor, height: 1.4, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final bool isLight;

  const _Badge(this.text, {required this.isLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color:
            isLight ? const Color(0xFFF2E8D8) : Colors.white.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE0D0BC)
              : Colors.white.withOpacity(0.14),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isLight ? const Color(0xFF4C453A) : Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
