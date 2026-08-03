import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app_config.dart';

class MoreInformationService {
  MoreInformationService._();

  static final MoreInformationService instance = MoreInformationService._();

  Future<Map<String, dynamic>> load() async {
    final response = await http.get(
      Uri.parse(AppConfig.hubBootstrapUrl),
      headers: {
        'Accept': 'application/json',
        'X-APP-TOKEN': AppConfig.appToken,
      },
    ).timeout(const Duration(seconds: 18));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Unable to load app information.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw const FormatException('Invalid bootstrap data.');
    final payload = Map<String, dynamic>.from(decoded.cast<String, dynamic>());
    final pages = payload['more_pages'];
    if (pages is! Map)
      throw const FormatException('More pages are unavailable.');
    return Map<String, dynamic>.from(pages.cast<String, dynamic>());
  }
}
