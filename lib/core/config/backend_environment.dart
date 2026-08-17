import 'package:flutter/foundation.dart';

enum DxmBackendEnvironment { production, local, staging }

class BackendEndpointResolution {
  final DxmBackendEnvironment environment;
  final String apiBaseUrl;

  const BackendEndpointResolution({
    required this.environment,
    required this.apiBaseUrl,
  });

  bool get isProduction => environment == DxmBackendEnvironment.production;

  String get environmentLabel => switch (environment) {
        DxmBackendEnvironment.production => 'Production',
        DxmBackendEnvironment.local => 'Local',
        DxmBackendEnvironment.staging => 'Staging',
      };

  Uri get uri => Uri.parse(apiBaseUrl);

  String sanitizedStartupDescription(String appSlug) {
    final endpoint = uri;
    final port = endpoint.hasPort ? ' port=${endpoint.port}' : '';
    return 'DXM backend: environment=${environment.name} '
        'host=${endpoint.host}$port app=$appSlug';
  }
}

class BackendEnvironmentResolver {
  const BackendEnvironmentResolver._();

  static const productionApiBaseUrl =
      'https://admin.appshub.digitxtramedia.com';

  static BackendEndpointResolution resolve({
    required bool isDebug,
    String environment = '',
    String localApiBaseUrl = '',
    String stagingApiBaseUrl = '',
  }) {
    if (!isDebug) return production;

    switch (environment.trim().toLowerCase()) {
      case 'local':
        return _debugResolution(
              DxmBackendEnvironment.local,
              localApiBaseUrl,
            ) ??
            production;
      case 'staging':
        return _debugResolution(
              DxmBackendEnvironment.staging,
              stagingApiBaseUrl,
            ) ??
            production;
      case '':
      case 'production':
      default:
        return production;
    }
  }

  static const production = BackendEndpointResolution(
    environment: DxmBackendEnvironment.production,
    apiBaseUrl: productionApiBaseUrl,
  );

  static BackendEndpointResolution? _debugResolution(
    DxmBackendEnvironment environment,
    String candidate,
  ) {
    final normalized = _normalizeBaseUrl(candidate);
    if (normalized == null) return null;
    return BackendEndpointResolution(
      environment: environment,
      apiBaseUrl: normalized,
    );
  }

  static String? _normalizeBaseUrl(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return null;

    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.isAbsolute || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) return null;

    var path = uri.path;
    while (path.endsWith('/') && path.isNotEmpty) {
      path = path.substring(0, path.length - 1);
    }

    return uri.replace(path: path).toString();
  }
}

class BackendEnvironment {
  const BackendEnvironment._();

  static const _environment = String.fromEnvironment(
    'DXM_BACKEND_ENV',
    defaultValue: 'production',
  );
  static const _localApiBaseUrl = String.fromEnvironment(
    'DXM_DEBUG_API_BASE_URL',
  );
  static const _stagingApiBaseUrl = String.fromEnvironment(
    'DXM_STAGING_API_BASE_URL',
  );

  static BackendEndpointResolution get active =>
      BackendEnvironmentResolver.resolve(
        isDebug: kDebugMode,
        environment: _environment,
        localApiBaseUrl: _localApiBaseUrl,
        stagingApiBaseUrl: _stagingApiBaseUrl,
      );

  static void logSanitizedStartup(String appSlug) {
    if (!kDebugMode) return;
    debugPrint(active.sanitizedStartupDescription(appSlug));
  }

  // Chrome:
  // flutter run -d chrome --dart-define=DXM_BACKEND_ENV=local
  //   --dart-define=DXM_DEBUG_API_BASE_URL=http://192.168.1.25:8000
  // Android LAN device:
  // flutter run -d <device-id> --dart-define=DXM_BACKEND_ENV=local
  //   --dart-define=DXM_DEBUG_API_BASE_URL=http://192.168.1.25:8000
  // The phone and AppsHub computer must share a LAN, AppsHub must listen on
  // 0.0.0.0, and the selected port must be permitted by Windows Firewall.
  // USB adb reverse is an optional fallback, not a permanent requirement.
}

class BackendDiagnosticsPolicy {
  const BackendDiagnosticsPolicy._();

  static bool isAvailable({required bool isDebug}) => isDebug;
}
