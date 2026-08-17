import 'package:shared_preferences/shared_preferences.dart';

import 'backend_environment.dart';

class BackendCacheIdentity {
  const BackendCacheIdentity._();

  static const legacyProductionKey = 'dxm.hub.bootstrap.cache.v2';

  static String key({
    required String appSlug,
    required BackendEndpointResolution endpoint,
    String namespace = 'hub.bootstrap',
  }) {
    final slug =
        appSlug.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
    final identity = '${endpoint.environment.name}|${endpoint.apiBaseUrl}';
    final safeNamespace =
        namespace.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9.]+'), '.');
    return 'dxm.$safeNamespace.cache.v3.$slug.${_safeHash(identity)}';
  }

  static String _safeHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}

class BackendResponseCache {
  final SharedPreferences preferences;
  final String appSlug;
  final BackendEndpointResolution endpoint;
  final String namespace;
  final String legacyProductionKey;

  const BackendResponseCache({
    required this.preferences,
    required this.appSlug,
    required this.endpoint,
    this.namespace = 'hub.bootstrap',
    this.legacyProductionKey = BackendCacheIdentity.legacyProductionKey,
  });

  String get key => BackendCacheIdentity.key(
        appSlug: appSlug,
        endpoint: endpoint,
        namespace: namespace,
      );

  Future<String?> load() async {
    final current = preferences.getString(key);
    if (current != null && current.trim().isNotEmpty) return current;
    if (!endpoint.isProduction) return null;

    final legacy = preferences.getString(legacyProductionKey);
    if (legacy == null || legacy.trim().isEmpty) return null;

    await preferences.setString(key, legacy);
    await preferences.remove(legacyProductionKey);
    return legacy;
  }

  Future<void> save(String value) async {
    await preferences.setString(key, value);
  }

  Future<void> clear() async {
    await preferences.remove(key);
  }

  bool get exists {
    final value = preferences.getString(key);
    return value != null && value.trim().isNotEmpty;
  }
}
