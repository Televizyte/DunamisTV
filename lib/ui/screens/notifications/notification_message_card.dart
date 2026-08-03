import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_config.dart';
import '../../../services/notification_bootstrap_service.dart';

class DxmNotificationOverlayHost extends StatelessWidget {
  final Widget child;

  const DxmNotificationOverlayHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ValueListenableBuilder<Map<String, dynamic>?>(
          valueListenable: NotificationBootstrapService.instance.overlayMessage,
          builder: (context, item, _) {
            if (item == null) return const SizedBox.shrink();

            final media = MediaQuery.maybeOf(context);
            final top = (media?.padding.top ?? 0) + 10;

            return Positioned(
              top: top,
              left: 12,
              right: 12,
              child: SafeArea(
                bottom: false,
                child: Material(
                  color: Colors.transparent,
                  child: _FloatingNotificationCard(
                    item: item,
                    compact: true,
                    onClose: () =>
                        NotificationBootstrapService.instance.hideOverlay(),
                    onOpen: () async {
                      NotificationBootstrapService.instance.hideOverlay();
                      await NotificationActionHelper.openTarget(context, item);
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

String? _activeNotificationDialogId;

Future<void> showNotificationMessageDialog(
  BuildContext context,
  Map<String, dynamic> item,
) async {
  final dialogId = NotificationActionHelper.notificationId(item);
  if (dialogId.isNotEmpty && _activeNotificationDialogId == dialogId) {
    return;
  }
  _activeNotificationDialogId = dialogId;
  final hostContext = context;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Notification',
    barrierColor: Colors.black.withOpacity(0.54),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
            child: Material(
              color: Colors.transparent,
              child: _FloatingNotificationCard(
                item: item,
                compact: false,
                onClose: () => Navigator.of(dialogContext, rootNavigator: true).maybePop(),
                onOpen: () async {
                  Navigator.of(dialogContext, rootNavigator: true).maybePop();
                  await Future<void>.delayed(const Duration(milliseconds: 90));
                  if (!hostContext.mounted) return;
                  await NotificationActionHelper.openTarget(hostContext, item);
                },
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  ).whenComplete(() {
    if (_activeNotificationDialogId == dialogId) {
      _activeNotificationDialogId = null;
    }
  });
}

class NotificationActionHelper {
  static String notificationId(Map<String, dynamic> item) {
    final data = item['data'];
    final map = data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};
    return _firstNonEmpty([
      item['id'],
      item['notification_id'],
      item['push_id'],
      map['notification_id'],
      map['push_id'],
      map['id'],
      '${item['title']}|${item['body']}|${item['sent_time']}',
    ]);
  }

  static Future<void> openTarget(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final data = item['data'];
    final map =
        data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};

    final actionType = _firstNonEmpty([
      item['action_type'],
      item['action_target'],
      map['action_type'],
      map['action_target'],
    ]).toLowerCase();

    final explicitExternal = _firstNonEmpty([
      item['external_url'],
      map['external_url'],
      _looksExternal(item['action_url']) ? item['action_url'] : '',
      _looksExternal(map['action_url']) ? map['action_url'] : '',
      _looksExternal(item['url']) ? item['url'] : '',
      _looksExternal(map['url']) ? map['url'] : '',
    ]);

    final explicitInternal = _firstNonEmpty([
      item['deep_link_url'],
      item['deep_link'],
      item['route'],
      map['deep_link_url'],
      map['deep_link'],
      map['route'],
      !_looksExternal(item['action_url']) ? item['action_url'] : '',
      !_looksExternal(map['action_url']) ? map['action_url'] : '',
      !_looksExternal(item['url']) ? item['url'] : '',
      !_looksExternal(map['url']) ? map['url'] : '',
    ]);

    final raw = actionType == 'external'
        ? explicitExternal
        : _firstNonEmpty([explicitInternal, explicitExternal]);

    if (raw.isEmpty) return;

    if (_looksExternal(raw)) {
      final uri = Uri.tryParse(raw);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    final route = _normalizeInternalRoute(raw);

    try {
      final routePath = Uri.tryParse(route)?.path ?? route;
      final isTabRoute = routePath == '/' ||
          routePath == '/watch' ||
          routePath == '/inspire' ||
          routePath == '/explore' ||
          routePath == '/more';

      if (isTabRoute) {
        context.go(route);
      } else {
        context.push(
          route,
          extra: {
            'source': 'notification',
            'notification_item': item,
          },
        );
      }
    } catch (_) {
      try {
        context.go('/');
      } catch (_) {}
    }
  }

  static String _normalizeInternalRoute(String raw) {
    final cleanRaw = raw.trim();
    final withSlash = cleanRaw.startsWith('/') ? cleanRaw : '/$cleanRaw';
    final uri = Uri.tryParse(withSlash);
    final path = (uri?.path ?? withSlash).trim();
    final query = uri?.hasQuery == true ? '?${uri!.query}' : '';

    final mappedPath = switch (path) {
      '/home' => '/',
      '/inspire/articles' || '/inspire/inside-dunamis' || '/inside-dunamis' => '/articles',
      '/inspire/highlights' || '/inspire/message-highlights' || '/message-highlights' => '/highlights',
      '/inspire/wordification' => '/wordification',
      '/inspire/motivation' => '/motivation',
      '/explore/books' || '/library' || '/books' || '/book-reader' => '/tools/books',
      '/explore/quiz' || '/quiz' || '/quiz/bible' || '/bible-quiz' => '/quiz/bible_quiz',
      '/explore/short-videos' || '/shorts' || '/reels' || '/short-video' => '/short-videos',
      '/explore/notes' || '/notes' || '/notepad' => '/tools/notes',
      '/explore/quote' || '/quote' || '/quotes' || '/quote-creator' => '/tools/quote',
      _ => path,
    };

    return '$mappedPath$query';
  }

  static bool _looksExternal(dynamic value) {
    final text = (value ?? '').toString().trim().toLowerCase();
    return text.startsWith('http://') ||
        text.startsWith('https://') ||
        text.startsWith('market://') ||
        text.startsWith('intent://');
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}

class _FloatingNotificationCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool compact;
  final VoidCallback onClose;
  final VoidCallback onOpen;

  const _FloatingNotificationCard({
    required this.item,
    required this.compact,
    required this.onClose,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final title = _firstNonEmpty([item['title'], 'Notification']);
    final body = _firstNonEmpty([item['body'], item['message']]);
    final appName = _firstNonEmpty([item['app_name'], AppConfig.appName]);
    final actionLabel = _firstNonEmpty([item['action_label'], 'Open']);
    final imageUrl = _firstNonEmpty([
      item['image_url'],
      item['image'],
      (item['data'] is Map) ? (item['data'] as Map)['image_url'] : '',
      (item['data'] is Map) ? (item['data'] as Map)['image'] : '',
    ]);
    final logoUrl = _firstNonEmpty([
      item['app_logo_url'],
      item['logo_url'],
      item['app_logo'],
      item['app_icon_url'],
      item['icon_url'],
      (item['data'] is Map) ? (item['data'] as Map)['app_logo_url'] : '',
      (item['data'] is Map) ? (item['data'] as Map)['logo_url'] : '',
      (item['data'] is Map) ? (item['data'] as Map)['app_logo'] : '',
      (item['data'] is Map) ? (item['data'] as Map)['app_icon_url'] : '',
      (item['data'] is Map) ? (item['data'] as Map)['icon_url'] : '',
    ]);

    final maxWidth = compact ? 430.0 : 520.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFBFF),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: Colors.white.withOpacity(0.84), width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty)
                AspectRatio(
                  aspectRatio: compact ? 3.4 : 2.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _ImageFallback(compact: compact),
                  ),
                )
              else
                _ImageFallback(compact: compact),
              Padding(
                padding: EdgeInsets.fromLTRB(16, compact ? 12 : 16, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _LogoAvatar(logoUrl: logoUrl),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF111827),
                                  fontSize: 13.4,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'In-app notification card',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color:
                                      const Color(0xFF4B5563).withOpacity(0.76),
                                  fontSize: 10.8,
                                  fontWeight: FontWeight.w600,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: onClose,
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: const Color(0xFF111827),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: TextStyle(
                        color: const Color(0xFF111827),
                        fontSize: compact ? 18 : 22,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        body,
                        maxLines: compact ? 4 : 8,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF4B5563),
                          fontSize: compact ? 13.2 : 15.2,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF071328),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          onPressed: onOpen,
                          child: Text(
                            actionLabel,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF111827),
                            side: BorderSide(
                                color:
                                    const Color(0xFF111827).withOpacity(0.12)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          onPressed: onClose,
                          child: const Text(
                            'Close',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}

class _LogoAvatar extends StatelessWidget {
  final String logoUrl;

  const _LogoAvatar({required this.logoUrl});

  @override
  Widget build(BuildContext context) {
    if (logoUrl.isNotEmpty) {
      return SizedBox(
        width: 34,
        height: 34,
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFF16C7F3), Color(0xFF7248F6)],
        ),
      ),
      alignment: Alignment.center,
      child: const Text(
        'D',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final bool compact;

  const _ImageFallback({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 92 : 150,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFC9E8F6), Color(0xFFE6D8FF)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'IMAGE PREVIEW',
        style: TextStyle(
          color: Colors.white.withOpacity(0.88),
          fontSize: compact ? 11 : 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}
