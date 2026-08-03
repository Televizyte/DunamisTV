import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

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
  late final String _viewType;
  late final html.IFrameElement _iframe;

  PlayerDockTool _dockTool = PlayerDockTool.none;
  bool _toolsExpanded = false;

  bool get _hasDockOpen => _dockTool != PlayerDockTool.none;

  @override
  void initState() {
    super.initState();

    final embedUrl = _resolveUrl(widget.url);
    _viewType =
        'yt-${DateTime.now().millisecondsSinceEpoch}-${embedUrl.hashCode}';

    _iframe = html.IFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allowFullscreen = true
      ..allow =
          'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'
      ..src = embedUrl;

    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      return _iframe;
    });
  }

  String _resolveUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return url.trim();

    final list = (uri.queryParameters['list'] ?? '').trim();
    if (list.isNotEmpty) {
      final video = (uri.queryParameters['v'] ?? '').trim();
      final params = <String, String>{'list': list};
      if (video.isNotEmpty) {
        params['v'] = video;
      }
      return Uri.https('www.youtube.com', '/playlist', params).toString();
    }

    final videoId = uri.queryParameters['v'];
    if (videoId != null && videoId.trim().isNotEmpty) {
      return 'https://www.youtube-nocookie.com/embed/${videoId.trim()}?autoplay=1';
    }

    if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
      return 'https://www.youtube-nocookie.com/embed/${uri.pathSegments.first}?autoplay=1';
    }

    return url.trim();
  }

  void _toggleTools() {
    setState(() {
      _toolsExpanded = !_toolsExpanded;
    });
  }

  void _closeTools() {
    setState(() {
      _toolsExpanded = false;
    });
  }

  void _openBible() {
    setState(() {
      _toolsExpanded = false;
      _dockTool = PlayerDockTool.bible;
    });
  }

  void _openNotes() {
    setState(() {
      _toolsExpanded = false;
      _dockTool = PlayerDockTool.notes;
    });
  }

  void _switchDockTool(PlayerDockTool tool) {
    setState(() {
      _dockTool = tool;
    });
  }

  void _closeDock() {
    setState(() {
      _dockTool = PlayerDockTool.none;
    });
  }

  Widget _buildPlayerCard({required double borderRadius}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: HtmlElementView(viewType: _viewType),
    );
  }

  Widget _buildFullPlayerLayout() {
    return Stack(
      children: [
        Positioned.fill(child: _buildPlayerCard(borderRadius: 0)),
        PlayerToolsOverlay(
          expanded: _toolsExpanded,
          onMainTap: _toggleTools,
          onClose: _closeTools,
          onBibleTap: _openBible,
          onNotesTap: _openNotes,
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
    final miniPlayer = _buildPlayerCard(borderRadius: 18);

    return PlayerFloatingDockLayout(
      miniPlayer: miniPlayer,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title.trim().isEmpty ? 'YouTube' : widget.title.trim();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: Column(
        children: [
          DxmTopBar(
            title: title,
            showBack: true,
            showMenu: true,
          ),
          Expanded(
            child: _hasDockOpen ? _buildDockLayout() : _buildFullPlayerLayout(),
          ),
        ],
      ),
    );
  }
}
