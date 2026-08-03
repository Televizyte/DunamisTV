import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/hub/models/dynamic_section.dart';
import '../../../features/hub/renderer/dynamic_insert_block_resolver.dart';
import '../../../features/hub/renderer/dynamic_section_renderer.dart';
import '../../../features/hub/state/hub_scope.dart';
import '../../../services/ads_service.dart';
import '../../widgets/ads/native_inline_ad_tile.dart';
import '../../widgets/ads/native_list_injection.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';

class MotivationHubScreen extends StatelessWidget {
  const MotivationHubScreen({super.key});

  static const String pageAdKey = 'inspire.motivation';

  @override
  Widget build(BuildContext context) {
    final store = HubScope.maybeOf(context);
    final Map<String, dynamic> hubMap = store?.raw ?? const <String, dynamic>{};

    final inspire = (hubMap['inspire'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    final List<Map<String, dynamic>> items = _extractItems(inspire);
    final List<Map<String, dynamic>> featuredItems =
        _extractFeaturedItems(inspire, items);
    final motivationDynamicSections =
        _extractMotivationDynamicSections(inspire);
    final motivationTopSections =
        DynamicInsertBlockResolver.topSections(motivationDynamicSections);
    final motivationInlineSections =
        DynamicInsertBlockResolver.inlineSections(motivationDynamicSections);

    final listEntries = NativeListInjection.buildEntries<Map<String, dynamic>>(
      items,
      tabKey: pageAdKey,
    );

    AdsService.instance.preloadInterstitial(tabKey: pageAdKey);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
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
            title: 'Motivation',
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
                      title: _resolveScreenText(
                        inspire,
                        const ['motivation_featured_title', 'featured_title'],
                        fallback: 'Featured Motivation',
                      ),
                      subtitle: _resolveScreenText(
                        inspire,
                        const [
                          'motivation_featured_subtitle',
                          'featured_subtitle'
                        ],
                        fallback:
                            'Swipe or use the arrows to browse featured posts.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (featuredItems.isEmpty)
                      const _EmptyCard(
                        title: 'No featured content yet',
                        subtitle: 'AppsHub will publish featured content here.',
                        icon: Icons.favorite_rounded,
                      )
                    else
                      _FeaturedCarousel(
                        items: featuredItems,
                        source: 'motivation',
                        icon: Icons.favorite_rounded,
                        fallbackPill: 'FEATURED',
                      ),
                    if (motivationTopSections.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      ...motivationTopSections.map(
                        (section) => DynamicHubSectionRenderer(
                          section: section,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _SectionHeader(
                      title: _resolveScreenText(
                        inspire,
                        const ['motivation_all_title', 'all_title'],
                        fallback: 'All Motivation',
                      ),
                      subtitle: _resolveScreenText(
                        inspire,
                        const ['motivation_all_subtitle', 'all_subtitle'],
                        fallback: 'Browse all available posts below.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      const _EmptyCard(
                        title: 'No content yet',
                        subtitle: 'AppsHub will publish content here.',
                        icon: Icons.favorite_rounded,
                      )
                    else
                      _MotivationArticleFlow(
                        entries: listEntries,
                        quoteSections: motivationInlineSections,
                        buildArticleCard: (item, itemIndex) =>
                            _buildArticleCard(
                          context,
                          item,
                          itemIndex,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildArticleCard(
    BuildContext context,
    Map<String, dynamic> m,
    int index,
  ) {
    final id = (m['id'] ?? m['slug'] ?? 'item_$index').toString();

    final title = _firstNonEmpty([
      (m['title'] ?? '').toString(),
      (m['topic'] ?? '').toString(),
      'Motivation',
    ]);

    final subtitle = _firstNonEmpty([
      (m['subtitle'] ?? '').toString(),
      _resolveMetaLine(m),
      (m['date'] ?? '').toString(),
    ]);
    final excerpt = _resolveExcerpt(m);

    return _ArticleListCard(
      title: title,
      subtitle: subtitle,
      excerpt: excerpt,
      imageUrl: _pickImage(m),
      fallbackAsset: _fallbackAssetFor(index),
      pillText: _resolvePillText(m, fallback: 'Motivation'.toUpperCase()),
      icon: Icons.favorite_rounded,
      onTap: () async {
        await AdsService.instance.maybeShowInterstitialOnSafeNav(
          context,
          tabKey: pageAdKey,
        );
        if (!context.mounted) return;
        context.push(
          '/articles/detail',
          extra: {'id': id, 'source': 'motivation'},
        );
      },
    );
  }

  static List<Map<String, dynamic>> _extractItems(
    Map<String, dynamic> inspire,
  ) {
    for (final key in const ['motivation']) {
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

  static List<HubDynamicSection> _extractMotivationDynamicSections(
    Map<String, dynamic> inspire,
  ) {
    return DynamicInsertBlockResolver.extractSections(
      inspire,
      targetBuckets: const ['motivation', 'inspire_motivation'],
    );
  }

  static bool _isMotivationShortVideoSection(HubDynamicSection section) {
    return DynamicInsertBlockResolver.isShortVideoSection(section);
  }

  static bool _isMotivationQuoteSection(HubDynamicSection section) {
    return DynamicInsertBlockResolver.isQuoteSection(section);
  }

  static int _sectionInsertAfter(HubDynamicSection section) {
    return DynamicInsertBlockResolver.insertAfter(section);
  }

  static String _motivationSectionHaystack(HubDynamicSection section) {
    final buffer = StringBuffer()
      ..write(' ')
      ..write(section.key)
      ..write(' ')
      ..write(section.title)
      ..write(' ')
      ..write(section.subtitle)
      ..write(' ')
      ..write(section.layout.name);

    void add(dynamic value) {
      if (value == null) return;
      if (value is Map) {
        for (final child in value.values) add(child);
        return;
      }
      if (value is List) {
        for (final child in value) add(child);
        return;
      }
      buffer.write(' ');
      buffer.write(value.toString());
    }

    add(section.settings);
    for (final item in section.items.take(3)) add(item);

    return buffer
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9/\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  static bool _isBackendControlledMotivationSection(
    Map<String, dynamic> section,
  ) {
    final id = section['id'];
    final isRealDestinationSection = id is int && id > 0;

    final settings = <String, dynamic>{};
    void mergeMap(dynamic value) {
      if (value is! Map) return;
      value.forEach((key, val) => settings[key.toString()] = val);
    }

    mergeMap(section);
    mergeMap(section['source']);
    mergeMap(section['meta']);
    mergeMap(section['settings']);

    String value(String key) => (settings[key] ?? '').toString().trim();
    String norm(String raw) => _motivationNormalizeKey(raw);

    final key = norm(value('key').isNotEmpty
        ? value('key')
        : value('section_key').isNotEmpty
            ? value('section_key')
            : (section['key'] ?? section['section_key'] ?? '').toString());
    final routeKey =
        norm((section['route_key'] ?? settings['route_key'] ?? '').toString());
    final placement = norm(value('placement'));
    final targetPage = norm(value('target_page'));
    final insertTarget = norm(value('insert_target_bucket'));
    final bucket = norm(value('source_bucket').isNotEmpty
        ? value('source_bucket')
        : value('bucket'));
    final sourceType = norm(value('source_type').isNotEmpty
        ? value('source_type')
        : value('content_source'));
    final engine = norm(value('content_engine').isNotEmpty
        ? value('content_engine')
        : value('engine'));
    final layout = norm(value('layout_variant').isNotEmpty
        ? value('layout_variant')
        : value('layout').isNotEmpty
            ? value('layout')
            : (section['template'] ?? section['layout'] ?? '').toString());

    final targetsMotivation = routeKey == 'motivation' ||
        placement == 'motivation' ||
        targetPage == 'motivation' ||
        insertTarget == 'motivation' ||
        key == 'motivation_short_videos' ||
        key == 'motivation_quotes';

    final isShortVideoSection = engine.contains('short_video') ||
        sourceType.contains('short_video') ||
        layout.contains('short_video') ||
        key.contains('motivation_short');

    final isQuoteSection = engine.contains('quote') ||
        sourceType.contains('quote') ||
        layout.contains('quote') ||
        bucket == 'motivational_quotes' ||
        key == 'motivation_quotes';

    // Do not render synthetic branding-only short-video placements here.
    // Motivation page sections must be controllable from Destination Builder.
    return isRealDestinationSection &&
        targetsMotivation &&
        (isShortVideoSection || isQuoteSection);
  }

  static List<Map<String, dynamic>> _extractFeaturedItems(
    Map<String, dynamic> inspire,
    List<Map<String, dynamic>> items,
  ) {
    for (final key in const [
      'motivation_featured',
      'featured_motivation',
      'featured',
    ]) {
      final configured = inspire[key];
      if (configured is List) {
        final normalized = configured
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
        if (normalized.isNotEmpty) return normalized.take(9).toList();
      }
    }

    final flagged = items.where((item) {
      final featured = item['featured'];
      final pinned = item['pinned'];
      return featured == true ||
          pinned == true ||
          featured?.toString().toLowerCase() == 'true' ||
          pinned?.toString().toLowerCase() == 'true';
    }).toList(growable: false);

    if (flagged.isNotEmpty) return flagged.take(9).toList(growable: false);
    return items.take(9).toList(growable: false);
  }

  static String _resolveScreenText(
    Map<String, dynamic> inspire,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = inspire[key];
      final s = value?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }

    final meta = inspire['motivation_meta'];
    if (meta is Map) {
      for (final key in keys) {
        final value = meta[key];
        final s = value?.toString().trim() ?? '';
        if (s.isNotEmpty) return s;
      }
    }

    return fallback;
  }

  static String _resolvePillText(
    Map<String, dynamic> item, {
    required String fallback,
  }) {
    for (final value in [
      item['pill_text'],
      item['badge'],
      item['label'],
      item['category'],
      item['type'],
    ]) {
      final s = value?.toString().trim() ?? '';
      if (s.isNotEmpty) return s.toUpperCase();
    }

    final meta = item['meta'];
    if (meta is Map) {
      for (final key in ['pill_text', 'badge', 'label', 'category', 'type']) {
        final value = meta[key];
        final s = value?.toString().trim() ?? '';
        if (s.isNotEmpty) return s.toUpperCase();
      }
    }

    return fallback;
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

  static String _resolveExcerpt(Map<String, dynamic> item) {
    final bodyText = _firstNonEmpty([
      (item['body'] ?? '').toString(),
      (item['content'] ?? '').toString(),
      (item['text'] ?? '').toString(),
      (item['body_html'] ?? '').toString(),
      _textFromBlocks(item['blocks']),
      _textFromBlocks(item['blocks_json']),
      _textFromNested(item, 'payload', const [
        'body',
        'content',
        'text',
        'body_html',
      ]),
    ]);

    if (bodyText.trim().isNotEmpty) {
      return _limitExcerpt(_cleanContentString(bodyText));
    }

    final direct = _firstNonEmpty([
      (item['excerpt'] ?? '').toString(),
      (item['summary'] ?? '').toString(),
      (item['description'] ?? '').toString(),
      _textFromNested(item, 'payload', const [
        'excerpt',
        'summary',
        'description',
      ]),
      _textFromNested(item, 'meta', const [
        'excerpt',
        'summary',
        'description',
      ]),
    ]);

    return _limitExcerpt(_cleanContentString(direct));
  }

  static String _resolveMetaLine(Map<String, dynamic> item) {
    final parts = <String>[];
    final author = _firstNonEmpty([
      (item['author_name'] ?? '').toString(),
      (item['author'] ?? '').toString(),
      (item['publisher_name'] ?? '').toString(),
    ]);
    if (author.trim().isNotEmpty) parts.add(author.trim());

    final date = _firstNonEmpty([
      (item['published_at'] ?? '').toString(),
      (item['publish_at'] ?? '').toString(),
      (item['date'] ?? '').toString(),
      (item['created_at'] ?? '').toString(),
    ]);
    if (date.trim().isNotEmpty) parts.add(date.trim());

    return parts.join(' || ');
  }

  static String _textFromNested(
    Map<String, dynamic> item,
    String key,
    List<String> fields,
  ) {
    final raw = item[key];
    if (raw is! Map) return '';
    final nested = raw.cast<dynamic, dynamic>();
    return _firstNonEmpty(fields.map((field) {
      return (nested[field] ?? '').toString();
    }).toList());
  }

  static String _textFromBlocks(dynamic rawBlocks) {
    if (rawBlocks is! List) return '';
    final parts = <String>[];
    for (final raw in rawBlocks) {
      if (raw is! Map) continue;
      for (final key in const ['text', 'body', 'content', 'html', 'quote']) {
        final value = raw[key];
        if (value == null) continue;
        final clean = _cleanContentString(value.toString());
        if (clean.isNotEmpty) parts.add(clean);
      }
    }
    return parts.join(' ');
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

  static String _limitExcerpt(String value) {
    final clean = value.trim();
    if (clean.length <= 220) return clean;
    return '${clean.substring(0, 217).trim()}...';
  }

  static String _fallbackAssetFor(int index) {
    const assets = [
      'assets/images/home_4.jpg',
      'assets/images/home_3.jpg',
      'assets/images/home_5.jpg',
      'assets/images/home_2.jpg',
      'assets/images/home_1.jpg',
    ];
    return assets[index % assets.length];
  }
}

class _FeaturedCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String source;
  final IconData icon;
  final String fallbackPill;

  const _FeaturedCarousel({
    required this.items,
    required this.source,
    required this.icon,
    required this.fallbackPill,
  });

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  static const _autoScrollDelay = Duration(seconds: 4);

  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88);
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (widget.items.length <= 1) return;

    _timer = Timer.periodic(_autoScrollDelay, (_) {
      if (!mounted || !_controller.hasClients || widget.items.isEmpty) return;
      final next = (_index + 1) % widget.items.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _restartAutoScroll() => _startAutoScroll();

  void _goTo(int next) {
    if (widget.items.isEmpty) return;
    final safe = next.clamp(0, widget.items.length - 1);
    _controller.animateToPage(
      safe,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
    _restartAutoScroll();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 286,
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is UserScrollNotification) _restartAutoScroll();
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.items.length,
              onPageChanged: (value) {
                if (!mounted) return;
                setState(() => _index = value);
              },
              itemBuilder: (context, i) {
                final m = widget.items[i];
                final id = (m['id'] ?? m['slug'] ?? 'featured_$i').toString();
                final title = MotivationHubScreen._firstNonEmpty([
                  (m['title'] ?? '').toString(),
                  (m['topic'] ?? '').toString(),
                  'Motivation',
                ]);
                final subtitle = MotivationHubScreen._firstNonEmpty([
                  (m['subtitle'] ?? '').toString(),
                  MotivationHubScreen._resolveMetaLine(m),
                ]);
                final excerpt = MotivationHubScreen._resolveExcerpt(m);

                return Padding(
                  padding: EdgeInsets.only(
                    right: i == widget.items.length - 1 ? 0 : 12,
                  ),
                  child: _FeaturedArticleCard(
                    title: title,
                    subtitle: subtitle,
                    excerpt: excerpt,
                    imageUrl: MotivationHubScreen._pickImage(m),
                    fallbackAsset: MotivationHubScreen._fallbackAssetFor(i),
                    icon: widget.icon,
                    pillText: MotivationHubScreen._resolvePillText(
                      m,
                      fallback: widget.fallbackPill,
                    ),
                    onTap: () async {
                      await AdsService.instance.maybeShowInterstitialOnSafeNav(
                        context,
                        tabKey: MotivationHubScreen.pageAdKey,
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
  final String? imageUrl;
  final String fallbackAsset;
  final IconData icon;
  final String pillText;
  final VoidCallback onTap;

  const _FeaturedArticleCard({
    required this.title,
    required this.subtitle,
    required this.excerpt,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.icon,
    required this.pillText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cleanTitle = title.trim();
    final cleanSubtitle = subtitle.trim();
    final rawExcerpt = excerpt.trim();
    final normTitle = cleanTitle.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final normSubtitle =
        cleanSubtitle.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final normExcerpt =
        rawExcerpt.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final cleanExcerpt = rawExcerpt.isEmpty ||
            normExcerpt == normSubtitle ||
            normExcerpt == normTitle
        ? ''
        : rawExcerpt;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF101735),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _SmartCardImage(
                          imageUrl: imageUrl,
                          fallbackAsset: fallbackAsset,
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: _Pill(text: pillText),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        if (cleanSubtitle.isNotEmpty) ...[
                          Text(
                            cleanSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.76),
                              fontSize: 12.2,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (cleanExcerpt.isNotEmpty)
                          Expanded(
                            child: Text(
                              cleanExcerpt,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.76),
                                fontSize: 12.6,
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                        Row(
                          children: [
                            Text(
                              'Read more',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.92),
                                fontSize: 12.8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white.withOpacity(0.86),
                              size: 25,
                            ),
                          ],
                        ),
                      ],
                    ),
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

class _ArticleListCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String excerpt;
  final String? imageUrl;
  final String fallbackAsset;
  final String pillText;
  final IconData icon;
  final VoidCallback onTap;

  const _ArticleListCard({
    required this.title,
    required this.subtitle,
    required this.excerpt,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.pillText,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cleanTitle = title.trim();
    final cleanSubtitle = subtitle.trim();
    final rawExcerpt = excerpt.trim();
    final normTitle = cleanTitle.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final normSubtitle =
        cleanSubtitle.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final normExcerpt =
        rawExcerpt.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final cleanExcerpt = rawExcerpt.isEmpty ||
            normExcerpt == normSubtitle ||
            normExcerpt == normTitle
        ? ''
        : rawExcerpt;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF101735),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 150,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _SmartCardImage(
                          imageUrl: imageUrl,
                          fallbackAsset: fallbackAsset,
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: _Pill(text: pillText),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (cleanSubtitle.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Text(
                          cleanSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            fontSize: 12.4,
                            height: 1.24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (cleanExcerpt.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          cleanExcerpt,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.74),
                            fontSize: 12.8,
                            height: 1.32,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 13),
                      Row(
                        children: [
                          Text(
                            'Read more',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.92),
                              fontSize: 12.8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white.withOpacity(0.86),
                            size: 25,
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

class _CardOverlay extends StatelessWidget {
  const _CardOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.14),
            Colors.black.withOpacity(0.28),
            Colors.black.withOpacity(0.82),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _CarouselArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: Material(
          color: Colors.black.withOpacity(0.30),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: enabled ? onTap : null,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

class _MotivationArticleFlow extends StatelessWidget {
  final List<dynamic> entries;
  final List<HubDynamicSection> quoteSections;
  final Widget Function(Map<String, dynamic> item, int itemIndex)
      buildArticleCard;

  const _MotivationArticleFlow({
    required this.entries,
    required this.quoteSections,
    required this.buildArticleCard,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    final pendingQuoteSections = List<HubDynamicSection>.from(quoteSections);

    var contentCount = 0;

    void addQuoteSectionsForCurrentPosition() {
      if (pendingQuoteSections.isEmpty) return;

      final ready = pendingQuoteSections
          .where((section) =>
              contentCount >= MotivationHubScreen._sectionInsertAfter(section))
          .toList(growable: false);

      for (final section in ready) {
        pendingQuoteSections.remove(section);
        if (children.isNotEmpty) children.add(const SizedBox(height: 14));
        children.add(
          DynamicHubSectionRenderer(
            section: section,
            padding: EdgeInsets.zero,
          ),
        );
      }
    }

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];

      if (entry.isAd) {
        children.add(
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: NativeInlineAdTile(
              tabKey: MotivationHubScreen.pageAdKey,
              label: 'Sponsored',
              minHeight: 120,
            ),
          ),
        );
        continue;
      }

      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: buildArticleCard(entry.item!, entry.itemIndex),
        ),
      );
      contentCount++;
      addQuoteSectionsForCurrentPosition();
    }

    for (final section in pendingQuoteSections) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 14));
      children.add(
        DynamicHubSectionRenderer(
          section: section,
          padding: EdgeInsets.zero,
        ),
      );
    }

    if (children.isNotEmpty && children.last is Padding) {
      final last = children.removeLast() as Padding;
      children.add(Padding(padding: EdgeInsets.zero, child: last.child));
    }

    return Column(children: children);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.70),
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

  const _SmartCardImage({
    required this.imageUrl,
    required this.fallbackAsset,
  });

  bool get _hasRemoteImage {
    final raw = (imageUrl ?? '').trim();
    if (raw.isEmpty) return false;
    final uri = Uri.tryParse(raw);
    if (uri == null) return raw.startsWith('assets/');
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  @override
  Widget build(BuildContext context) {
    final raw = (imageUrl ?? '').trim();

    if (_hasRemoteImage && raw.startsWith('assets/')) {
      return Image.asset(
        raw,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    if (_hasRemoteImage) {
      return Image.network(
        raw,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: const Color(0xFF151528),
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

    return _fallback();
  }

  Widget _fallback() {
    return Image.asset(
      fallbackAsset,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1B1B2A)),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;

  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 34),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
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

  const _EmptyCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        color: const Color(0xFF0D1228),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
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
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.78),
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

String _motivationNormalizeKey(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}
