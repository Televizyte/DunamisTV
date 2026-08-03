import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'brands/brand_selector.dart';
import 'features/hub/state/hub_scope.dart';
import 'features/hub/state/hub_store.dart';
import 'routing/app_router.dart';
import 'services/notification_bootstrap_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'ui/screens/notifications/notification_message_card.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  BrandSelector.applyFromEnvironment();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const _DxmStartupGate());
}

class _DxmStartupGate extends StatefulWidget {
  const _DxmStartupGate();

  @override
  State<_DxmStartupGate> createState() => _DxmStartupGateState();
}

class _DxmStartupGateState extends State<_DxmStartupGate> {
  final HubStore _store = HubStore();

  double _progress = 0.08;
  String _status = 'Preparing Dunamis TV…';
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _advance(0.18, 'Loading app settings…');

    try {
      await _store.init().timeout(const Duration(seconds: 18));
    } catch (_) {
      // HubStore already contains its own cached/default fallback behavior.
      // Startup must continue even when the network is temporarily unavailable.
    }

    if (!mounted) return;
    await _advance(0.62, 'Loading Dunamis TV content…');

    try {
      await ThemeController.instance.init();
    } catch (_) {}

    if (!mounted) return;
    await _advance(0.84, 'Preparing notifications…');

    setState(() {
      _progress = 1;
      _status = 'Opening Dunamis TV…';
    });

    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;

    setState(() => _ready = true);
    unawaited(NotificationBootstrapService.instance.init());
  }

  Future<void> _advance(double progress, String status) async {
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _status = status;
    });
    await Future<void>.delayed(const Duration(milliseconds: 220));
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return DxmHubApp(store: _store);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _BrandedStartupScreen(
        progress: _progress,
        status: _status,
      ),
    );
  }
}

class _BrandedStartupScreen extends StatelessWidget {
  final double progress;
  final String status;

  const _BrandedStartupScreen({
    required this.progress,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3C9EC),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/branding/splash/dunamis_splash_1080x1920.webp',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
          Positioned(
            left: 28,
            right: 28,
            bottom: MediaQuery.of(context).padding.bottom + 26,
            child: Semantics(
              label: status,
              value: '${(progress * 100).round()} percent',
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 13),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 7,
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF0A8A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DxmHubApp extends StatelessWidget {
  final HubStore store;

  const DxmHubApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return HubScope(
      store: store,
      child: AnimatedBuilder(
        animation: ThemeController.instance,
        builder: (context, _) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeController.instance.themeMode,
            routerConfig: AppRouter.router,
            builder: (context, child) {
              return DxmNotificationOverlayHost(
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
