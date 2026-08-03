import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../features/notes/models/note_model.dart';
import '../../../features/notes/state/notes_store.dart';
import '../../../theme/theme_controller.dart';
import '../../../widgets/banner_ad_widget.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final NotesStore _store = NotesStore();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late final NotesAutosaveController _autosave;

  NoteModel? _note;
  String _saveLabel = 'Saved';
  bool _loading = true;
  bool _attaching = false;
  bool _bootstrapped = false;
  String _sourceType = 'manual';
  String _sourceId = '';

  @override
  void initState() {
    super.initState();
    _autosave = NotesAutosaveController(onSave: _saveSilently);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    _loadFromRoute();
  }

  Future<void> _loadFromRoute() async {
    await _store.init();

    final extra = GoRouterState.of(context).extra;
    final extraMap = extra is Map ? extra : const <String, dynamic>{};

    final noteId = (extraMap['noteId'] ?? '').toString();
    final sourceType = (extraMap['sourceType'] ?? 'manual').toString();
    final sourceId = (extraMap['sourceId'] ?? '').toString();
    final requestedTitle = (extraMap['title'] ?? '').toString().trim();
    final prefill = (extraMap['prefill'] ?? '').toString().trim();

    Map? insertScripture = extraMap['insertScripture'] is Map
        ? extraMap['insertScripture'] as Map
        : null;

    if (insertScripture == null) {
      final reference = (extraMap['reference'] ?? '').toString().trim();
      final verse = (extraMap['verse'] ?? '').toString().trim();
      if (reference.isNotEmpty || verse.isNotEmpty) {
        insertScripture = {
          'ref': reference,
          'verse': verse,
        };
      }
    }

    if (noteId.isEmpty) {
      _note = await _store.createEmptyNote(
        sourceType: sourceType,
        sourceId: sourceId,
      );
    } else {
      _note = _store.findNoteById(noteId);
      _note ??= await _store.createEmptyNote(
        sourceType: sourceType,
        sourceId: sourceId,
      );
    }

    _sourceType = _note?.sourceType ?? sourceType;
    _sourceId = _note?.sourceId ?? sourceId;

    _titleController.text = _note?.title ?? '';
    _contentController.text = _note?.content ?? '';

    if (_titleController.text.trim().isEmpty && requestedTitle.isNotEmpty) {
      _titleController.text = requestedTitle;
    }

    if (insertScripture != null) {
      final ref = (insertScripture['ref'] ?? insertScripture['reference'] ?? '')
          .toString()
          .trim();
      final verse = (insertScripture['verse'] ?? '').toString().trim();
      final scriptureBlock = _buildScriptureBlock(ref: ref, verse: verse);

      if (scriptureBlock.trim().isNotEmpty) {
        final existing = _contentController.text.trimRight();
        final alreadyPresent = existing.contains(scriptureBlock.trim());

        if (!alreadyPresent) {
          _contentController.text = existing.isEmpty
              ? scriptureBlock.trim()
              : '$existing\n\n${scriptureBlock.trim()}';
        }
      }
    }

    if (prefill.isNotEmpty) {
      final existing = _contentController.text.trimRight();
      final alreadyPresent = existing.contains(prefill);

      if (!alreadyPresent) {
        _contentController.text =
            existing.isEmpty ? prefill : '$existing\n\n$prefill';
      }
    }

    await _saveSilently();

    if (!mounted) return;
    setState(() => _loading = false);
  }

  String _buildScriptureBlock({
    required String ref,
    required String verse,
  }) {
    final cleanRef = ref.trim();
    final cleanVerse = verse.trim();

    if (cleanRef.isEmpty && cleanVerse.isEmpty) return '';

    if (cleanRef.isNotEmpty && cleanVerse.isNotEmpty) {
      return '$cleanRef\n$cleanVerse';
    }

    return cleanRef.isNotEmpty ? cleanRef : cleanVerse;
  }

  @override
  void dispose() {
    _autosave.dispose();
    _titleController.dispose();
    _contentController.dispose();
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
      category: current.category,
      sourceType: current.sourceType.isEmpty ? _sourceType : current.sourceType,
      sourceId: current.sourceId.isEmpty ? _sourceId : current.sourceId,
    );

    await _store.saveNote(updated);
    _note = _store.findNoteById(updated.id) ?? updated;

    _sourceType = _note?.sourceType ?? _sourceType;
    _sourceId = _note?.sourceId ?? _sourceId;

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

  Future<void> _pickCategory() async {
    final categories = _store.categories;
    final current = _note;
    if (current == null) return;

    final isLight = ThemeController.instance.isLightMode;

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor:
          isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0B1020),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: categories.map((category) {
              return ListTile(
                title: Text(
                  category.name,
                  style: TextStyle(
                    color: isLight ? const Color(0xFF1E1B16) : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: current.category == category.name
                    ? Icon(
                        Icons.check_rounded,
                        color: isLight ? const Color(0xFF1E1B16) : Colors.white,
                      )
                    : null,
                onTap: () => Navigator.pop(context, category.name),
              );
            }).toList(),
          ),
        );
      },
    );

    if (selected == null) return;

    _note = current.copyWith(category: selected);
    await _saveSilently();

    if (!mounted) return;
    setState(() {});
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

  String _selectedTextOnly() {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (!selection.isValid || selection.isCollapsed) {
      return '';
    }

    final start =
        selection.start < selection.end ? selection.start : selection.end;
    final end =
        selection.start < selection.end ? selection.end : selection.start;

    if (start < 0 || end > text.length) return '';

    return text.substring(start, end).trim();
  }

  Future<void> _addSelectedAsKeyLine() async {
    final current = _note;
    if (current == null) return;

    final selected = _selectedTextOrWholeNote().trim();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select text or write something first')),
      );
      return;
    }

    final synced = current.copyWith(
      title: _titleController.text,
      content: _contentController.text,
    );

    await _store.saveNote(synced);
    _note = _store.findNoteById(synced.id) ?? synced;
    await _store.addKeyLine(note: _note!, text: selected);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to Key Lines')),
    );
  }

  Future<void> _insertScripture() async {
    final refController = TextEditingController();
    final verseController = TextEditingController();
    final isLight = ThemeController.instance.isLightMode;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430),
          title: Text(
            'Insert Scripture',
            style: TextStyle(
              color: isLight ? const Color(0xFF1E1B16) : Colors.white,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: refController,
                style: TextStyle(
                  color: isLight ? const Color(0xFF1E1B16) : Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Reference e.g. Romans 8:28',
                  hintStyle: TextStyle(
                    color: isLight ? const Color(0xFF8A7C68) : Colors.white54,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: verseController,
                maxLines: 4,
                style: TextStyle(
                  color: isLight ? const Color(0xFF1E1B16) : Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Optional verse text',
                  hintStyle: TextStyle(
                    color: isLight ? const Color(0xFF8A7C68) : Colors.white54,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  {
                    'ref': refController.text.trim(),
                    'verse': verseController.text.trim(),
                  },
                );
              },
              child: const Text('Insert'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    final ref = (result['ref'] ?? '').trim();
    final verse = (result['verse'] ?? '').trim();

    if (ref.isEmpty && verse.isEmpty) return;

    final insertText = _buildScriptureBlock(ref: ref, verse: verse);
    _insertAtCursor(insertText);
    _onTextChanged();
  }

  void _insertAtCursor(String value) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;

    final safeStart = start.clamp(0, text.length);
    final safeEnd = end.clamp(0, text.length);

    final shouldPrefixNewLine = text.isNotEmpty &&
        safeStart > 0 &&
        !text.substring(0, safeStart).endsWith('\n');
    final insertion = shouldPrefixNewLine ? '\n$value' : value;
    final newText = text.replaceRange(safeStart, safeEnd, insertion);

    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (safeStart + insertion.length).clamp(0, newText.length),
      ),
    );
  }

  void _applySimpleFormat() {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (!selection.isValid || selection.isCollapsed) {
      _insertAtCursor('• ');
      _onTextChanged();
      return;
    }

    final start =
        selection.start < selection.end ? selection.start : selection.end;
    final end =
        selection.start < selection.end ? selection.end : selection.start;

    final selected = text.substring(start, end);
    final replaced = text.replaceRange(start, end, '**$selected**');

    _contentController.value = TextEditingValue(
      text: replaced,
      selection: TextSelection.collapsed(
        offset: (end + 4).clamp(0, replaced.length),
      ),
    );

    _onTextChanged();
  }

  Future<void> _shareOrCopyNote() async {
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
      const SnackBar(content: Text('Note copied for sharing')),
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

  Future<void> _attachMedia() async {
    if (_attaching) return;

    setState(() => _attaching = true);

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked == null) {
        if (!mounted) return;
        setState(() => _attaching = false);
        return;
      }

      final bytes = await picked.readAsBytes();
      final dataUri = _bytesToDataUri(bytes, picked.mimeType);

      final current = _note;
      if (current == null) {
        if (!mounted) return;
        setState(() => _attaching = false);
        return;
      }

      final existing = List<String>.from(current.attachments);
      if (!existing.contains(dataUri)) {
        existing.add(dataUri);
      }

      final updated = current.copyWith(attachments: existing);

      await _store.saveNote(updated);
      _note = _store.findNoteById(updated.id) ?? updated;

      if (!mounted) return;
      setState(() => _attaching = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attachment added')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _attaching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to attach image')),
      );
    }
  }

  Future<void> _removeAttachmentAt(int index) async {
    final current = _note;
    if (current == null) return;
    if (index < 0 || index >= current.attachments.length) return;

    final updatedAttachments = List<String>.from(current.attachments)
      ..removeAt(index);

    final updated = current.copyWith(attachments: updatedAttachments);

    await _store.saveNote(updated);
    _note = _store.findNoteById(updated.id) ?? updated;

    if (!mounted) return;
    setState(() {});
  }

  String _bytesToDataUri(Uint8List bytes, String? mimeType) {
    final mime = (mimeType == null || mimeType.trim().isEmpty)
        ? 'image/jpeg'
        : mimeType.trim();
    final encoded = base64Encode(bytes);
    return 'data:$mime;base64,$encoded';
  }

  String _sourceLabel() {
    switch (_sourceType.trim().toLowerCase()) {
      case 'bible':
        return 'From Bible';
      case 'article':
        return 'From Article';
      case 'quote':
        return 'From Quote';
      case 'manual':
      default:
        return 'Manual Note';
    }
  }

  Color _panelColor(bool isLight) {
    return isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430);
  }

  Color _secondaryPanelColor(bool isLight) {
    return isLight ? const Color(0xFFF7F1E6) : const Color(0xFF0A1027);
  }

  Color _borderColor(bool isLight) {
    return isLight ? const Color(0xFFE6D8C3) : Colors.white.withOpacity(0.08);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final note = _note;

    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final isLight = ThemeController.instance.isLightMode;

        return Scaffold(
          appBar: DxmTopBar(
            title: 'Note Editor',
            showBack: true,
            showMenu: true,
            onBack: () async {
              await _saveSilently();
              if (!mounted) return;
              context.pop();
            },
          ),
          body: GradientPageBackground(
            child: _loading || note == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _panelColor(isLight),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: _borderColor(isLight),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: _titleController,
                                    onChanged: (_) => _onTextChanged(),
                                    style: TextStyle(
                                      color: isLight
                                          ? const Color(0xFF1E1B16)
                                          : Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Note title',
                                      hintStyle: TextStyle(
                                        color: isLight
                                            ? const Color(0xFF8A7C68)
                                            : Colors.white.withOpacity(0.45),
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _InfoPill(
                                        label: _note?.category ?? 'General',
                                        isLight: isLight,
                                      ),
                                      _InfoPill(
                                        label: _sourceLabel(),
                                        isLight: isLight,
                                      ),
                                      if (_sourceId.trim().isNotEmpty)
                                        _InfoPill(
                                          label: _sourceId.length > 28
                                              ? '${_sourceId.substring(0, 28)}...'
                                              : _sourceId,
                                          isLight: isLight,
                                        ),
                                      _InfoPill(
                                        label: _saveLabel,
                                        isLight: isLight,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _pickCategory,
                                          icon: const Icon(
                                            Icons.category_rounded,
                                          ),
                                          label: Text(
                                              _note?.category ?? 'General'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: isLight
                                                ? const Color(0xFF1E1B16)
                                                : Colors.white,
                                            side: BorderSide(
                                              color: isLight
                                                  ? const Color(0xFFE0D0BC)
                                                  : Colors.white
                                                      .withOpacity(0.18),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _shareOrCopyNote,
                                          icon: const Icon(Icons.share_rounded),
                                          label: const Text('Share'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: isLight
                                                ? const Color(0xFF1E1B16)
                                                : Colors.white,
                                            side: BorderSide(
                                              color: isLight
                                                  ? const Color(0xFFE0D0BC)
                                                  : Colors.white
                                                      .withOpacity(0.18),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _secondaryPanelColor(isLight),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: _borderColor(isLight),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quick Actions',
                                    style: TextStyle(
                                      color: isLight
                                          ? const Color(0xFF1E1B16)
                                          : Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 44,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: [
                                        _ToolbarChip(
                                          icon: Icons.format_bold_rounded,
                                          label: 'Format',
                                          onTap: _applySimpleFormat,
                                          isLight: isLight,
                                        ),
                                        const SizedBox(width: 8),
                                        _ToolbarChip(
                                          icon: Icons.highlight_rounded,
                                          label: 'Highlight',
                                          onTap: _addSelectedAsKeyLine,
                                          isLight: isLight,
                                        ),
                                        const SizedBox(width: 8),
                                        _ToolbarChip(
                                          icon: Icons.menu_book_rounded,
                                          label: 'Insert Scripture',
                                          onTap: _insertScripture,
                                          isLight: isLight,
                                        ),
                                        const SizedBox(width: 8),
                                        _ToolbarChip(
                                          icon: Icons.format_quote_rounded,
                                          label: 'Make Quote',
                                          onTap: _makeQuote,
                                          isLight: isLight,
                                        ),
                                        const SizedBox(width: 8),
                                        _ToolbarChip(
                                          icon: Icons.attach_file_rounded,
                                          label: _attaching
                                              ? 'Attaching...'
                                              : 'Attach',
                                          onTap:
                                              _attaching ? () {} : _attachMedia,
                                          isLight: isLight,
                                        ),
                                        const SizedBox(width: 8),
                                        _ToolbarChip(
                                          icon: Icons.copy_rounded,
                                          label: 'Copy',
                                          onTap: _shareOrCopyNote,
                                          isLight: isLight,
                                        ),
                                        const SizedBox(width: 8),
                                        _ToolbarChip(
                                          icon: Icons.save_rounded,
                                          label: 'Save Now',
                                          onTap: _saveNow,
                                          isLight: isLight,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (note.attachments.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _panelColor(isLight),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: _borderColor(isLight),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Attachments',
                                      style: TextStyle(
                                        color: isLight
                                            ? const Color(0xFF1E1B16)
                                            : Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 92,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: note.attachments.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 10),
                                        itemBuilder: (context, index) {
                                          final item = note.attachments[index];
                                          return _AttachmentPreviewCard(
                                            data: item,
                                            onRemove: () =>
                                                _removeAttachmentAt(index),
                                            isLight: isLight,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Container(
                              decoration: BoxDecoration(
                                color: _panelColor(isLight),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: _borderColor(isLight),
                                ),
                              ),
                              padding: const EdgeInsets.all(14),
                              child: TextField(
                                controller: _contentController,
                                onChanged: (_) => _onTextChanged(),
                                maxLines: null,
                                minLines: 18,
                                keyboardType: TextInputType.multiline,
                                style: TextStyle(
                                  color: isLight
                                      ? const Color(0xFF1E1B16)
                                      : Colors.white,
                                  height: 1.45,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Write your note here...\n\nUse this as your sermon note space, study workspace, prayer journal, or reflection area.',
                                  hintStyle: TextStyle(
                                    color: isLight
                                        ? const Color(0xFF8A7C68)
                                        : Colors.white.withOpacity(0.42),
                                  ),
                                  border: InputBorder.none,
                                ),
                                contextMenuBuilder:
                                    (context, editableTextState) {
                                  final items =
                                      editableTextState.contextMenuButtonItems;
                                  final selectedText = _selectedTextOnly();

                                  return AdaptiveTextSelectionToolbar
                                      .buttonItems(
                                    anchors:
                                        editableTextState.contextMenuAnchors,
                                    buttonItems: [
                                      ...items,
                                      if (selectedText.isNotEmpty)
                                        ContextMenuButtonItem(
                                          label: 'Key Line',
                                          onPressed: () {
                                            ContextMenuController.removeAny();
                                            _addSelectedAsKeyLine();
                                          },
                                        ),
                                      if (selectedText.isNotEmpty)
                                        ContextMenuButtonItem(
                                          label: 'Quote',
                                          onPressed: () {
                                            ContextMenuController.removeAny();
                                            _makeQuote();
                                          },
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!keyboardOpen)
                        const SafeArea(
                          top: false,
                          child: BannerAdWidget(tabKey: 'explore:notes.editor'),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _ToolbarChip extends StatelessWidget {
  const _ToolbarChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isLight,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      backgroundColor:
          isLight ? const Color(0xFFF2E8D8) : const Color(0xFF151C3A),
      side: BorderSide(
        color:
            isLight ? const Color(0xFFE0D0BC) : Colors.white.withOpacity(0.10),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      avatar: Icon(
        icon,
        size: 18,
        color: isLight ? const Color(0xFF1E1B16) : Colors.white,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isLight ? const Color(0xFF1E1B16) : Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.isLight,
  });

  final String label;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color:
            isLight ? const Color(0xFFF2E8D8) : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isLight
              ? const Color(0xFF4C453A)
              : Colors.white.withOpacity(0.82),
          fontSize: 11.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AttachmentPreviewCard extends StatelessWidget {
  const _AttachmentPreviewCard({
    required this.data,
    required this.onRemove,
    required this.isLight,
  });

  final String data;
  final VoidCallback onRemove;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 92,
            height: 92,
            color: isLight ? const Color(0xFFF2E8D8) : const Color(0xFF151C3A),
            child: _AttachmentImage(data: data, isLight: isLight),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.close,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AttachmentImage extends StatelessWidget {
  const _AttachmentImage({
    required this.data,
    required this.isLight,
  });

  final String data;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final trimmed = data.trim();
    final fallbackColor = isLight ? const Color(0xFF8A7C68) : Colors.white54;

    if (trimmed.isEmpty) {
      return Center(
        child: Icon(Icons.image_not_supported_rounded, color: fallbackColor),
      );
    }

    if (trimmed.startsWith('data:image')) {
      try {
        final base64Part = trimmed.split(',').last;
        final bytes = base64Decode(base64Part);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Center(
              child: Icon(Icons.broken_image_rounded, color: fallbackColor),
            );
          },
        );
      } catch (_) {
        return Center(
          child: Icon(Icons.broken_image_rounded, color: fallbackColor),
        );
      }
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Center(
            child: Icon(Icons.broken_image_rounded, color: fallbackColor),
          );
        },
      );
    }

    return Center(
      child: Icon(Icons.image_outlined, color: fallbackColor),
    );
  }
}
