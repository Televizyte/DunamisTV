class ShortVideoItem {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final String creatorName;
  final String source;
  final String category;
  final String categoryLabel;
  final List<String> tags;
  final int durationSeconds;
  final bool enabled;
  final Map<String, dynamic> raw;

  const ShortVideoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.creatorName,
    required this.source,
    required this.category,
    required this.categoryLabel,
    required this.tags,
    required this.durationSeconds,
    required this.enabled,
    required this.raw,
  });

  factory ShortVideoItem.fromMap(Map<String, dynamic> map) {
    final payload = _mapValue(map['payload']);
    final meta = _mapValue(map['meta']);
    final settings = _mapValue(map['settings']);
    final action = _mapValue(map['action']);
    final media = _mapValue(map['media']);
    final cover = _mapValue(payload?['cover']) ?? _mapValue(meta?['cover']);

    final categoryLabel = _firstDeep([
      map['category_label'],
      map['category_name'],
      map['category_title'],
      payload?['category_label'],
      payload?['category_name'],
      payload?['category_title'],
      meta?['category_label'],
      meta?['category_name'],
      meta?['category_title'],
      settings?['category_label'],
      settings?['category_name'],
      settings?['category_title'],
      map['category'],
      payload?['category'],
      meta?['category'],
      settings?['category'],
      map['group'],
      payload?['group'],
      meta?['group'],
      map['bucket'],
      payload?['bucket'],
      meta?['bucket'],
      payload?['feed_label'],
      meta?['feed_label'],
      map['badge'],
    ]);

    final videoUrl = _cleanUrl(_firstDeep([
      map['video_url'],
      payload?['video_url'],
      meta?['video_url'],
      settings?['video_url'],
      media?['video_url'],
      action?['video_url'],
      map['file_url'],
      payload?['file_url'],
      meta?['file_url'],
      map['media_url'],
      payload?['media_url'],
      meta?['media_url'],
      map['url'],
      payload?['url'],
      meta?['url'],
      settings?['url'],
      action?['url'],
      map['stream_url'],
      payload?['stream_url'],
      meta?['stream_url'],
    ]));

    final thumbnailUrl = _cleanUrl(_firstDeep([
      map['thumbnail_url'],
      payload?['thumbnail_url'],
      meta?['thumbnail_url'],
      settings?['thumbnail_url'],
      cover?['thumbnail_url'],
      media?['thumbnail_url'],
      map['thumbnail'],
      payload?['thumbnail'],
      meta?['thumbnail'],
      cover?['thumbnail'],
      media?['thumbnail'],
      map['poster'],
      payload?['poster'],
      meta?['poster'],
      cover?['poster'],
      map['image_url'],
      payload?['image_url'],
      meta?['image_url'],
      settings?['image_url'],
      cover?['image_url'],
      media?['image_url'],
      map['cover_image_url'],
      payload?['cover_image_url'],
      meta?['cover_image_url'],
      cover?['cover_image_url'],
      map['cover_image'],
      payload?['cover_image'],
      meta?['cover_image'],
      map['card_image_url'],
      map['background_image_url'],
    ]));

    final rawCategory = _firstDeep([
      map['category_key'],
      payload?['category_key'],
      meta?['category_key'],
      settings?['category_key'],
      map['category_slug'],
      payload?['category_slug'],
      meta?['category_slug'],
      settings?['category_slug'],
      map['category'],
      payload?['category'],
      meta?['category'],
      settings?['category'],
      map['group'],
      payload?['group'],
      meta?['group'],
      map['bucket'],
      payload?['bucket'],
      meta?['bucket'],
      payload?['beginner_bucket'],
      meta?['beginner_bucket'],
      categoryLabel,
    ]);

    return ShortVideoItem(
      id: _firstDeep([
        map['id'],
        map['uuid'],
        payload?['id'],
        payload?['content_id'],
        payload?['post_id'],
        meta?['content_id'],
        meta?['post_id'],
        map['content_id'],
        map['post_id'],
        map['slug'],
        payload?['slug'],
        map['key'],
        map['title'],
      ]),
      title: _htmlClean(_firstDeep([
        map['title'],
        payload?['title'],
        meta?['title'],
        map['name'],
        payload?['name'],
        map['caption'],
        payload?['caption'],
      ])),
      description: _htmlClean(_firstDeep([
        map['description'],
        payload?['description'],
        meta?['description'],
        map['summary'],
        payload?['summary'],
        map['body'],
        payload?['body'],
        map['subtitle'],
        payload?['subtitle'],
      ])),
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      creatorName: _firstDeep([
        map['creator_name'],
        payload?['creator_name'],
        meta?['creator_name'],
        map['author'],
        payload?['author'],
        map['publisher'],
        payload?['publisher'],
        map['source_name'],
        payload?['source_name'],
      ]),
      source: _firstDeep([
        map['source'],
        payload?['source'],
        meta?['source'],
        map['platform'],
        payload?['platform'],
        map['provider'],
        payload?['provider'],
        payload?['video_source'],
        meta?['video_source'],
      ]),
      category: _slugify(rawCategory),
      categoryLabel:
          categoryLabel.isEmpty ? 'General' : _titleCase(categoryLabel),
      tags: _tags([
        map['tags'],
        payload?['tags'],
        meta?['tags'],
        settings?['tags'],
        map['keywords'],
        payload?['keywords'],
        meta?['keywords'],
        map['topics'],
        payload?['topics'],
        meta?['topics'],
      ]),
      durationSeconds: _int([
        map['duration_seconds'],
        payload?['duration_seconds'],
        meta?['duration_seconds'],
        map['duration'],
        payload?['duration'],
        meta?['duration'],
        payload?['video_duration'],
        meta?['video_duration'],
        map['badge'],
        map['length'],
      ]),
      enabled: _bool(
        map['enabled'] ??
            map['is_enabled'] ??
            payload?['enabled'] ??
            payload?['is_enabled'] ??
            meta?['enabled'] ??
            meta?['is_enabled'] ??
            map['active'] ??
            map['is_active'],
        fallback: true,
      ),
      raw: map,
    );
  }

  bool get hasVideo => videoUrl.trim().isNotEmpty;
  bool get hasThumbnail => thumbnailUrl.trim().isNotEmpty;
  String get categoryKey => category.trim().isEmpty ? 'general' : category;

  String get safeId {
    final direct = id.trim();
    if (direct.isNotEmpty) return direct;
    return '${title.trim()}|${videoUrl.trim()}'.hashCode.toString();
  }

  ShortVideoItem copyWith({
    String? id,
    String? title,
    String? description,
    String? videoUrl,
    String? thumbnailUrl,
    String? creatorName,
    String? source,
    String? category,
    String? categoryLabel,
    List<String>? tags,
    int? durationSeconds,
    bool? enabled,
    Map<String, dynamic>? raw,
  }) {
    return ShortVideoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      creatorName: creatorName ?? this.creatorName,
      source: source ?? this.source,
      category: category ?? this.category,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      tags: tags ?? this.tags,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      enabled: enabled ?? this.enabled,
      raw: raw ?? this.raw,
    );
  }
}

