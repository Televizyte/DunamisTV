import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../features/bible/models/bible_models.dart';
import '../../../features/bible/state/bible_store.dart';
import '../../../features/notes/models/note_model.dart';
import '../../../features/notes/state/notes_store.dart';
import '../../../theme/theme_controller.dart';

enum PlayerDockTool { none, bible, notes }

const LinearGradient _playerAccentGradient = LinearGradient(
  colors: <Color>[
    Color(0xFF5B1FA8),
    Color(0xFFB70E7C),
  ],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

class PlayerToolsOverlay extends StatelessWidget {
  final bool expanded;
  final VoidCallback onMainTap;
  final VoidCallback onClose;
  final VoidCallback onBibleTap;
  final VoidCallback onNotesTap;

  const PlayerToolsOverlay({
    super.key,
    required this.expanded,
    required this.onMainTap,
    required this.onClose,
    required this.onBibleTap,
    required this.onNotesTap,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !expanded,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: expanded ? 1 : 0,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  color: Colors.black.withOpacity(0.38),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 92),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  decoration: BoxDecoration(
                    gradient: _playerAccentGradient,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.14)),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                        color: Colors.black.withOpacity(0.30),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.28),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const Text(
                        'Quick Tools',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Open Bible or Notes while the player stays available.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.88),
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _ToolCard(
                              icon: Icons.menu_book_rounded,
                              label: 'Bible',
                              subtitle: 'Read scripture',
                              onTap: onBibleTap,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ToolCard(
                              icon: Icons.note_alt_rounded,
                              label: 'Notes',
                              subtitle: 'Write while watching',
                              onTap: onNotesTap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerToolsFab extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const PlayerToolsFab({
    super.key,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _playerAccentGradient,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.24),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: SizedBox(
            width: 58,
            height: 58,
            child: Icon(
              expanded ? Icons.close_rounded : Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerFloatingDockLayout extends StatefulWidget {
  final Widget miniPlayer;
  final PlayerDockTool dockTool;
  final VoidCallback onExpandPlayer;
  final Widget bibleChild;
  final Widget notesChild;
  final Widget? bottomSwitcher;

  const PlayerFloatingDockLayout({
    super.key,
    required this.miniPlayer,
    required this.dockTool,
    required this.onExpandPlayer,
    required this.bibleChild,
    required this.notesChild,
    this.bottomSwitcher,
  });

  @override
  State<PlayerFloatingDockLayout> createState() =>
      _PlayerFloatingDockLayoutState();
}

class _PlayerFloatingDockLayoutState extends State<PlayerFloatingDockLayout> {
  Offset? _position;

  @override
  Widget build(BuildContext context) {
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final miniWidth = math.min(
          math.max(180.0, constraints.maxWidth * 0.38),
          250.0,
        );
        final miniHeight = miniWidth * 9 / 16;

        const horizontalGap = 10.0;
        const topGap = 10.0;
        final bottomSwitcherHeight =
            widget.bottomSwitcher == null ? 0.0 : 86.0;
        final bottomReserved = keyboardBottom > 0
            ? keyboardBottom + bottomSwitcherHeight + 12
            : bottomSwitcherHeight + 12;

        final maxX =
            math.max(0.0, constraints.maxWidth - miniWidth - horizontalGap);
        final maxY = math.max(
          topGap,
          constraints.maxHeight - miniHeight - bottomReserved,
        );

        _position ??= Offset(maxX, topGap);
        _position = Offset(
          _position!.dx.clamp(0.0, maxX),
          _position!.dy.clamp(topGap, maxY),
        );

        final content = widget.dockTool == PlayerDockTool.bible
            ? widget.bibleChild
            : widget.notesChild;

        return Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: bottomReserved,
                ),
                child: content,
              ),
            ),
            Positioned(
              left: _position!.dx,
              top: _position!.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _position = Offset(
                      (_position!.dx + details.delta.dx).clamp(0.0, maxX),
                      (_position!.dy + details.delta.dy).clamp(topGap, maxY),
                    );
                  });
                },
                child: _FloatingMiniPlayerCard(
                  width: miniWidth,
                  height: miniHeight,
                  playerChild: widget.miniPlayer,
                  onExpand: widget.onExpandPlayer,
                ),
              ),
            ),
            if (widget.bottomSwitcher != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: SafeArea(
                  top: false,
                  child: widget.bottomSwitcher!,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FloatingMiniPlayerCard extends StatelessWidget {
  final double width;
  final double height;
  final Widget playerChild;
  final VoidCallback onExpand;

  const _FloatingMiniPlayerCard({
    required this.width,
    required this.height,
    required this.playerChild,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0B1020),
      elevation: 14,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 10),
              color: Colors.black.withOpacity(0.30),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: playerChild),
            Positioned(
              right: 8,
              top: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _playerAccentGradient,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: onExpand,
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerDockBottomSwitcher extends StatelessWidget {
  final PlayerDockTool activeTool;
  final VoidCallback onBibleTap;
  final VoidCallback onNotesTap;
  final VoidCallback onCloseTap;

  const PlayerDockBottomSwitcher({
    super.key,
    required this.activeTool,
    required this.onBibleTap,
    required this.onNotesTap,
    required this.onCloseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF111938),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.18),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _DockActionButton(
              icon: Icons.menu_book_rounded,
              label: 'Bible',
              selected: activeTool == PlayerDockTool.bible,
              onTap: onBibleTap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DockActionButton(
              icon: Icons.note_alt_rounded,
              label: 'Notes',
              selected: activeTool == PlayerDockTool.notes,
              onTap: onNotesTap,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 56,
            child: _DockActionButton(
              icon: Icons.close_rounded,
              label: '',
              compact: true,
              selected: false,
              onTap: onCloseTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _DockActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _DockActionButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        selected ? const Color(0xFFFF2C96) : const Color(0xFF192247);
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

class PlayerDockedNotesView extends StatefulWidget {
  const PlayerDockedNotesView({super.key});

  @override
  State<PlayerDockedNotesView> createState() => _PlayerDockedNotesViewState();
}

class _PlayerDockedNotesViewState extends State<PlayerDockedNotesView> {
  final NotesStore _store = NotesStore();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();

  late final NotesAutosaveController _autosave;

  NoteModel? _note;
  bool _loading = true;
  String _saveLabel = 'Saved';

  @override
  void initState() {
    super.initState();
    _autosave = NotesAutosaveController(onSave: _saveSilently);
    _boot();
  }

  Future<void> _boot() async {
    await _store.init();

    final preferred = _latestReusableNote();

    if (preferred != null) {
      _loadNoteIntoEditor(preferred);
    } else {
      final created = await _store.createEmptyNote(
        sourceType: 'player',
        sourceId: 'player-note-${DateTime.now().millisecondsSinceEpoch}',
      );
      _loadNoteIntoEditor(created);
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _saveLabel = 'Saved';
    });
  }

  NoteModel? _latestReusableNote() {
    final notes = _store.notes;
    if (notes.isEmpty) return null;

    for (final note in notes.reversed) {
      if (note.sourceType.trim().toLowerCase() == 'player') {
        return note;
      }
    }

    return notes.isNotEmpty ? notes.last : null;
  }

  void _loadNoteIntoEditor(NoteModel note) {
    _note = note;
    _titleController.text = note.title;
    _contentController.text = note.content;
    _titleController.selection = TextSelection.collapsed(
      offset: _titleController.text.length,
    );
    _contentController.selection = TextSelection.collapsed(
      offset: _contentController.text.length,
    );
  }

  Future<void> _createNewNote() async {
    await _saveSilently();

    final created = await _store.createEmptyNote(
      sourceType: 'player',
      sourceId: 'player-note-${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!mounted) return;
    setState(() {
      _loadNoteIntoEditor(created);
      _saveLabel = 'New note';
    });

    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    _contentFocusNode.requestFocus();
  }

  Future<void> _openExistingNotePicker() async {
    await _saveSilently();

    final isLight = ThemeController.instance.isLightMode;
    final notes = _store.notes.reversed.toList();

    if (notes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No notes available yet')),
      );
      return;
    }

    final selected = await showModalBottomSheet<NoteModel>(
      context: context,
      backgroundColor:
          isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final textColor =
            isLight ? const Color(0xFF1E1B16) : Colors.white;
        final subtleColor = isLight
            ? const Color(0xFF6B6256)
            : Colors.white.withOpacity(0.68);
        final borderColor = isLight
            ? const Color(0xFFE6D8C3)
            : Colors.white.withOpacity(0.08);

        return SafeArea(
          top: false,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final note = notes[index];
              final title = note.title.trim().isEmpty
                  ? 'Untitled note'
                  : note.title.trim();
              final preview = note.content.trim().isEmpty
                  ? 'No content yet'
                  : note.content.trim().replaceAll('\n', ' ');

              return Material(
                color: isLight
                    ? const Color(0xFFFFFBF4)
                    : const Color(0xFF111938),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.pop(context, note),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: subtleColor,
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
            },
          ),
        );
      },
    );

    if (selected == null || !mounted) return;

    setState(() {
      _loadNoteIntoEditor(selected);
      _saveLabel = 'Opened';
    });
  }

  @override
  void dispose() {
    _autosave.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    _store.dispose();
    super.dispose();
  }

  Future<void> _saveSilently() async {
    final current = _note;
    if (current == null) return;

    if (mounted) {
      setState(() => _saveLabel = 'Saving...');
    }

    final updated = current.copyWith(
      title: _titleController.text,
      content: _contentController.text,
      sourceType: 'player',
      sourceId: current.sourceId.trim().isEmpty
          ? 'player-note-${DateTime.now().millisecondsSinceEpoch}'
          : current.sourceId,
    );

    await _store.saveNote(updated);
    _note = _store.findNoteById(updated.id) ?? updated;

    if (!mounted) return;
    setState(() => _saveLabel = 'Saved');
  }

  Future<void> _saveNow() async {
    await _saveSilently();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note saved')),
    );
  }

  void _onTextChanged() {
    if (!mounted) return;
    setState(() => _saveLabel = 'Typing...');
    _autosave.schedule();
  }

  String _selectedTextOrWholeNote() {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (selection.isValid && !selection.isCollapsed) {
      final start =
          selection.start < selection.end ? selection.start : selection.end;
      final end =
          selection.start < selection.end ? selection.end : selection.start;

      if (start >= 0 && end <= text.length) {
        final picked = text.substring(start, end).trim();
        if (picked.isNotEmpty) return picked;
      }
    }

    if (text.trim().isNotEmpty) return text.trim();
    return _titleController.text.trim();
  }

  Future<void> _copyNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something first')),
      );
      return;
    }

    final buffer = StringBuffer();
    if (title.isNotEmpty) {
      buffer.writeln(title);
      buffer.writeln();
    }
    if (content.isNotEmpty) {
      buffer.write(content);
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note copied')),
    );
  }

  Future<void> _makeQuote() async {
    final quoteText = _selectedTextOrWholeNote().trim();

    if (quoteText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select text or write something first')),
      );
      return;
    }

    await _saveSilently();
    if (!mounted) return;

    context.push(
      '/tools/quote',
      extra: {
        'designData': {
          'quote': quoteText,
          'author': _titleController.text.trim().isEmpty
              ? 'My Note'
              : _titleController.text.trim(),
          'source_type': 'note',
          'source_id': _note?.id ?? '',
        },
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final isLight = ThemeController.instance.isLightMode;
        final panelColor =
            isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430);
        final borderColor = isLight
            ? const Color(0xFFE6D8C3)
            : Colors.white.withOpacity(0.08);
        final textColor =
            isLight ? const Color(0xFF1E1B16) : Colors.white;
        final subtleColor = isLight
            ? const Color(0xFF6B6256)
            : Colors.white.withOpacity(0.68);

        if (_loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          color: isLight ? const Color(0xFFF7F1E6) : const Color(0xFF070B18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final editorMinHeight = math.max(
                220.0,
                constraints.maxHeight * 0.34,
              );

              return ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _CompactNoteActionButton(
                        icon: Icons.copy_rounded,
                        label: 'Copy',
                        onTap: _copyNote,
                        outlined: true,
                        textColor: textColor,
                        borderColor: borderColor,
                      ),
                      _CompactNoteActionButton(
                        icon: Icons.format_quote_rounded,
                        label: 'Quote',
                        onTap: _makeQuote,
                        gradient: true,
                        textColor: Colors.white,
                        borderColor: borderColor,
                      ),
                      _CompactNoteActionButton(
                        icon: Icons.add_rounded,
                        label: 'New',
                        onTap: _createNewNote,
                        outlined: true,
                        textColor: textColor,
                        borderColor: borderColor,
                      ),
                      _CompactNoteActionButton(
                        icon: Icons.folder_open_rounded,
                        label: 'Open',
                        onTap: _openExistingNotePicker,
                        outlined: true,
                        textColor: textColor,
                        borderColor: borderColor,
                      ),
                      _CompactNoteActionButton(
                        icon: Icons.save_rounded,
                        label: 'Save',
                        onTap: _saveNow,
                        gradient: true,
                        textColor: Colors.white,
                        borderColor: borderColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _saveLabel,
                          style: TextStyle(
                            color: subtleColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: panelColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextField(
                      controller: _titleController,
                      onChanged: (_) => _onTextChanged(),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Note title',
                        hintStyle: TextStyle(color: subtleColor),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    constraints: BoxConstraints(minHeight: editorMinHeight),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: panelColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextField(
                      controller: _contentController,
                      focusNode: _contentFocusNode,
                      onChanged: (_) => _onTextChanged(),
                      minLines: 12,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(
                        color: textColor,
                        height: 1.45,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Write your note here while the player continues behind...',
                        hintStyle: TextStyle(color: subtleColor),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _CompactNoteActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;
  final bool gradient;
  final Color textColor;
  final Color borderColor;

  const _CompactNoteActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.textColor,
    required this.borderColor,
    this.outlined = false,
    this.gradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = gradient
        ? BoxDecoration(
            gradient: _playerAccentGradient,
            borderRadius: BorderRadius.circular(14),
          )
        : BoxDecoration(
            color: outlined ? Colors.transparent : const Color(0xFF111938),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          );

    return DecoratedBox(
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: textColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerDockedBibleView extends StatefulWidget {
  const PlayerDockedBibleView({super.key});

  @override
  State<PlayerDockedBibleView> createState() => _PlayerDockedBibleViewState();
}

class _PlayerDockedBibleViewState extends State<PlayerDockedBibleView> {
  final BibleStore _store = BibleStore();
  final ScrollController _scrollController = ScrollController();

  String _bookName = '';
  int _chapter = 1;
  int _focusVerse = 0;
  bool _loading = true;
  bool _readingSavedForThisChapter = false;
  bool _focusScrollDone = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    _readingSavedForThisChapter = false;
    _focusScrollDone = false;

    await _store.init();

    final lastReading = _store.lastReading;
    if (lastReading != null &&
        lastReading.book.trim().isNotEmpty &&
        _store.findBook(lastReading.book) != null) {
      _bookName = lastReading.book;
      _chapter = lastReading.chapter < 1 ? 1 : lastReading.chapter;
      _focusVerse = lastReading.verse < 1 ? 0 : lastReading.verse;
    } else if (_store.books.isNotEmpty) {
      _bookName = _store.books.first.name;
      _chapter = 1;
      _focusVerse = 0;
    } else {
      _bookName = 'Genesis';
      _chapter = 1;
      _focusVerse = 0;
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _goToChapter({
    required String book,
    required int chapter,
    int verse = 0,
  }) {
    if (!mounted) return;

    setState(() {
      _bookName = book;
      _chapter = chapter < 1 ? 1 : chapter;
      _focusVerse = verse < 1 ? 0 : verse;
      _focusScrollDone = false;
      _readingSavedForThisChapter = false;
    });
  }

  Future<void> _pickBook() async {
    final isLight = ThemeController.instance.isLightMode;

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor:
          isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final oldBooks = _store.oldTestamentBooks;
        final newBooks = _store.newTestamentBooks;

        return SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              Text(
                'Old Testament',
                style: TextStyle(
                  color: isLight ? const Color(0xFF1E1B16) : Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              ...oldBooks.map(
                (book) => ListTile(
                  title: Text(
                    book.name,
                    style: TextStyle(
                      color:
                          isLight ? const Color(0xFF1E1B16) : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, book.name),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'New Testament',
                style: TextStyle(
                  color: isLight ? const Color(0xFF1E1B16) : Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              ...newBooks.map(
                (book) => ListTile(
                  title: Text(
                    book.name,
                    style: TextStyle(
                      color:
                          isLight ? const Color(0xFF1E1B16) : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, book.name),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || selected.trim().isEmpty) return;

    _goToChapter(book: selected, chapter: 1);
  }

  Future<void> _pickChapter() async {
    final isLight = ThemeController.instance.isLightMode;
    final count = await _store.chapterCountForBook(_bookName);
    if (count <= 0) return;

    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor:
          isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: GridView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.35,
            ),
            itemCount: count,
            itemBuilder: (context, index) {
              final chapterNumber = index + 1;
              final selectedChapter = chapterNumber == _chapter;

              return Material(
                color: selectedChapter
                    ? const Color(0xFFFF2C96)
                    : (isLight
                        ? const Color(0xFFF2E8D8)
                        : const Color(0xFF151C3A)),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.pop(context, chapterNumber),
                  child: Center(
                    child: Text(
                      '$chapterNumber',
                      style: TextStyle(
                        color: selectedChapter
                            ? Colors.white
                            : (isLight
                                ? const Color(0xFF1E1B16)
                                : Colors.white),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (selected == null) return;
    _goToChapter(book: _bookName, chapter: selected);
  }

  void _openFullBible() {
    context.push('/tools/bible');
  }

  Future<void> _persistReadingPositionIfNeeded(List<BibleVerse> verses) async {
    if (_readingSavedForThisChapter || verses.isEmpty) return;

    final verseToSave = _focusVerse > 0
        ? verses.firstWhere(
            (item) => item.verse == _focusVerse,
            orElse: () => verses.first,
          )
        : verses.first;

    _readingSavedForThisChapter = true;
    await _store.setLastReading(verseToSave);
    if (!mounted) return;
    setState(() {});
  }

  void _ensureFocusedVerseVisible(int verseIndex) {
    if (_focusVerse <= 0) return;
    if (_focusScrollDone) return;
    if (!_scrollController.hasClients) return;

    _focusScrollDone = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_scrollController.hasClients) return;

      const estimatedTileHeight = 110.0;
      final targetOffset = verseIndex * estimatedTileHeight;
      final maxExtent = _scrollController.position.maxScrollExtent;
      final safeOffset = targetOffset.clamp(0.0, maxExtent);

      await Future<void>.delayed(const Duration(milliseconds: 120));

      if (!mounted || !_scrollController.hasClients) return;

      await _scrollController.animateTo(
        safeOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _openVerseActions(BibleVerse verse) async {
    final isLight = ThemeController.instance.isLightMode;

    final result = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  verse.reference,
                  style: TextStyle(
                    color: isLight ? const Color(0xFF1E1B16) : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  verse.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isLight
                        ? const Color(0xFF4C453A)
                        : Colors.white.withOpacity(0.82),
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _VerseActionTile(
                  isLight: isLight,
                  icon: Icons.copy_rounded,
                  label: 'Copy Verse',
                  onTap: () =>
                      Navigator.pop(context, _actionPayload('copy', verse)),
                ),
                _VerseActionTile(
                  isLight: isLight,
                  icon: Icons.note_add_rounded,
                  label: 'Add to Note',
                  onTap: () =>
                      Navigator.pop(context, _actionPayload('note', verse)),
                ),
                _VerseActionTile(
                  isLight: isLight,
                  icon: Icons.format_quote_rounded,
                  label: 'Make Quote',
                  onTap: () =>
                      Navigator.pop(context, _actionPayload('quote', verse)),
                ),
                _VerseActionTile(
                  isLight: isLight,
                  icon: _store.isBookmarked(verse)
                      ? Icons.bookmark_remove_rounded
                      : Icons.bookmark_rounded,
                  label: _store.isBookmarked(verse)
                      ? 'Remove Bookmark'
                      : 'Bookmark Verse',
                  onTap: () =>
                      Navigator.pop(context, _actionPayload('bookmark', verse)),
                ),
                _VerseActionTile(
                  isLight: isLight,
                  icon: Icons.share_rounded,
                  label: 'Share Verse',
                  onTap: () =>
                      Navigator.pop(context, _actionPayload('share', verse)),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || result == null) return;

    String action = '';
    String reference = verse.reference;
    String verseText = verse.text;

    if (result is String) {
      action = result.trim().toLowerCase();
    } else if (result is Map) {
      action = (result['action'] ?? '').toString().trim().toLowerCase();
      final incomingRef = (result['reference'] ?? '').toString().trim();
      final incomingVerse = (result['verse'] ?? '').toString().trim();

      if (incomingRef.isNotEmpty) {
        reference = incomingRef;
      }
      if (incomingVerse.isNotEmpty) {
        verseText = incomingVerse;
      }
    }

    if (action.isEmpty) return;

    final text = '$reference\n\n$verseText';

    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verse copied')),
      );
      return;
    }

    if (action == 'note') {
      context.push(
        '/tools/notes/editor',
        extra: <String, dynamic>{
          'insertScripture': <String, dynamic>{
            'ref': reference,
            'verse': verseText,
          },
          'sourceType': 'bible',
          'sourceId': reference,
          'title': reference,
        },
      );
      return;
    }

    if (action == 'quote') {
      context.push(
        '/tools/quote',
        extra: <String, dynamic>{
          'designData': <String, dynamic>{
            'quote': verseText,
            'author': reference,
            'source_type': 'bible',
            'source_id': reference,
          },
        },
      );
      return;
    }

    if (action == 'bookmark') {
      await _store.toggleBookmark(verse);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _store.isBookmarked(verse)
                ? 'Verse bookmarked'
                : 'Bookmark removed',
          ),
        ),
      );
      return;
    }

    if (action == 'share') {
      await Share.share(text);
    }
  }

  Map<String, dynamic> _actionPayload(String action, BibleVerse verse) {
    return <String, dynamic>{
      'action': action,
      'reference': verse.reference,
      'verse': verse.text,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final isLight = ThemeController.instance.isLightMode;
        final book = _store.findBook(_bookName);
        final textColor =
            isLight ? const Color(0xFF1E1B16) : Colors.white;
        final subtleColor = isLight
            ? const Color(0xFF6B6256)
            : Colors.white.withOpacity(0.68);
        final borderColor = isLight
            ? const Color(0xFFE6D8C3)
            : Colors.white.withOpacity(0.08);

        if (_loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (book == null) {
          return Container(
            color: isLight ? const Color(0xFFF7F1E6) : const Color(0xFF070B18),
            alignment: Alignment.center,
            child: Text(
              'Unable to open chapter.',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        }

        return Container(
          color: isLight ? const Color(0xFFF7F1E6) : const Color(0xFF070B18),
          child: FutureBuilder<List<BibleVerse>>(
            future: _store.versesForChapter(
              bookName: _bookName,
              chapter: _chapter,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Unable to load this chapter.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }

              final verses = snapshot.data ?? const <BibleVerse>[];

              if (verses.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _persistReadingPositionIfNeeded(verses);
                });
              }

              if (_focusVerse > 0 && verses.isNotEmpty) {
                final focusedIndex = verses.indexWhere(
                  (item) => item.verse == _focusVerse,
                );
                if (focusedIndex >= 0) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _ensureFocusedVerseVisible(focusedIndex);
                  });
                }
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${book.name} $_chapter',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                gradient: _playerAccentGradient,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _store.translation,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickBook,
                                icon: const Icon(Icons.menu_book_rounded),
                                label: Text(
                                  book.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textColor,
                                  side: BorderSide(color: borderColor),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickChapter,
                                icon: const Icon(
                                  Icons.format_list_numbered_rounded,
                                ),
                                label: Text('Chapter $_chapter'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textColor,
                                  side: BorderSide(color: borderColor),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: _playerAccentGradient,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: _openFullBible,
                                  child: const SizedBox(
                                    width: 52,
                                    height: 52,
                                    child: Icon(
                                      Icons.search_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: verses.isEmpty
                        ? Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                'No verses found for this chapter yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: subtleColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                            itemCount: verses.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final verse = verses[index];
                              final isFocused = _focusVerse > 0 &&
                                  verse.verse == _focusVerse;

                              return _VerseTile(
                                isLight: isLight,
                                verse: verse,
                                focused: isFocused,
                                onTap: () => _openVerseActions(verse),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.14),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.84),
                  fontSize: 11.6,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerseTile extends StatelessWidget {
  const _VerseTile({
    required this.isLight,
    required this.verse,
    required this.focused,
    required this.onTap,
  });

  final bool isLight;
  final BibleVerse verse;
  final bool focused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = focused
        ? const Color(0xFFFF2C96)
        : (isLight
            ? const Color(0xFFE6D8C3)
            : Colors.white.withOpacity(0.08));

    final tileColor = focused
        ? (isLight ? const Color(0xFFFFF3F9) : const Color(0xFF18163A))
        : (isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430));

    final textColor =
        isLight ? const Color(0xFF2E2A24) : Colors.white.withOpacity(0.94);

    return Material(
      color: tileColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: focused ? 1.8 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: focused ? _playerAccentGradient : null,
                  color: focused
                      ? null
                      : (isLight
                          ? const Color(0xFFF2E8D8)
                          : Colors.white.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Text(
                      '${verse.verse}',
                      style: TextStyle(
                        color: focused
                            ? Colors.white
                            : (isLight
                                ? const Color(0xFF3C3428)
                                : Colors.white),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  verse.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerseActionTile extends StatelessWidget {
  const _VerseActionTile({
    required this.isLight,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool isLight;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Icon(
        icon,
        color: isLight ? const Color(0xFF3C3428) : Colors.white,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isLight ? const Color(0xFF1E1B16) : Colors.white,
          fontWeight: FontWeight.w800,
        ),
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
