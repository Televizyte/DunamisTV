import '../models/dynamic_section.dart';

class WatchDynamicSectionBuilder {
  const WatchDynamicSectionBuilder._();

  static List<HubDynamicSection> buildWatchSections({
    required List<HubDynamicSection> backendSections,
  }) {
    final sections = <HubDynamicSection>[];

    for (final section in backendSections) {
      if (!section.enabled) continue;

      final lower = '''
${section.title}
${section.subtitle}
${section.key}
'''
          .toLowerCase();

      final isWatchSection =
          lower.contains('watch') ||
          lower.contains('live') ||
          lower.contains('stream') ||
          lower.contains('video') ||
          section.layout == HubDynamicSectionLayout.videoFeed ||
          section.layout == HubDynamicSectionLayout.shortVideoFeed;

      if (!isWatchSection) continue;

      if (!section.isAdSection && section.items.isEmpty) continue;

      sections.add(section);
    }

    return sections;
  }

  static List<HubDynamicSection> injectDynamicAds({
    required List<HubDynamicSection> sections,
    int interval = 3,
  }) {
    if (sections.isEmpty) {
      return [];
    }

    final output = <HubDynamicSection>[];

    for (var i = 0; i < sections.length; i++) {
      output.add(sections[i]);

      final shouldInsert =
          i != 0 &&
          (i + 1) % interval == 0;

      if (shouldInsert) {
        output.add(
          HubDynamicSection(
            key: 'watch_dynamic_ad_$i',
            title: '',
            subtitle: '',
            layout: HubDynamicSectionLayout.adBlock,
            columns: 1,
            rows: 1,
            enabled: true,
            items: const [],
            settings: const {
              'placement': 'watch_feed',
            },
          ),
        );
      }
    }

    return output;
  }

  static List<HubDynamicSection> normalizeWatchFeed({
    required List<HubDynamicSection> backendSections,
  }) {
    final sections = buildWatchSections(
      backendSections: backendSections,
    );

    return injectDynamicAds(
      sections: sections,
    );
  }
}
