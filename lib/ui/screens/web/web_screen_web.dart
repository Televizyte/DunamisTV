import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

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
  late final String _viewType;
  late final html.IFrameElement _iframe;

  bool _toolsExpanded = false;
  PlayerDockTool _dockTool = PlayerDockTool.none;

  @override
  void initState() {
    super.initState();

    final cleanUrl = widget.url.trim();
    _viewType =
        'dxm-web-${DateTime.now().microsecondsSinceEpoch}-${cleanUrl.hashCode}';

    _iframe = html.IFrameElement()
      ..src = cleanUrl
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allowFullscreen = true;

    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      return _iframe;
    });
  }

  void _openNewTab() {
    final link = widget.url.trim();
    if (link.isEmpty) return;
    html.window.open(link, '_blank');
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
      _dockTool = PlayerDockTool.bible;
      _toolsExpanded = false;
    });
  }

  void _openNotes() {
    setState(() {
      _dockTool = PlayerDockTool.notes;
      _toolsExpanded = false;
    });
  }

  void _expandPlayer() {
    setState(() {
      _dockTool = PlayerDockTool.none;
      _toolsExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: Column(
        children: [
          DxmTopBar(
            title: widget.title,
            showBack: true,
            showMenu: true,
            extraMenuItems: [
              DxmTopBarMenuEntry(
                icon: Icons.open_in_new_rounded,
                title: 'Open in Browser',
                subtitle: 'Open this page in a separate browser tab',
                onTap: _openNewTab,
              ),
            ],
          ),
          Expanded(
            child: _dockTool == PlayerDockTool.none
                ? Column(
                    children: [
                      Expanded(
                        child: HtmlElementView(viewType: _viewType),
                      ),
                      _WebToolsDockBar(
                        expanded: _toolsExpanded,
                        onToggle: _toggleTools,
                        onClose: _closeTools,
                        onBibleTap: _openBible,
                        onNotesTap: _openNotes,
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      Positioned.fill(
                        child: _dockTool == PlayerDockTool.bible
                            ? const PlayerDockedBibleView()
                            : const PlayerDockedNotesView(),
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: _MiniPlayerChip(
                          onTap: _expandPlayer,
                          child: SizedBox(
                            width: 180,
                            height: 102,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: HtmlElementView(viewType: _viewType),
                            ),
                          ),
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

class _WebToolsDockBar extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onClose;
  final VoidCallback onBibleTap;
  final VoidCallback onNotesTap;

  const _WebToolsDockBar({
    required this.expanded,
    required this.onToggle,
    required this.onClose,
    required this.onBibleTap,
    required this.onNotesTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1228),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
          ),
          child: expanded
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _WebToolButton(
                            icon: Icons.menu_book_rounded,
                            label: 'Bible',
                            subtitle: 'Read scripture',
                            onTap: onBibleTap,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _WebToolButton(
                            icon: Icons.note_alt_rounded,
                            label: 'Notes',
                            subtitle: 'Write while watching',
                            onTap: onNotesTap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Select what to open below the player.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.74),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _WebToolToggle(
                          expanded: true,
                          onTap: onClose,
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tools area reserved below the player and above future ads',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.74),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _WebToolToggle(
                      expanded: false,
                      onTap: onToggle,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _WebToolToggle extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _WebToolToggle({
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF151C3A),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(
            expanded ? Icons.close_rounded : Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _WebToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _WebToolButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF151C3A),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  fontSize: 11.5,
                  height: 1.25,
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

class _MiniPlayerChip extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _MiniPlayerChip({
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0D1228),
      elevation: 8,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Stack(
          children: [
            child,
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.open_in_full_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
