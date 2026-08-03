import 'package:flutter/material.dart';

class HubToolItem {
  final String key;
  final String title;
  final String subtitle;
  final String route;
  final String badge;
  final String imageUrl;
  final IconData icon;
  final bool enabled;

  const HubToolItem({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.badge,
    required this.imageUrl,
    required this.icon,
    this.enabled = true,
  });

  HubToolItem copyWith({
    String? key,
    String? title,
    String? subtitle,
    String? route,
    String? badge,
    String? imageUrl,
    IconData? icon,
    bool? enabled,
  }) {
    return HubToolItem(
      key: key ?? this.key,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      route: route ?? this.route,
      badge: badge ?? this.badge,
      imageUrl: imageUrl ?? this.imageUrl,
      icon: icon ?? this.icon,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, String> toStringMap() {
    return {
      'key': key,
      'title': title,
      'subtitle': subtitle,
      'route': route,
      'badge': badge,
      'image_url': imageUrl,
      'enabled': enabled ? '1' : '0',
    };
  }
}

class HubToolRegistry {
  const HubToolRegistry._();

  static const List<HubToolItem> defaultTools = [
    HubToolItem(
      key: 'quote_creator',
      title: 'Quote Creator',
      subtitle: 'Create shareable quote designs',
      route: '/tools/quote',
      badge: 'TOOL',
      imageUrl: '',
      icon: Icons.format_quote_rounded,
    ),
    HubToolItem(
      key: 'notes',
      title: 'Notes',
      subtitle: 'Write and save personal notes',
      route: '/tools/notes',
      badge: 'TOOL',
      imageUrl: '',
      icon: Icons.sticky_note_2_rounded,
    ),
    HubToolItem(
      key: 'bible',
      title: 'Bible',
      subtitle: 'Read and explore scripture',
      route: '/tools/bible',
      badge: 'TOOL',
      imageUrl: '',
      icon: Icons.menu_book_rounded,
    ),
    HubToolItem(
      key: 'games',
      title: 'Games',
      subtitle: 'Open the games hub and play available games',
      route: '/games',
      badge: 'HUB',
      imageUrl: '',
      icon: Icons.sports_esports_rounded,
    ),
  ];

  static List<HubToolItem> resolveTools({
    required List<Map<String, String>> backendTools,
    required String fallbackImageUrl,
    bool includeDefaults = true,
  }) {
    final byRoute = <String, HubToolItem>{};

    if (includeDefaults) {
      for (final tool in defaultTools) {
        byRoute[tool.route] = tool.copyWith(imageUrl: fallbackImageUrl);
      }
    }

    for (final raw in backendTools) {
      final normalizedRoute = normalizeRoute(raw['route']);
      if (normalizedRoute.isEmpty || normalizedRoute == '/tools') continue;

      final defaultTool = defaultTools.where((tool) {
        return tool.route == normalizedRoute;
      }).cast<HubToolItem?>().firstWhere(
            (tool) => tool != null,
            orElse: () => null,
          );

      final title = _firstNonEmpty([
        raw['title'],
        defaultTool?.title,
        titleFromRoute(normalizedRoute),
      ]);

      final subtitle = _firstNonEmpty([
        raw['subtitle'],
        defaultTool?.subtitle,
        subtitleForTitle(title),
      ]);

      final badge = _firstNonEmpty([
        raw['badge'],
        defaultTool?.badge,
        normalizedRoute == '/games' ? 'HUB' : 'TOOL',
      ]);

      final imageUrl = _firstNonEmpty([
        raw['image_url'],
        defaultTool?.imageUrl,
        fallbackImageUrl,
      ]);

      final key = _firstNonEmpty([
        raw['key'],
        raw['slug'],
        defaultTool?.key,
        keyFromRoute(normalizedRoute),
      ]);

      byRoute[normalizedRoute] = HubToolItem(
        key: key,
        title: title,
        subtitle: subtitle,
        route: normalizedRoute,
        badge: badge,
        imageUrl: imageUrl,
        icon: iconForTool(title: title, route: normalizedRoute, key: key),
        enabled: _boolFromDynamic(raw['enabled'], fallback: true) &&
            _boolFromDynamic(raw['is_enabled'], fallback: true),
      );
    }

    const preferredOrder = [
      '/tools/quote',
      '/tools/notes',
      '/tools/bible',
      '/games',
    ];

    final ordered = <HubToolItem>[];

    for (final route in preferredOrder) {
      final item = byRoute[route];
      if (item != null && item.enabled) {
        ordered.add(item);
      }
    }

    for (final item in byRoute.values) {
      if (!item.enabled) continue;
      if (preferredOrder.contains(item.route)) continue;
      ordered.add(item);
    }

    return ordered;
  }

  static String normalizeRoute(String? route) {
    final raw = (route ?? '').trim();
    switch (raw) {
      case '/explore/quotes':
      case '/explore/quote':
      case '/quote':
      case '/quotes':
      case '/tools/quote':
      case 'quote':
      case 'quotes':
      case 'quote_creator':
        return '/tools/quote';

      case '/explore/notes':
      case '/note':
      case '/notes':
      case '/tools/notes':
      case 'note':
      case 'notes':
        return '/tools/notes';

      case '/explore/bible':
      case '/bible':
      case '/tools/bible':
      case 'bible':
        return '/tools/bible';

      case '/explore/games':
      case '/game':
      case '/games':
      case 'game':
      case 'games':
        return '/games';

      default:
        if (raw.startsWith('/')) return raw;
        return '/tools';
    }
  }

  static String keyFromRoute(String route) {
    switch (route) {
      case '/tools/quote':
        return 'quote_creator';
      case '/tools/notes':
        return 'notes';
      case '/tools/bible':
        return 'bible';
      case '/games':
        return 'games';
      default:
        return route.replaceAll('/', '_').replaceAll(RegExp(r'_+'), '_');
    }
  }

  static String titleFromRoute(String route) {
    switch (route) {
      case '/tools/quote':
        return 'Quote Creator';
      case '/tools/notes':
        return 'Notes';
      case '/tools/bible':
        return 'Bible';
      case '/games':
        return 'Games';
      default:
        return 'Tool';
    }
  }

  static String subtitleForTitle(String title) {
    switch (title.trim().toLowerCase()) {
      case 'quote creator':
      case 'quotes':
      case 'quote':
        return 'Create shareable quote designs';
      case 'notes':
      case 'note':
        return 'Write and save personal notes';
      case 'bible':
        return 'Read and explore scripture';
      case 'games':
      case 'game':
      case 'game hub':
        return 'Open the games hub and play available games';
      default:
        return 'Open tool';
    }
  }

  static IconData iconForTool({
    required String title,
    required String route,
    required String key,
  }) {
    final value = '$title $route $key'.toLowerCase();

    if (value.contains('quote')) return Icons.format_quote_rounded;
    if (value.contains('note')) return Icons.sticky_note_2_rounded;
    if (value.contains('bible') || value.contains('scripture')) {
      return Icons.menu_book_rounded;
    }
    if (value.contains('game')) return Icons.sports_esports_rounded;
    if (value.contains('video')) return Icons.play_circle_fill_rounded;
    if (value.contains('watch')) return Icons.live_tv_rounded;
    if (value.contains('music')) return Icons.music_note_rounded;
    if (value.contains('article') || value.contains('read')) {
      return Icons.article_rounded;
    }

    return Icons.apps_rounded;
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static bool _boolFromDynamic(dynamic value, {required bool fallback}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final raw = value.toString().trim().toLowerCase();
    if (raw.isEmpty) return fallback;

    if (raw == '1' || raw == 'true' || raw == 'yes' || raw == 'on') {
      return true;
    }

    if (raw == '0' || raw == 'false' || raw == 'no' || raw == 'off') {
      return false;
    }

    return fallback;
  }
}
