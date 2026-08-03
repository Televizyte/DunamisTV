import 'package:flutter/material.dart';

import 'dynamic_section.dart';

class HubDynamicTab {
  final String key;
  final String label;
  final String title;
  final String subtitle;
  final String icon;
  final String route;
  final String type;
  final bool enabled;
  final bool visible;
  final bool showInBottomNav;
  final bool startup;
  final int order;
  final List<HubDynamicSection> sections;
  final Map<String, dynamic> settings;

  const HubDynamicTab({
    required this.key,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.type,
    required this.enabled,
    required this.visible,
    required this.showInBottomNav,
    required this.startup,
    required this.order,
    required this.sections,
    required this.settings,
  });

  factory HubDynamicTab.fromMap(Map<String, dynamic> map) {
    final settings = _asMap(map['settings']) ??
        _asMap(map['settings_json']) ??
        _asMap(map['meta']) ??
        const <String, dynamic>{};

    final key = _firstNonEmpty([
      map['key'],
      map['slug'],
      map['tab_key'],
      map['id'],
      map['label'],
      map['title'],
    ]);

    final label = _firstNonEmpty([
      map['label'],
      map['title'],
      map['name'],
      settings['label'],
      settings['title'],
      key,
    ]);

    final type = _firstNonEmpty([
      map['type'],
      map['tab_type'],
      settings['type'],
      settings['tab_type'],
      'dynamic',
    ]);

    final route = _firstNonEmpty([
      map['route'],
      map['path'],
      settings['route'],
      settings['path'],
      _defaultRouteForKey(key),
    ]);

    return HubDynamicTab(
      key: key.isNotEmpty ? key : 'tab',
      label: label.isNotEmpty ? label : 'Tab',
      title: _firstNonEmpty([
        map['title'],
        map['name'],
        settings['title'],
        label,
      ]),
      subtitle: _firstNonEmpty([
        map['subtitle'],
        map['description'],
        settings['subtitle'],
        settings['description'],
      ]),
      icon: _firstNonEmpty([
        map['icon'],
        map['icon_key'],
        settings['icon'],
        settings['icon_key'],
        key,
      ]),
      route: route.isNotEmpty ? route : _defaultRouteForKey(key),
      type: type,
      enabled: _boolValue(
        map['enabled'] ??
            map['is_enabled'] ??
            map['active'] ??
            map['is_active'] ??
            settings['enabled'] ??
            settings['is_enabled'],
        fallback: true,
      ),
      visible: _boolValue(
        map['visible'] ??
            map['is_visible'] ??
            settings['visible'] ??
            settings['is_visible'],
        fallback: true,
      ),
      showInBottomNav: _boolValue(
        map['show_in_bottom_nav'] ??
            map['bottom_nav'] ??
            settings['show_in_bottom_nav'] ??
            settings['bottom_nav'],
        fallback: true,
      ),
      startup: _boolValue(
        map['startup'] ??
            map['default'] ??
            map['is_default'] ??
            settings['startup'] ??
            settings['default'],
        fallback: false,
      ),
      order: _intValue(
        map['order'] ??
            map['position'] ??
            map['sort_order'] ??
            map['display_order'] ??
            settings['order'] ??
            settings['position'],
        fallback: 0,
        min: -9999,
        max: 9999,
      ),
      sections: _sectionsFromDynamic(
        map['sections'] ??
            map['dynamic_sections'] ??
            map['builder_sections'] ??
            map['items'] ??
            map['children'],
      ),
      settings: settings,
    );
  }

  IconData get iconData => iconDataFor(icon);

  bool get hasSections => sections.isNotEmpty;

  bool get isDynamic => type.trim().toLowerCase() == 'dynamic';

  bool get isNative => type.trim().toLowerCase() == 'native';

  HubDynamicTab copyWith({
    String? key,
    String? label,
    String? title,
    String? subtitle,
    String? icon,
    String? route,
    String? type,
    bool? enabled,
    bool? visible,
    bool? showInBottomNav,
    bool? startup,
    int? order,
    List<HubDynamicSection>? sections,
    Map<String, dynamic>? settings,
  }) {
    return HubDynamicTab(
      key: key ?? this.key,
      label: label ?? this.label,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      route: route ?? this.route,
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      visible: visible ?? this.visible,
      showInBottomNav: showInBottomNav ?? this.showInBottomNav,
      startup: startup ?? this.startup,
      order: order ?? this.order,
      sections: sections ?? this.sections,
      settings: settings ?? this.settings,
    );
  }

