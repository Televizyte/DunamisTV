import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HubCache {
  static const _keyPrefix = 'dxm_hub_config_';
  static const _keySavedAtPrefix = 'dxm_hub_saved_at_';

  static String _key(String platformSlug) => '$_keyPrefix$platformSlug';
  static String _keySavedAt(String platformSlug) => '$_keySavedAtPrefix$platformSlug';

  static Future<void> save(String platformSlug, Map<String, dynamic> json) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key(platformSlug), jsonEncode(json));
    await sp.setInt(_keySavedAt(platformSlug), DateTime.now().millisecondsSinceEpoch);
  }

  static Future<Map<String, dynamic>?> load(String platformSlug) async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_key(platformSlug));
    if (s == null || s.trim().isEmpty) return null;

    final decoded = jsonDecode(s);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.map((k, v) => MapEntry(k.toString(), v));
    return null;
  }

  static Future<DateTime?> savedAt(String platformSlug) async {
    final sp = await SharedPreferences.getInstance();
    final ms = sp.getInt(_keySavedAt(platformSlug));
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> clear(String platformSlug) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key(platformSlug));
    await sp.remove(_keySavedAt(platformSlug));
  }
}
