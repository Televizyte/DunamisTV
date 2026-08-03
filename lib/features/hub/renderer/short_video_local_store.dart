import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ShortVideoLocalStore {
  // Backward-compatible saved/bookmarked storage. Existing saved videos remain saved.
  static const String _favoritesKey = 'dxm.short_video.favorite_ids.v1';
  static const String _likedKey = 'dxm.short_video.liked_ids.v1';
  static const String _recentKey = 'dxm.short_video.recent_ids.v1';

  const ShortVideoLocalStore();

  Future<Set<String>> loadFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey)?.toSet() ?? <String>{};
  }

  Future<Set<String>> toggleFavorite(String id) async {
    final clean = id.trim();
    final ids = await loadFavoriteIds();
    if (clean.isEmpty) return ids;
    if (ids.contains(clean)) {
      ids.remove(clean);
    } else {
      ids.add(clean);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, ids.toList(growable: false));
    return ids;
  }

  Future<Set<String>> loadLikedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_likedKey)?.toSet() ?? <String>{};
  }

  Future<Set<String>> toggleLiked(String id) async {
    final clean = id.trim();
    final ids = await loadLikedIds();
    if (clean.isEmpty) return ids;
    if (ids.contains(clean)) {
      ids.remove(clean);
    } else {
      ids.add(clean);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_likedKey, ids.toList(growable: false));
    return ids;
  }

  Future<List<String>> loadRecentIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recentKey);
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).toList(growable: false);
      }
    } catch (_) {}
    return const [];
  }

  Future<void> markWatched(String id) async {
    final clean = id.trim();
    if (clean.isEmpty) return;
    final current = await loadRecentIds();
    final updated = <String>[clean, ...current.where((item) => item != clean)]
        .take(40)
        .toList(growable: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recentKey, jsonEncode(updated));
  }
}
