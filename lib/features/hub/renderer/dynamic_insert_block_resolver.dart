import '../models/dynamic_section.dart';

class DynamicInsertBlockResolver {
  const DynamicInsertBlockResolver._();

  static List<HubDynamicSection> extractSections(
    Map<String, dynamic> tabPayload, {
    required List<String> targetBuckets,
    bool requireItems = true,
    bool excludeRootTargetSections = true,
  }) {
    final rawSections = tabPayload['sections'];
    if (rawSections is! List) return const <HubDynamicSection>[];

    final normalizedTargets = targetBuckets
        .map(_normalize)
        .where((value) => value.isNotEmpty)
        .toSet();
    if (normalizedTargets.isEmpty) return const <HubDynamicSection>[];

    final out = <HubDynamicSection>[];
    final seen = <String>{};

    for (final raw in rawSections) {
      if (raw is! Map) continue;
      final map = raw.cast<String, dynamic>();
      if (!_isBackendControlledInsertSection(
        map,
        normalizedTargets,
        excludeRootTargetSections: excludeRootTargetSections,
      )) {
        continue;
      }

      final section = HubDynamicSection.fromMap(map);
      if (!section.enabled) continue;
      if (requireItems && section.items.isEmpty && !isAdSection(section)) {
        continue;
      }

      final signature = '${section.key}|${section.title}|${section.order}';
      if (!seen.add(signature)) continue;
      out.add(section);
    }

    out.sort((a, b) {
      final after = insertAfter(a).compareTo(insertAfter(b));
      if (after != 0) return after;
      return a.order.compareTo(b.order);
    });
    return out;
  }

  static List<HubDynamicSection> topSections(List<HubDynamicSection> sections) {
    return sections.where((section) {
      final placement = placementType(section);
      return insertAfter(section) <= 0 ||
          placement == 'before_list' ||
          placement == 'after_featured' ||
          placement == 'top' ||
          placement == 'start';
    }).toList(growable: false);
  }

  static List<HubDynamicSection> inlineSections(
    List<HubDynamicSection> sections,
  ) {
    final top = topSections(sections).toSet();
    return sections.where((section) => !top.contains(section)).toList(
          growable: false,
        );
  }

  static bool isShortVideoSection(HubDynamicSection section) {
    final text = _sectionHaystack(section);
    return section.layout == HubDynamicSectionLayout.shortVideoFeed ||
        text.contains('short_video') ||
        text.contains('short_videos') ||
        text.contains('shorts') ||
        text.contains('reel');
  }

  static bool isQuoteSection(HubDynamicSection section) {
    final text = _sectionHaystack(section);
    return section.layout == HubDynamicSectionLayout.quote ||
        section.layout == HubDynamicSectionLayout.scripture ||
        text.contains('quote') ||
        text.contains('scripture') ||
        text.contains('daily_scripture');
  }

  static bool isAdSection(HubDynamicSection section) {
    final text = _sectionHaystack(section);
    return section.layout == HubDynamicSectionLayout.adBlock ||
        text.contains('ad_block') ||
        text.contains('native_ad') ||
        text.contains('advert');
  }

  static int insertAfter(HubDynamicSection section, {int fallback = 3}) {
    final raw = _firstNonEmpty([
      section.settings['insert_after_items'],
      section.settings['insert_after_item'],
      section.settings['insert_after'],
      section.settings['after_items'],
      section.settings['position_after'],
      section.settings['after_item'],
    ]);
    return int.tryParse(raw) ?? fallback;
  }

  static String placementType(HubDynamicSection section) {
    return _normalize(_firstNonEmpty([
      section.settings['placement_type'],
      section.settings['placement'],
      section.settings['insert_position'],
    ]));
  }

