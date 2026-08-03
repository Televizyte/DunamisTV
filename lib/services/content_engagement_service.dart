import 'dart:convert';

import 'package:http/http.dart' as http;
import '../app_config.dart';
import 'app_auth_service.dart';

class EngagementAuthRequiredException implements Exception {
  final String message;
  EngagementAuthRequiredException([this.message = 'Authentication required']);

  @override
  String toString() => message;
}

class EngagementApiException implements Exception {
  final String message;
  EngagementApiException(this.message);

  @override
  String toString() => message;
}

class ContentEngagementService {
  ContentEngagementService._();
  static final ContentEngagementService instance = ContentEngagementService._();

  Uri _appBaseUri() {
    final uri = Uri.parse(AppConfig.hubBootstrapUrl);
    final cleanedPath = uri.path.replaceFirst(RegExp(r'/bootstrap$'), '');
    return uri.replace(path: cleanedPath, query: null);
  }

  Uri _commentsUri(String idOrSlug) {
    final base = _appBaseUri();
    return base.replace(
      path: '${base.path}/content/${Uri.encodeComponent(idOrSlug)}/comments',
    );
  }

  Uri _commentStatusUri(String idOrSlug, int commentId) {
    final base = _appBaseUri();
    return base.replace(
      path:
          '${base.path}/content/${Uri.encodeComponent(idOrSlug)}/comments/$commentId/status',
    );
  }

  Uri _commentDeleteUri(String idOrSlug, int commentId) {
    final base = _appBaseUri();
    return base.replace(
      path:
          '${base.path}/content/${Uri.encodeComponent(idOrSlug)}/comments/$commentId',
    );
  }

  Uri _saveUri(String idOrSlug) {
    final base = _appBaseUri();
    return base.replace(
      path: '${base.path}/content/${Uri.encodeComponent(idOrSlug)}/save',
    );
  }

  Uri _likeUri(String idOrSlug) {
    final base = _appBaseUri();
    return base.replace(
      path: '${base.path}/content/${Uri.encodeComponent(idOrSlug)}/like',
    );
  }

  Future<Map<String, String>> _headers({bool includeAuth = false}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'X-APP-TOKEN': AppConfig.appToken,
      'Cache-Control': 'no-cache',
    };

    if (includeAuth) {
      final token = await _readAuthToken();
      if (token == null || token.trim().isEmpty) {
        throw EngagementAuthRequiredException();
      }
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<String?> _readAuthToken() async {
    await AppAuthState.instance.load();
    final token = AppAuthState.instance.token;
    if (token == null || token.trim().isEmpty) return null;
    return token.trim();
  }

  Future<Map<String, dynamic>> fetchComments(String idOrSlug) async {
    final res = await http
        .get(
          _commentsUri(idOrSlug),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw EngagementApiException(
        'Comments load failed (${res.statusCode}): ${res.body}',
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();

    throw EngagementApiException('Invalid comments response format');
  }

  Future<Map<String, dynamic>> postComment(
    String idOrSlug,
    String body,
  ) async {
    final res = await http
        .post(
          _commentsUri(idOrSlug),
          headers: {
            ...(await _headers(includeAuth: true)),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'body': body.trim(),
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 401) {
      throw EngagementAuthRequiredException();
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw EngagementApiException(
        'Comment submit failed (${res.statusCode}): ${res.body}',
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();

    throw EngagementApiException('Invalid comment submit response');
  }

  Future<void> deleteComment(String idOrSlug, int commentId) async {
    final res = await http
        .delete(
          _commentDeleteUri(idOrSlug, commentId),
          headers: await _headers(includeAuth: true),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 401) {
      throw EngagementAuthRequiredException();
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw EngagementApiException(
        'Comment delete failed (${res.statusCode}): ${res.body}',
      );
    }
  }

  Future<Map<String, dynamic>> setSaved(
    String idOrSlug, {
    required bool saved,
  }) async {
    final uri = _saveUri(idOrSlug);

    final res = saved
        ? await http
            .post(uri, headers: await _headers(includeAuth: true))
            .timeout(const Duration(seconds: 20))
        : await http
            .delete(uri, headers: await _headers(includeAuth: true))
            .timeout(const Duration(seconds: 20));

    if (res.statusCode == 401) {
      throw EngagementAuthRequiredException();
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw EngagementApiException(
        'Save update failed (${res.statusCode}): ${res.body}',
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();

    throw EngagementApiException('Invalid save response');
  }

  Future<Map<String, dynamic>> setLike(
    String idOrSlug, {
    required bool like,
  }) async {
    final uri = _likeUri(idOrSlug);

    final res = like
        ? await http
            .post(uri, headers: await _headers(includeAuth: true))
            .timeout(const Duration(seconds: 20))
        : await http
            .delete(uri, headers: await _headers(includeAuth: true))
            .timeout(const Duration(seconds: 20));

    if (res.statusCode == 401) {
      throw EngagementAuthRequiredException();
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw EngagementApiException(
        'Like update failed (${res.statusCode}): ${res.body}',
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();

    throw EngagementApiException('Invalid like response');
  }
}
