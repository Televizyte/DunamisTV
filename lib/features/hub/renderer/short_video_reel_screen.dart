import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../app_config.dart';
import '../../../ui/widgets/ads/native_inline_ad_tile.dart';
import '../../../ui/widgets/banner_ad_widget.dart';
import '../../../services/ads_service.dart';
import '../../../services/auth_action_gate.dart';
import '../../../services/content_engagement_service.dart';
import '../models/short_video_item.dart';
import '../state/hub_scope.dart';
import '../services/short_video_engagement_service.dart';
import 'short_video_local_store.dart';
import 'short_video_mapper.dart';

class ShortVideoReelScreen extends StatefulWidget {
  final List<ShortVideoItem> items;
  final int initialIndex;
  final String initialItemId;
  final String initialChannelKey;
  final String title;

  const ShortVideoReelScreen({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.initialItemId = '',
    this.initialChannelKey = '',
    this.title = 'Short Videos',
  });

  @override
  State<ShortVideoReelScreen> createState() => _ShortVideoReelScreenState();
}

class _ShortVideoReelScreenState extends State<ShortVideoReelScreen> {
  static const String _shortVideoFallbackAdsKey = 'shorts';

  late final PageController _pageController;
  late List<ShortVideoItem> _items;
  late int _activeIndex;

  final ShortVideoLocalStore _localStore = const ShortVideoLocalStore();
  bool _isMuted = true;
  Set<String> _favoriteIds = <String>{};
  Set<String> _likedIds = <String>{};
  bool _didLoadHubFallback = false;
  bool _libraryOpen = false;

  @override
  void initState() {
    super.initState();
    AdsService.instance.policyRevision.addListener(_handleAdsPolicyChanged);
    WakelockPlus.enable();
    _items = _preferredChannelItems(_visibleItems(widget.items));
    _activeIndex = _resolveInitialIndex(_items, widget.initialIndex);
    _pageController =
        PageController(initialPage: _videoIndexToPageIndex(_activeIndex));
    _loadLocalState();
    _markActiveWatched();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didLoadHubFallback || _items.isNotEmpty) return;

    _didLoadHubFallback = true;

    final hub = HubScope.maybeOf(context);
    final rawHub = hub?.raw ?? const <String, dynamic>{};
    final fallbackItems = _visibleItems(ShortVideoMapper.fromRawHub(rawHub));
    final targetedItems = _preferredChannelItems(fallbackItems);

    if (targetedItems.isEmpty) return;

    final fallbackIndex =
        _resolveInitialIndex(targetedItems, widget.initialIndex);

