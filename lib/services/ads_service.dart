import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  /// Changes whenever a new backend ad-policy bootstrap is applied.
  ///
  /// Screens whose item structure depends on ad policy can listen to this
  /// without making AdsService itself a ChangeNotifier.
  final ValueNotifier<int> policyRevision = ValueNotifier<int>(0);

  // Official Google Android demo units. These are selected automatically in
  // Flutter debug builds, so development never requests live production ads.
  static const String debugBannerUnitId =
      'ca-app-pub-3940256099942544/9214589741';
  static const String debugInterstitialUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String debugNativeUnitId =
      'ca-app-pub-3940256099942544/2247696110';

  bool _initialized = false;
  bool _nativeRuntimeAvailable = true;

  // Global admission control prevents every visible ad widget from starting
  // its own network request at the same time. This is especially important on
  // older Android devices and slower mobile networks.
  DateTime? _adNetworkReadyAt;
  DateTime? _lastAnyAdAttempt;
  final Map<String, DateTime> _formatBlockedUntil = <String, DateTime>{};
  final Map<String, DateTime> _placementLastAttempt = <String, DateTime>{};
  final Map<String, int> _activeLoads = <String, int>{};

  static const Duration _startupAdDelay =
      kDebugMode ? Duration(seconds: 2) : Duration(seconds: 8);
  static const Duration _globalRequestSpacing = Duration(milliseconds: 1200);
  static const Duration _placementRequestSpacing = Duration(seconds: 8);

  Map<String, dynamic> _ads = <String, dynamic>{};
  Map<String, dynamic> _tabs = <String, dynamic>{};
  Map<String, dynamic> _formats = <String, dynamic>{};
  Map<String, dynamic> _nativeInList = <String, dynamic>{};
  Map<String, dynamic> _interstitialConfig = <String, dynamic>{};

  BannerAd? _banner;
  AdSize? _bannerSize;

  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;
  DateTime? _lastInterstitial;

  int _safeActionCount = 0;
  int _interstitialShowsThisSession = 0;
  int _interstitialRequestGeneration = 0;
  DateTime _sessionStartedAt = DateTime.now();
  String? _loadedInterstitialPolicyKey;
  String? _activeInterstitialPolicyKey;
  DateTime? _activeInterstitialPolicyEnteredAt;

  Duration interstitialCooldown = const Duration(seconds: 60);
  int interstitialEverySafeActions = 4;

  Future<void> init() async {
    if (_initialized) return;

    if (!kIsWeb) {
      try {
        await MobileAds.instance.initialize();
      } catch (_) {}
    }

    _sessionStartedAt = DateTime.now();
    _adNetworkReadyAt = DateTime.now().add(_startupAdDelay);
    _initialized = true;
  }

  Future<bool> acquireAdLoadSlot({
    required String format,
    required String placement,
  }) async {
    if (kIsWeb || !_adsEnabled() || !_formatEnabled(format)) return false;

    final readyAt = _adNetworkReadyAt;
    if (readyAt != null) {
      final wait = readyAt.difference(DateTime.now());
      if (wait > Duration.zero) await Future<void>.delayed(wait);
    }

    final now = DateTime.now();
    final blockedUntil = _formatBlockedUntil[format];
    if (blockedUntil != null && now.isBefore(blockedUntil)) return false;

    final active = _activeLoads[format] ?? 0;
    if (active >= 1) return false;

    final lastAny = _lastAnyAdAttempt;
    if (lastAny != null && now.difference(lastAny) < _globalRequestSpacing) {
      return false;
    }

    final lastPlacement = _placementLastAttempt[placement];
    if (lastPlacement != null &&
        now.difference(lastPlacement) < _placementRequestSpacing) {
      return false;
    }

    _activeLoads[format] = active + 1;
    _lastAnyAdAttempt = now;
    _placementLastAttempt[placement] = now;
    return true;
  }

  void releaseAdLoadSlot({
    required String format,
    required bool success,
    int? errorCode,
  }) {
    final active = _activeLoads[format] ?? 0;
    if (active <= 1) {
      _activeLoads.remove(format);
    } else {
      _activeLoads[format] = active - 1;
    }

    if (success) return;

    // 3 is normally no-fill. Network/internal failures need a longer quiet
    // period so they cannot create a synchronized retry storm.
    final cooldown = errorCode == 3
        ? const Duration(minutes: 2)
        : const Duration(minutes: 5);
    _formatBlockedUntil[format] = DateTime.now().add(cooldown);
  }

  void applyBootstrap(Map<String, dynamic> bootstrap) {
    final ads = bootstrap['ads'];
    if (!_isValidAdsContract(ads)) {
      clearBootstrap();
      return;
    }

    dispose();
    _ads = Map<String, dynamic>.from(ads as Map);

    final tabs = _ads['tabs'];
    _tabs = tabs is Map ? tabs.cast<String, dynamic>() : <String, dynamic>{};

    final formats = _ads['formats'];
    _formats =
        formats is Map ? formats.cast<String, dynamic>() : <String, dynamic>{};

    final nativeInList = _ads['native_in_list'];
    _nativeInList = nativeInList is Map
        ? nativeInList.cast<String, dynamic>()
        : <String, dynamic>{};

    final interstitial = _ads['interstitial'];
    _interstitialConfig = interstitial is Map
        ? interstitial.cast<String, dynamic>()
        : <String, dynamic>{};

    _applyGlobalInterstitialConfig();
    _activeInterstitialPolicyKey = null;
    _activeInterstitialPolicyEnteredAt = null;

    // Notify policy-dependent layouts after all effective settings have been
    // applied. Incrementing avoids suppressing repeated bootstrap refreshes.
    policyRevision.value = policyRevision.value + 1;

    if (!_adsEnabled()) {
      dispose();
    }
  }

  void _applyGlobalInterstitialConfig() {
    int? cooldown = _readPositiveInt(_interstitialConfig['cooldown_seconds']);

    cooldown ??= _readPositiveInt(_ads['cooldown_seconds']);
    cooldown ??= _readPositiveInt(_ads['cooldown']);

    if (cooldown != null) {
      interstitialCooldown = Duration(seconds: cooldown);
    }

    int? everySafeActions =
        _readPositiveInt(_interstitialConfig['every_n_safe_actions']);

    everySafeActions ??= _readPositiveInt(_ads['every_n_safe_actions']);
    everySafeActions ??= _readPositiveInt(_ads['interstitial_count']);
    everySafeActions ??= _readPositiveInt(_ads['safe_action_count']);

    if (everySafeActions != null) {
      interstitialEverySafeActions = everySafeActions;
    }

    if (interstitialEverySafeActions < 1) {
      interstitialEverySafeActions = 4;
    }
  }

  bool _adsEnabled() {
    return _boolFromDynamic(_ads['enabled'], fallback: false);
  }

  bool _formatEnabled(String key) {
    return _boolFromDynamic(_formats[key], fallback: false);
  }

  bool _tabAllowed(String tabKey, String type) {
    final resolved = _resolvePolicyForKey(tabKey);
    if (resolved == null) return false;

    if (_boolFromDynamic(resolved['enabled'], fallback: true) == false) {
      return false;
    }

    return _boolFromDynamic(resolved[type], fallback: false);
  }

  Map<String, dynamic>? _resolvePolicyForKey(String tabKey) {
    var key = _canonicalPolicyKey(tabKey);
    if (key.isEmpty) return null;

    Map<String, dynamic>? exactPolicy(String currentKey) {
      final tab = _tabs[currentKey];
      if (tab is Map) {
        return tab.cast<String, dynamic>();
      }
      return null;
    }

    final exact = exactPolicy(key);
    if (exact != null) return exact;

    while (key.contains('.')) {
      key = key.substring(0, key.lastIndexOf('.'));
      final parent = exactPolicy(key);
      if (parent != null) return parent;
    }

    return null;
  }

  /// Returns true only when the exact backend policy key exists.
  /// This is intentionally different from [_resolvePolicyForKey], which may
  /// fall back to a parent scope. Exact detection lets a screen select the
  /// most specific configured route even when that route is disabled.
  bool hasExactPolicy(String policyKey) {
    final key = _canonicalPolicyKey(policyKey);
    if (key.isEmpty) return false;
    return _tabs[key] is Map;
  }

  /// Selects the first exact backend policy key from [candidates].
  /// The selected key is returned even when its policy is disabled, so an
  /// explicit backend OFF rule cannot be bypassed by a broader fallback.
  String resolveConfiguredPolicyKey(
    Iterable<String> candidates, {
    required String fallback,
  }) {
    for (final candidate in candidates) {
      final key = _canonicalPolicyKey(candidate);
      if (key.isNotEmpty && hasExactPolicy(key)) return key;
    }
    return _canonicalPolicyKey(fallback);
  }

  String _canonicalPolicyKey(String value) {
    var key = value.trim().toLowerCase().replaceAll(':', '.');
    const aliases = <String, String>{
      'watch.video.player': 'watch.player.hls',
      'watch.youtube.playlist': 'watch.player.youtube',
      'explore.book.reader': 'explore.books.reader',
      'explore.short.videos': 'explore.shorts',
      'inspire.motivation.list': 'inspire.motivation',
      'inspire.wordification.list': 'inspire.wordification',
      'inspire.sod.list': 'inspire.sod',
    };
    key = aliases[key] ?? key;
    while (key.contains('..')) {
      key = key.replaceAll('..', '.');
    }
    return key.replaceAll(RegExp(r'^\.|\.$'), '');
  }

  Map<String, dynamic> _policyConfig(String policyKey, String configKey) {
    final policy = _resolvePolicyForKey(policyKey);
    final value = policy?[configKey];
    return value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};
  }

  dynamic _policyConfigValue(
    String policyKey,
    String configKey,
    String valueKey,
  ) {
    var key = _canonicalPolicyKey(policyKey);
    while (key.isNotEmpty) {
      final policy = _tabs[key];
      if (policy is Map) {
        final config = policy[configKey];
        if (config is Map && config.containsKey(valueKey)) {
          return config[valueKey];
        }
      }
      if (!key.contains('.')) break;
      key = key.substring(0, key.lastIndexOf('.'));
    }
    return null;
  }

  Map<String, dynamic> bannerConfigForPolicy(String policyKey) {
    return _policyConfig(policyKey, 'banner_config');
  }

  String bannerPlacementForPolicy(String policyKey) {
    return (bannerConfigForPolicy(policyKey)['placement'] ?? 'disabled')
        .toString()
        .trim()
        .toLowerCase();
  }

  bool bannerHideOnFailureForPolicy(String policyKey) {
    return _boolFromDynamic(
      bannerConfigForPolicy(policyKey)['hide_on_failure'],
      fallback: true,
    );
  }

  bool bannerReserveSpaceBeforeLoadForPolicy(String policyKey) {
    return _boolFromDynamic(
      bannerConfigForPolicy(policyKey)['reserve_space_before_load'],
      fallback: false,
    );
  }

  bool bannerAllowedForPlacement(String policyKey, String placement) {
    if (!bannerAllowedForTab(policyKey)) return false;
    if (!hasUnitForFormat('banner')) return false;
    return bannerPlacementForPolicy(policyKey) ==
        placement.trim().toLowerCase();
  }

  String resolveRoutePolicyKey(String location, {required String fallback}) {
    final uri = Uri.tryParse(location);
    final path = (uri?.path ?? location).trim().toLowerCase();
    final candidates = <String>[];

    void add(String key) {
      final canonical = _canonicalPolicyKey(key);
      if (canonical.isNotEmpty && !candidates.contains(canonical)) {
        candidates.add(canonical);
      }
    }

    if (path == '/account') add('more.account');
    if (path == '/saved') add('more.saved');
    if (path == '/downloads') add('more.downloads');
    if (path == '/notifications') add('more.notifications');
    if (path == '/notifications/message') add('more.notifications.message');
    if (path == '/more/technical-support') add('more.support');
    if (path == '/watch/channels') add('watch.channels');
    if (path == '/watch/videos') add('watch.video_list');
    if (path == '/live') add('watch.player.live');
    if (path == '/player/hls') add('watch.player.hls');
    if (path == '/player/youtube' || path == '/player/youtube-legacy') {
      add('watch.player.youtube');
    }
    if (path == '/watch/web') add('watch.player.web_embed');
    if (path == '/web') add('webview.active');
    if (path == '/sod') add('inspire.sod.watch');
    if (path == '/tools/books/chapter') add('explore.books.reader');
    if (path.startsWith('/games/race-of-faith')) {
      add('game.race_of_faith.active');
    }
    if (path.startsWith('/games/dominion-match')) {
      add('game.dominion_match.active');
    }
    if (path.startsWith('/games/kingdom-builder')) {
      add('game.kingdom_builder.active');
    }
    if (path.startsWith('/quiz/') || path == '/games/bible-quiz') {
      add('quiz.active');
    }
    if (path == '/short-videos') add('explore.shorts.player');
    if (path == '/tools/notes/editor' || path == '/tools/quote') {
      add('form.active');
    }

    final segments = path.split('/').where((part) => part.isNotEmpty).toList();
    if (segments.isNotEmpty) add(segments.join('.'));
    add(fallback);
    return resolveConfiguredPolicyKey(candidates, fallback: fallback);
  }

  int nativeEveryForPolicy(String policyKey) {
    return _readPositiveInt(
          _policyConfigValue(policyKey, 'native_config', 'every'),
        ) ??
        _readPositiveInt(_nativeInList['every']) ??
        0;
  }

  int nativeStartAfterForPolicy(String policyKey) {
    return _readNonNegativeInt(
          _policyConfigValue(policyKey, 'native_config', 'start_after'),
        ) ??
        _readNonNegativeInt(_nativeInList['start_after']) ??
        0;
  }

  int nativeMaxPerListForPolicy(String policyKey) {
    return _readNonNegativeInt(
          _policyConfigValue(policyKey, 'native_config', 'max_per_list'),
        ) ??
        _readNonNegativeInt(_nativeInList['max_per_list']) ??
        0;
  }

  Duration interstitialCooldownForTab(String tabKey) {
    final seconds = _readPositiveInt(_policyConfigValue(
          tabKey,
          'interstitial_config',
          'cooldown_seconds',
        )) ??
        _readPositiveInt(_interstitialConfig['cooldown_seconds']);
    return Duration(seconds: seconds ?? interstitialCooldown.inSeconds);
  }

  int interstitialEverySafeActionsForPolicy(String policyKey) {
    return _readPositiveInt(_policyConfigValue(
          policyKey,
          'interstitial_config',
          'every_n_safe_actions',
        )) ??
        _readPositiveInt(_interstitialConfig['every_n_safe_actions']) ??
        0;
  }

  int interstitialMinimumLaunchDelayForPolicy(String policyKey) {
    return _readNonNegativeInt(_policyConfigValue(
          policyKey,
          'interstitial_config',
          'minimum_launch_delay_seconds',
        )) ??
        _readNonNegativeInt(
          _interstitialConfig['minimum_launch_delay_seconds'],
        ) ??
        0;
  }

  int interstitialMaximumPerSessionForPolicy(String policyKey) {
    return _readNonNegativeInt(_policyConfigValue(
          policyKey,
          'interstitial_config',
          'maximum_per_session',
        )) ??
        _readNonNegativeInt(_interstitialConfig['maximum_per_session']) ??
        0;
  }

  int interstitialMinimumPageDwellForPolicy(String policyKey) {
    return _readNonNegativeInt(_policyConfigValue(
          policyKey,
          'interstitial_config',
          'minimum_page_dwell_seconds',
        )) ??
        _readNonNegativeInt(
          _interstitialConfig['minimum_page_dwell_seconds'],
        ) ??
        0;
  }

  void markInterstitialPolicyEntered(
    String policyKey, {
    DateTime? enteredAt,
    bool reset = false,
  }) {
    final canonicalKey = _canonicalPolicyKey(policyKey);
    if (canonicalKey.isEmpty) return;
    if (!reset &&
        _activeInterstitialPolicyKey == canonicalKey &&
        _activeInterstitialPolicyEnteredAt != null) {
      return;
    }
    _activeInterstitialPolicyKey = canonicalKey;
    _activeInterstitialPolicyEnteredAt = enteredAt ?? DateTime.now();
  }

  bool isInterstitialDwellSatisfied(
    String policyKey, {
    DateTime? now,
  }) {
    final canonicalKey = _canonicalPolicyKey(policyKey);
    final requiredSeconds = interstitialMinimumPageDwellForPolicy(canonicalKey);
    if (requiredSeconds <= 0) return true;
    if (_activeInterstitialPolicyKey != canonicalKey) return false;
    final enteredAt = _activeInterstitialPolicyEnteredAt;
    if (enteredAt == null) return false;
    return (now ?? DateTime.now()).difference(enteredAt).inSeconds >=
        requiredSeconds;
  }

  bool isInterstitialSessionCapReached(
    String policyKey, {
    int? shownCount,
  }) {
    final maximum = interstitialMaximumPerSessionForPolicy(policyKey);
    return maximum > 0 &&
        (shownCount ?? _interstitialShowsThisSession) >= maximum;
  }

  bool bannerAllowedForTab(String tabKey) {
    if (!_adsEnabled()) return false;
    if (!_formatEnabled('banner')) return false;
    return _tabAllowed(tabKey, 'banner');
  }

  bool interstitialAllowedForTab(String tabKey) {
    if (!_adsEnabled()) return false;
    if (!_formatEnabled('interstitial')) return false;
    return _tabAllowed(tabKey, 'interstitial');
  }

  bool get nativeRuntimeAvailable => _nativeRuntimeAvailable;

  void markNativeUnavailableForSession() {
    _nativeRuntimeAvailable = false;
  }

  bool nativeAllowedForTab(String tabKey) {
    if (!_nativeRuntimeAvailable) return false;
    if (!_adsEnabled()) return false;
    if (!_formatEnabled('native')) return false;
    return _tabAllowed(tabKey, 'native');
  }

  bool shellBannerEnabledForTab(String tabKey) {
    return bannerAllowedForTab(tabKey);
  }

  bool get nativeInListEnabled =>
      _boolFromDynamic(_nativeInList['enabled'], fallback: false);

  int get nativeEvery {
    final value = _readPositiveInt(_nativeInList['every']);
    return value ?? 6;
  }

  int get nativeStartAfter {
    final value = _readNonNegativeInt(_nativeInList['start_after']);
    return value ?? 4;
  }

  int get nativeMaxPerList {
    final value = _readNonNegativeInt(_nativeInList['max_per_list']);
    return value ?? 0; // 0 means unlimited.
  }

  bool nativeInListAllowedForTab(String tabKey) {
    if (!nativeAllowedForTab(tabKey)) return false;
    if (!hasUnitForFormat('native')) return false;
    return _boolFromDynamic(
      _policyConfigValue(tabKey, 'native_config', 'enabled'),
      fallback: nativeInListEnabled,
    );
  }

  bool shouldInsertNativeAfterItem({
    required String tabKey,
    required int itemIndex,
  }) {
    if (itemIndex < 0) return false;
    if (!nativeInListAllowedForTab(tabKey)) return false;

    final every = nativeEveryForPolicy(tabKey);
    if (every <= 0) return false;

    final startAfter = nativeStartAfterForPolicy(tabKey);
    final itemNumber = itemIndex + 1;
    final firstInsertionItemNumber = startAfter == 0 ? every : startAfter;

    if (itemNumber < firstInsertionItemNumber) return false;

    if ((itemNumber - firstInsertionItemNumber) % every != 0) return false;

    final maxPerList = nativeMaxPerListForPolicy(tabKey);
    if (maxPerList == 0) return true;
    final insertionNumber =
        ((itemNumber - firstInsertionItemNumber) ~/ every) + 1;
    return insertionNumber <= maxPerList;
  }

  String configuredUnitId(String format, {bool debug = kDebugMode}) {
    if (debug) {
      switch (format) {
        case 'banner':
          return debugBannerUnitId;
        case 'native':
          return debugNativeUnitId;
        case 'interstitial':
          return debugInterstitialUnitId;
      }
    }

    final units = _ads['units'];
    if (units is Map) {
      final value = units[format]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }

    final global = _ads['global'];
    if (global is Map) {
      final value = global['${format}_unit_id']?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }

    return '';
  }

  bool hasUnitForFormat(String format, {bool debug = kDebugMode}) {
    return configuredUnitId(format, debug: debug).isNotEmpty;
  }

  String get bannerUnitId {
    return configuredUnitId('banner');
  }

  String get interstitialUnitId {
    return configuredUnitId('interstitial');
  }

  String get nativeUnitId {
    return configuredUnitId('native');
  }

  BannerAd? getBannerOrCreate({
    AdSize size = AdSize.banner,
  }) {
    if (kIsWeb) return null;
    if (!_adsEnabled()) return null;
    if (!_formatEnabled('banner')) return null;
    if (!hasUnitForFormat('banner')) return null;

    final sameSize = _banner != null &&
        _bannerSize != null &&
        _bannerSize!.width == size.width &&
        _bannerSize!.height == size.height;

    if (sameSize) return _banner;

    try {
      _banner?.dispose();
    } catch (_) {}

    final ad = BannerAd(
      size: size,
      adUnitId: bannerUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, _) {
          try {
            ad.dispose();
          } catch (_) {}

          if (identical(_banner, ad)) {
            _banner = null;
            _bannerSize = null;
          }
        },
      ),
    );

    _banner = ad;
    _bannerSize = size;

    try {
      ad.load();
    } catch (_) {
      try {
        ad.dispose();
      } catch (_) {}
      _banner = null;
      _bannerSize = null;
      return null;
    }

    return ad;
  }

  BannerAd? getAdaptiveBannerOrCreate({
    required AdSize size,
  }) {
    return getBannerOrCreate(size: size);
  }

  void preloadInterstitial({String? tabKey, bool resetDwell = false}) {
    if (tabKey != null) {
      markInterstitialPolicyEntered(tabKey, reset: resetDwell);
    }
    unawaited(_preloadInterstitial(tabKey: tabKey));
  }

  Future<void> _preloadInterstitial({String? tabKey}) async {
    if (kIsWeb) return;
    if (!_adsEnabled()) return;
    if (!_formatEnabled('interstitial')) return;
    if (!hasUnitForFormat('interstitial')) return;
    if (tabKey != null && !interstitialAllowedForTab(tabKey)) return;
    if (_loadingInterstitial) return;
    if (_interstitial != null) return;

    final placement = 'interstitial:${tabKey ?? 'global'}';
    final acquired = await acquireAdLoadSlot(
      format: 'interstitial',
      placement: placement,
    );
    if (!acquired) return;

    _loadingInterstitial = true;
    final requestGeneration = _interstitialRequestGeneration;

    try {
      InterstitialAd.load(
        adUnitId: interstitialUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (requestGeneration != _interstitialRequestGeneration) {
              ad.dispose();
              return;
            }
            if (kDebugMode) {
              debugPrint(
                  '[AdsLoad] format=interstitial status=loaded policy=${tabKey ?? 'global'}');
            }
            releaseAdLoadSlot(format: 'interstitial', success: true);
            _interstitial = ad;
            _loadedInterstitialPolicyKey =
                tabKey == null ? null : _canonicalPolicyKey(tabKey);
            _loadingInterstitial = false;
          },
          onAdFailedToLoad: (error) {
            if (requestGeneration != _interstitialRequestGeneration) {
              return;
            }
            if (kDebugMode) {
              debugPrint(
                '[AdsLoadError] format=interstitial policy=${tabKey ?? 'global'} '
                'code=${error.code} domain=${error.domain} message=${error.message}',
              );
            }
            releaseAdLoadSlot(
              format: 'interstitial',
              success: false,
              errorCode: error.code,
            );
            _interstitial = null;
            _loadedInterstitialPolicyKey = null;
            _loadingInterstitial = false;
          },
        ),
      );
    } catch (_) {
      releaseAdLoadSlot(format: 'interstitial', success: false);
      _interstitial = null;
      _loadedInterstitialPolicyKey = null;
      _loadingInterstitial = false;
    }
  }

  Future<void> maybeShowInterstitialOnSafeNav(
    BuildContext context, {
    required String tabKey,
  }) async {
    await trackAndMaybeShowInterstitial(
      context,
      tabKey: tabKey,
      countAction: true,
    );
  }

  Future<void> trackAndMaybeShowInterstitial(
    BuildContext context, {
    required String tabKey,
    bool countAction = true,
  }) async {
    if (kIsWeb) return;

    final masterEnabled = _adsEnabled();
    final formatEnabled = _formatEnabled('interstitial');
    final placementAllowed = interstitialAllowedForTab(tabKey);

    void logDecision(String reason) {
      if (!kDebugMode) return;
      debugPrint(
        '[AdsDecision] format=interstitial policy=$tabKey reason=$reason '
        'master=$masterEnabled formatEnabled=$formatEnabled '
        'allowed=$placementAllowed count=$_safeActionCount '
        'required=$interstitialEverySafeActions ready=${_interstitial != null} '
        'loading=$_loadingInterstitial',
      );
    }

    if (!masterEnabled) {
      logDecision('master_off');
      return;
    }
    if (!formatEnabled) {
      logDecision('format_off');
      return;
    }
    if (!placementAllowed) {
      logDecision('placement_off');
      return;
    }
    if (!hasUnitForFormat('interstitial')) {
      logDecision('unit_unavailable');
      return;
    }

    final canonicalPolicyKey = _canonicalPolicyKey(tabKey);
    markInterstitialPolicyEntered(canonicalPolicyKey);
    final everySafeActions =
        interstitialEverySafeActionsForPolicy(canonicalPolicyKey);
    final minimumLaunchDelay =
        interstitialMinimumLaunchDelayForPolicy(canonicalPolicyKey);

    if (DateTime.now().difference(_sessionStartedAt).inSeconds <
        minimumLaunchDelay) {
      logDecision('launch_delay');
      return;
    }
    if (isInterstitialSessionCapReached(canonicalPolicyKey)) {
      logDecision('session_cap');
      return;
    }
    if (!isInterstitialDwellSatisfied(canonicalPolicyKey)) {
      logDecision('page_dwell');
      return;
    }

    if (countAction) _safeActionCount++;

    if (everySafeActions <= 0 || _safeActionCount < everySafeActions) {
      logDecision('action_threshold');
      preloadInterstitial(tabKey: canonicalPolicyKey, resetDwell: false);
      return;
    }

    final now = DateTime.now();
    final effectiveCooldown = interstitialCooldownForTab(canonicalPolicyKey);
    if (_lastInterstitial != null &&
        now.difference(_lastInterstitial!) < effectiveCooldown) {
      logDecision('cooldown');
      preloadInterstitial(tabKey: tabKey, resetDwell: false);
      return;
    }

    final currentAllowed = interstitialAllowedForTab(canonicalPolicyKey);
    if (!currentAllowed) {
      logDecision('pre_show_policy_off');
      _interstitial?.dispose();
      _interstitial = null;
      _loadedInterstitialPolicyKey = null;
      return;
    }

    var ad = _interstitial;
    if (ad == null || _loadedInterstitialPolicyKey != canonicalPolicyKey) {
      if (ad != null) {
        ad.dispose();
        _interstitial = null;
        _loadedInterstitialPolicyKey = null;
      }
      logDecision('not_ready_for_policy');
      preloadInterstitial(tabKey: canonicalPolicyKey, resetDwell: false);

      final deadline = DateTime.now().add(const Duration(seconds: 3));
      while (DateTime.now().isBefore(deadline) &&
          (_interstitial == null ||
              _loadedInterstitialPolicyKey != canonicalPolicyKey)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      final stillAllowed = interstitialAllowedForTab(canonicalPolicyKey);
      if (!stillAllowed) {
        _interstitial?.dispose();
        _interstitial = null;
        _loadedInterstitialPolicyKey = null;
        logDecision('pending_policy_off');
        return;
      }

      ad = _interstitial;
      if (ad == null || _loadedInterstitialPolicyKey != canonicalPolicyKey) {
        logDecision('pending_load_timeout');
        return;
      }
    }

    final preShowNow = DateTime.now();
    final currentEverySafeActions =
        interstitialEverySafeActionsForPolicy(canonicalPolicyKey);
    final currentCooldown = interstitialCooldownForTab(canonicalPolicyKey);
    final cooldownSatisfied = _lastInterstitial == null ||
        preShowNow.difference(_lastInterstitial!) >= currentCooldown;
    final eligibleImmediatelyBeforeShow = _adsEnabled() &&
        _formatEnabled('interstitial') &&
        hasUnitForFormat('interstitial') &&
        interstitialAllowedForTab(canonicalPolicyKey) &&
        currentEverySafeActions > 0 &&
        _safeActionCount >= currentEverySafeActions &&
        !isInterstitialSessionCapReached(canonicalPolicyKey) &&
        isInterstitialDwellSatisfied(canonicalPolicyKey) &&
        preShowNow.difference(_sessionStartedAt).inSeconds >=
            interstitialMinimumLaunchDelayForPolicy(canonicalPolicyKey) &&
        cooldownSatisfied;
    if (!eligibleImmediatelyBeforeShow) {
      ad.dispose();
      _interstitial = null;
      _loadedInterstitialPolicyKey = null;
      logDecision('pre_show_recheck_failed');
      return;
    }

    logDecision('show');
    final completer = Completer<void>();
    _interstitial = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _safeActionCount = 0;
      },
      onAdDismissedFullScreenContent: (ad) {
        try {
          ad.dispose();
        } catch (_) {}
        _lastInterstitial = DateTime.now();
        _interstitialShowsThisSession++;
        _loadedInterstitialPolicyKey = null;
        preloadInterstitial(tabKey: canonicalPolicyKey, resetDwell: false);
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        if (kDebugMode) {
          debugPrint(
            '[AdsShowError] format=interstitial policy=$tabKey '
            'code=${error.code} domain=${error.domain} message=${error.message}',
          );
        }
        try {
          ad.dispose();
        } catch (_) {}
        _loadedInterstitialPolicyKey = null;
        preloadInterstitial(tabKey: canonicalPolicyKey, resetDwell: false);
        if (!completer.isCompleted) completer.complete();
      },
    );

    try {
      ad.show();
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[AdsShowError] format=interstitial policy=$tabKey exception=$error',
        );
      }
      try {
        ad.dispose();
      } catch (_) {}
      preloadInterstitial(tabKey: tabKey, resetDwell: false);
      if (!completer.isCompleted) completer.complete();
    }

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        if (!completer.isCompleted) completer.complete();
      },
    );
  }

  void clearBootstrap() {
    _ads = <String, dynamic>{};
    _tabs = <String, dynamic>{};
    _formats = <String, dynamic>{};
    _nativeInList = <String, dynamic>{};
    _interstitialConfig = <String, dynamic>{};
    _safeActionCount = 0;
    _interstitialShowsThisSession = 0;
    _lastInterstitial = null;
    _loadedInterstitialPolicyKey = null;
    _activeInterstitialPolicyKey = null;
    _activeInterstitialPolicyEnteredAt = null;
    interstitialCooldown = const Duration(seconds: 60);
    interstitialEverySafeActions = 4;
    dispose();
    policyRevision.value = policyRevision.value + 1;
  }

  void dispose() {
    _interstitialRequestGeneration++;
    try {
      _banner?.dispose();
    } catch (_) {}

    try {
      _interstitial?.dispose();
    } catch (_) {}

    _banner = null;
    _bannerSize = null;
    _interstitial = null;
    _loadedInterstitialPolicyKey = null;
    _loadingInterstitial = false;
    _activeLoads.clear();
    _formatBlockedUntil.clear();
    _placementLastAttempt.clear();
    _lastAnyAdAttempt = null;
  }

  bool _isValidAdsContract(dynamic value) {
    if (!_isStringKeyedMap(value) || !_isBooleanLike(value['enabled'])) {
      return false;
    }

    final formats = value['formats'];
    final units = value['units'];
    final tabs = value['tabs'];
    final nativeInList = value['native_in_list'];
    final interstitial = value['interstitial'];
    if (!_isStringKeyedMap(formats) ||
        !_isStringKeyedMap(units) ||
        !_isStringKeyedMap(tabs) ||
        !_isStringKeyedMap(nativeInList) ||
        !_isStringKeyedMap(interstitial)) {
      return false;
    }

    for (final format in const ['banner', 'native', 'interstitial']) {
      if (!_isBooleanLike(formats[format]) || !units.containsKey(format)) {
        return false;
      }
      final unit = units[format];
      if (unit != null && unit is! String) return false;
    }

    for (final entry in tabs.entries) {
      final policy = entry.value;
      if (entry.key is! String || !_isStringKeyedMap(policy)) return false;
      for (final gate in const [
        'enabled',
        'banner',
        'native',
        'interstitial'
      ]) {
        if (!_isBooleanLike(policy[gate])) return false;
      }
      for (final config in const [
        'banner_config',
        'native_config',
        'interstitial_config',
      ]) {
        if (policy.containsKey(config) && !_isStringKeyedMap(policy[config])) {
          return false;
        }
      }
    }
    return true;
  }

  bool _isStringKeyedMap(dynamic value) {
    return value is Map && value.keys.every((key) => key is String);
  }

  bool _isBooleanLike(dynamic value) {
    if (value is bool || value is num) return true;
    if (value is String) {
      const accepted = {'true', 'false', '1', '0', 'yes', 'no', 'on', 'off'};
      return accepted.contains(value.trim().toLowerCase());
    }
    return false;
  }

  @visibleForTesting
  void setInterstitialSessionCountForTesting(int value) {
    _interstitialShowsThisSession = value < 0 ? 0 : value;
  }

  bool _boolFromDynamic(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1' || v == 'yes' || v == 'on') return true;
      if (v == 'false' || v == '0' || v == 'no' || v == 'off') return false;
    }
    return fallback;
  }

  int? _readPositiveInt(dynamic value) {
    final parsed = _readInt(value);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  int? _readNonNegativeInt(dynamic value) {
    final parsed = _readInt(value);
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
