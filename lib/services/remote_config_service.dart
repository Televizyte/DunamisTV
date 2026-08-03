import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'firedrive_api.dart';

class RemoteConfigService {
  static const _kCacheKey = 'dxm_remote_config_cache_v1';

  final FireDriveApi api;
  RemoteConfigService(this.api);

  Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();

    // 1) return cached immediately if exists
    final cached = prefs.getString(_kCacheKey);
    if (cached != null && cached.isNotEmpty) {
      try {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        // refresh in background
        _refresh(prefs);
        return data;
      } catch (_) {
        // ignore and fetch fresh below
      }
    }

    // 2) no cache -> fetch now
    final fresh = await api.getConfig();
    await prefs.setString(_kCacheKey, jsonEncode(fresh));
    return fresh;
  }

  Future<void> _refresh(SharedPreferences prefs) async {
    try {
      final fresh = await api.getConfig();
      await prefs.setString(_kCacheKey, jsonEncode(fresh));
    } catch (_) {
      // silent fail
    }
  }
}
