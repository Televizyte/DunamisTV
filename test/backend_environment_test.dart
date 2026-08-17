import 'package:dunamis_tv/app_config.dart';
import 'package:dunamis_tv/core/config/backend_environment.dart';
import 'package:dunamis_tv/core/config/backend_response_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const productionUrl = 'https://admin.appshub.digitxtramedia.com';

  group('BackendEnvironmentResolver', () {
    test('production is the default and remains unchanged', () {
      final endpoint = BackendEnvironmentResolver.resolve(isDebug: true);

      expect(endpoint.environment, DxmBackendEnvironment.production);
      expect(endpoint.apiBaseUrl, productionUrl);
      expect(BackendEnvironmentResolver.productionApiBaseUrl, productionUrl);
      expect(AppConfig.apiBaseUrl, productionUrl);
      expect(AppConfig.appSlug, 'dunamis-tv');
    });

    test('unknown environment falls back to production', () {
      final endpoint = BackendEnvironmentResolver.resolve(
        isDebug: true,
        environment: 'preview',
        localApiBaseUrl: 'http://192.168.1.25:8000',
      );

      expect(endpoint, same(BackendEnvironmentResolver.production));
    });

    test('local and staging are permitted only in debug resolution', () {
      final local = BackendEnvironmentResolver.resolve(
        isDebug: true,
        environment: 'local',
        localApiBaseUrl: 'http://192.168.1.25:8000',
      );
      final staging = BackendEnvironmentResolver.resolve(
        isDebug: true,
        environment: 'staging',
        stagingApiBaseUrl: 'https://staging.example.com',
      );

      expect(local.environment, DxmBackendEnvironment.local);
      expect(local.apiBaseUrl, 'http://192.168.1.25:8000');
      expect(staging.environment, DxmBackendEnvironment.staging);

      for (final environment in const ['local', 'staging']) {
        final blocked = BackendEnvironmentResolver.resolve(
          isDebug: false,
          environment: environment,
          localApiBaseUrl: 'http://192.168.1.25:8000',
          stagingApiBaseUrl: 'https://staging.example.com',
        );
        expect(blocked.environment, DxmBackendEnvironment.production);
        expect(blocked.apiBaseUrl, productionUrl);
      }
    });

    test('blank, invalid-scheme and credential-bearing URLs are rejected', () {
      for (final value in const [
        '',
        'ftp://192.168.1.25:8000',
        'http://user:password@192.168.1.25:8000',
        'http://192.168.1.25:8000?token=secret',
      ]) {
        final endpoint = BackendEnvironmentResolver.resolve(
          isDebug: true,
          environment: 'local',
          localApiBaseUrl: value,
        );
        expect(endpoint.environment, DxmBackendEnvironment.production);
      }
    });

    test('trailing slashes are normalized', () {
      final endpoint = BackendEnvironmentResolver.resolve(
        isDebug: true,
        environment: 'local',
        localApiBaseUrl: 'http://192.168.1.25:8000///',
      );

      expect(endpoint.apiBaseUrl, 'http://192.168.1.25:8000');
    });

    test('sanitized description excludes credentials, query and paths', () {
      final endpoint = BackendEnvironmentResolver.resolve(
        isDebug: true,
        environment: 'local',
        localApiBaseUrl: 'http://192.168.1.25:8000',
      );
      final description = endpoint.sanitizedStartupDescription('dunamis-tv');

      expect(description, contains('host=192.168.1.25'));
      expect(description, contains('port=8000'));
      expect(description, isNot(contains('?')));
      expect(description, isNot(contains('@')));
      expect(description, isNot(contains('/api/')));
    });

    test('diagnostics availability follows debug mode only', () {
      expect(BackendDiagnosticsPolicy.isAvailable(isDebug: true), isTrue);
      expect(BackendDiagnosticsPolicy.isAvailable(isDebug: false), isFalse);
    });
  });

  group('BackendResponseCache', () {
    const production = BackendEnvironmentResolver.production;
    final local = BackendEnvironmentResolver.resolve(
      isDebug: true,
      environment: 'local',
      localApiBaseUrl: 'http://192.168.1.25:8000',
    );
    final staging = BackendEnvironmentResolver.resolve(
      isDebug: true,
      environment: 'staging',
      stagingApiBaseUrl: 'https://staging.example.com',
    );

    test('cache keys differ by production, local and staging identity', () {
      final keys = {production, local, staging}
          .map(
            (endpoint) => BackendCacheIdentity.key(
              appSlug: 'dunamis-tv',
              endpoint: endpoint,
            ),
          )
          .toSet();

      expect(keys, hasLength(3));
      for (final key in keys) {
        expect(key, startsWith('dxm.hub.bootstrap.cache.v3.dunamis-tv.'));
        expect(key, isNot(contains('http')));
      }
    });

    test('local never reads the legacy production cache', () async {
      SharedPreferences.setMockInitialValues({
        BackendCacheIdentity.legacyProductionKey: '{"production":true}',
      });
      final preferences = await SharedPreferences.getInstance();
      final cache = BackendResponseCache(
        preferences: preferences,
        appSlug: 'dunamis-tv',
        endpoint: local,
      );

      expect(await cache.load(), isNull);
      expect(
        preferences.getString(BackendCacheIdentity.legacyProductionKey),
        '{"production":true}',
      );
    });

    test('production migrates v2 once without erasing unrelated data',
        () async {
      SharedPreferences.setMockInitialValues({
        BackendCacheIdentity.legacyProductionKey: '{"production":true}',
        'quote_designs_v2': <String>['saved-user-quote'],
        'unrelated_preference': 'preserve-me',
      });
      final preferences = await SharedPreferences.getInstance();
      final cache = BackendResponseCache(
        preferences: preferences,
        appSlug: 'dunamis-tv',
        endpoint: production,
      );

      expect(await cache.load(), '{"production":true}');
      expect(cache.exists, isTrue);
      expect(
        preferences.containsKey(BackendCacheIdentity.legacyProductionKey),
        isFalse,
      );
      expect(
        preferences.getStringList('quote_designs_v2'),
        <String>['saved-user-quote'],
      );
      expect(
        preferences.getString('unrelated_preference'),
        'preserve-me',
      );
    });
  });
}
