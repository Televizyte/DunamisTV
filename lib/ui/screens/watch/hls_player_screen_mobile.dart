import 'dart:async';
import 'dart:math' as math;

import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../widgets/dxm_top_bar.dart';
import '../player/player_tools_overlay.dart';

class HlsPlayerScreen extends StatefulWidget {
  final String url;
  final String? title;

  const HlsPlayerScreen({
    super.key,
    required this.url,
    this.title,
  });

  @override
  State<HlsPlayerScreen> createState() => _HlsPlayerScreenState();
}

class _HlsPlayerScreenState extends State<HlsPlayerScreen> {
  BetterPlayerController? _controller;
  WebViewController? _webController;
  Timer? _statusClearTimer;

  bool _hasError = false;
  bool _initializing = true;
  bool _toolsExpanded = false;
  bool _preferWebFallback = false;
  bool _hasEverRenderedPlayback = false;
  bool _showSoftStatus = false;

  String _lastErrorText = '';
  String _statusText = '';

  PlayerDockTool _dockTool = PlayerDockTool.none;

  String get _cleanUrl => widget.url.trim();

  bool get _hasWorkspaceOpen => _dockTool != PlayerDockTool.none;

  bool get _canUseWebFallback {
    final url = _cleanUrl.toLowerCase();
    return url.contains('iframe.viewmedia.tv') ||
        url.contains('bozztv.com') ||
        url.contains('viewmedia.tv') ||
        url.contains('.html') ||
        url.contains('/live') ||
        url.contains('/watch') ||
        url.contains('/stream');
  }

  String get _safeTitle {
    final title = (widget.title ?? '').trim();
    return title.isEmpty ? 'Live Stream' : title;
  }

  @override
  void initState() {
    super.initState();
    _buildPlayer();
  }

