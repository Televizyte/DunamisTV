import 'package:flutter/material.dart';

import '../../../features/notes/state/notes_store.dart';

class NotesCategoriesScreen extends StatefulWidget {
  const NotesCategoriesScreen({super.key});

  @override
  State<NotesCategoriesScreen> createState() =>
      _NotesCategoriesScreenState();
}

class _NotesCategoriesScreenState extends State<NotesCategoriesScreen> {
  final NotesStore _store = NotesStore();
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _store.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(hintText: 'New category'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    _store.addCategory(_controller.text);
                    _controller.clear();
                  },
                )
              ],
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _store,
              builder: (_, __) {
                final cats = _store.categories;

                return ListView.builder(
                  itemCount: cats.length,
                  itemBuilder: (_, i) {
                    final c = cats[i];

                    return ListTile(
                      title: Text(c.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () =>
                            _store.deleteCategory(c.id),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
