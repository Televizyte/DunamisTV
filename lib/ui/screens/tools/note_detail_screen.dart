import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../features/notes/models/note_model.dart';
import '../../../features/notes/state/notes_store.dart';
import '../../../widgets/banner_ad_widget.dart';
import '../../widgets/gradient_page_background.dart';
import '../../widgets/scripture_preview_sheet.dart';

class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({super.key});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  static const _topGradient = LinearGradient(
    colors: [
      Color(0xFF1A1F5A),
      Color(0xFF5B1FA8),
      Color(0xFFB70E7C),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  final NotesStore _store = NotesStore();
  NoteModel? _note;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _store.init();

    final extra = GoRouterState.of(context).extra;
    final noteId = (extra is Map ? extra['noteId'] : null)?.toString() ?? '';

    _note = _store.findNoteById(noteId);

    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Future<void> _openEditor() async {
    final note = _note;
    if (note == null) return;

    await context.push('/tools/notes/editor', extra: {'noteId': note.id});
    await _load();
  }

  Future<void> _copyNote() async {
    final note = _note;
    if (note == null) return;

    final text = [
      if (note.title.trim().isNotEmpty) note.title.trim(),
      if (note.content.trim().isNotEmpty) note.content.trim(),
    ].join('\n\n');

    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note copied')),
    );
  }

  void _makeQuote() {
    final note = _note;
    if (note == null) return;

    final quoteText = note.content.trim().isNotEmpty
        ? note.content.trim()
        : note.title.trim();
    if (quoteText.isEmpty) return;

    context.push(
      '/tools/quote',
      extra: {
        'designData': {
          'quote': quoteText,
          'author': note.title.trim().isEmpty ? 'My Note' : note.title.trim(),
          'source_type': 'note',
          'source_id': note.id,
        },
      },
    );
  }

  Future<void> _openScripture(String ref) async {
    final result = await showModalBottomSheet<Object?>(
      context: context,
      backgroundColor: const Color(0xFF0E1430),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ScripturePreviewSheet(
          reference: ref,
          note: 'Detected from your note',
        );
      },
    );

    if (!mounted || result == null) return;

    String action = '';
    String reference = ref.trim();
    String verse = '';
    String previewNote = '';

    if (result is String) {
      action = result.trim().toLowerCase();
    } else if (result is Map) {
      action = (result['action'] ?? '').toString().trim().toLowerCase();

      final incomingRef = (result['reference'] ?? '').toString().trim();
      final incomingVerse = (result['verse'] ?? '').toString().trim();
      final incomingNote = (result['note'] ?? '').toString().trim();

      if (incomingRef.isNotEmpty) {
        reference = incomingRef;
      }
      verse = incomingVerse;
      previewNote = incomingNote;
    }

    if (action.isEmpty) return;

    if (action == 'open' || action == 'bible') {
      await context.push('/tools/bible', extra: {'ref': reference});
      return;
    }

    if (action == 'note') {
      await context.push(
        '/tools/notes/editor',
        extra: {
          'noteId': _note?.id ?? '',
          'insertScripture': {
            'ref': reference,
            'verse': verse,
          },
        },
      );
      await _load();
      return;
    }

    if (action == 'quote') {
      final quoteText = verse.trim().isNotEmpty ? verse.trim() : reference;

      context.push(
        '/tools/quote',
        extra: {
          'designData': {
            'quote': quoteText,
            'author': reference,
            'source_type': 'scripture',
            if (previewNote.trim().isNotEmpty)
              'source_note': previewNote.trim(),
          },
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = _note;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(gradient: _topGradient),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    note?.title.trim().isEmpty ?? true
                        ? 'Note Detail'
                        : note!.title.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: note == null ? null : _openEditor,
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
      body: GradientPageBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : note == null
                ? const Center(
                    child: Text(
                      'Note not found',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0E1430),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note.title.trim().isEmpty
                                        ? 'Untitled Note'
                                        : note.title.trim(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _MetaPill(label: note.category),
                                      _MetaPill(
                                        label: _formatDate(note.updatedAt),
                                      ),
                                      _MetaPill(
                                        label: 'Source: ${note.sourceType}',
                                      ),
                                      if (note.pinned)
                                        const _MetaPill(label: 'Pinned'),
                                      if (note.favorite)
                                        const _MetaPill(label: 'Favorite'),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    note.content.trim().isEmpty
                                        ? 'No content yet.'
                                        : note.content.trim(),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.92),
                                      fontSize: 14,
                                      height: 1.55,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (note.attachments.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0E1430),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Attachments',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
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
                                          return _AttachmentPreviewCard(
                                            data: note.attachments[index],
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (note.detectedScriptures.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0E1430),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Detected Scriptures',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children:
                                          note.detectedScriptures.map((ref) {
                                        return ActionChip(
                                          onPressed: () => _openScripture(ref),
                                          backgroundColor:
                                              const Color(0xFF151C3A),
                                          side: BorderSide(
                                            color:
                                                Colors.white.withOpacity(0.10),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          label: Text(
                                            ref,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _openEditor,
                                    icon: const Icon(Icons.edit_rounded),
                                    label: const Text('Edit'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.22),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _makeQuote,
                                    icon:
                                        const Icon(Icons.format_quote_rounded),
                                    label: const Text('Make Quote'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF2C96),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _copyNote,
                              icon: const Icon(Icons.copy_rounded),
                              label: const Text('Share / Copy'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.22),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SafeArea(
                        top: false,
                        child: BannerAdWidget(tabKey: 'explore:notes.detail'),
                      ),
                    ],
                  ),
      ),
    );
  }

  static String _formatDate(int value) {
    final dt = DateTime.fromMillisecondsSinceEpoch(value);
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.82),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AttachmentPreviewCard extends StatelessWidget {
  const _AttachmentPreviewCard({
    required this.data,
  });

  final String data;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 92,
        height: 92,
        color: const Color(0xFF151C3A),
        child: _AttachmentImage(data: data),
      ),
    );
  }
}

class _AttachmentImage extends StatelessWidget {
  const _AttachmentImage({required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    final trimmed = data.trim();

    if (trimmed.isEmpty) {
      return const Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          color: Colors.white54,
        ),
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
            return const Center(
              child: Icon(Icons.broken_image_rounded, color: Colors.white54),
            );
          },
        );
      } catch (_) {
        return const Center(
          child: Icon(Icons.broken_image_rounded, color: Colors.white54),
        );
      }
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.white54),
          );
        },
      );
    }

    return const Center(
      child: Icon(Icons.image_outlined, color: Colors.white54),
    );
  }
}
