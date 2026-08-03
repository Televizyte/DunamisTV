import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app_config.dart';
import '../../../features/hub/models/dynamic_section.dart';
import '../../../features/hub/models/short_video_item.dart';
import '../../../features/hub/renderer/short_video_mapper.dart';
import '../../../features/hub/state/hub_scope.dart';
import '../../../services/ads_service.dart';
import '../../../theme/theme_controller.dart';
import '../../shell/bottom_shell.dart';
import '../../widgets/ads/native_inline_ad_tile.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';
import 'widgets/inspire_short_video_entry.dart';

class InspireScreen extends StatelessWidget {
  const InspireScreen({super.key});

  static const String tabKey = 'inspire';

  @override
  Widget build(BuildContext context) {
    final store = HubScope.maybeOf(context);

    return AnimatedBuilder(
      animation: Listenable.merge([
        ThemeController.instance,
        if (store != null) store,
      ]),
      builder: (context, _) {
        final hub = store?.raw ?? const <String, dynamic>{};

        final inspire = (hub['inspire'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};

        final shortVideoEntry = _extractShortVideoEntry(inspire);
        final inspireWithoutShortVideos = _removeShortVideoSections(inspire);
        // Custom quote-channel sections are not rendered as loose top-level
        // cards on Inspire. They remain available in the hub payload so detail
        // screens such as Message Highlights can insert them at the configured
        // list position.
        final inspireWithoutDynamicQuotes =
            _removeDynamicQuoteSections(inspireWithoutShortVideos);
        var cards = _buildCards(inspireWithoutDynamicQuotes);
        cards = _ensureSeedsOfDestinyCards(
          cards,
          inspireWithoutShortVideos,
          inspire,
        );
        final isLight = ThemeController.instance.isLightMode;

        AdsService.instance.preloadInterstitial(tabKey: tabKey);

        final entries = _buildAdAwareEntries(cards);
        final hasAnyContent = shortVideoEntry != null || cards.isNotEmpty;

        return Scaffold(
          appBar: DxmTopBar(
            title: AppConfig.tabInspireLabel,
            showMenu: true,
            onRefresh: () => store?.refresh(),
          ),
          body: GradientPageBackground(
            child: RefreshIndicator(
              onRefresh: () async {
                await store?.refresh();
              },
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  14,
                  14,
                  14,
                  BottomShellInsets.of(context) + 12,
                ),
                children: [
                  if (!hasAnyContent)
                    _EmptyStateCard(
                      title: AppConfig.inspireEmptyTitle,
                      subtitle: AppConfig.inspireEmptySubtitle,
                      isLight: isLight,
                    )
                  else ...[
                    if (shortVideoEntry != null)
                      InspireShortVideoEntry(
                        title: shortVideoEntry.title,
                        subtitle: shortVideoEntry.subtitle,
                        previews: shortVideoEntry.previews,
                        count: shortVideoEntry.count,
                        isLight: isLight,
                        reelItems: shortVideoEntry.items,
                        onTap: (route) async {
                          await AdsService.instance
                              .maybeShowInterstitialOnSafeNav(
                            context,
                            tabKey: shortVideoEntry.adKey,
                          );

                          if (!context.mounted) return;
                          context.push(_normalizeAppRoute(route));
                        },
                      ),
                    ..._buildInspireEntryWidgets(
                      context: context,
                      entries: entries,
                      isLight: isLight,
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

  static List<HubDynamicSection> _extractDynamicQuoteSections(
    Map<String, dynamic> inspire,
  ) {
    final rawSections = inspire['sections'];
    if (rawSections is! List) return const <HubDynamicSection>[];

    final out = <HubDynamicSection>[];

    for (final raw in rawSections) {
      if (raw is! Map) continue;
      final map = raw.cast<String, dynamic>();
      if (!_isDynamicQuoteSection(map)) continue;

      final section = HubDynamicSection.fromMap(map);
      if (!section.enabled || section.items.isEmpty) continue;
      out.add(section);
    }

    return out;
  }

  static Map<String, dynamic> _removeDynamicQuoteSections(
    Map<String, dynamic> inspire,
  ) {
    final copy = Map<String, dynamic>.from(inspire);
    final rawSections = copy['sections'];
    if (rawSections is! List) return copy;

    copy['sections'] = rawSections.where((entry) {
      if (entry is! Map) return true;
      return !_isDynamicQuoteSection(entry.cast<String, dynamic>());
    }).toList(growable: false);

    copy['cards'] = copy['sections'];
    copy['hub_cards'] = copy['sections'];
    return copy;
  }

  static bool _isDynamicQuoteSection(Map<String, dynamic> map) {
    // A section should be treated as a standalone quote feed only when the
    // section itself is backed by a quote channel. Do not classify ordinary
    // hub/grid sections as quote feeds merely because they contain one child
    // card named "SOD Quotes".
    final sectionKey = _firstNonEmpty([
      _firstString(map, const ['key', 'section_key', 'slug', 'route_key']),
      _firstStringFromNested(map, 'settings', const ['key', 'section_key']),
      _firstStringFromNested(map, 'meta', const ['key', 'section_key']),
    ]).toLowerCase();

    final sectionTitle = _firstString(map, const ['title', 'name', 'label'])
        .trim()
        .toLowerCase();

    if (sectionKey.contains('inspire_sod') ||
        sectionKey == 'sod' ||
        sectionTitle.contains('seed of destiny') ||
        sectionTitle.contains('seeds of destiny')) {
      return false;
    }

    final sectionLayout = _firstNonEmpty([
      _firstString(map, const ['layout', 'layout_type', 'template']),
      _firstStringFromNested(map, 'settings', const ['layout', 'layout_type']),
      _firstStringFromNested(map, 'meta', const ['layout', 'layout_type']),
    ]).toLowerCase();

    final sectionSource = _firstNonEmpty([
      _firstString(map, const [
        'source_type',
        'sourceType',
        'content_source',
        'contentSource',
      ]),
      _firstStringFromNested(map, 'source', const ['type', 'source_type']),
      _firstStringFromNested(map, 'settings', const [
        'source_type',
        'sourceType',
        'content_source',
        'contentSource',
      ]),
      _firstStringFromNested(map, 'meta', const [
        'source_type',
        'sourceType',
        'content_source',
        'contentSource',
      ]),
    ]).toLowerCase();

    final sectionBucket = _firstNonEmpty([
      _firstString(map, const ['bucket', 'source_bucket']),
      _firstStringFromNested(map, 'source', const ['bucket', 'source_bucket']),
      _firstStringFromNested(
          map, 'settings', const ['bucket', 'source_bucket']),
      _firstStringFromNested(map, 'meta', const ['bucket', 'source_bucket']),
    ]).toLowerCase();

    final sectionDeclaresQuoteSource = sectionSource.contains('quote') ||
        sectionBucket.startsWith('quote_') ||
        sectionBucket == 'quotes' ||
        sectionBucket == 'daily_quotes';

    if (sectionDeclaresQuoteSource) return true;

    return sectionLayout == 'quote' ||
        sectionLayout == 'quote_card' ||
        sectionLayout == 'quote_feed' ||
        sectionLayout == 'quote_carousel' ||
        sectionLayout == 'dynamic_quote_card';
  }

  static List<_InspireCardData> _ensureSeedsOfDestinyCards(
    List<_InspireCardData> cards,
    Map<String, dynamic> filteredInspire,
    Map<String, dynamic> originalInspire,
  ) {
    final hasSod = cards.any((card) {
      final title = card.title.toLowerCase();
      final bucket = card.bucket.toLowerCase();
      return title.contains('seed of destiny') ||
          title.contains('seeds of destiny') ||
          bucket.contains('inspire_sod') ||
          bucket == 'sod';
    });

    if (hasSod) return cards;

    final rawSections = originalInspire['sections'];
    if (rawSections is! List) return cards;

    for (final raw in rawSections) {
      if (raw is! Map) continue;
      final section = raw.cast<String, dynamic>();
      if (!_isSeedsOfDestinySection(section)) continue;

      final recovered = _normalizeConfiguredCards([section], filteredInspire);
      if (recovered.isEmpty) return cards;

      return <_InspireCardData>[
        ...recovered,
        ...cards,
      ];
    }

    return cards;
  }

  static bool _isSeedsOfDestinySection(Map<String, dynamic> section) {
    final key = _firstNonEmpty([
      _firstString(section, const ['key', 'section_key', 'slug', 'route_key']),
      _firstStringFromNested(section, 'settings', const ['key', 'section_key']),
      _firstStringFromNested(section, 'meta', const ['key', 'section_key']),
    ]).toLowerCase();
    final title = _firstString(section, const ['title', 'name', 'label'])
        .trim()
        .toLowerCase();

    return key.contains('inspire_sod') ||
        key == 'sod' ||
        title.contains('seed of destiny') ||
        title.contains('seeds of destiny');
  }

  static _ShortVideoEntryData? _extractShortVideoEntry(
    Map<String, dynamic> inspire,
  ) {
    final rawSections = inspire['sections'];
    if (rawSections is! List) return null;

    for (final raw in rawSections) {
      if (raw is! Map) continue;

      final map = raw.cast<String, dynamic>();
      if (!_isShortVideoSection(map)) continue;

      final items = map['items'] is List ? map['items'] as List : const [];
      final firstItem = _firstMap(items);

      final route = _normalizeAppRoute(
        _firstNonEmpty([
          _firstString(map, const ['target_route', 'route', 'path', 'href']),
          _firstStringFromNested(map, 'meta', const ['target_route', 'route']),
          _firstStringFromNested(
            map,
            'settings',
            const ['target_route', 'route'],
          ),
          if (firstItem != null)
            _firstString(firstItem, const ['route', 'path', 'href']),
          '/short-videos',
        ]),
      );

      final title = _firstNonEmpty([
        _firstString(map, const ['title', 'name', 'label']),
        if (firstItem != null) _firstString(firstItem, const ['title', 'name']),
        'Short Videos',
      ]);

      final subtitle = _firstNonEmpty([
        _firstString(
          map,
          const ['subtitle', 'description', 'summary', 'caption'],
        ),
        if (firstItem != null)
          _firstString(
            firstItem,
            const ['subtitle', 'description', 'summary', 'caption'],
          ),
        'Watch short inspirational video feeds',
      ]);

      final previews = _extractShortVideoPreviews(items);
      final reelItems = ShortVideoMapper.fromRawList(items);

      final imageUrl =
          _pickImage(map) ?? (firstItem == null ? null : _pickImage(firstItem));

      final count = _sectionItemCount(map, inspire, 'short_videos');

      return _ShortVideoEntryData(
        title: title,
        subtitle: subtitle,
        imageUrl: imageUrl,
        count: count > 0 ? count : previews.length,
        route: route.trim().isNotEmpty ? route.trim() : '/short-videos',
        adKey: 'inspire.short_videos',
        items: reelItems,
        previews: previews.isNotEmpty
            ? previews
            : [
                InspireShortVideoPreview(
                  title: title,
                  subtitle: subtitle,
                  imageUrl: imageUrl,
                  route:
                      route.trim().isNotEmpty ? route.trim() : '/short-videos',
                ),
              ],
      );
    }

    return null;
  }

  static List<InspireShortVideoPreview> _extractShortVideoPreviews(
    List<dynamic> rawItems,
  ) {
    final previews = <InspireShortVideoPreview>[];

    for (final raw in rawItems) {
      if (raw is! Map) continue;

      final map = raw.cast<String, dynamic>();

      final title = _firstNonEmpty([
        _firstString(map, const ['title', 'name', 'label']),
        'Short Video',
      ]);

      final subtitle = _firstNonEmpty([
        _firstString(
          map,
          const ['subtitle', 'description', 'summary', 'caption'],
        ),
        'Tap to watch',
      ]);

      final route = _normalizeAppRoute(
        _firstNonEmpty([
          _firstString(map, const ['route', 'path', 'href']),
          _firstStringFromNested(
              map, 'payload', const ['route', 'target_route']),
          _firstStringFromNested(map, 'meta', const ['route', 'target_route']),
          '/short-videos',
        ]),
      );

      previews.add(
        InspireShortVideoPreview(
          title: title,
          subtitle: subtitle,
          imageUrl: _pickImage(map),
          route: route.trim().isNotEmpty ? route.trim() : '/short-videos',
        ),
      );
    }

    return previews;
  }

  static Map<String, dynamic> _removeShortVideoSections(
    Map<String, dynamic> inspire,
  ) {
    final copy = Map<String, dynamic>.from(inspire);

    for (final key in const [
      'sections',
      'cards',
      'items',
      'hub_cards',
      'menu',
    ]) {
      final raw = copy[key];
      if (raw is! List) continue;

      copy[key] = raw.where((entry) {
        if (entry is! Map) return true;
        return !_isShortVideoSection(entry.cast<String, dynamic>());
      }).toList(growable: false);
    }

    return copy;
  }

  static bool _isShortVideoSection(Map<String, dynamic> map) {
    final buffer = StringBuffer();

    for (final key in const [
      'key',
      'section_key',
      'title',
      'subtitle',
      'type',
      'layout',
      'template',
      'bucket',
      'source',
      'route_key',
      'slug',
    ]) {
      buffer.write(' ');
      buffer.write(map[key]?.toString() ?? '');
    }

    void addNested(String key) {
      final nested = map[key];
      if (nested is! Map) return;

      for (final value in nested.values) {
        buffer.write(' ');
        buffer.write(value?.toString() ?? '');
      }
    }

    addNested('payload');
    addNested('meta');
    addNested('settings');

    final lower = buffer.toString().toLowerCase();

    return lower.contains('short_video') ||
        lower.contains('short videos') ||
        lower.contains('short-videos') ||
        lower.contains('shorts') ||
        lower.contains('reel') ||
        lower.contains('vertical_video');
  }

  static Map<String, dynamic>? _firstMap(List<dynamic> items) {
    for (final item in items) {
      if (item is Map) {
        return item.cast<String, dynamic>();
      }
    }

    return null;
  }

  static String _firstStringFromNested(
    Map<String, dynamic> map,
    String nestedKey,
    List<String> keys,
  ) {
    final nested = map[nestedKey];
    if (nested is! Map) return '';

    final casted = nested.cast<String, dynamic>();
    return _firstString(casted, keys);
  }

  static List<_InspireAdEntry> _buildAdAwareEntries(
    List<_InspireCardData> cards,
  ) {
    if (cards.isEmpty) return const [];

    final out = <_InspireAdEntry>[];

    final ads = AdsService.instance;
    final listEnabled = ads.nativeInListEnabled;
    final every = ads.nativeEvery <= 0 ? 6 : ads.nativeEvery;
    final startAfter = ads.nativeStartAfter < 1 ? 1 : ads.nativeStartAfter;

    var displayedItems = 0;

    for (var index = 0; index < cards.length; index++) {
      final card = cards[index];

      out.add(
        _InspireAdEntry.card(
          card: card,
          itemIndex: index,
        ),
      );

      if (card.isSectionHeader) continue;

      displayedItems++;
      final shouldTryNative = listEnabled &&
          displayedItems >= startAfter &&
          ((displayedItems - startAfter) % every == 0) &&
          index != cards.length - 1;

      if (!shouldTryNative) continue;

      final nextCard = cards[index + 1];
      final tabAllowed = ads.nativeAllowedForTab(tabKey);
      final currentPageAllowed = ads.nativeAllowedForTab(card.adKey);
      final nextPageAllowed = ads.nativeAllowedForTab(nextCard.adKey);

      if (tabAllowed || currentPageAllowed || nextPageAllowed) {
        out.add(
          _InspireAdEntry.ad(
            itemIndex: index,
            adLabel: 'Sponsored',
          ),
        );
      }
    }

    return out;
  }

  static List<Widget> _buildInspireEntryWidgets({
    required BuildContext context,
    required List<_InspireAdEntry> entries,
    required bool isLight,
  }) {
    final widgets = <Widget>[];
    var index = 0;

    while (index < entries.length) {
      final entry = entries[index];

      if (entry.isAd) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: NativeInlineAdTile(
              label: entry.adLabel,
              minHeight: 126,
            ),
          ),
        );
        index++;
        continue;
      }

      final card = entry.card!;

      if (card.isSectionHeader) {
        final sectionEntries = <_InspireAdEntry>[];
        var cursor = index + 1;
        var deferredAd = false;

        while (cursor < entries.length &&
            (card.sectionChildCount <= 0 ||
                sectionEntries.length < card.sectionChildCount)) {
          final nextEntry = entries[cursor];

          if (nextEntry.isAd) {
            deferredAd = true;
            cursor++;
            continue;
          }

          final nextCard = nextEntry.card;
          if (nextCard == null || nextCard.isSectionHeader) break;

          sectionEntries.add(nextEntry);
          cursor++;
        }

        if (card.renderAsGrid && sectionEntries.isNotEmpty) {
          widgets.add(
            _InspireGridSection(
              header: card,
              entries: sectionEntries,
              isLight: isLight,
              onOpen: (target) async {
                await AdsService.instance.maybeShowInterstitialOnSafeNav(
                  context,
                  tabKey: target.adKey,
                );

                if (!context.mounted) return;
                _openInspireRoute(context, target.route, title: target.title);
              },
            ),
          );

          if (deferredAd) {
            widgets.add(
              const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: NativeInlineAdTile(
                  label: 'Sponsored',
                  minHeight: 126,
                ),
              ),
            );
          }

          index = cursor;
          continue;
        }

        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 12),
            child: _InspireSectionLabel(
              title: card.title,
              subtitle: card.subtitle,
              isLight: isLight,
            ),
          ),
        );
        index++;
        continue;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _InspireImageCard(
            title: card.title,
            subtitle: card.subtitle,
            badgeCount: card.badgeCount,
            icon: card.icon,
            imageUrl: card.imageUrl,
            fallbackAsset: _fallbackAssetFor(entry.itemIndex),
            onTap: () async {
              await AdsService.instance.maybeShowInterstitialOnSafeNav(
                context,
                tabKey: card.adKey,
              );

              if (!context.mounted) return;
              _openInspireRoute(context, card.route, title: card.title);
            },
            isLight: isLight,
          ),
        ),
      );
      index++;
    }

    return widgets;
  }

  static List<_InspireCardData> _buildCards(Map<String, dynamic> inspire) {
    final configured = _extractConfiguredCards(inspire);
    if (configured.isNotEmpty) {
      return configured;
    }

    return _buildFallbackCards(inspire);
  }

  static List<_InspireCardData> _extractConfiguredCards(
    Map<String, dynamic> inspire,
  ) {
    final candidates = <dynamic>[
      inspire['cards'],
      inspire['sections'],
      inspire['items'],
      inspire['hub_cards'],
      inspire['menu'],
    ];

    for (final candidate in candidates) {
      final cards = _normalizeConfiguredCards(candidate, inspire);
      if (cards.isNotEmpty) return cards;
    }

    return const [];
  }

  static List<_InspireCardData> _normalizeConfiguredCards(
    dynamic raw,
    Map<String, dynamic> inspire,
  ) {
    if (raw is! List) return const [];

    final out = <_InspireCardData>[];

    for (final item in raw) {
      if (item is! Map) continue;
      final map = item.cast<String, dynamic>();

      final bucket = _firstString(map, const [
        'bucket',
        'source',
        'key',
        'slug',
        'id',
        'route_key',
        'title',
      ]).trim();

      final normalizedBucket = _normalizeBucketKey(bucket);

      final route = _resolveRoute(
        explicitRoute: _firstNonEmpty([
          _firstString(map, const ['route', 'path', 'href']),
          _firstRouteFromItems(map),
        ]),
        bucket: normalizedBucket,
      );

      if (route.isEmpty) continue;

      final itemCount = _sectionItemCount(map, inspire, normalizedBucket);

      final title = _firstNonEmpty([
        _firstString(map, const ['title', 'name', 'label']),
        _humanizeBucket(normalizedBucket),
      ]);

      final subtitle = _firstNonEmpty([
        _firstString(
          map,
          const ['subtitle', 'description', 'summary', 'caption'],
        ),
        _defaultSubtitleForBucket(normalizedBucket),
      ]);

      final imageUrl = _pickImage(map) ??
          _firstImageFromItems(map) ??
          _pickPreviewImageForBucket(inspire, normalizedBucket);

      final renderAsGrid = _isBackendGridSection(map) ||
          normalizedBucket == 'sod' ||
          normalizedBucket == 'sod_quotes' ||
          title.toLowerCase().contains('seed') ||
          title.toLowerCase().contains('sod');
      final gridColumns = renderAsGrid &&
              (normalizedBucket == 'sod' ||
                  normalizedBucket == 'sod_quotes' ||
                  title.toLowerCase().contains('seed') ||
                  title.toLowerCase().contains('sod'))
          ? 2
          : _gridColumnsForSection(map);

      final expandedItems = _configuredItemCards(
        section: map,
        parentBucket: normalizedBucket,
        parentRoute: route,
        parentAdKey: _adKeyForBucket(normalizedBucket),
      );

      if (expandedItems.isNotEmpty) {
        out.add(
          _InspireCardData(
            bucket: '__section_header',
            title: title,
            subtitle: subtitle,
            badgeCount: 0,
            icon: _iconForBackendValue(
              _firstString(map, const ['icon']),
              fallback: _iconForBucket(normalizedBucket),
            ),
            imageUrl: null,
            route: '',
            adKey: _adKeyForBucket(normalizedBucket),
            isSectionHeader: true,
            renderAsGrid: renderAsGrid,
            gridColumns: gridColumns,
            sectionChildCount: expandedItems.length,
          ),
        );
        out.addAll(expandedItems);
        continue;
      }

      out.add(
        _InspireCardData(
          bucket: normalizedBucket,
          title: title,
          subtitle: subtitle,
          badgeCount: itemCount,
          icon: _iconForBackendValue(
            _firstString(map, const ['icon']),
            fallback: _iconForBucket(normalizedBucket),
          ),
          imageUrl: imageUrl,
          route: route,
          adKey: _adKeyForBucket(normalizedBucket),
        ),
      );
    }

    return out;
  }

  static List<_InspireCardData> _configuredItemCards({
    required Map<String, dynamic> section,
    required String parentBucket,
    required String parentRoute,
    required String parentAdKey,
  }) {
    final rawItems = section['items'];
    if (rawItems is! List || rawItems.isEmpty) return const [];

    final sectionLayout = _firstNonEmpty([
      _firstString(
        section,
        const ['layout', 'template', 'type', 'card_layout'],
      ),
      _firstStringFromNested(section, 'settings', const ['layout', 'template']),
      _firstStringFromNested(section, 'meta', const ['layout', 'template']),
    ]).toLowerCase();

    final sectionTitle = _firstString(section, const ['title', 'name', 'label'])
        .trim()
        .toLowerCase();

    final shouldExpand = sectionLayout.contains('grid') ||
        sectionLayout.contains('menu') ||
        sectionLayout.contains('hub') ||
        sectionLayout.contains('tiles') ||
        sectionLayout.contains('quick') ||
        sectionLayout.contains('shortcut') ||
        _dxmBoolFromMap(section, const [
          'expand_items',
          'expand_children',
          'show_items_as_cards',
        ]) ||
        _dxmBoolFromNested(section, 'settings', const [
          'expand_items',
          'expand_children',
          'show_items_as_cards',
        ]) ||
        _dxmBoolFromNested(section, 'meta', const [
          'expand_items',
          'expand_children',
          'show_items_as_cards',
        ]) ||
        sectionTitle.contains('hub') ||
        sectionTitle.contains('menu') ||
        sectionTitle.contains('seed') ||
        sectionTitle.contains('sod');

    if (!shouldExpand) return const [];

    final out = <_InspireCardData>[];

    for (final rawItem in rawItems) {
      if (rawItem is! Map) continue;
      final item = rawItem.cast<String, dynamic>();

      final title = _firstNonEmpty([
        _firstString(item, const ['title', 'name', 'label']),
        _humanizeBucket(parentBucket),
      ]);

      if (title.trim().isEmpty) continue;

      final subtitle = _firstNonEmpty([
        _firstString(
          item,
          const ['subtitle', 'description', 'summary', 'caption'],
        ),
        _defaultSubtitleForBucket(parentBucket),
      ]);

      final rawRoute = _firstNonEmpty([
        _firstString(
          item,
          const [
            'page_key',
            'pageKey',
            'route',
            'path',
            'href',
            'target_route',
            'route_key',
            'slug',
          ],
        ),
        _firstStringFromNested(
          item,
          'payload',
          const [
            'page_key',
            'pageKey',
            'route',
            'target_route',
            'route_key',
            'slug',
          ],
        ),
        _firstStringFromNested(
          item,
          'meta',
          const [
            'page_key',
            'pageKey',
            'route',
            'target_route',
            'route_key',
            'slug',
          ],
        ),
        _firstStringFromNested(
          item,
          'settings',
          const [
            'page_key',
            'pageKey',
            'route',
            'target_route',
            'route_key',
            'slug',
          ],
        ),
      ]);

      final route = _resolveBackendItemRoute(
        item: item,
        rawRoute: rawRoute,
        title: title,
        parentRoute: parentRoute,
      );

      if (route.trim().isEmpty) continue;

      final bucket = _normalizeBucketKey(_firstNonEmpty([
        _firstString(
          item,
          const ['bucket', 'source', 'key', 'slug', 'route_key'],
        ),
        parentBucket,
      ]));

      out.add(
        _InspireCardData(
          bucket: bucket,
          title: title,
          subtitle: subtitle,
          badgeCount: _childBadgeCount(item),
          icon: _iconForBackendValue(
            _firstString(item, const ['icon']),
            fallback: _iconForBucket(bucket),
          ),
          imageUrl: _pickImage(item) ?? _pickImage(section),
          route: route,
          adKey: _adKeyForBucket(bucket),
        ),
      );
    }

    return out;
  }

  static int _childBadgeCount(Map<String, dynamic> item) {
    int parseCount(dynamic value) {
      if (value is num) return value.toInt().clamp(0, 999999);
      final raw = (value ?? '').toString().trim();
      if (raw.isEmpty) return 0;
      return (int.tryParse(raw) ?? 0).clamp(0, 999999);
    }

    for (final key in const [
      'badge_count',
      'badgeCount',
      'items_count',
      'itemsCount',
      'children_count',
      'childrenCount',
      'child_count',
      'childCount',
      'count',
      'total',
      'total_count',
      'totalCount',
    ]) {
      final parsed = parseCount(item[key]);
      if (parsed > 0) return parsed;
    }

    for (final nestedKey in const ['payload', 'meta', 'settings']) {
      final nested = item[nestedKey];
      if (nested is! Map) continue;
      final nestedMap = nested.cast<String, dynamic>();

      for (final key in const [
        'badge_count',
        'badgeCount',
        'items_count',
        'itemsCount',
        'children_count',
        'childrenCount',
        'child_count',
        'childCount',
        'count',
        'total',
        'total_count',
        'totalCount',
      ]) {
        final parsed = parseCount(nestedMap[key]);
        if (parsed > 0) return parsed;
      }
    }

    for (final key in const [
      'items',
      'children',
      'cards',
      'entries',
      'results',
      'data',
    ]) {
      final raw = item[key];
      if (raw is List && raw.isNotEmpty) return raw.length;
    }

    final payload = item['payload'];
    if (payload is Map) {
      for (final key in const [
        'items',
        'children',
        'cards',
        'entries',
        'results',
        'data',
      ]) {
        final raw = payload[key];
        if (raw is List && raw.isNotEmpty) return raw.length;
      }
    }

    return 0;
  }

  static bool _isBackendGridSection(Map<String, dynamic> section) {
    final layout = _firstNonEmpty([
      _firstString(section, const [
        'layout',
        'layout_type',
        'layoutType',
        'template',
        'type',
        'card_layout',
        'cardLayout',
        'layout_variant',
        'layoutVariant',
        'variant',
      ]),
      _firstStringFromNested(section, 'settings', const [
        'layout',
        'layout_type',
        'layoutType',
        'template',
        'type',
        'card_layout',
        'cardLayout',
        'layout_variant',
        'layoutVariant',
        'variant',
      ]),
      _firstStringFromNested(section, 'meta', const [
        'layout',
        'layout_type',
        'layoutType',
        'template',
        'type',
        'card_layout',
        'cardLayout',
        'layout_variant',
        'layoutVariant',
        'variant',
      ]),
    ]).toLowerCase();

    return layout.contains('grid') ||
        layout.contains('tile') ||
        layout.contains('masonry');
  }

  static int _gridColumnsForSection(Map<String, dynamic> section) {
    int? parse(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse((value ?? '').toString().trim());
    }

    for (final map in <Map<String, dynamic>>[
      section,
      if (section['settings'] is Map)
        (section['settings'] as Map).cast<String, dynamic>(),
      if (section['meta'] is Map)
        (section['meta'] as Map).cast<String, dynamic>(),
      if (section['payload'] is Map)
        (section['payload'] as Map).cast<String, dynamic>(),
    ]) {
      for (final key in const [
        'grid_columns',
        'gridColumns',
        'columns',
        'column_count',
        'columnCount',
        'cols',
      ]) {
        final parsed = parse(map[key]);
        if (parsed == null) continue;
        return parsed.clamp(1, 4);
      }
    }

    return 2;
  }

  static String _resolveBackendItemRoute({
    required Map<String, dynamic> item,
    required String rawRoute,
    required String title,
    required String parentRoute,
  }) {
    final backendUrl = _backendActionUrlForItem(item: item, title: title);
    if (backendUrl.trim().isNotEmpty) return backendUrl.trim();

    final route = rawRoute.trim();
    if (route.isNotEmpty) {
      final normalized = _normalizeAppRoute(route);
      if (normalized.trim().isNotEmpty) return normalized;
    }

    final titleRoute = _routeFromTitle(title);
    if (titleRoute.trim().isNotEmpty) return titleRoute;

    return _normalizeAppRoute(parentRoute);
  }

  static String _backendActionUrlForItem({
    required Map<String, dynamic> item,
    required String title,
  }) {
    final action = _firstNonEmpty([
      _firstString(item, const [
        'action_type',
        'actionType',
        'tap_action',
        'tapAction',
        'action',
        'type',
      ]),
      _firstStringFromNested(item, 'payload', const [
        'action_type',
        'actionType',
        'tap_action',
        'tapAction',
        'action',
        'type',
      ]),
      _firstStringFromNested(item, 'meta', const [
        'action_type',
        'actionType',
        'tap_action',
        'tapAction',
        'action',
        'type',
      ]),
      _firstStringFromNested(item, 'settings', const [
        'action_type',
        'actionType',
        'tap_action',
        'tapAction',
        'action',
        'type',
      ]),
    ]).toLowerCase();

    final pageKey = _firstNonEmpty([
      _firstString(item, const ['page_key', 'pageKey', 'route', 'route_key']),
      _firstStringFromNested(
        item,
        'payload',
        const ['page_key', 'pageKey', 'route', 'route_key'],
      ),
      _firstStringFromNested(
        item,
        'meta',
        const ['page_key', 'pageKey', 'route', 'route_key'],
      ),
      _firstStringFromNested(
        item,
        'settings',
        const ['page_key', 'pageKey', 'route', 'route_key'],
      ),
    ]).toLowerCase();

    final youtubeUrl = _firstHttpStringFromItem(item, const [
      'youtube',
      'youtube_url',
      'youtubeUrl',
      'youtube_link',
      'youtubeLink',
      'youtube_playlist_url',
      'youtubePlaylistUrl',
      'youtube_video_url',
      'youtubeVideoUrl',
      'video_url',
      'videoUrl',
      'watch_url',
      'watchUrl',
    ]);

    final webUrl = _firstHttpStringFromItem(item, const [
      'url',
      'web_url',
      'webUrl',
      'external_url',
      'externalUrl',
      'target_url',
      'targetUrl',
      'content_url',
      'contentUrl',
      'link',
      'href',
      'live_url',
      'liveUrl',
      'quiz_url',
      'quizUrl',
      'quiz_link',
      'quizLink',
      'backend_url',
      'backendUrl',
      'api_url',
      'apiUrl',
    ]);

    final lowerTitle = title.trim().toLowerCase();
    final wantsYoutube = action.contains('youtube') ||
        action.contains('video') ||
        action.contains('playlist') ||
        action.contains('inner app') ||
        pageKey.contains('watch') ||
        lowerTitle.contains('watch') ||
        lowerTitle.contains('video');

    final wantsWeb = action.contains('web') ||
        action.contains('external') ||
        action.contains('url') ||
        pageKey.contains('read') ||
        lowerTitle.contains('read');

    final wantsQuiz = action.contains('quiz') ||
        pageKey.contains('quiz') ||
        lowerTitle.contains('quiz');

    if (wantsYoutube && youtubeUrl.isNotEmpty) return youtubeUrl;
    if ((wantsWeb || wantsQuiz) && webUrl.isNotEmpty) return webUrl;
    if (youtubeUrl.isNotEmpty && _isYoutubeUrl(youtubeUrl)) return youtubeUrl;
    if (webUrl.isNotEmpty && _isWebAction(action)) return webUrl;

    return '';
  }

  static String _firstHttpStringFromItem(
    Map<String, dynamic> item,
    List<String> keys,
  ) {
    final direct = _firstHttpStringFromMap(item, keys);
    if (direct.isNotEmpty) return direct;

    for (final nestedKey in const ['payload', 'meta', 'settings', 'data']) {
      final nested = item[nestedKey];
      if (nested is! Map) continue;
      final nestedValue = _firstHttpStringFromMap(
        nested.cast<String, dynamic>(),
        keys,
      );
      if (nestedValue.isNotEmpty) return nestedValue;
    }

    return '';
  }

  static String _firstHttpStringFromMap(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key]?.toString().trim() ?? '';
      if (_isHttpUrl(value)) return value;
    }
    return '';
  }

  static bool _isHttpUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.trim().isNotEmpty;
  }

  static bool _isYoutubeUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    return host.contains('youtube.com') || host.contains('youtu.be');
  }

  static bool _isWebAction(String action) {
    final lower = action.trim().toLowerCase();
    return lower.contains('web') ||
        lower.contains('external') ||
        lower.contains('url') ||
        lower.contains('browser');
  }

  static String _routeFromTitle(String title) {
    final lower = title.trim().toLowerCase();

    if (lower.isEmpty) return '';

    if ((lower.contains('quote') || lower.contains('code')) &&
        (lower.contains('sod') ||
            lower.contains('seed') ||
            lower.contains('destiny'))) {
      return '/sod/quotes';
    }

    if (lower.contains('quiz') &&
        (lower.contains('sod') ||
            lower.contains('seed') ||
            lower.contains('destiny'))) {
      return '/tab/sod_quiz';
    }

    if ((lower.contains('read') || lower.contains('reader')) &&
        (lower.contains('sod') ||
            lower.contains('seed') ||
            lower.contains('destiny'))) {
      return '/sod';
    }

    if ((lower.contains('watch') || lower.contains('video')) &&
        (lower.contains('sod') ||
            lower.contains('seed') ||
            lower.contains('destiny'))) {
      return '/watch';
    }

    return '';
  }

  static bool _dxmBoolFromMap(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (_dxmBoolValue(map[key])) return true;
    }
    return false;
  }

  static bool _dxmBoolFromNested(
    Map<String, dynamic> map,
    String nestedKey,
    List<String> keys,
  ) {
    final nested = map[nestedKey];
    if (nested is! Map) return false;
    return _dxmBoolFromMap(nested.cast<String, dynamic>(), keys);
  }

  static bool _dxmBoolValue(dynamic value) {
    final raw = (value ?? '').toString().trim().toLowerCase();
    return raw == '1' || raw == 'true' || raw == 'yes' || raw == 'on';
  }

  static List<_InspireCardData> _buildFallbackCards(
    Map<String, dynamic> inspire,
  ) {
    const preferredOrder = [
      'sod',
      'highlights',
      'wordification',
      'motivation',
      'articles',
    ];

    final out = <_InspireCardData>[];
    final used = <String>{};

    for (final bucket in preferredOrder) {
      final resolved = _resolveExistingBucketKey(inspire, bucket);
      if (resolved == null || used.contains(resolved)) continue;

      final route = _routeForBucket(resolved);
      if (route == null) continue;

      used.add(resolved);

      out.add(
        _InspireCardData(
          bucket: resolved,
          title: _titleForBucket(resolved),
          subtitle: _defaultSubtitleForBucket(resolved),
          badgeCount: _countForBucket(inspire, resolved),
          icon: _iconForBucket(resolved),
          imageUrl: _pickPreviewImageForBucket(inspire, resolved),
          route: route,
          adKey: _adKeyForBucket(resolved),
        ),
      );
    }

    for (final entry in inspire.entries) {
      final rawKey = entry.key.trim();
      if (rawKey.isEmpty) continue;

      final normalized = _normalizeBucketKey(rawKey);
      if (used.contains(normalized)) continue;

      final route = _routeForBucket(normalized);
      if (route == null) continue;

      final count = _countForBucket(inspire, normalized);
      final previewImage = _pickPreviewImageForBucket(inspire, normalized);

      if (count <= 0 && (previewImage == null || previewImage.trim().isEmpty)) {
        continue;
      }

      used.add(normalized);

      out.add(
        _InspireCardData(
          bucket: normalized,
          title: _titleForBucket(normalized),
          subtitle: _defaultSubtitleForBucket(normalized),
          badgeCount: count,
          icon: _iconForBucket(normalized),
          imageUrl: previewImage,
          route: route,
          adKey: _adKeyForBucket(normalized),
        ),
      );
    }

    return out;
  }

  static int _sectionItemCount(
    Map<String, dynamic> map,
    Map<String, dynamic> inspire,
    String normalizedBucket,
  ) {
    final bucketCount = _countForBucket(inspire, normalizedBucket);
    final rawItems = map['items'];
    if (rawItems is List && rawItems.isNotEmpty) {
      return bucketCount > rawItems.length ? bucketCount : rawItems.length;
    }

    final rawCount = map['items_count'] ?? map['count'] ?? map['badge_count'];
    if (rawCount is num) {
      final parsed = rawCount.toInt();
      return bucketCount > parsed ? bucketCount : parsed;
    }
    if (rawCount is String) {
      final parsed = int.tryParse(rawCount.trim()) ?? 0;
      return bucketCount > parsed ? bucketCount : parsed;
    }

    return bucketCount;
  }

  static String? _firstImageFromItems(Map<String, dynamic> map) {
    final rawItems = map['items'];
    if (rawItems is! List) return null;

    for (final raw in rawItems) {
      if (raw is! Map) continue;
      final image = _pickImage(raw.cast<String, dynamic>());
      if ((image ?? '').trim().isNotEmpty) return image;
    }

    return null;
  }

  static String _firstRouteFromItems(Map<String, dynamic> map) {
    final rawItems = map['items'];
    if (rawItems is! List) return '';

    for (final raw in rawItems) {
      if (raw is! Map) continue;
      final item = raw.cast<String, dynamic>();
      final route = _firstString(item, const ['route', 'path', 'href']);
      if (route.trim().isNotEmpty) return route.trim();
    }

    return '';
  }

  static String? _resolveExistingBucketKey(
    Map<String, dynamic> inspire,
    String preferred,
  ) {
    final normalizedPreferred = _normalizeBucketKey(preferred);

    for (final key in inspire.keys) {
      if (_normalizeBucketKey(key) == normalizedPreferred) {
        return normalizedPreferred;
      }
    }

    return null;
  }

  static int _countForBucket(Map<String, dynamic> inspire, String bucket) {
    final candidates = _candidateBucketKeys(bucket);

    for (final key in candidates) {
      final raw = inspire[key];
      if (raw is List) return raw.length;
    }

    return 0;
  }

  static String? _pickPreviewImageForBucket(
    Map<String, dynamic> inspire,
    String bucket,
  ) {
    final candidates = _candidateBucketKeys(bucket);

    for (final key in candidates) {
      final raw = inspire[key];
      if (raw is! List) continue;

      for (final item in raw) {
        if (item is! Map) continue;
        final image = _pickImage(item.cast<String, dynamic>());
        if ((image ?? '').trim().isNotEmpty) return image;
      }
    }

    return null;
  }

  static List<String> _candidateBucketKeys(String bucket) {
    final normalized = _normalizeBucketKey(bucket);

    switch (normalized) {
      case 'highlights':
        return const [
          'highlights',
          'highlight',
          'message_highlights',
          'message_highlight',
          'inspire_message_highlights',
        ];
      case 'articles':
        return const [
          'articles',
          'inside_dunamis',
          'inside_dunamis_articles',
          'inspire_inside_dunamis',
        ];
      case 'inside_dunamis':
        return const [
          'inside_dunamis',
          'articles',
          'inside_dunamis_articles',
          'inspire_inside_dunamis',
        ];
      case 'wordification':
        return const ['wordification', 'inspire_wordification'];
      case 'motivation':
        return const ['motivation', 'inspire_motivation'];
      case 'sod':
        return const ['sod', 'sod_quotes'];
      default:
        return [normalized];
    }
  }

  static String _normalizeBucketKey(String value) {
    final key = value.trim().toLowerCase();

    switch (key) {
      case 'highlight':
      case 'message_highlights':
      case 'message_highlight':
      case 'inspire_message_highlights':
        return 'highlights';
      case 'inside_dunamis':
      case 'inside_dunamis_articles':
      case 'inspire_inside_dunamis':
      case 'article':
        return 'articles';
      case 'seed_of_destiny':
      case 'seeds_of_destiny':
      case 'inspire_sod':
      case 'sod_quotes':
        return 'sod';
      case 'short_video':
      case 'short_videos':
      case 'short-videos':
      case 'short videos':
      case 'shorts':
      case 'inspire_short_videos':
        return 'short_videos';
      case 'inspire_wordification':
        return 'wordification';
      case 'inspire_motivation':
        return 'motivation';
      default:
        if (key.startsWith('inspire_')) return key.replaceFirst('inspire_', '');
        return key;
    }
  }

  static String _resolveRoute({
    required String explicitRoute,
    required String bucket,
  }) {
    final route = _normalizeAppRoute(explicitRoute.trim());
    if (route.isNotEmpty) return route;

    return _routeForBucket(bucket) ?? '';
  }

  static String _normalizeAppRoute(String route) {
    final clean = route.trim();
    if (clean.isEmpty) return '';

    if (clean.startsWith('/')) {
      final lowerPath = clean.toLowerCase();
      switch (lowerPath) {
        case '/watch/sod':
        case '/watch/sod/':
        case '/watch/read-sod':
        case '/watch/read_sod':
        case '/watch/seed-of-destiny':
        case '/inspire/sod':
        case '/inspire/read-sod':
        case '/inspire/read_sod':
        case '/sod/read':
          return '/inspire';

        case '/watch/sod-quotes':
        case '/watch/sod_quotes':
        case '/watch/sod/quotes':
        case '/inspire/sod-quotes':
        case '/inspire/sod_quotes':
        case '/sod-quotes':
          return '/sod/quotes';

        case '/watch/sod-keypoints':
        case '/watch/sod_keypoints':
        case '/watch/sod/keypoints':
        case '/inspire/sod-keypoints':
        case '/inspire/sod/keypoints':
        case '/sod-keypoints':
          return '/sod/keypoints';

        case '/inspire/highlights':
        case '/inspire/message-highlights':
        case '/inspire/message_highlights':
          return '/highlights';

        case '/inspire/wordification':
          return '/wordification';

        case '/inspire/motivation':
          return '/motivation';

        case '/inspire/articles':
        case '/inspire/inside-dunamis':
        case '/inspire/inside_dunamis':
          return '/articles';

        case '/inspire/short-videos':
        case '/inspire/short_videos':
        case '/short-videos':
        case '/shorts':
          return '/short-videos';

        default:
          return clean;
      }
    }

    final uri = Uri.tryParse(clean);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return clean;
    }

    final lower = clean.toLowerCase();

    switch (lower) {
      case 'read sod':
      case 'reader sod':
      case 'read_sod':
      case 'read-sod':
      case 'read seed of destiny':
      case 'reader study':
      case "reader's study":
      case 'readers study':
        return '/sod';

      case 'watch sod':
      case 'watch_sod':
      case 'watch-sod':
      case 'watch seed of destiny':
      case 'watcher study':
      case "watcher's study":
      case 'watchers study':
        return '/watch';

      case 'sod quiz':
      case 'sod_quiz':
      case 'sod-quiz':
      case 'seed of destiny quiz':
        return '/tab/sod_quiz';

      case 'sod quote':
      case 'sod quotes':
      case 'seed of destiny quote':
      case 'seed of destiny quotes':
        return '/sod/quotes';

      default:
        return '';
    }
  }

  static String? _routeForBucket(String bucket) {
    switch (_normalizeBucketKey(bucket)) {
      case 'sod':
        return '/sod';
      case 'highlights':
        return '/highlights';
      case 'wordification':
        return '/wordification';
      case 'articles':
        return '/articles';
      case 'motivation':
        return '/motivation';
      case 'short_videos':
        return '/short-videos';
      default:
        return null;
    }
  }

  static String _titleForBucket(String bucket) {
    switch (_normalizeBucketKey(bucket)) {
      case 'sod':
        return 'Seeds Of Destiny';
      case 'highlights':
        return 'Message Highlights';
      case 'wordification':
        return 'Wordification';
      case 'articles':
        return 'Inside Dunamis / Articles';
      case 'motivation':
        return 'Motivation';
      case 'short_videos':
        return 'Short Videos';
      default:
        return _humanizeBucket(bucket);
    }
  }

  static String _defaultSubtitleForBucket(String bucket) {
    switch (_normalizeBucketKey(bucket)) {
      case 'sod':
        return 'Read SOD • Watch SOD • SOD Quotes';
      case 'highlights':
        return 'Powerful sermon insights';
      case 'wordification':
        return 'Scripture explained and applied';
      case 'articles':
        return 'Teachings, insights and ministry updates';
      case 'motivation':
        return 'Short encouragement messages';
      case 'short_videos':
        return 'Watch short inspirational video feeds';
      default:
        return 'Open and explore available content';
    }
  }

  static IconData _iconForBucket(String bucket) {
    switch (_normalizeBucketKey(bucket)) {
      case 'sod':
        return Icons.menu_book_rounded;
      case 'highlights':
        return Icons.flash_on_rounded;
      case 'wordification':
        return Icons.lightbulb_rounded;
      case 'articles':
        return Icons.article_rounded;
      case 'motivation':
        return Icons.favorite_rounded;
      case 'short_videos':
        return Icons.play_circle_fill_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  static IconData _iconForBackendValue(
    String value, {
    required IconData fallback,
  }) {
    final icon = value.trim().toLowerCase().replaceAll('-', '_');
    if (icon.isEmpty) return fallback;

    if (icon.contains('read') ||
        icon.contains('book') ||
        icon.contains('study')) {
      return Icons.menu_book_rounded;
    }
    if (icon.contains('watch') ||
        icon.contains('play') ||
        icon.contains('video') ||
        icon.contains('tv')) {
      return Icons.play_circle_fill_rounded;
    }
    if (icon.contains('quote') || icon.contains('format_quote')) {
      return Icons.format_quote_rounded;
    }
    if (icon.contains('quiz') ||
        icon.contains('question') ||
        icon.contains('help')) {
      return Icons.quiz_rounded;
    }
    if (icon.contains('light') || icon.contains('word')) {
      return Icons.lightbulb_rounded;
    }
    if (icon.contains('heart') || icon.contains('favorite')) {
      return Icons.favorite_rounded;
    }
    if (icon.contains('flash') || icon.contains('highlight')) {
      return Icons.flash_on_rounded;
    }
    if (icon.contains('article') || icon.contains('blog')) {
      return Icons.article_rounded;
    }

    return fallback;
  }

  static String _adKeyForBucket(String bucket) {
    switch (_normalizeBucketKey(bucket)) {
      case 'sod':
        return 'inspire.sod';
      case 'highlights':
        return 'inspire.highlights';
      case 'wordification':
        return 'inspire.wordification';
      case 'articles':
        return 'inspire.articles';
      case 'motivation':
        return 'inspire.motivation';
      case 'short_videos':
        return 'inspire.short_videos';
      default:
        return tabKey;
    }
  }

  static String _humanizeBucket(String value) {
    final cleaned = _normalizeBucketKey(value);
    if (cleaned.isEmpty) return AppConfig.tabInspireLabel;

    return cleaned
        .split('_')
        .where((part) => part.trim().isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static String? _pickImage(Map<String, dynamic>? item) {
    if (item == null || item.isEmpty) return null;

    const directKeys = [
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

    final payload = item['payload'];
    if (payload is Map) {
      final cover = payload['cover'];
      if (cover is Map) {
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

    final media = item['media'];
    if (media is Map) {
      for (final key in directKeys) {
        final value = media[key];
        final s = value?.toString().trim() ?? '';
        if (s.isNotEmpty) return s;
      }
    }

    final meta = item['meta'];
    if (meta is Map) {
      for (final key in directKeys) {
        final value = meta[key];
        final s = value?.toString().trim() ?? '';
        if (s.isNotEmpty) return s;
      }
    }

    return null;
  }

  static String _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      final s = value?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }

    final meta = map['meta'];
    if (meta is Map) {
      for (final key in keys) {
        final value = meta[key];
        final s = value?.toString().trim() ?? '';
        if (s.isNotEmpty) return s;
      }
    }

    return '';
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
      'assets/images/home_2.jpg',
      'assets/images/home_4.jpg',
      'assets/images/home_5.jpg',
      'assets/images/home_3.jpg',
      'assets/images/home_1.jpg',
    ];
    return assets[index % assets.length];
  }

  static void _openInspireRoute(
    BuildContext context,
    String route, {
    String title = 'Open',
  }) {
    final normalized = _normalizeAppRoute(route);

    if (normalized.trim().isEmpty || normalized == '/inspire') {
      return;
    }

    if (normalized.startsWith('/coming-soon')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This feature is coming soon.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(normalized);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      if (_isYoutubeUrl(normalized)) {
        context.push(
          '/player/youtube',
          extra: {
            'title': title.trim().isNotEmpty ? title.trim() : 'YouTube',
            'url': normalized,
          },
        );
        return;
      }

      context.push(
        '/web',
        extra: {
          'title': title.trim().isNotEmpty ? title.trim() : 'Open',
          'url': normalized,
        },
      );
      return;
    }

    context.push(normalized);
  }
}

class _InspireSectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isLight;

  const _InspireSectionLabel({
    required this.title,
    required this.subtitle,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.trim().isNotEmpty ? title.trim() : 'Section',
          style: TextStyle(
            color: isLight ? const Color(0xFF16131F) : Colors.white,
            fontSize: 18,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            subtitle.trim(),
            style: TextStyle(
              color: isLight
                  ? const Color(0xFF665E70)
                  : Colors.white.withOpacity(0.66),
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _ShortVideoEntryData {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final int count;
  final String route;
  final String adKey;
  final List<ShortVideoItem> items;
  final List<InspireShortVideoPreview> previews;

  const _ShortVideoEntryData({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.count,
    required this.route,
    required this.adKey,
    required this.items,
    required this.previews,
  });
}

class _InspireAdEntry {
  final bool isAd;
  final _InspireCardData? card;
  final int itemIndex;
  final String adLabel;

  const _InspireAdEntry.card({
    required this.card,
    required this.itemIndex,
  })  : isAd = false,
        adLabel = '';

  const _InspireAdEntry.ad({
    required this.itemIndex,
    required this.adLabel,
  })  : isAd = true,
        card = null;
}

class _InspireCardData {
  final String bucket;
  final String title;
  final String subtitle;
  final int badgeCount;
  final IconData icon;
  final String? imageUrl;
  final String route;
  final String adKey;
  final bool isSectionHeader;
  final bool renderAsGrid;
  final int gridColumns;
  final int sectionChildCount;

  const _InspireCardData({
    required this.bucket,
    required this.title,
    required this.subtitle,
    required this.badgeCount,
    required this.icon,
    required this.imageUrl,
    required this.route,
    required this.adKey,
    this.isSectionHeader = false,
    this.renderAsGrid = false,
    this.gridColumns = 2,
    this.sectionChildCount = 0,
  });
}

class _InspireGridSection extends StatelessWidget {
  final _InspireCardData header;
  final List<_InspireAdEntry> entries;
  final bool isLight;
  final Future<void> Function(_InspireCardData target) onOpen;

  const _InspireGridSection({
    required this.header,
    required this.entries,
    required this.isLight,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 12),
            child: _InspireSectionLabel(
              title: header.title,
              subtitle: header.subtitle,
              isLight: isLight,
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final spacing = 12.0;
              final configuredColumns = header.gridColumns.clamp(1, 4);
              final columns =
                  constraints.maxWidth < 340 && configuredColumns > 2
                      ? 2
                      : configuredColumns;
              final tileWidth =
                  (constraints.maxWidth - (spacing * (columns - 1))) / columns;
              final tileHeight = (tileWidth * 1.08).clamp(154.0, 220.0);

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: entries.map((entry) {
                  final card = entry.card!;
                  return SizedBox(
                    width: tileWidth,
                    height: tileHeight,
                    child: _InspireGridTile(
                      title: card.title,
                      subtitle: card.subtitle,
                      icon: card.icon,
                      imageUrl: card.imageUrl,
                      fallbackAsset: InspireScreen._fallbackAssetFor(
                        entry.itemIndex,
                      ),
                      onTap: () => onOpen(card),
                    ),
                  );
                }).toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InspireGridTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? imageUrl;
  final String fallbackAsset;
  final VoidCallback onTap;

  const _InspireGridTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned.fill(
                  child: _CardBackgroundImage(
                    imageUrl: imageUrl,
                    fallbackAsset: fallbackAsset,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.08),
                          Colors.black.withOpacity(0.20),
                          Colors.black.withOpacity(0.76),
                        ],
                        stops: const [0.0, 0.48, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.16),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (subtitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.84),
                            fontSize: 11.5,
                            height: 1.18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

class _InspireImageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int badgeCount;
  final IconData icon;
  final String? imageUrl;
  final String fallbackAsset;
  final VoidCallback onTap;
  final bool isLight;

  const _InspireImageCard({
    required this.title,
    required this.subtitle,
    required this.badgeCount,
    required this.icon,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.onTap,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final shadowColor = isLight
        ? Colors.black.withOpacity(0.10)
        : Colors.black.withOpacity(0.22);

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
                color: shadowColor,
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
                  child: _CardBackgroundImage(
                    imageUrl: imageUrl,
                    fallbackAsset: fallbackAsset,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isLight
                            ? [
                                Colors.black.withOpacity(0.08),
                                Colors.black.withOpacity(0.18),
                                Colors.black.withOpacity(0.58),
                              ]
                            : [
                                Colors.black.withOpacity(0.18),
                                Colors.black.withOpacity(0.28),
                                Colors.black.withOpacity(0.72),
                              ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.10),
                      ),
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
                          color: Colors.black.withOpacity(0.28),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.14),
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
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
                                fontSize: 13,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _Badge(count: badgeCount),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withOpacity(0.82),
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

class _CardBackgroundImage extends StatelessWidget {
  final String? imageUrl;
  final String fallbackAsset;

  const _CardBackgroundImage({
    required this.imageUrl,
    required this.fallbackAsset,
  });

  @override
  Widget build(BuildContext context) {
    final remote = (imageUrl ?? '').trim();

    if (_isRemoteImage(remote)) {
      return Image.network(
        remote,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          fallbackAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF1B1B2A),
          ),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: const Color(0xFF1B1B2A),
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
        color: const Color(0xFF1B1B2A),
      ),
    );
  }

  bool _isRemoteImage(String value) {
    if (value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }
}

class _Badge extends StatelessWidget {
  final int count;

  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 34),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isLight;

  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isLight
        ? Colors.white.withOpacity(0.92)
        : Colors.white.withOpacity(0.04);
    final border =
        isLight ? const Color(0xFFE6E8F0) : Colors.white.withOpacity(0.08);
    final iconColor = isLight ? const Color(0xFF7C3AED) : Colors.white;
    final titleColor = isLight ? const Color(0xFF1E1B16) : Colors.white;
    final subtitleColor =
        isLight ? const Color(0xFF5E6472) : Colors.white.withOpacity(0.76);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: iconColor,
            size: 26,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 13.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
