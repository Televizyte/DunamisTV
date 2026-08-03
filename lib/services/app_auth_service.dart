import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../app_config.dart';
import 'notification_bootstrap_service.dart';

class AppUser {
  final int id;
  final String name;
  final String email;

  const AppUser({required this.id, required this.name, required this.email});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: (json['name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}

class AppAuthState extends ChangeNotifier {
  AppAuthState._();

  static final AppAuthState instance = AppAuthState._();

  static const _tokenKey = 'app_user_token';
  static const _userKey = 'app_user_json';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  String? _token;
  AppUser? _user;
  bool _loaded = false;
  bool _loading = false;

  bool get isLoaded => _loaded;
  bool get isSignedIn => (_token ?? '').isNotEmpty && _user != null;
  String? get token => _token;
  AppUser? get user => _user;

  Future<String?> _readToken() async {
    final prefs = await SharedPreferences.getInstance();

    if (kIsWeb) {
      return prefs.getString(_tokenKey);
    }

    final secureToken = await _secureStorage.read(key: _tokenKey);
    if (secureToken != null && secureToken.trim().isNotEmpty) {
      return secureToken.trim();
    }

    // One-time migration from the legacy SharedPreferences token.
    final legacyToken = prefs.getString(_tokenKey);
    if (legacyToken != null && legacyToken.trim().isNotEmpty) {
      await _secureStorage.write(key: _tokenKey, value: legacyToken.trim());
      await prefs.remove(_tokenKey);
      return legacyToken.trim();
    }

    return null;
  }

  Future<void> _writeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();

    if (kIsWeb) {
      await prefs.setString(_tokenKey, token);
      return;
    }

    await _secureStorage.write(key: _tokenKey, value: token);
    await prefs.remove(_tokenKey);
  }

  Future<void> _deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);

    if (!kIsWeb) {
      await _secureStorage.delete(key: _tokenKey);
    }
  }

  Future<void> load() async {
    if (_loaded || _loading) return;
    _loading = true;

    try {
      final token = await _readToken();

      if (token == null || token.isEmpty) {
        _token = null;
        _user = null;
      } else {
        try {
          final user = await AppAuthService.instance.fetchCurrentUser(token);
          _token = token;
          _user = user;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userKey, jsonEncode(user.toJson()));

          await NotificationBootstrapService.instance
              .syncCurrentTokenOwnership(bearerToken: token);
        } on AppAuthException catch (error) {
          if (error.statusCode == 401 || error.statusCode == 403) {
            await _deleteToken();
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_userKey);
            _token = null;
            _user = null;
          } else {
            // A temporary network/backend error must not destroy a valid local
            // credential. Keep the cached user for this launch and retry later.
            final prefs = await SharedPreferences.getInstance();
            final raw = prefs.getString(_userKey);
            _token = token;
            _user = _decodeCachedUser(raw);
          }
        } catch (_) {
          final prefs = await SharedPreferences.getInstance();
          final raw = prefs.getString(_userKey);
          _token = token;
          _user = _decodeCachedUser(raw);
        }
      }
    } finally {
      _loaded = true;
      _loading = false;
      notifyListeners();
    }
  }

  AppUser? _decodeCachedUser(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> setSession(String token, AppUser user) async {
    final cleanToken = token.trim();
    _token = cleanToken;
    _user = user;

    await _writeToken(cleanToken);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));

    _loaded = true;
    notifyListeners();

    await NotificationBootstrapService.instance
        .syncCurrentTokenOwnership(bearerToken: cleanToken);
  }

  Future<void> clear({bool resyncDeviceAsGuest = true}) async {
    _token = null;
    _user = null;

    await _deleteToken();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);

    _loaded = true;
    notifyListeners();

    if (resyncDeviceAsGuest) {
      await NotificationBootstrapService.instance.syncCurrentTokenOwnership();
    }
  }
}

class AppAuthService {
  AppAuthService._();

  static final AppAuthService instance = AppAuthService._();

  String get _base =>
      '${AppConfig.apiBaseUrl}/api/v1/apps/${AppConfig.appSlug}/auth';

  Map<String, String> _headers({
    bool authenticated = false,
    String? bearerToken,
  }) =>
      {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-APP-TOKEN': AppConfig.appToken,
        if ((bearerToken ?? '').trim().isNotEmpty)
          'Authorization': 'Bearer ${bearerToken!.trim()}'
        else if (authenticated && AppAuthState.instance.token != null)
          'Authorization': 'Bearer ${AppAuthState.instance.token}',
      };

  Future<AppUser> fetchCurrentUser(String token) async {
    final response = await http.get(
      Uri.parse('$_base/me'),
      headers: _headers(bearerToken: token),
    );
    final payload = _decode(response);
    return AppUser.fromJson(payload['user'] as Map<String, dynamic>);
  }

  Future<AppUser> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_base/login'),
      headers: _headers(),
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );
    final payload = _decode(response);
    final user = AppUser.fromJson(payload['user'] as Map<String, dynamic>);
    await AppAuthState.instance.setSession(payload['token'].toString(), user);
    return user;
  }

  Future<AppUser> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$_base/register'),
      headers: _headers(),
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      }),
    );
    final payload = _decode(response);
    final user = AppUser.fromJson(payload['user'] as Map<String, dynamic>);
    await AppAuthState.instance.setSession(payload['token'].toString(), user);
    return user;
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$_base/logout'),
        headers: _headers(authenticated: true),
      );
    } finally {
      await AppAuthState.instance.clear();
    }
  }

  Future<void> deleteAccount(String password) async {
    final request = http.Request('DELETE', Uri.parse('$_base/account'))
      ..headers.addAll(_headers(authenticated: true))
      ..body = jsonEncode({'password': password, 'confirmation': true});
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _decode(response);
    await AppAuthState.instance.clear();
  }

  String publicDeletionUrl() =>
      '${AppConfig.apiBaseUrl}/account-deletion/${AppConfig.appSlug}';

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> payload = {};
    try {
      payload = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errors = payload['errors'];
      String message = (payload['message'] ?? 'Request failed.').toString();
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) message = first.first.toString();
      }
      throw AppAuthException(message, response.statusCode);
    }

    return payload;
  }
}

class AppAuthException implements Exception {
  final String message;
  final int statusCode;
  const AppAuthException(this.message, this.statusCode);

  @override
  String toString() => message;
}