Map<String, dynamic>? _mapValue(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map)
    return value.map((key, value) => MapEntry(key.toString(), value));
  return null;
}

String _firstDeep(List<dynamic> values) {
  for (final value in values) {
    if (value == null) continue;
    if (value is String) {
      final text = value.trim();
      if (text.isNotEmpty && text != 'null') return text;
      continue;
    }
    if (value is num || value is bool) {
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty && text != 'null') return text;
  }
  return '';
}

int _int(List<dynamic> values) {
  for (final value in values) {
    if (value == null) continue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    final text = value.toString().trim();
    if (text.isEmpty) continue;
    final direct = int.tryParse(text);
    if (direct != null) return direct;
    final parts = text.split(':');
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0].trim()) ?? 0;
      final seconds = int.tryParse(parts[1].trim()) ?? 0;
      return (minutes * 60) + seconds;
    }
    if (parts.length == 3) {
      final hours = int.tryParse(parts[0].trim()) ?? 0;
      final minutes = int.tryParse(parts[1].trim()) ?? 0;
      final seconds = int.tryParse(parts[2].trim()) ?? 0;
      return (hours * 3600) + (minutes * 60) + seconds;
    }
  }
  return 0;
}

bool _bool(dynamic value, {required bool fallback}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final raw = value.toString().trim().toLowerCase();
  if (raw == '1' || raw == 'true' || raw == 'yes' || raw == 'on') return true;
  if (raw == '0' || raw == 'false' || raw == 'no' || raw == 'off') return false;
  return fallback;
}

List<String> _tags(List<dynamic> values) {
  final output = <String>[];
  void add(String value) {
    final clean = value.trim();
    if (clean.isNotEmpty && !output.contains(clean)) output.add(clean);
  }

  for (final value in values) {
    if (value == null) continue;
    if (value is List) {
      for (final item in value) add(item.toString());
      continue;
    }
    for (final part in value.toString().split(',')) add(part);
  }
  return output;
}

String _slugify(String value) {
  final clean = value.trim().toLowerCase();
  if (clean.isEmpty) return '';
  return clean
      .replaceAll(RegExp(r'&[a-z0-9#]+;'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

String _titleCase(String value) {
  final clean = _htmlClean(value).trim();
  if (clean.isEmpty) return '';
  return clean
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .map((part) {
    final lower = part.toLowerCase();
    return lower.substring(0, 1).toUpperCase() + lower.substring(1);
  }).join(' ');
}

String _htmlClean(String value) {
  return value
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _cleanUrl(String value) {
  final raw = value.trim();
  if (raw.isEmpty) return '';
  final match = RegExp(r'https?://[^\s]+').firstMatch(raw);
  if (match != null) return match.group(0)!;
  return raw;
}
