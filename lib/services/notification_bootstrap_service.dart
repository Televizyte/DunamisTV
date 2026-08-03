import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../app_config.dart';
import '../routing/app_router.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  await NotificationBootstrapService.storeMessageSnapshot(
    message,
    storageKey: NotificationBootstrapService.backgroundMessagesKey,
  );
}

class NotificationBootstrapService {
  NotificationBootstrapService._();

  static final NotificationBootstrapService instance =
      NotificationBootstrapService._();

  static const String tokenKey = 'dxm_fcm_token';
  static const String tokenSyncedKey = 'dxm_fcm_token_synced';
  static const String tokenSyncStatusKey = 'dxm_fcm_token_sync_status';
  static const String tokenSyncErrorKey = 'dxm_fcm_token_sync_error';
  static const String tokenLastSyncAtKey = 'dxm_fcm_token_last_sync_at';

  static const String foregroundMessagesKey = 'dxm_foreground_notifications';
  static const String backgroundMessagesKey = 'dxm_background_notifications';
  static const String openedMessagesKey = 'dxm_opened_notifications';

  bool _initialized = false;
  bool _initializing = false;
  String? _token;

  final ValueNotifier<Map<String, dynamic>?> overlayMessage =
      ValueNotifier(null);

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<String>? _tokenRefreshSub;

  bool get isInitialized => _initialized;
  String? get token => _token;

  static void _openNotificationInbox() {
    _openNotificationTarget(null);
  }

