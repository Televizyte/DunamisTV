import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_config.dart';
import '../../core/config/backend_environment.dart';
import '../../features/hub/state/hub_store.dart';
import '../../routing/app_router.dart';

class BackendDiagnosticsOverlay extends StatelessWidget {
  final HubStore store;
  final Widget child;

  const BackendDiagnosticsOverlay({
    super.key,
    required this.store,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!BackendDiagnosticsPolicy.isAvailable(isDebug: kDebugMode)) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          right: 8,
          top: MediaQuery.paddingOf(context).top + 8,
          child: Builder(
            builder: (navigatorContext) => Material(
              color: Colors.transparent,
              child: IconButton.filledTonal(
                onPressed: () => _showDiagnostics(navigatorContext),
                icon: const Icon(Icons.dns_rounded),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDiagnostics(BuildContext context) async {
    final navigator = AppRouter.rootNavigatorKey.currentState;

    if (navigator == null) {
      debugPrint(
        '[BackendDiagnostics] Root Navigator is not ready.',
      );
      return;
    }

    await showDialog<void>(
      context: navigator.context,
      useRootNavigator: true,
      builder: (dialogContext) => _BackendDiagnosticsDialog(store: store),
    );
  }
}

class _BackendDiagnosticsDialog extends StatefulWidget {
  final HubStore store;

  const _BackendDiagnosticsDialog({required this.store});

  @override
  State<_BackendDiagnosticsDialog> createState() =>
      _BackendDiagnosticsDialogState();
}

class _BackendDiagnosticsDialogState extends State<_BackendDiagnosticsDialog> {
  late Future<bool> _cacheExists;

  @override
  void initState() {
    super.initState();
    _cacheExists = widget.store.hasCachedBackendData();
  }

  void _refreshCacheStatus() {
    setState(() => _cacheExists = widget.store.hasCachedBackendData());
  }

  @override
  Widget build(BuildContext context) {
    final endpoint = BackendEnvironment.active;
    final lastRefresh =
        widget.store.lastSuccessfulRefresh?.toLocal().toString() ?? 'Never';

    return AlertDialog(
      title: const Text('Backend diagnostics'),
      content: SingleChildScrollView(
        child: SelectionArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line('Environment', endpoint.environmentLabel),
              _line('API base URL', endpoint.apiBaseUrl),
              _line('App slug', AppConfig.appSlug),
              _line('Cache key', widget.store.backendCacheKey),
              FutureBuilder<bool>(
                future: _cacheExists,
                builder: (context, snapshot) => _line(
                  'Cached bootstrap',
                  snapshot.data == true ? 'Yes' : 'No',
                ),
              ),
              _line('Last successful refresh', lastRefresh),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await widget.store.clearCurrentBackendCache();
            if (mounted) _refreshCacheStatus();
          },
          child: const Text('Clear cache'),
        ),
        TextButton(
          onPressed: () async {
            await widget.store.debugReloadBootstrap();
            if (mounted) _refreshCacheStatus();
          },
          child: const Text('Reload Bootstrap'),
        ),
        TextButton(
          onPressed: () async {
            await widget.store.refresh();
            if (mounted) _refreshCacheStatus();
          },
          child: const Text('Reload Hub'),
        ),
        TextButton(
          onPressed: () async {
            final description = [
              'Environment: ${endpoint.environmentLabel}',
              'API base URL: ${endpoint.apiBaseUrl}',
              'App slug: ${AppConfig.appSlug}',
              'Cache key: ${widget.store.backendCacheKey}',
            ].join('\n');
            await Clipboard.setData(ClipboardData(text: description));
          },
          child: const Text('Copy'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label: $value'),
    );
  }
}
