import 'package:flutter/material.dart';

import 'native_engine_action.dart';

class DynamicHubItem {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String imageUrl;
  final String thumbnailUrl;
  final String route;
  final String externalUrl;
  final String type;
  final String badge;
  final String engine;
  final bool premium;
  final bool enabled;
  final IconData icon;
  final Map<String, dynamic> raw;

  const DynamicHubItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.route,
    required this.externalUrl,
    required this.type,
    required this.badge,
    required this.engine,
    required this.premium,
    required this.enabled,
    required this.icon,
    required this.raw,
  });

  factory DynamicHubItem.fromMap(Map<String, dynamic> map) {
    final type = _first([
      map['type'],
      map['content_type'],
      map['item_type'],
    ]);

    final route = _first([
      map['route'],
      map['screen_route'],
      map['target_route'],
      map['path'],
    ]);

    final title = _first([
      map['title'],
      map['name'],
      map['label'],
    ]);

    final engine = _first([
      map['engine'],
      map['native_engine'],
      map['action_engine'],
      map['tool'],
      map['tool_key'],
      map['content_engine'],
      map['content_type'],
      type,
    ]);

    final actionMap = _asMap(map['action']);
    final payloadMap = _asMap(map['payload']);
    final styleMap = _asMap(map['style']);
    final settingsMap = _asMap(map['settings']);

    final explicitIcon = _first([
      map['icon'],
      map['icon_key'],
      map['icon_name'],
      actionMap?['icon'],
      payloadMap?['icon'],
      styleMap?['icon'],
      settingsMap?['icon'],
    ]);

    return DynamicHubItem(
      id: _first([
        map['id'],
        map['slug'],
        map['uuid'],
        title,
      ]),
      title: title,
      subtitle: _first([
        map['subtitle'],
        map['caption'],
      ]),
      description: _first([
        map['description'],
        map['summary'],
        map['body'],
      ]),
      imageUrl: _first([
        map['image_url'],
        map['cover_image_url'],
        map['image'],
      ]),
      thumbnailUrl: _first([
        map['thumbnail_url'],
        map['thumbnail'],
        map['poster'],
      ]),
      route: route,
      externalUrl: _first([
        map['url'],
        map['external_url'],
        map['link'],
      ]),
      type: type,
      badge: _first([
        map['badge'],
        map['tag'],
        map['pill'],
      ]),
      engine: engine,
      premium: _bool(
        map['premium'] ??
            map['is_premium'] ??
            map['requires_subscription'],
      ),
      enabled: !_bool(
        map['disabled'] ?? false,
      ),
      icon: _resolveIcon(
        explicitIcon.trim().isNotEmpty
            ? explicitIcon
            : '$title $type $route $engine',
      ),
      raw: map,
    );
  }

  bool get hasImage =>
      imageUrl.trim().isNotEmpty ||
      thumbnailUrl.trim().isNotEmpty;

  bool get isExternal =>
      externalUrl.trim().isNotEmpty;

  bool get isVideo =>
      type.toLowerCase().contains('video') ||
      type.toLowerCase().contains('live') ||
      engine.toLowerCase().contains('youtube') ||
      engine.toLowerCase().contains('video');

  bool get isArticle =>
      type.toLowerCase().contains('article') ||
      type.toLowerCase().contains('blog') ||
      engine.toLowerCase().contains('article');

  bool get isTool =>
      type.toLowerCase().contains('tool') ||
      engine.toLowerCase().contains('tool');

  bool get hasEngine =>
      engine.trim().isNotEmpty;

  NativeEngineAction get nativeAction {
    return NativeEngineAction.fromMap({
      ...raw,
      'engine': engine,
      'route': route,
      'title': title,
      'url': externalUrl,
      'content_id': id,
    });
  }

  DynamicHubItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    String? imageUrl,
    String? thumbnailUrl,
    String? route,
    String? externalUrl,
    String? type,
    String? badge,
    String? engine,
    bool? premium,
    bool? enabled,
    IconData? icon,
    Map<String, dynamic>? raw,
  }) {
    return DynamicHubItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      route: route ?? this.route,
      externalUrl: externalUrl ?? this.externalUrl,
      type: type ?? this.type,
      badge: badge ?? this.badge,
      engine: engine ?? this.engine,
      premium: premium ?? this.premium,
      enabled: enabled ?? this.enabled,
      icon: icon ?? this.icon,
      raw: raw ?? this.raw,
    );
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }

  return null;
}

