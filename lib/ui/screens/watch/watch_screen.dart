import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app_config.dart';
import '../../../features/hub/state/hub_scope.dart';
import '../../../services/ads_service.dart';
import '../../../theme/theme_controller.dart';
import '../../media/universal_media_launcher.dart';
import '../../shell/bottom_shell.dart';
import '../../widgets/ads/native_inline_ad_tile.dart';
import '../../widgets/ads/native_list_injection.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';

import 'watch_payload_resolver.dart';

class WatchScreen extends StatelessWidget {
  const WatchScreen({super.key});

  static const String tabKey = 'watch';
  static const String nativeListKey = 'watch.native.channel_list';

  @override
  Widget build(BuildContext context) {
    final hub = HubScope.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([hub, ThemeController.instance]),
      builder: (context, _) {
        final isLight = ThemeController.instance.isLightMode;
        final cards = _buildWatchCards(hub);
        final slides = _buildWatchSlides(hub, cards);
        final listEntries = NativeListInjection.buildEntries<_WatchCardConfig>(
          cards,
          tabKey: nativeListKey,
        );

        AdsService.instance.preloadInterstitial(tabKey: tabKey);

        return Scaffold(
          appBar: DxmTopBar(
            title: AppConfig.tabWatchLabel,
            showMenu: true,
            onRefresh: hub.refresh,
          ),
          body: GradientPageBackground(
            child: RefreshIndicator(
              onRefresh: hub.refresh,
              child: ListView(
                padding: EdgeInsets.only(
                  bottom: BottomShellInsets.of(context) + 12,
                ),
                children: [
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: _WatchHeroCarousel(slides: slides),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConfig.watchChannelsLabel,
                          style: TextStyle(
                            color: isLight
                                ? const Color(0xFF1E1B16)
                                : Colors.white.withOpacity(0.92),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Open available live streams, church broadcasts, special programs and channel alternatives from the backend.',
                          style: TextStyle(
                            color: isLight
                                ? const Color(0xFF6B6256)
                                : Colors.white.withOpacity(0.68),
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (cards.isEmpty)
                          _WatchEmptyState(isLight: isLight)
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final spacing = 12.0;
                              final wide = constraints.maxWidth >= 760;
                              final cardWidth = wide
                                  ? (constraints.maxWidth - spacing) / 2
                                  : constraints.maxWidth;

                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children:
                                    List.generate(listEntries.length, (index) {
                                  final entry = listEntries[index];

                                  if (entry.isAd) {
                                    return SizedBox(
                                      width: cardWidth,
                                      child: const NativeInlineAdTile(
                                        tabKey: nativeListKey,
                                        label: 'Sponsored',
                                        minHeight: 126,
                                      ),
                                    );
                                  }

                                  final card = entry.item!;
                                  return SizedBox(
                                    width: cardWidth,
                                    child: _WatchBannerCard(
                                      title: card.title,
                                      subtitle: card.subtitle,
                                      badge: card.badge,
                                      icon: card.icon,
                                      imageUrl: card.imageUrl,
                                      gradientIndex: entry.itemIndex,
                                      onTap: card.onTap == null
                                          ? null
                                          : () => card.onTap!(context),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static List<_WatchCardConfig> _buildWatchCards(dynamic hub) {
    final cards = <_WatchCardConfig>[];
    final seen = <String>{};

    void addCard(_WatchCardConfig card) {
      final titleKey = _normalizeKey(card.title);
      final urlKey = _normalizeKey(card.url);
      final dedupeKey = urlKey.isNotEmpty ? '$titleKey|$urlKey' : titleKey;

      if (dedupeKey.trim().isEmpty) return;
      if (seen.contains(dedupeKey)) return;

      seen.add(dedupeKey);
      cards.add(card);
    }

    final sections = hub.watchSectionsRaw;

    for (final rawSection in sections) {
      if (rawSection is! Map) continue;

      final section = Map<String, dynamic>.from(rawSection);
      final rawItems = section['items'];

      if (rawItems is! List || rawItems.isEmpty) {
        final sectionCard = _buildSectionBackedWatchCard(
          section: section,
          hub: hub,
          gradientIndex: cards.length,
        );
        if (sectionCard != null) addCard(sectionCard);
        continue;
      }

      final items = rawItems
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((item) {
        final enabled = item['is_enabled'] ?? item['enabled'];
        return enabled != false && enabled != 0 && enabled != '0';
      }).toList(growable: false);

      if (items.isEmpty) continue;

      if (_shouldOpenSectionAsInnerPage(section, items)) {
        final sectionTitle = _pickSectionTitle(section, items);
        if (sectionTitle.isEmpty) continue;

        final sectionSubtitle = _pickSectionSubtitle(section, items);
        final sectionImage = _pickBackendImage(section, fallbackItems: items);
        final sectionBadge = _pickBackendBadge(section, fallback: 'Channels');

        addCard(
          _WatchCardConfig(
            title: sectionTitle,
            subtitle: sectionSubtitle.isNotEmpty
                ? sectionSubtitle
                : 'Open available channels and programs',
            badge: sectionBadge,
            icon: _iconForGroupKey(
              (section['key'] ??
                      section['section_key'] ??
                      section['title'] ??
                      'channels')
                  .toString(),
            ),
            imageUrl: sectionImage.isNotEmpty
                ? sectionImage
                : (hub.brandingBannerUrl ?? ''),
            url: '',
            onTap: (context) {
              _openWatchChannels(
                context,
                title: sectionTitle,
                items: items,
              );
            },
          ),
        );
        continue;
      }

      for (final item in items) {
        final card = _buildExactBackendWatchCard(
          item: item,
          section: section,
          hub: hub,
        );
        if (card != null) addCard(card);
      }
    }

    if (cards.isNotEmpty) return cards;

    final legacyCards = <_WatchCardConfig?>[
      _buildBackendWatchCard(
        item: hub.watchLiveHlsCard,
        fallbackIcon: Icons.live_tv_rounded,
        fallbackImageUrl:
            hub.watchLiveHlsImageUrl ?? hub.brandingBannerUrl ?? '',
      ),
      _buildBackendWatchCard(
        item: hub.watchLiveYoutubeCard,
        fallbackIcon: Icons.church_rounded,
        fallbackImageUrl:
            hub.watchLiveYoutubeImageUrl ?? hub.brandingBannerUrl ?? '',
      ),
      _buildBackendWatchCard(
        item: hub.watchCommandingDayCard,
        fallbackIcon: Icons.wb_sunny_rounded,
        fallbackImageUrl:
            hub.watchCommandingDayImageUrl ?? hub.brandingBannerUrl ?? '',
      ),
    ];

    for (final legacyCard in legacyCards) {
      if (legacyCard != null) addCard(legacyCard);
    }

    for (final item in hub.watchVideoCards) {
      final legacyCard = _buildBackendWatchCard(
        item: item,
        fallbackIcon: _iconForType((item['type'] ?? '').toString()),
        fallbackImageUrl: hub.brandingBannerUrl ?? '',
      );
      if (legacyCard != null) addCard(legacyCard);
    }

    for (final group in hub.watchGroupCards) {
      final items = group['items'];
      if (items is! List || items.isEmpty) continue;

      final title = (group['title'] ?? '').toString().trim();
      if (title.isEmpty) continue;

      final subtitle = (group['subtitle'] ?? '').toString().trim();
      final badge = (group['badge'] ?? '').toString().trim();
      final key = (group['key'] ?? '').toString().trim();

      addCard(
        _WatchCardConfig(
          title: title,
          subtitle: subtitle.isNotEmpty
              ? subtitle
              : 'Open available channels and programs',
          badge: badge.isNotEmpty ? _toTitleCase(badge) : 'Watch',
          icon: _iconForGroupKey(key),
          imageUrl: _cleanImageUrl((group['image_url'] ?? '').toString().trim())
                  .isNotEmpty
              ? _cleanImageUrl((group['image_url'] ?? '').toString().trim())
              : (hub.brandingBannerUrl ?? ''),
          url: '',
          onTap: (context) {
            _openWatchChannels(
              context,
              title: title,
              items: items,
            );
          },
        ),
      );
    }

    return cards;
  }

  static _WatchCardConfig? _buildExactBackendWatchCard({
    required Map<String, dynamic> item,
    required Map<String, dynamic> section,
    required dynamic hub,
  }) {
    final title = (item['title'] ?? '').toString().trim();
    final url = WatchPayloadResolver.resolveUrl(item);

    if (title.isEmpty || url.isEmpty) return null;

    final subtitle = WatchPayloadResolver.resolveSubtitle(
      item,
      fallback:
          (section['subtitle'] ?? section['description'] ?? '').toString(),
    );
    final type = WatchPayloadResolver.resolveType(
      item,
      fallback: (section['type'] ?? section['engine'] ?? '').toString(),
    );
    final imageUrl = WatchPayloadResolver.resolveImageUrl(item);
    final sectionImage = _pickBackendImage(section, fallbackItems: const []);
    final badge = WatchPayloadResolver.resolveBadge(item,
        fallback: _pickBackendBadge(item));

    return _WatchCardConfig(
      title: title,
      subtitle: subtitle.isNotEmpty ? subtitle : 'Open available content',
      badge: badge.isNotEmpty ? badge : _deriveBadgeFromBackend(item),
      icon: _iconForType(type),
      imageUrl: imageUrl.isNotEmpty
          ? imageUrl
          : sectionImage.isNotEmpty
              ? sectionImage
              : (hub.brandingBannerUrl ?? ''),
      url: url,
      onTap: (context) {
        _openWatchItem(
          context,
          title: title,
          type: type,
          url: url,
        );
      },
    );
  }

  static _WatchCardConfig? _buildSectionBackedWatchCard({
    required Map<String, dynamic> section,
    required dynamic hub,
    required int gradientIndex,
  }) {
    final title = (section['title'] ?? '').toString().trim();
    final url = WatchPayloadResolver.resolveUrl(section);

    if (title.isEmpty || url.isEmpty) return null;

    final subtitle =
        (section['subtitle'] ?? section['description'] ?? '').toString().trim();
    final type = (section['type'] ?? section['engine'] ?? '').toString().trim();
    final imageUrl = _pickBackendImage(section, fallbackItems: const []);
    final badge = _pickBackendBadge(section);

    return _WatchCardConfig(
      title: title,
      subtitle: subtitle.isNotEmpty ? subtitle : 'Open available content',
      badge: badge.isNotEmpty ? badge : _deriveBadgeFromBackend(section),
      icon: _iconForType(type),
      imageUrl: imageUrl.isNotEmpty ? imageUrl : (hub.brandingBannerUrl ?? ''),
      url: url,
      onTap: (context) {
        _openWatchItem(
          context,
          title: title,
          type: type,
          url: url,
        );
      },
    );
  }

  static bool _shouldOpenSectionAsInnerPage(
    Map<String, dynamic> section,
    List<Map<String, dynamic>> items,
  ) {
    final key = (section['key'] ??
            section['section_key'] ??
            section['route_key'] ??
            section['title'] ??
            '')
        .toString()
        .trim()
        .toLowerCase();

    final layout = (section['layout'] ?? section['template'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    final type = (section['type'] ?? '').toString().trim().toLowerCase();

    if (key.contains('other_channel') ||
        key.contains('channels') ||
        key.contains('channel_list') ||
        key.contains('christian_tv')) {
      return items.length > 1;
    }

    if (layout.contains('channel') || type == 'channel_group') {
      return items.length > 1;
    }

    return false;
  }

  static String _pickSectionTitle(
    Map<String, dynamic> section,
    List<Map<String, dynamic>> items,
  ) {
    final sectionTitle = (section['title'] ?? '').toString().trim();
    if (sectionTitle.isNotEmpty) return sectionTitle;

    if (items.isNotEmpty) {
      return (items.first['title'] ?? '').toString().trim();
    }

    return '';
  }

  static String _pickSectionSubtitle(
    Map<String, dynamic> section,
    List<Map<String, dynamic>> items,
  ) {
    final subtitle =
        (section['subtitle'] ?? section['description'] ?? '').toString().trim();
    if (subtitle.isNotEmpty) return subtitle;

    if (items.length > 1) {
      return 'Open available channels and programs';
    }

    if (items.isNotEmpty) {
      return (items.first['subtitle'] ?? items.first['description'] ?? '')
          .toString()
          .trim();
    }

    return '';
  }

  static String _pickBackendImage(
    Map<String, dynamic> source, {
    required List<Map<String, dynamic>> fallbackItems,
  }) {
    const keys = [
      'image_url',
      'thumbnail_url',
      'cover_image_url',
      'card_image_url',
      'background_image_url',
      'poster',
      'cover_url',
      'banner_url',
      'image',
    ];

    for (final key in keys) {
      final value = (source[key] ?? '').toString().trim();
      final cleaned = _cleanImageUrl(value);
      if (cleaned.isNotEmpty) return cleaned;
    }

    final payload = source['payload'];
    if (payload is Map) {
      for (final key in keys) {
        final value = (payload[key] ?? '').toString().trim();
        final cleaned = _cleanImageUrl(value);
        if (cleaned.isNotEmpty) return cleaned;
      }
    }

    final meta = source['meta'];
    if (meta is Map) {
      for (final key in keys) {
        final value = (meta[key] ?? '').toString().trim();
        final cleaned = _cleanImageUrl(value);
        if (cleaned.isNotEmpty) return cleaned;
      }
    }

    for (final item in fallbackItems) {
      final image = _pickBackendImage(item, fallbackItems: const []);
      if (image.isNotEmpty) return image;
    }

    return '';
  }

  static String _pickBackendBadge(
    Map<String, dynamic> source, {
    String fallback = '',
  }) {
    final value = (source['badge'] ??
            source['label'] ??
            source['category_label'] ??
            source['category_name'] ??
            fallback)
        .toString()
        .trim();

    if (value.isEmpty) return '';
    return _toTitleCase(value);
  }

  static String _deriveBadgeFromBackend(Map<String, dynamic> item) {
    final explicit = _pickBackendBadge(item);
    if (explicit.isNotEmpty) return explicit;

    final title = (item['title'] ?? '').toString().trim().toLowerCase();
    if (title.contains('healing')) return 'Healing';
    if (title.contains('testimon')) return 'Testimony';
    if (title.contains('crusade')) return 'Crusade';
    if (title.contains('prayer')) return 'Prayer';
    if (title.contains('service')) return 'Service';
    if (title.contains('live')) return 'Live';
    if (title.contains('channel')) return 'Channel';

    final type = (item['type'] ?? '').toString().trim().toLowerCase();
    if (type.contains('hls')) return 'Live';
    if (type.contains('youtube')) return 'Video';
    if (type.contains('playlist')) return 'Playlist';
    if (type.contains('web')) return 'Channel';

    return 'Watch';
  }

  static _WatchCardConfig? _buildBackendWatchCard({
    required Map<String, String>? item,
    required IconData fallbackIcon,
    String fallbackImageUrl = '',
  }) {
    if (item == null || item.isEmpty) return null;

    final title = (item['title'] ?? '').trim();
    final rawUrl = (item['url'] ?? '').trim();
    final url = _cleanUrl(rawUrl);

    if (title.isEmpty || url.isEmpty) return null;

    final subtitle = (item['subtitle'] ?? '').trim();
    final type = (item['type'] ?? '').trim();
    final imageUrl = _cleanImageUrl((item['image_url'] ?? '').trim());
    final badge = (item['badge'] ?? '').trim();

    return _WatchCardConfig(
      title: title,
      subtitle: subtitle.isNotEmpty ? subtitle : 'Open available watch item',
      badge: badge.isNotEmpty ? _toTitleCase(badge) : _deriveBadge(item),
      icon: _iconForType(type, fallback: fallbackIcon),
      imageUrl:
          imageUrl.isNotEmpty ? imageUrl : _cleanImageUrl(fallbackImageUrl),
      url: url,
      onTap: (context) {
        _openWatchItem(
          context,
          title: title,
          type: type,
          url: url,
        );
      },
    );
  }

  static List<Map<String, String>> _buildWatchSlides(
    dynamic hub,
    List<_WatchCardConfig> cards,
  ) {
    final slides = <Map<String, String>>[];

    for (final card in cards.take(10)) {
      slides.add({
        'title': card.title,
        'subtitle': card.subtitle,
        'image_url': card.imageUrl,
      });
    }

    if (slides.isEmpty && (hub.brandingBannerUrl ?? '').toString().isNotEmpty) {
      slides.add({
        'title': AppConfig.tabWatchLabel,
        'subtitle': 'Watch content will appear here when enabled from backend.',
        'image_url': hub.brandingBannerUrl ?? '',
      });
    }

    return slides;
  }

  static String _deriveBadge(Map<String, String> item) {
    final explicit = (item['badge'] ?? '').trim();
    if (explicit.isNotEmpty) return _toTitleCase(explicit);

    final title = (item['title'] ?? '').trim().toLowerCase();
    if (title.contains('healing')) return 'Healing';
    if (title.contains('testimon')) return 'Testimony';
    if (title.contains('crusade')) return 'Crusade';
    if (title.contains('prayer')) return 'Prayer';
    if (title.contains('service')) return 'Service';
    if (title.contains('live')) return 'Live';
    if (title.contains('channel')) return 'Channel';

    final type = (item['type'] ?? '').trim().toLowerCase();
    if (type.contains('hls')) return 'Live';
    if (type.contains('youtube')) return 'Video';
    if (type.contains('playlist')) return 'Playlist';
    if (type.contains('web')) return 'Channel';

    return 'Watch';
  }

  static String _cleanUrl(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return '';

    final match = RegExp(r'https?://[^\s]+').firstMatch(raw);
    if (match != null) return match.group(0)!;

    return raw;
  }

  static String _cleanImageUrl(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return '';

    final match = RegExp(r'https?://[^\s]+').firstMatch(raw);
    if (match != null) return match.group(0)!;

    return raw;
  }

  static String _toTitleCase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;

    return trimmed.split(RegExp(r'\s+')).map((part) {
      if (part.isEmpty) return part;
      final lower = part.toLowerCase();
      return '${lower[0].toUpperCase()}${lower.substring(1)}';
    }).join(' ');
  }

  static String _normalizeKey(String value) {
    return value.trim().toLowerCase();
  }

  static IconData _iconForGroupKey(String key) {
    final k = key.trim().toLowerCase();

    if (k.contains('channel')) return Icons.tv_rounded;
    if (k.contains('crusade')) return Icons.campaign_rounded;
    if (k.contains('healing')) return Icons.healing_rounded;
    if (k.contains('testimon')) return Icons.record_voice_over_rounded;
    if (k.contains('prayer')) return Icons.wb_sunny_rounded;

    return Icons.view_carousel_rounded;
  }

  static IconData _iconForType(
    String type, {
    IconData fallback = Icons.play_circle_fill_rounded,
  }) {
    final t = type.trim().toLowerCase();

    if (t == 'hls' || t == 'live_hls') return Icons.live_tv_rounded;
    if (t == 'youtube' ||
        t == 'live_youtube' ||
        t == 'youtube_playlist' ||
        t == 'playlist') {
      return Icons.church_rounded;
    }
    if (t == 'commanding_day') return Icons.wb_sunny_rounded;
    if (t == 'channel' || t == 'web' || t == 'html' || t == 'embed') {
      return Icons.tv_rounded;
    }
    if (t == 'video' || t == 'vod' || t == 'youtube_video') {
      return Icons.play_circle_fill_rounded;
    }

    return fallback;
  }

  static Future<void> _openWatchChannels(
    BuildContext context, {
    required String title,
    required List items,
  }) async {
    await AdsService.instance.maybeShowInterstitialOnSafeNav(
      context,
      tabKey: 'watch.action.open_channels',
    );

    if (!context.mounted) return;

    context.push(
      '/watch/channels',
      extra: {
        'title': title,
        'items': items,
      },
    );
  }

  static String _actionPolicyKeyForType(String rawType) {
    final type = rawType.trim().toLowerCase();

    if (type == 'hls' || type == 'live_hls' || type == 'live') {
      return 'watch.action.open_live_hls';
    }
    if (type == 'youtube_playlist' || type == 'playlist') {
      return 'watch.action.open_playlist';
    }
    if (type == 'youtube' ||
        type == 'live_youtube' ||
        type == 'youtube_video') {
      return 'watch.action.open_youtube';
    }
    if (type == 'channel' ||
        type == 'web' ||
        type == 'html' ||
        type == 'embed') {
      return 'watch.action.open_web_embed';
    }
    if (type == 'video' || type == 'vod') {
      return 'watch.action.open_video_collection';
    }

    return 'watch.action.other';
  }

  static Future<void> _openWatchItem(
    BuildContext context, {
    required String title,
    required String type,
    required String url,
  }) async {
    final cleanTitle =
        title.trim().isEmpty ? AppConfig.tabWatchLabel : title.trim();
    final cleanType = type.trim();
    final cleanUrl = _cleanUrl(url);

    if (cleanUrl.isEmpty) return;

    final policyKey = _actionPolicyKeyForType(cleanType);

    await AdsService.instance.maybeShowInterstitialOnSafeNav(
      context,
      tabKey: policyKey,
    );

    if (!context.mounted) return;

    UniversalMediaLauncher.open(
      context,
      title: cleanTitle,
      url: cleanUrl,
      type: cleanType,
    );
  }
}

class _WatchCardConfig {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final String imageUrl;
  final String url;
  final void Function(BuildContext context)? onTap;

  const _WatchCardConfig({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.imageUrl,
    required this.url,
    required this.onTap,
  });
}

class _WatchHeroCarousel extends StatefulWidget {
  final List<Map<String, String>> slides;

  const _WatchHeroCarousel({
    required this.slides,
  });

  @override
  State<_WatchHeroCarousel> createState() => _WatchHeroCarouselState();
}

class _WatchHeroCarouselState extends State<_WatchHeroCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  List<Map<String, String>> get _effectiveSlides {
    if (widget.slides.isNotEmpty) return widget.slides;

    return [
      {
        'title': AppConfig.tabWatchLabel,
        'subtitle': 'Watch content will appear here when enabled from backend.',
        'image_url': '',
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 1.0);
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant _WatchHeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slides.length != widget.slides.length) {
      _index = 0;
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _timer?.cancel();

    final count = _effectiveSlides.length;
    if (count <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_index + 1) % count;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _goTo(int next) {
    final count = _effectiveSlides.length;
    if (count == 0) return;

    final safe = (next % count + count) % count;
    _controller.animateToPage(
      safe,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _effectiveSlides;

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: PageView.builder(
                  controller: _controller,
                  itemCount: slides.length,
                  onPageChanged: (value) {
                    if (!mounted) return;
                    setState(() => _index = value);
                  },
                  itemBuilder: (context, i) {
                    final slide = slides[i];
                    return _WatchHeroSlideCard(
                      title: slide['title']?.trim().isNotEmpty == true
                          ? slide['title']!
                          : AppConfig.tabWatchLabel,
                      subtitle: slide['subtitle']?.trim().isNotEmpty == true
                          ? slide['subtitle']!
                          : 'Watch content will appear here when enabled from backend.',
                      imageUrl: slide['image_url'],
                      gradientIndex: i,
                    );
                  },
                ),
              ),
              if (slides.length > 1)
                Positioned(
                  left: 10,
                  top: 0,
                  bottom: 0,
                  child: _WatchHeroArrowButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _goTo(_index - 1),
                  ),
                ),
              if (slides.length > 1)
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: _WatchHeroArrowButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => _goTo(_index + 1),
                  ),
                ),
            ],
          ),
        ),
        if (slides.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              slides.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 16 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _index
                      ? const Color(0xFFFF3CA6)
                      : Colors.white.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _WatchHeroSlideCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final int gradientIndex;

  const _WatchHeroSlideCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.gradientIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _WatchSmartImage(
          imageUrl: imageUrl,
          height: 190,
          gradientIndex: gradientIndex,
        ),
        Container(
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.16),
                Colors.black.withOpacity(0.28),
                Colors.black.withOpacity(0.82),
              ],
              stops: const [0.0, 0.42, 1.0],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WatchHeroArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _WatchHeroArrowButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.black.withOpacity(0.28),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _WatchBannerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final String? imageUrl;
  final int gradientIndex;
  final VoidCallback? onTap;

  const _WatchBannerCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.imageUrl,
    required this.gradientIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Opacity(
      opacity: enabled ? 1 : 0.62,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            height: 170,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  color: Colors.black.withOpacity(0.18),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: _WatchSmartImage(
                    imageUrl: imageUrl,
                    height: 170,
                    gradientIndex: gradientIndex,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.10),
                        Colors.black.withOpacity(0.22),
                        Colors.black.withOpacity(0.80),
                      ],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _WatchBadge(text: badge),
                          const Spacer(),
                          Icon(
                            icon,
                            color: Colors.white.withOpacity(0.92),
                            size: 24,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.90),
                          fontSize: 12.5,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
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

class _WatchSmartImage extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final int gradientIndex;

  const _WatchSmartImage({
    required this.imageUrl,
    required this.height,
    required this.gradientIndex,
  });

  bool get _hasRemoteImage {
    final raw = (imageUrl ?? '').trim();
    if (raw.isEmpty) return false;

    final uri = Uri.tryParse(raw);
    if (uri == null) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  @override
  Widget build(BuildContext context) {
    if (_hasRemoteImage) {
      return Image.network(
        imageUrl!.trim(),
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _WatchGradientPlaceholder(
            height: height,
            index: gradientIndex,
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;

          return Stack(
            children: [
              _WatchGradientPlaceholder(
                height: height,
                index: gradientIndex,
              ),
              Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return _WatchGradientPlaceholder(
      height: height,
      index: gradientIndex,
    );
  }
}

class _WatchGradientPlaceholder extends StatelessWidget {
  final double height;
  final int index;

  const _WatchGradientPlaceholder({
    required this.height,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    const palettes = [
      [Color(0xFF0B1F4D), Color(0xFF1D5CFF), Color(0xFFE2388A)],
      [Color(0xFF180B3A), Color(0xFF5F3BFF), Color(0xFF35C6FF)],
      [Color(0xFF081F2D), Color(0xFF087E8B), Color(0xFFB9FBC0)],
      [Color(0xFF2A0D30), Color(0xFF8E24AA), Color(0xFFFF4E8A)],
      [Color(0xFF111827), Color(0xFF2563EB), Color(0xFF9333EA)],
    ];

    final colors = palettes[index % palettes.length];

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: -38,
            child: Container(
              width: 126,
              height: 126,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            left: -28,
            bottom: -34,
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchBadge extends StatelessWidget {
  final String text;

  const _WatchBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    final safeText = text.trim().isEmpty ? 'Watch' : text.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Text(
        safeText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WatchEmptyState extends StatelessWidget {
  final bool isLight;

  const _WatchEmptyState({
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE6D8C3)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Text(
        'No watch channels are available right now. Pull to refresh or check your backend watch feed.',
        style: TextStyle(
          color: isLight
              ? const Color(0xFF6B6256)
              : Colors.white.withOpacity(0.72),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }
}
