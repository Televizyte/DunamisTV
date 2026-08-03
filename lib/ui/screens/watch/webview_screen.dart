import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../widgets/dxm_top_bar.dart';
import '../player/player_tools_overlay.dart';

class WebViewScreen extends StatefulWidget {
  final String title;
  final String url;

  const WebViewScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  WebViewController? _controller;
  Timer? _statusClearTimer;
  Timer? _loadWatchdogTimer;
  Timer? _autoplayRetryTimer;

  int _progress = 0;
  int _retryCount = 0;
  int _autoplayAttemptCount = 0;

  bool _hasError = false;
  bool _toolsExpanded = false;
  bool _hasEverLoadedPage = false;
  bool _showSoftStatus = false;
  bool _isPreparing = true;
  bool _autoRetriedWrapper = false;

  String _errorText = '';
  String _statusText = '';

  PlayerDockTool _dockTool = PlayerDockTool.none;

  bool get _hasWorkspaceOpen => _dockTool != PlayerDockTool.none;

  String get _safeTitle =>
      widget.title.trim().isEmpty ? 'Open' : widget.title.trim();

  String get _cleanUrl => widget.url.trim();

  bool get _isWrapperChannel {
    final lower = _cleanUrl.toLowerCase();
    return lower.contains('iframe.viewmedia.tv') ||
        lower.contains('viewmedia.tv') ||
        lower.contains('bozztv.com') ||
        lower.contains('/embed/') ||
        lower.contains('/iframe/');
  }

  bool get _isLikelyChannelPage {
    final lower = _cleanUrl.toLowerCase();
    final title = _safeTitle.toLowerCase();

    return _isWrapperChannel ||
        lower.contains('/channel') ||
        lower.contains('/live') ||
        lower.contains('/stream') ||
        lower.contains('/watch') ||
        lower.contains('/player') ||
        lower.contains('channel?') ||
        lower.contains('live?') ||
        lower.contains('stream?') ||
        lower.contains('watch?') ||
        lower.contains('player?') ||
        title.contains('channel') ||
        title.contains('tv') ||
        title.contains('christian');
  }

  @override
  void initState() {
    super.initState();
    _prepareWebView();
  }

  Uri _buildLoadUri({bool forceFresh = false}) {
    final base = Uri.parse(_cleanUrl);

    if (!_isLikelyChannelPage && !forceFresh) {
      return base;
    }

    final query = Map<String, String>.from(base.queryParameters);
    query['_ts'] = DateTime.now().millisecondsSinceEpoch.toString();

    return base.replace(queryParameters: query);
  }

  void _setSoftStatus(
    String text, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _statusClearTimer?.cancel();

    if (!mounted) return;
    setState(() {
      _statusText = text.trim();
      _showSoftStatus = _statusText.isNotEmpty;
    });

    if (_statusText.isEmpty) return;

    _statusClearTimer = Timer(duration, () {
      if (!mounted) return;
      setState(() {
        _showSoftStatus = false;
        _statusText = '';
      });
    });
  }

