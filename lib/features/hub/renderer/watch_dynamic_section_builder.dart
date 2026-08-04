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

      final isWatchSection = lower.contains('watch') ||
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
    return sections;
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
