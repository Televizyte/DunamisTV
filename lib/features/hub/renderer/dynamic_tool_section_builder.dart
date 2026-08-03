import '../models/dynamic_section.dart';
import '../registry/tool_registry.dart';

class DynamicToolSectionBuilder {
  const DynamicToolSectionBuilder._();

  static HubDynamicSection buildToolSection({
    required List<Map<String, String>> backendTools,
    required String fallbackImageUrl,
    String title = 'Quick Tools',
    String subtitle = 'Open available tools and useful features.',
    int columns = 2,
  }) {
    final tools = HubToolRegistry.resolveTools(
      backendTools: backendTools,
      fallbackImageUrl: fallbackImageUrl,
    );

    return HubDynamicSection(
      key: 'quick_tools',
      title: title,
      subtitle: subtitle,
      layout: HubDynamicSectionLayout.toolGrid,
      columns: columns,
      rows: 1,
      enabled: true,
      items: tools.map((tool) {
        final title = _canonicalTitle(tool.route, tool.title);
        return {
          'key': tool.key,
          'title': title,
          'subtitle': _canonicalSubtitle(title, tool.subtitle),
          'route': tool.route,
          'badge': _canonicalBadge(title, tool.badge),
          'image_url': tool.imageUrl,
          'type': 'tool',
          'enabled': tool.enabled,
        };
      }).toList(growable: false),
      settings: const {
        'source': 'frontend_tool_registry',
      },
    );
  }

  static HubDynamicSection buildEmptyToolSection({
    String title = 'Quick Tools',
    String subtitle = 'Tools will appear here when enabled.',
  }) {
    return HubDynamicSection(
      key: 'quick_tools_empty',
      title: title,
      subtitle: subtitle,
      layout: HubDynamicSectionLayout.toolGrid,
      columns: 2,
      rows: 1,
      enabled: true,
      items: const [],
      settings: const {
        'source': 'frontend_tool_registry',
        'empty': true,
      },
    );
  }

  static String _canonicalTitle(String route, String title) {
    final lowerRoute = route.trim().toLowerCase();
    final lowerTitle = title.trim().toLowerCase();

    if (lowerRoute == '/tools/quote' || lowerTitle.contains('quote')) {
      return 'Quote Creator';
    }

    if (lowerRoute == '/tools/notes' || lowerTitle.contains('note')) {
      return 'Notes';
    }

    if (lowerRoute == '/tools/bible' || lowerTitle.contains('bible')) {
      return 'Bible';
    }

    if (lowerRoute == '/tab/books_reader' ||
        lowerTitle.contains('book') ||
        lowerTitle.contains('library')) {
      return 'Books Reader/Library';
    }

    return title.trim().isNotEmpty ? title.trim() : 'Tool';
  }

  static String _canonicalSubtitle(String title, String subtitle) {
    if (subtitle.trim().isNotEmpty) return subtitle.trim();

    switch (title.trim().toLowerCase()) {
      case 'quote creator':
        return 'Create shareable quote designs';
      case 'notes':
        return 'Write and save personal notes';
      case 'bible':
        return 'Read and explore scripture';
      case 'books reader/library':
        return 'Read books and study materials';
      default:
        return 'Open available tools and useful features.';
    }
  }

  static String _canonicalBadge(String title, String badge) {
    final lowerTitle = title.trim().toLowerCase();

    if (lowerTitle.contains('quote')) return 'QUOTE';
    if (lowerTitle.contains('note')) return 'NOTE';
    if (lowerTitle.contains('bible')) return 'BIBLE';
    if (lowerTitle.contains('book') || lowerTitle.contains('library')) {
      return 'BOOK';
    }

    return badge.trim().isNotEmpty ? badge.trim() : 'TOOL';
  }
}
