import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/firedrive_config.dart';

class FireDriveApi {
  final http.Client _client;
  FireDriveApi({http.Client? client}) : _client = client ?? http.Client();

  Uri _u(String path) => Uri.parse('${FireDriveConfig.baseUrl}$path');

  Future<Map<String, dynamic>> getConfig() async {
    final res = await _client.get(_u('/platforms/${FireDriveConfig.platformKey}/api/config'));
    if (res.statusCode != 200) {
      throw Exception('Config failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getPosts({String? category}) async {
    final q = category == null ? '' : '?category=${Uri.encodeComponent(category)}';
    final res = await _client.get(_u('/platforms/${FireDriveConfig.platformKey}/api/posts$q'));
    if (res.statusCode != 200) {
      throw Exception('Posts failed: ${res.statusCode} ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['data'] as List<dynamic>);
  }

  Future<Map<String, dynamic>> getPost(int id) async {
    final res = await _client.get(_u('/platforms/${FireDriveConfig.platformKey}/api/posts/$id'));
    if (res.statusCode != 200) {
      throw Exception('Post failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getQuoteToday() async {
    final res = await _client.get(_u('/platforms/${FireDriveConfig.platformKey}/api/quotes/today'));
    if (res.statusCode != 200) {
      throw Exception('QuoteToday failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded == null) return null;
    return decoded as Map<String, dynamic>;
  }
}
