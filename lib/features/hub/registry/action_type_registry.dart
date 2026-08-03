class ActionTypeRegistry {
  const ActionTypeRegistry._();

  static const Set<String> nativeEngineActions = {
    'engine',
    'native_engine',
    'tool',
    'tool_launch',
  };

  static const Set<String> routeActions = {
    'route',
    'screen',
    'internal_route',
    'navigation',
  };

  static const Set<String> webActions = {
    'web',
    'external',
    'external_url',
    'browser',
    'website',
  };

  static const Set<String> videoActions = {
    'video',
    'youtube',
    'hls',
    'live',
    'stream',
  };

  static const Set<String> articleActions = {
    'article',
    'blog',
    'read',
    'post',
  };

  static const Set<String> shortsActions = {
    'shorts',
    'reels',
    'short_video',
  };

  static bool isNativeEngine(String value) {
    return nativeEngineActions.contains(
      value.trim().toLowerCase(),
    );
  }

  static bool isRoute(String value) {
    return routeActions.contains(
      value.trim().toLowerCase(),
    );
  }

  static bool isWeb(String value) {
    return webActions.contains(
      value.trim().toLowerCase(),
    );
  }

  static bool isVideo(String value) {
    return videoActions.contains(
      value.trim().toLowerCase(),
    );
  }

  static bool isArticle(String value) {
    return articleActions.contains(
      value.trim().toLowerCase(),
    );
  }

  static bool isShorts(String value) {
    return shortsActions.contains(
      value.trim().toLowerCase(),
    );
  }
}
