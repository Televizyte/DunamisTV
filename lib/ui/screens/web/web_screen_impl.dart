import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../widgets/dxm_top_bar.dart';
import '../player/player_tools_overlay.dart';

class WebScreenImpl extends StatefulWidget {
  final String title;
  final String url;

  const WebScreenImpl({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<WebScreenImpl> createState() => _WebScreenImplState();
}

class _WebScreenImplState extends State<WebScreenImpl> {
  WebViewController? _controller;
  bool _loading = true;
  bool _failed = false;
  bool _toolsExpanded = false;
  String _errorMessage = '';
  int _progress = 0;
  PlayerDockTool _dockTool = PlayerDockTool.none;

  String get _cleanTitle {
    final value = widget.title.trim();
    return value.isEmpty ? 'Open Link' : value;
  }

  String get _cleanUrl {
    final raw = widget.url.trim();
    if (raw.isEmpty) return '';

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    if (raw.startsWith('//')) {
      return 'https:$raw';
    }

    if (raw.startsWith('www.')) {
      return 'https://$raw';
    }

    return raw;
  }

  Uri? get _uri {
    final normalized = _cleanUrl;
    if (normalized.isEmpty) return null;
    return Uri.tryParse(normalized);
  }

  bool get _hasDockOpen => _dockTool != PlayerDockTool.none;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final uri = _uri;

    if (uri == null || (!uri.hasScheme && !uri.hasAuthority)) {
      setState(() {
        _controller = null;
        _loading = false;
        _failed = true;
        _progress = 0;
        _errorMessage = 'This web link is invalid or missing.';
      });
      return;
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (!mounted) return;
            setState(() {
              _progress = value;
            });
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _failed = false;
              _progress = 0;
              _errorMessage = '';
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _failed = false;
              _progress = 100;
            });
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _failed = true;
              _errorMessage = error.description.trim().isEmpty
                  ? 'This page could not be loaded.'
                  : error.description.trim();
            });
          },
        ),
      )
      ..loadRequest(
        uri,
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
        },
      );

    setState(() {
      _controller = controller;
      _loading = true;
      _failed = false;
      _progress = 0;
      _errorMessage = '';
    });
  }

  void _retry() {
    setState(() {
      _failed = false;
      _loading = true;
      _progress = 0;
      _errorMessage = '';
      _toolsExpanded = false;
    });
    _initializeWebView();
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

  void _openBibleDock() {
    if (!mounted) return;
    setState(() {
      _toolsExpanded = false;
      _dockTool = PlayerDockTool.bible;
    });
  }

  void _openNotesDock() {
    if (!mounted) return;
    setState(() {
      _toolsExpanded = false;
      _dockTool = PlayerDockTool.notes;
    });
  }

  void _switchDockTool(PlayerDockTool tool) {
    if (!mounted) return;
    setState(() {
      _dockTool = tool;
    });
  }

  void _closeDock() {
    if (!mounted) return;
    setState(() {
      _dockTool = PlayerDockTool.none;
    });
  }

  Widget _buildWebSurface() {
    final controller = _controller;

    if (controller == null) {
      return _WebErrorState(
        message: _errorMessage.isEmpty
            ? 'This page could not be prepared.'
            : _errorMessage,
        onRetry: _retry,
      );
    }

    if (_failed) {
      return _WebErrorState(
        message: _errorMessage.isEmpty
            ? 'This page could not be loaded.'
            : _errorMessage,
        onRetry: _retry,
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: WebViewWidget(controller: controller),
        ),
        if (_loading || _progress < 100)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: LinearProgressIndicator(
              minHeight: 2,
              value: _progress <= 0 || _progress >= 100 ? null : _progress / 100,
              backgroundColor: Colors.white.withOpacity(0.12),
            ),
          ),
      ],
    );
  }

  Widget _buildMiniPlayerCard() {
    return _MiniWebCard(
      title: _cleanTitle,
      subtitle: _failed ? 'Page unavailable' : 'Tap to expand',
      icon: _failed ? Icons.error_outline_rounded : Icons.public_rounded,
    );
  }

  Widget _buildFullLayout() {
    return Stack(
      children: [
        Positioned.fill(child: _buildWebSurface()),
        PlayerToolsOverlay(
          expanded: _toolsExpanded,
          onMainTap: _toggleTools,
          onClose: _closeTools,
          onBibleTap: _openBibleDock,
          onNotesTap: _openNotesDock,
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
      ],
    );
  }

  Widget _buildDockLayout() {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: Opacity(
              opacity: 0.01,
              child: _buildWebSurface(),
            ),
          ),
        ),
        Positioned.fill(
          child: PlayerFloatingDockLayout(
            miniPlayer: _buildMiniPlayerCard(),
            dockTool: _dockTool,
            onExpandPlayer: _closeDock,
            bibleChild: const PlayerDockedBibleView(),
            notesChild: const PlayerDockedNotesView(),
            bottomSwitcher: PlayerDockBottomSwitcher(
              activeTool: _dockTool,
              onBibleTap: () => _switchDockTool(PlayerDockTool.bible),
              onNotesTap: () => _switchDockTool(PlayerDockTool.notes),
              onCloseTap: _closeDock,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: Column(
        children: [
          DxmTopBar(
            title: _cleanTitle,
            showBack: true,
            showMenu: true,
            extraMenuItems: [
              DxmTopBarMenuEntry(
                icon: Icons.refresh_rounded,
                title: 'Reload Page',
                subtitle: 'Reload this web page',
                onTap: _retry,
              ),
            ],
          ),
          Expanded(
            child: _hasDockOpen ? _buildDockLayout() : _buildFullLayout(),
          ),
        ],
      ),
    );
  }
}

class _WebErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _WebErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1228),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.public_off_rounded,
                size: 44,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              const Text(
                'This page could not be opened.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.76),
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniWebCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _MiniWebCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1228),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Icon(
                icon,
                color: Colors.white.withOpacity(0.92),
                size: 34,
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 11.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
