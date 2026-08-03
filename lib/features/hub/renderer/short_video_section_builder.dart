import '../models/dynamic_section.dart';

class ShortVideoSectionBuilder {
  const ShortVideoSectionBuilder._();

  static List<HubDynamicSection> buildShortVideoSections({
    required List<HubDynamicSection> backendSections,
  }) {
    final sections = <HubDynamicSection>[];

    for (final section in backendSections) {
      if (!section.enabled) continue;

      final lower = '''
${section.key}
${section.title}
${section.subtitle}
${section.type}
${section.layout.name}
'''
          .toLowerCase();

      final isShortSection =
          section.layout == HubDynamicSectionLayout.shortVideoFeed ||
          lower.contains('short') ||
          lower.contains('shorts') ||
          lower.contains('reel') ||
          lower.contains('vertical_video');

      if (!isShortSection) continue;

      if (!section.isAdSection && section.items.isEmpty) continue;

      sections.add(section);
    }

    return sections;
  }

  static HubDynamicSection buildShortVideoSection({
    required String key,
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> items,
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
      items: items,
      settings: {
        'source': 'short_video_section_builder',
        'type': 'short_video_feed',
        'order': order,
      },
    );
  }

  static List<HubDynamicSection> injectAdBlocks({
    required List<HubDynamicSection> sections,
    int interval = 5,
  }) {
    if (sections.isEmpty) return [];

    final output = <HubDynamicSection>[];

    for (var i = 0; i < sections.length; i++) {
      output.add(sections[i]);

      final shouldInsert = i != 0 && (i + 1) % interval == 0;

      if (shouldInsert) {
        output.add(
          HubDynamicSection(
            key: 'short_video_dynamic_ad_$i',
            title: '',
            subtitle: '',
            layout: HubDynamicSectionLayout.adBlock,
            columns: 1,
            rows: 1,
            enabled: true,
            items: const [],
            settings: const {
              'placement': 'short_video_feed',
              'source': 'short_video_section_builder',
            },
          ),
        );
      }
    }

    return output;
  }

  static List<HubDynamicSection> normalizeShortVideoFeed({
    required List<HubDynamicSection> backendSections,
  }) {
    final sections = buildShortVideoSections(
      backendSections: backendSections,
    );

    return injectAdBlocks(
      sections: sections,
      interval: 5,
    );
  }
}
