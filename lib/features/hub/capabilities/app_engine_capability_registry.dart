import 'app_engine_capability.dart';

class AppEngineCapabilityRegistry {
  const AppEngineCapabilityRegistry._();

  static const AppEngineCapability tv = AppEngineCapability(
    key: 'tv',
    title: 'TV / Ministry / Channel App',
    description:
        'For apps like Dunamis TV, Celebration TV, church TV, video ministry, and channel-based streaming apps.',
    requiredEngines: [
      'youtube',
      'hls',
      'article',
      'web',
    ],
    optionalEngines: [
      'bible',
      'notes',
      'quote_creator',
      'shorts',
      'games',
      'events',
      'donations',
      'prayer',
    ],
    reservedFutureEngines: [
      'podcast',
      'music',
      'community',
      'courses',
    ],
  );

  static const AppEngineCapability store = AppEngineCapability(
    key: 'store',
    title: 'Store / Commerce App',
    description:
        'For ecommerce, digital product stores, restaurant ordering, service booking, and marketplace-style apps.',
    requiredEngines: [
      'store',
      'product',
      'cart',
      'checkout',
      'orders',
      'account',
    ],
    optionalEngines: [
      'web',
      'article',
      'notes',
      'events',
      'community',
    ],
    reservedFutureEngines: [
      'wallet',
      'delivery_tracking',
      'coupons',
      'affiliate',
    ],
  );

  static const AppEngineCapability media = AppEngineCapability(
    key: 'media',
    title: 'Media Player App',
    description:
        'For music, video, podcast, teaching libraries, playlist apps, and media learning apps.',
    requiredEngines: [
      'media_player',
      'video_player',
      'audio_player',
      'playlist',
    ],
    optionalEngines: [
      'notes',
      'quote_creator',
      'article',
      'web',
      'shorts',
      'bible',
    ],
    reservedFutureEngines: [
      'transcription',
      'lyrics',
      'downloads',
      'background_audio',
    ],
  );

  static const AppEngineCapability radio = AppEngineCapability(
    key: 'radio',
    title: 'Radio App',
    description:
        'For live radio stations, audio streams, program schedules, and station-based broadcast apps.',
    requiredEngines: [
      'live_audio',
      'radio_station',
      'schedule',
    ],
    optionalEngines: [
      'article',
      'web',
      'notes',
      'community',
      'events',
    ],
    reservedFutureEngines: [
      'background_audio',
      'notification_controls',
      'now_playing',
      'chat',
    ],
  );

  static const AppEngineCapability tools = AppEngineCapability(
    key: 'tools',
    title: 'Tools / Utility App',
    description:
        'For calculator, note, design, QR, invoice, productivity, learning, and utility-focused apps.',
    requiredEngines: [
      'web',
      'notes',
    ],
    optionalEngines: [
      'quote_creator',
      'article',
      'store',
      'community',
    ],
    reservedFutureEngines: [
      'calculator',
      'qr_generator',
      'invoice',
      'pdf_export',
      'image_export',
    ],
  );

  static const Map<String, AppEngineCapability> capabilities = {
    'tv': tv,
    'channel': tv,
    'ministry': tv,
    'church_tv': tv,
    'store': store,
    'commerce': store,
    'ecommerce': store,
    'restaurant': store,
    'marketplace': store,
    'media': media,
    'player': media,
    'music': media,
    'podcast': media,
    'radio': radio,
    'tools': tools,
    'utility': tools,
    'productivity': tools,
  };

  static AppEngineCapability find(String value) {
    final key = value.trim().toLowerCase().replaceAll('-', '_');
    return capabilities[key] ?? tv;
  }

  static bool supportsEngine({
    required String appType,
    required String engine,
  }) {
    return find(appType).supportsEngine(engine);
  }

  static List<String> enginesFor(String appType) {
    return find(appType).allEngines;
  }
}
