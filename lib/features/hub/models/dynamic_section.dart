import 'package:flutter/material.dart';

import 'native_engine_action.dart';

enum HubDynamicSectionLayout {
  hero,
  carousel,
  horizontalScroll,
  verticalList,
  grid,
  iconGrid,
  compact,
  toolGrid,
  quote,
  scripture,
  videoFeed,
  shortVideoFeed,
  adBlock,
  unknown,
}

class HubDynamicSection {
  final String key;
  final String title;
  final String subtitle;
  final HubDynamicSectionLayout layout;
  final int columns;
  final int rows;
  final bool enabled;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> settings;

  const HubDynamicSection({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.layout,
    required this.columns,
    required this.rows,
    required this.enabled,
    required this.items,
    required this.settings,
  });

  factory HubDynamicSection.fromMap(Map<String, dynamic> map) {
    final settings = _asMap(map['settings']) ??
        _asMap(map['settings_json']) ??
        _asMap(map['meta']) ??
        const <String, dynamic>{};

    final layoutRaw = _firstNonEmpty([
      map['layout_type'],
      map['layout'],
      map['section_type'],
      map['type'],
      settings['layout_type'],
      settings['layout'],
      settings['section_type'],
      settings['type'],
    ]);

    return HubDynamicSection(
      key: _firstNonEmpty([
        map['key'],
        map['slug'],
        map['route_key'],
        map['id'],
        map['title'],
      ]),
      title: _firstNonEmpty([
        map['title'],
        map['name'],
        map['label'],
        settings['title'],
      ]),
      subtitle: _firstNonEmpty([
        map['subtitle'],
        map['description'],
        map['summary'],
        settings['subtitle'],
        settings['description'],
      ]),
      layout: parseLayout(layoutRaw),
      columns: _intValue(
        _firstNonEmpty([
          map['columns'],
          map['column_count'],
          settings['columns'],
          settings['column_count'],
        ]),
        fallback: 2,
        min: 1,
        max: 6,
      ),
      rows: _intValue(
        _firstNonEmpty([
          map['rows'],
          map['row_count'],
          settings['rows'],
          settings['row_count'],
        ]),
        fallback: 1,
        min: 1,
        max: 20,
      ),
      enabled: _boolValue(
        _firstNonEmpty([
          map['enabled'],
          map['is_enabled'],
          map['active'],
          map['is_active'],
          settings['enabled'],
          settings['is_enabled'],
        ]),
        fallback: true,
      ),
      items: _itemsFromDynamic(
        map['items'] ??
            map['children'] ??
            map['cards'] ??
            map['content'] ??
            map['data'],
      ),
      settings: {
        ...settings,
        if (map['type'] != null) 'type': map['type'],
        if (map['section_type'] != null) 'section_type': map['section_type'],
        if (map['layout_type'] != null) 'layout_type': map['layout_type'],
        if (map['layout'] != null) 'layout': map['layout'],
        if (map['order'] != null) 'order': map['order'],
        if (map['position'] != null) 'position': map['position'],
        if (map['sort_order'] != null) 'sort_order': map['sort_order'],
        if (map['bucket'] != null) 'bucket': map['bucket'],
        if (map['source'] != null) 'source': map['source'],
      },
    );
  }

