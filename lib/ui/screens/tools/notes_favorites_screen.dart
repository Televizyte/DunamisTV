import 'package:flutter/material.dart';

import '../../../features/notes/state/notes_store.dart';

class NotesFavoritesScreen extends StatefulWidget {
  const NotesFavoritesScreen({super.key});

  @override
  State<NotesFavoritesScreen> createState() =>
      _NotesFavoritesScreenState();
}

class _NotesFavoritesScreenState extends State<NotesFavoritesScreen> {
  final NotesStore _store = NotesStore();

  @override
  void initState() {
    super.initState();
    _store.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Key Lines')),
      body: AnimatedBuilder(
        animation: _store,
        builder: (_, __) {
          final lines = _store.keyLines;

          if (lines.isEmpty) {
            return const Center(child: Text('No key lines yet'));
          }

          return ListView.builder(
            itemCount: lines.length,
            itemBuilder: (_, i) {
              final item = lines[i];

              return ListTile(
                title: Text(item.text),
                subtitle: Text(item.noteTitle),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _store.deleteKeyLine(item.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
