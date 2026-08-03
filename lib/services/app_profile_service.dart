import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../app_config.dart';

class AppPublicLink {
  final String key;
  final String label;
  final String value;
  final String type;
  final String icon;
  final String description;
  final bool enabled;

  const AppPublicLink({
    required this.key,
    required this.label,
    required this.value,
    required this.type,
    required this.icon,
    required this.description,
    required this.enabled,
  });

  bool get hasValue => value.trim().isNotEmpty;

  factory AppPublicLink.fromMap(
    Map<String, dynamic> map, {
    String fallbackKey = '',
    String fallbackLabel = '',
    String fallbackType = 'url',
    String fallbackIcon = 'link',
  }) {
    final key = _stringValue(map['key']).isNotEmpty
        ? _stringValue(map['key'])
        : fallbackKey;

    final label = _stringValue(map['label']).isNotEmpty
        ? _stringValue(map['label'])
        : fallbackLabel;

    final type = _stringValue(map['type']).isNotEmpty
        ? _stringValue(map['type'])
        : fallbackType;

    final icon = _stringValue(map['icon']).isNotEmpty
        ? _stringValue(map['icon'])
        : fallbackIcon;

    final enabledValue = map['enabled'];
    final enabled = enabledValue is bool
        ? enabledValue
        : enabledValue == null
            ? true
            : enabledValue.toString() != '0' &&
                enabledValue.toString().toLowerCase() != 'false';

    return AppPublicLink(
      key: key,
      label: label.isEmpty ? key : label,
      value: _stringValue(
          map['value'] ?? map['url'] ?? map['phone'] ?? map['email']),
      type: type,
      icon: icon,
      description: _stringValue(map['description'] ?? map['subtitle']),
      enabled: enabled,
    );
  }

  static String _stringValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }
}

class AppPublicSetting {
  final String key;
  final String label;
  final String value;
  final String type;
  final String icon;
  final String description;
  final bool enabled;

  const AppPublicSetting({
    required this.key,
    required this.label,
    required this.value,
    required this.type,
    required this.icon,
    required this.description,
    required this.enabled,
  });

  factory AppPublicSetting.fromMap(Map<String, dynamic> map) {
    final enabledValue = map['enabled'];
    final enabled = enabledValue is bool
        ? enabledValue
        : enabledValue == null
            ? true
            : enabledValue.toString() != '0' &&
                enabledValue.toString().toLowerCase() != 'false';

    final key = _stringValue(map['key']);
    final label = _stringValue(map['label']);

    return AppPublicSetting(
      key: key,
      label: label.isEmpty ? key : label,
      value: _stringValue(map['value']),
      type: _stringValue(map['type']).isEmpty
          ? 'text'
          : _stringValue(map['type']),
      icon: _stringValue(map['icon']).isEmpty
          ? 'info'
          : _stringValue(map['icon']),
      description: _stringValue(map['description']),
      enabled: enabled,
    );
  }

  static String _stringValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }
}

class AppPublicProfile {
  final String appName;
  final String displayName;
  final String tagline;
  final String about;
  final String websiteUrl;
  final String supportEmail;
  final String supportPhone;
  final String contactAddress;
  final String privacyUrl;
  final String termsUrl;
  final String playStoreUrl;
  final String versionName;
  final String versionCode;
  final Map<String, String> social;
  final List<AppPublicLink> supportChannels;
  final List<AppPublicLink> officialLinks;
  final List<AppPublicSetting> customPublicSettings;

  const AppPublicProfile({
    required this.appName,
    required this.displayName,
    required this.tagline,
    required this.about,
    required this.websiteUrl,
    required this.supportEmail,
    required this.supportPhone,
    required this.contactAddress,
    required this.privacyUrl,
    required this.termsUrl,
    required this.playStoreUrl,
    required this.versionName,
    required this.versionCode,
    required this.social,
    required this.supportChannels,
    required this.officialLinks,
    required this.customPublicSettings,
  });

