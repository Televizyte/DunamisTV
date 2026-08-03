import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../content/links.dart';
import '../../../features/hub/state/hub_scope.dart';
import '../../../theme/theme_controller.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';

class SodHubScreen extends StatelessWidget {
  const SodHubScreen({super.key});

  static const String _readSodUrl =
      'https://dunamisgospel.org/category/seed-of-destiny/';

  static const String _watchSodUrl =
      'https://youtube.com/playlist?list=PLsFcFNo2Ku1_ntUPoiEhY-uNR3GsSi2X4&si=z8mOg6vYOfctx9CO';

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
        final colors = _SodColors.fromBrightness(isLight);

        final hub = store?.raw ?? const <String, dynamic>{};
        final inspire = (hub['inspire'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};

        final sodSection = _extractSodSection(inspire);
        final sodItems = _extractSodItems(inspire, sodSection);
        final quoteCount = _extractQuoteCount(inspire, sodItems);

        final banner = _buildBanner(hub, inspire, sodSection, sodItems);
        final cards = _buildSodCards(
          hub,
          inspire,
          sodSection,
          sodItems,
          quoteCount,
        );

        return Scaffold(
          backgroundColor: colors.scaffold,
          bottomNavigationBar: const SafeArea(
            top: false,
            child: BannerAdWidget(
              tabKey: 'inspire.sod',
              padding: EdgeInsets.fromLTRB(12, 8, 12, 10),
            ),
          ),
          body: Column(
            children: [
              DxmTopBar(
                title:
                    banner.title.isNotEmpty ? banner.title : 'Seed of Destiny',
                showBack: true,
                showMenu: true,
                onRefresh: () => store?.refresh(),
              ),
              Expanded(
                child: GradientPageBackground(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await store?.refresh();
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                      children: [
                        _SodTopBanner(
                          title: banner.title.isNotEmpty
                              ? banner.title
                              : 'Seed of Destiny',
                          subtitle: banner.subtitle.isNotEmpty
                              ? banner.subtitle
                              : 'Daily devotion • Watch • Quotes',
                          imageUrl: banner.imageUrl,
                          fallbackAsset: 'assets/images/home_2.jpg',
                          pillText: banner.pillText.isNotEmpty
                              ? banner.pillText
                              : 'SEED OF DESTINY',
                          colors: colors,
                        ),
                        const SizedBox(height: 18),
                        if (cards.isEmpty)
                          _EmptyCard(
                            title: 'No Seed of Destiny actions yet',
                            subtitle:
                                'AppsHub will publish SOD actions and cards here automatically.',
                            icon: Icons.menu_book_rounded,
                            colors: colors,
                          )
                        else
                          ...List.generate(cards.length, (index) {
                            final card = cards[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == cards.length - 1 ? 0 : 14,
                              ),
                              child: _SodActionCard(
                                title: card.title,
                                subtitle: card.subtitle,
                                badgeText: card.badgeText,
                                icon: card.icon,
                                imageUrl: card.imageUrl,
                                fallbackAsset: _fallbackAssetFor(index),
                                onTap: () => _handleCardTap(context, card),
                                colors: colors,
                              ),
                            );
                          }),
                        if ((store?.error ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              'Backend currently unavailable. Showing available SOD content.',
                              style: TextStyle(
                                color: colors.metaText,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
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

  static Map<String, dynamic>? _extractSodSection(
    Map<String, dynamic> inspire,
  ) {
    for (final sourceKey in const ['sections', 'cards', 'hub_cards']) {
      final raw = inspire[sourceKey];
      if (raw is! List) continue;

      for (final item in raw) {
        if (item is! Map) continue;
        final map = item.cast<String, dynamic>();

        final hay = [
          map['bucket'],
          map['key'],
          map['route_key'],
          map['title'],
          map['name'],
        ].whereType<Object>().map((e) => e.toString().toLowerCase()).join(' ');

        if (hay.contains('seed') || hay.contains('sod')) {
          return map;
        }
      }
    }

    return null;
  }

  static List<Map<String, dynamic>> _extractSodItems(
    Map<String, dynamic> inspire,
    Map<String, dynamic>? sodSection,
  ) {
    final sectionItems = sodSection?['items'];
    if (sectionItems is List) {
      final items = sectionItems
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e.isNotEmpty)
          .toList(growable: false);

      if (items.isNotEmpty) return items;
    }

    for (final key in const [
      'sod_cards',
      'sod_actions',
      'sod_sections',
      'sod_menu',
    ]) {
      final raw = inspire[key];
      if (raw is List) {
        final items = raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) => e.isNotEmpty)
            .toList(growable: false);

        if (items.isNotEmpty) return items;
      }
    }

    return const [];
  }

  static int _extractQuoteCount(
    Map<String, dynamic> inspire,
    List<Map<String, dynamic>> sodItems,
  ) {
    final rawQuotes = inspire['sod_quotes'];
    if (rawQuotes is List && rawQuotes.isNotEmpty) return rawQuotes.length;

    final rawSod = inspire['sod'];
    if (rawSod is List && rawSod.isNotEmpty) {
      final quoteLike = rawSod.whereType<Map>().where((item) {
        final text = _firstString(item.cast<String, dynamic>(), const [
          'quote',
          'text',
          'body',
          'content',
          'message',
          'excerpt',
          'subtitle',
        ]);
        return text.trim().isNotEmpty;
      }).length;

      if (quoteLike > 0) return quoteLike;
    }

    return sodItems.length;
  }

  static _SodBannerData _buildBanner(
    Map<String, dynamic> hub,
    Map<String, dynamic> inspire,
    Map<String, dynamic>? sodSection,
    List<Map<String, dynamic>> sodItems,
  ) {
    final home = _asMap(hub['home']);
    final shortcuts = _asMap(home?['shortcuts']);
    final shortcutSod = _asMap(shortcuts?['sod']);

    final candidates = <Map<String, dynamic>?>[
      sodSection,
      _asMap(inspire['sod_banner']),
      _asMap(inspire['banner']),
      _asMap(inspire['hero']),
      shortcutSod,
      if (sodItems.isNotEmpty) sodItems.first,
    ];

    for (final map in candidates) {
      if (map == null || map.isEmpty) continue;

      final title = _firstString(map, const [
        'title',
        'name',
        'label',
        'headline',
      ]);

      final subtitle = _firstString(map, const [
        'subtitle',
        'description',
        'summary',
        'caption',
        'excerpt',
      ]);

      final imageUrl = _pickImage(map) ?? _pickFirstItemImage(sodItems);
      final pillText = _firstString(map, const [
        'pill_text',
        'badge',
        'label',
      ]);

      if (title.isNotEmpty ||
          subtitle.isNotEmpty ||
          (imageUrl ?? '').trim().isNotEmpty) {
        return _SodBannerData(
          title: title,
          subtitle: subtitle,
          imageUrl: imageUrl,
          pillText: pillText,
        );
      }
    }

    return const _SodBannerData(
      title: 'Seed of Destiny',
      subtitle: 'Daily devotion • Watch • Quotes',
      imageUrl: null,
      pillText: 'SEED OF DESTINY',
    );
  }

  static List<_SodCardData> _buildSodCards(
    Map<String, dynamic> hub,
    Map<String, dynamic> inspire,
    Map<String, dynamic>? sodSection,
    List<Map<String, dynamic>> sodItems,
    int quoteCount,
  ) {
    final configured = _extractConfiguredCards(
      hub: hub,
      inspire: inspire,
      sodSection: sodSection,
      sodItems: sodItems,
    );

    if (configured.isNotEmpty) return configured;

    final sectionImage =
        _pickImage(sodSection) ?? _pickFirstItemImage(sodItems);

    final readBackendUrl = _findBackendUrl(
      hub,
      inspire,
      const [
        'sod_read_url',
        'seed_of_destiny_url',
        'read_sod_url',
        'devotional_url',
        'reading_url',
      ],
    );

    final watchBackendUrl = _findBackendUrl(
      hub,
      inspire,
      const [
        'sod_watch_url',
        'watch_sod_url',
        'sod_youtube_url',
        'seed_of_destiny_watch_url',
        'playlist_url',
      ],
    );

    return [
      _SodCardData(
        id: 'sod-read',
        title: 'Read Seed of Destiny',
        subtitle: 'Open today’s devotional reading',
        badgeText: 'Read',
        icon: Icons.menu_book_rounded,
        imageUrl: _findBackendImage(
              hub,
              inspire,
              const ['sod_read_image', 'read_image_url'],
            ) ??
            _imageFromSodItems(sodItems, const ['read']) ??
            sectionImage,
        actionType: 'web',
        routeOrUrl: _normalizeSodReadUrl(
          readBackendUrl.isNotEmpty ? readBackendUrl : _readSodUrl,
        ),
        adKey: 'inspire.sod.read',
      ),
      _SodCardData(
        id: 'sod-watch',
        title: 'Watch Seed of Destiny',
        subtitle: 'Open the available video or playlist',
        badgeText: 'Watch',
        icon: Icons.play_circle_fill_rounded,
        imageUrl: _findBackendImage(
              hub,
              inspire,
              const ['sod_watch_image', 'watch_image_url'],
            ) ??
            _imageFromSodItems(sodItems, const ['watch']) ??
            sectionImage,
        actionType: 'youtube',
        routeOrUrl: _normalizeSodWatchUrl(
          watchBackendUrl.isNotEmpty ? watchBackendUrl : _watchSodUrl,
        ),
        adKey: 'inspire.sod.watch',
      ),
      _SodCardData(
        id: 'sod-quotes',
        title: 'SOD Quotes',
        subtitle: quoteCount > 0
            ? 'Browse quotes and written inspiration'
            : 'Quotes will appear here once published',
        badgeText: quoteCount > 0 ? '$quoteCount' : 'Quote',
        icon: Icons.format_quote_rounded,
        imageUrl: _imageFromSodItems(sodItems, const ['quote']) ?? sectionImage,
        actionType: 'route',
        routeOrUrl: '/sod/quotes',
        adKey: 'inspire.sod.quotes',
      ),
    ];
  }

  static List<_SodCardData> _extractConfiguredCards({
    required Map<String, dynamic> hub,
    required Map<String, dynamic> inspire,
    required Map<String, dynamic>? sodSection,
    required List<Map<String, dynamic>> sodItems,
  }) {
    final candidates = <dynamic>[
      sodItems,
      sodSection?['items'],
      inspire['sod_cards'],
      inspire['sod_actions'],
      inspire['sod_sections'],
      inspire['sod_menu'],
      inspire['actions'],
    ];

    final sectionImage =
        _pickImage(sodSection) ?? _pickFirstItemImage(sodItems);

    for (final raw in candidates) {
      if (raw is! List) continue;

      final out = <_SodCardData>[];

      for (final item in raw) {
        if (item is! Map) continue;
        final map = item.cast<String, dynamic>();

        final id = _firstString(map, const ['id', 'slug', 'key']);
        final title = _firstString(map, const ['title', 'name', 'label']);
        if (title.isEmpty) continue;

        final lowerTitle = title.toLowerCase();

        final subtitle = _firstString(map, const [
          'subtitle',
          'description',
          'summary',
          'caption',
          'excerpt',
        ]);

        final badgeText = _firstString(map, const [
          'badge',
          'badge_text',
          'pill_text',
          'label',
        ]);

        final imageUrl = _pickImage(map) ?? sectionImage;
        final explicitRoute =
            _firstString(map, const ['route', 'path', 'href']);
        final explicitUrl = _firstString(map, const ['url', 'link']);
        final bucket = _firstString(map, const ['bucket', 'source']);

        late String actionType;
        late String routeOrUrl;

        if (lowerTitle.contains('read')) {
          actionType = 'web';
          routeOrUrl = _normalizeSodReadUrl(
            explicitUrl.trim().isNotEmpty ? explicitUrl : _readSodUrl,
          );
        } else if (lowerTitle.contains('watch')) {
          actionType = 'youtube';
          routeOrUrl = _normalizeSodWatchUrl(
            explicitUrl.trim().isNotEmpty ? explicitUrl : _watchSodUrl,
          );
        } else if (lowerTitle.contains('quote') ||
            _normalizeBucket(bucket) == 'sod_quotes' ||
            _normalizeBucket(bucket) == 'quotes') {
          actionType = 'route';
          routeOrUrl = explicitRoute.trim().isNotEmpty
              ? _normalizeInternalRoute(explicitRoute)
              : '/sod/quotes';
        } else {
          final normalizedUrl = _normalizeSodUrl(explicitUrl);
          actionType = _resolveActionType(
            explicitType:
                _firstString(map, const ['type', 'action_type', 'kind']),
            route: explicitRoute,
            url: normalizedUrl,
            bucket: bucket,
          );

          routeOrUrl = _resolveRouteOrUrl(
            actionType: actionType,
            explicitRoute: explicitRoute,
            explicitUrl: normalizedUrl,
            bucket: bucket,
          );
        }

        if (routeOrUrl.isEmpty) continue;

        out.add(
          _SodCardData(
            id: id.isNotEmpty ? id : title.toLowerCase().replaceAll(' ', '-'),
            title: title,
            subtitle: subtitle.isNotEmpty
                ? subtitle
                : _defaultSubtitleForType(actionType),
            badgeText: badgeText.isNotEmpty
                ? badgeText
                : _defaultBadgeForType(actionType),
            icon: _iconForType(actionType, bucket),
            imageUrl: imageUrl,
            actionType: actionType,
            routeOrUrl: routeOrUrl,
            adKey: _adKeyForSodCard(id, title, actionType, routeOrUrl, bucket),
          ),
        );
      }

      if (out.isNotEmpty) {
        final sorted = [...out];
        sorted.sort((a, b) {
          int weight(_SodCardData card) {
            final t = card.title.toLowerCase();
            if (t.contains('read')) return 10;
            if (t.contains('watch')) return 20;
            if (t.contains('quote')) return 30;
            return 100;
          }

          return weight(a).compareTo(weight(b));
        });
        return sorted;
      }
    }

    return const [];
  }

  static String _adKeyForSodCard(
    String id,
    String title,
    String actionType,
    String routeOrUrl,
    String bucket,
  ) {
    final hay =
        '${id.trim()} ${title.trim()} ${actionType.trim()} ${routeOrUrl.trim()} ${bucket.trim()}'
            .toLowerCase();

    if (hay.contains('quote') || hay.contains('/sod/quotes')) {
      return 'inspire.sod.quotes';
    }

    if (hay.contains('watch') ||
        hay.contains('youtube') ||
        hay.contains('youtu.be')) {
      return 'inspire.sod.watch';
    }

    if (hay.contains('read') ||
        hay.contains('devotional') ||
        hay.contains('seed')) {
      return 'inspire.sod.read';
    }

    return 'inspire.sod';
  }

  static Future<void> _handleCardTap(
    BuildContext context,
    _SodCardData card,
  ) async {
    if (!context.mounted) return;

    final actionType = card.actionType.trim().toLowerCase();

    if (actionType == 'route') {
      final route = _normalizeInternalRoute(card.routeOrUrl);

      if (route.trim().isEmpty) {
        _showOpenError(context, 'This SOD section is not ready yet.');
        return;
      }

      context.push(route);
      return;
    }

    if (actionType == 'youtube') {
      final url = _normalizeSodWatchUrl(card.routeOrUrl);

      if (url.trim().isEmpty) {
        _showOpenError(context, 'Watch SOD link is not available yet.');
        return;
      }

      context.push(
        '/player/youtube',
        extra: {
          'title': card.title,
          'url': url,
          'link': url,
          'youtube': url,
          'youtube_url': url,
          'video_url': url,
          'playlist_url': url,
        },
      );
      return;
    }

    final url = _normalizeSodReadUrl(card.routeOrUrl);

    if (url.trim().isEmpty) {
      _showOpenError(context, 'Read SOD link is not available yet.');
      return;
    }

    context.push(
      '/watch/web',
      extra: {
        'title': card.title,
        'url': url,
        'link': url,
        'web_url': url,
      },
    );
  }

  static void _showOpenError(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static String _resolveActionType({
    required String explicitType,
    required String route,
    required String url,
    required String bucket,
  }) {
    final t = explicitType.trim().toLowerCase();

    if (_normalizeBucket(bucket) == 'sod_quotes' ||
        _normalizeBucket(bucket) == 'quotes') {
      return 'route';
    }

    if (_looksLikeYouTube(url)) return 'youtube';
    if (_looksLikeSodReadWeb(url)) return 'web';

    if (t.isNotEmpty) {
      if (t == 'route' || t == 'internal') return 'route';
      if (t == 'youtube' || t == 'playlist' || t == 'youtube_playlist') {
        return 'youtube';
      }
      if (t == 'web' || t == 'external' || t == 'link') return 'web';
    }

    if (route.trim().isNotEmpty) return 'route';
    if (url.trim().isNotEmpty) return 'web';

    return 'route';
  }

  static String _resolveRouteOrUrl({
    required String actionType,
    required String explicitRoute,
    required String explicitUrl,
    required String bucket,
  }) {
    if (actionType == 'route' && explicitRoute.trim().isNotEmpty) {
      return _normalizeInternalRoute(explicitRoute);
    }

    if (actionType == 'route') {
      switch (_normalizeBucket(bucket)) {
        case 'sod_quotes':
        case 'quotes':
          return '/sod/quotes';
      }
    }

    if (explicitUrl.trim().isNotEmpty) return explicitUrl.trim();

    return '';
  }

  static String _normalizeInternalRoute(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return value;

    if (value == '/inspire/sod/quotes' || value == 'inspire/sod/quotes') {
      return '/sod/quotes';
    }

    if (value == '/inspire/sod' || value == 'inspire/sod') {
      return '/sod';
    }

    if (value.startsWith('/')) return value;
    return '/$value';
  }

  static String _normalizeBucket(String value) {
    return value.trim().toLowerCase();
  }

  static String _defaultSubtitleForType(String type) {
    switch (type) {
      case 'youtube':
        return 'Open the available video or playlist';
      case 'route':
        return 'Open this Seed of Destiny section';
      case 'web':
      default:
        return 'Open this Seed of Destiny resource';
    }
  }

  static String _defaultBadgeForType(String type) {
    switch (type) {
      case 'youtube':
        return 'Watch';
      case 'route':
        return 'Open';
      case 'web':
      default:
        return 'Read';
    }
  }

  static IconData _iconForType(String type, String bucket) {
    final normalizedBucket = _normalizeBucket(bucket);

    if (normalizedBucket == 'sod_quotes' || normalizedBucket == 'quotes') {
      return Icons.format_quote_rounded;
    }

    switch (type) {
      case 'youtube':
        return Icons.play_circle_fill_rounded;
      case 'route':
        return Icons.format_quote_rounded;
      case 'web':
      default:
        return Icons.menu_book_rounded;
    }
  }

  static bool _looksLikeYouTube(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty) return false;
    return lower.contains('youtube.com') ||
        lower.contains('youtu.be') ||
        lower.contains('youtube-nocookie.com');
  }

  static bool _looksLikeSodReadWeb(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty) return false;
    return lower.contains('dunamisgospel.org') ||
        lower.contains('seed-of-destiny') ||
        lower.contains('seed') ||
        lower.contains('destiny');
  }

  static String _normalizeSodUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;

    if (_looksLikeYouTube(trimmed)) return _normalizeSodWatchUrl(trimmed);
    return _normalizeSodReadUrl(trimmed);
  }

  static String _normalizeSodReadUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return _readSodUrl;

    final lower = trimmed.toLowerCase();

    if (_looksLikeYouTube(lower)) return _readSodUrl;

    if (lower.contains('seedsofdestinyonline.org')) {
      return Links.readSod.trim().isNotEmpty ? Links.readSod : _readSodUrl;
    }

    if (lower.contains('dunamisgospel.org')) return trimmed;

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    return _readSodUrl;
  }

  static String _normalizeSodWatchUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return _watchSodUrl;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return _watchSodUrl;

    final lower = trimmed.toLowerCase();
    if (!_looksLikeYouTube(lower)) return _watchSodUrl;

    final list = (uri.queryParameters['list'] ?? '').trim();
    final video = (uri.queryParameters['v'] ?? '').trim();

    if (list.isNotEmpty && video.isNotEmpty) {
      return 'https://www.youtube.com/watch?v=$video&list=$list';
    }

    if (list.isNotEmpty) return 'https://www.youtube.com/playlist?list=$list';
    if (video.isNotEmpty) return 'https://www.youtube.com/watch?v=$video';

    return trimmed;
  }

  static String _findBackendUrl(
    Map<String, dynamic> hub,
    Map<String, dynamic> inspire,
    List<String> keys,
  ) {
    for (final key in keys) {
      final direct = inspire[key]?.toString().trim() ?? '';
      if (direct.isNotEmpty) return direct;
    }

    final home = _asMap(hub['home']);
    final shortcuts = _asMap(home?['shortcuts']);
    final sod = _asMap(shortcuts?['sod']);

    for (final key in keys) {
      final fromShortcut = sod?[key]?.toString().trim() ?? '';
      if (fromShortcut.isNotEmpty) return fromShortcut;
    }

    return '';
  }

  static String? _findBackendImage(
    Map<String, dynamic> hub,
    Map<String, dynamic> inspire,
    List<String> keys,
  ) {
    for (final key in keys) {
      final direct = inspire[key]?.toString().trim() ?? '';
      if (direct.isNotEmpty) return direct;
    }

    final home = _asMap(hub['home']);
    final shortcuts = _asMap(home?['shortcuts']);
    final sod = _asMap(shortcuts?['sod']);

    for (final key in keys) {
      final fromShortcut = sod?[key]?.toString().trim() ?? '';
      if (fromShortcut.isNotEmpty) return fromShortcut;
    }

    return null;
  }

  static String? _pickFirstItemImage(List<Map<String, dynamic>> items) {
    for (final item in items) {
      final image = _pickImage(item);
      if ((image ?? '').trim().isNotEmpty) return image;
    }
    return null;
  }

  static String? _imageFromSodItems(
    List<Map<String, dynamic>> items,
    List<String> probes,
  ) {
    for (final item in items) {
      final title = _firstString(item, const ['title', 'name', 'label']);
      final bucket = _firstString(item, const ['bucket', 'key', 'source']);
      final hay = '$title $bucket'.toLowerCase();

      final match = probes.any((probe) => hay.contains(probe.toLowerCase()));
      if (!match) continue;

      final image = _pickImage(item);
      if ((image ?? '').trim().isNotEmpty) return image;
    }

    return null;
  }

  static Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    return null;
  }

  static String _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      final s = value?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }

