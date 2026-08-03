import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../features/notes/models/note_model.dart';
import '../../../features/notes/state/notes_store.dart';
import '../../../services/ads_service.dart';
import '../../widgets/gradient_page_background.dart';

class NoteFavoritesScreen extends StatefulWidget {
  const NoteFavoritesScreen({super.key});

  @override
  State<NoteFavoritesScreen> createState() => _NoteFavoritesScreenState();
}

class _NoteFavoritesScreenState extends State<NoteFavoritesScreen> {
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _store.init();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Future<void> _copyKeyLine(NoteKeyLineModel item) async {
    await Clipboard.setData(ClipboardData(text: item.text.trim()));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Key line copied')),
    );
  }

  void _makeQuote(NoteKeyLineModel item) {
    context.push(
      '/tools/quote',
      extra: {
        'designData': {
          'quote': item.text.trim(),
          'author': item.noteTitle.trim().isEmpty ? 'My Note' : item.noteTitle.trim(),
          'source_type': 'key_line',
          'source_id': item.id,
        },
      },
    );
  }

  Future<void> _addBackToNote(NoteKeyLineModel item) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0B1020),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              const Text(
                'Add back to note',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                onTap: () => Navigator.pop(context, '__create__'),
                leading: const Icon(Icons.add_rounded, color: Colors.white),
                title: const Text(
                  'Create new note',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
              ..._store.notes.map((note) {
                return ListTile(
                  onTap: () => Navigator.pop(context, note.id),
                  leading: const Icon(Icons.note_alt_rounded, color: Colors.white70),
                  title: Text(
                    note.title.trim().isEmpty ? 'Untitled Note' : note.title.trim(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    note.category,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.60),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );

    if (selected == null) return;

    if (selected == '__create__') {
      final note = await _store.createEmptyNote(category: item.category);
      await _store.appendTextToNote(noteId: note.id, text: item.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to new note')),
      );
      return;
    }

    await _store.appendTextToNote(noteId: selected, text: item.text.trim());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added back to note')),
    );
  }

  Future<void> _openSourceNote(NoteKeyLineModel item) async {
    final note = _store.findNoteById(item.noteId);
    if (note == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source note no longer exists')),
      );
      return;
    }

    await context.push('/tools/notes/detail', extra: {'noteId': note.id});
    await _load();
  }

  List<Widget> _buildList() {
    final widgets = <Widget>[];

    for (var i = 0; i < _store.keyLines.length; i++) {
      final item = _store.keyLines[i];

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _KeyLineCard(
            item: item,
            onQuote: () => _makeQuote(item),
            onCopy: () => _copyKeyLine(item),
            onAddBack: () => _addBackToNote(item),
            onOpenSource: () => _openSourceNote(item),
            onDelete: () => _store.deleteKeyLine(item.id),
          ),
        ),
      );

      if (AdsService.instance.shouldInsertNativeAfterItem(
        tabKey: 'explore',
        itemIndex: i,
      )) {
        widgets.add(const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: _NativeAdPlaceholderCard(),
        ));
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
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
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Favorites / Key Lines',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
          body: GradientPageBackground(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _store.keyLines.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome_rounded, color: Colors.white70, size: 46),
                              const SizedBox(height: 12),
                              const Text(
                                'No key lines yet',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Select text inside a note and save it as a highlighted key line for quick quote creation later.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.70),
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                        children: _buildList(),
                      ),
          ),
        );
      },
    );
  }
}

class _KeyLineCard extends StatelessWidget {
  const _KeyLineCard({
    required this.item,
    required this.onQuote,
    required this.onCopy,
    required this.onAddBack,
    required this.onOpenSource,
    required this.onDelete,
  });

  final NoteKeyLineModel item;
  final VoidCallback onQuote;
  final VoidCallback onCopy;
  final VoidCallback onAddBack;
  final VoidCallback onOpenSource;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1430),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.text.trim(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaPill(label: item.noteTitle.trim().isEmpty ? 'Untitled Note' : item.noteTitle.trim()),
              _MetaPill(label: item.category),
              _MetaPill(label: _timeAgo(item.createdAt)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionChip(
                icon: Icons.format_quote_rounded,
                label: 'Make Quote',
                onTap: onQuote,
              ),
              _ActionChip(
                icon: Icons.copy_rounded,
                label: 'Copy',
                onTap: onCopy,
              ),
              _ActionChip(
                icon: Icons.assignment_return_rounded,
                label: 'Add to Note',
                onTap: onAddBack,
              ),
              _ActionChip(
                icon: Icons.open_in_new_rounded,
                label: 'Open Note',
                onTap: onOpenSource,
              ),
              _ActionChip(
                icon: Icons.delete_rounded,
                label: 'Delete',
                onTap: onDelete,
                destructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _timeAgo(int value) {
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(value));
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
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

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.redAccent : Colors.white;

    return ActionChip(
      onPressed: onTap,
      backgroundColor: const Color(0xFF151C3A),
      side: BorderSide(color: Colors.white.withOpacity(0.10)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      avatar: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NativeAdPlaceholderCard extends StatelessWidget {
  const _NativeAdPlaceholderCard();

  @override
  Widget build(BuildContext context) {
    if (!AdsService.instance.nativeInListAllowedForTab('explore')) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1430),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_rounded, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sponsored content slot',
              style: TextStyle(
                color: Colors.white.withOpacity(0.82),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Ad',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
