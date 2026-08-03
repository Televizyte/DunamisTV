import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/bible/models/bible_models.dart';
import '../../../features/bible/state/bible_store.dart';
import '../../../theme/theme_controller.dart';
import '../../../widgets/banner_ad_widget.dart';
import '../../widgets/gradient_page_background.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
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
  final TextEditingController _searchController = TextEditingController();

  bool _handledInitialExtra = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await _store.init();
    if (!mounted) return;
    await _handleInitialExtraIfAny();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _handleInitialExtraIfAny() async {
    if (_handledInitialExtra) return;
    _handledInitialExtra = true;

    final extra = GoRouterState.of(context).extra;
    if (extra is! Map) return;

    final ref = (extra['ref'] ?? '').toString().trim();
    final verse = (extra['verse'] ?? '').toString().trim();

    if (ref.isEmpty) return;

    final found = await _store.verseByReference(ref);

    if (found != null) {
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.push(
          '/tools/bible/reader',
          extra: <String, dynamic>{
            'book': found.book,
            'chapter': found.chapter,
            'verse': found.verse,
          },
        );
      });
      return;
    }

    if (verse.isNotEmpty) {
      _searchController.text = ref;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSearch() {
    final query = _searchController.text.trim();
    context.push(
      '/tools/bible/search',
      extra: <String, dynamic>{
        'query': query,
      },
    );
  }

  void _openBooks(String testament) {
    context.push(
      '/tools/bible/books',
      extra: <String, dynamic>{
        'testament': testament,
      },
    );
  }

  void _continueReading() {
    final reading = _store.lastReading;
    if (reading == null || reading.book.trim().isEmpty) {
      _openBooks('old');
      return;
    }

    context.push(
      '/tools/bible/reader',
      extra: <String, dynamic>{
        'book': reading.book,
        'chapter': reading.chapter <= 0 ? 1 : reading.chapter,
        'verse': reading.verse,
      },
    );
  }

  void _openSavedVerses() {
    context.push('/tools/bible/saved');
  }

  void _openRecentVerse(BibleVerse verse) {
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
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final reading = _store.lastReading;
        final loading = _store.loading;
        final isLight = ThemeController.instance.isLightMode;

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
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Bible',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: isLight
                          ? 'Switch to dark mode'
                          : 'Switch to light mode',
                      onPressed: () => ThemeController.instance.toggleTheme(),
                      icon: Icon(
                        isLight
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      loading ? 'Loading...' : _store.translation,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ),
          body: _BibleBackground(
            isLight: isLight,
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: <Widget>[
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                          children: <Widget>[
                            _BibleCard(
                              isLight: isLight,
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Search Scripture',
                                    style: TextStyle(
                                      color: isLight
                                          ? const Color(0xFF1E1B16)
                                          : Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Search by reference like Romans 8:28 or by keyword.',
                                    style: TextStyle(
                                      color: isLight
                                          ? const Color(0xFF5F5648)
                                          : Colors.white.withOpacity(0.68),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          style: TextStyle(
                                            color: isLight
                                                ? const Color(0xFF1E1B16)
                                                : Colors.white,
                                          ),
                                          textInputAction:
                                              TextInputAction.search,
                                          onSubmitted: (_) => _openSearch(),
                                          decoration: InputDecoration(
                                            hintText: 'Search the Bible',
                                            hintStyle: TextStyle(
                                              color: isLight
                                                  ? const Color(0xFF8A7C68)
                                                  : Colors.white
                                                      .withOpacity(0.45),
                                            ),
                                            filled: true,
                                            fillColor: isLight
                                                ? const Color(0xFFF2E8D8)
                                                : const Color(0xFF151C3A),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 14,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        height: 52,
                                        child: ElevatedButton(
                                          onPressed: _openSearch,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFFF2C96),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.search_rounded,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            _BibleHeroCard(
                              isLight: isLight,
                              title: 'Continue Reading',
                              subtitle: reading?.label ?? 'Start from any book',
                              buttonLabel:
                                  reading == null ? 'Open Books' : 'Continue',
                              icon: Icons.menu_book_rounded,
                              onTap: _continueReading,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: _QuickActionCard(
                                    isLight: isLight,
                                    title: 'Old Testament',
                                    subtitle:
                                        '${_store.oldTestamentBooks.length} books',
                                    icon: Icons.auto_stories_rounded,
                                    onTap: () => _openBooks('old'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _QuickActionCard(
                                    isLight: isLight,
                                    title: 'New Testament',
                                    subtitle:
                                        '${_store.newTestamentBooks.length} books',
                                    icon: Icons.bookmarks_rounded,
                                    onTap: () => _openBooks('new'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _QuickActionCard(
                              isLight: isLight,
                              title: 'Saved Verses',
                              subtitle:
                                  '${_store.bookmarks.length} bookmarked verses',
                              icon: Icons.bookmark_rounded,
                              onTap: _openSavedVerses,
                            ),
                            const SizedBox(height: 18),
                            if (_store.recentVerses.isNotEmpty) ...<Widget>[
                              Text(
                                'Recent Verses',
                                style: TextStyle(
                                  color: isLight
                                      ? const Color(0xFF1E1B16)
                                      : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ..._store.recentVerses.take(8).map(
                                    (verse) => _RecentVerseTile(
                                      isLight: isLight,
                                      verse: verse,
                                      onTap: () => _openRecentVerse(verse),
                                    ),
                                  ),
                            ] else ...<Widget>[
                              _BibleCard(
                                isLight: isLight,
                                padding: const EdgeInsets.all(14),
                                child: Text(
                                  'Your recent verses will appear here after you start reading.',
                                  style: TextStyle(
                                    color: isLight
                                        ? const Color(0xFF5F5648)
                                        : Colors.white.withOpacity(0.72),
                                    fontSize: 13,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SafeArea(
                        top: false,
                        child: BannerAdWidget(tabKey: 'explore:bible'),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _BibleBackground extends StatelessWidget {
  const _BibleBackground({
    required this.isLight,
    required this.child,
  });

  final bool isLight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isLight) {
      return GradientPageBackground(child: child);
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F1E6),
      ),
      child: child,
    );
  }
}

class _BibleCard extends StatelessWidget {
  const _BibleCard({
    required this.isLight,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final bool isLight;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430),
        borderRadius: BorderRadius.circular(18),
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

class _BibleHeroCard extends StatelessWidget {
  const _BibleHeroCard({
    required this.isLight,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.icon,
    required this.onTap,
  });

  final bool isLight;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (isLight) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE6D8C3)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(0.06),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFF2E8D8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Color(0xFF3C3428),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1E1B16),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF5F5648),
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3C3428),
                      side: const BorderSide(color: Color(0xFFE0D0BC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      buttonLabel,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF1A1F5A),
            Color(0xFF5B1FA8),
            Color(0xFFB70E7C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.22),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.28)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.isLight,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final bool isLight;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

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
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isLight
                      ? const Color(0xFFF2E8D8)
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isLight ? const Color(0xFF3C3428) : Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        color: isLight ? const Color(0xFF1E1B16) : Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isLight
                            ? const Color(0xFF5F5648)
                            : Colors.white.withOpacity(0.64),
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

class _RecentVerseTile extends StatelessWidget {
  const _RecentVerseTile({
    required this.isLight,
    required this.verse,
    required this.onTap,
  });

  final bool isLight;
  final BibleVerse verse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE6D8C3)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          verse.reference,
          style: TextStyle(
            color: isLight ? const Color(0xFF1E1B16) : Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            verse.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isLight
                  ? const Color(0xFF5F5648)
                  : Colors.white.withOpacity(0.72),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: isLight ? const Color(0xFF6B6256) : Colors.white70,
        ),
      ),
    );
  }
}
