import 'dart:convert';

class HubResponse {
  final Map<String, dynamic> platform;
  final HubConfig hub;

  HubResponse({required this.platform, required this.hub});

  factory HubResponse.fromJson(Map<String, dynamic> json) {
    return HubResponse(
      platform: (json['platform'] as Map?)?.cast<String, dynamic>() ?? {},
      hub: HubConfig.fromJson((json['hub'] as Map?)?.cast<String, dynamic>() ?? const {}),
    );
  }
}

class HubConfig {
  final int version;
  final HubNavigation navigation;
  final HubConsole console;
  final HubAds ads;
  final List<HubTab> tabs;

  HubConfig({
    required this.version,
    required this.navigation,
    required this.console,
    required this.ads,
    required this.tabs,
  });

  factory HubConfig.fromJson(Map<String, dynamic> json) {
    final tabsRaw = (json['tabs'] as List?) ?? const [];
    return HubConfig(
      version: (json['version'] as num?)?.toInt() ?? 1,
      navigation: HubNavigation.fromJson((json['navigation'] as Map?)?.cast<String, dynamic>() ?? const {}),
      console: HubConsole.fromJson((json['console'] as Map?)?.cast<String, dynamic>() ?? const {}),
      ads: HubAds.fromJson((json['ads'] as Map?)?.cast<String, dynamic>() ?? const {}),
      tabs: tabsRaw
          .whereType<Map>()
          .map((m) => HubTab.fromJson(m.cast<String, dynamic>()))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'navigation': navigation.toJson(),
        'console': console.toJson(),
        'ads': ads.toJson(),
        'tabs': tabs.map((e) => e.toJson()).toList(),
      };

  String toJsonString() => jsonEncode(toJson());

  static HubConfig? tryFromJsonString(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    try {
      final obj = jsonDecode(s);
      if (obj is Map<String, dynamic>) return HubConfig.fromJson(obj);
      return null;
    } catch (_) {
      return null;
    }
  }

  List<HubTab> enabledTabs() => tabs.where((t) => t.enabled).toList();
}

class HubTab {
  final String key; // home/watch/inspire/explore/more
  final String label;
  final bool enabled;
  final String icon;

  HubTab({
    required this.key,
    required this.label,
    required this.enabled,
    required this.icon,
  });

  factory HubTab.fromJson(Map<String, dynamic> json) {
    return HubTab(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      enabled: (json['enabled'] as bool?) ?? true,
      icon: (json['icon'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'enabled': enabled,
        'icon': icon,
      };
}

class HubNavigation {
  final String defaultTab; // home/watch/inspire/explore/more
  final String watchDefault; // live/vod/etc (future)

  HubNavigation({required this.defaultTab, required this.watchDefault});

  factory HubNavigation.fromJson(Map<String, dynamic> json) {
    return HubNavigation(
      defaultTab: (json['default_tab'] ?? 'home').toString(),
      watchDefault: (json['watch_default'] ?? 'live').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'default_tab': defaultTab,
        'watch_default': watchDefault,
      };
}

class HubConsole {
  final String appName;
  final String primaryColor;
  final String accentColor;

  HubConsole({
    required this.appName,
    required this.primaryColor,
    required this.accentColor,
  });

  factory HubConsole.fromJson(Map<String, dynamic> json) {
    return HubConsole(
      appName: (json['app_name'] ?? 'Dunamis TV').toString(),
      primaryColor: (json['primary_color'] ?? '#1e0042').toString(),
      accentColor: (json['accent_color'] ?? '#ff24a4').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'app_name': appName,
        'primary_color': primaryColor,
        'accent_color': accentColor,
      };
}

class HubAds {
  final bool enabledGlobal;
  final Map<String, dynamic> tabs; // future use by UI

  HubAds({required this.enabledGlobal, required this.tabs});

  factory HubAds.fromJson(Map<String, dynamic> json) {
    return HubAds(
      enabledGlobal: (json['enabled_global'] as bool?) ?? false,
      tabs: (json['tabs'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled_global': enabledGlobal,
        'tabs': tabs,
      };
}
