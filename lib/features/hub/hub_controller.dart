import 'package:flutter/foundation.dart';

import '../../core/config/hub_cache.dart';
import '../../core/config/hub_config.dart';
import 'hub_repository.dart';

class HubController extends ChangeNotifier {
  HubController({
    required this.platformSlug,
    HubRepository? repo,
  }) : _repo = repo ?? HubRepository();

  final String platformSlug;
  final HubRepository _repo;

  HubConfig? _config;
  HubConfig? get config => _config;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  DateTime? _lastSavedAt;
  DateTime? get lastSavedAt => _lastSavedAt;

  /// Load from cache first (fast UI), then optionally refresh from API.
  Future<void> init({bool refreshAfterCache = true}) async {
    _error = null;

    final cached = await HubCache.load(platformSlug);
    _lastSavedAt = await HubCache.savedAt(platformSlug);

    if (cached != null) {
      _config = HubConfig(cached);
      notifyListeners();
    }

    if (refreshAfterCache) {
      await refresh();
    }
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final remote = await _repo.fetchHubConfig(platformSlug);

      // Cache + apply
      await HubCache.save(platformSlug, remote);
      _lastSavedAt = await HubCache.savedAt(platformSlug);

      _config = HubConfig(remote);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> clearCache() async {
    await HubCache.clear(platformSlug);
    _config = null;
    _lastSavedAt = null;
    notifyListeners();
  }
}
