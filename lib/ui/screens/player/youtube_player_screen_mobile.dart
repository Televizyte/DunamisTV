import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../widgets/dxm_top_bar.dart';
import 'player_tools_overlay.dart';

class YoutubePlayerScreen extends StatefulWidget {
  final String title;
  final String url;

  const YoutubePlayerScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  YoutubePlayerController? _controller;
  WebViewController? _playlistWebController;

  bool _loading = true;
  bool _failed = false;
  bool _playlistPageError = false;
  bool _toolsExpanded = false;

  String _errorText = '';
  PlayerDockTool _dockTool = PlayerDockTool.none;

  String? _videoId;
  String? _playlistId;
  bool _preferWebForYoutubePage = false;

  bool get _hasWorkspaceOpen => _dockTool != PlayerDockTool.none;

  bool get _isPlaylistMode => (_playlistId?.isNotEmpty ?? false) && !kIsWeb;

  bool get _isYoutubePageMode =>
      _preferWebForYoutubePage && !kIsWeb && _playlistWebController != null;

  String get _safeTitle =>
      widget.title.trim().isEmpty ? 'YouTube' : widget.title.trim();

  @override
  void initState() {
    super.initState();
    _loadPlayer();
  }

  void _loadPlayer() {
    _controller?.removeListener(_handleYoutubeState);
    _controller?.dispose();
    _controller = null;
    _playlistWebController = null;

    _videoId = _extractYoutubeVideoId(widget.url);
    _playlistId = _extractPlaylistId(widget.url);
    _preferWebForYoutubePage = _shouldOpenYoutubeViaWebView(widget.url);

    if (_isPlaylistMode || _preferWebForYoutubePage) {
      _preparePlaylistWebView();
      return;
    }

    if (_videoId == null || _videoId!.trim().isEmpty) {
      setState(() {
        _controller = null;
        _loading = false;
        _failed = true;
        _errorText =
            'This YouTube link could not be converted to a playable video ID.';
      });
      return;
    }

    final controller = YoutubePlayerController(
      initialVideoId: _videoId!,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        isLive: _isLikelyLive(widget.url),
        disableDragSeek: false,
        forceHD: false,
        enableCaption: false,
        controlsVisibleAtStart: true,
      ),
    );

    controller.addListener(_handleYoutubeState);

