import '../models/dynamic_section.dart';
import '../models/short_video_item.dart';

class ShortVideoMapper {
  const ShortVideoMapper._();

  static List<ShortVideoItem> fromSections(List<HubDynamicSection> sections) {
    final items = <ShortVideoItem>[];
    for (final section in sections) {
      if (!section.enabled) continue;
      final isShortSection =
          section.layout == HubDynamicSectionLayout.shortVideoFeed ||
              _containsShortVideoSignal([
                section.key,
                section.title,
                section.subtitle,
                section.type,
                section.layout.name,
                section.settings,
              ]);
      if (!isShortSection) continue;
      for (final item in section.items) {
        final sectionChannel = _firstNonEmpty([
          section.settings['source_channel'],
          section.settings['channel_key'],
          section.settings['channel'],
          section.settings['short_channel_key'],
          section.key,
        ]);
        final merged = <String, dynamic>{
          ...item,
          '_section_key': section.key,
          '_section_title': section.title,
          '_section_subtitle': section.subtitle,
          '_section_type': section.type,
          '_section_layout': section.layout.name,
          '_section_settings': section.settings,
          '_section_source_channel': sectionChannel,
          '_source_channel': sectionChannel,
        };
        final short = ShortVideoItem.fromMap(merged);
        if (!short.enabled || !short.hasVideo) continue;
        items.add(short);
      }
    }
    return _dedupe(items);
  }

  static List<ShortVideoItem> fromRawList(List<dynamic> rawItems) {
    final items = <ShortVideoItem>[];
    for (final raw in rawItems) {
      if (raw is! Map) continue;
      final map = raw.map((key, value) => MapEntry(key.toString(), value));
      final item = ShortVideoItem.fromMap(map);
      if (!item.enabled || !item.hasVideo) continue;
      items.add(item);
    }
    return _dedupe(items);
  }

  static List<ShortVideoItem> fromRawHub(Map<String, dynamic> rawHub) {
    final rawItems = <dynamic>[];
    void addItems(dynamic value) {
      if (value is List) rawItems.addAll(value);
    }

    void addSectionItems(Map<String, dynamic> section) {
      final items = section['items'];
      if (items is! List) return;

      final sectionChannel = _sectionChannelKey(section);
      for (final item in items) {
        final itemMap = _asMap(item);
        if (itemMap == null) continue;
        rawItems.add({
          ...itemMap,
          '_section_key': _stringValue(section['key'] ?? section['section_key']),
          '_section_title': _stringValue(section['title']),
          '_section_subtitle': _stringValue(section['subtitle']),
          '_section_type': _stringValue(section['type']),
          '_section_layout': _stringValue(section['layout']),
          '_section_tab_key': _stringValue(section['tab_key']),
          '_section_route_key': _stringValue(section['route_key']),
          '_section_source_channel': sectionChannel,
          '_source_channel': sectionChannel,
        });
      }
    }

    void scanSections(dynamic value) {
      if (value is List) {
        for (final raw in value) {
          if (raw is! Map) continue;
          final section =
              raw.map((key, value) => MapEntry(key.toString(), value));
          if (!_isShortSection(section)) continue;
          addSectionItems(section);
        }
        return;
      }
      if (value is Map) {
        final map = value.map((key, value) => MapEntry(key.toString(), value));
        for (final key in const [
          'sections',
          'dynamic_sections',
          'builder_sections',
          'cards',
          'hub_cards',
          'items'
        ]) {
          scanSections(map[key]);
        }
      }
    }

    addItems(rawHub['short_videos']);
    addItems(rawHub['shorts']);
    scanSections(rawHub['sections']);
    final sectionsByTab = _asMap(rawHub['sections_by_tab']);
    if (sectionsByTab != null) {
      scanSections(sectionsByTab['home']);
      scanSections(sectionsByTab['inspire']);
      scanSections(sectionsByTab['watch']);
      scanSections(sectionsByTab['explore']);
    }
    scanSections(rawHub['home']);
    scanSections(rawHub['inspire']);
    scanSections(rawHub['watch']);
    scanSections(rawHub['explore']);
    return fromRawList(rawItems);
  }

