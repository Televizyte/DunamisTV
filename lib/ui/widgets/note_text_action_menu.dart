import 'package:flutter/material.dart';

import '../../features/notes/state/notes_store.dart';
import '../../features/notes/models/note_model.dart';

class NoteTextActionMenu {
  static Future<void> show({
    required BuildContext context,
    required String selectedText,
    required NotesStore store,
    required NoteModel note,
  }) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('Save as Key Line'),
                onTap: () => Navigator.pop(context, 'keyline'),
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () => Navigator.pop(context, 'copy'),
              ),
            ],
          ),
        );
      },
    );

    if (action == 'keyline') {
      await store.addKeyLine(note: note, text: selectedText);
    }
  }
}
