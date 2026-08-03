import '../models/dynamic_section.dart';
import 'dynamic_tool_section_builder.dart';

class HomeDynamicSectionBuilder {
  const HomeDynamicSectionBuilder._();

  static List<HubDynamicSection> buildHomeSections({
    required List<HubDynamicSection> backendSections,
    required List<Map<String, String>> backendTools,
    required String fallbackImageUrl,
  }) {
    final sections = <HubDynamicSection>[];

    sections.addAll(backendSections.where((section) {
      if (!section.enabled) return false;
      if (section.isAdSection) return true;
      return section.items.isNotEmpty;
    }));

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

  static List<HubDynamicSection> buildFallbackHomeSections({
    required List<Map<String, String>> backendTools,
    required String fallbackImageUrl,
  }) {
    return [
      DynamicToolSectionBuilder.buildToolSection(
        backendTools: backendTools,
        fallbackImageUrl: fallbackImageUrl,
        title: 'Quick Tools',
        subtitle: 'Quote Creator, Notes, Bible and Books Reader/Library.',
        columns: 2,
      ),
    ];
  }
}
