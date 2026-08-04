import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app_config.dart';
import '../../../services/ads_service.dart';
import '../data/hub_service.dart';

class HubStore extends ChangeNotifier {
  static const _cacheKey = 'dxm.hub.bootstrap.cache.v2';

  final http.Client _httpClient;
  late final HubService _service;

  Map<String, dynamic> _data = const {};
  bool _loading = false;
  bool _backgroundRefreshing = false;
  String? _error;
  DateTime? _lastUpdated;

  HubStore() : _httpClient = http.Client() {
    _service = HubService(
      bootstrapUrl: AppConfig.hubBootstrapUrl,
      timeout: const Duration(seconds: 15),
      client: _httpClient,
    );
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  bool get loading => _loading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;

  Map<String, dynamic> get raw => _data;

  Map<String, dynamic> get capabilities =>
      _asMap(_data['capabilities']) ??
      _asMap(_valueAt(['branding', 'capabilities'])) ??
      _asMap(_valueAt(['branding', 'raw', 'capabilities'])) ??
      const <String, dynamic>{};

  Map<String, dynamic> get featureFlags =>
      _asMap(_data['feature_flags']) ?? const <String, dynamic>{};

  bool capabilityEnabled(
    String key, {
    bool fallback = true,
    List<String> aliases = const [],
  }) {
    final keys = <String>{
      key.trim(),
      ...aliases.map((item) => item.trim()),
    }.where((item) => item.isNotEmpty).toList(growable: false);

    for (final candidate in keys) {
      final value = capabilities[candidate] ?? featureFlags[candidate];
      final resolved = _boolFromDynamic(value);
      if (resolved != null) return resolved;
    }

    return fallback;
  }

  String? get brandingBannerUrl =>
      _stringAt(['branding', 'assets', 'banner_url']) ??
      _stringAt(['branding', 'banner_url']) ??
      _stringAt(['branding', 'raw', 'banner_url']);
  String? get brandingSplashUrl =>
      _stringAt(['branding', 'assets', 'splash_url']) ??
      _stringAt(['branding', 'splash_url']) ??
      _stringAt(['branding', 'raw', 'splash_url']) ??
      _stringAt(['branding', 'raw', 'splash_path']);

  String? get watchLiveHlsUrl => _stringAt(['watch', 'live_hls', 'url']);
  String get watchLiveHlsTitle =>
      _stringAt(['watch', 'live_hls', 'title']) ?? AppConfig.liveTitle;
  String? get watchLiveHlsImageUrl =>
      _stringAt(['watch', 'live_hls', 'image_url']) ??
      _stringAt(['watch', 'live_youtube', 'image_url']) ??
      brandingBannerUrl;

  String? get watchLiveYoutubeUrl =>
      _stringAt(['watch', 'live_youtube', 'url']);
  String get watchLiveYoutubeTitle =>
      _stringAt(['watch', 'live_youtube', 'title']) ?? 'Live Services';
  String? get watchLiveYoutubeImageUrl =>
      _stringAt(['watch', 'live_youtube', 'image_url']) ?? brandingBannerUrl;

  String? get watchCommandingDayUrl =>
      _stringAt(['watch', 'commanding_day', 'url']);
  String get watchCommandingDayTitle =>
      _stringAt(['watch', 'commanding_day', 'title']) ??
      AppConfig.commandingDayTitle;
  String? get watchCommandingDayImageUrl =>
      _stringAt(['watch', 'commanding_day', 'image_url']) ?? brandingBannerUrl;

  String? get homePrayerYoutubeUrl =>
      _stringAt(['home', 'prayer_broadcast', 'url']);

  String get homePrayerTitle =>
      _stringAt(['home', 'prayer_broadcast', 'title']) ??
      AppConfig.commandingDayTitle;

  String? get homePrayerImageUrl =>
      _stringAt(['home', 'prayer_broadcast', 'image_url']) ?? brandingBannerUrl;

  Map<String, String>? get watchLiveHlsCard =>
      _watchCardAt(['watch', 'live_hls'], fallbackType: 'hls');

  Map<String, String>? get watchLiveYoutubeCard =>
      _watchCardAt(['watch', 'live_youtube'], fallbackType: 'youtube');

  Map<String, String>? get watchCommandingDayCard =>
      _watchCardAt(['watch', 'commanding_day'], fallbackType: 'commanding_day');

  List<Map<String, String>> get watchOtherChannels {
    final v = _valueAt(['watch', 'other_channels']);
    return _normalizeCardList(v, fallbackType: 'web');
  }

  List<Map<String, String>> get watchVideos {
    final v = _valueAt(['watch', 'videos']);
    return _normalizeCardList(v, fallbackType: 'youtube');
  }

  List<Map<String, String>> get watchVideoCards => watchVideos;

  List<Map<String, dynamic>> get watchGroupCards {
    final v = _valueAt(['watch', 'groups']);
    if (v is! Map) return const [];

    const excluded = {
      'live_hls',
      'live_youtube',
      'commanding_day',
      'video',
      'videos',
    };

    final out = <Map<String, dynamic>>[];

    v.forEach((key, value) {
      final groupKey = key.toString().trim();
      if (groupKey.isEmpty || excluded.contains(groupKey)) {
        return;
      }

      final items = _normalizeCardList(value, fallbackType: 'web');
      if (items.isEmpty) return;

      out.add({
        'key': groupKey,
        'title': _humanizeGroupKey(groupKey),
        'subtitle': 'Open available channels and programs',
        'badge': groupKey == 'other_channels'
            ? 'CHANNELS'
            : _humanizeGroupKey(groupKey).toUpperCase(),
        'image_url': _firstImageFromMaps(items),
        'items': items,
      });
    });

    return out;
  }

  List<Map<String, dynamic>> get watchSectionsRaw {
    final sections = _valueAt(['watch', 'sections_raw']);

    if (sections is List) {
      return sections
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    }

    final raw = _valueAt(['watch', 'raw']);
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    }

    final rootSections = _valueAt(['sections']);
    if (rootSections is List) {
      return rootSections
          .whereType<Map>()
          .where((section) {
            final tab = (section['tab_key'] ??
                    section['route_key'] ??
                    section['tab'] ??
                    '')
                .toString()
                .trim()
                .toLowerCase();
            return tab == 'watch';
          })
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    }

    return const <Map<String, dynamic>>[];
  }

