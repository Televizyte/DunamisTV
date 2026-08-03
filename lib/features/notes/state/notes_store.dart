import 'dart:async';

import 'package:flutter/material.dart';

import '../models/note_model.dart';
import '../services/note_storage_service.dart';

class NotesStore extends ChangeNotifier {
  final List<NoteModel> _notes = <NoteModel>[];
  final List<NoteCategoryModel> _categories = <NoteCategoryModel>[];
  final List<NoteKeyLineModel> _keyLines = <NoteKeyLineModel>[];

  bool _loading = true;
  String _query = '';
  String _selectedCategory = 'All';

  bool get loading => _loading;
  String get query => _query;
  String get selectedCategory => _selectedCategory;

  List<NoteModel> get notes => List.unmodifiable(_notes);
  List<NoteCategoryModel> get categories => List.unmodifiable(_categories);
  List<NoteKeyLineModel> get keyLines => List.unmodifiable(_keyLines);

  List<String> get categoryNames => <String>[
        'All',
        ..._categories.map((e) => e.name),
      ];

  int get noteCount => _notes.length;
  int get favoriteCount => _notes.where((e) => e.favorite).length;
  int get pinnedCount => _notes.where((e) => e.pinned).length;
  int get attachmentCount =>
      _notes.fold<int>(0, (sum, note) => sum + note.attachments.length);
  int get scriptureLinkedCount =>
      _notes.where((e) => e.detectedScriptures.isNotEmpty).length;

  Future<void> init() async {
    _loading = true;
    notifyListeners();

    final loadedNotes = await NoteStorageService.getNotes();
    final loadedCategories = await NoteStorageService.getCategories();
    final loadedKeyLines = await NoteStorageService.getKeyLines();

    _notes
      ..clear()
      ..addAll(loadedNotes);

    _categories
      ..clear()
      ..addAll(loadedCategories);

    _keyLines
      ..clear()
      ..addAll(loadedKeyLines);

    _loading = false;
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value.trimLeft();
    notifyListeners();
  }

  void setSelectedCategory(String value) {
    _selectedCategory = value;
    notifyListeners();
  }

  int noteCountForCategory(String category) {
    if (category == 'All') return _notes.length;
    return _notes.where((e) => e.category == category).length;
  }

  List<NoteModel> get filteredNotes {
    final q = _query.trim().toLowerCase();

    return _notes.where((note) {
      final categoryMatch =
          _selectedCategory == 'All' || note.category == _selectedCategory;

      if (!categoryMatch) return false;
      if (q.isEmpty) return true;

      return note.title.toLowerCase().contains(q) ||
          note.content.toLowerCase().contains(q) ||
          note.category.toLowerCase().contains(q) ||
          note.sourceType.toLowerCase().contains(q) ||
          note.sourceId.toLowerCase().contains(q) ||
          note.detectedScriptures.any((e) => e.toLowerCase().contains(q));
    }).toList();
  }

  List<NoteModel> get pinnedNotes =>
      filteredNotes.where((e) => e.pinned).toList();

  List<NoteModel> get favoriteNotes =>
      filteredNotes.where((e) => e.favorite).toList();

  List<NoteModel> get recentNotes => filteredNotes
      .where((e) => !e.pinned)
      .take(6)
      .toList();

  List<NoteModel> get unpinnedNotes =>
      filteredNotes.where((e) => !e.pinned).toList();

  List<NoteModel> get allListNotes => filteredNotes;

  List<NoteModel> get homeMainNotes {
    final pinnedIds = pinnedNotes.map((e) => e.id).toSet();
    return filteredNotes.where((e) => !pinnedIds.contains(e.id)).toList();
  }

  NoteModel? findNoteById(String id) {
    try {
      return _notes.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<NoteModel> createEmptyNote({
    String category = 'General',
    String sourceType = 'manual',
    String sourceId = '',
  }) async {
    final note = NoteModel.empty(
      id: _newId('note'),
      sourceType: sourceType,
      sourceId: sourceId,
    ).copyWith(category: category);

    await saveNote(note);
    return note;
  }

  Future<void> saveNote(NoteModel note) async {
    final normalized = _normalizeNote(note);

    final index = _notes.indexWhere((e) => e.id == normalized.id);
    if (index >= 0) {
      _notes[index] = normalized;
    } else {
      _notes.insert(0, normalized);
    }

    _sortNotes();
    notifyListeners();
    await NoteStorageService.saveNote(normalized);
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((e) => e.id == id);
    _keyLines.removeWhere((e) => e.noteId == id);
    notifyListeners();
    await NoteStorageService.deleteNote(id);
  }

  Future<void> togglePinned(String id) async {
    final note = findNoteById(id);
    if (note == null) return;

    await saveNote(note.copyWith(pinned: !note.pinned));
  }

  Future<void> toggleFavorite(String id) async {
    final note = findNoteById(id);
    if (note == null) return;

    await saveNote(note.copyWith(favorite: !note.favorite));
  }

  Future<void> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_categories.any((e) => e.name.toLowerCase() == trimmed.toLowerCase())) {
      return;
    }

    _categories.add(
      NoteCategoryModel.create(
        id: _newId('cat'),
        name: trimmed,
        order: _categories.length,
      ),
    );

    notifyListeners();
    await NoteStorageService.saveCategories(_categories);
  }

