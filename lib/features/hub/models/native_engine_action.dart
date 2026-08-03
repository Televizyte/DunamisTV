class NativeEngineAction {
  final String engine;
  final String route;
  final String title;
  final String url;
  final String contentId;
  final String bucket;
  final Map<String, dynamic> extra;

  const NativeEngineAction({
    required this.engine,
    required this.route,
    required this.title,
    required this.url,
    required this.contentId,
    required this.bucket,
    required this.extra,
  });

  factory NativeEngineAction.fromMap(Map<String, dynamic> map) {
    final extra = <String, dynamic>{...map};

    return NativeEngineAction(
      engine: _firstNonEmpty([
        map['engine'],
        map['native_engine'],
        map['action_engine'],
        map['tool'],
        map['key'],
        map['type'],
      ]),
      route: _firstNonEmpty([
        map['route'],
        map['path'],
        map['url_route'],
      ]),
      title: _firstNonEmpty([
        map['title'],
        map['label'],
        map['name'],
      ]),
      url: _firstNonEmpty([
        map['url'],
        map['link'],
        map['video_url'],
        map['stream_url'],
        map['web_url'],
      ]),
      contentId: _firstNonEmpty([
        map['content_id'],
        map['article_id'],
        map['post_id'],
        map['id'],
      ]),
      bucket: _firstNonEmpty([
        map['bucket'],
        map['content_bucket'],
        map['category'],
      ]),
      extra: extra,
    );
  }

  NativeEngineAction copyWith({
    String? engine,
    String? route,
    String? title,
    String? url,
    String? contentId,
    String? bucket,
    Map<String, dynamic>? extra,
  }) {
    return NativeEngineAction(
      engine: engine ?? this.engine,
      route: route ?? this.route,
      title: title ?? this.title,
      url: url ?? this.url,
      contentId: contentId ?? this.contentId,
      bucket: bucket ?? this.bucket,
      extra: extra ?? this.extra,
    );
  }

  bool get hasEngine => engine.trim().isNotEmpty;

  bool get hasRoute => route.trim().isNotEmpty;

  bool get hasUrl => url.trim().isNotEmpty;

  bool get hasContentId => contentId.trim().isNotEmpty;
}

String _firstNonEmpty(List<dynamic> values) {
  for (final value in values) {
    final text = (value ?? '').toString().trim();
    if (text.isNotEmpty) return text;
  }

  return '';
}
