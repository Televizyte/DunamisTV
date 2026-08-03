import '../models/dynamic_section.dart';
import 'dynamic_tool_section_builder.dart';

class ExploreDynamicSectionBuilder {
  const ExploreDynamicSectionBuilder._();

  static List<HubDynamicSection> buildExploreSections({
    required List<HubDynamicSection> backendSections,
    required List<Map<String, String>> backendTools,
    required String fallbackImageUrl,
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

      final isExploreSection = lower.contains('tool') ||
          lower.contains('explore') ||
          lower.contains('game') ||
          lower.contains('short_video') ||
          lower.contains('short videos') ||
          lower.contains('short-videos') ||
          lower.contains('shorts') ||
          lower.contains('reel') ||
          section.layout == HubDynamicSectionLayout.shortVideoFeed ||
          section.layout == HubDynamicSectionLayout.iconGrid ||
          section.layout == HubDynamicSectionLayout.toolGrid;

      if (!isExploreSection) continue;

      if (!section.isAdSection && section.items.isEmpty) continue;

      sections.add(section);
    }

    final hasBackendToolSection = sections.any((section) {
      final lower = '''
${section.key}
${section.title}
${section.type}
${section.layout.name}
${section.settings}
'''.toLowerCase();
      return lower.contains('tool') || lower.contains('quick_tools');
    });

    if (!hasBackendToolSection && backendTools.isNotEmpty) {
      sections.add(
        DynamicToolSectionBuilder.buildToolSection(
          backendTools: backendTools,
          fallbackImageUrl: fallbackImageUrl,
          title: 'Quick Tools',
          subtitle: 'Open available tools and useful features.',
          columns: 2,
        ),
      );
    }

    return sections;
  }

  static List<HubDynamicSection> injectDynamicAds({
    required List<HubDynamicSection> sections,
    int interval = 5,
  }) {
    // Real ad placement is controlled by AppsHub policy and the shared ad
    // widgets. Do not inject visible placeholder ad blocks from the renderer.
    return sections;
  }

  static List<HubDynamicSection> normalizeExploreFeed({
    required List<HubDynamicSection> backendSections,
    required List<Map<String, String>> backendTools,
    required String fallbackImageUrl,
  }) {
    final sections = buildExploreSections(
      backendSections: backendSections,
      backendTools: backendTools,
      fallbackImageUrl: fallbackImageUrl,
    );

    return injectDynamicAds(
      sections: sections,
    );
  }
}