    setState(() {
      _items = targetedItems;
      _activeIndex = fallbackIndex;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pageController.hasClients) return;
      _pageController.jumpToPage(_videoIndexToPageIndex(fallbackIndex));
    });

    _markActiveWatched();
  }

  @override
  void didUpdateWidget(covariant ShortVideoReelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items == widget.items &&
        oldWidget.initialIndex == widget.initialIndex &&
        oldWidget.initialItemId == widget.initialItemId &&
        oldWidget.initialChannelKey == widget.initialChannelKey) return;
    final nextItems = _preferredChannelItems(_visibleItems(widget.items));
    final nextIndex = _resolveInitialIndex(nextItems, widget.initialIndex);
    setState(() {
      _items = nextItems;
      _activeIndex = nextIndex;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pageController.hasClients) return;
      _pageController.jumpToPage(_videoIndexToPageIndex(nextIndex));
    });
    _markActiveWatched();
  }

  List<ShortVideoItem> _preferredChannelItems(List<ShortVideoItem> items) {
    if (items.isEmpty) return items;

    final channelKey = _normalizeKey(widget.initialChannelKey);
    if (channelKey.isEmpty) return items;

    final matched = items
        .where((item) => _matchesChannel(item, channelKey))
        .toList(growable: false);
    if (matched.isNotEmpty) return matched;

    return items;
  }

  bool _matchesChannel(ShortVideoItem item, String channelKey) {
    final raw = item.raw;
    final values = <String>{
      raw['channel']?.toString() ?? '',
      raw['channel_key']?.toString() ?? '',
      raw['short_channel']?.toString() ?? '',
      raw['short_channel_key']?.toString() ?? '',
      raw['placement']?.toString() ?? '',
      raw['_section_key']?.toString() ?? '',
      raw['_section_title']?.toString() ?? '',
      raw['_section_subtitle']?.toString() ?? '',
      raw['_section_type']?.toString() ?? '',
      raw['_section_layout']?.toString() ?? '',
      raw['_section_tab_key']?.toString() ?? '',
      raw['_section_route_key']?.toString() ?? '',
      raw['_section_source_channel']?.toString() ?? '',
      raw['_source_channel']?.toString() ?? '',
      raw['source_channel']?.toString() ?? '',
    };

    final source = raw['source'];
    if (source is Map) {
      values.add(source['channel']?.toString() ?? '');
      values.add(source['channel_key']?.toString() ?? '');
      values.add(source['source_channel']?.toString() ?? '');
      values.add(source['short_channel_key']?.toString() ?? '');
      values.add(source['bucket']?.toString() ?? '');
    }

    final sectionSettings = raw['_section_settings'];
    if (sectionSettings is Map) {
      values.add(sectionSettings['channel']?.toString() ?? '');
      values.add(sectionSettings['channel_key']?.toString() ?? '');
      values.add(sectionSettings['source_channel']?.toString() ?? '');
      values.add(sectionSettings['short_channel_key']?.toString() ?? '');
    }

    final payload = raw['payload'];
    if (payload is Map) {
      values.add(payload['channel']?.toString() ?? '');
      values.add(payload['channel_key']?.toString() ?? '');
      values.add(payload['short_channel']?.toString() ?? '');
      values.add(payload['short_channel_key']?.toString() ?? '');
    }

    final meta = raw['meta'];
    if (meta is Map) {
      values.add(meta['channel']?.toString() ?? '');
      values.add(meta['channel_key']?.toString() ?? '');
      values.add(meta['short_channel']?.toString() ?? '');
      values.add(meta['short_channel_key']?.toString() ?? '');
    }

    for (final value in values) {
      final clean = _normalizeKey(value);
      if (clean.isEmpty) continue;
      if (clean == channelKey) return true;
      if (clean.contains(channelKey) || channelKey.contains(clean)) return true;
    }

    return false;
  }

  String _normalizeKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  int _resolveInitialIndex(List<ShortVideoItem> items, int fallbackIndex) {
    final target = widget.initialItemId.trim();
    if (target.isNotEmpty) {
      final found =
          items.indexWhere((item) => _matchesTargetItem(item, target));
      if (found >= 0) return found;
    }
    return _safeInitialIndex(items, fallbackIndex);
  }

  bool _matchesTargetItem(ShortVideoItem item, String rawTarget) {
    final target = rawTarget.trim();
    if (target.isEmpty) return false;

    final raw = item.raw;
    final candidates = <String>{
      item.id,
      item.safeId,
      raw['id']?.toString() ?? '',
      raw['key']?.toString() ?? '',
      raw['content_id']?.toString() ?? '',
      raw['post_id']?.toString() ?? '',
      raw['slug']?.toString() ?? '',
      raw['video_id']?.toString() ?? '',
      raw['item_id']?.toString() ?? '',
    };

    final payload = raw['payload'];
    if (payload is Map) {
      candidates.add(payload['id']?.toString() ?? '');
      candidates.add(payload['content_id']?.toString() ?? '');
      candidates.add(payload['post_id']?.toString() ?? '');
      candidates.add(payload['slug']?.toString() ?? '');
      candidates.add(payload['video_id']?.toString() ?? '');
      candidates.add(payload['item_id']?.toString() ?? '');
    }

    final meta = raw['meta'];
    if (meta is Map) {
      candidates.add(meta['id']?.toString() ?? '');
      candidates.add(meta['content_id']?.toString() ?? '');
      candidates.add(meta['post_id']?.toString() ?? '');
      candidates.add(meta['slug']?.toString() ?? '');
      candidates.add(meta['video_id']?.toString() ?? '');
      candidates.add(meta['item_id']?.toString() ?? '');
    }

    for (final candidate in candidates) {
      final clean = candidate.trim();
      if (clean.isEmpty) continue;
      if (clean == target || clean == 'short_video_$target') return true;
      if (target == 'short_video_$clean') return true;
    }

    return false;
  }

  Iterable<Map<String, dynamic>> _shortVideoSettingsCandidates() sync* {
    final seen = <int>{};

    final active =
        (_items.isNotEmpty && _activeIndex >= 0 && _activeIndex < _items.length)
            ? _items[_activeIndex]
            : null;

    final rawItems = <Map<String, dynamic>>[
      if (active != null) active.raw,
      if (_items.isNotEmpty) _items.first.raw,
    ];

    for (final raw in rawItems) {
      final candidates = <Map<String, dynamic>>[];

      void addMap(Object? value) {
        if (value is Map) {
          final identity = identityHashCode(value);
          if (!seen.add(identity)) return;
          candidates.add(
            value.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
      }

      addMap(raw['_section_settings']);
      addMap(raw['settings']);
      addMap(raw['meta']);
      final payload = raw['payload'];
      if (payload is Map) {
        addMap(payload['settings']);
        addMap(payload['meta']);
        addMap(payload);
      }
      for (final candidate in candidates) {
        yield candidate;
      }
    }
  }

  Object? _shortVideoSettingValue(List<String> keys) {
    final normalizedKeys = keys.map(_normalizeKey).toSet();

    for (final settings in _shortVideoSettingsCandidates()) {
      for (final entry in settings.entries) {
        if (normalizedKeys.contains(_normalizeKey(entry.key))) {
          return entry.value;
        }
      }
    }

    return null;
  }

  bool _shortVideoBoolSetting(List<String> keys, bool fallback) {
    final value = _shortVideoSettingValue(keys);
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) return fallback;
    if (['1', 'true', 'yes', 'on', 'enabled', 'enable'].contains(text)) {
      return true;
    }
    if (['0', 'false', 'no', 'off', 'disabled', 'disable'].contains(text)) {
      return false;
    }

    return fallback;
  }

  int _shortVideoIntSetting(List<String> keys, int fallback) {
    final value = _shortVideoSettingValue(keys);
    if (value == null) return fallback;
    if (value is num) return value.round();

    return int.tryParse(value.toString().trim()) ?? fallback;
  }

  bool get _loopCurrentVideo => _shortVideoBoolSetting(
        ['loop_current_video', 'loop_video', 'repeat_current_video'],
        false,
      );

  bool get _autoScrollNext => _shortVideoBoolSetting(
        ['auto_scroll_next', 'auto_scroll_to_next', 'advance_to_next'],
        true,
      );

  bool get _backendShowNativeAds => _shortVideoBoolSetting(
        ['show_native_ads', 'native_ads_enabled', 'enable_native_ads'],
        false,
      );

  bool get _backendShowBannerAds => _shortVideoBoolSetting(
        ['show_banner_ads', 'banner_ads_enabled', 'enable_banner_ads'],
        true,
      );

  int get _configuredNativeAdInterval => AdsService.instance.nativeEvery;

  int get _configuredNativeStartAfter =>
      AdsService.instance.nativeStartAfter < 1
          ? 1
          : AdsService.instance.nativeStartAfter;

  bool get _canRenderRealAdSlots => true;

  Map<String, dynamic>? get _activeRaw {
    if (_items.isEmpty || _activeIndex < 0 || _activeIndex >= _items.length) {
      return null;
    }
    return _items[_activeIndex].raw;
  }

  String _rawString(Map<String, dynamic>? raw, String key) {
    return raw?[key]?.toString().trim() ?? '';
  }

  String get _resolvedAdsPolicyKey {
    return AdsService.instance.resolveConfiguredPolicyKey(
      const <String>[
        'shorts.reel',
        'shorts.player',
        'shorts',
        'explore.shorts',
        'inspire.short_videos',
        'home.short_videos',
      ],
      fallback: _shortVideoFallbackAdsKey,
    );
  }

  bool get _showNativeAdSlots {
    if (!_canRenderRealAdSlots) return false;
    return AdsService.instance.nativeInListAllowedForTab(_resolvedAdsPolicyKey);
  }

  bool get _showBannerAdSlot {
    if (!_canRenderRealAdSlots || _libraryOpen) return false;
    return AdsService.instance.bannerAllowedForTab(_resolvedAdsPolicyKey);
  }

  void _handleAdsPolicyChanged() {
    if (!mounted) return;

    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients || _items.isEmpty) return;
      final targetPage = _videoIndexToPageIndex(_activeIndex);
      final currentPage = _pageController.page?.round();
      if (currentPage != targetPage) {
        _pageController.jumpToPage(targetPage);
      }
    });
  }

  @override
  void dispose() {
    AdsService.instance.policyRevision.removeListener(_handleAdsPolicyChanged);
    WakelockPlus.disable();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalState() async {
    final favorites = await _localStore.loadFavoriteIds();
    final likes = await _localStore.loadLikedIds();
    if (!mounted) return;
    setState(() {
      _favoriteIds = favorites;
      _likedIds = likes;
    });
  }

  Future<void> _markActiveWatched() async {
    if (_items.isEmpty || _activeIndex < 0 || _activeIndex >= _items.length) {
      return;
    }

    final item = _items[_activeIndex];
    await _localStore.markWatched(item.safeId);

    ShortVideoEngagementService.instance.trackWatch(item);
  }

  static List<ShortVideoItem> _visibleItems(List<ShortVideoItem> items) {
    return items
        .where((item) => item.enabled && item.hasVideo)
        .toList(growable: false);
  }

  static int _safeInitialIndex(List<ShortVideoItem> items, int index) {
    if (items.isEmpty || index < 0) return 0;
    if (index >= items.length) return items.length - 1;
    return index;
  }

  int _nativeAdsBeforeVideoIndex(int videoIndex) {
    if (!_showNativeAdSlots || videoIndex <= 0) return 0;

    var count = 0;
    for (var itemIndex = 0; itemIndex < videoIndex; itemIndex++) {
      if (AdsService.instance.shouldInsertNativeAfterItem(
        tabKey: _resolvedAdsPolicyKey,
        itemIndex: itemIndex,
      )) {
        count++;
      }
    }
    return count;
  }

  int _videoIndexToPageIndex(int videoIndex) {
    if (videoIndex <= 0) return videoIndex < 0 ? 0 : videoIndex;
    return videoIndex + _nativeAdsBeforeVideoIndex(videoIndex);
  }

  List<_ShortVideoPageEntry> _buildPageEntries() {
    final entries = <_ShortVideoPageEntry>[];
    for (var i = 0; i < _items.length; i++) {
      entries.add(_ShortVideoPageEntry.video(index: i, item: _items[i]));
      if (_showNativeAdSlots &&
          AdsService.instance.shouldInsertNativeAfterItem(
            tabKey: _resolvedAdsPolicyKey,
            itemIndex: i,
          )) {
        entries.add(_ShortVideoPageEntry.nativeAd(afterVideoIndex: i));
      }
    }
    return entries;
  }

  Future<void> _openLibrary() async {
    if (_libraryOpen) return;
    setState(() => _libraryOpen = true);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ShortVideoLibrarySheet(
          items: _items,
          activeIndex: _activeIndex,
          favoriteIds: _favoriteIds,
          onSelected: (index) {
            Navigator.of(context).pop();
            final safeIndex = _safeInitialIndex(_items, index);
            setState(() => _activeIndex = safeIndex);
            if (_pageController.hasClients) {
              _pageController.animateToPage(
                _videoIndexToPageIndex(safeIndex),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
              );
            }
            _markActiveWatched();
          },
          onToggleFavorite: _toggleFavoriteById,
          adsPolicyKey: _resolvedAdsPolicyKey,
        );
      },
    );
    if (mounted) setState(() => _libraryOpen = false);
  }

  Future<void> _toggleLiked(ShortVideoItem item) async =>
      _toggleLikedById(item.safeId);

  Future<void> _toggleLikedById(String id) async {
    final ids = await _localStore.toggleLiked(id);
    if (!mounted) return;
    setState(() => _likedIds = ids);
  }

  Future<void> _toggleFavorite(ShortVideoItem item) async =>
      _toggleFavoriteById(item.safeId);

  Future<void> _toggleFavoriteById(String id) async {
    final ids = await _localStore.toggleFavorite(id);
    ShortVideoItem? item;

    for (final video in _items) {
      if (video.safeId == id) {
        item = video;
        break;
      }
    }

    if (item != null) {
      ShortVideoEngagementService.instance.toggleFavorite(
        item,
        isFavorite: ids.contains(id),
      );
    }

    if (!mounted) return;
    setState(() => _favoriteIds = ids);
  }

  Future<void> _advanceToNextVideo() async {
    if (!_autoScrollNext || _items.isEmpty) return;

    final nextVideoIndex = _activeIndex + 1;
    if (nextVideoIndex >= _items.length) {
      if (_loopCurrentVideo) return;
      return;
    }

    final nextPageIndex = _videoIndexToPageIndex(nextVideoIndex);

    if (_pageController.hasClients) {
      await _pageController.animateToPage(
        nextPageIndex,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
      );
    } else if (mounted) {
      setState(() => _activeIndex = nextVideoIndex);
    }

    if (mounted) {
      setState(() => _activeIndex = nextVideoIndex);
    }

    await _markActiveWatched();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(widget.title)),
        body: const Center(
            child: Text('No short videos available.',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800))),
      );
    }

    final entries = _buildPageEntries();
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: _showBannerAdSlot
          ? SafeArea(
              top: false,
              child: BannerAdWidget(
                tabKey: _resolvedAdsPolicyKey,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              ),
            )
          : null,
      body: Stack(
        children: [
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: IconButton.filledTonal(
                tooltip: 'Browse Shorts',
                onPressed: () => context.push(
                  '/short-videos/library?channel=${Uri.encodeQueryComponent(widget.initialChannelKey)}',
                ),
                icon: const Icon(Icons.video_library_rounded),
              ),
            ),
          ),
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(),
              itemCount: entries.length,
              onPageChanged: (pageIndex) {
                final entry = entries[pageIndex];
                if (!entry.isVideo) return;
                setState(() => _activeIndex = entry.videoIndex);
                _markActiveWatched();
              },
              itemBuilder: (context, pageIndex) {
                final entry = entries[pageIndex];
                if (entry.isNativeAd) {
                  return _ShortVideoNativeAdPage(
                    bottomContentInset: 0,
                    tabKey: _resolvedAdsPolicyKey,
                  );
                }
                final item = entry.item!;
                return ShortVideoReelPage(
                  item: item,
                  isActive: entry.videoIndex == _activeIndex,
                  isMuted: _isMuted,
                  isFavorite: _favoriteIds.contains(item.safeId),
                  isLiked: _likedIds.contains(item.safeId),
                  bottomContentInset: 0,
                  onMutedChanged: (muted) => setState(() => _isMuted = muted),
                  loopCurrentVideo: _loopCurrentVideo,
                  autoScrollNext: _autoScrollNext,
                  onVideoComplete: _advanceToNextVideo,
                  onShowLibrary: _openLibrary,
                  onToggleFavorite: () => _toggleFavorite(item),
                  onToggleLiked: () => _toggleLiked(item),
                );
              },
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white)),
                Expanded(
                  child: Text(widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900)),
                ),
                Text('${_activeIndex + 1}/${_items.length}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
                IconButton(
                    tooltip: 'Open library',
                    onPressed: _openLibrary,
                    icon: const Icon(Icons.grid_view_rounded,
                        color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortVideoPageEntry {
  final ShortVideoItem? item;
  final int videoIndex;
  final bool isNativeAd;

  const _ShortVideoPageEntry._(
      {required this.item, required this.videoIndex, required this.isNativeAd});
  factory _ShortVideoPageEntry.video(
          {required int index, required ShortVideoItem item}) =>
      _ShortVideoPageEntry._(item: item, videoIndex: index, isNativeAd: false);
  factory _ShortVideoPageEntry.nativeAd({required int afterVideoIndex}) =>
      _ShortVideoPageEntry._(
          item: null, videoIndex: afterVideoIndex, isNativeAd: true);
  bool get isVideo => !isNativeAd;
}

class ShortVideoReelPage extends StatefulWidget {
  final ShortVideoItem item;
  final bool isActive;
  final bool isMuted;
  final bool isFavorite;
  final bool isLiked;
  final double bottomContentInset;
  final bool loopCurrentVideo;
  final bool autoScrollNext;
  final ValueChanged<bool> onMutedChanged;
  final VoidCallback onVideoComplete;
  final VoidCallback onShowLibrary;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleLiked;

  const ShortVideoReelPage({
    super.key,
    required this.item,
    required this.isActive,
    required this.isMuted,
    required this.isFavorite,
    required this.isLiked,
    required this.bottomContentInset,
    required this.loopCurrentVideo,
    required this.autoScrollNext,
    required this.onMutedChanged,
    required this.onVideoComplete,
    required this.onShowLibrary,
    required this.onToggleFavorite,
    required this.onToggleLiked,
  });

  @override
  State<ShortVideoReelPage> createState() => _ShortVideoReelPageState();
}

class _ShortVideoReelPageState extends State<ShortVideoReelPage> {
  VideoPlayerController? _controller;
  bool _isReady = false;
  bool _showControls = true;
  bool _isSeeking = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _didComplete = false;
  Object? _error;
  Timer? _controlsHideTimer;
  DateTime _lastPointerActivity = DateTime.fromMillisecondsSinceEpoch(0);
  int _likesCount = 0;
  int _commentsCount = 0;
  int _savesCount = 0;
  bool? _likedOverride;
  bool? _savedOverride;

  bool get _effectiveLiked => _likedOverride ?? widget.isLiked;
  bool get _effectiveSaved => _savedOverride ?? widget.isFavorite;

  bool get _isPlaying => _controller?.value.isPlaying == true;

  bool get _chromeVisible =>
      _showControls ||
      !widget.isActive ||
      !_isPlaying ||
      _isSeeking ||
      _error != null;

  @override
  void initState() {
    super.initState();
    _likesCount = _readCount(const ['likes_count', 'like_count']);
    _commentsCount = _readCount(const ['comments_count', 'comment_count']);
    _savesCount = _readCount(const ['saves_count', 'save_count']);
    _prepare();
  }

  int _readCount(List<String> keys) {
    final raw = widget.item.raw;
    final payload = raw['payload'];
    final engagement = payload is Map ? payload['engagement'] : null;

    for (final key in keys) {
      final candidates = <Object?>[
        raw[key],
        if (payload is Map) payload[key],
        if (engagement is Map) engagement[key],
      ];
      for (final value in candidates) {
        if (value is num) return value.toInt();
        final parsed = int.tryParse(value?.toString() ?? '');
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  @override
  void didUpdateWidget(covariant ShortVideoReelPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.videoUrl != widget.item.videoUrl) {
      _disposeController();
      _prepare();
      return;
    }
    if (oldWidget.isMuted != widget.isMuted) _applyVolume();
    if (oldWidget.loopCurrentVideo != widget.loopCurrentVideo) {
      _controller?.setLooping(widget.loopCurrentVideo);
    }
    if (oldWidget.isActive != widget.isActive) {
      _didComplete = false;
      if (widget.isActive) {
        _showControls = true;
      }
      _syncPlayback();
    }
  }

  Future<void> _prepare() async {
    final url = widget.item.videoUrl.trim();
    if (!_isPlayableUrl(url)) return;
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = controller;
      await controller.initialize();
      controller.addListener(_handleProgress);
      await controller.setLooping(widget.loopCurrentVideo);
      await controller.setVolume(widget.isMuted ? 0 : 1);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _isReady = true;
        _error = null;
        _duration = controller.value.duration;
        _position = controller.value.position;
      });
      _syncPlayback();
      _scheduleControlsAutoHide();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _isReady = false;
      });
    }
  }

  void _handleProgress() {
    final controller = _controller;

    if (controller == null || !mounted || _isSeeking) {
      return;
    }

    final value = controller.value;

    if (!value.isInitialized) {
      return;
    }

    final nextPosition = value.position;
    final nextDuration = value.duration;

    final isFinished = nextDuration.inMilliseconds > 0 &&
        nextPosition.inMilliseconds >= nextDuration.inMilliseconds - 220;

    if (isFinished &&
        widget.isActive &&
        widget.autoScrollNext &&
        !widget.loopCurrentVideo &&
        !_didComplete) {
      _didComplete = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onVideoComplete();
      });
    }

    if (nextPosition.inMilliseconds == _position.inMilliseconds &&
        nextDuration.inMilliseconds == _duration.inMilliseconds) {
      return;
    }

    setState(() {
      _position = nextPosition;
      _duration = nextDuration;
    });
  }

  Future<void> _seekToFraction(double fraction) async {
    final controller = _controller;

    if (controller == null || !_isReady || _duration.inMilliseconds <= 0) {
      return;
    }

    final clamped = fraction.clamp(0.0, 1.0);
    final target = Duration(
      milliseconds: (_duration.inMilliseconds * clamped).round(),
    );

    setState(() {
      _position = target;
    });

    _didComplete = false;
    await controller.seekTo(target);

    if (widget.isActive) {
      await controller.play();
    }
  }

  String _formatDuration(Duration value) {
    final totalSeconds = value.inSeconds < 0 ? 0 : value.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _applyVolume() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.setVolume(widget.isMuted ? 0 : 1);
  }

  void _syncPlayback() {
    final controller = _controller;
    if (controller == null || !_isReady) return;
    if (widget.isActive) {
      if (_didComplete && !widget.loopCurrentVideo) return;
      controller.play();
      _scheduleControlsAutoHide();
    } else {
      controller.pause();
      _controlsHideTimer?.cancel();
    }
  }

  void _scheduleControlsAutoHide() {
    _controlsHideTimer?.cancel();
    if (!mounted || !widget.isActive || !_isPlaying || _isSeeking) {
      return;
    }
    _controlsHideTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || !widget.isActive || !_isPlaying || _isSeeking) {
        return;
      }
      setState(() => _showControls = false);
    });
  }

  void _showChromeTemporarily() {
    if (!mounted) return;
    _controlsHideTimer?.cancel();
    if (!_showControls) {
      setState(() => _showControls = true);
    }
    _scheduleControlsAutoHide();
  }

  void _handlePointerActivity() {
    final now = DateTime.now();
    if (_showControls &&
        now.difference(_lastPointerActivity).inMilliseconds < 220) {
      return;
    }

    _lastPointerActivity = now;
    _showChromeTemporarily();
  }

  void _runWithVisibleChrome(VoidCallback action) {
    _showChromeTemporarily();
    action();
    _scheduleControlsAutoHide();
  }

  void _handleSurfaceTap() {
    _showChromeTemporarily();
  }

  @override
  void dispose() {
    _controlsHideTimer?.cancel();
    unawaited(_disposeController());
    super.dispose();
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    _isReady = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _didComplete = false;

    if (controller == null) return;

    controller.removeListener(_handleProgress);
    await controller.dispose();
  }

  bool _isPlayableUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null || !_isReady) {
      _showChromeTemporarily();
      return;
    }

    if (controller.value.isPlaying) {
      controller.pause();
      _controlsHideTimer?.cancel();
      setState(() => _showControls = true);
      return;
    }

    _didComplete = false;
    controller.play();
    setState(() => _showControls = true);
    _scheduleControlsAutoHide();
  }

  Future<void> _toggleMute() async {
    final nextMuted = !widget.isMuted;
    widget.onMutedChanged(nextMuted);
    final controller = _controller;
    if (controller != null) await controller.setVolume(nextMuted ? 0 : 1);
  }

  String get _interactionPostId {
    final raw = widget.item.raw;
    final payload = raw['payload'];
    final action = raw['action'];
    final candidates = <Object?>[
      raw['content_id'],
      raw['post_id'],
      raw['slug'],
      if (payload is Map) payload['content_id'],
      if (payload is Map) payload['post_id'],
      if (payload is Map) payload['slug'],
      if (action is Map) action['content_id'],
      if (action is Map) action['post_id'],
      if (action is Map) action['slug'],
    ];
    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isEmpty) continue;
      if (value.startsWith('short_video_')) {
        return value.substring('short_video_'.length);
      }
      return value;
    }
    final fallback = widget.item.safeId.trim();
    if (fallback.startsWith('short_video_')) {
      return fallback.substring('short_video_'.length);
    }
    return fallback;
  }

  Future<void> _toggleBackendLike() async {
    final nextLike = !_effectiveLiked;
    try {
      final response = await ContentEngagementService.instance.setLike(
        _interactionPostId,
        like: nextLike,
      );
      if (mounted) {
        setState(() {
          _likedOverride = response['liked'] == true;
          _likesCount =
              (response['likes_count'] as num?)?.toInt() ?? _likesCount;
        });
      }
      widget.onToggleLiked();
    } on EngagementAuthRequiredException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to like this video.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Like update failed: $error')),
      );
    }
  }

  Future<void> _toggleBackendSave() async {
    final nextSaved = !_effectiveSaved;
    try {
      final response = await ContentEngagementService.instance.setSaved(
        _interactionPostId,
        saved: nextSaved,
      );
      if (mounted) {
        setState(() {
          _savedOverride =
              response['saved_by_me'] == true || response['saved'] == true;
          _savesCount =
              (response['saves_count'] as num?)?.toInt() ?? _savesCount;
        });
      }
      widget.onToggleFavorite();
    } on EngagementAuthRequiredException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save this video.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save update failed: $error')),
      );
    }
  }

  Future<void> _openComments() async {
    final controller = TextEditingController();
    var loading = true;
    var posting = false;
    String? error;
    List<Map<String, dynamic>> comments = const [];

    try {
      final response = await ContentEngagementService.instance
          .fetchComments(_interactionPostId);
      final raw = response['items'];
      if (raw is List) {
        comments = raw
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList(growable: false);
        _commentsCount =
            (response['comments_count'] as num?)?.toInt() ?? comments.length;
      }
    } catch (exception) {
      error = exception.toString();
    } finally {
      loading = false;
    }

    if (!mounted) {
      controller.dispose();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1020),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> submit() async {
            final body = controller.text.trim();
            if (body.isEmpty || posting) return;

            setSheetState(() {
              posting = true;
              error = null;
            });

            try {
              final response = await ContentEngagementService.instance
                  .postComment(_interactionPostId, body);
              final item = response['item'];
              if (item is Map) {
                setSheetState(() {
                  comments = [
                    item.cast<String, dynamic>(),
                    ...comments,
                  ];
                  _commentsCount =
                      (response['comments_count'] as num?)?.toInt() ??
                          comments.length;
                  controller.clear();
                });
              }
            } catch (exception) {
              setSheetState(() => error = exception.toString());
            } finally {
              if (sheetContext.mounted) {
                setSheetState(() => posting = false);
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 18,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 18,
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: MediaQuery.of(sheetContext).size.height * 0.72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Comments',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.white,
                        ),
                      ],
                    ),
                    if (loading)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (comments.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            error ??
                                'No comments yet. Be the first to comment.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: comments.length,
                          separatorBuilder: (_, __) => Divider(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            final user = comment['user'];
                            final name = user is Map
                                ? (user['name'] ?? 'User').toString()
                                : (comment['user_name'] ?? 'User').toString();
                            final body = (comment['body'] ?? '').toString();
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                child: Icon(Icons.person_rounded),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                body,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    if (error != null && comments.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          error!,
                          style: const TextStyle(color: Color(0xFFFF7C92)),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            enabled: !posting,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Write a comment…',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filled(
                          onPressed: posting ? null : submit,
                          icon: posting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    controller.dispose();
  }

  void _shareVideo() {
    final title = widget.item.title.trim().isNotEmpty
        ? widget.item.title.trim()
        : 'Short Video';
    final shareId = _interactionPostId;
    final url = AppConfig.shortShareUrl(shareId);
    final text = '$title\n\nWatch this short video in Dunamis TV:\n$url';

    Share.share(text, subject: title);

    ShortVideoEngagementService.instance.trackShare(widget.item);
  }

  Future<void> _runProtectedAction(
    AuthRequiredAction action,
    FutureOr<void> Function() continuation,
  ) async {
    final allowed = await AuthActionGate.requireAuthentication(
      context,
      action: action,
    );
    if (!allowed || !mounted) return;
    await continuation();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.item.title.trim().isNotEmpty
        ? widget.item.title.trim()
        : 'Short Video';
    final description = widget.item.description.trim();
    final creator = widget.item.creatorName.trim();
    final controller = _controller;
    final showVideo = controller != null && _isReady && _error == null;

    return MouseRegion(
      onEnter: (_) => _handlePointerActivity(),
      onHover: (_) => _handlePointerActivity(),
      onExit: (_) => _scheduleControlsAutoHide(),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _handlePointerActivity(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleSurfaceTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (showVideo)
                FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                        width: controller.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller)))
              else
                _ReelPoster(
                    thumbnailUrl: widget.item.thumbnailUrl,
                    isActive: widget.isActive),
              if (_error != null)
                Positioned.fill(
                    child: Container(
                        color: Colors.black.withOpacity(0.22),
                        alignment: Alignment.center,
                        child: const _ReelErrorChip())),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.24),
                      Colors.transparent,
                      Colors.black.withOpacity(0.88)
                    ],
                    stops: const [0.0, 0.48, 1.0],
                  ),
                ),
              ),
              Center(
                child: IgnorePointer(
                  ignoring: !_chromeVisible,
                  child: AnimatedOpacity(
                    opacity: _chromeVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _togglePlayback,
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.34),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.20))),
                        child: Icon(
                            showVideo && controller.value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 42),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 72,
                bottom: widget.bottomContentInset + 78,
                child: IgnorePointer(
                  ignoring: !_chromeVisible,
                  child: AnimatedOpacity(
                    opacity: _chromeVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CategoryPill(label: widget.item.categoryLabel),
                        const SizedBox(height: 9),
                        if (creator.isNotEmpty) ...[
                          Text(creator,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.88),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                        ],
                        Text(title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                height: 1.08,
                                fontWeight: FontWeight.w900)),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.84),
                                  fontSize: 13.5,
                                  height: 1.32,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: widget.bottomContentInset + 18,
                child: IgnorePointer(
                  ignoring: !_chromeVisible,
                  child: AnimatedOpacity(
                    opacity: _chromeVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: _ShortVideoProgressBar(
                      position: _position,
                      duration: _duration,
                      positionLabel: _formatDuration(_position),
                      durationLabel: _formatDuration(_duration),
                      enabled: showVideo && _duration.inMilliseconds > 0,
                      onSeekStart: () {
                        _controlsHideTimer?.cancel();
                        setState(() {
                          _isSeeking = true;
                          _showControls = true;
                        });
                      },
                      onSeekChanged: (fraction) {
                        if (_duration.inMilliseconds <= 0) {
                          return;
                        }

                        setState(() {
                          _position = Duration(
                            milliseconds: (_duration.inMilliseconds *
                                    fraction.clamp(0.0, 1.0))
                                .round(),
                          );
                        });
                      },
                      onSeekEnd: (fraction) async {
                        setState(() {
                          _isSeeking = false;
                        });

                        await _seekToFraction(fraction);
                        _scheduleControlsAutoHide();
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: MediaQuery.of(context).padding.top + 84,
                bottom: widget.bottomContentInset + 86,
                child: IgnorePointer(
                  ignoring: !_chromeVisible,
                  child: AnimatedOpacity(
                    opacity: _chromeVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _ReelActionButton(
                              icon: widget.isMuted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              label: widget.isMuted ? 'Mute' : 'Sound',
                              onTap: () => _runWithVisibleChrome(_toggleMute)),
                          const SizedBox(height: 10),
                          _ReelActionButton(
                              icon: Icons.grid_view_rounded,
                              label: 'Library',
                              onTap: () =>
                                  _runWithVisibleChrome(widget.onShowLibrary)),
                          const SizedBox(height: 10),
                          _ReelActionButton(
                              icon: _effectiveLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              label: 'Like',
                              active: _effectiveLiked,
                              count: _likesCount,
                              onTap: () => _runWithVisibleChrome(
                                  () => _runProtectedAction(
                                        AuthRequiredAction.like,
                                        _toggleBackendLike,
                                      ))),
                          const SizedBox(height: 10),
                          _ReelActionButton(
                              icon: _effectiveSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              label: 'Save',
                              active: _effectiveSaved,
                              count: _savesCount,
                              onTap: () => _runWithVisibleChrome(
                                  () => _runProtectedAction(
                                        AuthRequiredAction.save,
                                        _toggleBackendSave,
                                      ))),
                          const SizedBox(height: 10),
                          _ReelActionButton(
                              icon: Icons.mode_comment_outlined,
                              label: 'Comment',
                              count: _commentsCount,
                              onTap: () => _runWithVisibleChrome(
                                  () => _runProtectedAction(
                                        AuthRequiredAction.comment,
                                        _openComments,
                                      ))),
                          const SizedBox(height: 10),
                          _ReelActionButton(
                              icon: Icons.share_rounded,
                              label: 'Share',
                              onTap: () => _runWithVisibleChrome(_shareVideo)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortVideoProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final String positionLabel;
  final String durationLabel;
  final bool enabled;
  final VoidCallback onSeekStart;
  final ValueChanged<double> onSeekChanged;
  final ValueChanged<double> onSeekEnd;

  const _ShortVideoProgressBar({
    required this.position,
    required this.duration,
    required this.positionLabel,
    required this.durationLabel,
    required this.enabled,
    required this.onSeekStart,
    required this.onSeekChanged,
    required this.onSeekEnd,
  });

  @override
  Widget build(BuildContext context) {
    final total = duration.inMilliseconds <= 0 ? 1 : duration.inMilliseconds;
    final current = position.inMilliseconds.clamp(0, total).toDouble();
    final value = enabled ? (current / total).clamp(0.0, 1.0) : 0.0;

    return IgnorePointer(
      ignoring: !enabled,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.4,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 5.4,
                disabledThumbRadius: 4.8,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: const Color(0xFFE2388A),
              inactiveTrackColor: Colors.white.withOpacity(0.32),
              thumbColor: Colors.white,
              disabledThumbColor: Colors.white.withOpacity(0.70),
              disabledActiveTrackColor: Colors.white.withOpacity(0.28),
              disabledInactiveTrackColor: Colors.white.withOpacity(0.16),
              overlayColor: const Color(0xFFE2388A).withOpacity(0.18),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 1,
              onChangeStart: enabled ? (_) => onSeekStart() : null,
              onChanged: enabled ? onSeekChanged : null,
              onChangeEnd: enabled ? onSeekEnd : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
            child: Row(
              children: [
                Text(
                  enabled ? positionLabel : '0:00',
                  style: TextStyle(
                    color: Colors.white.withOpacity(enabled ? 0.92 : 0.50),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 6),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  enabled ? durationLabel : '0:00',
                  style: TextStyle(
                    color: Colors.white.withOpacity(enabled ? 0.76 : 0.45),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 6),
                    ],
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

class _ShortVideoNativeAdPage extends StatelessWidget {
  final double bottomContentInset;
  final String tabKey;

  const _ShortVideoNativeAdPage({
    required this.bottomContentInset,
    required this.tabKey,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return ColoredBox(
      color: const Color(0xFF07070A),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 18, 16, bottomContentInset + 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.campaign_rounded, color: Colors.white70, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Sponsored',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: NativeInlineAdTile(
                  tabKey: tabKey,
                  label: 'Sponsored',
                  minHeight: 620,
                  margin: EdgeInsets.zero,
                  factoryId: 'listTile',
                ),
              ),
              SizedBox(height: topInset > 0 ? 2 : 8),
              const Center(
                child: Text(
                  'Swipe to continue',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShortVideoLibrarySheet extends StatefulWidget {
  final List<ShortVideoItem> items;
  final int activeIndex;
  final Set<String> favoriteIds;
  final ValueChanged<int> onSelected;
  final ValueChanged<String> onToggleFavorite;
  final String adsPolicyKey;
  const ShortVideoLibrarySheet({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.favoriteIds,
    required this.onSelected,
    required this.onToggleFavorite,
    required this.adsPolicyKey,
  });
  @override
  State<ShortVideoLibrarySheet> createState() => _ShortVideoLibrarySheetState();
}

class _ShortVideoLibrarySheetState extends State<ShortVideoLibrarySheet> {
  String _activeCategory = 'all';
  String _query = '';
  bool _showFavoritesOnly = false;

  List<ShortVideoCategory> get _categories => [
        const ShortVideoCategory(key: 'all', label: 'All'),
        ...ShortVideoMapper.categoriesFor(widget.items)
      ];

  List<ShortVideoItem> get _filteredItems {
    final q = _query.trim().toLowerCase();
    return widget.items.where((item) {
      if (_showFavoritesOnly && !widget.favoriteIds.contains(item.safeId))
        return false;
      if (_activeCategory != 'all' && item.categoryKey != _activeCategory)
        return false;
      if (q.isEmpty) return true;
      final haystack = [
        item.title,
        item.description,
        item.creatorName,
        item.categoryLabel,
        item.tags.join(' ')
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList(growable: false);
  }

  String get _libraryAdsPolicyKey =>
      AdsService.instance.resolveConfiguredPolicyKey(
        const <String>[
          'shorts.library',
          'shorts',
          'explore.shorts',
          'inspire.short_videos',
          'home.short_videos',
        ],
        fallback: widget.adsPolicyKey,
      );

  bool get _libraryNativeAdsEnabled =>
      AdsService.instance.nativeInListAllowedForTab(_libraryAdsPolicyKey);

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.9,
      decoration: const BoxDecoration(
          color: Color(0xFF070B16),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(99))),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 10, 10),
          child: Row(children: [
            const Expanded(
                child: Text('Short Video Library',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900))),
            IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'Search short videos...',
              hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.48),
                  fontWeight: FontWeight.w700),
              prefixIcon: Icon(Icons.search_rounded,
                  color: Colors.white.withOpacity(0.7)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.07),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide:
                      BorderSide(color: Colors.white.withOpacity(0.10))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide:
                      BorderSide(color: Colors.white.withOpacity(0.10))),
              focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                  borderSide: BorderSide(color: Color(0xFFE2388A))),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == _categories.length) {
                return _LibraryFilterChip(
                    label: 'Saved',
                    selected: _showFavoritesOnly,
                    icon: Icons.bookmark_rounded,
                    onTap: () => setState(
                        () => _showFavoritesOnly = !_showFavoritesOnly));
              }
              final category = _categories[index];
              return _LibraryFilterChip(
                  label: category.label,
                  selected: _activeCategory == category.key,
                  onTap: () => setState(() => _activeCategory = category.key));
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text('No videos found.',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800)))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 12.0;
                      final cardWidth =
                          (constraints.maxWidth - 28 - spacing) / 2;
                      final blocks = <Widget>[];

                      for (var start = 0; start < items.length; start += 4) {
                        final end = (start + 4).clamp(0, items.length);
                        blocks.add(
                          Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              for (var itemIndex = start;
                                  itemIndex < end;
                                  itemIndex++)
                                SizedBox(
                                  width: cardWidth,
                                  height: cardWidth / 0.64,
                                  child: Builder(
                                    builder: (context) {
                                      final item = items[itemIndex];
                                      final sourceIndex =
                                          widget.items.indexWhere(
                                        (existing) =>
                                            existing.safeId == item.safeId,
                                      );
                                      return _ShortVideoLibraryTile(
                                        item: item,
                                        isActive:
                                            sourceIndex == widget.activeIndex,
                                        isFavorite: widget.favoriteIds
                                            .contains(item.safeId),
                                        onTap: () => widget.onSelected(
                                            sourceIndex < 0 ? 0 : sourceIndex),
                                        onToggleFavorite: () => widget
                                            .onToggleFavorite(item.safeId),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        );

                        final lastItemIndex = end - 1;
                        if (_libraryNativeAdsEnabled &&
                            end < items.length &&
                            AdsService.instance.shouldInsertNativeAfterItem(
                              tabKey: _libraryAdsPolicyKey,
                              itemIndex: lastItemIndex,
                            )) {
                          blocks.add(const SizedBox(height: 12));
                          blocks.add(
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: NativeInlineAdTile(
                                tabKey: _libraryAdsPolicyKey,
                                label: 'Sponsored',
                                minHeight: 180,
                                margin: EdgeInsets.zero,
                              ),
                            ),
                          );
                        }

                        if (end < items.length) {
                          blocks.add(const SizedBox(height: 12));
                        }
                      }

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                        physics: const BouncingScrollPhysics(),
                        children: blocks,
                      );
                    },
                  )),
      ]),
    );
  }
}

class _LibraryFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;
  const _LibraryFilterChip(
      {required this.label,
      required this.selected,
      this.icon,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          selected ? const Color(0xFFE2388A) : Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: selected
                      ? Colors.white.withOpacity(0.22)
                      : Colors.white.withOpacity(0.10))),
          child: Row(children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6)
            ],
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900))
          ]),
        ),
      ),
    );
  }
}