  List<Map<String, String>> get homeHeroSlides {
    final v = _valueAt(['home', 'hero', 'slides']);
    if (v is List) {
      return v
          .whereType<Map>()
          .map((e) => {
                'title': (e['title'] ?? '').toString(),
                'subtitle': (e['subtitle'] ?? '').toString(),
                'image_url': (e['image_url'] ?? '').toString(),
              })
          .where((e) => (e['image_url'] ?? '').trim().isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  Map<String, String> get homeLiveCard => _mapStringAt(
        ['home', 'shortcuts', 'live'],
        fallback: {
          'title': AppConfig.liveTitle,
          'subtitle': 'Watch live broadcast and streaming content',
          'image_url': '',
        },
      );

  Map<String, String> get homeSodCard => _mapStringAt(
        ['home', 'shortcuts', 'sod'],
        fallback: {
          'title': AppConfig.homeSodTitle,
          'subtitle': 'Read today’s devotional and key spiritual insights',
          'image_url': '',
        },
      );

  Map<String, String> get homeArticlesCard => _mapStringAt(
        ['home', 'shortcuts', 'articles'],
        fallback: {
          'title': AppConfig.homeArticlesTitle,
          'subtitle': 'Read featured articles and ministry updates',
          'image_url': '',
        },
      );

  Map<String, String> get homeHighlightsCard => _mapStringAt(
        ['home', 'shortcuts', 'highlights'],
        fallback: {
          'title': AppConfig.homeHighlightsTitle,
          'subtitle': 'Catch short message summaries and spiritual takeaways',
          'image_url': '',
        },
      );

  Map<String, String> get homeDailyScripture => _mapStringAt(
        ['home', 'daily_scripture'],
        fallback: const {
          'ref': '',
          'verse': '',
          'note': '',
          'image_url': '',
        },
      );

  bool get hasHomeDailyScripture {
    final item = homeDailyScripture;
    return (item['ref'] ?? '').trim().isNotEmpty ||
        (item['verse'] ?? '').trim().isNotEmpty ||
        (item['note'] ?? '').trim().isNotEmpty;
  }

  List<Map<String, String>> get homeDailyScriptureCards {
    final items = _mapStringListAt(['home', 'daily_scriptures']);
    if (items.isNotEmpty) return items;

    final active = homeDailyScripture;
    return hasHomeDailyScripture ? [active] : const <Map<String, String>>[];
  }

  Map<String, String> get homeDailyQuote => _mapStringAt(
        ['home', 'daily_quote'],
        fallback: const {
          'quote': '',
          'source': '',
          'image_url': '',
        },
      );

  bool get hasHomeDailyQuote {
    final item = homeDailyQuote;
    return (item['quote'] ?? '').trim().isNotEmpty;
  }

  List<Map<String, String>> get homeDailyQuoteCards {
    final items = _mapStringListAt(['home', 'daily_quotes']);
    if (items.isNotEmpty) return items;

    final active = homeDailyQuote;
    return hasHomeDailyQuote ? [active] : const <Map<String, String>>[];
  }

  List<Map<String, String>> get exploreTools {
    final v = _valueAt(['explore', 'tools']);
    if (v is List) {
      return v
          .whereType<Map>()
          .map((e) => {
                'title': (e['title'] ?? '').toString(),
                'subtitle': (e['subtitle'] ?? '').toString(),
                'icon': (e['icon'] ?? '').toString(),
                'route': (e['route'] ?? '').toString(),
                'url': (e['url'] ?? '').toString(),
                'image_url': (e['image_url'] ?? '').toString(),
              })
          .toList(growable: false);
    }
    return const [];
  }

  Future<void> init() async {
    await AdsService.instance.init();
    await _loadCache();

    final cachedBootstrap = _extractBootstrap(_data);
    if (cachedBootstrap.isNotEmpty) {
      AdsService.instance.applyBootstrap(cachedBootstrap);
    }

    Future.microtask(refresh);
  }

  Future<void> refresh() async {
    if (_loading) return;

    _loading = true;
    _error = null;
    notifyListeners();

    final previousData = _data;
    final previousBootstrap = _extractBootstrap(previousData);

    try {
      if (kDebugMode) {
        print('[HubStore] priority refresh started');
      }

      // Home is the only network payload allowed during the priority phase.
      // Bootstrap, push registration and secondary tabs are deliberately kept
      // out of this path so a large Home response has the full connection.
      final latestBootstrap = previousBootstrap;
      final latestHomeHubPayload = await _fetchHubPayload(tab: 'home');

      final normalized = _normalizeBootstrap(
        bootstrap:
            latestBootstrap.isNotEmpty ? latestBootstrap : previousBootstrap,
        motivation: _previousInspireItems(previousData, 'motivation'),
        wordification: _previousInspireItems(previousData, 'wordification'),
        highlights: _previousInspireItems(previousData, 'highlights'),
        articles: _previousInspireItems(previousData, 'inside_dunamis'),
        sod: _previousInspireItems(previousData, 'sod_quotes'),
        dailyQuotes: _previousHomeItems(previousData, 'daily_quotes'),
        dailyScriptures: _previousHomeItems(previousData, 'daily_scriptures'),
        homeHubPayload: latestHomeHubPayload.isNotEmpty
            ? latestHomeHubPayload
            : _normalizedTabPayload(previousData, 'home'),
        hubPayload: _normalizedTabPayload(previousData, 'inspire'),
        watchHubPayload: _normalizedTabPayload(previousData, 'watch'),
        exploreHubPayload: _normalizedTabPayload(previousData, 'explore'),
      );

      if (normalized.isNotEmpty) {
        _data = normalized;
        _lastUpdated = DateTime.now();

        if (latestBootstrap.isNotEmpty) {
          AdsService.instance.applyBootstrap(latestBootstrap);
        }

        await _saveCache(normalized);
        notifyListeners();
      }

      if (kDebugMode) {
        print('[HubStore] priority refresh completed');
      }

      unawaited(_refreshSecondaryPayloads());
    } catch (e) {
      _error = e.toString();

      if (previousData.isNotEmpty) {
        _data = previousData;
        _lastUpdated ??= DateTime.now();

        final cachedBootstrap = _extractBootstrap(previousData);
        if (cachedBootstrap.isNotEmpty) {
          AdsService.instance.applyBootstrap(cachedBootstrap);
        }
      }

      if (kDebugMode) {
        print('[HubStore] priority refresh failed; cache preserved: $e');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshSecondaryPayloads() async {
    if (_backgroundRefreshing) return;
    _backgroundRefreshing = true;

    try {
      if (kDebugMode) {
        print('[HubStore] secondary refresh started');
      }

      // Refresh bootstrap only after Home has completed, then run all
      // remaining requests sequentially to protect slower devices/connections.
      final refreshedBootstrap = await _fetchBootstrapPayload(
        fallback: _extractBootstrap(_data),
      );
      final inspireHub = await _fetchHubPayload(tab: 'inspire');
      final watchHub = await _fetchHubPayload(tab: 'watch');
      final exploreHub = await _fetchHubPayload(tab: 'explore');

      final motivation = await _fetchFirstAvailableContentBucket(
        const ['motivation'],
      );
      final wordification = await _fetchFirstAvailableContentBucket(
        const ['wordification'],
      );
      final highlights = await _fetchFirstAvailableContentBucket(
        const ['highlights', 'highlight'],
      );
      final sod = await _fetchFirstAvailableContentBucket(
        const ['sod_quotes', 'sod'],
      );
      final articles = await _fetchFirstAvailableContentBucket(
        const ['inside_dunamis', 'articles'],
      );
      final dailyQuotes = await _fetchFirstAvailableContentBucket(
        const ['daily_quotes'],
      );
      final dailyScriptures = await _fetchFirstAvailableContentBucket(
        const ['daily_scriptures'],
      );

      final snapshot = _data;
      final bootstrap = refreshedBootstrap.isNotEmpty
          ? refreshedBootstrap
          : _extractBootstrap(snapshot);

      final normalized = _normalizeBootstrap(
        bootstrap: bootstrap,
        motivation: motivation.isNotEmpty
            ? motivation
            : _previousInspireItems(snapshot, 'motivation'),
        wordification: wordification.isNotEmpty
            ? wordification
            : _previousInspireItems(snapshot, 'wordification'),
        highlights: highlights.isNotEmpty
            ? highlights
            : _previousInspireItems(snapshot, 'highlights'),
        articles: articles.isNotEmpty
            ? articles
            : _previousInspireItems(snapshot, 'inside_dunamis'),
        sod: sod.isNotEmpty
            ? sod
            : _previousInspireItems(snapshot, 'sod_quotes'),
        dailyQuotes: dailyQuotes.isNotEmpty
            ? dailyQuotes
            : _previousHomeItems(snapshot, 'daily_quotes'),
        dailyScriptures: dailyScriptures.isNotEmpty
            ? dailyScriptures
            : _previousHomeItems(snapshot, 'daily_scriptures'),
        homeHubPayload: _normalizedTabPayload(snapshot, 'home'),
        hubPayload: inspireHub.isNotEmpty
            ? inspireHub
            : _normalizedTabPayload(snapshot, 'inspire'),
        watchHubPayload: watchHub.isNotEmpty
            ? watchHub
            : _normalizedTabPayload(snapshot, 'watch'),
        exploreHubPayload: exploreHub.isNotEmpty
            ? exploreHub
            : _normalizedTabPayload(snapshot, 'explore'),
      );

      if (normalized.isNotEmpty) {
        applyRefreshedAdPolicy(bootstrap);
        _data = normalized;
        _lastUpdated = DateTime.now();
        await _saveCache(normalized);
        notifyListeners();
      }

      if (kDebugMode) {
        print('[HubStore] secondary refresh completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            '[HubStore] secondary refresh failed; current data preserved: $e');
      }
    } finally {
      _backgroundRefreshing = false;
    }
  }

  @visibleForTesting
  void applyRefreshedAdPolicy(Map<String, dynamic> bootstrap) {
    AdsService.instance.applyBootstrap(bootstrap);
  }

  List<Map<String, dynamic>> _previousInspireItems(
    Map<String, dynamic> snapshot,
    String key,
  ) {
    final inspire = _asMap(snapshot['inspire']);
    final value = inspire?[key];
    if (value is! List) return const <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _previousHomeItems(
    Map<String, dynamic> snapshot,
    String key,
  ) {
    final home = _asMap(snapshot['home']);
    final value = home?[key];
    if (value is! List) return const <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Map<String, dynamic> _normalizedTabPayload(
    Map<String, dynamic> snapshot,
    String tab,
  ) {
    final value = _asMap(snapshot[tab]);
    if (value == null || value.isEmpty) return const <String, dynamic>{};

    return <String, dynamic>{
      tab:
          value['sections'] ?? value['cards'] ?? value['hub_cards'] ?? const [],
      'sections': value['sections'] ?? value['cards'] ?? const [],
      if (tab == 'home') ...{
        'daily_scripture': value['daily_scripture'],
        'daily_quote': value['daily_quote'],
      },
    };
  }

  Future<Map<String, dynamic>> _fetchBootstrapPayload({
    required Map<String, dynamic> fallback,
  }) async {
    const maxAttempts = 1;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final decoded = await _service
            .fetchBootstrapJson()
            .timeout(const Duration(seconds: 45));

        final map = Map<String, dynamic>.from(decoded);
        if (map.isNotEmpty) return map;
      } catch (e) {
        if (kDebugMode) {
          print(
              '[HubStore] bootstrap attempt $attempt/$maxAttempts failed: $e');
        }

        if (attempt < maxAttempts) {
          await Future<void>.delayed(Duration(milliseconds: 700 * attempt));
        }
      }
    }

    if (fallback.isNotEmpty) {
      return fallback;
    }

    return const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _fetchHubPayload({required String tab}) async {
    final uri = Uri.parse(_hubUrlForTab(tab));
    const maxAttempts = 1;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        if (kDebugMode) {
          print('[HubStore] hub call attempt $attempt/$maxAttempts: $uri');
        }

        final res = await _httpClient.get(
          uri,
          headers: {
            'Accept': 'application/json',
            'X-APP-TOKEN': AppConfig.appToken,
            'Cache-Control': 'no-cache',
          },
        ).timeout(const Duration(seconds: 45));

        if (kDebugMode) {
          print('[HubStore] hub response: ${res.statusCode}');
        }

        if (res.statusCode < 200 || res.statusCode >= 300) {
          if (kDebugMode) {
            print('[HubStore] hub fetch failed: ${res.statusCode} ${res.body}');
          }
          if (attempt < maxAttempts) {
            await Future<void>.delayed(Duration(milliseconds: 700 * attempt));
          }
          continue;
        }

        final decoded = await compute(_dxmDecodeJsonObject, res.body);
        if (decoded.isNotEmpty) return decoded;
      } catch (e) {
        if (kDebugMode) {
          print('[HubStore] hub attempt $attempt/$maxAttempts failed: $e');
        }

        if (attempt < maxAttempts) {
          await Future<void>.delayed(Duration(milliseconds: 700 * attempt));
        }
      }
    }

    return const <String, dynamic>{};
  }

  String _hubUrlForTab(String tab) {
    final raw = AppConfig.hubBootstrapUrl.trim();
    if (raw.isEmpty) return raw;

    var url = raw;
    if (url.contains('/bootstrap')) {
      url = url.replaceFirst('/bootstrap', '/hub');
    } else if (!url.endsWith('/hub')) {
      url = url.replaceAll(RegExp(r'/+$'), '');
      url = '$url/hub';
    }

    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}tab=$tab';
  }

  Future<List<Map<String, dynamic>>> _fetchFirstAvailableContentBucket(
    List<String> buckets,
  ) async {
    for (final bucket in buckets) {
      final items = await _fetchContentBucket(bucket);
      if (items.isNotEmpty) return items;
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> _fetchContentBucket(String bucket) async {
    final uri = Uri.parse(
      AppConfig.contentListUrl(
        tab: 'inspire',
        bucket: bucket,
        page: 1,
        perPage: 20,
      ),
    );

    const maxAttempts = 1;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        if (kDebugMode) {
          print(
              '[HubStore] content call attempt $attempt/$maxAttempts: $bucket => $uri');
        }

        final res = await _httpClient.get(
          uri,
          headers: {
            'Accept': 'application/json',
            'X-APP-TOKEN': AppConfig.appToken,
            'Cache-Control': 'no-cache',
          },
        ).timeout(const Duration(seconds: 45));

        if (kDebugMode) {
          print('[HubStore] content response [$bucket]: ${res.statusCode}');
        }

        if (res.statusCode < 200 || res.statusCode >= 300) {
          if (attempt < maxAttempts) {
            await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
          }
          continue;
        }

        final decoded = await compute(_dxmDecodeJsonObject, res.body);
        final items = decoded['items'] ?? decoded['data'];
        if (items is! List) return const <Map<String, dynamic>>[];

        return items
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(growable: false);
      } catch (e) {
        if (kDebugMode) {
          print(
              '[HubStore] content attempt $attempt/$maxAttempts failed [$bucket]: $e');
        }

        if (attempt < maxAttempts) {
          await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }

    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _normalizeBootstrap({
    required Map<String, dynamic> bootstrap,
    required List<Map<String, dynamic>> motivation,
    required List<Map<String, dynamic>> wordification,
    required List<Map<String, dynamic>> highlights,
    required List<Map<String, dynamic>> articles,
    required List<Map<String, dynamic>> sod,
    required List<Map<String, dynamic>> dailyQuotes,
    required List<Map<String, dynamic>> dailyScriptures,
    required Map<String, dynamic> homeHubPayload,
    required Map<String, dynamic> hubPayload,
    required Map<String, dynamic> watchHubPayload,
    required Map<String, dynamic> exploreHubPayload,
  }) {
    final branding = _asMap(bootstrap['branding']) ?? const <String, dynamic>{};
    final brandingRaw = _asMap(branding['raw']) ?? const <String, dynamic>{};
    final assets = _mergeNonEmptyMaps([
      _asMap(branding['assets']),
      {
        'logo_url': brandingRaw['logo_url'] ?? branding['logo_url'],
        'banner_url': brandingRaw['banner_url'] ?? branding['banner_url'],
        'splash_url': brandingRaw['splash_url'] ?? branding['splash_url'],
        'app_icon_url': brandingRaw['app_icon_url'] ?? branding['app_icon_url'],
      },
    ]);
    final profile = _mergeNonEmptyMaps([
      _asMap(branding['profile']),
      {
        'display_name': brandingRaw['display_name'] ??
            brandingRaw['name'] ??
            branding['display_name'],
        'tagline': brandingRaw['tagline'] ?? branding['tagline'],
        'about': brandingRaw['about'] ?? branding['about'],
        'primary_color':
            brandingRaw['primary_color'] ?? branding['primary_color'],
        'accent_color': brandingRaw['accent_color'] ?? branding['accent_color'],
        'background_color':
            brandingRaw['background_color'] ?? branding['background_color'],
        'text_color': brandingRaw['text_color'] ?? branding['text_color'],
        'theme_mode': brandingRaw['theme_mode'] ?? branding['theme_mode'],
      },
    ]);
    final normalizedBranding = {
      ...branding,
      'raw': brandingRaw,
      'assets': assets,
      'profile': profile,
      'capabilities': _extractCapabilities(bootstrap, branding, brandingRaw),
    };
    final capabilities = _extractCapabilities(bootstrap, branding, brandingRaw);
    final featureFlags = {
      ...(_asMap(brandingRaw['flags']) ?? const <String, dynamic>{}),
      ...(_asMap(bootstrap['feature_flags']) ?? const <String, dynamic>{}),
      ..._legacyFlagsFromCapabilities(capabilities),
      ...capabilities,
    };
    final links = _asMap(bootstrap['links']) ?? const <String, dynamic>{};
    final watch = _asMap(bootstrap['watch']) ?? const <String, dynamic>{};
    final home = _asMap(bootstrap['home']) ?? const <String, dynamic>{};

    final bannerUrl = (assets['banner_url'] ?? '').toString().trim();
    final appName =
        (profile['display_name'] ?? AppConfig.appName).toString().trim();
    final tagline = (profile['tagline'] ?? 'Watch, learn and get inspired')
        .toString()
        .trim();

    final normalizedWatch = _normalizeWatchPayload(
      watch: watch,
      bannerUrl: bannerUrl,
    );

    final backendWatchSections = _normalizeWatchHubSections(
      watchHubPayload,
      bannerUrl: bannerUrl,
    );

    final hubHomeSections = _normalizeHubSections(
      homeHubPayload['home'] ??
          homeHubPayload['sections'] ??
          homeHubPayload['items'],
    );

    final hubExploreSections = _normalizeHubSections(
      exploreHubPayload['explore'] ??
          exploreHubPayload['sections'] ??
          exploreHubPayload['items'],
    );

    final backendHeroSlides =
        _normalizeHomeHeroSlides(home['hero'], appName, tagline, bannerUrl);
    final backendShortcuts =
        _normalizeHomeShortcuts(home['shortcuts'], bannerUrl);
    final normalizedPrayerBroadcast = _normalizeHomePrayerBroadcast(
        _asMap(home['prayer_broadcast']), bannerUrl);

    final hubDailyScripture = _extractHomeDailyItem(
      homeHubPayload,
      dailyKind: 'daily_scripture',
    );
    final hubDailyQuote = _extractHomeDailyItem(
      homeHubPayload,
      dailyKind: 'daily_quote',
    );

    final normalizedDailyScripture = _normalizeDailyScripture(
      hubDailyScripture ?? _asMap(home['daily_scripture']),
    );
    final normalizedDailyQuote = _normalizeDailyQuote(
      hubDailyQuote ?? _asMap(home['daily_quote']),
    );

    final normalizedDailyScriptureItems = _dailyListWithActive(
      active: normalizedDailyScripture,
      libraryItems: dailyScriptures,
      kind: 'daily_scripture',
    );
    final normalizedDailyQuoteItems = _dailyListWithActive(
      active: normalizedDailyQuote,
      libraryItems: dailyQuotes,
      kind: 'daily_quote',
    );

    final exploreTools = _extractExploreTools(bootstrap);

    final inspireSection =
        _asMap(bootstrap['inspire']) ?? const <String, dynamic>{};
    final hubInspireRaw = hubPayload['inspire'] ??
        _asMap(hubPayload['sections_by_tab'])?['inspire'] ??
        hubPayload['sections'] ??
        hubPayload['items'];

    var hubInspireSections = _normalizeHubSections(hubInspireRaw);

    hubInspireSections = _expandQuoteChannelSections(
      hubInspireSections,
      quoteItems: _collectDynamicQuoteItems(
        payloads: [hubPayload, homeHubPayload, exploreHubPayload, bootstrap],
        libraryItems: dailyQuotes,
      ),
    );

    final allHubSections = <Map<String, dynamic>>[];
    final seenHubSectionKeys = <String>{};
    void addHubSections(List<Map<String, dynamic>> sections) {
      for (final section in sections) {
        final key = (section['key'] ??
                section['section_key'] ??
                section['route_key'] ??
                section['title'] ??
                '')
            .toString()
            .trim()
            .toLowerCase();
        final tab = (section['tab_key'] ??
                section['placement'] ??
                section['route_key'] ??
                '')
            .toString()
            .trim()
            .toLowerCase();
        final signature = '$tab|$key';
        if (signature.trim() != '|' && seenHubSectionKeys.contains(signature)) {
          continue;
        }
        if (signature.trim() != '|') seenHubSectionKeys.add(signature);
        allHubSections.add(section);
      }
    }

    addHubSections(hubHomeSections);
    addHubSections(hubInspireSections);
    addHubSections(backendWatchSections);
    addHubSections(hubExploreSections);

    return {
      'bootstrap': bootstrap,
      'branding': normalizedBranding,
      'tabs': bootstrap['tabs'] ?? const [],
      'routes': bootstrap['routes'] ?? const [],
      'links': links,
      'app': bootstrap['app'] ?? const {},
      'capabilities': capabilities,
      'feature_flags': featureFlags,
      'ads': bootstrap['ads'] ?? const {},
      'ad_policy': bootstrap['ad_policy'] ?? const {},
      'ad_formats': bootstrap['ad_formats'] ?? const {},
      'native_in_list': bootstrap['native_in_list'] ?? const {},
      if (allHubSections.isNotEmpty) 'sections': allHubSections,
      'home': {
        if (hubHomeSections.isNotEmpty) 'sections': hubHomeSections,
        if (hubHomeSections.isNotEmpty) 'cards': hubHomeSections,
        if (hubHomeSections.isNotEmpty) 'hub_cards': hubHomeSections,
        'hero': {
          'slides': backendHeroSlides,
        },
        'shortcuts': backendShortcuts,
        'prayer_broadcast': normalizedPrayerBroadcast,
        'daily_scripture': normalizedDailyScripture,
        'daily_quote': normalizedDailyQuote,
        'daily_scriptures': normalizedDailyScriptureItems,
        'daily_quotes': normalizedDailyQuoteItems,
      },
      'watch': {
        ...normalizedWatch,
        if (backendWatchSections.isNotEmpty)
          'sections_raw': backendWatchSections,
      },
      'inspire': {
        ...inspireSection,
        if (hubInspireSections.isNotEmpty) 'sections': hubInspireSections,
        if (hubInspireSections.isNotEmpty) 'cards': hubInspireSections,
        if (hubInspireSections.isNotEmpty) 'hub_cards': hubInspireSections,
        'articles': articles,
        'inside_dunamis': articles,
        'highlights': highlights,
        'highlight': highlights,
        'wordification': wordification,
        'motivation': motivation,
        'sod': sod,
        'sod_quotes': sod,
      },
      'explore': {
        'tools': exploreTools,
        if (hubExploreSections.isNotEmpty) 'sections': hubExploreSections,
        if (hubExploreSections.isNotEmpty) 'cards': hubExploreSections,
        if (hubExploreSections.isNotEmpty) 'hub_cards': hubExploreSections,
      },
      'more': {
        'links': links,
      },
    };
  }

  List<Map<String, dynamic>> _normalizeWatchHubSections(
    Map<String, dynamic> payload, {
    required String bannerUrl,
  }) {
    final rawSections =
        payload['watch'] ?? payload['sections'] ?? payload['items'];

    if (rawSections is! List) return const <Map<String, dynamic>>[];

    final sections = <Map<String, dynamic>>[];

    for (final rawSection in rawSections) {
      if (rawSection is! Map) continue;

      final section = Map<String, dynamic>.from(rawSection);
      final enabled = section['is_enabled'] ?? section['enabled'];
      if (enabled == false || enabled == 0 || enabled == '0') continue;

      final tabKey = (section['tab_key'] ??
              section['route_key'] ??
              section['tab'] ??
              section['bucket'] ??
              '')
          .toString()
          .trim()
          .toLowerCase();

      final sectionKey = (section['key'] ??
              section['section_key'] ??
              section['route_key'] ??
              section['title'] ??
              '')
          .toString()
          .trim();

      final looksLikeWatch = tabKey == 'watch' ||
          sectionKey.toLowerCase().contains('watch') ||
          sectionKey.toLowerCase().contains('live') ||
          sectionKey.toLowerCase().contains('channel') ||
          sectionKey.toLowerCase().contains('stream') ||
          sectionKey.toLowerCase().contains('video');

      if (!looksLikeWatch) continue;

      final rawItems = section['items'];
      final items = <Map<String, dynamic>>[];

      if (rawItems is List) {
        for (final rawItem in rawItems) {
          if (rawItem is! Map) continue;

          final item = Map<String, dynamic>.from(rawItem);
          final itemEnabled = item['is_enabled'] ?? item['enabled'];
          if (itemEnabled == false || itemEnabled == 0 || itemEnabled == '0') {
            continue;
          }

          final imageUrl = _normalizeRemoteAssetUrl(
            _pickImage(item) ?? _pickImage(section) ?? bannerUrl,
          );

          if (imageUrl.isNotEmpty) {
            item['image_url'] = imageUrl;
            item['thumbnail_url'] =
                (item['thumbnail_url'] ?? imageUrl).toString();
            item['cover_image_url'] =
                (item['cover_image_url'] ?? imageUrl).toString();
            item['card_image_url'] =
                (item['card_image_url'] ?? imageUrl).toString();
            item['background_image_url'] =
                (item['background_image_url'] ?? imageUrl).toString();
          }

          item['title'] = (item['title'] ?? '').toString().trim();
          item['subtitle'] = (item['subtitle'] ?? '').toString().trim();
          item['url'] = _cleanUrl(
            (item['url'] ??
                    item['video_url'] ??
                    item['stream_url'] ??
                    item['link'] ??
                    '')
                .toString()
                .trim(),
          );
          item['route'] = (item['route'] ?? '').toString().trim();
          item['type'] = _normalizeWatchPlayerType(
            rawType: (item['type'] ?? item['engine'] ?? '').toString(),
            player: ((_asMap(item['meta']) ??
                        const <String, dynamic>{})['player'] ??
                    item['player'] ??
                    '')
                .toString(),
            url: (item['url'] ?? '').toString(),
          );
          item['badge'] =
              (item['badge'] ?? item['label'] ?? '').toString().trim();

          items.add(item);
        }
      }

      final sectionImage = _normalizeRemoteAssetUrl(
        _pickImage(section) ?? _firstImageFromDynamicItems(items),
      );

      if (sectionImage.isNotEmpty) {
        section['image_url'] = sectionImage;
        section['cover_image_url'] =
            (section['cover_image_url'] ?? sectionImage).toString();
        section['card_image_url'] =
            (section['card_image_url'] ?? sectionImage).toString();
        section['background_image_url'] =
            (section['background_image_url'] ?? sectionImage).toString();
      }

      section['key'] = sectionKey;
      section['section_key'] =
          (section['section_key'] ?? sectionKey).toString().trim();
      section['title'] = (section['title'] ?? '').toString().trim();
      section['subtitle'] = (section['subtitle'] ?? '').toString().trim();
      section['items'] = items;
      section['items_count'] = items.length;

      if (items.isNotEmpty ||
          (section['title'] ?? '').toString().trim().isNotEmpty) {
        sections.add(section);
      }
    }

    return sections;
  }

  List<Map<String, dynamic>> _collectDynamicQuoteItems({
    required List<Map<String, dynamic>> payloads,
    required List<Map<String, dynamic>> libraryItems,
  }) {
    final out = <Map<String, dynamic>>[];
    final seen = <String>{};

    void addQuote(Map<String, dynamic> item) {
      final flattened = _flattenDailyDesignItem(item);
      final quote = _pickFirstString(flattened, const [
        'quote',
        'quote_text',
        'text',
        'content',
        'body',
        'message',
      ]).trim();

      final bucket = _quoteBucketFromMap(flattened);
      final type = _pickFirstString(flattened, const [
        'type',
        'layout',
        'designer_type',
        'home_kind',
        'daily_kind',
      ]).toLowerCase();

      final looksLikeQuote = quote.isNotEmpty &&
          (bucket.contains('quote') ||
              type.contains('quote') ||
              type.contains('daily'));

      if (!looksLikeQuote) return;

      final id = _pickFirstString(flattened, const [
        'id',
        'content_id',
        'post_id',
        'quote_id',
        'slug',
      ]).trim();
      final signature =
          '${bucket.toLowerCase()}|${id.isNotEmpty ? id : quote.toLowerCase()}';
      if (seen.contains(signature)) return;
      seen.add(signature);

      out.add({
        ...item,
        ...flattened,
        if (bucket.isNotEmpty) 'bucket': bucket,
        if (bucket.isNotEmpty) 'source_bucket': bucket,
      });
    }

    void scan(dynamic value) {
      if (value == null) return;

      if (value is List) {
        for (final item in value) {
          scan(item);
        }
        return;
      }

      final map = _asMap(value);
      if (map == null || map.isEmpty) return;

      addQuote(map);

      for (final key in const [
        'daily_quote_items',
        'daily_quotes',
        'quote_items',
        'quotes',
        'items',
        'data',
        'records',
        'sections',
        'home',
        'inspire',
        'explore',
        'sections_by_tab',
      ]) {
        final nested = map[key];
        if (nested is List || nested is Map) {
          scan(nested);
        }
      }
    }

    scan(libraryItems);
    for (final payload in payloads) {
      scan(payload);
    }

    return out;
  }

  List<Map<String, dynamic>> _expandQuoteChannelSections(
    List<Map<String, dynamic>> sections, {
    required List<Map<String, dynamic>> quoteItems,
  }) {
    if (sections.isEmpty || quoteItems.isEmpty) return sections;

    return sections.map((section) {
      final sectionKey = (section['key'] ??
              section['section_key'] ??
              section['route_key'] ??
              section['bucket'] ??
              '')
          .toString()
          .trim()
          .toLowerCase();
      final sectionTitle =
          (section['title'] ?? '').toString().trim().toLowerCase();

      // The SOD hub/grid is a launcher section controlled by Destination
      // Builder. Its child item named "SOD Quotes" must remain one launcher
      // card; it must not be replaced with all quote cards from the quote
      // library. Standalone quote-channel sections can still expand below.
      final isSodLauncherSection = sectionKey.contains('inspire_sod') ||
          sectionKey == 'sod' ||
          sectionKey == 'sod_quotes' ||
          sectionTitle.contains('seed of destiny') ||
          sectionTitle.contains('seeds of destiny');

      if (isSodLauncherSection) return section;

      final rawItems = section['items'];
      if (rawItems is! List || rawItems.isEmpty) return section;

      final expandedItems = <Map<String, dynamic>>[];
      var expanded = false;
      var expandedBucket = '';

      for (final rawItem in rawItems) {
        final item = _asMap(rawItem);
        if (item == null) continue;

        final bucket = _quoteSourceBucketFromItem(item);
        if (bucket.isEmpty) {
          expandedItems.add(item);
          continue;
        }

        final limit = _builderLimit(item, section, fallback: 12);
        final matches = quoteItems
            .where((quote) => _quoteMatchesBucket(quote, bucket))
            .map((quote) => _quoteToDynamicCardItem(quote, bucket))
            .take(limit)
            .toList(growable: false);

        if (matches.isEmpty) {
          expandedItems.add(item);
          continue;
        }

        expanded = true;
        expandedBucket = bucket;
        expandedItems.addAll(matches);
      }

      if (!expanded) return section;

      final settings = <String, dynamic>{
        ...(_asMap(section['settings']) ?? const <String, dynamic>{}),
        'source_type': 'quote_channel',
        'source_bucket': expandedBucket,
        'layout': 'quote_carousel',
        'layout_template': 'quote_card',
        'card_style': 'quote_poster',
        'size_preset': 'poster_4_5',
        'card_width': '282',
        'card_height': '366',
      };

      return <String, dynamic>{
        ...section,
        'layout': 'quote_carousel',
        'layout_type': 'quote_carousel',
        'source_type': 'quote_channel',
        'bucket':
            expandedBucket.isNotEmpty ? expandedBucket : section['bucket'],
        'items': expandedItems,
        'items_count': expandedItems.length,
        'settings': settings,
      };
    }).toList(growable: false);
  }

  String _quoteSourceBucketFromItem(Map<String, dynamic> item) {
    final payload = _asMap(item['payload']) ?? const <String, dynamic>{};
    final source = _asMap(item['source']) ??
        _asMap(item['quote_source']) ??
        _asMap(payload['source']) ??
        const <String, dynamic>{};
    final builder = _asMap(item['item_builder']) ??
        _asMap(payload['item_builder']) ??
        const <String, dynamic>{};

    final sourceType = _pickFirstString({
      ...source,
      ...builder,
      ...item,
    }, const [
      'source_type',
      'type',
      'kind',
    ]).toLowerCase();

    final bucket = _pickFirstString({
      ...item,
      ...source,
      ...builder,
      ...payload,
    }, const [
      'source_bucket',
      'bucket',
      'beginner_bucket',
      'content_group',
      'channel',
    ]).trim();

    if (bucket.isNotEmpty &&
        (sourceType.contains('quote') ||
            bucket.toLowerCase().contains('quote'))) {
      return bucket;
    }

    return '';
  }

  String _quoteBucketFromMap(Map<String, dynamic> item) {
    return _pickFirstString(item, const [
      'source_bucket',
      'bucket',
      'beginner_bucket',
      'content_group',
      'channel',
    ]).trim();
  }

  bool _quoteMatchesBucket(Map<String, dynamic> quote, String bucket) {
    final normalizedBucket = bucket.trim().toLowerCase();
    if (normalizedBucket.isEmpty) return false;

    final flattened = _flattenDailyDesignItem(quote);
    final quoteBucket = _quoteBucketFromMap(flattened).toLowerCase();
    return quoteBucket == normalizedBucket;
  }

  int _builderLimit(
    Map<String, dynamic> item,
    Map<String, dynamic> section, {
    required int fallback,
  }) {
    final payload = _asMap(item['payload']) ?? const <String, dynamic>{};
    final display = _asMap(item['display']) ??
        _asMap(payload['display']) ??
        const <String, dynamic>{};
    final settings = _asMap(section['settings']) ?? const <String, dynamic>{};

    final raw = _pickFirstString({
      ...settings,
      ...display,
      ...payload,
      ...item,
    }, const [
      'maximum_items',
      'max_items',
      'limit',
      'count',
      'items_count',
    ]);

    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0) return fallback;
    return parsed.clamp(1, 50).toInt();
  }

  Map<String, dynamic> _quoteToDynamicCardItem(
    Map<String, dynamic> item,
    String bucket,
  ) {
    final flattened = _flattenDailyDesignItem(item);
    final quote = _pickFirstString(flattened, const [
      'quote',
      'quote_text',
      'text',
      'content',
      'body',
      'message',
      'title',
    ]).trim();
    final source = _pickFirstString(flattened, const [
      'source',
      'quote_source',
      'author',
      'subtitle',
    ]).trim();
    final id = _pickFirstString(flattened, const [
      'id',
      'content_id',
      'post_id',
      'quote_id',
      'slug',
    ]).trim();
    final imageUrl = _normalizeRemoteAssetUrl(_pickImage(flattened) ?? '');

    final renderStyle = <String, dynamic>{
      'standard': 'dxm_render_style_v1',
      'background_mode': _pickFirstString(flattened, const [
        'background_mode',
      ]).isNotEmpty
          ? _pickFirstString(flattened, const ['background_mode'])
          : (_pickFirstString(flattened, const ['bg_color_2', 'gradient_end'])
                  .isNotEmpty
              ? 'gradient'
              : 'solid'),
      'card_format':
          _pickFirstString(flattened, const ['card_format', 'format'])
                  .isNotEmpty
              ? _pickFirstString(flattened, const ['card_format', 'format'])
              : 'portrait',
      'bg_color': _pickFirstString(flattened, const [
        'bg_color',
        'background_color',
        'gradient_start',
      ]),
      'bg_color_2': _pickFirstString(flattened, const [
        'bg_color_2',
        'gradient_end',
      ]),
      'text_color': _pickFirstString(flattened, const ['text_color']),
      'accent_color': _pickFirstString(flattened, const [
        'accent_color',
        'highlight_color',
      ]),
      'title_size': _pickFirstString(flattened, const [
        'title_size',
        'quote_size',
        'font_size',
      ]),
      'font_size': _pickFirstString(flattened, const [
        'font_size',
        'source_size',
      ]),
      'font_family': _pickFirstString(flattened, const ['font_family']),
      'font_weight': _pickFirstString(flattened, const ['font_weight']),
      'text_align': _pickFirstString(flattened, const ['text_align']),
      'vertical_align': _pickFirstString(flattened, const ['vertical_align']),
      'line_height': _pickFirstString(flattened, const ['line_height']),
      'content_width': _pickFirstString(flattened, const ['content_width']),
      'card_padding': _pickFirstString(flattened, const [
        'card_padding',
        'padding_x',
      ]),
      'overlay_strength':
          _pickFirstString(flattened, const ['overlay_strength']),
      'show_quote_mark': flattened['show_quote_mark'],
    };

    return <String, dynamic>{
      ...item,
      ...flattened,
      'id': id.isNotEmpty ? id : item['id'],
      'key': id.isNotEmpty ? 'quote_$id' : 'quote_${quote.hashCode}',
      'title': quote,
      'subtitle': source,
      'type': 'quote',
      'layout': 'dynamic_quote_card',
      'bucket': bucket,
      'source_bucket': bucket,
      'quote': quote,
      'quote_text': quote,
      'source': source,
      'quote_source': source,
      'daily_kind': 'daily_quote',
      'home_kind': 'daily_quote',
      'image_url': imageUrl,
      'cover_image_url': imageUrl,
      'thumbnail_url': imageUrl,
      'route': id.isNotEmpty
          ? '/sod/quotes?id=$id&quote_id=$id&channel=$bucket'
          : '/sod/quotes?channel=$bucket',
      'render_style': renderStyle,
      'payload': {
        ...(_asMap(item['payload']) ?? const <String, dynamic>{}),
        ...flattened,
        'quote': quote,
        'quote_text': quote,
        'quote_source': source,
        'bucket': bucket,
        'source_bucket': bucket,
      },
    };
  }

  List<Map<String, dynamic>> _normalizeHubSections(dynamic value) {
    if (value is! List) return const [];

    final out = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final raw in value) {
      if (raw is! Map) continue;
      final section = Map<String, dynamic>.from(raw);
      final enabled = section['is_enabled'];
      if (enabled == false || enabled == 0 || enabled == '0') continue;

      final key =
          (section['key'] ?? section['route_key'] ?? section['title'] ?? '')
              .toString()
              .trim();
      final title = (section['title'] ?? '').toString().trim();
      if (key.isEmpty && title.isEmpty) continue;

      final normalizedKey = _normalizeInspireKey(key.isNotEmpty ? key : title);
      // Deduplicate by the backend section identity, not by normalized bucket.
      // Several Inspire sections may intentionally share a bucket/category
      // (for example short-video inserts and Inside Dunamis/articles). Using
      // the normalized bucket as the signature can hide valid sections from
      // the frontend even though Destination Builder enabled them.
      final signatureSource = key.isNotEmpty ? key : title;
      final signature = signatureSource.trim().toLowerCase();
      if (signature.isNotEmpty && seen.contains(signature)) continue;
      if (signature.isNotEmpty) seen.add(signature);

      final rawItems = section['items'];
      final items = <Map<String, dynamic>>[];

      if (rawItems is List) {
        for (final rawItem in rawItems) {
          if (rawItem is! Map) continue;
          final item = Map<String, dynamic>.from(rawItem);
          final itemEnabled = item['is_enabled'];
          if (itemEnabled == false || itemEnabled == 0 || itemEnabled == '0') {
            continue;
          }

          final itemImage = _normalizeRemoteAssetUrl(_pickImage(item) ?? '');
          if (itemImage.isNotEmpty) {
            item['image_url'] = itemImage;
            item['cover_image_url'] = itemImage;
            item['card_image_url'] = itemImage;
            item['background_image_url'] = itemImage;
          }

          item['title'] = (item['title'] ?? '').toString().trim();
          item['subtitle'] = (item['subtitle'] ?? '').toString().trim();
          item['route'] = (item['route'] ?? '').toString().trim();
          item['url'] = (item['url'] ?? '').toString().trim();
          items.add(item);
        }
      }

      final sectionImage = _normalizeRemoteAssetUrl(
        _pickImage(section) ?? _firstImageFromDynamicItems(items),
      );

      final route = (section['route'] ?? '').toString().trim();
      final routeKey = (section['route_key'] ?? '').toString().trim();

      out.add({
        ...section,
        'key': key,
        'bucket': normalizedKey,
        'title': title,
        'subtitle': (section['subtitle'] ?? '').toString().trim(),
        'route': route,
        'route_key': routeKey,
        'image_url': sectionImage,
        'cover_image_url': sectionImage,
        'card_image_url': sectionImage,
        'background_image_url': sectionImage,
        'items': items,
        'items_count': items.length,
      });
    }

    return out;
  }

  String _normalizeInspireKey(String value) {
    final key = value.trim().toLowerCase().replaceAll('-', '_');

    if (key.contains('message') && key.contains('highlight')) {
      return 'highlights';
    }
    if (key.contains('highlight')) return 'highlights';
    if (key.contains('seed') || key.contains('sod')) {
      return 'sod_quotes';
    }
    if (key.contains('wordification')) return 'wordification';
    if (key.contains('motivation')) return 'motivation';
    if (key.contains('inside') || key.contains('article')) return 'articles';

    return key
        .replaceFirst('inspire_', '')
        .replaceFirst('_hub', '')
        .replaceFirst('_section', '')
        .trim();
  }

  String _firstImageFromDynamicItems(List<Map<String, dynamic>> items) {
    for (final item in items) {
      final image = _normalizeRemoteAssetUrl(_pickImage(item) ?? '');
      if (image.isNotEmpty) return image;
    }
    return '';
  }

  Map<String, dynamic> _normalizeWatchPayload({
    required Map<String, dynamic> watch,
    required String bannerUrl,
  }) {
    final rawItems = watch['items'];
    final watchItems = (rawItems is List)
        ? rawItems
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(growable: false)
        : const <Map<String, dynamic>>[];

    final grouped = <String, List<Map<String, String>>>{};

    void addToGroup(String key, Map<String, String> item) {
      final groupKey = key.trim();
      if (groupKey.isEmpty) return;

      grouped.putIfAbsent(groupKey, () => []);

      final signature =
          '${(item['title'] ?? '').trim().toLowerCase()}|${(item['url'] ?? '').trim().toLowerCase()}';

      final exists = grouped[groupKey]!.any((existing) {
        final existingSignature =
            '${(existing['title'] ?? '').trim().toLowerCase()}|${(existing['url'] ?? '').trim().toLowerCase()}';
        return existingSignature == signature;
      });

      if (!exists) {
        grouped[groupKey]!.add(item);
      }
    }

    for (final raw in watchItems) {
      final title = (raw['title'] ?? '').toString().trim();
      final rawUrl = (raw['url'] ?? '').toString().trim();
      final url = _cleanUrl(rawUrl);
      if (title.isEmpty || url.isEmpty) continue;

      final meta = _asMap(raw['meta']) ?? const <String, dynamic>{};
      final subtitle = _pickFirstString(raw, const ['subtitle']);
      final imageUrl = _pickImage(raw) ?? bannerUrl;
      final badge = (raw['badge'] ?? raw['label'] ?? meta['label'] ?? '')
          .toString()
          .trim();

      final rawType = (raw['type'] ?? '').toString().trim().toLowerCase();
      final player = (meta['player'] ?? '').toString().trim().toLowerCase();
      final group =
          (meta['group'] ?? raw['group'] ?? '').toString().trim().toLowerCase();

      final normalizedType = _normalizeWatchPlayerType(
        rawType: rawType,
        player: player,
        url: url,
      );

      final normalizedItem = {
        'title': title,
        'subtitle': subtitle,
        'type': normalizedType,
        'url': url,
        'image_url': imageUrl,
        'badge': badge,
      };

      final bucketKey = group.isNotEmpty
          ? group
          : _inferWatchGroupKey(
              rawType: rawType,
              normalizedType: normalizedType,
              title: title,
            );

      addToGroup(bucketKey, normalizedItem);
    }

    final explicitVideos = _normalizeWatchList(
      watch['videos'],
      fallbackType: 'youtube',
    );
    for (final item in explicitVideos) {
      addToGroup('video', item);
    }

    final explicitOtherChannels = _normalizeWatchList(
      watch['other_channels'],
      fallbackType: 'web',
    );
    for (final item in explicitOtherChannels) {
      addToGroup('other_channels', item);
    }

    final explicitGroups = _normalizeWatchGroups(watch['groups']);
    explicitGroups.forEach((key, items) {
      for (final item in items) {
        addToGroup(key, item);
      }
    });

    final liveHls = _normalizeWatchCard(
          _asMap(watch['live_hls']),
          bannerUrl: bannerUrl,
        ) ??
        _firstCardFromGroup(
          grouped,
          const ['live_hls'],
          bannerUrl: bannerUrl,
        ) ??
        _normalizeWatchCard(
          _asMap({
            'title': watch['primary_stream_title'] ?? AppConfig.liveTitle,
            'url': watch['primary_stream_url'],
            'image_url': bannerUrl,
            'type': 'hls',
            'badge': 'LIVE',
          }),
          bannerUrl: bannerUrl,
        );

    final liveYoutube = _normalizeWatchCard(
          _asMap(watch['live_youtube']),
          bannerUrl: bannerUrl,
        ) ??
        _firstCardFromGroup(
          grouped,
          const ['live_youtube', 'live_service', 'service'],
          bannerUrl: bannerUrl,
        );

    final commandingDay = _normalizeWatchCard(
          _asMap(watch['commanding_day']),
          bannerUrl: bannerUrl,
        ) ??
        _firstCardFromGroup(
          grouped,
          const ['commanding_day', 'prayer'],
          bannerUrl: bannerUrl,
        );

    grouped.remove('live_hls');
    grouped.remove('live_youtube');
    grouped.remove('live_service');
    grouped.remove('service');
    grouped.remove('commanding_day');
    grouped.remove('prayer');

    return {
      'live_hls': liveHls ??
          {
            'title': AppConfig.liveTitle,
            'subtitle': '',
            'type': 'web',
            'url': '',
            'image_url': bannerUrl,
            'badge': 'LIVE',
          },
      'live_youtube': liveYoutube,
      'commanding_day': commandingDay,
      'videos': grouped['video'] ??
          grouped['videos'] ??
          const <Map<String, String>>[],
      'other_channels':
          grouped['other_channels'] ?? const <Map<String, String>>[],
      'groups': grouped,
      'raw': watchItems,
    };
  }

  Map<String, String>? _firstCardFromGroup(
    Map<String, List<Map<String, String>>> grouped,
    List<String> keys, {
    required String bannerUrl,
  }) {
    for (final key in keys) {
      final items = grouped[key];
      if (items == null || items.isEmpty) continue;

      final item = items.first;
      final title = (item['title'] ?? '').trim();
      final url = _cleanUrl((item['url'] ?? '').trim());
      if (title.isEmpty || url.isEmpty) continue;

      return {
        'title': title,
        'subtitle': (item['subtitle'] ?? '').trim(),
        'type': (item['type'] ?? 'web').trim(),
        'url': url,
        'image_url': (item['image_url'] ?? '').trim().isNotEmpty
            ? (item['image_url'] ?? '').trim()
            : bannerUrl,
        'badge': (item['badge'] ?? '').trim(),
      };
    }
    return null;
  }

  Map<String, String>? _normalizeWatchCard(
    Map<String, dynamic>? item, {
    required String bannerUrl,
  }) {
    if (item == null || item.isEmpty) return null;

    final title = (item['title'] ?? '').toString().trim();
    final url = _cleanUrl((item['url'] ?? '').toString().trim());
    if (title.isEmpty || url.isEmpty) return null;

    final subtitle = _pickFirstString(item, const ['subtitle']);
    final imageUrl = _pickImage(item) ?? bannerUrl;
    final type = (item['type'] ?? '').toString().trim();
    final badge = (item['badge'] ?? item['label'] ?? '').toString().trim();

    return {
      'title': title,
      'subtitle': subtitle,
      'type': type,
      'url': url,
      'image_url': imageUrl,
      'badge': badge,
    };
  }

  List<Map<String, String>> _normalizeWatchList(
    dynamic value, {
    required String fallbackType,
  }) {
    if (value is! List) return const [];

    final out = <Map<String, String>>[];
    final seen = <String>{};

    for (final item in value) {
      if (item is! Map) continue;

      final title = (item['title'] ?? '').toString().trim();
      final url = _cleanUrl((item['url'] ?? '').toString().trim());
      if (title.isEmpty || url.isEmpty) continue;

      final signature = '${title.toLowerCase()}|${url.toLowerCase()}';
      if (seen.contains(signature)) continue;
      seen.add(signature);

      out.add({
        'title': title,
        'subtitle': (item['subtitle'] ?? '').toString().trim(),
        'type': (item['type'] ?? fallbackType).toString().trim(),
        'url': url,
        'image_url': (item['image_url'] ?? '').toString().trim(),
        'badge': (item['badge'] ?? '').toString().trim(),
      });
    }

    return out;
  }

  Map<String, List<Map<String, String>>> _normalizeWatchGroups(dynamic value) {
    if (value is! Map) return const {};

    final out = <String, List<Map<String, String>>>{};

    value.forEach((key, rawItems) {
      final groupKey = key.toString().trim();
      if (groupKey.isEmpty || rawItems is! List) return;

      final items = <Map<String, String>>[];
      final seen = <String>{};

      for (final item in rawItems) {
        if (item is! Map) continue;

        final title = (item['title'] ?? '').toString().trim();
        final url = _cleanUrl((item['url'] ?? '').toString().trim());
        if (title.isEmpty || url.isEmpty) continue;

        final signature = '${title.toLowerCase()}|${url.toLowerCase()}';
        if (seen.contains(signature)) continue;
        seen.add(signature);

        items.add({
          'title': title,
          'subtitle': (item['subtitle'] ?? '').toString().trim(),
          'type': (item['type'] ?? 'web').toString().trim(),
          'url': url,
          'image_url': (item['image_url'] ?? '').toString().trim(),
          'badge': (item['badge'] ?? '').toString().trim(),
        });
      }

      if (items.isNotEmpty) {
        out[groupKey] = items;
      }
    });

    return out;
  }

  String _normalizeWatchPlayerType({
    required String rawType,
    required String player,
    required String url,
  }) {
    final t = rawType.trim().toLowerCase();
    final p = player.trim().toLowerCase();
    final u = url.trim().toLowerCase();

    if (_isDirectHlsUrl(u)) {
      return 'hls';
    }

    if (p == 'hls' || t == 'live_hls' || t == 'hls' || t == 'm3u8') {
      return _looksLikeWebPageUrl(u) ? 'web' : 'hls';
    }

    if (p == 'youtube' ||
        t == 'live_youtube' ||
        t == 'youtube' ||
        t == 'youtube_video' ||
        t == 'video' ||
        t == 'vod' ||
        t == 'playlist' ||
        t == 'commanding_day' ||
        u.contains('youtube.com') ||
        u.contains('youtu.be') ||
        u.contains('youtube-nocookie.com')) {
      return 'youtube';
    }

    return 'web';
  }

  bool _isDirectHlsUrl(String lowerUrl) {
    return lowerUrl.endsWith('.m3u8') ||
        lowerUrl.contains('.m3u8?') ||
        lowerUrl.contains('/m3u8');
  }

  bool _looksLikeWebPageUrl(String lowerUrl) {
    return lowerUrl.endsWith('.html') ||
        lowerUrl.endsWith('.htm') ||
        lowerUrl.contains('.html?') ||
        lowerUrl.contains('.htm?') ||
        lowerUrl.contains('/watch') ||
        lowerUrl.contains('/live') ||
        lowerUrl.contains('/stream') ||
        lowerUrl.contains('/channel') ||
        lowerUrl.contains('/player') ||
        lowerUrl.contains('/embed/') ||
        lowerUrl.contains('/iframe/') ||
        lowerUrl.contains('watch?') ||
        lowerUrl.contains('live?') ||
        lowerUrl.contains('stream?') ||
        lowerUrl.contains('channel?') ||
        lowerUrl.contains('player?') ||
        lowerUrl.contains('viewmedia.tv') ||
        lowerUrl.contains('iframe.viewmedia.tv') ||
        lowerUrl.contains('bozztv.com');
  }

  String _inferWatchGroupKey({
    required String rawType,
    required String normalizedType,
    required String title,
  }) {
    final t = rawType.trim().toLowerCase();
    final lowerTitle = title.toLowerCase();

    if (t == 'channel') return 'other_channels';
    if (t == 'video' || t == 'youtube_video' || t == 'vod' || t == 'playlist') {
      return 'video';
    }
    if (t == 'commanding_day' ||
        lowerTitle.contains('commanding the day') ||
        lowerTitle.contains('prayer broadcast')) {
      return 'commanding_day';
    }
    if (t == 'live_hls') return 'live_hls';
    if (t == 'live_youtube' || t == 'live' || t == 'youtube') {
      return 'live_youtube';
    }

    return normalizedType == 'youtube' ? 'video' : 'other_channels';
  }

  List<Map<String, String>> _normalizeHomeHeroSlides(
    dynamic heroValue,
    String appName,
    String tagline,
    String bannerUrl,
  ) {
    final hero = _asMap(heroValue);
    final slidesRaw = hero?['slides'];

    if (slidesRaw is List) {
      final slides = slidesRaw
          .whereType<Map>()
          .map((e) => {
                'title': (e['title'] ?? appName).toString(),
                'subtitle': (e['subtitle'] ?? tagline).toString(),
                'image_url': (e['image_url'] ?? '').toString(),
              })
          .where((e) => (e['image_url'] ?? '').trim().isNotEmpty)
          .toList(growable: false);

      if (slides.isNotEmpty) {
        return slides;
      }
    }

    if (bannerUrl.isNotEmpty) {
      return [
        {
          'title': appName.isEmpty ? AppConfig.heroDefaultTitle : appName,
          'subtitle':
              tagline.isEmpty ? 'Watch, learn and get inspired' : tagline,
          'image_url': bannerUrl,
        },
      ];
    }

    return const [];
  }

  Map<String, Map<String, String>> _normalizeHomeShortcuts(
    dynamic shortcutsValue,
    String bannerUrl,
  ) {
    final shortcuts = _asMap(shortcutsValue) ?? const <String, dynamic>{};

    Map<String, String> build(
      String key,
      Map<String, String> fallback,
    ) {
      final raw = _asMap(shortcuts[key]);
      if (raw == null || raw.isEmpty) return fallback;

      return {
        'title': (raw['title'] ?? fallback['title'] ?? '').toString(),
        'subtitle': (raw['subtitle'] ?? fallback['subtitle'] ?? '').toString(),
        'image_url':
            (raw['image_url'] ?? fallback['image_url'] ?? '').toString(),
      };
    }

    return {
      'live': build(
        'live',
        {
          'title': AppConfig.liveTitle,
          'subtitle': 'Watch live broadcast and streaming content',
          'image_url': bannerUrl,
        },
      ),
      'sod': build(
        'sod',
        {
          'title': AppConfig.homeSodTitle,
          'subtitle': 'Read today’s devotional and key spiritual insights',
          'image_url': bannerUrl,
        },
      ),
      'articles': build(
        'articles',
        {
          'title': AppConfig.homeArticlesTitle,
          'subtitle': 'Read featured articles and ministry updates',
          'image_url': bannerUrl,
        },
      ),
      'highlights': build(
        'highlights',
        {
          'title': AppConfig.homeHighlightsTitle,
          'subtitle': 'Catch short message summaries and spiritual takeaways',
          'image_url': bannerUrl,
        },
      ),
    };
  }

  Map<String, String> _normalizeHomePrayerBroadcast(
    Map<String, dynamic>? item,
    String bannerUrl,
  ) {
    if (item == null || item.isEmpty) {
      return {
        'title': AppConfig.commandingDayTitle,
        'subtitle': 'Open the current prayer stream from Watch.',
        'image_url': bannerUrl,
        'url': '',
        'route': '/watch',
      };
    }

    final title =
        (item['title'] ?? AppConfig.commandingDayTitle).toString().trim();
    final subtitle = _pickFirstString(item, const ['subtitle', 'note']);
    final imageUrl = _pickImage(item) ?? bannerUrl;
    final url = _cleanUrl((item['url'] ?? '').toString().trim());
    final route = (item['route'] ?? '/watch').toString().trim();

    return {
      'title': title.isNotEmpty ? title : AppConfig.commandingDayTitle,
      'subtitle': subtitle.isNotEmpty
          ? subtitle
          : 'Open the current prayer stream from Watch.',
      'image_url': imageUrl,
      'url': url,
      'route': route.isNotEmpty ? route : '/watch',
    };
  }

  Map<String, dynamic>? _extractHomeDailyItem(
    Map<String, dynamic> payload, {
    required String dailyKind,
  }) {
    if (payload.isEmpty) return null;

    final normalizedKind = dailyKind.trim().toLowerCase();

    bool looksLikeDailyKind(Map<String, dynamic> item) {
      final kind = _pickFirstString(item, const [
        'daily_kind',
        'home_kind',
        'kind',
      ]).toLowerCase();

      final sectionKey = _pickFirstString(item, const [
        'section_key',
        'key',
        'bucket',
        'layout',
        'type',
        'template',
        'slug',
      ]).toLowerCase();

      final title = _pickFirstString(item, const [
        'title',
        'label',
        'name',
      ]).toLowerCase();

      final combined = '$kind $sectionKey $title';

      return kind == normalizedKind ||
          sectionKey == 'home_$normalizedKind' ||
          sectionKey == normalizedKind ||
          combined.contains('home_$normalizedKind') ||
          (normalizedKind == 'daily_quote' &&
              combined.contains('daily') &&
              combined.contains('quote')) ||
          (normalizedKind == 'daily_scripture' &&
              ((combined.contains('daily') && combined.contains('scripture')) ||
                  combined.contains('daily scripture')));
    }

    bool hasDailyText(Map<String, dynamic> item) {
      final flattened = _flattenDailyDesignItem(item);

      if (normalizedKind == 'daily_scripture') {
        return _pickFirstString(flattened, const [
          'verse',
          'scripture_text',
          'quote',
          'quote_text',
          'text',
          'content',
          'body',
        ]).trim().isNotEmpty;
      }

      return _pickFirstString(flattened, const [
        'quote',
        'quote_text',
        'text',
        'content',
        'body',
        'message',
      ]).trim().isNotEmpty;
    }

    Map<String, dynamic>? matchFromMap(Map<String, dynamic> item) {
      final directLooksLike = looksLikeDailyKind(item);

      if (directLooksLike) {
        final items = item['items'];
        if (items is List) {
          for (final rawChild in items) {
            final child = _asMap(rawChild);
            if (child == null) continue;

            final merged = <String, dynamic>{
              ...item,
              ...child,
              if (_asMap(item['style']) != null) 'style': _asMap(item['style']),
              if (_asMap(item['render_style']) != null)
                'render_style': _asMap(item['render_style']),
              if (_asMap(item['design']) != null)
                'design': _asMap(item['design']),
              if (_asMap(child['style']) != null)
                'style': _asMap(child['style']),
              if (_asMap(child['render_style']) != null)
                'render_style': _asMap(child['render_style']),
              if (_asMap(child['design']) != null)
                'design': _asMap(child['design']),
            };

            if (hasDailyText(merged) || looksLikeDailyKind(child)) {
              return _flattenDailyDesignItem(merged);
            }
          }
        }

        return _flattenDailyDesignItem(item);
      }

      if (hasDailyText(item) &&
          looksLikeDailyKind(_flattenDailyDesignItem(item))) {
        return _flattenDailyDesignItem(item);
      }

      return null;
    }

    Map<String, dynamic>? scan(dynamic value) {
      if (value is Map) {
        final map = value.map((k, v) => MapEntry(k.toString(), v));

        final direct = matchFromMap(map);
        if (direct != null) return direct;

        for (final key in const [
          'daily_quote',
          'daily_scripture',
          'home_daily_quote',
          'home_daily_scripture',
          'active_daily_quote',
          'active_daily_scripture',
        ]) {
          final nested = map[key];
          if (nested is Map) {
            final found = matchFromMap(
              nested.map((k, v) => MapEntry(k.toString(), v)),
            );
            if (found != null) return found;
          }
        }

        final items = map['items'];
        if (items is List) {
          for (final item in items) {
            final found = scan(item);
            if (found != null) return found;
          }
        }

        for (final value in map.values) {
          if (value is List) {
            for (final item in value) {
              final found = scan(item);
              if (found != null) return found;
            }
          } else if (value is Map) {
            final found = scan(value);
            if (found != null) return found;
          }
        }
      }

      if (value is List) {
        for (final item in value) {
          final found = scan(item);
          if (found != null) return found;
        }
      }

      return null;
    }

    return scan(payload['home']) ??
        scan(_asMap(payload['sections_by_tab'])?['home']) ??
        scan(payload['sections']) ??
        scan(payload['app']) ??
        scan(payload['branding']) ??
        scan(payload);
  }

  Map<String, dynamic> _flattenDailyDesignItem(Map<String, dynamic> item) {
    final output = <String, dynamic>{};

    void put(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      output[key] = value;
    }

    void addMap(dynamic value) {
      final map = _asMap(value);
      if (map == null) return;
      map.forEach(put);
    }

    item.forEach(put);

    for (final key in const [
      'style',
      'render_style',
      'design',
      'payload',
      'meta',
      'meta_json',
    ]) {
      addMap(item[key]);
    }

    return output;
  }

  List<Map<String, String>> _dailyListWithActive({
    required Map<String, String> active,
    required List<Map<String, dynamic>> libraryItems,
    required String kind,
  }) {
    final out = <Map<String, String>>[];
    final seen = <String>{};

    bool hasText(Map<String, String> item) {
      if (kind == 'daily_scripture') {
        return (item['verse'] ?? '').trim().isNotEmpty ||
            (item['ref'] ?? '').trim().isNotEmpty ||
            (item['reference'] ?? '').trim().isNotEmpty;
      }

      return (item['quote'] ?? '').trim().isNotEmpty ||
          (item['quote_text'] ?? '').trim().isNotEmpty ||
          (item['text'] ?? '').trim().isNotEmpty;
    }

    void add(Map<String, String> item) {
      if (!hasText(item)) return;

      final text = kind == 'daily_scripture'
          ? ((item['verse'] ?? item['quote_text'] ?? item['text'] ?? '').trim())
          : ((item['quote'] ?? item['quote_text'] ?? item['text'] ?? '')
              .trim());
      final source = kind == 'daily_scripture'
          ? ((item['ref'] ?? item['reference'] ?? item['quote_source'] ?? '')
              .trim())
          : ((item['source'] ?? item['quote_source'] ?? '').trim());
      final signature = '${text.toLowerCase()}|${source.toLowerCase()}';
      if (signature.trim() == '|') return;
      if (seen.contains(signature)) return;
      seen.add(signature);
      out.add(item);
    }

    add(active);

    for (final raw in libraryItems) {
      final normalized = kind == 'daily_scripture'
          ? _normalizeDailyScripture(raw)
          : _normalizeDailyQuote(raw);
      add(normalized);
      if (out.length >= 10) break;
    }

    return out;
  }

  Map<String, String> _normalizeDailyScripture(Map<String, dynamic>? item) {
    return _normalizeDailyDesignedCard(
      item,
      kind: 'daily_scripture',
      empty: const {
        'ref': '',
        'reference': '',
        'verse': '',
        'note': '',
        'image_url': '',
        'image': '',
      },
      textKeys: const [
        'verse',
        'scripture_text',
        'quote',
        'quote_text',
        'text',
        'content',
        'body',
      ],
      sourceKeys: const [
        'ref',
        'reference',
        'scripture_reference',
        'verse_ref',
        'bible_ref',
        'quote_source',
        'source',
      ],
      noteKeys: const [
        'note',
        'scripture_note',
        'caption',
        'summary',
        'description',
        'subtitle',
      ],
    );
  }

  Map<String, String> _normalizeDailyQuote(Map<String, dynamic>? item) {
    return _normalizeDailyDesignedCard(
      item,
      kind: 'daily_quote',
      empty: const {
        'quote': '',
        'source': '',
        'image_url': '',
        'image': '',
      },
      textKeys: const [
        'quote',
        'quote_text',
        'text',
        'content',
        'body',
        'message',
      ],
      sourceKeys: const [
        'source',
        'quote_source',
        'author',
        'credit',
        'brand_text',
        'caption',
        'subtitle',
      ],
      noteKeys: const [
        'note',
        'caption',
        'summary',
        'description',
        'subtitle',
      ],
    );
  }

  Map<String, String> _normalizeDailyDesignedCard(
    Map<String, dynamic>? item, {
    required String kind,
    required Map<String, String> empty,
    required List<String> textKeys,
    required List<String> sourceKeys,
    required List<String> noteKeys,
  }) {
    if (item == null || item.isEmpty) {
      return {
        ...empty,
        ..._emptyDailyDesignDefaults(),
      };
    }

    final text = _pickFirstString(item, textKeys);
    final source = _pickFirstString(item, sourceKeys);
    final note = _pickFirstString(item, noteKeys);
    final imageUrl = _normalizeRemoteAssetUrl(_pickImage(item) ?? '');

    String pickDesign(List<String> keys, [String fallback = '']) {
      for (final key in keys) {
        final value = item[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }

      for (final parentKey in const [
        'payload',
        'design',
        'render_style',
        'style',
        'meta',
        'meta_json',
      ]) {
        final parent = _asMap(item[parentKey]);
        if (parent == null) continue;

        for (final key in keys) {
          final value = parent[key]?.toString().trim() ?? '';
          if (value.isNotEmpty) return value;
        }
      }

      return fallback;
    }

    final out = <String, String>{
      ..._emptyDailyDesignDefaults(),
      if (kind == 'daily_scripture') ...{
        'ref': source,
        'reference': source,
        'verse': text,
        'note': note,
      } else ...{
        'quote': text,
        'source': source,
      },
      'quote_text': text,
      'text': text,
      'quote_source': source,
      'source': source,
      'image_url': imageUrl,
      'image': pickDesign(const ['image'], imageUrl),
    };

    const designKeys = [
      'background_mode',
      'card_format',
      'canvas_ratio',
      'font_family',
      'text_scale_mode',
      'text_color',
      'bg_color',
      'background_color',
      'bg_color_2',
      'background_color_2',
      'gradient_start',
      'gradient_end',
      'accent_color',
      'font_size',
      'title_size',
      'quote_size',
      'main_font_size',
      'source_size',
      'support_font_size',
      'font_weight',
      'source_weight',
      'text_align',
      'vertical_align',
      'overlay_strength',
      'content_width',
      'card_padding',
      'card_padding_x',
      'card_padding_y',
      'padding_x',
      'padding_y',
      'line_height',
      'show_quote_mark',
      'text_shadow',
      'source_color',
      'highlight_color',
      'highlight_scale',
      'highlight_size_boost',
      'highlight_weight',
      'highlight_phrases',
      'highlight_words',
      'use_solid_bg',
      'use_solid_background',
    ];

    for (final key in designKeys) {
      final value = pickDesign([key]);
      if (value.isNotEmpty) {
        out[key] = value;
      }
    }

    return out;
  }

  Map<String, String> _emptyDailyDesignDefaults() {
    return const {
      'quote_text': '',
      'quote_source': '',
      'text': '',
      'source': '',
      'image_url': '',
      'image': '',
      'text_color': '',
      'source_color': '',
      'bg_color': '',
      'background_color': '',
      'bg_color_2': '',
      'background_color_2': '',
      'accent_color': '',
      'background_mode': '',
      'card_format': '',
      'font_family': '',
      'text_scale_mode': '',
      'font_size': '',
      'title_size': '',
      'quote_size': '',
      'source_size': '',
      'font_weight': '',
      'source_weight': '',
      'text_align': '',
      'vertical_align': '',
      'overlay_strength': '',
      'content_width': '',
      'card_padding': '',
      'card_padding_x': '',
      'card_padding_y': '',
      'padding_x': '',
      'padding_y': '',
      'line_height': '',
      'show_quote_mark': '',
      'text_shadow': '',
      'highlight_color': '',
      'highlight_scale': '',
      'highlight_size_boost': '',
      'highlight_weight': '',
      'highlight_phrases': '',
      'highlight_words': '',
      'use_solid_bg': '',
      'use_solid_background': '',
    };
  }

  String _pickFirstString(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }

    final meta = _asMap(item['meta']);
    if (meta != null) {
      for (final key in keys) {
        final value = meta[key];
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) return text;
      }
    }

    return '';
  }

  List<Map<String, dynamic>> _extractExploreTools(
    Map<String, dynamic> bootstrap,
  ) {
    final hub = _asMap(bootstrap['hub']) ?? const <String, dynamic>{};
    final grouped = _asMap(hub['grouped']) ?? const <String, dynamic>{};
    final explore = _asMap(grouped['explore']) ?? const <String, dynamic>{};
    final exploreList = explore['explore'];

    if (exploreList is! List || exploreList.isEmpty) return const [];

    final first = exploreList.first;
    if (first is! Map) return const [];

    final items = first['items'];
    if (items is! List) return const [];

    return items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }

  String? _pickImage(Map<String, dynamic>? item) {
    if (item == null || item.isEmpty) return null;

    final directKeys = [
      'image_url',
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
      for (final key in directKeys) {
        final value = meta[key];
        final s = value?.toString().trim() ?? '';
        if (s.isNotEmpty) return s;
      }
    }

    return null;
  }

  String _normalizeRemoteAssetUrl(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return '';

    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('//')) return 'https:$raw';
    if (raw.startsWith('assets/')) return raw;

    Uri? base;
    try {
      base = Uri.parse(AppConfig.hubBootstrapUrl);
    } catch (_) {
      base = null;
    }

    if (base == null || base.scheme.isEmpty || base.host.isEmpty) return raw;

    final origin =
        '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';

    if (raw.startsWith('/')) return '$origin$raw';

    if (raw.startsWith('storage/') ||
        raw.startsWith('uploads/') ||
        raw.startsWith('images/') ||
        raw.startsWith('media/')) {
      return '$origin/$raw';
    }

    return raw;
  }

  String _cleanUrl(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return '';

    final match = RegExp(r'https?://[^\s]+').firstMatch(raw);
    if (match != null) return match.group(0)!;

    return raw;
  }

  Map<String, dynamic> _extractBootstrap(Map<String, dynamic> source) {
    final inner = source['bootstrap'];
    if (inner is Map<String, dynamic>) return inner;
    if (inner is Map) return Map<String, dynamic>.from(inner);
    return const {};
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_cacheKey);
      if (s == null || s.trim().isEmpty) return;

      final decoded = jsonDecode(s);
      if (decoded is Map<String, dynamic>) {
        _data = decoded;
      } else if (decoded is Map) {
        _data = decoded.cast<String, dynamic>();
      }
    } catch (_) {}
  }

  Future<void> _saveCache(Map<String, dynamic> json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(json));
    } catch (_) {}
  }