  static HubDynamicSection toSection({
    required String key,
    required String title,
    required String subtitle,
    required List<ShortVideoItem> items,
    int order = 0,
  }) {
    return HubDynamicSection(
      key: key,
      title: title,
      subtitle: subtitle,
      layout: HubDynamicSectionLayout.shortVideoFeed,
      columns: 1,
      rows: 1,
      enabled: true,
      items: items.map((item) => item.raw).toList(growable: false),
      settings: {
        'type': 'short_video_feed',
        'source': 'short_video_mapper',
        'order': order
      },
    );
  }

  static List<ShortVideoCategory> categoriesFor(List<ShortVideoItem> items) {
    final categories = <String, ShortVideoCategory>{};
    for (final item in items) {
      final key = item.categoryKey;
      if (key.isEmpty) continue;
      categories.putIfAbsent(
        key,
        () => ShortVideoCategory(
          key: key,
          label: item.categoryLabel.trim().isNotEmpty
              ? item.categoryLabel.trim()
              : _humanize(key),
        ),
      );
    }
    final list = categories.values.toList(growable: false);
    list.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return list;
  }

  static bool _isShortSection(Map<String, dynamic> section) {
    return _containsShortVideoSignal([
      section['key'],
      section['section_key'],
      section['title'],
      section['subtitle'],
      section['type'],
      section['layout'],
      section['template'],
      section['bucket'],
      section['source'],
      section['route_key'],
      section['slug'],
      section['payload'],
      section['meta'],
      section['settings'],
    ]);
  }

  static bool _containsShortVideoSignal(List<dynamic> values) {
    final buffer = StringBuffer();
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
        for (final item in value) add(item);
        return;
      }
      buffer.write(' ');
      buffer.write(value.toString());
    }

    for (final value in values) add(value);
    final lower = buffer.toString().toLowerCase();
    return lower.contains('short_video') ||
        lower.contains('short videos') ||
        lower.contains('short-videos') ||
        lower.contains('shorts') ||
        lower.contains('reel') ||
        lower.contains('vertical_video');
  }

  static List<ShortVideoItem> _dedupe(List<ShortVideoItem> items) {
    final out = <ShortVideoItem>[];
    final seen = <String>{};
    for (final item in items) {
      final channel = _sectionChannelKey(item.raw);
      final signature = [
        item.safeId.trim().toLowerCase(),
        item.videoUrl.trim().toLowerCase(),
        channel.isEmpty ? '_global' : channel,
      ].join('|');
      if (seen.contains(signature)) continue;
      seen.add(signature);
      out.add(item);
    }
    return out;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map)
      return value.map((key, value) => MapEntry(key.toString(), value));
    return null;
  }

  static String _sectionChannelKey(Map<String, dynamic> section) {
    final source = _asMap(section['source']);
    final settings = _asMap(section['settings']);
    final payload = _asMap(section['payload']);
    final meta = _asMap(section['meta']);
    return _normalizeKey(_firstNonEmpty([
      section['source_channel'],
      section['channel_key'],
      section['channel'],
      section['short_channel_key'],
      section['_section_source_channel'],
      section['_source_channel'],
      source?['channel'],
      source?['channel_key'],
      source?['source_channel'],
      settings?['channel'],
      settings?['channel_key'],
      settings?['source_channel'],
      payload?['channel'],
      payload?['channel_key'],
      payload?['source_channel'],
      meta?['channel'],
      meta?['channel_key'],
      meta?['source_channel'],
    ]));
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }

  static String _stringValue(dynamic value) {
    final text = (value ?? '').toString().trim();
    if (text.toLowerCase() == 'null') return '';
    return text;
  }

  static String _normalizeKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  static String _humanize(String key) {
    final clean = key.trim().replaceAll('-', ' ').replaceAll('_', ' ');
    if (clean.isEmpty) return 'General';
    return clean
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .map((part) {
      final lower = part.toLowerCase();
      return lower.substring(0, 1).toUpperCase() + lower.substring(1);
    }).join(' ');
  }
}

class ShortVideoCategory {
  final String key;
  final String label;
  const ShortVideoCategory({required this.key, required this.label});
}