    final payload = _asMap(map['payload']);
    if (payload != null) {
      for (final key in keys) {
        final value = payload[key];
        final s = value?.toString().trim() ?? '';
        if (s.isNotEmpty) return s;
      }

      final action = _asMap(payload['action']);
      if (action != null) {
        for (final key in keys) {
          final value = action[key];
          final s = value?.toString().trim() ?? '';
          if (s.isNotEmpty) return s;
        }
      }
    }

    final meta = _asMap(map['meta']);
    if (meta != null) {
      for (final key in keys) {
        final value = meta[key];
        final s = value?.toString().trim() ?? '';
        if (s.isNotEmpty) return s;
      }

      final action = _asMap(meta['action']);
      if (action != null) {
        for (final key in keys) {
          final value = action[key];
          final s = value?.toString().trim() ?? '';
          if (s.isNotEmpty) return s;
        }
      }
    }

    return '';
  }

  static String? _pickImage(Map<String, dynamic>? item) {
    if (item == null || item.isEmpty) return null;

    const directKeys = [
      'image_url',
      'card_image_url',
      'background_image_url',
      'cover_image_url',
      'cover_image',
      'cover_url',
      'banner_url',
      'featured_image',
      'thumbnail_url',
      'thumbnail',
      'image',
      'poster',
      'photo',
      'cover_asset_url',
    ];

    for (final key in directKeys) {
      final value = item[key];
      final s = value?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }

    final payload = _asMap(item['payload']);
    if (payload != null) {
      final cover = _asMap(payload['cover']);
      if (cover != null) {
        for (final key in directKeys) {
          final value = cover[key];
          final s = value?.toString().trim() ?? '';
          if (s.isNotEmpty) return s;
        }
      }

      final design = _asMap(payload['design']);
      if (design != null) {
        for (final key in directKeys) {
          final value = design[key];
          final s = value?.toString().trim() ?? '';
          if (s.isNotEmpty) return s;
        }
      }

      for (final key in directKeys) {
        final value = payload[key];
        final s = value?.toString().trim() ?? '';
        if (s.isNotEmpty) return s;
      }
    }

    final media = _asMap(item['media']);
    if (media != null) {
      for (final key in directKeys) {
        final value = media[key];
        final s = value?.toString().trim() ?? '';
        if (s.isNotEmpty) return s;
      }
    }

    final meta = _asMap(item['meta']);
    if (meta != null) {
      final cover = _asMap(meta['cover']);
      if (cover != null) {
        for (final key in directKeys) {
          final value = cover[key];
          final s = value?.toString().trim() ?? '';
          if (s.isNotEmpty) return s;
        }
      }

      for (final key in directKeys) {
        final value = meta[key];
        final s = value?.toString().trim() ?? '';
        if (s.isNotEmpty) return s;
      }
    }

    return null;
  }

  static String _fallbackAssetFor(int index) {
    const assets = [
      'assets/images/home_2.jpg',
      'assets/images/home_4.jpg',
      'assets/images/home_5.jpg',
      'assets/images/home_3.jpg',
      'assets/images/home_1.jpg',
    ];
    return assets[index % assets.length];
  }
}