String _first(List<dynamic> values) {
  for (final value in values) {
    final text = (value ?? '').toString().trim();

    if (text.isNotEmpty) {
      return text;
    }
  }

  return '';
}

bool _bool(dynamic value) {
  if (value == null) return false;

  if (value is bool) return value;

  if (value is num) return value != 0;

  final raw = value.toString().trim().toLowerCase();

  return raw == '1' ||
      raw == 'true' ||
      raw == 'yes' ||
      raw == 'on';
}

IconData _resolveIcon(String value) {
  final lower = value.toLowerCase().trim();

  if (lower.contains('home')) {
    return Icons.home_rounded;
  }

  if (lower.contains('play') ||
      lower.contains('youtube') ||
      lower.contains('video') ||
      lower.contains('movie') ||
      lower.contains('watch')) {
    return Icons.play_circle_fill_rounded;
  }

  if (lower.contains('live') ||
      lower.contains('stream') ||
      lower.contains('broadcast') ||
      lower.contains('tv')) {
    return Icons.live_tv_rounded;
  }

  if (lower.contains('bible') ||
      lower.contains('scripture') ||
      lower.contains('word')) {
    return Icons.menu_book_rounded;
  }

  if (lower.contains('quote')) {
    return Icons.format_quote_rounded;
  }

  if (lower.contains('note')) {
    return Icons.sticky_note_2_rounded;
  }

  if (lower.contains('article') ||
      lower.contains('blog') ||
      lower.contains('post') ||
      lower.contains('read')) {
    return Icons.article_rounded;
  }

  if (lower.contains('sod') ||
      lower.contains('seed') ||
      lower.contains('devotional')) {
    return Icons.auto_stories_rounded;
  }

  if (lower.contains('game')) {
    return Icons.sports_esports_rounded;
  }

  if (lower.contains('music') ||
      lower.contains('audio') ||
      lower.contains('song')) {
    return Icons.music_note_rounded;
  }

  if (lower.contains('podcast')) {
    return Icons.podcasts_rounded;
  }

  if (lower.contains('community') ||
      lower.contains('group') ||
      lower.contains('follow')) {
    return Icons.groups_rounded;
  }

  if (lower.contains('event') ||
      lower.contains('calendar')) {
    return Icons.event_rounded;
  }

  if (lower.contains('prayer') ||
      lower.contains('pray')) {
    return Icons.volunteer_activism_rounded;
  }

  if (lower.contains('web') ||
      lower.contains('browser') ||
      lower.contains('link') ||
      lower.contains('external')) {
    return Icons.public_rounded;
  }

  if (lower.contains('download')) {
    return Icons.download_rounded;
  }

  if (lower.contains('notification')) {
    return Icons.notifications_rounded;
  }

  if (lower.contains('support')) {
    return Icons.support_agent_rounded;
  }

  if (lower.contains('about') ||
      lower.contains('info')) {
    return Icons.info_rounded;
  }

  if (lower.contains('policy') ||
      lower.contains('privacy') ||
      lower.contains('terms')) {
    return Icons.privacy_tip_rounded;
  }

  if (lower.contains('setting')) {
    return Icons.settings_rounded;
  }

  if (lower.contains('account') ||
      lower.contains('profile') ||
      lower.contains('user')) {
    return Icons.person_rounded;
  }

  if (lower.contains('share') ||
      lower.contains('rate')) {
    return Icons.ios_share_rounded;
  }

  if (lower.contains('grid') ||
      lower.contains('tool') ||
      lower.contains('explore')) {
    return Icons.apps_rounded;
  }

  return Icons.apps_rounded;
}
