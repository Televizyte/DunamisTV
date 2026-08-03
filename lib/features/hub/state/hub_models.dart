class HubConfig {
  final String hlsUrl;
  final String youtubeUrl;

  const HubConfig({
    required this.hlsUrl,
    required this.youtubeUrl,
  });

  factory HubConfig.fallback({
    required String hlsUrl,
    required String youtubeUrl,
  }) {
    return HubConfig(hlsUrl: hlsUrl, youtubeUrl: youtubeUrl);
  }

  factory HubConfig.fromJson(Map<String, dynamic> json, HubConfig fallback) {
    String pick(String key, String fb) {
      final v = json[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      return fb;
    }

    // Allow multiple possible keys (so FireDrive can evolve without breaking app)
    final hls = pick('hls_url', pick('live_hls', fallback.hlsUrl));
    final yt = pick('youtube_url', pick('live_youtube', fallback.youtubeUrl));

    return HubConfig(hlsUrl: hls, youtubeUrl: yt);
  }
}