class _ShortVideoLibraryTile extends StatelessWidget {
  final ShortVideoItem item;
  final bool isActive;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  const _ShortVideoLibraryTile(
      {required this.item,
      required this.isActive,
      required this.isFavorite,
      required this.onTap,
      required this.onToggleFavorite});
  @override
  Widget build(BuildContext context) {
    final title =
        item.title.trim().isNotEmpty ? item.title.trim() : 'Short Video';
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.055),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: isActive
                      ? const Color(0xFFE2388A)
                      : Colors.white.withOpacity(0.08),
                  width: isActive ? 1.5 : 1)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(fit: StackFit.expand, children: [
              _ReelPoster(thumbnailUrl: item.thumbnailUrl, isActive: isActive),
              DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.18),
                    Colors.black.withOpacity(0.82)
                  ]))),
              Positioned(
                  top: 9,
                  right: 9,
                  child: GestureDetector(
                      onTap: onToggleFavorite,
                      child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.42),
                              shape: BoxShape.circle),
                          child: Icon(
                              isFavorite
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: Colors.white,
                              size: 21)))),
              Positioned(
                  left: 9,
                  top: 9,
                  child: _CategoryPill(label: item.categoryLabel)),
              Positioned(
                  left: 11,
                  right: 11,
                  bottom: 12,
                  child: Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          height: 1.1,
                          fontSize: 13.2,
                          fontWeight: FontWeight.w900))),
            ]),
          ),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  const _CategoryPill({required this.label});
  @override
  Widget build(BuildContext context) {
    final safeLabel = label.trim().isEmpty ? 'General' : label.trim();
    return Container(
      constraints: const BoxConstraints(maxWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.46),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.14))),
      child: Text(safeLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w900)),
    );
  }
}