    setState(() {
      _controller = controller;
      _loading = true;
      _failed = false;
      _playlistPageError = false;
      _toolsExpanded = false;
      _dockTool = PlayerDockTool.none;
      _errorText = '';
    });
  }

  bool _shouldOpenYoutubeViaWebView(String rawUrl) {
    final normalized = rawUrl.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) return false;

    final host = uri.host.toLowerCase();
    if (!host.contains('youtube.com') &&
        !host.contains('youtu.be') &&
        !host.contains('youtube-nocookie.com')) {
      return false;
    }

    final segments = uri.pathSegments.where((e) => e.trim().isNotEmpty).toList();

    if (segments.isEmpty) return false;

    if (segments.first.startsWith('@') &&
        segments.length >= 2 &&
        segments[1].toLowerCase() == 'live') {
      return true;
    }

    if (segments.first.startsWith('@')) {
      return true;
    }

    if (segments.first == 'channel' ||
        segments.first == 'c' ||
        segments.first == 'user') {
      return true;
    }

    return false;
  }

  void _preparePlaylistWebView() {
    final link = _buildPlaylistUrl();

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _failed = false;
              _playlistPageError = false;
              _errorText = '';
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _failed = false;
              _playlistPageError = false;
            });
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _failed = true;
              _playlistPageError = true;
              _errorText = error.description;
            });
          },
        ),
      )
      ..loadRequest(
        Uri.parse(link),
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
        },
      );

    setState(() {
      _playlistWebController = controller;
      _loading = true;
      _failed = false;
      _playlistPageError = false;
      _toolsExpanded = false;
      _dockTool = PlayerDockTool.none;
      _errorText = '';
    });
  }

  String _buildPlaylistUrl() {
    final uri = Uri.tryParse(widget.url.trim());
    if (uri == null) return widget.url.trim();

    final list = (uri.queryParameters['list'] ?? '').trim();
    final video = (uri.queryParameters['v'] ?? '').trim();

    if (_preferWebForYoutubePage) {
      return widget.url.trim();
    }

    if (list.isEmpty) {
      return widget.url.trim();
    }

    final params = <String, String>{'list': list};
    if (video.isNotEmpty) {
      params['v'] = video;
    }

    return Uri.https('m.youtube.com', '/playlist', params).toString();
  }

  void _handleYoutubeState() {
    final controller = _controller;
    if (!mounted || controller == null) return;

    final value = controller.value;

    if (value.hasError) {
      setState(() {
        _loading = false;
        _failed = true;
        _errorText = value.errorCode.toString();
      });
      return;
    }

    if (value.isReady || value.isPlaying || value.position > Duration.zero) {
      if (_loading || _failed) {
        setState(() {
          _loading = false;
          _failed = false;
        });
      }
    }
  }

  bool _isLikelyLive(String rawUrl) {
    final normalized = rawUrl.toLowerCase();
    return normalized.contains('/live/') ||
        normalized.contains('/live') ||
        normalized.contains('live_stream') ||
        normalized.contains('islive=1') ||
        normalized.contains('live');
  }

  String? _extractYoutubeVideoId(String rawUrl) {
    final direct = YoutubePlayer.convertUrlToId(rawUrl, trimWhitespaces: true);
    if (direct != null && direct.trim().isNotEmpty) {
      return direct.trim();
    }

    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) return null;

    final segments =
        uri.pathSegments.where((e) => e.trim().isNotEmpty).toList();

    if (uri.host.contains('youtu.be') && segments.isNotEmpty) {
      return segments.first.trim();
    }

    if (segments.isNotEmpty &&
        segments.first == 'live' &&
        segments.length >= 2) {
      return segments[1].trim();
    }

    if (segments.isNotEmpty &&
        segments.first == 'shorts' &&
        segments.length >= 2) {
      return segments[1].trim();
    }

    final v = (uri.queryParameters['v'] ?? '').trim();
    if (v.isNotEmpty) return v;

    return null;
  }

  String? _extractPlaylistId(String rawUrl) {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) return null;

    final list = (uri.queryParameters['list'] ?? '').trim();
    if (list.isEmpty) return null;
    return list;
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

    _controller?.play();

    setState(() {
      _toolsExpanded = false;
      _dockTool = PlayerDockTool.bible;
    });
  }

  void _openNotesWorkspace() {
    if (!mounted) return;

    _controller?.play();

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

  Widget _buildPlayerSurface() {
    if (_failed) {
      return _YoutubeErrorState(
        onRetry: _loadPlayer,
        message: _errorText,
      );
    }

    if (_isPlaylistMode || _preferWebForYoutubePage) {
      if (_playlistWebController == null || _playlistPageError) {
        return _YoutubeErrorState(
          onRetry: _loadPlayer,
          message: _errorText.isEmpty
              ? 'The YouTube page could not be opened.'
              : _errorText,
        );
      }

      return Stack(
        children: [
          Positioned.fill(
            child: WebViewWidget(controller: _playlistWebController!),
          ),
          if (_loading)
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

    final controller = _controller;
    if (controller == null) {
      return _YoutubeErrorState(
        onRetry: _loadPlayer,
        message: _errorText,
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: YoutubePlayer(
            controller: controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: const Color(0xFFFF2C96),
            progressColors: const ProgressBarColors(
              playedColor: Color(0xFFFF2C96),
              handleColor: Color(0xFFFF2C96),
              bufferedColor: Color(0xFF8D62FF),
              backgroundColor: Color(0xFF2B315A),
            ),
            bottomActions: const [
              CurrentPosition(),
              SizedBox(width: 8),
              ProgressBar(isExpanded: true),
              SizedBox(width: 8),
              RemainingDuration(),
              FullScreenButton(),
            ],
          ),
        ),
        if (_loading)
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
        Positioned.fill(child: _buildPlayerSurface()),
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
    _controller?.removeListener(_handleYoutubeState);
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
                title: 'Reload Player',
                subtitle: (_isPlaylistMode || _preferWebForYoutubePage)
                    ? 'Reload this YouTube page'
                    : 'Reload this YouTube player',
                onTap: _loadPlayer,
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

class _YoutubeErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final String message;

  const _YoutubeErrorState({
    required this.onRetry,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final safeMessage = message.trim();

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
                      Icons.ondemand_video_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'YouTube content failed to load',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      safeMessage.isEmpty
                          ? 'Please retry. The player is being reloaded now.'
                          : safeMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.76),
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry Player'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2C96),
                        foregroundColor: Colors.white,
                        elevation: 0,
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
