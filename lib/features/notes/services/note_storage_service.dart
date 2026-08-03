import 'package:shared_preferences/shared_preferences.dart';

import '../models/note_model.dart';

class NoteStorageService {
  static const String _notesKey = 'dunamis_notes_v2';
  static const String _categoriesKey = 'dunamis_note_categories_v2';
  static const String _keyLinesKey = 'dunamis_note_key_lines_v2';

  static Future<List<NoteModel>> getNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_notesKey) ?? const <String>[];

    final notes = raw.map(NoteModel.fromJson).toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) {
          return a.pinned ? -1 : 1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });

    return notes;
  }

  static Future<void> saveNote(NoteModel note) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_notesKey) ?? const <String>[];

    final updated = <String>[
      note.toJson(),
      ...existing.where((raw) => NoteModel.fromJson(raw).id != note.id),
    ];

    await prefs.setStringList(_notesKey, updated);
  }

  static Future<void> saveNotes(List<NoteModel> notes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _notesKey,
      notes.map((e) => e.toJson()).toList(),
    );
  }

  static Future<void> deleteNote(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_notesKey) ?? const <String>[];

    final updated = existing.where((raw) => NoteModel.fromJson(raw).id != id).toList();

    await prefs.setStringList(_notesKey, updated);

    final keyLines = await getKeyLines();
    final filteredLines = keyLines.where((e) => e.noteId != id).toList();
    await saveKeyLines(filteredLines);
  }

  static Future<List<NoteCategoryModel>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_categoriesKey);

    if (raw == null || raw.isEmpty) {
      final defaults = <NoteCategoryModel>[
        NoteCategoryModel.create(id: 'cat_general', name: 'General', order: 0),
        NoteCategoryModel.create(id: 'cat_sermon', name: 'Sermon', order: 1),
        NoteCategoryModel.create(id: 'cat_prayer', name: 'Prayer', order: 2),
        NoteCategoryModel.create(id: 'cat_study', name: 'Study', order: 3),
      ];

      await saveCategories(defaults);
      return defaults;
    }

    final categories = raw.map(NoteCategoryModel.fromJson).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return categories;
  }

  static Future<void> saveCategories(List<NoteCategoryModel> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _categoriesKey,
      categories.map((e) => e.toJson()).toList(),
    );
  }

  static Future<List<NoteKeyLineModel>> getKeyLines() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyLinesKey) ?? const <String>[];

    final items = raw.map(NoteKeyLineModel.fromJson).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return items;
  }

  static Future<void> saveKeyLine(NoteKeyLineModel item) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_keyLinesKey) ?? const <String>[];

    final updated = <String>[
      item.toJson(),
      ...existing.where((raw) => NoteKeyLineModel.fromJson(raw).id != item.id),
    ];

    await prefs.setStringList(_keyLinesKey, updated);
  }

  static Future<void> saveKeyLines(List<NoteKeyLineModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyLinesKey,
      items.map((e) => e.toJson()).toList(),
    );
  }

  static Future<void> deleteKeyLine(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_keyLinesKey) ?? const <String>[];

    final updated = existing.where((raw) => NoteKeyLineModel.fromJson(raw).id != id).toList();

    await prefs.setStringList(_keyLinesKey, updated);
  }
}
