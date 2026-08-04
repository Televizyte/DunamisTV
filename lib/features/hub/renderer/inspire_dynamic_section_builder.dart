import '../models/dynamic_section.dart';

class InspireDynamicSectionBuilder {
  const InspireDynamicSectionBuilder._();

  static List<HubDynamicSection> buildInspireSections({
    required List<HubDynamicSection> backendSections,
  }) {
    final sections = <HubDynamicSection>[];

    for (final section in backendSections) {
      if (!section.enabled) continue;

      final lower = '''
${section.title}
${section.subtitle}
${section.key}
${section.type}
'''
          .toLowerCase();

      final isInspireSection = lower.contains('inspire') ||
          lower.contains('article') ||
          lower.contains('blog') ||
          lower.contains('motivation') ||
          lower.contains('wordification') ||
          lower.contains('devotional') ||
          lower.contains('quote') ||
          lower.contains('scripture') ||
          lower.contains('sod') ||
          lower.contains('seed') ||
          lower.contains('study') ||
          lower.contains('quiz') ||
          lower.contains('highlight') ||
          lower.contains('short_video') ||
          lower.contains('short-videos') ||
          lower.contains('short videos');

      if (!isInspireSection) continue;

      if (!section.isAdSection && section.items.isEmpty) continue;

      sections.add(section);
    }

    return sections;
  }

  static List<HubDynamicSection> injectDynamicAds({
    required List<HubDynamicSection> sections,
    int interval = 4,
  }) {
    return sections;
  }

  static List<HubDynamicSection> normalizeInspireFeed({
    required List<HubDynamicSection> backendSections,
  }) {
    final sections = buildInspireSections(
      backendSections: backendSections,
    );

    return sections;
  }
}
