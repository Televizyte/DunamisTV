import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/notes/models/note_model.dart';
import '../../../features/notes/state/notes_store.dart';
import '../../widgets/gradient_page_background.dart';

class NoteCategoriesScreen extends StatefulWidget {
  const NoteCategoriesScreen({super.key});

  @override
  State<NoteCategoriesScreen> createState() => _NoteCategoriesScreenState();
}

class _NoteCategoriesScreenState extends State<NoteCategoriesScreen> {
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

  Future<void> _showAddOrEditDialog({NoteCategoryModel? category}) async {
    final controller = TextEditingController(text: category?.name ?? '');

    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0E1430),
          title: Text(
            category == null ? 'Create Category' : 'Edit Category',
            style: const TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Category name',
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (value == null || value.trim().isEmpty) return;

    if (category == null) {
      await _store.addCategory(value);
    } else {
      await _store.renameCategory(category.id, value);
    }
  }

  Future<void> _deleteCategory(NoteCategoryModel category) async {
    if (category.name == 'General') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('General category cannot be deleted')),
      );
      return;
    }

    await _store.deleteCategory(category.id);
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
                        'Note Categories',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showAddOrEditDialog(),
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
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
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                    itemCount: _store.categories.length,
                    onReorder: _store.reorderCategories,
                    itemBuilder: (context, index) {
                      final category = _store.categories[index];

                      return Container(
                        key: ValueKey(category.id),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E1430),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.drag_handle_rounded, color: Colors.white70),
                          title: Text(
                            category.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            category.name == 'General'
                                ? 'Default category'
                                : 'Tap edit or delete',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.62),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _showAddOrEditDialog(category: category),
                                icon: const Icon(Icons.edit_rounded, color: Colors.white70),
                              ),
                              IconButton(
                                onPressed: () => _deleteCategory(category),
                                icon: Icon(
                                  Icons.delete_rounded,
                                  color: category.name == 'General'
                                      ? Colors.white24
                                      : Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddOrEditDialog(),
            backgroundColor: const Color(0xFFFF2C96),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Category'),
          ),
        );
      },
    );
  }
}