  void _clearSoftStatus() {
    _statusClearTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _showSoftStatus = false;
      _statusText = '';
    });
  }

  void _startLoadWatchdog() {
    _loadWatchdogTimer?.cancel();

    final wait = _isLikelyChannelPage
        ? const Duration(seconds: 22)
        : const Duration(seconds: 12);

    _loadWatchdogTimer = Timer(wait, () {
      if (!mounted) return;
      if (_hasEverLoadedPage) return;
      if (_progress >= 80) return;

      if (_isLikelyChannelPage && !_autoRetriedWrapper) {
        _autoRetriedWrapper = true;
        _setSoftStatus('Refreshing channel page...');
        _reloadCurrentPage(forceFresh: true);
        return;
      }

      if (!mounted) return;
      setState(() {
        _isPreparing = false;
        _hasError = true;
        _errorText = _isLikelyChannelPage
            ? 'This channel page is taking too long to respond.'
            : 'This page is taking too long to respond.';
      });
    });
  }

  Future<void> _attemptEmbeddedAutoplay() async {
    final controller = _controller;
    if (controller == null) return;

    try {
      await controller.runJavaScript('''
        (() => {
          try {
            const styleId = 'dxm-webview-style';
            if (!document.getElementById(styleId)) {
              const style = document.createElement('style');
              style.id = styleId;
              style.innerHTML = `
                html, body {
                  margin: 0 !important;
                  padding: 0 !important;
                  background: #000 !important;
                  min-height: 100% !important;
                  overflow: auto !important;
                }
                iframe, video {
                  max-width: 100% !important;
                }
              `;
              document.head.appendChild(style);
            }

            const videos = Array.from(document.querySelectorAll('video'));
            for (const video of videos) {
              try {
                video.autoplay = true;
                video.playsInline = true;
                video.setAttribute('autoplay', 'true');
                video.setAttribute('playsinline', 'true');
                video.setAttribute('webkit-playsinline', 'true');
                video.muted = true;
                const p = video.play();
                if (p && typeof p.catch === 'function') {
                  p.catch(() => {});
                }
              } catch (_) {}
            }

            const iframes = Array.from(document.querySelectorAll('iframe'));
            for (const frame of iframes) {
              try {
                let src = frame.getAttribute('src') || '';
                if (!src) continue;

                if (!src.includes('autoplay=1')) {
                  src += (src.includes('?') ? '&' : '?') + 'autoplay=1';
                }
                if (!src.includes('mute=1')) {
                  src += (src.includes('?') ? '&' : '?') + 'mute=1';
                }
                if (!src.includes('playsinline=1')) {
                  src += (src.includes('?') ? '&' : '?') + 'playsinline=1';
                }

                frame.setAttribute(
                  'allow',
                  'autoplay; fullscreen; encrypted-media; picture-in-picture',
                );
                frame.setAttribute('src', src);
              } catch (_) {}
            }
          } catch (_) {}
        })();
      ''');
    } catch (_) {
      // ignore injection errors
    }
  }

  void _scheduleAutoplayRecovery() {
    _autoplayRetryTimer?.cancel();
    _autoplayAttemptCount = 0;

    if (!_isLikelyChannelPage) return;

    _autoplayRetryTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      _autoplayAttemptCount += 1;

      if (!mounted || _controller == null) {
        timer.cancel();
        return;
      }

      await _attemptEmbeddedAutoplay();

      if (_autoplayAttemptCount >= 4) {
        timer.cancel();
      }
    });
  }

  Map<String, String> _requestHeaders() {
    return const {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
    };
  }

  void _prepareWebView({bool forceFresh = false}) {
    if (kIsWeb || _cleanUrl.isEmpty) {
      return;
    }

    _loadWatchdogTimer?.cancel();
    _autoplayRetryTimer?.cancel();

    setState(() {
      _hasError = false;
      _errorText = '';
      _progress = 0;
      _isPreparing = true;
      if (_retryCount == 0) {
        _hasEverLoadedPage = false;
      }
    });

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
          onProgress: (p) {
            if (!mounted) return;
            setState(() => _progress = p);
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _hasError = false;
              _errorText = '';
              _progress = 0;
              _isPreparing = true;
            });
            _startLoadWatchdog();
          },
          onPageFinished: (_) async {
            if (!mounted) return;

            setState(() {
              _progress = 100;
              _hasError = false;
              _hasEverLoadedPage = true;
              _isPreparing = false;
            });

            _loadWatchdogTimer?.cancel();
            _clearSoftStatus();

            if (_isLikelyChannelPage) {
              await Future<void>.delayed(const Duration(milliseconds: 500));
              await _attemptEmbeddedAutoplay();
              _scheduleAutoplayRecovery();
            }
          },
          onWebResourceError: (error) {
            if (!mounted) return;

            final safeText = error.description.trim();

            if (_hasEverLoadedPage) {
              setState(() {
                _errorText = safeText;
                _isPreparing = false;
              });
              _setSoftStatus('Channel connection issue detected. Continuing...');
              return;
            }

            if (_isLikelyChannelPage && !_autoRetriedWrapper) {
              _autoRetriedWrapper = true;
              _setSoftStatus('Retrying channel page...');
              _reloadCurrentPage(forceFresh: true);
              return;
            }

            setState(() {
              _hasError = true;
              _errorText = safeText.isEmpty
                  ? 'This channel could not be opened right now.'
                  : safeText;
              _isPreparing = false;
            });
          },
        ),
      )
      ..loadRequest(
        _buildLoadUri(forceFresh: forceFresh),
        headers: _requestHeaders(),
      );

    _controller = controller;
    _startLoadWatchdog();
  }

  void _reloadCurrentPage({bool forceFresh = false}) {
    if (kIsWeb || _cleanUrl.isEmpty) return;

    _retryCount += 1;
    _autoplayRetryTimer?.cancel();

    setState(() {
      _hasError = false;
      _errorText = '';
      _progress = 0;
      _isPreparing = true;
      _controller = null;
    });

    _prepareWebView(forceFresh: forceFresh);
  }

  void _retry() {
    _autoRetriedWrapper = false;
    _retryCount = 0;
    _reloadCurrentPage(forceFresh: true);
  }

  void _toggleTools() {
    if (!mounted) return;
    setState(() {
      _toolsExpanded = !_toolsExpanded;
    });
  }

  void _closeTools() {
    if (!mounted) return;
    setState(() {
      _toolsExpanded = false;
    });
  }

  void _openBibleWorkspace() {
    if (!mounted) return;
    setState(() {
      _toolsExpanded = false;
      _dockTool = PlayerDockTool.bible;
    });
  }

  void _openNotesWorkspace() {
    if (!mounted) return;
    setState(() {
      _toolsExpanded = false;
      _dockTool = PlayerDockTool.notes;
    });
  }

  void _switchWorkspace(PlayerDockTool tool) {
    if (!mounted) return;
    setState(() {
      _dockTool = tool;
    });
  }

  void _closeWorkspace() {
    if (!mounted) return;
    setState(() {
      _dockTool = PlayerDockTool.none;
    });
  }

  Widget _buildSoftStatusChip() {
    if (!_showSoftStatus || _statusText.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 14,
      left: 14,
      right: 14,
      child: SafeArea(
        bottom: false,
        child: IgnorePointer(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xCC0D1228),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ColoredBox(
      color: const Color(0xFF0B1020),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              const SizedBox(height: 16),
              Text(
                _isLikelyChannelPage
                    ? 'Preparing channel page...'
                    : 'Opening content...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLikelyChannelPage
                    ? 'Please wait while the embedded player connects.'
                    : 'Please wait while the page loads.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebSurface() {
    if (_cleanUrl.isEmpty) {
      return const _WebCleanState(
        icon: Icons.link_off_rounded,
        title: 'Content not available',
        message: 'This content does not have a valid link yet.',
      );
    }

    if (kIsWeb) {
      return const _WebCleanState(
        icon: Icons.language_rounded,
        title: 'Web preview mode',
        message:
            'This content opens normally on Android inside the app WebView.',
      );
    }

    if (_hasError && !_hasEverLoadedPage) {
      return _WebCleanState(
        icon: Icons.error_outline_rounded,
        title: 'Unable to open channel yet',
        message: _errorText.trim().isEmpty
            ? 'This channel could not be loaded right now.'
            : _errorText.trim(),
        buttonText: 'Retry',
        onPressed: _retry,
      );
    }

    if (_controller == null || (_isPreparing && !_hasEverLoadedPage)) {
      return _buildLoadingState();
    }

    return Stack(
      children: [
        Positioned.fill(
          child: WebViewWidget(controller: _controller!),
        ),
        if (_progress < 100)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: LinearProgressIndicator(
              minHeight: 2,
              value: _progress <= 0 ? null : _progress / 100,
              backgroundColor: Colors.white.withOpacity(0.12),
            ),
          ),
      ],
    );
  }

  Widget _buildFullPlayerLayout() {
    return Stack(
      children: [
        Positioned.fill(child: _buildWebSurface()),
        PlayerToolsOverlay(
          expanded: _toolsExpanded,
          onMainTap: _toggleTools,
          onClose: _closeTools,
          onBibleTap: _openBibleWorkspace,
          onNotesTap: _openNotesWorkspace,
        ),
        Positioned(
          right: 14,
          bottom: 88,
          child: SafeArea(
            top: false,
            child: PlayerToolsFab(
              expanded: _toolsExpanded,
              onTap: _toggleTools,
            ),
          ),
        ),
        _buildSoftStatusChip(),
        if (_hasWorkspaceOpen)
          _PlayerWorkspaceOverlay(
            activeTool: _dockTool,
            onBibleTap: () => _switchWorkspace(PlayerDockTool.bible),
            onNotesTap: () => _switchWorkspace(PlayerDockTool.notes),
            onCloseTap: _closeWorkspace,
            bibleChild: const PlayerDockedBibleView(),
            notesChild: const PlayerDockedNotesView(),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _statusClearTimer?.cancel();
    _loadWatchdogTimer?.cancel();
    _autoplayRetryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: Column(
        children: [
          DxmTopBar(
            title: _safeTitle,
            showBack: true,
            showMenu: true,
            extraMenuItems: [
              DxmTopBarMenuEntry(
                icon: Icons.refresh_rounded,
                title: 'Reload Channel',
                subtitle: 'Refresh this channel stream',
                onTap: _retry,
              ),
            ],
          ),
          Expanded(
            child: _buildFullPlayerLayout(),
          ),
        ],
      ),
    );
  }
}

class _PlayerWorkspaceOverlay extends StatelessWidget {
  final PlayerDockTool activeTool;
  final VoidCallback onBibleTap;
  final VoidCallback onNotesTap;
  final VoidCallback onCloseTap;
  final Widget bibleChild;
  final Widget notesChild;

  const _PlayerWorkspaceOverlay({
    required this.activeTool,
    required this.onBibleTap,
    required this.onNotesTap,
    required this.onCloseTap,
    required this.bibleChild,
    required this.notesChild,
  });

  @override
  Widget build(BuildContext context) {
    final child = activeTool == PlayerDockTool.notes ? notesChild : bibleChild;
    final media = MediaQuery.of(context);
    final mediaTop = media.padding.top + 96;
    final keyboardBottom = media.viewInsets.bottom;
    final safeBottom = math.max(12.0, keyboardBottom + 8.0);

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Container(
                color: Colors.black.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: mediaTop,
            bottom: safeBottom,
            child: SafeArea(
              top: false,
              bottom: false,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF8A2BE2),
                        Color(0xFFC3007A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.28),
                        blurRadius: 28,
                        offset: const Offset(0, 18),
                      ),
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 92,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: _WorkspaceTopButton(
                                label: 'Bible',
                                icon: Icons.menu_book_rounded,
                                active: activeTool == PlayerDockTool.bible,
                                onTap: onBibleTap,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _WorkspaceTopButton(
                                label: 'Notes',
                                icon: Icons.edit_note_rounded,
                                active: activeTool == PlayerDockTool.notes,
                                onTap: onNotesTap,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _WorkspaceCloseButton(onTap: onCloseTap),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF09122E).withOpacity(0.96),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: child,
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

class _WorkspaceTopButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _WorkspaceTopButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = active
        ? const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF2C96),
                Color(0xFF8A2BE2),
              ],
            ),
            borderRadius: BorderRadius.all(Radius.circular(14)),
          )
        : BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        decoration: decoration,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 17),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceCloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _WorkspaceCloseButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFF6F2BFF),
            Color(0xFFD4007F),
          ],
        ),
      ),
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.close_rounded),
        color: Colors.white,
        iconSize: 20,
      ),
    );
  }
}

class _WebCleanState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;

  const _WebCleanState({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xCC0B1020),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1228),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                    color: Colors.black.withOpacity(0.20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.76),
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (buttonText != null && onPressed != null) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: onPressed,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(buttonText!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2C96),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
