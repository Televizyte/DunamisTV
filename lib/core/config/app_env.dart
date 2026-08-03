class AppEnv {
  /// ✅ Change this to your DXM FireDrive base URL (no trailing slash)
  /// Example: https://digitxtramedia.com
  static const String apiBaseUrl = String.fromEnvironment(
    'DXM_API_BASE_URL',
    defaultValue: 'https://digitxtramedia.com',
  );

  /// API endpoint that returns hub config JSON for a platform
  /// We will call: {apiBaseUrl}/api/v1/platforms/{slug}/hub
  static String hubConfigUrl(String platformSlug) =>
      '$apiBaseUrl/api/v1/platforms/$platformSlug/hub';
}