  Future<void> renameCategory(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final index = _categories.indexWhere((e) => e.id == id);
    if (index < 0) return;

    final oldName = _categories[index].name;
    _categories[index] = _categories[index].copyWith(name: trimmed);

    for (var i = 0; i < _notes.length; i++) {
      if (_notes[i].category == oldName) {
        _notes[i] = _notes[i].copyWith(category: trimmed);
      }
    }

    notifyListeners();
    await NoteStorageService.saveCategories(_categories);
    await NoteStorageService.saveNotes(_notes);
  }

  Future<void> deleteCategory(String id) async {
    final category = _categories.where((e) => e.id == id).toList();
    if (category.isEmpty) return;

    final name = category.first.name;
    if (name == 'General') return;

    _categories.removeWhere((e) => e.id == id);

    for (var i = 0; i < _categories.length; i++) {
      _categories[i] = _categories[i].copyWith(order: i);
    }

    for (var i = 0; i < _notes.length; i++) {
      if (_notes[i].category == name) {
        _notes[i] = _notes[i].copyWith(category: 'General');
      }
    }

    if (_selectedCategory == name) {
      _selectedCategory = 'All';
    }

    notifyListeners();
    await NoteStorageService.saveCategories(_categories);
    await NoteStorageService.saveNotes(_notes);
  }

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final moved = _categories.removeAt(oldIndex);
    _categories.insert(newIndex, moved);

    for (var i = 0; i < _categories.length; i++) {
      _categories[i] = _categories[i].copyWith(order: i);
    }

    notifyListeners();
    await NoteStorageService.saveCategories(_categories);
  }

  Future<void> addKeyLine({
    required NoteModel note,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final exists = _keyLines.any(
      (e) =>
          e.noteId == note.id &&
          e.text.trim().toLowerCase() == trimmed.toLowerCase(),
    );

    if (exists) return;

    final item = NoteKeyLineModel(
      id: _newId('line'),
      noteId: note.id,
      noteTitle: note.title.trim().isEmpty ? 'Untitled Note' : note.title.trim(),
      text: trimmed,
      category: note.category,
      sourceType: note.sourceType,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    _keyLines.insert(0, item);
    notifyListeners();
    await NoteStorageService.saveKeyLine(item);
  }

  Future<void> deleteKeyLine(String id) async {
    _keyLines.removeWhere((e) => e.id == id);
    notifyListeners();
    await NoteStorageService.deleteKeyLine(id);
  }

  Future<void> appendTextToNote({
    required String noteId,
    required String text,
  }) async {
    final note = findNoteById(noteId);
    if (note == null) return;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final content = note.content.trim().isEmpty
        ? trimmed
        : '${note.content.trimRight()}\n\n$trimmed';

    await saveNote(note.copyWith(content: content));
  }

  NoteModel _normalizeNote(NoteModel note) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final detected = detectScriptures('${note.title}\n${note.content}');

    return note.copyWith(
      title: note.title.trim(),
      content: note.content.trimRight(),
      category: note.category.trim().isEmpty ? 'General' : note.category.trim(),
      sourceType: note.sourceType.trim().isEmpty ? 'manual' : note.sourceType.trim(),
      sourceId: note.sourceId.trim(),
      updatedAt: now,
      detectedScriptures: detected,
    );
  }

  List<String> detectScriptures(String text) {
    final exp = RegExp(
      r'\b(?:[1-3]\s*)?[A-Z][a-z]+(?:\s+(?:of|the|[A-Z][a-z]+))*\s+\d{1,3}:\d{1,3}(?:-\d{1,3})?\b',
      multiLine: true,
    );

    return exp
        .allMatches(text)
        .map((e) => (e.group(0) ?? '').trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  void _sortNotes() {
    _notes.sort((a, b) {
      if (a.pinned != b.pinned) {
        return a.pinned ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  String _newId(String prefix) {
    final now = DateTime.now().microsecondsSinceEpoch;
    return '${prefix}_$now';
  }
}

class NotesAutosaveController {
  NotesAutosaveController({
    required this.onSave,
    this.delay = const Duration(milliseconds: 700),
  });

  final Future<void> Function() onSave;
  final Duration delay;

  Timer? _timer;

  void schedule() {
    _timer?.cancel();
    _timer = Timer(delay, () async {
      await onSave();
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}