  static HubDynamicSectionLayout parseLayout(String value) {
    final raw = value.trim().toLowerCase().replaceAll('-', '_');

    switch (raw) {
      case 'hero':
      case 'hero_card':
      case 'featured_large':
        return HubDynamicSectionLayout.hero;
      case 'carousel':
      case 'banner_slider':
      case 'slider':
        return HubDynamicSectionLayout.carousel;
      case 'horizontal':
      case 'horizontal_scroll':
      case 'horizontal_list':
        return HubDynamicSectionLayout.horizontalScroll;
      case 'list':
      case 'vertical':
      case 'vertical_list':
        return HubDynamicSectionLayout.verticalList;
      case 'grid':
      case 'content_grid':
        return HubDynamicSectionLayout.grid;
      case 'icon_grid':
      case 'icons':
      case 'menu_grid':
        return HubDynamicSectionLayout.iconGrid;
      case 'compact':
      case 'compact_list':
      case 'compact_cards':
        return HubDynamicSectionLayout.compact;
      case 'tool':
      case 'tools':
      case 'tool_grid':
      case 'tool_launcher':
        return HubDynamicSectionLayout.toolGrid;
      case 'quote':
      case 'quote_card':
      case 'quote_cards':
      case 'quote_feed':
      case 'quote_carousel':
      case 'quote_channel':
      case 'dynamic_quote_card':
      case 'daily_quote':
        return HubDynamicSectionLayout.quote;
      case 'scripture':
      case 'scripture_card':
      case 'daily_scripture':
        return HubDynamicSectionLayout.scripture;
      case 'video':
      case 'videos':
      case 'video_feed':
        return HubDynamicSectionLayout.videoFeed;
      case 'short':
      case 'shorts':
      case 'short_feed':
      case 'short_video_feed':
        return HubDynamicSectionLayout.shortVideoFeed;
      case 'ad':
      case 'ads':
      case 'ad_block':
      case 'advert':
        return HubDynamicSectionLayout.adBlock;
      default:
        return HubDynamicSectionLayout.unknown;
    }
  }

  String get type => _firstNonEmpty([
        settings['type'],
        settings['section_type'],
        settings['content_type'],
        settings['source'],
        settings['bucket'],
        layout.name,
      ]);

  int get order {
    final raw = _firstNonEmpty([
      settings['order'],
      settings['position'],
      settings['sort_order'],
      settings['display_order'],
      settings['index'],
    ]);

    return int.tryParse(raw) ?? 0;
  }

  bool get hasItems => items.isNotEmpty;

  bool get isToolSection => layout == HubDynamicSectionLayout.toolGrid;

  bool get isAdSection => layout == HubDynamicSectionLayout.adBlock;

  HubDynamicSection copyWith({
    String? key,
    String? title,
    String? subtitle,
    HubDynamicSectionLayout? layout,
    int? columns,
    int? rows,
    bool? enabled,
    List<Map<String, dynamic>>? items,
    Map<String, dynamic>? settings,
  }) {
    return HubDynamicSection(
      key: key ?? this.key,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      layout: layout ?? this.layout,
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      enabled: enabled ?? this.enabled,
      items: items ?? this.items,
      settings: settings ?? this.settings,
    );
  }
}

class HubDynamicCard {
  final String key;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String route;
  final String url;
  final String badge;
  final String type;
  final String engine;
  final IconData icon;
  final bool enabled;
  final Map<String, dynamic> raw;

  const HubDynamicCard({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.route,
    required this.url,
    required this.badge,
    required this.type,
    required this.engine,
    required this.icon,
    required this.enabled,
    required this.raw,
  });