  static IconData iconDataFor(String value) {
    final raw = value.trim().toLowerCase();

    if (raw.contains('home')) {
      return Icons.home_rounded;
    }

    if (raw.contains('watch') || raw.contains('play')) {
      return Icons.play_circle_fill_rounded;
    }

    if (raw.contains('video')) {
      return Icons.play_circle_fill_rounded;
    }

    if (raw.contains('live')) {
      return Icons.live_tv_rounded;
    }

    if (raw.contains('inspire') || raw.contains('book')) {
      return Icons.menu_book_rounded;
    }

    if (raw.contains('explore') || raw.contains('grid')) {
      return Icons.grid_view_rounded;
    }

    if (raw.contains('more') || raw.contains('menu')) {
      return Icons.menu_rounded;
    }

    if (raw.contains('setting')) {
      return Icons.settings_rounded;
    }

    if (raw.contains('account')) {
      return Icons.person_rounded;
    }

    if (raw.contains('article')) {
      return Icons.article_rounded;
    }

    if (raw.contains('news')) {
      return Icons.newspaper_rounded;
    }

    if (raw.contains('music')) {
      return Icons.music_note_rounded;
    }

    if (raw.contains('radio')) {
      return Icons.radio_rounded;
    }

    if (raw.contains('bible') || raw.contains('scripture')) {
      return Icons.menu_book_rounded;
    }

    if (raw.contains('note')) {
      return Icons.sticky_note_2_rounded;
    }

    if (raw.contains('quote')) {
      return Icons.format_quote_rounded;
    }

    if (raw.contains('game')) {
      return Icons.sports_esports_rounded;
    }

    if (raw.contains('tv')) {
      return Icons.live_tv_rounded;
    }

    if (raw.contains('movie')) {
      return Icons.movie_rounded;
    }

    if (raw.contains('short')) {
      return Icons.video_collection_rounded;
    }

    if (raw.contains('tool')) {
      return Icons.apps_rounded;
    }

    return Icons.apps_rounded;
  }
}

List<HubDynamicTab> hubDynamicTabsFromRaw(dynamic raw) {
  if (raw is! List) {
    return const [];
  }

  final tabs = raw
      .whereType<Map>()
      .map(
        (item) => HubDynamicTab.fromMap(
          Map<String, dynamic>.from(item),
        ),
      )
      .where((tab) => tab.enabled && tab.visible)
      .toList(growable: false);

  final sorted = [...tabs]..sort((a, b) => a.order.compareTo(b.order));

  return sorted;
}

List<HubDynamicSection> _sectionsFromDynamic(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map(
        (item) => HubDynamicSection.fromMap(
          Map<String, dynamic>.from(item),
        ),
      )
      .where((section) => section.enabled)
      .toList(growable: false);
}

String _defaultRouteForKey(String key) {
  final clean = key.trim().toLowerCase().replaceAll('_', '-');

  switch (clean) {
    case '':
    case 'home':
      return '/';

    case 'watch':
      return '/watch';

    case 'inspire':
      return '/inspire';

    case 'explore':
      return '/explore';

    case 'more':
      return '/more';

    default:
      return '/tab/$clean';
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return null;
}

String _firstNonEmpty(List<dynamic> values) {
  for (final value in values) {
    final text = (value ?? '').toString().trim();

    if (text.isNotEmpty) {
      return text;
    }
  }

  return '';
}

int _intValue(
  dynamic value, {
  required int fallback,
  required int min,
  required int max,
}) {
  final parsed = int.tryParse((value ?? '').toString().trim());

  if (parsed == null) {
    return fallback;
  }

  if (parsed < min) {
    return min;
  }

  if (parsed > max) {
    return max;
  }

  return parsed;
}

bool _boolValue(
  dynamic value, {
  required bool fallback,
}) {
  if (value == null) {
    return fallback;
  }

  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final raw = value.toString().trim().toLowerCase();

  if (raw == '1' || raw == 'true' || raw == 'yes' || raw == 'on') {
    return true;
  }

  if (raw == '0' || raw == 'false' || raw == 'no' || raw == 'off') {
    return false;
  }

  return fallback;
}
