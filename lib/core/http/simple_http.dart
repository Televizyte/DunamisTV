import 'dart:convert';
import 'package:http/http.dart' as http;

class SimpleHttp {
  static Future<Map<String, dynamic>> getJson(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final res = await http.get(Uri.parse(url), headers: {
      'Accept': 'application/json',
      ...?headers,
    }).timeout(timeout);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException(
        'HTTP ${res.statusCode}: ${_safeBody(res.body)}',
        statusCode: res.statusCode,
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;

    // Some APIs return {"data":{...}} — we still accept only map at top-level
    throw const FormatException('Response is not a JSON object');
  }

  static String _safeBody(String body) {
    final trimmed = body.trim();
    if (trimmed.length <= 300) return trimmed;
    return '${trimmed.substring(0, 300)}...';
  }
}

class HttpException implements Exception {
  final String message;
  final int? statusCode;
  const HttpException(this.message, {this.statusCode});
  @override
  String toString() => message;
}