  static bool _isBackendControlledInsertSection(
    Map<String, dynamic> section,
    Set<String> normalizedTargets, {
    required bool excludeRootTargetSections,
  }) {
    final settings = _flattenSectionSettings(section);
    String value(String key) => (settings[key] ?? '').toString().trim();

    final key = _normalize(_firstNonEmpty([
      value('key'),
      value('section_key'),
      section['key'],
      section['section_key'],
      section['slug'],
    ]));
    final title = _normalize(_firstNonEmpty([
      section['title'],
      settings['title'],
      section['name'],
    ]));

    if (excludeRootTargetSections &&
        (normalizedTargets.contains(key) ||
            normalizedTargets.contains(title))) {
      return false;
    }

    final placement = _normalize(_firstNonEmpty([
      value('placement_type'),
      value('placement'),
      value('insert_position'),
    ]));

    final targetValues = <String>{
      _normalize(value('insert_target_bucket')),
      _normalize(value('target_bucket')),
      _normalize(value('target_page')),
      _normalize(value('target_section')),
      _normalize(value('parent_section_key')),
      _normalize(value('parent_bucket')),
      _normalize(value('parent')),
      _normalize(value('route_key')),
    }..removeWhere((value) => value.isEmpty);

    final targetsPage = targetValues.any(normalizedTargets.contains) ||
        normalizedTargets.any((target) =>
            key.startsWith('${target}_') || key.endsWith('_$target'));
    if (!targetsPage) return false;

    final insertPlacement = placement.isEmpty ||
        placement == 'inside_content_list' ||
        placement == 'inside_list' ||
        placement == 'after_featured' ||
        placement == 'before_list' ||
        placement == 'after_item' ||
        placement == 'after_items' ||
        placement == 'end_of_page' ||
        placement == 'top' ||
        placement == 'start';
    if (!insertPlacement) return false;

    final sectionForLayout = HubDynamicSection.fromMap(section);
    if (_isRenderableByLayout(sectionForLayout)) return true;

    final searchText = _searchText(section);
    return searchText.contains('short_video') ||
        searchText.contains('shorts') ||
        searchText.contains('quote') ||
        searchText.contains('scripture') ||
        searchText.contains('book') ||
        searchText.contains('tool') ||
        searchText.contains('card') ||
        searchText.contains('ad_block') ||
        searchText.contains('native_ad');
  }

  static bool _isRenderableByLayout(HubDynamicSection section) {
    switch (section.layout) {
      case HubDynamicSectionLayout.hero:
      case HubDynamicSectionLayout.carousel:
      case HubDynamicSectionLayout.horizontalScroll:
      case HubDynamicSectionLayout.verticalList:
      case HubDynamicSectionLayout.grid:
      case HubDynamicSectionLayout.iconGrid:
      case HubDynamicSectionLayout.compact:
      case HubDynamicSectionLayout.toolGrid:
      case HubDynamicSectionLayout.quote:
      case HubDynamicSectionLayout.scripture:
      case HubDynamicSectionLayout.videoFeed:
      case HubDynamicSectionLayout.shortVideoFeed:
      case HubDynamicSectionLayout.adBlock:
        return true;
      case HubDynamicSectionLayout.unknown:
        return false;
    }
  }

  static Map<String, dynamic> _flattenSectionSettings(
    Map<String, dynamic> section,
  ) {
    final settings = <String, dynamic>{};
    void merge(dynamic value) {
      if (value is! Map) return;
      value.forEach((key, val) => settings[key.toString()] = val);
    }

    merge(section);
    merge(section['source']);
    merge(section['meta']);
    merge(section['settings']);
    merge(section['payload']);
    return settings;
  }

  static String _sectionHaystack(HubDynamicSection section) {
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
        for (final child in value.values) add(child);
        return;
      }
      if (value is List) {
        for (final child in value) add(child);
        return;
      }
      buffer.write(' ');
      buffer.write(value.toString());
    }

    add(section.settings);
    for (final item in section.items.take(3)) add(item);
    return _normalize(buffer.toString());
  }

  static String _searchText(Map<String, dynamic> map) {
    final buffer = StringBuffer();
    void add(dynamic value) {
      if (value == null) return;
      if (value is Map) {
        for (final child in value.values) add(child);
        return;
      }
      if (value is List) {
        for (final child in value) add(child);
        return;
      }
      buffer.write(' ');
      buffer.write(value.toString());
    }

    add(map);
    return _normalize(buffer.toString());
  }

  static String _firstNonEmpty(Iterable<dynamic> values) {
    for (final value in values) {
      final raw = value?.toString().trim() ?? '';
      if (raw.isNotEmpty && raw.toLowerCase() != 'null') return raw;
    }
    return '';
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(RegExp(r'[^a-z0-9/_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
