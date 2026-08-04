import '../models/dynamic_section.dart';

class HubRendererRegistry {
  const HubRendererRegistry._();

  static List<HubDynamicSection> normalizeSections(
    List<dynamic> rawSections,
  ) {
    final sections = <HubDynamicSection>[];

    for (final raw in rawSections) {
      if (raw is! Map) continue;

      try {
        final map = raw.map(
          (key, value) => MapEntry(
            key.toString(),
            value,
          ),
        );

        final section = HubDynamicSection.fromMap(map);

        if (!section.enabled) continue;

        sections.add(section);
      } catch (_) {}
    }

    sections.sort((a, b) => a.order.compareTo(b.order));

    return sections;
  }

  static List<HubDynamicSection> filterEnabled(
    List<HubDynamicSection> sections,
  ) {
    return sections.where((section) => section.enabled).toList(growable: false);
  }

  static List<HubDynamicSection> homeSections(
    List<HubDynamicSection> sections,
  ) {
    return sections.where((section) {
      final value = _searchText(section);

      return !value.contains('watch') &&
          !value.contains('explore') &&
          !value.contains('game');
    }).toList(growable: false);
  }

  static List<HubDynamicSection> exploreSections(
    List<HubDynamicSection> sections,
  ) {
    return sections.where((section) {
      final value = _searchText(section);

      return value.contains('tool') ||
          value.contains('explore') ||
          value.contains('game') ||
          value.contains('icon_grid');
    }).toList(growable: false);
  }

  static List<HubDynamicSection> watchSections(
    List<HubDynamicSection> sections,
  ) {
    return sections.where((section) {
      final value = _searchText(section);

      return value.contains('watch') ||
          value.contains('video') ||
          value.contains('live') ||
          value.contains('stream');
    }).toList(growable: false);
  }

  static List<HubDynamicSection> inspireSections(
    List<HubDynamicSection> sections,
  ) {
    return sections.where((section) {
      final value = _searchText(section);

      return value.contains('inspire') ||
          value.contains('article') ||
          value.contains('quote') ||
          value.contains('scripture') ||
          value.contains('devotional') ||
          value.contains('sod') ||
          value.contains('motivation') ||
          value.contains('wordification') ||
          value.contains('highlight');
    }).toList(growable: false);
  }

  static List<HubDynamicSection> shortFeedSections(
    List<HubDynamicSection> sections,
  ) {
    return sections.where((section) {
      final value = _searchText(section);

      return section.layout == HubDynamicSectionLayout.shortVideoFeed ||
          value.contains('short') ||
          value.contains('short_video');
    }).toList(growable: false);
  }

  static List<HubDynamicSection> adSections(
    List<HubDynamicSection> sections,
  ) {
    return sections.where((section) {
      return section.layout == HubDynamicSectionLayout.adBlock;
    }).toList(growable: false);
  }

  static HubDynamicSection? firstHeroSection(
    List<HubDynamicSection> sections,
  ) {
    for (final section in sections) {
      if (section.layout == HubDynamicSectionLayout.hero) {
        return section;
      }
    }

    return null;
  }

  static List<HubDynamicSection> removeEmpty(
    List<HubDynamicSection> sections,
  ) {
    return sections.where((section) {
      if (!section.enabled) return false;
      if (section.isAdSection) return true;
      return section.items.isNotEmpty;
    }).toList(growable: false);
  }

  static List<HubDynamicSection> injectAdBlocks({
    required List<HubDynamicSection> sections,
    int interval = 4,
  }) {
    return sections;
  }

  static List<HubDynamicSection> normalizeForHomeFeed(
    List<dynamic> rawSections,
  ) {
    final normalized = normalizeSections(rawSections);
    final filtered = homeSections(normalized);
    final cleaned = removeEmpty(filtered);

    return cleaned;
  }

  static List<HubDynamicSection> normalizeForExploreFeed(
    List<dynamic> rawSections,
  ) {
    final normalized = normalizeSections(rawSections);
    final filtered = exploreSections(normalized);

    return removeEmpty(filtered);
  }

  static List<HubDynamicSection> normalizeForWatchFeed(
    List<dynamic> rawSections,
  ) {
    final normalized = normalizeSections(rawSections);
    final filtered = watchSections(normalized);

    return removeEmpty(filtered);
  }

  static List<HubDynamicSection> normalizeForInspireFeed(
    List<dynamic> rawSections,
  ) {
    final normalized = normalizeSections(rawSections);
    final filtered = inspireSections(normalized);

    return removeEmpty(filtered);
  }

  static String _searchText(HubDynamicSection section) {
    return '''
${section.key}
${section.title}
${section.subtitle}
${section.type}
${section.layout.name}
'''
        .toLowerCase();
  }
}
