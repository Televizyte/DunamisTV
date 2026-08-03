import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/notes/models/note_model.dart';
import '../../../features/notes/state/notes_store.dart';
import '../../../services/ads_service.dart';
import '../../../theme/theme_controller.dart';
import '../../../widgets/banner_ad_widget.dart';
import '../../widgets/gradient_page_background.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _store.init();
    _searchController.addListener(_handleSearchInputChanged);
    AdsService.instance.preloadInterstitial(tabKey: 'explore:notes');
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchInputChanged);
    _searchController.dispose();
    _store.dispose();
    super.dispose();
  }

  void _handleSearchInputChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openCreateNote() async {
    final note = await _store.createEmptyNote();
    if (!mounted) return;

    await context.push('/tools/notes/editor', extra: {'noteId': note.id});
    await _store.init();
  }

  Future<void> _openDetail(NoteModel note) async {
    await context.push('/tools/notes/detail', extra: {'noteId': note.id});
    await _store.init();
  }

  Future<void> _openCategories() async {
    await context.push('/tools/notes/categories');
    await _store.init();
  }

  Future<void> _openFavorites() async {
    await context.push('/tools/notes/favorites');
    await _store.init();
  }

  Future<void> _showNoteMenu(NoteModel note) async {
    final isLight = ThemeController.instance.isLightMode;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor:
          isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0B1020),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MenuTile(
                  icon: Icons.edit_rounded,
                  title: 'Open',
                  onTap: () => Navigator.pop(context, 'open'),
                  isLight: isLight,
                ),
                _MenuTile(
                  icon: note.pinned
                      ? Icons.push_pin_outlined
                      : Icons.push_pin_rounded,
                  title: note.pinned ? 'Unpin note' : 'Pin note',
                  onTap: () => Navigator.pop(context, 'pin'),
                  isLight: isLight,
                ),
                _MenuTile(
                  icon: note.favorite
                      ? Icons.star_border_rounded
                      : Icons.star_rounded,
                  title: note.favorite ? 'Remove favorite' : 'Mark favorite',
                  onTap: () => Navigator.pop(context, 'favorite'),
                  isLight: isLight,
                ),
                _MenuTile(
                  icon: Icons.delete_rounded,
                  title: 'Delete note',
                  destructive: true,
                  onTap: () => Navigator.pop(context, 'delete'),
                  isLight: isLight,
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'open':
        await _openDetail(note);
        break;
      case 'pin':
        await _store.togglePinned(note.id);
        break;
      case 'favorite':
        await _store.toggleFavorite(note.id);
        break;
      case 'delete':
        await _store.deleteNote(note.id);
        break;
    }
  }

  void _showMoreMenu() {
    final isLight = ThemeController.instance.isLightMode;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0B1020),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MenuTile(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Key Lines',
                  onTap: () {
                    Navigator.pop(context);
                    _openFavorites();
                  },
                  isLight: isLight,
                ),
                _MenuTile(
                  icon: Icons.category_rounded,
                  title: 'Manage Categories',
                  onTap: () {
                    Navigator.pop(context);
                    _openCategories();
                  },
                  isLight: isLight,
                ),
                _MenuTile(
                  icon: isLight
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  title:
                      isLight ? 'Switch to Dark Mode' : 'Switch to Light Mode',
                  onTap: () {
                    Navigator.pop(context);
                    ThemeController.instance.toggleTheme();
                  },
                  isLight: isLight,
                ),
                _MenuTile(
                  icon: Icons.add_rounded,
                  title: 'New Note',
                  onTap: () {
                    Navigator.pop(context);
                    _openCreateNote();
                  },
                  isLight: isLight,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _pageTextColor(bool isLight) {
    return isLight ? const Color(0xFF1E1B16) : Colors.white;
  }

  Color _pageSubtleColor(bool isLight) {
    return isLight ? const Color(0xFF6B6256) : Colors.white.withOpacity(0.68);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_store, ThemeController.instance]),
      builder: (context, _) {
        final isLight = ThemeController.instance.isLightMode;

        final pinnedNotes = _store.pinnedNotes;
        final recentNotes = _store.recentNotes;
        final mainNotes = _store.homeMainNotes;

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
                    const SizedBox(width: 2),
                    const Expanded(
                      child: Text(
                        'Notes',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Key Lines',
                      onPressed: _openFavorites,
                      icon: const Icon(
                        Icons.format_quote_rounded,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Categories',
                      onPressed: _openCategories,
                      icon: const Icon(
                        Icons.category_rounded,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      tooltip: isLight
                          ? 'Switch to dark mode'
                          : 'Switch to light mode',
                      onPressed: () => ThemeController.instance.toggleTheme(),
                      icon: Icon(
                        isLight
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      tooltip: 'More',
                      onPressed: _showMoreMenu,
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 2),
                  ],
                ),
              ),
            ),
          ),
          body: GradientPageBackground(
            child: _store.loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _store.init,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 124),
                            children: [
                              _SearchBar(
                                controller: _searchController,
                                onChanged: _store.setQuery,
                                onClear: () {
                                  _searchController.clear();
                                  _store.setQuery('');
                                  setState(() {});
                                },
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _QuickStatCard(
                                      title: 'Pinned',
                                      value: '${_store.pinnedCount}',
                                      icon: Icons.push_pin_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _QuickStatCard(
                                      title: 'Key Lines',
                                      value: '${_store.keyLines.length}',
                                      icon: Icons.auto_awesome_rounded,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _QuickStatCard(
                                      title: 'Favorites',
                                      value: '${_store.favoriteCount}',
                                      icon: Icons.star_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _QuickStatCard(
                                      title: 'Scripture Notes',
                                      value: '${_store.scriptureLinkedCount}',
                                      icon: Icons.menu_book_rounded,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _SectionTitle(
                                title: 'Categories',
                                actionLabel: 'Manage',
                                onAction: _openCategories,
                                isLight: isLight,
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 42,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _store.categoryNames.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final category =
                                        _store.categoryNames[index];
                                    final selected =
                                        _store.selectedCategory == category;

                                    return _CategoryChip(
                                      label:
                                          '$category (${_store.noteCountForCategory(category)})',
                                      selected: selected,
                                      onTap: () =>
                                          _store.setSelectedCategory(category),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 18),
                              if (pinnedNotes.isNotEmpty) ...[
                                _SectionTitle(
                                  title: 'Pinned Notes',
                                  isLight: isLight,
                                ),
                                const SizedBox(height: 10),
                                ..._buildNotesSection(pinnedNotes),
                                const SizedBox(height: 18),
                              ],
                              if (_store.query.trim().isEmpty &&
                                  recentNotes.isNotEmpty) ...[
                                _SectionTitle(
                                  title: 'Recent Notes',
                                  isLight: isLight,
                                ),
                                const SizedBox(height: 10),
                                ..._buildNotesSection(recentNotes),
                                const SizedBox(height: 18),
                              ],
                              _SectionTitle(
                                title: pinnedNotes.isNotEmpty
                                    ? 'More Notes'
                                    : 'All Notes',
                                isLight: isLight,
                              ),
                              const SizedBox(height: 10),
                              if (_store.allListNotes.isEmpty)
                                _EmptyNotesCard(
                                  onCreate: _openCreateNote,
                                  isLight: isLight,
                                )
                              else if (mainNotes.isEmpty &&
                                  pinnedNotes.isNotEmpty)
                                ..._buildNotesSection(pinnedNotes)
                              else
                                ..._buildNotesSection(mainNotes),
                              if (_store.allListNotes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Notes remain connected to Bible references, quote creation, categories, favorites, and key lines.',
                                  style: TextStyle(
                                    color: _pageSubtleColor(isLight),
                                    fontSize: 12,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SafeArea(
                        top: false,
                        child: BannerAdWidget(tabKey: 'explore:notes'),
                      ),
                    ],
                  ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 84),
            child: FloatingActionButton.extended(
              onPressed: _openCreateNote,
              backgroundColor: const Color(0xFFFF2C96),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('New Note'),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildNotesSection(List<NoteModel> notes) {
    final widgets = <Widget>[];

    for (var i = 0; i < notes.length; i++) {
      final note = notes[i];
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _NoteCard(
            note: note,
            onTap: () => _openDetail(note),
            onLongPress: () => _showNoteMenu(note),
            onMenuTap: () => _showNoteMenu(note),
          ),
        ),
      );

      if (AdsService.instance.shouldInsertNativeAfterItem(
        tabKey: 'explore:notes',
        itemIndex: i,
      )) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _NativeAdPlaceholderCard(),
          ),
        );
      }
    }

    return widgets;
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E1430),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search notes, categories, or content...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
          suffixIcon: hasText
              ? IconButton(
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1430),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.70),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.actionLabel,
    this.onAction,
    required this.isLight,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isLight ? const Color(0xFF1E1B16) : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      backgroundColor:
          selected ? const Color(0xFFFF2C96) : const Color(0xFF151C3A),
      side: BorderSide(
        color:
            selected ? const Color(0xFFFF2C96) : Colors.white.withOpacity(0.10),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onLongPress,
    required this.onMenuTap,
  });

  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0E1430),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (note.pinned)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.push_pin_rounded,
                        size: 16,
                        color: Colors.white70,
                      ),
                    ),
                  if (note.favorite)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Color(0xFFFFD76A),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      note.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onMenuTap,
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              if (note.preview.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note.preview,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.78),
                    fontSize: 12.8,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaPill(label: note.displayCategory),
                  _MetaPill(label: _timeAgo(note.updatedAt)),
                  _MetaPill(label: note.displaySourceType),
                  if (note.hasDetectedScriptures)
                    _MetaPill(
                      label: '${note.detectedScriptures.length} scriptures',
                    ),
                  if (note.hasAttachments) const _MetaPill(label: 'Attachment'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _timeAgo(int value) {
    final diff =
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(value));
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
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
          color: Colors.white.withOpacity(0.80),
          fontSize: 11.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NativeAdPlaceholderCard extends StatelessWidget {
  const _NativeAdPlaceholderCard();

  @override
  Widget build(BuildContext context) {
    if (!AdsService.instance.nativeInListAllowedForTab('explore:notes')) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1430),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.campaign_rounded, color: Colors.white),
          ),
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

class _EmptyNotesCard extends StatelessWidget {
  const _EmptyNotesCard({
    required this.onCreate,
    required this.isLight,
  });

  final VoidCallback onCreate;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1430),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.note_alt_rounded, size: 44, color: Colors.white70),
          const SizedBox(height: 12),
          const Text(
            'No notes yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start building your sermon notes, prayer thoughts, study reflections, and key lines.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.68),
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create First Note'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2C96),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isLight,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLight;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? Colors.redAccent
        : (isLight ? const Color(0xFF1E1B16) : Colors.white);

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
