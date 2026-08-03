class PlatformEnv {
  // ✅ Change these only if needed
  static const String apiBaseUrl = 'https://digitxtramedia.com';
  static const String platformSlug = 'dunamis-tv';

  // Hub endpoint used by Stage 2
  static String hubUrl() => '$apiBaseUrl/api/v1/platforms/$platformSlug/hub';
}