  dynamic _valueAt(List<String> path) {
    dynamic cur = _data;
    for (final key in path) {
      if (cur is Map && cur.containsKey(key)) {
        cur = cur[key];
      } else if (cur is List) {
        final index = int.tryParse(key);
        if (index == null || index < 0 || index >= cur.length) {
          return null;
        }
        cur = cur[index];
      } else {
        return null;
      }
    }
    return cur;
  }

  String? _stringAt(List<String> path) {
    final v = _valueAt(path);
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  Map<String, String>? _watchCardAt(
    List<String> path, {
    required String fallbackType,
  }) {
    final v = _valueAt(path);
    if (v is! Map) return null;

    final title = (v['title'] ?? '').toString().trim();
    final url = _cleanUrl((v['url'] ?? '').toString().trim());
    if (title.isEmpty || url.isEmpty) return null;

    return {
      'title': title,
      'subtitle': (v['subtitle'] ?? '').toString().trim(),
      'type': (v['type'] ?? fallbackType).toString().trim(),
      'url': url,
      'image_url': (v['image_url'] ?? '').toString().trim(),
      'badge': (v['badge'] ?? '').toString().trim(),
    };
  }

  List<Map<String, String>> _normalizeCardList(
    dynamic value, {
    required String fallbackType,
  }) {
    if (value is! List) return const [];

    final out = <Map<String, String>>[];
    final seen = <String>{};

    for (final item in value) {
      if (item is! Map) continue;

      final title = (item['title'] ?? '').toString().trim();
      final url = _cleanUrl((item['url'] ?? '').toString().trim());
      if (title.isEmpty || url.isEmpty) continue;

      final signature = '${title.toLowerCase()}|${url.toLowerCase()}';
      if (seen.contains(signature)) continue;
      seen.add(signature);

      out.add({
        'title': title,
        'subtitle': (item['subtitle'] ?? '').toString().trim(),
        'type': (item['type'] ?? fallbackType).toString().trim(),
        'url': url,
        'image_url': (item['image_url'] ?? '').toString().trim(),
        'badge': (item['badge'] ?? '').toString().trim(),
      });
    }

    return out;
  }

  List<Map<String, String>> _mapStringListAt(List<String> path) {
    final value = _valueAt(path);
    if (value is! List) return const <Map<String, String>>[];

    final out = <Map<String, String>>[];
    for (final item in value) {
      if (item is! Map) continue;
      final map = <String, String>{};
      item.forEach((key, value) {
        map[key.toString()] = (value ?? '').toString();
      });
      if (map.isNotEmpty) out.add(map);
    }

    return out;
  }

  Map<String, String> _mapStringAt(
    List<String> path, {
    required Map<String, String> fallback,
  }) {
    final v = _valueAt(path);
    if (v is Map) {
      final map = <String, String>{};
      v.forEach((key, value) {
        map[key.toString()] = (value ?? '').toString();
      });

      final output = <String, String>{};
      final keys = <String>{
        ...fallback.keys,
        ...map.keys,
      };

      for (final key in keys) {
        final current = (map[key] ?? '').trim();
        output[key] = current.isNotEmpty ? current : (fallback[key] ?? '');
      }

      return output;
    }
    return fallback;
  }

  Map<String, dynamic> _extractCapabilities(
    Map<String, dynamic> bootstrap,
    Map<String, dynamic> branding,
    Map<String, dynamic> brandingRaw,
  ) {
    return _mergeNonEmptyMaps([
      _asMap(brandingRaw['capabilities']),
      _asMap(branding['capabilities']),
      _asMap(bootstrap['capabilities']),
    ]);
  }

  Map<String, dynamic> _legacyFlagsFromCapabilities(
    Map<String, dynamic> capabilities,
  ) {
    bool enabled(String key) => _boolFromDynamic(capabilities[key]) ?? false;

    return <String, dynamic>{
      if (enabled('watch_manager') || enabled('watch_links'))
        'enable_watch': true,
      if (enabled('content_channels') ||
          enabled('home_manager') ||
          enabled('inspire_manager') ||
          enabled('explore_manager'))
        'enable_content_studio': true,
      if (enabled('ads')) 'enable_ads': true,
      if (enabled('notifications')) 'enable_push': true,
      if (enabled('user_auth')) 'enable_auth': true,
    };
  }

  Map<String, dynamic> _mergeNonEmptyMaps(
    Iterable<Map<String, dynamic>?> maps,
  ) {
    final merged = <String, dynamic>{};

    for (final map in maps) {
      if (map == null) continue;
      map.forEach((key, value) {
        if (value == null) return;
        if (value is String && value.trim().isEmpty) return;
        merged[key.toString()] = value;
      });
    }

    return merged;
  }

  bool? _boolFromDynamic(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.trim().toLowerCase();
      if (lower.isEmpty) return null;
      if (['1', 'true', 'yes', 'on', 'enabled', 'active'].contains(lower)) {
        return true;
      }
      if (['0', 'false', 'no', 'off', 'disabled', 'inactive'].contains(lower)) {
        return false;
      }
    }
    return null;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  static String _humanizeGroupKey(String key) {
    final cleaned = key.trim();
    if (cleaned.isEmpty) return 'More';

    return cleaned
        .split('_')
        .where((part) => part.trim().isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  static String _firstImageFromMaps(List<Map<String, String>> items) {
    for (final item in items) {
      final image = (item['image_url'] ?? '').trim();
      if (image.isNotEmpty) return image;
    }
    return '';
  }
}

Map<String, dynamic> _dxmDecodeJsonObject(String body) {
  final decoded = jsonDecode(body);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  if (decoded is Map) {
    return Map<String, dynamic>.from(decoded);
  }
  return const <String, dynamic>{};
}