  void _setSoftStatus(String text, {Duration duration = const Duration(seconds: 4)}) {
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

  Future<void> _buildPlayer() async {
    _statusClearTimer?.cancel();
    _controller?.removeEventsListener(_onPlayerEvent);
    _controller?.dispose();
    _controller = null;
    _webController = null;

    if (!mounted) return;
    setState(() {
      _hasError = false;
      _initializing = true;
      _lastErrorText = '';
      _statusText = '';
      _showSoftStatus = false;
      _preferWebFallback = _canUseWebFallback && !_isDirectHlsUrl(_cleanUrl);
      _hasEverRenderedPlayback = false;
      _dockTool = PlayerDockTool.none;
    });

    if (_cleanUrl.isEmpty) {
      setState(() {
        _hasError = true;
        _initializing = false;
        _lastErrorText = 'Stream URL is empty.';
      });
      return;
    }

    if (_preferWebFallback) {
      _prepareWebFallback();
      return;
    }

    final controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        autoPlay: true,
        looping: false,
        fit: BoxFit.contain,
        expandToFill: false,
        handleLifecycle: true,
        fullScreenByDefault: false,
        allowedScreenSleep: false,
        autoDispose: false,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enablePlayPause: true,
          enableFullscreen: true,
          enableMute: true,
          enableProgressBar: true,
          enableOverflowMenu: false,
          enableSkips: false,
        ),
      ),
    );

    controller.addEventsListener(_onPlayerEvent);

    try {
      await controller.setupDataSource(
        BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          _cleanUrl,
          videoFormat: BetterPlayerVideoFormat.hls,
          liveStream: true,
          useAsmsTracks: true,
          useAsmsSubtitles: false,
          cacheConfiguration: const BetterPlayerCacheConfiguration(
            useCache: false,
          ),
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
            'Accept': '*/*',
            'Connection': 'keep-alive',
          },
        ),
      );

      _controller = controller;

      await Future<void>.delayed(const Duration(milliseconds: 180));
      await controller.play();

      if (!mounted) return;
      setState(() {
        _initializing = false;
        _hasError = false;
      });
    } catch (e) {
      controller.removeEventsListener(_onPlayerEvent);
      controller.dispose();

      if (!mounted) return;
      setState(() {
        _controller = null;
        _initializing = false;
        _hasError = true;
        _lastErrorText = e.toString();
      });
    }
  }

  bool _isDirectHlsUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.m3u8') ||
        lower.contains('.m3u8?') ||
        lower.contains('/m3u8');
  }

  void _prepareWebFallback() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _initializing = true;
              _hasError = false;
              _lastErrorText = '';
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _initializing = false;
              _hasError = false;
              _hasEverRenderedPlayback = true;
            });
            _clearSoftStatus();
          },
          onWebResourceError: (error) {
            if (!mounted) return;

            final safeText = error.description.trim();

            if (_hasEverRenderedPlayback) {
              setState(() {
                _initializing = false;
                _lastErrorText = safeText;
              });
              _setSoftStatus('Connection issue detected. Trying to continue...');
              return;
            }

            setState(() {
              _initializing = false;
              _hasError = true;
              _lastErrorText = safeText;
            });
          },
        ),
      )
      ..loadRequest(
        Uri.parse(_cleanUrl),
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
        },
      );

    setState(() {
      _webController = controller;
      _initializing = true;
      _hasError = false;
    });
  }

  void _onPlayerEvent(BetterPlayerEvent event) {
    if (!mounted) return;

    if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
      setState(() {
        _initializing = false;
        _hasError = false;
        _hasEverRenderedPlayback = true;
      });
      _clearSoftStatus();
      return;
    }

    if (event.betterPlayerEventType == BetterPlayerEventType.play) {
      setState(() {
        _initializing = false;
        _hasError = false;
        _hasEverRenderedPlayback = true;
      });
      _clearSoftStatus();
      return;
    }

    if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
      final text = event.parameters?.toString() ?? '';

      final shouldSwitchToWeb =
          _canUseWebFallback && !_preferWebFallback && _webController == null;

      if (shouldSwitchToWeb) {
        setState(() {
          _preferWebFallback = true;
          _lastErrorText = text;
        });
        _setSoftStatus('Switching to compatible web stream...');
        _prepareWebFallback();
        return;
      }

      if (_hasEverRenderedPlayback) {
        setState(() {
          _initializing = false;
          _lastErrorText = text;
        });
        _setSoftStatus('Stream interrupted. Trying to recover...');
        return;
      }

      setState(() {
        _hasError = true;
        _initializing = false;
        _lastErrorText = text;
      });
      return;
    }

    if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
      _controller?.play();
      return;
    }

    if (event.betterPlayerEventType == BetterPlayerEventType.bufferingStart) {
      setState(() {
        _initializing = true;
      });

      if (_hasEverRenderedPlayback) {
        _setSoftStatus('Buffering live stream...');
      }
      return;
    }

    if (event.betterPlayerEventType == BetterPlayerEventType.bufferingEnd) {
      setState(() {
        _initializing = false;
      });
      _clearSoftStatus();
      return;
    }
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xCC0D1228),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
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

  Widget _buildPrimarySurface() {
    if (_preferWebFallback) {
      if (_webController == null) {
        return const ColoredBox(
          color: Color(0xFF0B1020),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return Stack(
        children: [
          Positioned.fill(
            child: WebViewWidget(controller: _webController!),
          ),
          if (_initializing)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.white.withOpacity(0.12),
              ),
            ),
        ],
      );
    }

    if (_hasError && !_hasEverRenderedPlayback) {
      return _HlsErrorOverlay(
        onRetry: _buildPlayer,
        onTryWebFallback: _canUseWebFallback
            ? () {
                setState(() {
                  _preferWebFallback = true;
                  _hasError = false;
                  _initializing = true;
                });
                _prepareWebFallback();
              }
            : null,
        details: _lastErrorText,
      );
    }

    final controller = _controller;
    if (controller == null) {
      return const ColoredBox(
        color: Color(0xFF0B1020),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: BetterPlayer(controller: controller),
        ),
        if (_initializing)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.white.withOpacity(0.12),
            ),
          ),
      ],
    );
  }

  Widget _buildFullPlayerLayout() {
    return Stack(
      children: [
        Positioned.fill(child: _buildPrimarySurface()),
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
    _controller?.removeEventsListener(_onPlayerEvent);
    _controller?.dispose();
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
                title: 'Restart Stream',
                subtitle: 'Reload this stream',
                onTap: _buildPlayer,
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

class _HlsErrorOverlay extends StatelessWidget {
  final Future<void> Function() onRetry;
  final VoidCallback? onTryWebFallback;
  final String details;

  const _HlsErrorOverlay({
    required this.onRetry,
    required this.details,
    required this.onTryWebFallback,
  });

  @override
  Widget build(BuildContext context) {
    final safeDetails = details.trim();

    return ColoredBox(
      color: const Color(0xCC0B1020),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1228),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.live_tv_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Live stream could not start yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please retry. If the direct stream is unavailable, you can open the compatible web player instead.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.76),
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (safeDetails.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        safeDetails,
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.40),
                          fontSize: 10.8,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry Stream'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF2C96),
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                        ),
                        if (onTryWebFallback != null)
                          OutlinedButton.icon(
                            onPressed: onTryWebFallback,
                            icon: const Icon(Icons.open_in_browser_rounded),
                            label: const Text('Open Web Player'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.14),
                              ),
                            ),
                          ),
                      ],
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
}
