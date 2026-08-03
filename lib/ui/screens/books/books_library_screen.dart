import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/books/models/book_models.dart';
import '../../../features/books/services/books_service.dart';
import '../../../services/ads_service.dart';
import '../../../theme/theme_controller.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/ads/native_inline_ad_tile.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';
import 'widgets/book_card.dart';

class BooksLibraryScreen extends StatefulWidget {
  const BooksLibraryScreen({super.key});

  @override
  State<BooksLibraryScreen> createState() => _BooksLibraryScreenState();
}

class _BooksLibraryScreenState extends State<BooksLibraryScreen> {
  final BooksService _service = BooksService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String _error = '';
  String _query = '';
  List<BookItem> _books = const [];

  @override
  void initState() {
    super.initState();
    AdsService.instance.preloadInterstitial(tabKey: 'explore.books');
    _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final response = await _service.fetchBooks(perPage: 96);
      if (!mounted) return;
      setState(() {
        _books = response.items;
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

  List<BookItem> get _filteredBooks {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _books;
    return _books.where((book) {
      return book.title.toLowerCase().contains(q) ||
          book.subtitle.toLowerCase().contains(q) ||
          book.authorName.toLowerCase().contains(q) ||
          book.description.toLowerCase().contains(q);
    }).toList(growable: false);
  }

  Future<void> _openBook(BookItem book) async {
    await AdsService.instance.trackAndMaybeShowInterstitial(
      context,
      tabKey: 'explore.books',
    );
    if (!mounted) return;
    context.push('/tools/books/detail', extra: {'book': book});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final isLight = ThemeController.instance.isLightMode;
        final filtered = _filteredBooks;
        final featured =
            _books.where((book) => book.isFeatured).toList(growable: false);

        return Scaffold(
          appBar: DxmTopBar(
            title: 'Books & Library',
            showBack: true,
            showMenu: true,
            onRefresh: _loadBooks,
          ),
          bottomNavigationBar: const SafeArea(
            top: false,
            child: BannerAdWidget(tabKey: 'explore.books'),
          ),
          body: GradientPageBackground(
            child: RefreshIndicator(
              onRefresh: _loadBooks,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                children: [
                  _SearchBox(
                    controller: _searchController,
                    isLight: isLight,
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 18),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_error.isNotEmpty)
                    _StateCard(
                      icon: Icons.error_outline_rounded,
                      title: 'Books could not load',
                      subtitle: _error,
                      actionLabel: 'Try Again',
                      onAction: _loadBooks,
                      isLight: isLight,
                    )
                  else if (_books.isEmpty)
                    _StateCard(
                      icon: Icons.auto_stories_rounded,
                      title: 'No books yet',
                      subtitle:
                          'Publish books from AppsHub and refresh this page.',
                      actionLabel: 'Refresh',
                      onAction: _loadBooks,
                      isLight: isLight,
                    )
                  else ...[
                    if (featured.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Featured Books',
                        subtitle: 'Selected from AppsHub',
                        isLight: isLight,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 192,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: featured.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final book = featured[index];
                            return FeaturedBookCard(
                              book: book,
                              isLight: isLight,
                              onTap: () => _openBook(book),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (AdsService.instance
                        .nativeInListAllowedForTab('explore.books')) ...[
                      _NativeAdInlineCard(isLight: isLight),
                      const SizedBox(height: 20),
                    ],
                    _SectionHeader(
                      title:
                          _query.trim().isEmpty ? 'Library' : 'Search Results',
                      subtitle:
                          '${filtered.length} book${filtered.length == 1 ? '' : 's'} available',
                      isLight: isLight,
                    ),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      _NoSearchResults(isLight: isLight)
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 12.0;
                          final columns = constraints.maxWidth < 390 ? 2 : 3;
                          final width =
                              (constraints.maxWidth - spacing * (columns - 1)) /
                                  columns;
                          final height = columns == 2 ? 265.0 : 250.0;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              for (var i = 0; i < filtered.length; i++) ...[
                                SizedBox(
                                  width: width,
                                  height: height,
                                  child: BookCard(
                                    book: filtered[i],
                                    isLight: isLight,
                                    onTap: () => _openBook(filtered[i]),
                                  ),
                                ),
                                if (AdsService.instance
                                        .shouldInsertNativeAfterItem(
                                      tabKey: 'explore.books',
                                      itemIndex: i,
                                    ) &&
                                    i != filtered.length - 1)
                                  SizedBox(
                                    width: constraints.maxWidth,
                                    child: _NativeAdInlineCard(
                                      isLight: isLight,
                                      compact: true,
                                    ),
                                  ),
                              ],
                            ],
                          );
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

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isLight;

  const _SearchBox({
    required this.controller,
    required this.onChanged,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isLight ? const Color(0xFF1E1B16) : Colors.white;
    final hintColor =
        isLight ? const Color(0xFF8A7C68) : Colors.white.withOpacity(0.55);
    final fillColor =
        isLight ? const Color(0xFFFFFBF4) : Colors.white.withOpacity(0.06);
    final borderColor =
        isLight ? const Color(0xFFE6D8C3) : Colors.white.withOpacity(0.10);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search_rounded, color: hintColor),
        hintText: 'Search books, authors, topics...',
        hintStyle: TextStyle(color: hintColor, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFFF2C96)),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isLight;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isLight ? const Color(0xFF1E1B16) : Colors.white;
    final subColor =
        isLight ? const Color(0xFF6B6256) : Colors.white.withOpacity(0.64);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(
            color: subColor,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isLight;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final panel =
        isLight ? const Color(0xFFFFFBF4) : Colors.white.withOpacity(0.055);
    final border =
        isLight ? const Color(0xFFE6D8C3) : Colors.white.withOpacity(0.08);
    final titleColor = isLight ? const Color(0xFF1E1B16) : Colors.white;
    final subColor =
        isLight ? const Color(0xFF6B6256) : Colors.white.withOpacity(0.66);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(icon, color: titleColor, size: 36),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: titleColor,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subColor,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  final bool isLight;

  const _NoSearchResults({required this.isLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            isLight ? const Color(0xFFFFFBF4) : Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE6D8C3)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Text(
        'No books match your search.',
        style: TextStyle(
          color: isLight
              ? const Color(0xFF6B6256)
              : Colors.white.withOpacity(0.70),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NativeAdInlineCard extends StatelessWidget {
  final bool isLight;
  final bool compact;

  const _NativeAdInlineCard({
    required this.isLight,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return NativeInlineAdTile(
      tabKey: 'explore.books',
      label: 'Sponsored book recommendation',
      minHeight: compact ? 120 : 150,
      margin: EdgeInsets.zero,
    );
  }
}