  bool get hasWebsite => websiteUrl.trim().isNotEmpty;
  bool get hasSupportEmail => supportEmail.trim().isNotEmpty;
  bool get hasSupportPhone => supportPhone.trim().isNotEmpty;
  bool get hasAddress => contactAddress.trim().isNotEmpty;
  bool get hasPrivacy => privacyUrl.trim().isNotEmpty;
  bool get hasTerms => termsUrl.trim().isNotEmpty;
  bool get hasPlayStore => playStoreUrl.trim().isNotEmpty;

  List<AppPublicLink> get enabledSupportChannels => supportChannels
      .where((item) => item.enabled && item.value.trim().isNotEmpty)
      .toList(growable: false);

  List<AppPublicLink> get enabledOfficialLinks => officialLinks
      .where((item) => item.enabled && item.value.trim().isNotEmpty)
      .toList(growable: false);

  List<AppPublicSetting> get enabledCustomSettings => customPublicSettings
      .where((item) => item.enabled && item.value.trim().isNotEmpty)
      .toList(growable: false);

  bool get hasAnySupport =>
      enabledSupportChannels.isNotEmpty ||
      hasWebsite ||
      hasSupportEmail ||
      hasSupportPhone ||
      hasAddress;

  bool get hasAnySocial =>
      enabledOfficialLinks.isNotEmpty ||
      social.values.any((value) => value.trim().isNotEmpty);

  String get bestShareLink {
    if (hasPlayStore) return playStoreUrl;
    if (hasWebsite) return websiteUrl;
    if (enabledOfficialLinks.isNotEmpty)
      return enabledOfficialLinks.first.value;
    return AppConfig.apiBaseUrl;
  }

  factory AppPublicProfile.fallback() {
    return AppPublicProfile(
      appName: AppConfig.appName,
      displayName: AppConfig.appName,
      tagline: AppConfig.appTagline,
      about:
          'Dunamis TV brings inspiring messages, worship, devotionals, and faith-building content to viewers everywhere.',
      websiteUrl: '',
      supportEmail: '',
      supportPhone: '',
      contactAddress: '',
      privacyUrl: '',
      termsUrl: '',
      playStoreUrl: '',
      versionName: '',
      versionCode: '',
      social: const {
        'youtube': '',
        'facebook': '',
        'instagram': '',
        'x': '',
      },
      supportChannels: const [],
      officialLinks: const [],
      customPublicSettings: const [],
    );
  }

  AppPublicProfile copyWith({
    String? appName,
    String? displayName,
    String? tagline,
    String? about,
    String? websiteUrl,
    String? supportEmail,
    String? supportPhone,
    String? contactAddress,
    String? privacyUrl,
    String? termsUrl,
    String? playStoreUrl,
    String? versionName,
    String? versionCode,
    Map<String, String>? social,
    List<AppPublicLink>? supportChannels,
    List<AppPublicLink>? officialLinks,
    List<AppPublicSetting>? customPublicSettings,
  }) {
    return AppPublicProfile(
      appName: appName ?? this.appName,
      displayName: displayName ?? this.displayName,
      tagline: tagline ?? this.tagline,
      about: about ?? this.about,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      supportEmail: supportEmail ?? this.supportEmail,
      supportPhone: supportPhone ?? this.supportPhone,
      contactAddress: contactAddress ?? this.contactAddress,
      privacyUrl: privacyUrl ?? this.privacyUrl,
      termsUrl: termsUrl ?? this.termsUrl,
      playStoreUrl: playStoreUrl ?? this.playStoreUrl,
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
      social: social ?? this.social,
      supportChannels: supportChannels ?? this.supportChannels,
      officialLinks: officialLinks ?? this.officialLinks,
      customPublicSettings: customPublicSettings ?? this.customPublicSettings,
    );
  }
}

class AppProfileService {
  AppProfileService._();

  static final AppProfileService instance = AppProfileService._();

