import 'dart:convert';

class WatchPayloadResolver {
  const WatchPayloadResolver._();

  static String resolveUrl(Map<dynamic, dynamic> item) {
    final payload = _map(item['payload']);
    final meta = _map(item['meta']);
    final action = _map(item['action'] ?? payload['action'] ?? meta['action']);
    final watchSource = _map(
      item['watch_source'] ??
          item['watch_link'] ??
          action['watch_source'] ??
          payload['watch_source'] ??
          payload['watch_link'] ??
          meta['watch_source'] ??
          meta['watch_link'],
    );

    return _firstHttpOrRaw([
      action['resolved_url'],
      action['url'],
      action['youtube'],
      action['youtube_url'],
      watchSource['url'],
      payload['resolved_url'],
      payload['url'],
      payload['youtube'],
      payload['youtube_url'],
      meta['resolved_url'],
      meta['url'],
      meta['youtube'],
      meta['youtube_url'],
      item['resolved_url'],
      item['url'],
      item['video_url'],
      item['stream_url'],
      item['youtube'],
      item['youtube_url'],
      item['link'],
    ]);
  }

  static String resolveType(
    Map<dynamic, dynamic> item, {
    String fallback = '',
  }) {
    final payload = _map(item['payload']);
    final meta = _map(item['meta']);
    final action = _map(item['action'] ?? payload['action'] ?? meta['action']);
    final watchSource = _map(
      item['watch_source'] ??
          item['watch_link'] ??
          action['watch_source'] ??
          payload['watch_source'] ??
          payload['watch_link'] ??
          meta['watch_source'] ??
          meta['watch_link'],
    );

    final url = resolveUrl(item).toLowerCase();

    final type = _firstText([
      action['player'],
      action['watch_type'],
      action['type'],
      watchSource['player'],
      watchSource['type'],
      payload['player'],
      payload['watch_type'],
      payload['type'],
      meta['player'],
      meta['watch_type'],
      meta['type'],
      item['player'],
      item['type'],
      item['engine'],
      fallback,
    ]).toLowerCase();

    if (type == 'hls' || type == 'live_hls' || type == 'stream_hls') {
      return 'hls';
    }

    if (type == 'youtube_playlist' ||
        type == 'playlist' ||
        type == 'yt_playlist') {
      return 'youtube_playlist';
    }

    if (type == 'youtube' ||
        type == 'youtube_video' ||
        type == 'live_youtube' ||
        type == 'commanding_day' ||
        type == 'video' ||
        type == 'vod') {
      return url.contains('list=') ? 'youtube_playlist' : 'youtube';
    }

    if (type == 'web' ||
        type == 'channel' ||
        type == 'embed' ||
        type == 'iframe' ||
        type == 'html' ||
        type == 'page' ||
        type == 'external' ||
        type == 'browser') {
      return 'web';
    }

    if (url.contains('.m3u8')) return 'hls';
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return url.contains('list=') ? 'youtube_playlist' : 'youtube';
    }

    return type.isNotEmpty ? type : 'web';
  }

  static String resolveSubtitle(
    Map<dynamic, dynamic> item, {
    String fallback = '',
  }) {
    final payload = _map(item['payload']);
    final meta = _map(item['meta']);
    final action = _map(item['action'] ?? payload['action'] ?? meta['action']);
    final watchSource = _map(
      item['watch_source'] ??
          item['watch_link'] ??
          action['watch_source'] ??
          payload['watch_source'] ??
          payload['watch_link'] ??
          meta['watch_source'] ??
          meta['watch_link'],
    );

    return _firstText([
      item['subtitle'],
      item['description'],
      payload['subtitle'],
      payload['description'],
      meta['subtitle'],
      meta['description'],
      watchSource['subtitle'],
      fallback,
    ]);
  }

  static String resolveImageUrl(
    Map<dynamic, dynamic> item, {
    String fallback = '',
  }) {
    final payload = _map(item['payload']);
    final meta = _map(item['meta']);
    final action = _map(item['action'] ?? payload['action'] ?? meta['action']);
    final watchSource = _map(
      item['watch_source'] ??
          item['watch_link'] ??
          action['watch_source'] ??
          payload['watch_source'] ??
          payload['watch_link'] ??
          meta['watch_source'] ??
          meta['watch_link'],
    );

    return _firstHttpOrRaw([
      item['image_url'],
      item['thumbnail_url'],
      item['cover_image_url'],
      item['card_image_url'],
      item['background_image_url'],
      item['poster'],
      item['cover_url'],
      item['banner_url'],
      item['image'],
      payload['image_url'],
      payload['thumbnail_url'],
      payload['cover_image_url'],
      payload['card_image_url'],
      payload['background_image_url'],
      payload['poster'],
      payload['cover_url'],
      payload['banner_url'],
      payload['image'],
      meta['image_url'],
      meta['thumbnail_url'],
      meta['cover_image_url'],
      meta['card_image_url'],
      meta['background_image_url'],
      meta['poster'],
      meta['cover_url'],
      meta['banner_url'],
      meta['image'],
      watchSource['image_url'],
      watchSource['thumbnail_url'],
      fallback,
    ]);
  }

  static String resolveBadge(
    Map<dynamic, dynamic> item, {
    String fallback = '',
  }) {
    final payload = _map(item['payload']);
    final meta = _map(item['meta']);
    final action = _map(item['action'] ?? payload['action'] ?? meta['action']);
    final watchSource = _map(
      item['watch_source'] ??
          item['watch_link'] ??
          action['watch_source'] ??
          payload['watch_source'] ??
          payload['watch_link'] ??
          meta['watch_source'] ??
          meta['watch_link'],
    );

    return _firstText([
      item['badge'],
      item['label'],
      item['category_label'],
      item['category_name'],
      payload['badge'],
      payload['label'],
      meta['badge'],
      meta['label'],
      watchSource['label'],
      fallback,
    ]);
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    return <String, dynamic>{};
  }

  static String _firstText(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }

    return '';
  }

  static String _firstHttpOrRaw(List<dynamic> values) {
    for (final value in values) {
      final raw = (value ?? '').toString().trim();
      if (raw.isEmpty || raw == 'null') continue;

      final match = RegExp(r'https?://[^\s]+').firstMatch(raw);
      if (match != null) return match.group(0)!;

      if (raw.startsWith('//')) return 'https:$raw';
      if (raw.startsWith('www.')) return 'https://$raw';

      return raw;
    }

    return '';
  }
}