class _ReelPoster extends StatelessWidget {
  final String thumbnailUrl;
  final bool isActive;
  const _ReelPoster({required this.thumbnailUrl, required this.isActive});
  bool get _hasRemoteImage {
    final uri = Uri.tryParse(thumbnailUrl.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  @override
  Widget build(BuildContext context) {
    if (_hasRemoteImage) {
      return Image.network(thumbnailUrl.trim(),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _ReelGradientPlaceholder(isActive: isActive));
    }
    return _ReelGradientPlaceholder(isActive: isActive);
  }
}

class _ReelGradientPlaceholder extends StatelessWidget {
  final bool isActive;
  const _ReelGradientPlaceholder({required this.isActive});
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
            Color(0xFF071A3D),
            Color(0xFF1D5CFF),
            Color(0xFFE2388A)
          ])),
      child: Center(
          child: Icon(Icons.play_circle_fill_rounded,
              color: Colors.white.withOpacity(isActive ? 0.24 : 0.12),
              size: 120)),
    );
  }
}

class _ReelActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final int? count;
  final VoidCallback onTap;
  const _ReelActionButton(
      {required this.icon,
      required this.label,
      this.active = false,
      this.count,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFE2388A) : Colors.white;
    return Column(children: [
      Material(
        color: Colors.black.withOpacity(0.28),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: active
                          ? const Color(0xFFE2388A).withOpacity(0.8)
                          : Colors.white.withOpacity(0.16))),
              child: Icon(icon, color: color, size: 20)),
        ),
      ),
      const SizedBox(height: 3),
      Text(label,
          style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 9,
              fontWeight: FontWeight.w800)),
      if (count != null)
        Text(
          count.toString(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.92),
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
    ]);
  }
}

class _ReelErrorChip extends StatelessWidget {
  const _ReelErrorChip();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.58),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.18))),
      child: const Text('Preview unavailable. Tap to retry later.',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}