class _SodBannerData {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String pillText;

  const _SodBannerData({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.pillText,
  });
}

class _SodCardData {
  final String id;
  final String title;
  final String subtitle;
  final String badgeText;
  final IconData icon;
  final String? imageUrl;
  final String actionType;
  final String routeOrUrl;
  final String adKey;

  const _SodCardData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.icon,
    required this.imageUrl,
    required this.actionType,
    required this.routeOrUrl,
    required this.adKey,
  });
}

class _SodTopBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String fallbackAsset;
  final String pillText;
  final _SodColors colors;

  const _SodTopBanner({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.pillText,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            Positioned.fill(
              child: _BannerImage(
                imageUrl: imageUrl,
                fallbackAsset: fallbackAsset,
                colors: colors,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: colors.heroOverlay,
                    stops: const [0.0, 0.42, 1.0],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.heroBorder),
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
                  _BannerPill(text: pillText, colors: colors),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onImagePrimary,
                      fontSize: 22,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onImageSecondary,
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SodActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final IconData icon;
  final String? imageUrl;
  final String fallbackAsset;
  final VoidCallback onTap;
  final _SodColors colors;

  const _SodActionCard({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.icon,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 176,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
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
            child: Stack(
              children: [
                Positioned.fill(
                  child: _BannerImage(
                    imageUrl: imageUrl,
                    fallbackAsset: fallbackAsset,
                    colors: colors,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomCenter,
                        colors: colors.cardOverlay,
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: colors.cardBorder),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: colors.iconChipBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.iconChipBorder),
                        ),
                        child: Icon(
                          icon,
                          color: colors.onImagePrimary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _BannerPill(text: badgeText, colors: colors),
                            const SizedBox(height: 12),
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.onImagePrimary,
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
                                color: colors.onImageSecondary,
                                fontSize: 12.8,
                                height: 1.22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colors.chevron,
                        size: 28,
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

class _BannerImage extends StatelessWidget {
  final String? imageUrl;
  final String fallbackAsset;
  final _SodColors colors;

  const _BannerImage({
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
          errorBuilder: (_, __, ___) => Container(
            color: colors.imageFallback,
          ),
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
      errorBuilder: (_, __, ___) => Container(
        color: colors.imageFallback,
      ),
    );
  }
}

class _BannerPill extends StatelessWidget {
  final String text;
  final _SodColors colors;

  const _BannerPill({
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
          color: colors.onImagePrimary,
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
  final _SodColors colors;

  const _EmptyCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.panelBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.panelBorder),
        boxShadow: colors.panelShadow,
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
            child: Icon(icon, color: colors.onAccent, size: 22),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.panelSubtitle,
                    fontSize: 12.8,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
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

class _SodColors {
  final Color scaffold;
  final Color panelBg;
  final Color panelBorder;
  final List<BoxShadow>? panelShadow;
  final Color panelTitle;
  final Color panelSubtitle;
  final Color metaText;
  final Color onAccent;
  final Color onImagePrimary;
  final Color onImageSecondary;
  final Color chevron;
  final Color heroBorder;
  final Color cardBorder;
  final Color iconChipBg;
  final Color iconChipBorder;
  final Color pillBg;
  final Color pillBorder;
  final Color imageLoading;
  final Color imageFallback;
  final Color shadow;
  final List<Color> heroOverlay;
  final List<Color> cardOverlay;

  const _SodColors({
    required this.scaffold,
    required this.panelBg,
    required this.panelBorder,
    required this.panelShadow,
    required this.panelTitle,
    required this.panelSubtitle,
    required this.metaText,
    required this.onAccent,
    required this.onImagePrimary,
    required this.onImageSecondary,
    required this.chevron,
    required this.heroBorder,
    required this.cardBorder,
    required this.iconChipBg,
    required this.iconChipBorder,
    required this.pillBg,
    required this.pillBorder,
    required this.imageLoading,
    required this.imageFallback,
    required this.shadow,
    required this.heroOverlay,
    required this.cardOverlay,
  });

  factory _SodColors.fromBrightness(bool isLight) {
    if (isLight) {
      return _SodColors(
        scaffold: const Color(0xFFF6F7FB),
        panelBg: Colors.white.withOpacity(0.94),
        panelBorder: const Color(0xFFE6E8F0),
        panelShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        panelTitle: const Color(0xFF1E1B16),
        panelSubtitle: const Color(0xFF5E6472),
        metaText: const Color(0xFF6B7280),
        onAccent: Colors.white,
        onImagePrimary: Colors.white,
        onImageSecondary: Colors.white.withOpacity(0.90),
        chevron: Colors.white.withOpacity(0.85),
        heroBorder: Colors.white.withOpacity(0.10),
        cardBorder: Colors.white.withOpacity(0.10),
        iconChipBg: Colors.black.withOpacity(0.24),
        iconChipBorder: Colors.white.withOpacity(0.14),
        pillBg: Colors.black.withOpacity(0.28),
        pillBorder: Colors.white.withOpacity(0.16),
        imageLoading: const Color(0xFFE9ECF5),
        imageFallback: const Color(0xFFD9DEEA),
        shadow: Colors.black.withOpacity(0.08),
        heroOverlay: [
          Colors.black.withOpacity(0.10),
          Colors.black.withOpacity(0.22),
          Colors.black.withOpacity(0.70),
        ],
        cardOverlay: [
          Colors.black.withOpacity(0.10),
          Colors.black.withOpacity(0.22),
          Colors.black.withOpacity(0.74),
        ],
      );
    }

    return _SodColors(
      scaffold: const Color(0xFF0B1020),
      panelBg: const Color(0xFF0D1228),
      panelBorder: Colors.white.withOpacity(0.08),
      panelShadow: null,
      panelTitle: Colors.white,
      panelSubtitle: Colors.white.withOpacity(0.78),
      metaText: Colors.white.withOpacity(0.55),
      onAccent: Colors.white,
      onImagePrimary: Colors.white,
      onImageSecondary: Colors.white.withOpacity(0.88),
      chevron: Colors.white.withOpacity(0.78),
      heroBorder: Colors.white.withOpacity(0.08),
      cardBorder: Colors.white.withOpacity(0.08),
      iconChipBg: Colors.black.withOpacity(0.28),
      iconChipBorder: Colors.white.withOpacity(0.12),
      pillBg: Colors.black.withOpacity(0.34),
      pillBorder: Colors.white.withOpacity(0.14),
      imageLoading: const Color(0xFF151528),
      imageFallback: const Color(0xFF1B1B2A),
      shadow: Colors.black.withOpacity(0.22),
      heroOverlay: [
        Colors.black.withOpacity(0.12),
        Colors.black.withOpacity(0.28),
        Colors.black.withOpacity(0.88),
      ],
      cardOverlay: [
        Colors.black.withOpacity(0.14),
        Colors.black.withOpacity(0.28),
        Colors.black.withOpacity(0.82),
      ],
    );
  }
}
