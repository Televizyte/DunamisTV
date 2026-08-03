import '../models/native_engine_action.dart';

class NativeEngineDefinition {
  final String key;
  final String title;
  final String route;
  final bool enabled;
  final bool reservedForFuture;

  const NativeEngineDefinition({
    required this.key,
    required this.title,
    required this.route,
    required this.enabled,
    required this.reservedForFuture,
  });
}

class NativeEngineRegistry {
  const NativeEngineRegistry._();

  static const Map<String, NativeEngineDefinition> engines = {
    'bible': NativeEngineDefinition(
      key: 'bible',
      title: 'Bible',
      route: '/tools/bible',
      enabled: true,
      reservedForFuture: false,
    ),
    'notes': NativeEngineDefinition(
      key: 'notes',
      title: 'Notes',
      route: '/tools/notes',
      enabled: true,
      reservedForFuture: false,
    ),
    'note': NativeEngineDefinition(
      key: 'note',
      title: 'Notes',
      route: '/tools/notes',
      enabled: true,
      reservedForFuture: false,
    ),
    'quote': NativeEngineDefinition(
      key: 'quote',
      title: 'Quote Creator',
      route: '/tools/quote',
      enabled: true,
      reservedForFuture: false,
    ),
    'quote_creator': NativeEngineDefinition(
      key: 'quote_creator',
      title: 'Quote Creator',
      route: '/tools/quote',
      enabled: true,
      reservedForFuture: false,
    ),
    'games': NativeEngineDefinition(
      key: 'games',
      title: 'Games',
      route: '/games',
      enabled: true,
      reservedForFuture: false,
    ),
    'game': NativeEngineDefinition(
      key: 'game',
      title: 'Games',
      route: '/games',
      enabled: true,
      reservedForFuture: false,
    ),
    'web': NativeEngineDefinition(
      key: 'web',
      title: 'Web',
      route: '/web',
      enabled: true,
      reservedForFuture: false,
    ),
    'webview': NativeEngineDefinition(
      key: 'webview',
      title: 'Web',
      route: '/web',
      enabled: true,
      reservedForFuture: false,
    ),
    'youtube': NativeEngineDefinition(
      key: 'youtube',
      title: 'YouTube',
      route: '/player/youtube',
      enabled: true,
      reservedForFuture: false,
    ),
    'hls': NativeEngineDefinition(
      key: 'hls',
      title: 'Live Stream',
      route: '/player/hls',
      enabled: true,
      reservedForFuture: false,
    ),
    'live': NativeEngineDefinition(
      key: 'live',
      title: 'Live',
      route: '/live',
      enabled: true,
      reservedForFuture: false,
    ),
    'article': NativeEngineDefinition(
      key: 'article',
      title: 'Article',
      route: '/articles/detail',
      enabled: true,
      reservedForFuture: false,
    ),
    'articles': NativeEngineDefinition(
      key: 'articles',
      title: 'Articles',
      route: '/articles',
      enabled: true,
      reservedForFuture: false,
    ),
    'shorts': NativeEngineDefinition(
      key: 'shorts',
      title: 'Short Videos',
      route: '/short-videos',
      enabled: true,
      reservedForFuture: false,
    ),
    'short_videos': NativeEngineDefinition(
      key: 'short_videos',
      title: 'Short Videos',
      route: '/short-videos',
      enabled: true,
      reservedForFuture: false,
    ),

    // Reserved future engines.
    'podcast': NativeEngineDefinition(
      key: 'podcast',
      title: 'Podcast',
      route: '/tab/podcast',
      enabled: false,
      reservedForFuture: true,
    ),
    'music': NativeEngineDefinition(
      key: 'music',
      title: 'Music',
      route: '/tab/music',
      enabled: false,
      reservedForFuture: true,
    ),
    'courses': NativeEngineDefinition(
      key: 'courses',
      title: 'Courses',
      route: '/tab/courses',
      enabled: false,
      reservedForFuture: true,
    ),
    'store': NativeEngineDefinition(
      key: 'store',
      title: 'Store',
      route: '/tab/store',
      enabled: false,
      reservedForFuture: true,
    ),
    'community': NativeEngineDefinition(
      key: 'community',
      title: 'Community',
      route: '/tab/community',
      enabled: false,
      reservedForFuture: true,
    ),
    'donations': NativeEngineDefinition(
      key: 'donations',
      title: 'Donations',
      route: '/tab/donations',
      enabled: false,
      reservedForFuture: true,
    ),
    'prayer': NativeEngineDefinition(
      key: 'prayer',
      title: 'Prayer',
      route: '/tab/prayer',
      enabled: false,
      reservedForFuture: true,
    ),
    'events': NativeEngineDefinition(
      key: 'events',
      title: 'Events',
      route: '/tab/events',
      enabled: false,
      reservedForFuture: true,
    ),
  };

  static String normalizeEngine(String value) {
    final raw = value.trim().toLowerCase().replaceAll('-', '_');

    switch (raw) {
      case 'quotes':
      case 'quote_maker':
      case 'quotecreator':
        return 'quote_creator';
      case 'note':
      case 'notepad':
      case 'my_notes':
        return 'notes';
      case 'scripture':
      case 'holy_bible':
        return 'bible';
      case 'game':
      case 'gaming':
        return 'games';
      case 'browser':
      case 'external_web':
      case 'website':
        return 'web';
      case 'yt':
      case 'youtube_video':
      case 'youtube_player':
        return 'youtube';
      case 'livestream':
      case 'stream':
      case 'live_stream':
        return 'hls';
      case 'post':
      case 'blog':
      case 'article_detail':
        return 'article';
      case 'reels':
      case 'short':
      case 'short_video':
      case 'short_video_feed':
        return 'shorts';
      default:
        return raw;
    }
  }

  static NativeEngineDefinition? find(String engine) {
    final normalized = normalizeEngine(engine);
    return engines[normalized];
  }

  static bool isKnown(String engine) {
    return find(engine) != null;
  }

  static bool isEnabled(String engine) {
    final found = find(engine);
    return found != null && found.enabled;
  }

  static bool isReservedForFuture(String engine) {
    final found = find(engine);
    return found != null && found.reservedForFuture;
  }

  static String routeForAction(NativeEngineAction action) {
    final directRoute = action.route.trim();
    if (directRoute.isNotEmpty) {
      return directRoute;
    }

    final found = find(action.engine);
    if (found != null) {
      return found.route;
    }

    return '';
  }

  static List<NativeEngineDefinition> enabledEngines() {
    return engines.values.where((engine) => engine.enabled).toList();
  }

  static List<NativeEngineDefinition> futureEngines() {
    return engines.values.where((engine) => engine.reservedForFuture).toList();
  }
}