  static const String _cacheKey = 'dxm_app_public_profile_cache_v2';

  Future<AppPublicProfile> getProfile({bool refresh = false}) async {
    if (!refresh) {
      final cached = await _readCachedProfile();
      if (cached != null) return cached;
    }

    try {
      final response = await http.get(
        Uri.parse(AppConfig.hubBootstrapUrl),
        headers: {
          'Accept': 'application/json',
          'X-APP-TOKEN': AppConfig.appToken,
        },
      ).timeout(const Duration(seconds: 18));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final profile = _profileFromPayload(decoded.cast<String, dynamic>());
          await _cacheProfile(response.body);
          return profile;
        }
      }
    } catch (_) {}

    final cached = await _readCachedProfile();
    return cached ?? AppPublicProfile.fallback();
  }

  Future<AppPublicProfile?> _readCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.trim().isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return _profileFromPayload(decoded.cast<String, dynamic>());
      }
    } catch (_) {}

    return null;
  }

  Future<void> _cacheProfile(String rawJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, rawJson);
    } catch (_) {}
  }

  AppPublicProfile _profileFromPayload(Map<String, dynamic> payload) {
    final fallback = AppPublicProfile.fallback();

    final maps = _collectMaps(payload);

    final destinations = payload['destinations'] is Map
        ? Map<String, dynamic>.from(
            (payload['destinations'] as Map).cast<String, dynamic>())
        : const <String, dynamic>{};
    final legalPayload = payload['legal'] is Map
        ? Map<String, dynamic>.from(
            (payload['legal'] as Map).cast<String, dynamic>())
        : const <String, dynamic>{};

    String canonicalValue(List<String> path) {
      dynamic value = destinations;
      for (final key in path) {
        if (value is! Map || !value.containsKey(key)) return '';
        value = value[key];
      }
      if (value is Map) value = value['value'] ?? value['url'];
      return value?.toString().trim() ?? '';
    }

    String legalDocumentUrl(String key) {
      final docs = legalPayload['documents'];
      if (docs is Map && docs[key] is Map) {
        return ((docs[key] as Map)['url'] ?? '').toString().trim();
      }
      return '';
    }

    final appName = _firstString(
      maps,
      const ['name', 'app_name', 'appName'],
      fallback.appName,
    );

    final displayName = _firstString(
      maps,
      const ['display_name', 'displayName', 'title'],
      appName.trim().isEmpty ? fallback.displayName : appName,
    );

    final tagline = _firstString(
      maps,
      const ['tagline', 'subtitle', 'description_short', 'short_description'],
      fallback.tagline,
    );

    final about = _firstString(
      maps,
      const [
        'about',
        'about_text',
        'mission',
        'description',
        'full_description'
      ],
      fallback.about,
    );

    final website = canonicalValue(const ['official', 'website']).isNotEmpty
        ? canonicalValue(const ['official', 'website'])
        : _firstString(maps, const ['website_url', 'website', 'site_url'],
            fallback.websiteUrl);

    final supportEmail = _firstString(
      maps,
      const ['support_email', 'contact_email'],
      fallback.supportEmail,
    );

    final supportPhone = _firstString(
      maps,
      const ['support_phone', 'contact_phone'],
      fallback.supportPhone,
    );

    final address = _firstString(
      maps,
      const ['contact_address', 'address', 'location'],
      fallback.contactAddress,
    );

    final privacy = canonicalValue(const ['legal', 'privacy']).isNotEmpty
        ? canonicalValue(const ['legal', 'privacy'])
        : (legalDocumentUrl('privacy').isNotEmpty
            ? legalDocumentUrl('privacy')
            : _firstString(
                maps,
                const [
                  'privacy_url',
                  'privacy_policy_url',
                  'privacy_policy',
                  'privacy'
                ],
                fallback.privacyUrl));

    final terms = canonicalValue(const ['legal', 'terms']).isNotEmpty
        ? canonicalValue(const ['legal', 'terms'])
        : (legalDocumentUrl('terms').isNotEmpty
            ? legalDocumentUrl('terms')
            : _firstString(
                maps,
                const [
                  'terms_url',
                  'terms_of_use_url',
                  'terms_policy_url',
                  'terms'
                ],
                fallback.termsUrl));

    final playStore = canonicalValue(const ['store', 'rate']).isNotEmpty
        ? canonicalValue(const ['store', 'rate'])
        : _firstString(
            maps,
            const [
              'play_store_url',
              'playstore_url',
              'store_url',
              'android_store_url'
            ],
            fallback.playStoreUrl);

    final versionName = canonicalValue(const ['app', 'version_name']).isNotEmpty
        ? canonicalValue(const ['app', 'version_name'])
        : _firstString(maps, const ['version_name'], fallback.versionName);
    final versionCode = canonicalValue(const ['app', 'version_code']).isNotEmpty
        ? canonicalValue(const ['app', 'version_code'])
        : _firstString(maps, const ['version_code'], fallback.versionCode);

    final social = <String, String>{
      'youtube': _firstSocialString(maps, 'youtube'),
      'facebook': _firstSocialString(maps, 'facebook'),
      'instagram': _firstSocialString(maps, 'instagram'),
      'x': _firstSocialString(maps, 'x', aliases: const ['twitter']),
    };

    final supportChannels = _readLinkList(
      maps,
      keys: const ['support_channels', 'supportChannels', 'contact_channels'],
    );

    final officialLinks = _readLinkList(
      maps,
      keys: const ['official_links', 'officialLinks', 'links', 'social_links'],
    );

    final customSettings = _readSettingList(
      maps,
      keys: const [
        'custom_public_settings',
        'customPublicSettings',
        'public_settings',
        'extra_settings',
      ],
    );

    return fallback.copyWith(
      appName: appName,
      displayName: displayName,
      tagline: tagline,
      about: about,
      websiteUrl: website,
      supportEmail: supportEmail,
      supportPhone: supportPhone,
      contactAddress: address,
      privacyUrl: privacy,
      termsUrl: terms,
      playStoreUrl: playStore,
      versionName: versionName,
      versionCode: versionCode,
      social: social,
      supportChannels: supportChannels.isNotEmpty
          ? supportChannels
          : _legacySupportChannels(
              website: website,
              supportEmail: supportEmail,
              supportPhone: supportPhone,
              address: address,
            ),
      officialLinks: officialLinks.isNotEmpty
          ? officialLinks
          : _legacyOfficialLinks(social),
      customPublicSettings: customSettings,
    );
  }

  List<Map<String, dynamic>> _collectMaps(Map<String, dynamic> root) {
    final out = <Map<String, dynamic>>[];

    void visit(dynamic value) {
      if (value is Map) {
        final map = value.cast<String, dynamic>();
        out.add(map);
        for (final child in map.values) {
          visit(child);
        }
      } else if (value is List) {
        for (final child in value) {
          visit(child);
        }
      }
    }

    visit(root);
    return out;
  }

  List<AppPublicLink> _readLinkList(
    List<Map<String, dynamic>> maps, {
    required List<String> keys,
  }) {
    for (final key in keys) {
      for (final map in maps) {
        final value = map[key];
        if (value is List) {
          final links = <AppPublicLink>[];

          for (var index = 0; index < value.length; index++) {
            final item = value[index];
            if (item is Map) {
              final link = AppPublicLink.fromMap(
                item.cast<String, dynamic>(),
                fallbackKey: '${key}_$index',
                fallbackLabel: 'Link ${index + 1}',
              );

              if (link.hasValue) links.add(link);
            }
          }

          if (links.isNotEmpty) return links;
        }
      }
    }

    return <AppPublicLink>[];
  }

  List<AppPublicSetting> _readSettingList(
    List<Map<String, dynamic>> maps, {
    required List<String> keys,
  }) {
    for (final key in keys) {
      for (final map in maps) {
        final value = map[key];
        if (value is List) {
          final settings = <AppPublicSetting>[];

          for (final item in value) {
            if (item is Map) {
              final setting = AppPublicSetting.fromMap(
                item.cast<String, dynamic>(),
              );

              if (setting.key.trim().isNotEmpty &&
                  setting.value.trim().isNotEmpty) {
                settings.add(setting);
              }
            }
          }

          if (settings.isNotEmpty) return settings;
        }
      }
    }

    return <AppPublicSetting>[];
  }

  List<AppPublicLink> _legacySupportChannels({
    required String website,
    required String supportEmail,
    required String supportPhone,
    required String address,
  }) {
    return <AppPublicLink>[
      if (website.trim().isNotEmpty)
        AppPublicLink(
          key: 'website',
          label: 'Website',
          value: website,
          type: 'url',
          icon: 'website',
          description: 'Official website',
          enabled: true,
        ),
      if (supportEmail.trim().isNotEmpty)
        AppPublicLink(
          key: 'technical_support',
          label: 'Technical Support',
          value: supportEmail,
          type: 'email',
          icon: 'support',
          description: 'For app and technical support',
          enabled: true,
        ),
      if (supportPhone.trim().isNotEmpty)
        AppPublicLink(
          key: 'phone',
          label: 'Phone',
          value: supportPhone,
          type: 'phone',
          icon: 'phone',
          description: 'Official contact phone',
          enabled: true,
        ),
      if (address.trim().isNotEmpty)
        AppPublicLink(
          key: 'address',
          label: 'Address',
          value: address,
          type: 'address',
          icon: 'address',
          description: 'Official contact address',
          enabled: true,
        ),
    ];
  }

  List<AppPublicLink> _legacyOfficialLinks(Map<String, String> social) {
    return <AppPublicLink>[
      if ((social['facebook'] ?? '').trim().isNotEmpty)
        AppPublicLink(
          key: 'facebook',
          label: 'Facebook',
          value: social['facebook']!,
          type: 'url',
          icon: 'facebook',
          description: 'Official Facebook page',
          enabled: true,
        ),
      if ((social['x'] ?? '').trim().isNotEmpty)
        AppPublicLink(
          key: 'x',
          label: 'X / Twitter',
          value: social['x']!,
          type: 'url',
          icon: 'x',
          description: 'Official X account',
          enabled: true,
        ),
      if ((social['instagram'] ?? '').trim().isNotEmpty)
        AppPublicLink(
          key: 'instagram',
          label: 'Instagram',
          value: social['instagram']!,
          type: 'url',
          icon: 'instagram',
          description: 'Official Instagram account',
          enabled: true,
        ),
      if ((social['youtube'] ?? '').trim().isNotEmpty)
        AppPublicLink(
          key: 'youtube',
          label: 'YouTube',
          value: social['youtube']!,
          type: 'url',
          icon: 'youtube',
          description: 'Official YouTube channel',
          enabled: true,
        ),
    ];
  }

  String _firstString(
    List<Map<String, dynamic>> maps,
    List<String> keys,
    String fallback,
  ) {
    for (final key in keys) {
      for (final map in maps) {
        final value = map[key];
        final text = _stringValue(value);
        if (text.isNotEmpty) return text;
      }
    }

    return fallback;
  }

  String _firstSocialString(
    List<Map<String, dynamic>> maps,
    String key, {
    List<String> aliases = const [],
  }) {
    final keys = <String>[
      key,
      '${key}_url',
      ...aliases,
      ...aliases.map((e) => '${e}_url'),
    ];

    for (final map in maps) {
      final social = map['social'];
      if (social is Map) {
        for (final socialKey in keys) {
          final text = _stringValue(social[socialKey]);
          if (text.isNotEmpty) return text;
        }
      }
    }

    return _firstString(maps, keys, '');
  }

  String _stringValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }
}
