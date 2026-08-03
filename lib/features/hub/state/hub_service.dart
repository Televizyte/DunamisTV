import 'dart:convert';

import 'hub_models.dart';
import 'hub_store.dart';

// Conditional import: web vs io vs stub
import 'hub_fetcher_stub.dart'
    if (dart.library.html) 'hub_fetcher_web.dart'
    if (dart.library.io) 'hub_fetcher_io.dart';

class HubService {
  final String bootstrapUrl;

  HubService({required this.bootstrapUrl});

  Future<HubConfig> fetchConfig(HubConfig fallback) async {
    final raw = await hubHttpGet(bootstrapUrl);
    if (raw.trim().isEmpty) return fallback;

    try {
      final decoded = jsonDecode(raw);

      // Accept either:
      // 1) { "hls_url": "...", "youtube_url": "..." }
      // 2) { "data": { ...same... } }
      if (decoded is Map<String, dynamic>) {
        final maybeData = decoded['data'];
        if (maybeData is Map<String, dynamic>) {
          return HubConfig.fromJson(maybeData, fallback);
        }
        return HubConfig.fromJson(decoded, fallback);
      }

      return fallback;
    } catch (_) {
      return fallback;
    }
  }
}
