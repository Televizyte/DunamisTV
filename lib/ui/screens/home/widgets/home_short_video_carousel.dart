import 'package:flutter/material.dart';

import '../../../../features/hub/models/short_video_item.dart';
import '../../../../features/hub/renderer/short_video_mapper.dart';
import '../../inspire/widgets/inspire_short_video_entry.dart';

class HomeShortVideoCarousel extends StatelessWidget {
  final Map<String, dynamic> rawHub;
  final bool isLight;
  final void Function(String route) onTap;

  const HomeShortVideoCarousel({
    super.key,
    required this.rawHub,
    required this.isLight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final entry = _HomeShortVideoData.fromRawHub(rawHub);

    if (entry == null || entry.previews.isEmpty) {
      return _ShortVideoFallbackCard(
        isLight: isLight,
        onTap: () => onTap('/short-videos'),
      );
    }

    return InspireShortVideoEntry(
      title: entry.title,
      subtitle: entry.subtitle,
      previews: entry.previews,
      count: entry.count,
      isLight: isLight,
      reelItems: entry.items,
      onTap: (route) {
        final normalized = _normalizeRoute(route);
        onTap(normalized.isNotEmpty ? normalized : '/short-videos');
      },
    );
  }
}

class _ShortVideoFallbackCard extends StatelessWidget {
  final bool isLight;
  final VoidCallback onTap;

