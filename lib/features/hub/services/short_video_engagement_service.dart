import '../models/short_video_item.dart';

typedef ShortVideoEngagementCallback = Future<void> Function(
  ShortVideoItem item,
  Map<String, dynamic> payload,
);

class ShortVideoEngagementService {
  const ShortVideoEngagementService._();

  static ShortVideoEngagementCallback? _watchHandler;
  static ShortVideoEngagementCallback? _favoriteHandler;
  static ShortVideoEngagementCallback? _shareHandler;

  static const ShortVideoEngagementService instance =
      ShortVideoEngagementService._();

  static void configure({
    ShortVideoEngagementCallback? onWatch,
    ShortVideoEngagementCallback? onFavorite,
    ShortVideoEngagementCallback? onShare,
  }) {
    _watchHandler = onWatch;
    _favoriteHandler = onFavorite;
    _shareHandler = onShare;
  }

  Future<void> trackWatch(ShortVideoItem item) async {
    final handler = _watchHandler;
    if (handler == null) return;

    await _silently(
      () => handler(item, _basePayload(item)..['event'] = 'watch'),
    );
  }

  Future<void> toggleFavorite(
    ShortVideoItem item, {
    required bool isFavorite,
  }) async {
    final handler = _favoriteHandler;
    if (handler == null) return;

    await _silently(
      () => handler(
        item,
        _basePayload(item)
          ..['event'] = isFavorite ? 'favorite_on' : 'favorite_off'
          ..['is_favorite'] = isFavorite,
      ),
    );
  }

  Future<void> trackShare(ShortVideoItem item) async {
    final handler = _shareHandler;
    if (handler == null) return;

    await _silently(
      () => handler(item, _basePayload(item)..['event'] = 'share'),
    );
  }

  String shareTextFor(ShortVideoItem item) {
    final title =
        item.title.trim().isNotEmpty ? item.title.trim() : 'Short Video';
    final description = item.description.trim();
    final link = shareLinkFor(item);

    final parts = <String>[
      title,
      if (description.isNotEmpty) description,
      'Watch this short video in the app:',
      link,
    ];

    return parts.join('\n');
  }

  String shareLinkFor(ShortVideoItem item) {
    final explicitLink = _firstString([
      item.raw['share_url'],
      item.raw['share_link'],
      item.raw['app_link'],
      item.raw['deep_link'],
      item.raw['permalink'],
    ]);

    if (explicitLink.isNotEmpty) {
      return explicitLink;
    }

    final route = _firstString([
      item.raw['route'],
      item.raw['target_route'],
      item.raw['path'],
    ]);

    if (route.isNotEmpty) {
      return _routeWithId(route, item.safeId);
    }

    return _routeWithId('/short-videos', item.safeId);
  }

  Map<String, dynamic> _basePayload(ShortVideoItem item) {
    return <String, dynamic>{
      'id': item.safeId,
      'title': item.title,
      'category': item.category,
      'category_label': item.categoryLabel,
      'source': item.source,
    };
  }

  Future<void> _silently(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Engagement must never break video playback or the render engine UI.
    }
  }

  String _routeWithId(String route, String id) {
    final cleanRoute = route.trim().isEmpty ? '/short-videos' : route.trim();
    final separator = cleanRoute.contains('?') ? '&' : '?';
    return '$cleanRoute${separator}id=${Uri.encodeComponent(id)}';
  }

  String _firstString(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}
