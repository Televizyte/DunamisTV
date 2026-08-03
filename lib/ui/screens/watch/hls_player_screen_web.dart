import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

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
  late final String _viewType;
  late final html.IFrameElement _iframe;

  PlayerDockTool _dockTool = PlayerDockTool.none;

  bool get _hasDockOpen => _dockTool != PlayerDockTool.none;

  @override
  void initState() {
    super.initState();

    final cleanUrl = widget.url.trim();
    _viewType =
        'hls-${DateTime.now().millisecondsSinceEpoch}-${cleanUrl.hashCode}';

    _iframe = html.IFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allowFullscreen = true
      ..src = cleanUrl;

    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      return _iframe;
    });
  }

  void _openBible() {
    setState(() {
      _dockTool = PlayerDockTool.bible;
    });
  }

  void _openNotes() {
    setState(() {
      _dockTool = PlayerDockTool.notes;
    });
  }

  void _closeDock() {
    setState(() {
      _dockTool = PlayerDockTool.none;
    });
  }

  Widget _buildPlayerCard({
    required double borderRadius,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: HtmlElementView(viewType: _viewType),
    );
  }

  Widget _buildMainPlayerLayout() {
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildPlayerCard(borderRadius: 18),
          ),
          const SizedBox(height: 12),
          _BottomToolsBar(
            activeTool: _dockTool,
            onBibleTap: _openBible,
            onNotesTap: _openNotes,
            onCloseTap: null,
          ),
          const SizedBox(height: 12),
          const _PlayerInfoPlaceholder(
            title: 'Use tools while watching',
            message:
                'Open Bible or Notes with the labeled buttons below the player.',
          ),
        ],
      ),
    );
  }

  Widget _buildDockedLayout() {
    final miniPlayer = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: _buildPlayerCard(borderRadius: 18),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: PlayerFloatingDockLayout(
            miniPlayer: miniPlayer,
            dockTool: _dockTool,
            onExpandPlayer: _closeDock,
            bibleChild: const PlayerDockedBibleView(),
            notesChild: const PlayerDockedNotesView(),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: SafeArea(
            top: false,
            child: _BottomToolsBar(
              activeTool: _dockTool,
              onBibleTap: _openBible,
              onNotesTap: _openNotes,
              onCloseTap: _closeDock,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final title =
        (widget.title ?? '').trim().isEmpty ? 'Live' : widget.title!.trim();

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
            child: _hasDockOpen ? _buildDockedLayout() : _buildMainPlayerLayout(),
          ),
        ],
      ),
    );
  }
}

class _BottomToolsBar extends StatelessWidget {
  final PlayerDockTool activeTool;
  final VoidCallback onBibleTap;
  final VoidCallback onNotesTap;
  final VoidCallback? onCloseTap;

  const _BottomToolsBar({
    required this.activeTool,
    required this.onBibleTap,
    required this.onNotesTap,
    required this.onCloseTap,
  });

  @override
  Widget build(BuildContext context) {
    final showClose = onCloseTap != null && activeTool != PlayerDockTool.none;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1228),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToolActionButton(
              icon: Icons.menu_book_rounded,
              label: 'Bible',
              selected: activeTool == PlayerDockTool.bible,
              onTap: onBibleTap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ToolActionButton(
              icon: Icons.note_alt_rounded,
              label: 'Notes',
              selected: activeTool == PlayerDockTool.notes,
              onTap: onNotesTap,
            ),
          ),
          if (showClose) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 56,
              child: _ToolActionButton(
                icon: Icons.close_rounded,
                label: '',
                compact: true,
                selected: false,
                onTap: onCloseTap!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToolActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _ToolActionButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        selected ? const Color(0xFFFF2C96) : const Color(0xFF151C3A);
    final borderColor = selected
        ? const Color(0xFFFF2C96)
        : Colors.white.withOpacity(0.08);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 14),
          child: compact
              ? Center(
                  child: Icon(icon, color: Colors.white, size: 20),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PlayerInfoPlaceholder extends StatelessWidget {
  final String title;
  final String message;

  const _PlayerInfoPlaceholder({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1228),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.space_dashboard_rounded,
                color: Colors.white.withOpacity(0.92),
                size: 34,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
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
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
