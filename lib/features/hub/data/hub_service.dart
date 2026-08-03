import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../app_config.dart';

/// Generic AppsHub JSON service used by the Flutter render engine.
///
/// This service is intentionally app-agnostic. It does not hardcode Dunamis TV,
/// Celebration TV, or any future platform name. App identity stays in AppConfig.
class HubService {
  final String bootstrapUrl;
  final Duration timeout;
  final http.Client? client;

  const HubService({
    required this.bootstrapUrl,
    this.timeout = const Duration(seconds: 15),
    this.client,
  });

  Map<String, String> _headers() {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-APP-TOKEN': AppConfig.appToken,
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
    };
  }

  Future<Map<String, dynamic>> fetchBootstrapJson() async {
    final url = bootstrapUrl.trim();

    if (url.isEmpty) {
      throw const HubServiceException('AppsHub bootstrap URL is empty');
    }

    final uri = Uri.parse(url);
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;

    try {
      final res = await httpClient
          .get(uri, headers: _headers())
          .timeout(timeout, onTimeout: () {
        throw TimeoutException(
          'AppsHub bootstrap request timed out after ${timeout.inSeconds}s',
          timeout,
        );
      });

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw HubServiceException(
          'AppsHub bootstrap failed (${res.statusCode}): ${res.body}',
        );
      }

      final decoded = jsonDecode(res.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      throw HubServiceException(
        'Invalid AppsHub bootstrap JSON format: ${decoded.runtimeType}',
      );
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }
}

class HubServiceException implements Exception {
  final String message;

  const HubServiceException(this.message);

  @override
  String toString() => message;
}
