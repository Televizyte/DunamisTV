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

  static const String fallbackBannerUnitId =
      'ca-app-pub-4171224553175356/1750219844';
  static const String fallbackInterstitialUnitId =
      'ca-app-pub-4171224553175356/7855762495';
  static const String fallbackNativeUnitId =
      'ca-app-pub-4171224553175356/9731854705';

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
  DateTime _sessionStartedAt = DateTime.now();
  String? _loadedInterstitialPolicyKey;

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
    if (ads is! Map) return;

    _ads = ads.cast<String, dynamic>();

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

  int nativeEveryForPolicy(String policyKey) {
    return _readPositiveInt(
            _policyConfig(policyKey, 'native_config')['every']) ??
        0;
  }

  int nativeStartAfterForPolicy(String policyKey) {
    return _readNonNegativeInt(
            _policyConfig(policyKey, 'native_config')['start_after']) ??
        0;
  }

  int nativeMaxPerListForPolicy(String policyKey) {
    return _readNonNegativeInt(
            _policyConfig(policyKey, 'native_config')['max_per_list']) ??
        0;
  }

  Map<String, dynamic> _interstitialForPolicy(String policyKey) {
    return _policyConfig(policyKey, 'interstitial_config');
  }

  Duration interstitialCooldownForTab(String tabKey) {
    final resolved = _resolvePolicyForKey(tabKey);
    final config = _interstitialForPolicy(tabKey);
    final seconds = _readPositiveInt(config['cooldown_seconds']) ??
        _readPositiveInt(resolved?['cooldown']);
    return Duration(seconds: seconds ?? interstitialCooldown.inSeconds);
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
    final config = _policyConfig(tabKey, 'native_config');
    return _boolFromDynamic(config['enabled'], fallback: nativeInListEnabled);
  }

  bool shouldInsertNativeAfterItem({
    required String tabKey,
    required int itemIndex,
  }) {
    if (itemIndex < 0) return false;
    if (!nativeInListAllowedForTab(tabKey)) return false;

    final every = nativeEveryForPolicy(tabKey);
    if (every <= 0) return false;

    final configuredStart = nativeStartAfterForPolicy(tabKey);
    final startAfter = configuredStart < 1 ? 1 : configuredStart;
    final itemNumber = itemIndex + 1;

    if (itemNumber < startAfter) return false;

    return (itemNumber - startAfter) % every == 0;
  }

  String get bannerUnitId {
    if (kDebugMode) return debugBannerUnitId;

    final units = _ads['units'];
    if (units is Map) {
      final value = units['banner']?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }

    final global = _ads['global'];
    if (global is Map) {
      final value = global['banner_unit_id']?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }

    return fallbackBannerUnitId;
  }

  String get interstitialUnitId {
    if (kDebugMode) return debugInterstitialUnitId;

    final units = _ads['units'];
    if (units is Map) {
      final value = units['interstitial']?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }

    final global = _ads['global'];
    if (global is Map) {
      final value = global['interstitial_unit_id']?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }

    return fallbackInterstitialUnitId;
  }

  String get nativeUnitId {
    if (kDebugMode) return debugNativeUnitId;

    final units = _ads['units'];
    if (units is Map) {
      final value = units['native']?.toString().trim() ??
          units['native_advanced']?.toString().trim() ??
          '';
      if (value.isNotEmpty) return value;
    }

    final global = _ads['global'];
    if (global is Map) {
      final value = global['native_unit_id']?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }

    return fallbackNativeUnitId;
  }

  BannerAd? getBannerOrCreate({
    AdSize size = AdSize.banner,
  }) {
    if (kIsWeb) return null;
    if (!_adsEnabled()) return null;
    if (!_formatEnabled('banner')) return null;

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

  void preloadInterstitial({String? tabKey}) {
    unawaited(_preloadInterstitial(tabKey: tabKey));
  }

  Future<void> _preloadInterstitial({String? tabKey}) async {
    if (kIsWeb) return;
    if (!_adsEnabled()) return;
    if (!_formatEnabled('interstitial')) return;
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

    try {
      InterstitialAd.load(
        adUnitId: interstitialUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
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

    final canonicalPolicyKey = _canonicalPolicyKey(tabKey);
    final policyConfig = _interstitialForPolicy(canonicalPolicyKey);
    final everySafeActions =
        _readPositiveInt(policyConfig['every_n_safe_actions']) ?? 0;
    final minimumLaunchDelay =
        _readNonNegativeInt(policyConfig['minimum_launch_delay_seconds']) ?? 0;
    final maximumPerSession =
        _readNonNegativeInt(policyConfig['maximum_per_session']) ?? 0;

    if (DateTime.now().difference(_sessionStartedAt).inSeconds <
        minimumLaunchDelay) {
      logDecision('launch_delay');
      return;
    }
    if (maximumPerSession > 0 &&
        _interstitialShowsThisSession >= maximumPerSession) {
      logDecision('session_cap');
      return;
    }

    if (countAction) _safeActionCount++;

    if (everySafeActions <= 0 || _safeActionCount < everySafeActions) {
      logDecision('action_threshold');
      preloadInterstitial(tabKey: canonicalPolicyKey);
      return;
    }

    final now = DateTime.now();
    final effectiveCooldown = interstitialCooldownForTab(canonicalPolicyKey);
    if (_lastInterstitial != null &&
        now.difference(_lastInterstitial!) < effectiveCooldown) {
      logDecision('cooldown');
      preloadInterstitial(tabKey: tabKey);
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
      preloadInterstitial(tabKey: canonicalPolicyKey);

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

    logDecision('show');
    final completer = Completer<void>();
    _interstitial = null;
    _safeActionCount = 0;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        try {
          ad.dispose();
        } catch (_) {}
        _lastInterstitial = DateTime.now();
        _interstitialShowsThisSession++;
        _loadedInterstitialPolicyKey = null;
        preloadInterstitial(tabKey: canonicalPolicyKey);
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
        preloadInterstitial(tabKey: canonicalPolicyKey);
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
      preloadInterstitial(tabKey: tabKey);
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
    interstitialCooldown = const Duration(seconds: 60);
    interstitialEverySafeActions = 4;
    dispose();
  }

  void dispose() {
    try {
      _banner?.dispose();
    } catch (_) {}

    try {
      _interstitial?.dispose();
    } catch (_) {}

    _banner = null;
    _bannerSize = null;
    _interstitial = null;
    _loadingInterstitial = false;
    _activeLoads.clear();
    _formatBlockedUntil.clear();
    _placementLastAttempt.clear();
    _lastAnyAdAttempt = null;
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
