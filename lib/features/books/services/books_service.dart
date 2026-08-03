import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../app_config.dart';
import '../models/book_models.dart';

class BooksService {
  BooksService(
      {http.Client? client, this.timeout = const Duration(seconds: 18)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-APP-TOKEN': AppConfig.appToken,
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      };

  String get _base =>
      '${AppConfig.apiBaseUrl}/api/v1/apps/${AppConfig.appSlug}/books';

  Future<BooksListResponse> fetchBooks({int page = 1, int perPage = 48}) async {
    final uri = Uri.parse('$_base?page=$page&per_page=$perPage');
    final decoded = await _getJson(uri);
    return BooksListResponse.fromJson(decoded);
  }

  Future<BooksListResponse> fetchFeaturedBooks() async {
    final uri = Uri.parse('$_base/featured');
    final decoded = await _getJson(uri);
    return BooksListResponse.fromJson(decoded);
  }

  Future<List<BookCategory>> fetchCategories() async {
    final uri = Uri.parse('$_base/categories');
    final decoded = await _getJson(uri);
    final raw = decoded['items'] ?? decoded['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => BookCategory.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<BookItem> fetchBook(String idOrSlug) async {
    final uri = Uri.parse('$_base/${Uri.encodeComponent(idOrSlug)}');
    final decoded = await _getJson(uri);
    return BookItem.fromJson(_extractItem(decoded));
  }

  Future<List<BookChapter>> fetchBookChapters(String bookIdOrSlug) async {
    final uri =
        Uri.parse('$_base/${Uri.encodeComponent(bookIdOrSlug)}/chapters');
    final decoded = await _getJson(uri);
    final raw = decoded['items'] ?? decoded['data'] ?? decoded['chapters'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => BookChapter.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<BookChapter> fetchChapter({
    required String bookIdOrSlug,
    required String chapterIdOrSlug,
  }) async {
    final uri = Uri.parse(
      '$_base/${Uri.encodeComponent(bookIdOrSlug)}/chapters/${Uri.encodeComponent(chapterIdOrSlug)}',
    );
    final decoded = await _getJson(uri);
    final item = decoded['item'] ?? decoded['chapter'] ?? decoded['data'];
    if (item is Map) return BookChapter.fromJson(item.cast<String, dynamic>());
    return BookChapter.fromJson(decoded);
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final res = await _client.get(uri, headers: _headers).timeout(timeout,
        onTimeout: () {
      throw TimeoutException(
          'Books request timed out after ${timeout.inSeconds}s', timeout);
    });

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw BooksServiceException(
          'Books request failed (${res.statusCode}): ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
    throw BooksServiceException(
        'Invalid books response: ${decoded.runtimeType}');
  }

  Map<String, dynamic> _extractItem(Map<String, dynamic> decoded) {
    final candidates = [decoded['item'], decoded['book'], decoded['data']];
    for (final candidate in candidates) {
      if (candidate is Map<String, dynamic>) return candidate;
      if (candidate is Map) return candidate.cast<String, dynamic>();
    }
    return decoded;
  }
}

class BooksServiceException implements Exception {
  final String message;
  const BooksServiceException(this.message);

  @override
  String toString() => message;
}