  factory HubDynamicCard.fromMap(Map<String, dynamic> map) {
    final payload = _asMap(map['payload']) ?? const <String, dynamic>{};
    final source = _asMap(map['source']) ?? const <String, dynamic>{};
    final display = _asMap(map['display']) ?? const <String, dynamic>{};
    final itemBuilder = _asMap(map['item_builder']) ??
        _asMap(payload['item_builder']) ??
        const <String, dynamic>{};

    final title = _firstNonEmpty([
      map['title'],
      map['quote_text'],
      map['quote'],
      payload['quote_text'],
      payload['quote'],
      map['name'],
      map['label'],
    ]);

    final route = _firstNonEmpty([
      map['route'],
      map['target_route'],
      map['screen_route'],
      map['path'],
      payload['route'],
      payload['target_route'],
    ]);

    final type = _firstNonEmpty([
      map['type'],
      map['content_type'],
      map['item_type'],
      itemBuilder['kind'],
      source['type'],
    ]);

    final engine = _firstNonEmpty([
      map['engine'],
      map['native_engine'],
      map['action_engine'],
      map['tool'],
      map['tool_key'],
      map['content_engine'],
      map['engine_key'],
      itemBuilder['source_type'],
      source['type'],
      type,
    ]);

    return HubDynamicCard(
      key: _firstNonEmpty([
        map['key'],
        map['slug'],
        map['id'],
        title,
      ]),
      title: title,
      subtitle: _firstNonEmpty([
        map['subtitle'],
        map['quote_source'],
        map['source'],
        payload['quote_source'],
        payload['source'],
        map['description'],
        map['summary'],
        map['caption'],
      ]),
      imageUrl: _firstNonEmpty([
        map['image_url'],
        map['cover_image_url'],
        map['card_image_url'],
        map['thumbnail_url'],
        payload['image_url'],
        payload['cover_image_url'],
        payload['card_image_url'],
        payload['thumbnail_url'],
        map['thumbnail'],
        map['image'],
      ]),
      route: route,
      url: _firstNonEmpty([
        map['url'],
        map['action_url'],
        map['external_url'],
        map['link'],
        map['video_url'],
        map['stream_url'],
        map['web_url'],
      ]),
      badge: _firstNonEmpty([
        map['badge'],
        map['pill'],
        map['label'],
        display['badge'],
        itemBuilder['kind'],
      ]),
      type: type,
      engine: engine,
      icon: _iconForValue('$title $route $type $engine'),
      enabled: _boolValue(
        _firstNonEmpty([
          map['enabled'],
          map['is_enabled'],
          map['active'],
          map['is_active'],
        ]),
        fallback: true,
      ),
      raw: map,
    );
  }

  NativeEngineAction get nativeAction {
    return NativeEngineAction.fromMap({
      ...raw,
      'engine': engine,
      'route': route,
      'title': title,
      'url': url,
      'content_id': key,
    });
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return null;
}

List<Map<String, dynamic>> _itemsFromDynamic(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];

  return value
      .whereType<Map>()
      .map((item) => item.map((key, val) => MapEntry(key.toString(), val)))
      .toList(growable: false);
}

String _firstNonEmpty(List<dynamic> values) {
  for (final value in values) {
    if (value == null) continue;
    if (value is Map || value is Iterable) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

int _intValue(
  dynamic value, {
  required int fallback,
  required int min,
  required int max,
}) {
  final raw = (value ?? '').toString().trim();
  final parsed = int.tryParse(raw);
  if (parsed == null) return fallback;
  if (parsed < min) return min;
  if (parsed > max) return max;
  return parsed;
}

bool _boolValue(dynamic value, {required bool fallback}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;

  final raw = value.toString().trim().toLowerCase();
  if (raw.isEmpty) return fallback;

  if (raw == '1' || raw == 'true' || raw == 'yes' || raw == 'on') return true;
  if (raw == '0' || raw == 'false' || raw == 'no' || raw == 'off') {
    return false;
  }

  return fallback;
}

IconData _iconForValue(String value) {
  final lower = value.toLowerCase();

  if (lower.contains('quote')) return Icons.format_quote_rounded;
  if (lower.contains('note')) return Icons.sticky_note_2_rounded;
  if (lower.contains('bible') || lower.contains('scripture')) {
    return Icons.menu_book_rounded;
  }
  if (lower.contains('game')) return Icons.sports_esports_rounded;
  if (lower.contains('watch') || lower.contains('live')) {
    return Icons.live_tv_rounded;
  }
  if (lower.contains('video') || lower.contains('short')) {
    return Icons.play_circle_fill_rounded;
  }
  if (lower.contains('article') || lower.contains('read')) {
    return Icons.article_rounded;
  }
  if (lower.contains('web') || lower.contains('link')) {
    return Icons.language_rounded;
  }
  if (lower.contains('music')) return Icons.music_note_rounded;
  if (lower.contains('podcast')) return Icons.podcasts_rounded;
  if (lower.contains('event')) return Icons.event_rounded;
  if (lower.contains('prayer')) return Icons.volunteer_activism_rounded;

  return Icons.apps_rounded;
}
