import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/hub/state/hub_scope.dart';
import '../../../services/ads_service.dart';
import '../../../theme/theme_controller.dart';
import '../../widgets/ads/native_inline_ad_tile.dart';
import '../../widgets/ads/native_list_injection.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';

class ArticlesHubScreen extends StatelessWidget {
  const ArticlesHubScreen({super.key});

  static const String pageAdKey = 'inspire.articles';

  @override
  Widget build(BuildContext context) {
    final store = HubScope.maybeOf(context);

    return AnimatedBuilder(
      animation: Listenable.merge([
        ThemeController.instance,
        if (store != null) store,
      ]),
      builder: (context, _) {
        final isLight = ThemeController.instance.isLightMode;
        final colors = _ArticleHubColors.fromBrightness(isLight);

        final Map<String, dynamic> hubMap =
            store?.raw ?? const <String, dynamic>{};

        final inspire = (hubMap['inspire'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};

        final items = _extractItems(inspire);
        final featuredItems = _extractFeaturedItems(inspire, items);

        final listEntries =
            NativeListInjection.buildEntries<Map<String, dynamic>>(
          items,
          tabKey: pageAdKey,
        );

        AdsService.instance.preloadInterstitial(tabKey: pageAdKey);

        return Scaffold(
          backgroundColor: colors.scaffold,
          bottomNavigationBar: const SafeArea(
            top: false,
            child: BannerAdWidget(
              tabKey: pageAdKey,
              padding: EdgeInsets.fromLTRB(12, 8, 12, 10),
            ),
          ),
          body: Column(
            children: [
              DxmTopBar(
                title: 'Inside Dunamis',
                showBack: true,
                showMenu: true,
                onRefresh: () => store?.refresh(),
              ),
              Expanded(
                child: GradientPageBackground(
                  child: RefreshIndicator(
                    onRefresh: () async => store?.refresh(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                      children: [
                        _SectionHeader(
                          title: _resolveText(
                            inspire,
                            const [
                              'articles_featured_title',
                              'inside_dunamis_featured_title',
                              'featured_title'
                            ],
                            fallback: 'Featured Inside Dunamis',
                          ),
                          subtitle: _resolveText(
                            inspire,
                            const [
                              'articles_featured_subtitle',
                              'inside_dunamis_featured_subtitle',
                              'featured_subtitle'
                            ],
                            fallback: 'Browse highlighted ministry articles.',
                          ),
                          colors: colors,
                        ),
                        const SizedBox(height: 12),
                        if (featuredItems.isEmpty)
                          _EmptyCard(
                            title: 'No posts yet',
                            subtitle:
                                'AppsHub will publish Inside Dunamis posts here.',
                            icon: Icons.article_rounded,
                            colors: colors,
                          )
                        else
                          _FeaturedCarousel(
                            items: featuredItems,
                            source: 'inside_dunamis',
                            colors: colors,
                          ),
                        const SizedBox(height: 20),
                        _SectionHeader(
                          title: _resolveText(
                            inspire,
                            const [
                              'articles_all_title',
                              'inside_dunamis_all_title',
                              'all_title'
                            ],
                            fallback: 'All Inside Dunamis',
                          ),
                          subtitle: _resolveText(
                            inspire,
                            const [
                              'articles_all_subtitle',
                              'inside_dunamis_all_subtitle',
                              'all_subtitle'
                            ],
                            fallback: 'Explore all available articles.',
                          ),
                          colors: colors,
                        ),
                        const SizedBox(height: 12),
                        if (items.isEmpty)
                          _EmptyCard(
                            title: 'No posts yet',
                            subtitle:
                                'AppsHub will publish Inside Dunamis posts here.',
                            icon: Icons.article_rounded,
                            colors: colors,
                          )
                        else
                          Column(
                            children: List.generate(listEntries.length, (i) {
                              final entry = listEntries[i];

                              if (entry.isAd) {
                                return const NativeInlineAdTile(
                                  tabKey: pageAdKey,
                                  label: 'Sponsored',
                                  minHeight: 120,
                                );
                              }

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: i == listEntries.length - 1 ? 0 : 14,
                                ),
                                child: _buildArticleCard(
                                  context,
                                  entry.item!,
                                  entry.itemIndex,
                                  colors,
                                ),
                              );
                            }),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildArticleCard(
    BuildContext context,
    Map<String, dynamic> m,
    int index,
    _ArticleHubColors colors,
  ) {
    final id = (m['id'] ?? m['slug'] ?? 'item_$index').toString();

    final title = _readerFirstNonEmpty([
      (m['title'] ?? '').toString(),
      (m['topic'] ?? '').toString(),
      'Inside Dunamis',
    ]);

    final subtitle = _readerFirstNonEmpty([
      (m['subtitle'] ?? '').toString(),
      (m['excerpt'] ?? '').toString(),
      (m['summary'] ?? '').toString(),
      (m['date'] ?? '').toString(),
    ]);

    return _ArticleListCard(
      title: title,
      subtitle: subtitle,
      excerpt: _resolveExcerpt(m),
      metaText: _resolveMetaLine(m),
      imageUrl: _pickImage(m),
      fallbackAsset: _fallbackAssetFor(index),
      pillText: _resolvePill(m),
      icon: Icons.article_rounded,
      colors: colors,
      onTap: () async {
        await AdsService.instance.maybeShowInterstitialOnSafeNav(
          context,
          tabKey: pageAdKey,
        );
        if (!context.mounted) return;
        context.push(
          '/articles/detail',
          extra: {'id': id, 'source': 'inside_dunamis'},
        );
      },
    );
  }

  static List<Map<String, dynamic>> _extractItems(
    Map<String, dynamic> inspire,
  ) {
    for (final key in const ['articles', 'inside_dunamis']) {
      final raw = inspire[key];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(growable: false);
      }
    }
    return const [];
  }

  static List<Map<String, dynamic>> _extractFeaturedItems(
    Map<String, dynamic> inspire,
    List<Map<String, dynamic>> items,
  ) {
    for (final key in const [
      'articles_featured',
      'inside_dunamis_featured',
      'featured_articles',
      'featured_inside_dunamis',
    ]) {
      final configured = inspire[key];
      if (configured is List && configured.isNotEmpty) {
        final normalized = configured
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
        if (normalized.isNotEmpty) return normalized.take(9).toList();
      }
    }

    final flagged = items.where((item) {
      final f = item['featured'] ?? item['pinned'];
      return f == true || f.toString().toLowerCase() == 'true';
    }).toList(growable: false);

    if (flagged.isNotEmpty) return flagged.take(9).toList(growable: false);
    return items.take(9).toList(growable: false);
  }

  static String _resolveText(
    Map<String, dynamic> inspire,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = inspire[key];
      final s = value?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }

    for (final metaKey in const ['articles_meta', 'inside_dunamis_meta']) {
      final meta = inspire[metaKey];
      if (meta is Map) {
        for (final key in keys) {
          final value = meta[key];
          final s = value?.toString().trim() ?? '';
          if (s.isNotEmpty) return s;
        }
      }
    }

    return fallback;
  }

  static String _resolvePill(Map<String, dynamic> item) {
    for (final key in const [
      'pill_text',
      'badge',
      'label',
      'category',
      'type'
    ]) {
      final value = item[key];
      final s = value?.toString().trim() ?? '';
      if (s.isNotEmpty) return s.toUpperCase();
    }

    final meta = item['meta'];
    if (meta is Map) {
      for (final key in const [
        'pill_text',
        'badge',
        'label',
        'category',
        'type'
      ]) {
        final value = meta[key];
        final s = value?.toString().trim() ?? '';
        if (s.isNotEmpty) return s.toUpperCase();
      }
    }

    return 'ARTICLE';
  }

  static dynamic _nestedValue(
    Map<String, dynamic> item,
    String parent,
    String child,
  ) {
    final value = item[parent];
    if (value is Map) return value[child];
    return null;
  }

  static String _nestedString(
    Map<String, dynamic> item,
    String parent,
    String child,
  ) {
    final value = _nestedValue(item, parent, child);
    return value?.toString() ?? '';
  }

  static String _blocksToPlainText(dynamic blocks) {
    if (blocks is! List) return '';
    final out = <String>[];

    for (final block in blocks) {
      if (block is! Map) continue;
      for (final key in const [
        'excerpt',
        'summary',
        'description',
        'text',
        'quote',
        'body',
        'content',
        'html',
      ]) {
        final value = block[key];
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) out.add(text);
      }
    }

    return out.join(' ');
  }

  static String _resolveExcerpt(Map<String, dynamic> item) {
    // AppsHub list endpoints sometimes send subtitle/excerpt as the author/date
    // meta line, while the real article preview is available in payload.blocks.
    // Prefer true article body/sample text first, then fall back to direct fields.
    final blockText = _readerFirstNonEmpty([
      _blocksToPlainText(item['blocks']),
      _blocksToPlainText(_nestedValue(item, 'payload', 'blocks')),
    ]);
    if (blockText.trim().isNotEmpty) return _cleanContentString(blockText);

    final body = _readerFirstNonEmpty([
      (item['body'] ?? '').toString(),
      (item['content'] ?? '').toString(),
      (item['text'] ?? '').toString(),
      (item['body_html'] ?? '').toString(),
      _nestedString(item, 'payload', 'body_html'),
      _nestedString(item, 'payload', 'body'),
      _nestedString(item, 'payload', 'content'),
      _nestedString(item, 'payload', 'text'),
    ]);
    if (body.trim().isNotEmpty) return _cleanContentString(body);

    final direct = _readerFirstNonEmpty([
      (item['excerpt'] ?? '').toString(),
      (item['summary'] ?? '').toString(),
      (item['description'] ?? '').toString(),
      _nestedString(item, 'payload', 'excerpt'),
      _nestedString(item, 'payload', 'summary'),
      _nestedString(item, 'payload', 'description'),
      _nestedString(item, 'meta', 'excerpt'),
      _nestedString(item, 'meta', 'summary'),
      _nestedString(item, 'meta', 'description'),
    ]);

    if (direct.trim().isNotEmpty) return _cleanContentString(direct);

    // Final fallback only: use subtitle when no body sample exists.
    return _cleanContentString((item['subtitle'] ?? '').toString());
  }

  static String _resolveMetaLine(Map<String, dynamic> item) {
    final parts = <String>[];

    final author = _readerFirstNonEmpty([
      (item['author_name'] ?? '').toString(),
      (item['author'] ?? '').toString(),
      (item['publisher_name'] ?? '').toString(),
    ]);
    if (author.trim().isNotEmpty) parts.add(author.trim());

    final date = _formatCompactDate(_readerFirstNonEmpty([
      (item['published_at'] ?? '').toString(),
      (item['publish_at'] ?? '').toString(),
      (item['date'] ?? '').toString(),
      (item['created_at'] ?? '').toString(),
    ]));
    if (date.trim().isNotEmpty) parts.add(date.trim());

    return parts.join(' • ');
  }

  static String _formatCompactDate(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return '';

    try {
      final parsed = DateTime.parse(clean).toLocal();
      const months = <String>[
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
    } catch (_) {
      return clean;
    }
  }

  static String _cleanContentString(String value) {
    return value
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String? _pickImage(Map<String, dynamic> item) {
    const directKeys = [
      'cover_image_url',
      'image_url',
      'card_image_url',
      'background_image_url',
      'cover_image',
      'cover_url',
      'banner_url',
      'featured_image',
      'thumbnail_url',
      'thumbnail',
      'image',
      'imageUrl',
      'poster',
      'photo',
      'cover_asset_url',
      'file_url',
    ];

    String? fromMap(Map source) {
      for (final key in directKeys) {
        final value = source[key];
        if (value is Map) {
          final nested = fromMap(value);
          if ((nested ?? '').trim().isNotEmpty) return nested;
        }
        final s = value?.toString().trim() ?? '';
        if (_looksLikeImageUrl(s)) return s;
      }
      return null;
    }

    final direct = fromMap(item);
    if ((direct ?? '').trim().isNotEmpty) return direct;

    for (final key in const ['payload', 'media', 'meta', 'cover']) {
      final value = item[key];
      if (value is Map) {
        final nested = fromMap(value);
        if ((nested ?? '').trim().isNotEmpty) return nested;
      }
    }

    return null;
  }

  static bool _looksLikeImageUrl(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return false;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return true;
    if (raw.startsWith('assets/')) return true;
    return raw.contains('/storage/') ||
        raw.contains('/uploads/') ||
        raw.contains('/images/') ||
        raw.endsWith('.jpg') ||
        raw.endsWith('.jpeg') ||
        raw.endsWith('.png') ||
        raw.endsWith('.webp');
  }

  static String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final s = value.trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  static String _fallbackAssetFor(int index) {
    const assets = [
      'assets/images/home_3.jpg',
      'assets/images/home_1.jpg',
      'assets/images/home_4.jpg',
      'assets/images/home_5.jpg',
      'assets/images/home_2.jpg',
    ];
    return assets[index % assets.length];
  }
}

class _FeaturedCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String source;
  final _ArticleHubColors colors;

  const _FeaturedCarousel({
    required this.items,
    required this.source,
    required this.colors,
  });

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int next) {
    if (widget.items.isEmpty) return;
    final safe = next.clamp(0, widget.items.length - 1);
    _controller.animateToPage(
      safe,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 382,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (value) {
              if (!mounted) return;
              setState(() => _index = value);
            },
            itemBuilder: (context, i) {
              final m = widget.items[i];
              final id = (m['id'] ?? m['slug'] ?? 'featured_$i').toString();

              final title = ArticlesHubScreen._firstNonEmpty([
                (m['title'] ?? '').toString(),
                (m['topic'] ?? '').toString(),
                'Inside Dunamis',
              ]);

              final subtitle = ArticlesHubScreen._firstNonEmpty([
                (m['subtitle'] ?? '').toString(),
                ArticlesHubScreen._resolveMetaLine(m),
              ]);

              return Padding(
                padding: EdgeInsets.only(
                  right: i == widget.items.length - 1 ? 0 : 12,
                ),
                child: _FeaturedArticleCard(
                  title: title,
                  subtitle: subtitle,
                  excerpt: '',
                  metaText: ArticlesHubScreen._resolveMetaLine(m),
                  imageUrl: ArticlesHubScreen._pickImage(m),
                  fallbackAsset: ArticlesHubScreen._fallbackAssetFor(i),
                  icon: Icons.article_rounded,
                  pillText: ArticlesHubScreen._resolvePill(m),
                  colors: widget.colors,
                  onTap: () async {
                    await AdsService.instance.maybeShowInterstitialOnSafeNav(
                      context,
                      tabKey: ArticlesHubScreen.pageAdKey,
                    );
                    if (!context.mounted) return;
                    context.push(
                      '/articles/detail',
                      extra: {'id': id, 'source': widget.source},
                    );
                  },
                ),
              );
            },
          ),
          if (widget.items.length > 1)
            Positioned(
              left: 6,
              top: 0,
              bottom: 0,
              child: _CarouselArrow(
                icon: Icons.chevron_left_rounded,
                enabled: _index > 0,
                onTap: () => _goTo(_index - 1),
                colors: widget.colors,
              ),
            ),
          if (widget.items.length > 1)
            Positioned(
              right: 6,
              top: 0,
              bottom: 0,
              child: _CarouselArrow(
                icon: Icons.chevron_right_rounded,
                enabled: _index < widget.items.length - 1,
                onTap: () => _goTo(_index + 1),
                colors: widget.colors,
              ),
            ),
        ],
      ),
    );
  }
}

class _FeaturedArticleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String excerpt;
  final String metaText;
  final String? imageUrl;
  final String fallbackAsset;
  final IconData icon;
  final String pillText;
  final VoidCallback onTap;
  final _ArticleHubColors colors;

  const _FeaturedArticleCard({
    required this.title,
    required this.subtitle,
    required this.excerpt,
    required this.metaText,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.icon,
    required this.pillText,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return _ReaderArticleCardShell(
      title: title,
      subtitle: subtitle,
      excerpt: excerpt,
      metaText: metaText,
      imageUrl: imageUrl,
      fallbackAsset: fallbackAsset,
      pillText: pillText,
      icon: icon,
      colors: colors,
      onTap: onTap,
      featured: true,
    );
  }
}

class _ArticleListCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String excerpt;
  final String metaText;
  final String? imageUrl;
  final String fallbackAsset;
  final String pillText;
  final IconData icon;
  final VoidCallback onTap;
  final _ArticleHubColors colors;

  const _ArticleListCard({
    required this.title,
    required this.subtitle,
    required this.excerpt,
    required this.metaText,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.pillText,
    required this.icon,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return _ReaderArticleCardShell(
      title: title,
      subtitle: subtitle,
      excerpt: excerpt,
      metaText: metaText,
      imageUrl: imageUrl,
      fallbackAsset: fallbackAsset,
      pillText: pillText,
      icon: icon,
      colors: colors,
      onTap: onTap,
    );
  }
}

class _ReaderArticleCardShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final String excerpt;
  final String metaText;
  final String? imageUrl;
  final String fallbackAsset;
  final String pillText;
  final IconData icon;
  final VoidCallback onTap;
  final _ArticleHubColors colors;
  final bool featured;

  const _ReaderArticleCardShell({
    required this.title,
    required this.subtitle,
    required this.excerpt,
    required this.metaText,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.pillText,
    required this.icon,
    required this.onTap,
    required this.colors,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    final cleanTitle = title.trim().isEmpty ? 'Untitled article' : title.trim();
    final cleanSubtitle = _removeReaderFallbackText(subtitle.trim());
    final cleanExcerpt = _readerFirstNonEmpty([
      _removeReaderFallbackText(excerpt.trim()),
      cleanSubtitle,
    ]);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.panelBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.panelBorder),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _SmartCardImage(
                        imageUrl: imageUrl,
                        fallbackAsset: fallbackAsset,
                        colors: colors,
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.08),
                                Colors.black.withOpacity(0.22),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: _Pill(text: pillText, colors: colors),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    featured ? 16 : 14,
                    featured ? 15 : 14,
                    featured ? 16 : 14,
                    featured ? 16 : 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cleanTitle,
                        maxLines: featured ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.panelTitle,
                          fontSize: featured ? 18.5 : 17,
                          height: 1.14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (metaText.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: colors.iconChipBg,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: colors.iconChipBorder),
                              ),
                              child: Icon(
                                icon,
                                color: colors.primaryTextOnImage,
                                size: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                metaText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.panelSubtitle,
                                  fontSize: 12.2,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (cleanExcerpt.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          cleanExcerpt,
                          maxLines: featured ? 3 : 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.panelSubtitle,
                            fontSize: 13.4,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Read article',
                            style: TextStyle(
                              color: colors.headerTitle,
                              fontSize: 12.8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colors.panelTitle,
                            size: 24,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final _ArticleHubColors colors;

  const _CarouselArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: Material(
          color: colors.arrowBg,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: enabled ? onTap : null,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(icon, color: colors.primaryTextOnImage, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final _ArticleHubColors colors;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.headerTitle,
            fontSize: 18,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: colors.headerSubtitle,
            fontSize: 12.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SmartCardImage extends StatelessWidget {
  final String? imageUrl;
  final String fallbackAsset;
  final _ArticleHubColors colors;

  const _SmartCardImage({
    required this.imageUrl,
    required this.fallbackAsset,
    required this.colors,
  });

  bool get _hasRemoteImage => (imageUrl ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_hasRemoteImage) {
      return Image.network(
        imageUrl!.trim(),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          fallbackAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: colors.imageFallback),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: colors.imageLoading,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          );
        },
      );
    }

    return Image.asset(
      fallbackAsset,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: colors.imageFallback),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final _ArticleHubColors colors;

  const _Pill({
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 34),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.pillBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.pillBorder),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.primaryTextOnImage,
          fontWeight: FontWeight.w900,
          fontSize: 11.5,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final _ArticleHubColors colors;

  const _EmptyCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.panelBorder),
        color: colors.panelBg,
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5B1FA8), Color(0xFFB70E7C)],
              ),
            ),
            child: Icon(icon, color: colors.primaryTextOnImage, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.panelTitle,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.panelSubtitle,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
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

class _ArticleHubColors {
  final Color scaffold;
  final Color panelBg;
  final Color panelBorder;
  final Color panelTitle;
  final Color panelSubtitle;
  final Color headerTitle;
  final Color headerSubtitle;
  final Color primaryTextOnImage;
  final Color secondaryTextOnImage;
  final Color chevronOnImage;
  final Color cardBorder;
  final Color iconChipBg;
  final Color iconChipBorder;
  final Color pillBg;
  final Color pillBorder;
  final Color arrowBg;
  final Color imageLoading;
  final Color imageFallback;
  final Color shadow;
  final List<Color> cardOverlay;

  const _ArticleHubColors({
    required this.scaffold,
    required this.panelBg,
    required this.panelBorder,
    required this.panelTitle,
    required this.panelSubtitle,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.primaryTextOnImage,
    required this.secondaryTextOnImage,
    required this.chevronOnImage,
    required this.cardBorder,
    required this.iconChipBg,
    required this.iconChipBorder,
    required this.pillBg,
    required this.pillBorder,
    required this.arrowBg,
    required this.imageLoading,
    required this.imageFallback,
    required this.shadow,
    required this.cardOverlay,
  });

  factory _ArticleHubColors.fromBrightness(bool isLight) {
    if (isLight) {
      return _ArticleHubColors(
        scaffold: const Color(0xFFF6F7FB),
        panelBg: Colors.white.withOpacity(0.92),
        panelBorder: const Color(0xFFE6E8F0),
        panelTitle: const Color(0xFF1E1B16),
        panelSubtitle: const Color(0xFF5E6472),
        headerTitle: const Color(0xFF1E1B16),
        headerSubtitle: const Color(0xFF5E6472),
        primaryTextOnImage: Colors.white,
        secondaryTextOnImage: Colors.white.withOpacity(0.90),
        chevronOnImage: Colors.white.withOpacity(0.85),
        cardBorder: Colors.white.withOpacity(0.10),
        iconChipBg: Colors.black.withOpacity(0.24),
        iconChipBorder: Colors.white.withOpacity(0.14),
        pillBg: Colors.black.withOpacity(0.28),
        pillBorder: Colors.white.withOpacity(0.16),
        arrowBg: Colors.black.withOpacity(0.26),
        imageLoading: const Color(0xFFE9ECF5),
        imageFallback: const Color(0xFFD9DEEA),
        shadow: Colors.black.withOpacity(0.08),
        cardOverlay: [
          Colors.black.withOpacity(0.10),
          Colors.black.withOpacity(0.22),
          Colors.black.withOpacity(0.70),
        ],
      );
    }

    return _ArticleHubColors(
      scaffold: const Color(0xFF0B1020),
      panelBg: const Color(0xFF0D1228),
      panelBorder: Colors.white.withOpacity(0.08),
      panelTitle: Colors.white,
      panelSubtitle: Colors.white.withOpacity(0.78),
      headerTitle: Colors.white,
      headerSubtitle: Colors.white.withOpacity(0.70),
      primaryTextOnImage: Colors.white,
      secondaryTextOnImage: Colors.white.withOpacity(0.86),
      chevronOnImage: Colors.white.withOpacity(0.78),
      cardBorder: Colors.white.withOpacity(0.08),
      iconChipBg: Colors.black.withOpacity(0.28),
      iconChipBorder: Colors.white.withOpacity(0.12),
      pillBg: Colors.black.withOpacity(0.34),
      pillBorder: Colors.white.withOpacity(0.14),
      arrowBg: Colors.black.withOpacity(0.30),
      imageLoading: const Color(0xFF151528),
      imageFallback: const Color(0xFF1B1B2A),
      shadow: Colors.black.withOpacity(0.22),
      cardOverlay: [
        Colors.black.withOpacity(0.14),
        Colors.black.withOpacity(0.28),
        Colors.black.withOpacity(0.82),
      ],
    );
  }
}

String _removeReaderFallbackText(String value) {
  var text = value.trim();

  if (text.isEmpty) return '';

  const blockedExact = <String>{
    'tap to read',
    'tap to open',
    'tap to open and read',
    'tap to read article',
    'read article',
    'read more',
    'open article',
  };

  final normalized = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  if (blockedExact.contains(normalized)) {
    return '';
  }

  text = text
      .replaceAll(RegExp(r'\bTap to read\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\bTap to open\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\bTap to open and read\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\bRead article\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\bRead more\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();

  return text;
}

String _readerFirstNonEmpty(Iterable<String> values) {
  for (final value in values) {
    final clean = value.trim();
    if (clean.isNotEmpty) {
      return clean;
    }
  }

  return '';
}
