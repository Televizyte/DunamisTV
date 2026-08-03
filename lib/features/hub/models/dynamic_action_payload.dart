class DynamicActionPayload {
  final String type;
  final String route;
  final String engine;
  final String url;
  final String title;
  final String contentId;
  final String bucket;
  final bool external;
  final Map<String, dynamic> extra;

  const DynamicActionPayload({
    required this.type,
    required this.route,
    required this.engine,
    required this.url,
    required this.title,
    required this.contentId,
    required this.bucket,
    required this.external,
    required this.extra,
  });

  factory DynamicActionPayload.fromMap(
    Map<String, dynamic> map,
  ) {
    return DynamicActionPayload(
      type: _first([
        map['type'],
        map['action_type'],
        map['content_type'],
      ]),
      route: _first([
        map['route'],
        map['path'],
        map['screen_route'],
        map['target_route'],
      ]),
      engine: _first([
        map['engine'],
        map['native_engine'],
        map['tool'],
        map['tool_key'],
      ]),
      url: _first([
        map['url'],
        map['external_url'],
        map['video_url'],
        map['stream_url'],
        map['web_url'],
      ]),
      title: _first([
        map['title'],
        map['label'],
        map['name'],
      ]),
      contentId: _first([
        map['content_id'],
        map['article_id'],
        map['id'],
      ]),
      bucket: _first([
        map['bucket'],
        map['category'],
      ]),
      external: _bool(
        map['external'] ??
            map['is_external'],
      ),
      extra: {...map},
    );
  }

  bool get hasRoute =>
      route.trim().isNotEmpty;

  bool get hasEngine =>
      engine.trim().isNotEmpty;

  bool get hasUrl =>
      url.trim().isNotEmpty;
}

String _first(List<dynamic> values) {
  for (final value in values) {
    final text = (value ?? '')
        .toString()
        .trim();

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

  final raw = value
      .toString()
      .trim()
      .toLowerCase();

  return raw == '1' ||
      raw == 'true' ||
      raw == 'yes' ||
      raw == 'on';
}