  static void _openNotificationTarget(Map<String, dynamic>? snapshot) {
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      try {
        final route = _routeForNotificationSnapshot(snapshot);
        final extra = _extraForNotificationSnapshot(snapshot);

        if (extra.isEmpty) {
          AppRouter.router.go(route);
        } else {
          AppRouter.router.go(route, extra: extra);
        }
      } catch (error) {
        _log('notification route open failed: $error');
        try {
          AppRouter.router.go('/notifications?open=latest');
        } catch (_) {}
      }
    });
  }

  void publishOverlayMessage(Map<String, dynamic>? message) {
    if (message == null) return;
    overlayMessage.value = Map<String, dynamic>.from(message);
  }

  void hideOverlay() {
    overlayMessage.value = null;
  }

  Future<void> showLatestStoredOverlay() async {
    final messages = await readStoredMessages();
    if (messages.isNotEmpty) {
      publishOverlayMessage(messages.first);
    }
  }

  Future<void> init() async {
    if (_initialized || _initializing) return;

    _initializing = true;

    if (kIsWeb) {
      await _saveSyncStatus(
        synced: false,
        status: 'web_skipped',
        error: 'Firebase Messaging token sync is skipped on web.',
      );
      _initialized = true;
      _initializing = false;
      return;
    }

    try {
      _log('init started');

      await Firebase.initializeApp().timeout(const Duration(seconds: 20));
      _log('firebase initialized');

      final messaging = FirebaseMessaging.instance;

      await messaging.setAutoInitEnabled(true);

      final settings = await messaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          )
          .timeout(const Duration(seconds: 20));

      _log('permission status: ${settings.authorizationStatus}');

      // Keep Firebase registration traffic away from the Home priority fetch.
      // Notification setup remains automatic, but network sync starts only
      // after the initial content-loading window has passed.
      _log('deferring token sync for 45 seconds to protect Home startup');
      await Future<void>.delayed(const Duration(seconds: 45));

      await _fetchAndSyncTokenWithRetry(messaging);
      await _subscribeToReleaseTopics(messaging);

      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) async {
        _log('token refreshed len=${newToken.length}');
        _token = newToken;
        await _saveToken(newToken);
        await _syncTokenToBackend(newToken);
      });

      _foregroundSub?.cancel();
      _foregroundSub = FirebaseMessaging.onMessage.listen((message) async {
        _log('foreground message received: ${message.messageId ?? 'no-id'}');
        final snapshot = await storeMessageSnapshot(
          message,
          storageKey: foregroundMessagesKey,
        );
        publishOverlayMessage(snapshot);
      });

      _openedSub?.cancel();
      _openedSub = FirebaseMessaging.onMessageOpenedApp.listen((message) async {
        _log('opened message received: ${message.messageId ?? 'no-id'}');
        final snapshot = await storeMessageSnapshot(
          message,
          storageKey: openedMessagesKey,
        );
        hideOverlay();
        _openNotificationTarget(snapshot);
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _log('initial message found: ${initialMessage.messageId ?? 'no-id'}');
        final snapshot = await storeMessageSnapshot(
          initialMessage,
          storageKey: openedMessagesKey,
        );
        hideOverlay();
        _openNotificationTarget(snapshot);
      }

      _initialized = true;
      _log('init completed');
    } catch (error) {
      _log('init failed: $error');
      await _saveSyncStatus(
        synced: false,
        status: 'init_failed',
        error: error.toString(),
      );
      _initialized = false;
    } finally {
      _initializing = false;
    }
  }

  Future<void> _fetchAndSyncTokenWithRetry(
    FirebaseMessaging messaging,
  ) async {
    Object? lastError;

    for (var attempt = 1; attempt <= 4; attempt++) {
      try {
        _log('getToken attempt $attempt/4');

        final token = await messaging.getToken().timeout(
              const Duration(seconds: 30),
            );

        if (token == null || token.trim().isEmpty) {
          _log('getToken attempt $attempt returned empty token');
          lastError = 'FirebaseMessaging.getToken() returned empty token';
        } else {
          final cleanToken = token.trim();
          _log(
            'getToken success len=${cleanToken.length} prefix=${_prefix(cleanToken)}',
          );

          _token = cleanToken;
          await _saveToken(cleanToken);
          await _syncTokenToBackend(cleanToken);
          return;
        }
      } catch (error) {
        lastError = error;
        _log('getToken attempt $attempt failed: $error');
      }

      await Future<void>.delayed(Duration(seconds: attempt * 3));
    }

    await _saveSyncStatus(
      synced: false,
      status: 'token_empty_or_failed',
      error: lastError?.toString() ?? 'Unknown token failure',
    );
  }

  Future<void> _subscribeToReleaseTopics(FirebaseMessaging messaging) async {
    final topics = <String>{
      'app-${AppConfig.appSlug}',
      AppConfig.appSlug.replaceAll('-', '_'),
      '${AppConfig.appSlug.replaceAll('-', '_')}_android',
    };

    for (final topic in topics) {
      final cleanTopic = topic.trim();
      if (cleanTopic.isEmpty) continue;

      try {
        await messaging.subscribeToTopic(cleanTopic).timeout(
              const Duration(seconds: 15),
            );
        _log('subscribed topic: $cleanTopic');
      } catch (error) {
        _log('topic subscribe failed [$cleanTopic]: $error');
      }
    }
  }

  Future<void> _saveToken(String? token) async {
    if (token == null || token.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenKey, token.trim());
      _log('token saved locally len=${token.trim().length}');
    } catch (error) {
      _log('token local save failed: $error');
    }
  }

  Future<void> _syncTokenToBackend(
    String? token, {
    String? bearerToken,
  }) async {
    final cleanToken = token?.trim() ?? '';
    if (cleanToken.isEmpty) {
      await _saveSyncStatus(
        synced: false,
        status: 'empty_token',
        error: 'Token is empty, backend sync skipped.',
      );
      return;
    }

    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/apps/${AppConfig.appSlug}/push/device-token',
    );

    final platform = kIsWeb
        ? 'web'
        : Platform.isAndroid
            ? 'android'
            : Platform.isIOS
                ? 'ios'
                : Platform.operatingSystem;

    Object? lastError;

    for (var attempt = 1; attempt <= 4; attempt++) {
      try {
        _log(
          'backend sync attempt $attempt/4 url=$url tokenLen=${cleanToken.length}',
        );

        final response = await http
            .post(
              url,
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'X-APP-TOKEN': AppConfig.appToken,
                if ((bearerToken ?? '').trim().isNotEmpty)
                  'Authorization': 'Bearer ${bearerToken!.trim()}',
              },
              body: jsonEncode({
                'token': cleanToken,
                'platform': platform,
                'is_active': true,
                'meta': {
                  'app_name': AppConfig.appName,
                  'app_slug': AppConfig.appSlug,
                  'source': 'flutter_notification_bootstrap_service',
                  'token_length': cleanToken.length,
                  'token_prefix': _prefix(cleanToken),
                  'synced_at': DateTime.now().toIso8601String(),
                },
              }),
            )
            .timeout(const Duration(seconds: 30));

        _log(
          'backend sync response ${response.statusCode}: ${_safeBody(response.body)}',
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          await _saveSyncStatus(
            synced: true,
            status: 'synced',
            error: '',
          );
          return;
        }

        lastError = 'HTTP ${response.statusCode}: ${_safeBody(response.body)}';
      } catch (error) {
        lastError = error;
        _log('backend sync attempt $attempt failed: $error');
      }

      await Future<void>.delayed(Duration(seconds: attempt * 3));
    }

    await _saveSyncStatus(
      synced: false,
      status: 'sync_failed',
      error: lastError?.toString() ?? 'Unknown backend sync failure',
    );
  }

  Future<void> syncCurrentTokenOwnership({String? bearerToken}) async {
    final savedToken = _token ?? await getSavedToken();
    if (savedToken == null || savedToken.trim().isEmpty) return;

    await _syncTokenToBackend(
      savedToken,
      bearerToken: bearerToken,
    );
  }

  Future<void> retryTokenSync() async {
    _log('manual retry requested');

    if (!_initialized && !_initializing) {
      await init();
      return;
    }

    final savedToken = _token ?? await getSavedToken();

    if (savedToken == null || savedToken.trim().isEmpty) {
      try {
        final messaging = FirebaseMessaging.instance;
        await _fetchAndSyncTokenWithRetry(messaging);
      } catch (error) {
        await _saveSyncStatus(
          synced: false,
          status: 'manual_retry_failed',
          error: error.toString(),
        );
      }
      return;
    }

    await _syncTokenToBackend(savedToken);
  }

  Future<void> _saveSyncStatus({
    required bool synced,
    required String status,
    required String error,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(tokenSyncedKey, synced);
      await prefs.setString(tokenSyncStatusKey, status);
      await prefs.setString(tokenSyncErrorKey, error);
      await prefs.setString(
        tokenLastSyncAtKey,
        DateTime.now().toIso8601String(),
      );
      _log('status saved synced=$synced status=$status error=$error');
    } catch (saveError) {
      _log('status save failed: $saveError');
    }
  }

  Future<String?> getSavedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getTokenSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'synced': prefs.getBool(tokenSyncedKey) ?? false,
        'status': prefs.getString(tokenSyncStatusKey) ?? '',
        'error': prefs.getString(tokenSyncErrorKey) ?? '',
        'last_sync_at': prefs.getString(tokenLastSyncAtKey) ?? '',
      };
    } catch (_) {
      return {
        'synced': false,
        'status': '',
        'error': '',
        'last_sync_at': '',
      };
    }
  }

  static Future<Map<String, dynamic>?> storeMessageSnapshot(
    RemoteMessage message, {
    required String storageKey,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(storageKey) ?? <String>[];

      final data = message.data;
      final now = DateTime.now();
      final sentTime = message.sentTime;
      final safeSentTime =
          sentTime == null || sentTime.year <= 1971 ? now : sentTime;

      final snapshot = <String, dynamic>{
        'id': _firstNonEmpty([
          data['notification_id'],
          data['push_id'],
          data['id'],
          message.messageId,
          now.microsecondsSinceEpoch.toString(),
        ]),
        'title': _firstNonEmpty([
          message.notification?.title,
          data['title'],
          data['notification_title'],
          'Notification',
        ]),
        'body': _firstNonEmpty([
          message.notification?.body,
          data['body'],
          data['message'],
          data['notification_body'],
        ]),
        'image_url': _firstNonEmpty([
          data['image_url'],
          data['image'],
          data['banner_url'],
          data['card_image_url'],
        ]),
        'app_logo_url': _firstNonEmpty([
          data['app_logo_url'],
          data['logo_url'],
          data['app_logo'],
          data['app_icon_url'],
          data['icon_url'],
        ]),
        'logo_url': _firstNonEmpty([
          data['logo_url'],
          data['app_logo_url'],
          data['app_logo'],
          data['app_icon_url'],
          data['icon_url'],
        ]),
        'action_type': _firstNonEmpty([
          data['action_type'],
          data['action_target'],
          _looksExternal(
                  _firstNonEmpty([data['external_url'], data['action_url']]))
              ? 'external'
              : 'internal',
        ]),
        'external_url': _firstNonEmpty([
          data['external_url'],
          _looksExternal(data['action_url']) ? data['action_url'] : '',
          _looksExternal(data['url']) ? data['url'] : '',
        ]),
        'action_url': _firstNonEmpty([
          data['action_url'],
          data['external_url'],
          data['deep_link_url'],
          data['deep_link'],
          data['route'],
          data['url'],
        ]),
        'action_target': _firstNonEmpty([
          data['action_target'],
          data['action_type'],
        ]),
        'deep_link_url': _firstNonEmpty([
          data['deep_link_url'],
          data['deep_link'],
          data['route'],
          !_looksExternal(data['action_url']) ? data['action_url'] : '',
          !_looksExternal(data['url']) ? data['url'] : '',
        ]),
        'action_label': _firstNonEmpty([data['action_label'], 'Open']),
        'app_name': _firstNonEmpty([data['app_name'], AppConfig.appName]),
        'sent_time': safeSentTime.toIso8601String(),
        'data': data,
      };

      final encoded = jsonEncode(snapshot);
      final notificationId = snapshot['id'].toString();
      final deduped = <String>[];

      for (final raw in existing) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map &&
              (decoded['id'] ?? '').toString() == notificationId) {
            continue;
          }
        } catch (_) {}
        deduped.add(raw);
      }

      final updated = <String>[encoded, ...deduped];

      if (updated.length > 60) {
        updated.removeRange(60, updated.length);
      }

      await prefs.setStringList(storageKey, updated);
      return snapshot;
    } catch (_) {
      return null;
    }
  }

  static bool _looksExternal(dynamic value) {
    final text = (value ?? '').toString().trim().toLowerCase();
    return text.startsWith('http://') ||
        text.startsWith('https://') ||
        text.startsWith('market://') ||
        text.startsWith('intent://');
  }

  static Map<String, dynamic> _extraForNotificationSnapshot(
    Map<String, dynamic>? snapshot,
  ) {
    if (snapshot == null || snapshot.isEmpty) {
      return const <String, dynamic>{};
    }

    final data = _stringMap(snapshot['data']);

    return <String, dynamic>{
      ...data,
      'notification_item': snapshot,
      'notification_id':
          _firstNonEmpty([snapshot['id'], data['notification_id']]),
      'title': _firstNonEmpty([snapshot['title'], data['title']]),
      'body': _firstNonEmpty([snapshot['body'], data['body']]),
      'bucket': _firstNonEmpty([
        snapshot['bucket'],
        data['bucket'],
        data['content_bucket'],
        data['channel'],
        data['category'],
      ]),
      'id': _firstNonEmpty([
        snapshot['id'],
        data['quote_id'],
        data['post_id'],
        data['content_id'],
        data['id'],
      ]),
      'content_id': _firstNonEmpty([
        data['content_id'],
        data['quote_id'],
        data['post_id'],
        data['id'],
      ]),
      'source': 'push_notification',
    };
  }

  static String _routeForNotificationSnapshot(Map<String, dynamic>? snapshot) {
    if (snapshot == null || snapshot.isEmpty) {
      return '/notifications?open=latest';
    }

    final data = _stringMap(snapshot['data']);
    final deepLink = _firstNonEmpty([
      snapshot['deep_link_url'],
      data['deep_link_url'],
      data['deep_link'],
      data['route'],
      !_looksExternal(data['action_url']) ? data['action_url'] : '',
      !_looksExternal(data['url']) ? data['url'] : '',
    ]);

    if (_isInternalRoute(deepLink)) {
      return deepLink;
    }

    final externalUrl = _firstNonEmpty([
      snapshot['external_url'],
      data['external_url'],
      _looksExternal(data['action_url']) ? data['action_url'] : '',
      _looksExternal(data['url']) ? data['url'] : '',
    ]);

    if (externalUrl.isNotEmpty) {
      return '/web';
    }

    final bucket = _normalizeKey(_firstNonEmpty([
      snapshot['bucket'],
      data['bucket'],
      data['content_bucket'],
      data['channel'],
      data['category'],
    ]));

    final type = _normalizeKey(_firstNonEmpty([
      snapshot['type'],
      snapshot['action_type'],
      data['type'],
      data['content_type'],
      data['action_type'],
    ]));

    final id = Uri.encodeComponent(_firstNonEmpty([
      data['quote_id'],
      data['post_id'],
      data['content_id'],
      data['id'],
      snapshot['id'],
    ]));
    final bucketQuery = bucket.isEmpty ? '' : '&bucket=$bucket&channel=$bucket';
    final idQuery = id.isEmpty ? '' : '?id=$id&quote_id=$id&post_id=$id';

    if (bucket == 'sod_quotes') {
      return '/sod/quotes${idQuery.isEmpty ? '?bucket=sod_quotes' : '$idQuery$bucketQuery'}';
    }

    if (bucket == 'motivation_quotes' ||
        bucket == 'motivational_quotes' ||
        bucket == 'motivation') {
      return '/motivation${idQuery.isEmpty ? '?bucket=motivation_quotes' : '$idQuery$bucketQuery'}';
    }

    if (bucket == 'daily_scriptures' || bucket == 'daily_scripture') {
      return '/daily-scripture${idQuery.isEmpty ? '?bucket=daily_scriptures' : '$idQuery$bucketQuery'}';
    }

    if (bucket == 'daily_quotes' || bucket == 'daily_quote') {
      return '/${idQuery.isEmpty ? '?open=daily_quote&bucket=daily_quotes' : '$idQuery$bucketQuery&open=daily_quote'}';
    }

    if (bucket.startsWith('quote_')) {
      return '/highlights${idQuery.isEmpty ? '?bucket=$bucket' : '$idQuery$bucketQuery'}';
    }

    if (type == 'quote_card' || type == 'quote' || type.contains('quote')) {
      return '/tools/quote/library${bucket.isEmpty ? '' : '?bucket=$bucket'}';
    }

    return '/notifications?open=latest';
  }

  static bool _isInternalRoute(dynamic value) {
    final text = (value ?? '').toString().trim();
    return text.startsWith('/') && !text.startsWith('//');
  }

  static String _normalizeKey(dynamic value) {
    return (value ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  static Map<String, dynamic> _stringMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }

    return const <String, dynamic>{};
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  Future<List<Map<String, dynamic>>> readStoredMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final all = <String>[
        ...?prefs.getStringList(openedMessagesKey),
        ...?prefs.getStringList(foregroundMessagesKey),
        ...?prefs.getStringList(backgroundMessagesKey),
      ];

      final parsed = <Map<String, dynamic>>[];
      final seen = <String>{};

      for (final raw in all) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            final map = decoded.cast<String, dynamic>();
            final id = (map['id'] ??
                    '${map['title']}|${map['body']}|${map['sent_time']}')
                .toString();
            if (seen.add(id)) {
              parsed.add(map);
            }
          }
        } catch (_) {}
      }

      parsed.sort((a, b) {
        final ad = DateTime.tryParse((a['sent_time'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bd = DateTime.tryParse((b['sent_time'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

      return parsed;
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> clearStoredMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(openedMessagesKey);
      await prefs.remove(foregroundMessagesKey);
      await prefs.remove(backgroundMessagesKey);
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    await _tokenRefreshSub?.cancel();
    _foregroundSub = null;
    _openedSub = null;
    _tokenRefreshSub = null;
  }

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[PushBootstrap] $message');
    }
  }

  static String _prefix(String token) {
    if (token.length <= 18) return token;
    return token.substring(0, 18);
  }

  static String _safeBody(String body) {
    final trimmed = body.trim();
    if (trimmed.length <= 300) return trimmed;
    return '${trimmed.substring(0, 300)}...';
  }
}
