class HubConfig {
  final Map<String, dynamic> raw;

  HubConfig(this.raw);

  Map<String, dynamic> get hub => _asMap(raw['hub']) ?? raw;

  /// Common fields we’ll need now (Stage 1)
  String get appName => _asMap(hub['console'])?['app_name']?.toString() ?? 'Dunamis TV';

  String get primaryColor => _asMap(hub['console'])?['primary_color']?.toString() ?? '#22d3ee';
  String get accentColor => _asMap(hub['console'])?['accent_color']?.toString() ?? '#a855f7';

  Map<String, dynamic> get watch => _asMap(hub['watch']) ?? const {};
  String get watchHlsUrl => watch['hls_url']?.toString() ?? '';
  String get watchYoutubeUrl => watch['youtube_url']?.toString() ?? '';

  Map<String, dynamic> get watchSettings => _asMap(watch['settings']) ?? const {};
  bool get showShare => (watchSettings['show_share'] ?? true) == true;
  bool get showReactions => (watchSettings['show_reactions'] ?? true) == true;
  bool get allowComments => (watchSettings['allow_comments'] ?? true) == true;
  bool get showLiveBadge => (watchSettings['show_live_badge'] ?? true) == true;
  bool get forceSigninForActions => (watchSettings['force_signin_for_actions'] ?? true) == true;

  Map<String, dynamic> get ads => _asMap(hub['ads']) ?? const {};
  bool get adsEnabledGlobal => (ads['enabled_global'] ?? false) == true;

  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return null;
  }
}
