import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/hub/models/dynamic_section.dart';
import '../../../features/hub/models/short_video_item.dart';
import '../../../features/hub/renderer/short_video_mapper.dart';
import '../inspire/widgets/inspire_short_video_entry.dart';
import '../../../features/hub/state/hub_scope.dart';
import '../../shell/bottom_shell.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';
import '../../widgets/ads/native_inline_ad_tile.dart';
import '../../widgets/ads/native_list_injection.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  static const String tabKey = 'explore';

  @override
  Widget build(BuildContext context) {
    final hub = HubScope.of(context);

    return AnimatedBuilder(
      animation: hub,
      builder: (context, _) {
        final sections = _buildBackendSections(
          rawHub: hub.raw,
          backendTools: hub.exploreTools,
          fallbackImageUrl: hub.brandingBannerUrl ?? '',
        );
        final widgets = _buildSectionWidgets(
          sections: sections,
          onOpen: (item) => _openExploreItem(context, item),
        );

        return Scaffold(
          appBar: DxmTopBar(
            title: 'Explore',
            showMenu: true,
            onRefresh: hub.refresh,
          ),
          body: GradientPageBackground(
            child: RefreshIndicator(
              onRefresh: hub.refresh,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  14,
                  14,
                  14,
                  BottomShellInsets.of(context) + 12,
                ),
                children: [
                  if (widgets.isEmpty)
                    const _ExploreEmptyState()
                  else
                    ...widgets,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static List<Widget> _buildSectionWidgets({
    required List<_ExploreSectionData> sections,
    required ValueChanged<_ExploreItemData> onOpen,
  }) {
    final normalized = <_ExploreSectionData>[];
    final bookItems = <_ExploreItemData>[];
    var hasBooksSection = false;

    for (final section in sections) {
      if (_isBooksSection(section)) {
        hasBooksSection = true;
      }

      var effective = section;

      if (_isToolsSection(section)) {
        final tools = <_ExploreItemData>[];
        for (final item in section.items) {
          if (_isBookItem(item)) {
            bookItems.add(item);
          } else {
            tools.add(item);
          }
        }
        if (tools.isEmpty) {
          continue;
        }
        effective = section.copyWith(items: tools);
      }

      normalized.add(effective);
    }

    if (bookItems.isNotEmpty && !hasBooksSection) {
      normalized.add(
        _ExploreSectionData(
          key: 'books_resources',
          title: 'Books & Resources',
          subtitle: 'Browse books, reading tools and faith resources.',
          layout: 'grid',
          variant: 'image_grid',
          columns: 1,
          order: 60,
          placement: 'resources',
          items: bookItems,
        ),
      );
    }

    final ordered = [...normalized]..sort((a, b) {
        final priority = _sectionPriority(a).compareTo(_sectionPriority(b));
        if (priority != 0) {
          return priority;
        }
        final order = a.order.compareTo(b.order);
        if (order != 0) {
          return order;
        }
        return a.key.compareTo(b.key);
      });

    final widgets = <Widget>[];
    final entries =
        NativeListInjection.buildEntries(ordered, tabKey: 'explore');
    for (final entry in entries) {
      if (entry.isAd) {
        widgets.add(
          NativeInlineAdTile(
            key: ValueKey('explore.native.${entry.itemIndex}'),
            tabKey: 'explore',
            label: 'Sponsored',
            minHeight: 118,
            margin: const EdgeInsets.only(bottom: 24),
          ),
        );
        continue;
      }
      final section = entry.item!;
      widgets.add(
        _ExploreBackendSection(
          key: ValueKey('explore.section.${section.key}'),
          section: section,
          onOpen: onOpen,
        ),
      );
    }

    return widgets;
  }

  static int _sectionPriority(_ExploreSectionData section) {
    final explicit = ExploreReleaseContract.zonePriority(section.placement);
    if (explicit != null) return explicit;
    if (section.isCarousel) return 10;
    if (_isToolsSection(section)) return 20;
    if (_isShortsSection(section)) return 40;
    if (_isQuotesScriptureSection(section)) return 50;
    if (_isBooksSection(section)) return 60;
    if (_isGamesSection(section)) return 70;
    return 55;
  }

  static bool _isQuotesScriptureSection(_ExploreSectionData section) {
    final clean = '${section.key} ${section.title}'.toLowerCase();
    return clean.contains('quote library') ||
        clean.contains('quotes & scripture') ||
        clean.contains('quotes and scripture') ||
        clean.contains('scripture library');
  }

  static bool _isShortsSection(_ExploreSectionData section) {
    final clean = '${section.key} ${section.title}'.toLowerCase();
    return clean.contains('short') || clean.contains('reel');
  }

  static bool _isGamesSection(_ExploreSectionData section) {
    final clean = '${section.key} ${section.title}'.toLowerCase();
    return clean.contains('game');
  }

  static bool _isBooksSection(_ExploreSectionData section) {
    if (section.placement == 'resources') return true;
    final clean = '${section.key} ${section.title}'.toLowerCase();
    return clean.contains('book') || clean.contains('resource');
  }

  static bool _isBookItem(_ExploreItemData item) {
    final clean =
        '${item.title} ${item.route} ${item.sourceRoute}'.toLowerCase();
    if (ExploreReleaseContract.isQuoteLibraryRoute(item.route) ||
        ExploreReleaseContract.isShortVideoLibraryRoute(item.route)) {
      return false;
    }
    return clean.contains('book');
  }

  static bool _isToolsSection(_ExploreSectionData section) {
    final key = section.key.toLowerCase();
    final title = section.title.toLowerCase();
    return key == 'explore_tools' ||
        key.contains('quick_tools') ||
        title == 'tools' ||
        title == 'quick tools';
  }

  static List<_ExploreSectionData> _buildBackendSections({
    required Map<String, dynamic> rawHub,
    required List<Map<String, String>> backendTools,
    required String fallbackImageUrl,
  }) {
    final sectionsByKey = <String, _ExploreSectionData>{};
    final visited = <Object>{};

    bool isExploreSectionMap(Map<String, dynamic> sectionMap) {
      final tabKey = _firstNonEmpty([
        _firstString(sectionMap, const ['tab_key', 'tabKey']),
        _firstString(sectionMap, const ['destination_tab', 'destinationTab']),
      ]).toLowerCase();

      final routeKey = _firstString(sectionMap, const [
        'route_key',
        'routeKey',
        'page_key',
        'pageKey',
      ]).toLowerCase();

      final rawKey = _firstNonEmpty([
        _firstString(sectionMap, const [
          'key',
          'section_key',
          'sectionKey',
          'slug',
          'frontend_key',
          'frontendKey',
        ]),
        _firstStringFromNested(sectionMap, 'settings', const [
          'key',
          'section_key',
          'sectionKey',
          'frontend_key',
          'frontendKey',
        ]),
        _firstStringFromNested(sectionMap, 'meta', const [
          'key',
          'section_key',
          'sectionKey',
          'frontend_key',
          'frontendKey',
        ]),
      ]).toLowerCase();

      final title = _firstString(sectionMap, const [
        'title',
        'name',
        'label',
      ]).toLowerCase();

      return tabKey == tabKeyConstant ||
          routeKey == tabKeyConstant ||
          rawKey == tabKeyConstant ||
          rawKey.startsWith('${tabKeyConstant}_') ||
          rawKey.contains('_${tabKeyConstant}_') ||
          title == tabKeyConstant;
    }

    void putSection(_ExploreSectionData section) {
      final existing = sectionsByKey[section.key];
      if (existing == null) {
        sectionsByKey[section.key] = section;
        return;
      }

      // Keep the richest backend version if the same section appears in more
      // than one normalized container. This prevents a smaller legacy copy from
      // hiding a real AppsHub section with cards.
      final shouldReplace = section.items.length > existing.items.length ||
          (section.items.length == existing.items.length &&
              section.order <= existing.order);
      if (shouldReplace) sectionsByKey[section.key] = section;
    }

    void addSection(
      dynamic rawSection, {
      bool requireExploreOwnership = false,
    }) {
      final sectionMap = _asMap(rawSection);
      if (sectionMap == null || _isDisabled(sectionMap)) return;
      if (requireExploreOwnership && !isExploreSectionMap(sectionMap)) return;

      final section = _sectionFromMap(sectionMap);
      if (section == null || section.items.isEmpty) return;
      putSection(section);
    }

    void scanForExploreSections(dynamic node, {int depth = 0}) {
      if (depth > 9 || node == null) return;

      if (node is Map) {
        if (visited.contains(node)) return;
        visited.add(node);

        final map = node.cast<String, dynamic>();
        final rawItems = map['items'];
        if (rawItems is List && isExploreSectionMap(map)) {
          addSection(map, requireExploreOwnership: true);
        }

        // AppsHub may expose the same payload at different nesting levels,
        // depending on the endpoint version. Scan all values so the frontend
        // does not depend on one exact JSON shape.
        for (final value in map.values) {
          scanForExploreSections(value, depth: depth + 1);
        }
        return;
      }

      if (node is List) {
        if (visited.contains(node)) return;
        visited.add(node);

        for (final item in node) {
          scanForExploreSections(item, depth: depth + 1);
        }
      }
    }

    // Primary AppsHub shape: rawHub['sections'] contains all app sections.
    final allSections = rawHub['sections'];
    if (allSections is List) {
      for (final rawSection in allSections) {
        addSection(rawSection, requireExploreOwnership: true);
      }
    }

    // Secondary shapes used by older or normalized hub payloads.
    for (final key in const [
      'explore',
      'Explore',
      'explore_sections',
      'exploreSections',
    ]) {
      final exploreDirect = rawHub[key];
      if (exploreDirect is List) {
        for (final rawSection in exploreDirect) {
          addSection(rawSection, requireExploreOwnership: false);
        }
      } else {
        final exploreMap = _asMap(exploreDirect);
        if (exploreMap != null) {
          for (final sectionKey in const [
            'sections',
            'cards',
            'items',
            'hub_cards',
            'menu',
          ]) {
            final rawSections = exploreMap[sectionKey];
            if (rawSections is! List) continue;
            for (final rawSection in rawSections) {
              addSection(rawSection, requireExploreOwnership: false);
            }
          }
        }
      }
    }

    // Final safety net: search the whole raw hub tree for any section whose
    // tab_key/section_key points to Explore. This is what keeps carousel,
    // tools, games, and future Explore blocks visible even if AppsHub changes
    // the wrapper object name.
    scanForExploreSections(rawHub);

    final sections = sectionsByKey.values.toList(growable: false)
      ..sort((a, b) {
        final order = a.order.compareTo(b.order);
        if (order != 0) return order;
        return a.key.compareTo(b.key);
      });

    if (sections.isNotEmpty) return sections;

    final toolItems = _toolItemsFromLegacyBackend(
      backendTools: backendTools,
      fallbackImageUrl: fallbackImageUrl,
    );

    if (toolItems.isNotEmpty) {
      return [
        _ExploreSectionData(
          key: 'explore_tools',
          title: 'Tools',
          subtitle:
              'Open the built-in tools designed for reading, note taking, creativity and quick interaction.',
          layout: 'image_grid',
          variant: 'image_grid',
          columns: 2,
          order: 20,
          items: toolItems,
        ),
      ];
    }

    return const [];
  }

  static const String tabKeyConstant = 'explore';

  static _ExploreSectionData? _sectionFromMap(dynamic rawSection) {
    final section = _asMap(rawSection);
    if (section == null) return null;

    final rawItems = section['items'];
    if (rawItems is! List || rawItems.isEmpty) return null;

    final title = _firstNonEmpty([
      _firstString(section, const ['title', 'name', 'label']),
      _humanize(_firstString(section, const ['key', 'section_key', 'slug'])),
      'Explore',
    ]);

    final subtitle = _firstNonEmpty([
      _firstString(section, const [
        'subtitle',
        'description',
        'summary',
        'caption',
      ]),
      '',
    ]);

    final key = _normalizeKey(
      _firstNonEmpty([
        _firstString(section, const [
          'key',
          'section_key',
          'slug',
          'route_key',
        ]),
        title,
      ]),
    );

    final layout = _firstNonEmpty([
      _firstString(section, const [
        'layout',
        'layout_type',
        'template',
        'type',
        'card_layout',
      ]),
      _firstStringFromNested(section, 'settings', const [
        'layout',
        'layout_type',
        'template',
        'type',
        'card_layout',
      ]),
      _firstStringFromNested(section, 'meta', const [
        'layout',
        'layout_type',
        'template',
        'type',
        'card_layout',
      ]),
      'grid',
    ]).toLowerCase();

    final variant = _firstNonEmpty([
      _firstString(section, const [
        'layout_variant',
        'layoutVariant',
        'variant',
        'style',
      ]),
      _firstStringFromNested(section, 'settings', const [
        'layout_variant',
        'layoutVariant',
        'variant',
        'style',
      ]),
      _firstStringFromNested(section, 'meta', const [
        'layout_variant',
        'layoutVariant',
        'variant',
        'style',
      ]),
      'image_grid',
    ]).toLowerCase();

    final columns = _sectionColumns(section);
    final order = _intFromMap(section, const [
      'display_order',
      'order',
      'sort_order',
    ]);
    final placement = ExploreReleaseContract.normalizeZone(_firstNonEmpty([
      _firstString(section, const ['placement', 'placement_zone', 'zone']),
      _firstStringFromNested(
        section,
        'settings',
        const ['placement', 'placement_zone', 'zone'],
      ),
      _firstStringFromNested(
        section,
        'meta',
        const ['placement', 'placement_zone', 'zone'],
      ),
    ]));

    final items = <_ExploreItemData>[];
    for (final rawItem in rawItems) {
      final item = _itemFromMap(rawItem, parentKey: key);
      if (item != null && item.enabled) items.add(item);
    }

    items.sort((a, b) => a.order.compareTo(b.order));

    return _ExploreSectionData(
      key: key,
      title: title,
      subtitle: subtitle,
      layout: layout,
      variant: variant,
      columns: columns,
      order: order,
      placement: placement,
      items: items,
      dynamicSection: HubDynamicSection.fromMap(section),
    );
  }

  static List<_ExploreItemData> _toolItemsFromLegacyBackend({
    required List<Map<String, String>> backendTools,
    required String fallbackImageUrl,
  }) {
    final items = <_ExploreItemData>[];

    for (var index = 0; index < backendTools.length; index++) {
      final tool = backendTools[index];
      final title = _firstNonEmpty([tool['title'] ?? '', 'Tool']);
      final route = _mapBackendRoute(tool['route'] ?? '', title: title);

      if (route.trim().isEmpty || _isGamesRouteOrTitle(route, title)) continue;

      items.add(
        _ExploreItemData(
          title: title,
          subtitle: tool['subtitle'] ?? '',
          badge:
              tool['badge'] ?? _badgeForTitleOrSection(title, 'explore_tools'),
          icon: _iconFromText(tool['icon'] ?? title),
          imageUrl: _firstNonEmpty([tool['image_url'] ?? '', fallbackImageUrl]),
          route: route,
          actionType: tool['action_type'] ?? '',
          url: tool['url'] ?? '',
          youtubeUrl: tool['youtube_url'] ?? '',
          order: _parseInt(tool['display_order']) ?? ((index + 1) * 10),
          enabled: true,
          sourceRoute: tool['route'] ?? '',
        ),
      );
    }

    items.sort((a, b) => a.order.compareTo(b.order));
    return items;
  }

  static _ExploreItemData? _itemFromMap(
    dynamic rawItem, {
    required String parentKey,
  }) {
    final item = _asMap(rawItem);
    if (item == null) return null;

    final title = _firstNonEmpty([
      _firstString(item, const ['title', 'name', 'label']),
      'Item',
    ]);

    if (title.trim().isEmpty) return null;

    final rawRoute = _firstNonEmpty([
      _firstDeepStringForKeys(item, const [
        'engine_key',
        'engineKey',
        'action_key',
        'actionKey',
        'renderer_key',
        'rendererKey',
        'content_type',
        'contentType',
      ]),
      _firstDeepStringForKeys(item, const [
        'route',
        'path',
        'href',
        'target_route',
        'targetRoute',
        'page_key',
        'pageKey',
      ]),
      _firstActionRouteKey(item),
      _firstString(item, const ['slug']),
    ]);

    final actionType = _actionTypeFromItem(item);

    final url = _firstHttpStringFromItem(item, const [
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
      'backend_url',
      'backendUrl',
      'api_url',
      'apiUrl',
    ]);

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

    final route = _mapBackendRoute(
      rawRoute,
      title: title,
      parentKey: parentKey,
    );
    final enabled = !_isDisabled(item);

    return _ExploreItemData(
      title: title,
      subtitle: _firstString(item, const [
        'subtitle',
        'description',
        'summary',
        'caption',
      ]),
      badge: _firstNonEmpty([
        _firstString(item, const ['badge', 'badge_text', 'badgeText', 'tag']),
        _badgeForTitleOrSection(title, parentKey),
      ]),
      icon: _iconFromText(
        _firstNonEmpty([
          _firstString(item, const ['icon', 'icon_name', 'iconName']),
          title,
        ]),
      ),
      imageUrl: _pickImage(item),
      route: route,
      actionType: actionType,
      url: url,
      youtubeUrl: youtubeUrl,
      order: _intFromMap(item, const ['display_order', 'order', 'sort_order']),
      enabled: enabled,
      sourceRoute: rawRoute,
    );
  }

  static String _actionTypeFromItem(Map<String, dynamic> item) {
    final direct = _firstString(item, const [
      'action_type',
      'actionType',
      'tap_action',
      'tapAction',
    ]);
    if (direct.isNotEmpty) return direct;

    final action = item['action'];
    if (action is Map) {
      final type = (action['type'] ?? '').toString().trim();
      if (type.isNotEmpty) return type;
    }

    final payload = item['payload'];
    if (payload is Map) {
      final payloadMap = payload.cast<String, dynamic>();
      final payloadAction = payloadMap['action'];
      if (payloadAction is Map) {
        final type = (payloadAction['type'] ?? '').toString().trim();
        if (type.isNotEmpty) return type;
      }
    }

    return '';
  }

  static String _firstActionRouteKey(Map<String, dynamic> item) {
    final action = item['action'];
    if (action is Map) {
      final routeKey = _firstString(action.cast<String, dynamic>(), const [
        'route_key',
        'routeKey',
        'page_key',
        'pageKey',
        'slug',
      ]);
      if (routeKey.isNotEmpty) return routeKey;
    }

    final payload = item['payload'];
    if (payload is Map) {
      final payloadMap = payload.cast<String, dynamic>();
      final payloadAction = payloadMap['action'];
      if (payloadAction is Map) {
        final routeKey =
            _firstString(payloadAction.cast<String, dynamic>(), const [
          'route_key',
          'routeKey',
          'page_key',
          'pageKey',
          'slug',
        ]);
        if (routeKey.isNotEmpty) return routeKey;
      }
    }

    final meta = item['meta'];
    if (meta is Map) {
      final metaMap = meta.cast<String, dynamic>();
      final metaAction = metaMap['action'];
      if (metaAction is Map) {
        final routeKey =
            _firstString(metaAction.cast<String, dynamic>(), const [
          'route_key',
          'routeKey',
          'page_key',
          'pageKey',
          'slug',
        ]);
        if (routeKey.isNotEmpty) return routeKey;
      }
    }

    return '';
  }

  static void _openExploreItem(BuildContext context, _ExploreItemData item) {
    final action = item.actionType.trim().toLowerCase();
    final route = item.route.trim();
    final title = item.title.trim().isNotEmpty ? item.title.trim() : 'Open';

    if ((action.contains('youtube') || action.contains('video')) &&
        item.youtubeUrl.trim().isNotEmpty) {
      context.push(
        '/player/youtube',
        extra: {'title': title, 'url': item.youtubeUrl.trim()},
      );
      return;
    }

    if ((action.contains('web') ||
            action.contains('external') ||
            action.contains('url')) &&
        item.url.trim().isNotEmpty) {
      context.push('/web', extra: {'title': title, 'url': item.url.trim()});
      return;
    }

    if (item.youtubeUrl.trim().isNotEmpty) {
      context.push(
        '/player/youtube',
        extra: {'title': title, 'url': item.youtubeUrl.trim()},
      );
      return;
    }

    if (item.url.trim().isNotEmpty && route.isEmpty) {
      context.push('/web', extra: {'title': title, 'url': item.url.trim()});
      return;
    }

    if (route.isEmpty) return;

    final uri = Uri.tryParse(route);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      if (_isYoutubeUrl(route)) {
        context.push('/player/youtube', extra: {'title': title, 'url': route});
      } else {
        context.push('/web', extra: {'title': title, 'url': route});
      }
      return;
    }

    context.push(route);
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return value.cast<String, dynamic>();
    return null;
  }

  static String _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      final s = value?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }

    for (final nestedKey in const ['payload', 'meta', 'settings']) {
      final nested = map[nestedKey];
      if (nested is! Map) continue;
      final nestedMap = nested.cast<String, dynamic>();

      for (final key in keys) {
        final value = nestedMap[key];
        final s = value?.toString().trim() ?? '';
        if (s.isNotEmpty) return s;
      }
    }

    return '';
  }

  static String _firstStringFromNested(
    Map<String, dynamic> map,
    String nestedKey,
    List<String> keys,
  ) {
    final nested = map[nestedKey];
    if (nested is! Map) return '';
    return _firstString(nested.cast<String, dynamic>(), keys);
  }

  static String _firstDeepStringForKeys(
    Map<String, dynamic> map,
    List<String> keys, {
    int maxDepth = 4,
  }) {
    final visited = <Object>{};

    String walk(dynamic value, int depth) {
      if (depth > maxDepth || value == null) return '';

      if (value is Map) {
        if (visited.contains(value)) return '';
        visited.add(value);

        final typed = value.cast<String, dynamic>();
        for (final key in keys) {
          final candidate = typed[key]?.toString().trim() ?? '';
          if (candidate.isNotEmpty) return candidate;
        }

        for (final nestedValue in typed.values) {
          final result = walk(nestedValue, depth + 1);
          if (result.isNotEmpty) return result;
        }
      }

      if (value is List) {
        for (final item in value) {
          final result = walk(item, depth + 1);
          if (result.isNotEmpty) return result;
        }
      }

      return '';
    }

    return walk(map, 0);
  }

  static String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final clean = value.trim();
      if (clean.isNotEmpty) return clean;
    }
    return '';
  }

  static String _firstHttpStringFromItem(
    Map<String, dynamic> item,
    List<String> keys,
  ) {
    final visited = <Object>{};

    String walk(dynamic value, int depth) {
      if (depth > 5 || value == null) return '';

      if (value is Map) {
        if (visited.contains(value)) return '';
        visited.add(value);

        final typed = value.cast<String, dynamic>();
        for (final key in keys) {
          final candidate = typed[key]?.toString().trim() ?? '';
          if (_isHttpUrl(candidate)) return candidate;
        }

        for (final nestedValue in typed.values) {
          final result = walk(nestedValue, depth + 1);
          if (result.isNotEmpty) return result;
        }
      }

      if (value is List) {
        for (final item in value) {
          final result = walk(item, depth + 1);
          if (result.isNotEmpty) return result;
        }
      }

      return '';
    }

    return walk(item, 0);
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

  static String? _pickImage(Map<String, dynamic>? item) {
    if (item == null || item.isEmpty) return null;

    const keys = [
      'image_url',
      'imageUrl',
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

    for (final key in keys) {
      final value = item[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }

    for (final nestedKey in const ['payload', 'media', 'meta', 'settings']) {
      final nested = item[nestedKey];
      if (nested is! Map) continue;
      final nestedMap = nested.cast<String, dynamic>();

      for (final key in keys) {
        final value = nestedMap[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
    }

    return null;
  }

  static int _sectionColumns(Map<String, dynamic> section) {
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
        final parsed = _parseInt(map[key]);
        if (parsed != null) return parsed.clamp(1, 4).toInt();
      }
    }

    return 1;
  }

  static int _intFromMap(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final parsed = _parseInt(map[key]);
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static int? _parseInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString().trim());
  }

  static bool _isDisabled(Map<String, dynamic> item) {
    final raw = _firstNonEmpty([
      item['enabled']?.toString() ?? '',
      item['is_enabled']?.toString() ?? '',
      item['status']?.toString() ?? '',
    ]).toLowerCase();

    if (raw.isEmpty) return false;
    return raw == '0' ||
        raw == 'false' ||
        raw == 'disabled' ||
        raw == 'inactive' ||
        raw == 'off';
  }

  static String _mapBackendRoute(
    String rawRoute, {
    required String title,
    String parentKey = '',
  }) {
    final resolved =
        ExploreReleaseContract.resolveRoute(rawRoute, title: title);
    if (resolved.isNotEmpty) return resolved;
    final clean = rawRoute.trim();
    final lower = clean.toLowerCase();
    final lowerTitle = title.trim().toLowerCase();
    final lowerParent = parentKey.trim().toLowerCase();

    if (_isHttpUrl(clean)) return clean;

    // Direct game routes from AppsHub must open the actual game screen, not the
    // generic Games Hub. The Games Hub is only a listing page.
    if (lower == '/short-videos' ||
        lower == '/short-video' ||
        lower == '/shorts' ||
        lower == '/reels' ||
        lower.contains('short_video') ||
        lower.contains('short-video') ||
        lowerTitle.contains('short video') ||
        lowerTitle.contains('shorts')) {
      return '/short-videos';
    }

    if (lower.startsWith('/games/')) return clean;
    if (lowerTitle.contains('dominion match') ||
        lower.contains('dominion_match') ||
        lower.contains('dominion-match')) {
      return '/games/dominion-match';
    }
    if (lowerTitle.contains('race of faith') ||
        lowerTitle.contains('race off faith') ||
        lower.contains('race_of_faith') ||
        lower.contains('race-of-faith')) {
      return '/games/race-of-faith';
    }
    if (lowerTitle.contains('kingdom builder') ||
        lower.contains('kingdom-builder') ||
        lower.contains('kingdom_builder') ||
        lowerTitle.contains('dominion growth') ||
        lowerTitle.contains('dominion builder') ||
        lower.contains('dominion_growth') ||
        lower.contains('dominion-builder') ||
        lower.contains('dominion_builder')) {
      return '/games/kingdom-builder';
    }
    if (lowerTitle.contains('bible quiz') ||
        lower.contains('bible_quiz') ||
        lower.contains('bible-quiz')) {
      return '/games/bible-quiz';
    }

    if (lowerTitle.contains('quiz') || lower.contains('quiz')) {
      if (lowerTitle.contains('sod') || lower.contains('sod')) {
        return '/tab/sod_quiz';
      }
      if (lowerTitle.contains('bible') || lower.contains('bible')) {
        return '/tab/bible_quiz';
      }
      return clean.startsWith('/') ? clean : '/tab/quiz';
    }

    if (lowerTitle.contains('book reader') ||
        lower == 'books' ||
        lower == 'book_reader' ||
        lower == 'book-reader' ||
        lower == 'books_reader' ||
        lower == 'books-reader') {
      if (clean.startsWith('/') && clean != '/tools/books') return clean;
      return '/tab/books_reader';
    }

    if (lower == '/explore/quotes' ||
        lower == 'explore_quotes' ||
        lower == 'quote_creator' ||
        lower == 'quote-creator' ||
        lower == 'quotes' ||
        lowerTitle.contains('quote')) {
      return '/tools/quote';
    }

    if (lower == '/explore/notes' ||
        lower == 'explore_notes' ||
        lower == 'notes' ||
        lower == 'notepad' ||
        lowerTitle.contains('note')) {
      return '/tools/notes';
    }

    if (lower == '/explore/bible' ||
        lower == 'explore_bible' ||
        lower == 'bible' ||
        lowerTitle == 'bible' ||
        lowerTitle.contains('scripture')) {
      return '/tools/bible';
    }

    if (lower == '/explore/games' ||
        lower == 'explore_games' ||
        lower == 'games' ||
        lower == 'game' ||
        lowerParent == 'explore_games' ||
        lowerParent == 'games') {
      return '/games';
    }

    if (clean.startsWith('/')) return clean;
    if (clean.isNotEmpty) return '/tab/$clean';

    if (lowerParent.contains('game')) return '/games';

    return '';
  }

  static bool _isGamesRouteOrTitle(String route, String title) {
    final lowerRoute = route.trim().toLowerCase();
    final lowerTitle = title.trim().toLowerCase();
    return lowerRoute == '/games' ||
        lowerRoute == '/explore/games' ||
        lowerTitle == 'games' ||
        lowerTitle == 'game hub';
  }

  static String _badgeForTitleOrSection(String title, String parentKey) {
    final lowerTitle = title.toLowerCase();
    final lowerParent = parentKey.toLowerCase();

    if (lowerTitle.contains('quiz')) return 'QUIZ';
    if (lowerTitle.contains('book') || lowerTitle.contains('library')) {
      return 'BOOK';
    }
    if (lowerParent.contains('game') || lowerTitle.contains('game')) {
      return 'GAME';
    }
    if (lowerTitle.contains('bible')) return 'BIBLE';
    if (lowerTitle.contains('note')) return 'NOTE';
    if (lowerTitle.contains('quote')) return 'QUOTE';
    return 'TOOL';
  }

  static String _normalizeKey(String value) {
    return value.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
  }

  static String _humanize(String value) {
    final clean = _normalizeKey(value).replaceFirst('explore_', '');
    if (clean.isEmpty) return '';
    return clean
        .split('_')
        .where((part) => part.trim().isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static IconData _iconFromText(String value) {
    final lower = value.trim().toLowerCase();

    if (lower.contains('quote')) return Icons.format_quote_rounded;
    if (lower.contains('note')) return Icons.sticky_note_2_rounded;
    if (lower.contains('quiz')) return Icons.quiz_rounded;
    if (lower.contains('bible')) return Icons.menu_book_rounded;
    if (lower.contains('book') || lower.contains('library')) {
      return Icons.auto_stories_rounded;
    }
    if (lower.contains('game') || lower.contains('play')) {
      return Icons.sports_esports_rounded;
    }
    if (lower.contains('video') || lower.contains('watch')) {
      return Icons.play_circle_fill_rounded;
    }
    if (lower.contains('music') || lower.contains('audio')) {
      return Icons.music_note_rounded;
    }
    return Icons.apps_rounded;
  }
}

class ExploreReleaseContract {
  const ExploreReleaseContract._();

  static const _exactRoutes = <String>{
    '/quotes-scripture/library',
    '/quotes-scripture/reader',
    '/short-videos/library',
    '/short-videos',
    '/tools/quote',
    '/tools/books',
  };

  static String resolveRoute(String value, {String title = ''}) {
    final raw = value.trim();
    final key = normalizeKey(raw);
    if (_exactRoutes.contains(raw.toLowerCase())) return raw.toLowerCase();

    switch (key) {
      case 'quote_library':
      case 'quotes_library':
      case 'quotes_scripture':
      case 'quotes_scripture_library':
        return '/quotes-scripture/library';
      case 'short_video_library':
      case 'short_videos_library':
      case 'shorts_library':
        return '/short-videos/library';
      case 'short_video_feed':
      case 'short_videos':
      case 'short_video':
      case 'shorts':
      case 'reels':
        return '/short-videos';
      case 'quote_creator':
        return '/tools/quote';
      case 'books':
      case 'books_library':
      case 'book_reader':
      case 'books_reader':
        return '/tools/books';
    }

    final normalizedTitle = normalizeKey(title);
    if (normalizedTitle.contains('quote_library') ||
        normalizedTitle.contains('quotes_scripture')) {
      return '/quotes-scripture/library';
    }
    if (normalizedTitle.contains('short_video_library')) {
      return '/short-videos/library';
    }
    return '';
  }

  static bool isQuoteLibraryRoute(String value) =>
      resolveRoute(value) == '/quotes-scripture/library';

  static bool isShortVideoLibraryRoute(String value) =>
      resolveRoute(value) == '/short-videos/library';

  static String normalizeZone(String value) {
    final key = normalizeKey(value);
    const aliases = <String, String>{
      'featured': 'featured',
      'quick_tools': 'quick_tools',
      'tools': 'quick_tools',
      'media': 'media',
      'libraries': 'libraries',
      'library': 'libraries',
      'resources': 'resources',
      'resource': 'resources',
      'games': 'games',
      'custom': 'custom',
    };
    return aliases[key] ?? '';
  }

  static int? zonePriority(String value) {
    switch (normalizeZone(value)) {
      case 'featured':
        return 10;
      case 'quick_tools':
        return 20;
      case 'media':
        return 40;
      case 'libraries':
        return 50;
      case 'custom':
        return 55;
      case 'resources':
        return 60;
      case 'games':
        return 70;
    }
    return null;
  }

  static String normalizeKey(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

class _ExploreSectionData {
  final String key;
  final String title;
  final String subtitle;
  final String layout;
  final String variant;
  final int columns;
  final int order;
  final String placement;
  final List<_ExploreItemData> items;
  final HubDynamicSection? dynamicSection;

  const _ExploreSectionData({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.layout,
    required this.variant,
    required this.columns,
    required this.order,
    this.placement = '',
    required this.items,
    this.dynamicSection,
  });

  bool get isCarousel {
    final clean = '$key $layout $variant'.toLowerCase();
    return clean.contains('carousel') ||
        clean.contains('slider') ||
        clean.contains('banner_carousel');
  }

  _ExploreSectionData copyWith({
    String? title,
    String? subtitle,
    List<_ExploreItemData>? items,
  }) {
    return _ExploreSectionData(
      key: key,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      layout: layout,
      variant: variant,
      columns: columns,
      order: order,
      placement: placement,
      items: items ?? this.items,
      dynamicSection: dynamicSection,
    );
  }
}

class _ExploreItemData {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final String? imageUrl;
  final String route;
  final String actionType;
  final String url;
  final String youtubeUrl;
  final int order;
  final bool enabled;
  final String sourceRoute;

  const _ExploreItemData({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.imageUrl,
    required this.route,
    required this.actionType,
    required this.url,
    required this.youtubeUrl,
    required this.order,
    required this.enabled,
    required this.sourceRoute,
  });
}

bool _looksLikeShortVideoSection(HubDynamicSection section) {
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
      for (final entry in value.entries) {
        buffer.write(' ');
        buffer.write(entry.key);
        buffer.write(' ');
        add(entry.value);
      }
      return;
    }
    if (value is Iterable) {
      for (final item in value) {
        add(item);
      }
      return;
    }
    buffer.write(' ');
    buffer.write(value);
  }

  add(section.settings);

  final lower = buffer.toString().toLowerCase();
  return lower.contains('short_video') ||
      lower.contains('short videos') ||
      lower.contains('short-videos') ||
      lower.contains('shorts') ||
      lower.contains('reel');
}

class _ExploreToolsList extends StatelessWidget {
  final _ExploreSectionData section;
  final ValueChanged<_ExploreItemData> onOpen;

  const _ExploreToolsList({required this.section, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: section.items.map((item) {
        final subtitle = item.subtitle.trim().isNotEmpty
            ? item.subtitle.trim()
            : _toolSubtitle(item.title);

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: () => onOpen(item),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                constraints: const BoxConstraints(minHeight: 122),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF302071),
                      Color(0xFF702078),
                      Color(0xFFC00A7E),
                    ],
                  ),
                  border: Border.all(color: Colors.white24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 34),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.86),
                              fontSize: 13,
                              height: 1.32,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  String _toolSubtitle(String title) {
    final clean = title.toLowerCase();
    if (clean.contains('quote')) {
      return 'Create and share inspiring quote designs.';
    }
    if (clean.contains('note')) {
      return 'Capture ideas, messages and personal notes.';
    }
    if (clean.contains('bible') || clean.contains('scripture')) {
      return 'Read, search and study Scripture.';
    }
    return 'Open this tool and continue exploring.';
  }
}

class _ExploreBackendSection extends StatelessWidget {
  final _ExploreSectionData section;
  final ValueChanged<_ExploreItemData> onOpen;

  const _ExploreBackendSection({
    super.key,
    required this.section,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicSection = section.dynamicSection;
    final shortItems = dynamicSection == null
        ? const <ShortVideoItem>[]
        : ShortVideoMapper.fromRawList(dynamicSection.items);
    if (dynamicSection != null &&
        (dynamicSection.layout == HubDynamicSectionLayout.shortVideoFeed ||
            _looksLikeShortVideoSection(dynamicSection)) &&
        shortItems.isNotEmpty) {
      final visibleItems = shortItems
          .where((item) => item.enabled && item.hasVideo)
          .toList(growable: false);
      if (visibleItems.isEmpty) return const SizedBox.shrink();

      return InspireShortVideoEntry(
        title: section.title.trim().isNotEmpty
            ? section.title.trim()
            : 'Short Videos',
        subtitle: section.subtitle.trim(),
        previews: _shortVideoPreviewsFromItems(visibleItems),
        count: visibleItems.length,
        isLight: false,
        reelItems: visibleItems,
        onTap: (_) {},
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title.trim().isNotEmpty ? section.title.trim() : 'Explore',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              height: 1.1,
            ),
          ),
          if (section.subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              section.subtitle.trim(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.68),
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (ExploreScreen._isToolsSection(section))
            _ExploreToolsList(section: section, onOpen: onOpen)
          else if (section.isCarousel)
            _ExploreCarousel(section: section, onOpen: onOpen)
          else
            _ExploreSectionGrid(section: section, onOpen: onOpen),
        ],
      ),
    );
  }
}

List<InspireShortVideoPreview> _shortVideoPreviewsFromItems(
  List<ShortVideoItem> items,
) {
  return items.map((item) {
    final title =
        item.title.trim().isNotEmpty ? item.title.trim() : 'Short Video';
    final subtitle = item.description.trim().isNotEmpty
        ? item.description.trim()
        : (item.categoryLabel.trim().isNotEmpty
            ? item.categoryLabel.trim()
            : 'Tap to watch');

    return InspireShortVideoPreview(
      title: title,
      subtitle: subtitle,
      imageUrl:
          item.thumbnailUrl.trim().isNotEmpty ? item.thumbnailUrl.trim() : null,
      route: '/short-videos',
    );
  }).toList(growable: false);
}

class _ExploreCarousel extends StatefulWidget {
  final _ExploreSectionData section;
  final ValueChanged<_ExploreItemData> onOpen;

  const _ExploreCarousel({required this.section, required this.onOpen});

  @override
  State<_ExploreCarousel> createState() => _ExploreCarouselState();
}

class _ExploreCarouselState extends State<_ExploreCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.88);
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    final count = widget.section.items.length;
    if (count == 0) return;
    final safe = (index % count + count) % count;
    _controller.animateToPage(
      safe,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.section.items;
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: items.length,
                onPageChanged: (value) {
                  if (!mounted) return;
                  setState(() => _index = value);
                },
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _ExploreFeaturedLandscapeCard(
                      item: item,
                      onTap: () => widget.onOpen(item),
                    ),
                  );
                },
              ),
              if (items.length > 1)
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: _ExploreCircleButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _goTo(_index - 1),
                  ),
                ),
              if (items.length > 1)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: _ExploreCircleButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => _goTo(_index + 1),
                  ),
                ),
            ],
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              items.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: index == _index ? 17 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == _index
                      ? const Color(0xFFFF4DB8)
                      : Colors.white.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ExploreFeaturedLandscapeCard extends StatelessWidget {
  final _ExploreItemData item;
  final VoidCallback onTap;

  const _ExploreFeaturedLandscapeCard(
      {required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _ExploreImageCardShell(
      imageUrl: item.imageUrl,
      height: double.infinity,
      borderRadius: 22,
      onTap: onTap,
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -12,
            child: Icon(
              item.icon,
              size: 96,
              color: Colors.white.withOpacity(0.14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ExploreBadge(text: item.badge),
                const Spacer(),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.5,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (item.subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.subtitle.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.86),
                      fontSize: 11.5,
                      height: 1.22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      color: Colors.white.withOpacity(0.86),
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Open',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.86),
                          fontSize: 11.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ExploreCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.black.withOpacity(0.34),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

class _ExploreSectionGrid extends StatelessWidget {
  final _ExploreSectionData section;
  final ValueChanged<_ExploreItemData> onOpen;

  const _ExploreSectionGrid({required this.section, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final configuredColumns = section.columns.clamp(1, 4).toInt();
        final columns = constraints.maxWidth < 360 && configuredColumns > 2
            ? 2
            : configuredColumns;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        final useCompactTile = columns >= 2;
        final height = useCompactTile
            ? (width * 1.22).clamp(150.0, 210.0).toDouble()
            : 160.0;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: section.items.map((item) {
            return SizedBox(
              width: width,
              height: height,
              child: useCompactTile
                  ? _ExploreGridTile(item: item, onTap: () => onOpen(item))
                  : _ExploreBannerCard(
                      item: item,
                      onTap: () => onOpen(item),
                    ),
            );
          }).toList(growable: false),
        );
      },
    );
  }
}

class _ExploreBannerCard extends StatelessWidget {
  final _ExploreItemData item;
  final VoidCallback onTap;

  const _ExploreBannerCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _ExploreImageCardShell(
      imageUrl: item.imageUrl,
      height: 160,
      borderRadius: 22,
      onTap: onTap,
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: -12,
            child: Icon(
              item.icon,
              size: 92,
              color: Colors.white.withOpacity(0.13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ExploreBadge(text: item.badge),
                const Spacer(),
                Text(
                  item.title,
                  maxLines: 1,
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
                  item.subtitle.trim().isNotEmpty
                      ? item.subtitle.trim()
                      : 'Open item',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
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
    );
  }
}

class _ExploreGridTile extends StatelessWidget {
  final _ExploreItemData item;
  final VoidCallback onTap;

  const _ExploreGridTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _ExploreImageCardShell(
      imageUrl: item.imageUrl,
      height: double.infinity,
      borderRadius: 20,
      onTap: onTap,
      child: Stack(
        children: [
          Positioned(left: 10, top: 10, child: _ExploreBadge(text: item.badge)),
          Positioned(
            right: -7,
            bottom: -8,
            child: Icon(
              item.icon,
              size: 70,
              color: Colors.white.withOpacity(0.13),
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
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.8,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (item.subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.subtitle.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.82),
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
    );
  }
}

class _ExploreImageCardShell extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final double borderRadius;
  final Widget child;
  final VoidCallback onTap;

  const _ExploreImageCardShell({
    required this.imageUrl,
    required this.height,
    required this.borderRadius,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: Ink(
          height: height.isFinite ? height : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Stack(
              children: [
                Positioned.fill(child: _ExploreSmartImage(imageUrl: imageUrl)),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.10),
                          Colors.black.withOpacity(0.22),
                          Colors.black.withOpacity(0.74),
                        ],
                        stops: const [0.0, 0.42, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExploreSmartImage extends StatelessWidget {
  final String? imageUrl;

  const _ExploreSmartImage({required this.imageUrl});

  bool get _hasRemoteImage {
    final raw = (imageUrl ?? '').trim();
    if (raw.isEmpty) return false;

    final uri = Uri.tryParse(raw);
    if (uri == null) return false;
    if (!(uri.scheme == 'http' || uri.scheme == 'https')) return false;
    if (uri.host.trim().isEmpty) return false;
    if (uri.host.contains('your-real-')) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_hasRemoteImage) {
      return Image.network(
        imageUrl!.trim(),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _ExploreNeutralImage(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const _ExploreNeutralImage(showLoader: true);
        },
      );
    }

    return const _ExploreNeutralImage();
  }
}

class _ExploreNeutralImage extends StatelessWidget {
  final bool showLoader;

  const _ExploreNeutralImage({this.showLoader = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF162A57), Color(0xFF25294F), Color(0xFF5B164A)],
        ),
      ),
      alignment: Alignment.center,
      child: showLoader
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          : null,
    );
  }
}

class _ExploreBadge extends StatelessWidget {
  final String text;

  const _ExploreBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    final safeText = text.trim().isEmpty ? 'ITEM' : text.trim().toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Text(
        safeText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.2,
          letterSpacing: 0.4,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ExploreEmptyState extends StatelessWidget {
  const _ExploreEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(
        'No Explore sections are available right now. Add sections from AppsHub and refresh this page.',
        style: TextStyle(
          color: Colors.white.withOpacity(0.72),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }
}