  const _ShortVideoFallbackCard({required this.isLight, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isLight
                  ? const [
                      Color(0xFFFFFFFF),
                      Color(0xFFEDE9FE),
                      Color(0xFFFCE7F3),
                    ]
                  : const [
                      Color(0xFF0B1535),
                      Color(0xFF351168),
                      Color(0xFFB40A72),
                    ],
            ),
            border: Border.all(
              color: isLight
                  ? const Color(0xFFE6D8C3)
                  : Colors.white.withOpacity(0.10),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withOpacity(isLight ? 0.70 : 0.14),
                  border: Border.all(color: Colors.white.withOpacity(0.16)),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: isLight ? const Color(0xFF4B1D8A) : Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Short Videos',
                      style: TextStyle(
                        color: isLight ? const Color(0xFF1E1B16) : Colors.white,
                        fontSize: 17,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Open the short video feed',
                      style: TextStyle(
                        color: isLight
                            ? const Color(0xFF6B6256)
                            : Colors.white.withOpacity(0.76),
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: isLight
                    ? const Color(0xFF4B1D8A)
                    : Colors.white.withOpacity(0.84),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeShortVideoData {
  final String title;
  final String subtitle;
  final int count;
  final List<InspireShortVideoPreview> previews;
  final List<ShortVideoItem> items;

  const _HomeShortVideoData({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.previews,
    required this.items,
  });

  static _HomeShortVideoData? fromRawHub(Map<String, dynamic> rawHub) {
    final homeEntry = _fromSections(_homeShortVideoSections(rawHub));
    if (homeEntry != null && homeEntry.previews.isNotEmpty) return homeEntry;

    // Fallback only when Home has no short-video items yet. This keeps one
    // clean Home section while still reusing the active short-video engine data.
    final inspireEntry = _fromSections(_inspireShortVideoSections(rawHub));
    if (inspireEntry != null && inspireEntry.previews.isNotEmpty) {
      return inspireEntry;
    }

    return null;
  }

  static _HomeShortVideoData? _fromSections(
    List<Map<String, dynamic>> sections,
  ) {
    for (final section in sections) {
      if (!_boolValue(
        section['enabled'] ?? section['is_enabled'],
        fallback: true,
      )) {
        continue;
      }

      if (!_isShortVideoSection(section)) continue;

      final items = _itemsWithSectionContext(section, _listValue(section['items']));
      final previews = _buildPreviews(items);
      final reelItems = ShortVideoMapper.fromRawList(items);
      if (previews.isEmpty && reelItems.isEmpty) continue;

      final title = _firstNonEmpty([
        _stringValue(section['title']),
        _stringValue(_mapValue(section['meta'])?['title']),
        _stringValue(_mapValue(section['settings'])?['title']),
        'Short Videos',
      ]);

      final subtitle = _firstNonEmpty([
        _stringValue(section['subtitle']),
        _stringValue(_mapValue(section['meta'])?['subtitle']),
        _stringValue(_mapValue(section['settings'])?['subtitle']),
        'Watch short inspirational video feeds',
      ]);

      final count = _intValue(section['items_count']) ??
          _intValue(section['count']) ??
          _intValue(section['badge_count']) ??
          previews.length;

      return _HomeShortVideoData(
        title: title,
        subtitle: subtitle,
        count: count > 0 ? count : previews.length,
        previews: previews,
        items: reelItems,
      );
    }

    return null;
  }

  static List<Map<String, dynamic>> _homeShortVideoSections(
    Map<String, dynamic> rawHub,
  ) {
    final sections = <Map<String, dynamic>>[];

    sections.addAll(_sectionsFrom(rawHub['home']));
    sections.addAll(_sectionsFrom(_mapValue(rawHub['pages'])?['home']));
    sections.addAll(_sectionsFrom(_mapValue(rawHub['builder'])?['home']));

    final sectionsByTab = _mapValue(rawHub['sections_by_tab']);
    sections.addAll(_sectionsFrom(sectionsByTab?['home']));

    final topLevelShortVideos = _listValue(rawHub['short_videos']);
    if (topLevelShortVideos.isNotEmpty) {
      sections.add({
        'key': 'home_short_videos',
        'title': 'Short Videos',
        'subtitle': 'Watch short inspirational video feeds',
        'type': 'short_video_feed',
        'route': '/short-videos',
        'items': topLevelShortVideos,
        'count': topLevelShortVideos.length,
      });
    }

    final allSections = _listValue(rawHub['sections']);
    for (final raw in allSections) {
      final map = _mapValue(raw);
      if (map == null) continue;

      final tabKey = _stringValue(map['tab_key']).toLowerCase();
      if (tabKey == 'home' || tabKey.isEmpty) sections.add(map);
    }

    return sections;
  }

  static List<Map<String, dynamic>> _inspireShortVideoSections(
    Map<String, dynamic> rawHub,
  ) {
    final sections = <Map<String, dynamic>>[];

    sections.addAll(_sectionsFrom(rawHub['inspire']));
    sections.addAll(_sectionsFrom(_mapValue(rawHub['pages'])?['inspire']));
    sections.addAll(_sectionsFrom(_mapValue(rawHub['builder'])?['inspire']));

    final sectionsByTab = _mapValue(rawHub['sections_by_tab']);
    sections.addAll(_sectionsFrom(sectionsByTab?['inspire']));

    final allSections = _listValue(rawHub['sections']);
    for (final raw in allSections) {
      final map = _mapValue(raw);
      if (map == null) continue;

      final tabKey = _stringValue(map['tab_key']).toLowerCase();
      if (tabKey == 'inspire') sections.add(map);
    }

    return sections;
  }

  static List<Map<String, dynamic>> _sectionsFrom(dynamic value) {
    final output = <Map<String, dynamic>>[];

    if (value is List) {
      for (final item in value) {
        final map = _mapValue(item);
        if (map != null) output.add(map);
      }
      return output;
    }

    final map = _mapValue(value);
    if (map == null) return output;

    for (final key in const [
      'sections',
      'dynamic_sections',
      'builder_sections',
      'cards',
      'items',
      'hub_cards',
    ]) {
      final rawList = map[key];
      if (rawList is! List) continue;

      for (final item in rawList) {
        final itemMap = _mapValue(item);
        if (itemMap != null) output.add(itemMap);
      }
    }

    return output;
  }

  static List<Map<String, dynamic>> _itemsWithSectionContext(
    Map<String, dynamic> section,
    List<dynamic> items,
  ) {
    final sectionChannel = _firstNonEmpty([
      _stringValue(section['source_channel']),
      _stringValue(section['channel_key']),
      _stringValue(section['channel']),
      _stringValue(_mapValue(section['source'])?['source_channel']),
      _stringValue(_mapValue(section['source'])?['channel_key']),
      _stringValue(_mapValue(section['settings'])?['source_channel']),
      _stringValue(_mapValue(section['settings'])?['channel_key']),
    ]);

    final output = <Map<String, dynamic>>[];
    for (final item in items) {
      final map = _mapValue(item);
      if (map == null) continue;
      output.add({
        ...map,
        '_section_key': _stringValue(section['key'] ?? section['section_key']),
        '_section_title': _stringValue(section['title']),
        '_section_subtitle': _stringValue(section['subtitle']),
        '_section_tab_key': _stringValue(section['tab_key']),
        '_section_route_key': _stringValue(section['route_key']),
        '_section_source_channel': sectionChannel,
        '_source_channel': sectionChannel,
      });
    }
    return output;
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
      buffer.write(_stringValue(map[key]));
    }

    for (final nestedKey in const ['payload', 'meta', 'settings']) {
      final nested = _mapValue(map[nestedKey]);
      if (nested == null) continue;

      for (final value in nested.values) {
        buffer.write(' ');
        buffer.write(_stringValue(value));
      }
    }

    final lower = buffer.toString().toLowerCase();

    return lower.contains('short_video') ||
        lower.contains('short videos') ||
        lower.contains('short-videos') ||
        lower.contains('shorts') ||
        lower.contains('reel') ||
        lower.contains('vertical_video');
  }

  static List<InspireShortVideoPreview> _buildPreviews(
    List<dynamic> rawItems,
  ) {
    final previews = <InspireShortVideoPreview>[];

    for (final raw in rawItems) {
      final map = _mapValue(raw);
      if (map == null) continue;

      if (!_boolValue(
        map['enabled'] ??
            map['is_enabled'] ??
            map['active'] ??
            map['is_active'],
        fallback: true,
      )) {
        continue;
      }

      final image = _pickImage(map);
      final videoUrl = _firstNonEmpty([
        _stringValue(map['video_url']),
        _stringValue(map['url']),
        _stringValue(_mapValue(map['payload'])?['video_url']),
        _stringValue(_mapValue(map['payload'])?['url']),
        _stringValue(_mapValue(map['meta'])?['video_url']),
      ]);

      if ((image ?? '').trim().isEmpty && videoUrl.trim().isEmpty) continue;

      final route = _normalizeRoute(
        _firstNonEmpty([
          _stringValue(map['route']),
          _stringValue(map['path']),
          _stringValue(map['href']),
          _stringValue(_mapValue(map['payload'])?['route']),
          _stringValue(_mapValue(map['payload'])?['target_route']),
          _stringValue(_mapValue(map['meta'])?['route']),
          _stringValue(_mapValue(map['meta'])?['target_route']),
          '/short-videos',
        ]),
      );

      previews.add(
        InspireShortVideoPreview(
          title: _firstNonEmpty([
            _stringValue(map['title']),
            _stringValue(map['name']),
            _stringValue(map['label']),
            'Short Video',
          ]),
          subtitle: _firstNonEmpty([
            _stringValue(map['subtitle']),
            _stringValue(map['description']),
            _stringValue(map['summary']),
            _stringValue(map['caption']),
            _stringValue(map['badge']),
            'Tap to watch',
          ]),
          imageUrl: image,
          route: _routeWithItemTarget(
            route.isNotEmpty ? route : '/short-videos',
            map,
          ),
        ),
      );
    }

    final unique = <InspireShortVideoPreview>[];
    final seen = <String>{};

    for (final item in previews) {
      final key = [
        item.route.trim().toLowerCase(),
        (item.imageUrl ?? '').trim().toLowerCase(),
        item.title.trim().toLowerCase(),
      ].join('|');

      if (seen.contains(key)) continue;
      seen.add(key);
      unique.add(item);

    }

    return unique;
  }

  static String _routeWithItemTarget(String route, Map<String, dynamic> map) {
    final base = route.trim().isEmpty ? '/short-videos' : route.trim();
    final rawId = _stringValue(map['id']);
    final normalizedRawId = rawId.replaceFirst(RegExp(r'^short_video_'), '');
    final itemId = _firstNonEmpty([
      _stringValue(map['content_id']),
      _stringValue(map['post_id']),
      normalizedRawId,
      _stringValue(_mapValue(map['payload'])?['content_id']),
      _stringValue(_mapValue(map['payload'])?['post_id']),
    ]);
    final channel = _firstNonEmpty([
      _stringValue(map['_section_source_channel']),
      _stringValue(map['source_channel']),
      _stringValue(map['channel_key']),
      _stringValue(map['channel']),
      _stringValue(_mapValue(map['source'])?['source_channel']),
      _stringValue(_mapValue(map['source'])?['channel_key']),
    ]);

    final uri = Uri.tryParse(base);
    final path = uri?.path.trim().isNotEmpty == true ? uri!.path : '/short-videos';
    final params = <String, String>{
      if (uri != null) ...uri.queryParameters,
      if (itemId.isNotEmpty) 'id': itemId,
      if (itemId.isNotEmpty) 'content_id': itemId,
      if (itemId.isNotEmpty) 'post_id': itemId,
      if (channel.isNotEmpty) 'channel': channel,
      if (channel.isNotEmpty) 'channel_key': channel,
    };
    return Uri(
      path: path,
      queryParameters: params.isEmpty ? null : params,
    ).toString();
  }
}

Map<String, dynamic>? _mapValue(dynamic value) {
  if (value is Map<String, dynamic>) return value;

  if (value is Map) {
    return value.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  return null;
}

List<dynamic> _listValue(dynamic value) {
  if (value is List) return value;
  return const [];
}

String _stringValue(dynamic value) {
  return (value ?? '').toString().trim();
}

String _firstNonEmpty(List<String> values) {
  for (final value in values) {
    final clean = value.trim();
    if (clean.isNotEmpty) return clean;
  }

  return '';
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

int? _intValue(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value.toString().trim());
}

String _normalizeRoute(String route) {
  final clean = route.trim();
  if (clean.isEmpty) return '';

  final uri = Uri.tryParse(clean);
  final path = uri?.path.toLowerCase() ?? clean.toLowerCase();

  switch (path) {
    case '/inspire/short-videos':
    case '/inspire/short_videos':
    case '/short-video':
    case '/shorts':
      final query = uri?.hasQuery == true ? '?${uri!.query}' : '';
      return '/short-videos$query';
    default:
      return clean;
  }
}

String? _pickImage(Map<String, dynamic>? item) {
  if (item == null || item.isEmpty) return null;

  const directKeys = [
    'image_url',
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
    'card_image_url',
    'background_image_url',
  ];

  for (final key in directKeys) {
    final value = _stringValue(item[key]);
    if (value.isNotEmpty) return value;
  }

  for (final nestedKey in const ['payload', 'media', 'meta', 'settings']) {
    final nested = _mapValue(item[nestedKey]);
    if (nested == null) continue;

    final cover = _mapValue(nested['cover']);
    if (cover != null) {
      for (final key in directKeys) {
        final value = _stringValue(cover[key]);
        if (value.isNotEmpty) return value;
      }
    }

    for (final key in directKeys) {
      final value = _stringValue(nested[key]);
      if (value.isNotEmpty) return value;
    }
  }

  return null;
}
