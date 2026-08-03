import 'dart:convert';

class NoteModel {
  final String id;
  final String title;
  final String content;
  final String category;
  final List<String> tags;
  final bool pinned;
  final bool favorite;
  final int createdAt;
  final int updatedAt;
  final String sourceType;
  final String sourceId;
  final List<String> detectedScriptures;
  final List<String> attachments;

  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.tags,
    required this.pinned,
    required this.favorite,
    required this.createdAt,
    required this.updatedAt,
    required this.sourceType,
    required this.sourceId,
    required this.detectedScriptures,
    required this.attachments,
  });

  factory NoteModel.empty({
    required String id,
    String sourceType = 'manual',
    String sourceId = '',
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;

    return NoteModel(
      id: id,
      title: '',
      content: '',
      category: 'General',
      tags: const [],
      pinned: false,
      favorite: false,
      createdAt: now,
      updatedAt: now,
      sourceType: sourceType,
      sourceId: sourceId,
      detectedScriptures: const [],
      attachments: const [],
    );
  }

  String get displayTitle {
    final value = title.trim();
    return value.isEmpty ? 'Untitled Note' : value;
  }

  String get displayCategory {
    final value = category.trim();
    return value.isEmpty ? 'General' : value;
  }

  String get displaySourceType {
    switch (sourceType.trim().toLowerCase()) {
      case 'bible':
        return 'Bible';
      case 'article':
        return 'Article';
      case 'quote':
        return 'Quote';
      case 'manual':
      default:
        return 'Manual';
    }
  }

  String get preview {
    final cleaned =
        content.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return '';
    if (cleaned.length <= 140) return cleaned;
    return '${cleaned.substring(0, 140)}...';
  }

  bool get hasContent => title.trim().isNotEmpty || content.trim().isNotEmpty;
  bool get hasAttachments => attachments.isNotEmpty;
  bool get hasDetectedScriptures => detectedScriptures.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'tags': tags,
      'pinned': pinned,
      'favorite': favorite,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'sourceType': sourceType,
      'sourceId': sourceId,
      'detectedScriptures': detectedScriptures,
      'attachments': attachments,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      content: (map['content'] ?? '').toString(),
      category: (map['category'] ?? 'General').toString(),
      tags: (map['tags'] is List)
          ? List<String>.from((map['tags'] as List).map((e) => e.toString()))
          : const [],
      pinned: map['pinned'] == true,
      favorite: map['favorite'] == true,
      createdAt: _asInt(map['createdAt']),
      updatedAt: _asInt(map['updatedAt']),
      sourceType: (map['sourceType'] ?? 'manual').toString(),
      sourceId: (map['sourceId'] ?? '').toString(),
      detectedScriptures: (map['detectedScriptures'] is List)
          ? List<String>.from(
              (map['detectedScriptures'] as List).map((e) => e.toString()),
            )
          : const [],
      attachments: (map['attachments'] is List)
          ? List<String>.from(
              (map['attachments'] as List).map((e) => e.toString()),
            )
          : const [],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory NoteModel.fromJson(String source) {
    return NoteModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    List<String>? tags,
    bool? pinned,
    bool? favorite,
    int? createdAt,
    int? updatedAt,
    String? sourceType,
    String? sourceId,
    List<String>? detectedScriptures,
    List<String>? attachments,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      pinned: pinned ?? this.pinned,
      favorite: favorite ?? this.favorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      detectedScriptures: detectedScriptures ?? this.detectedScriptures,
      attachments: attachments ?? this.attachments,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? 0}') ?? 0;
  }
}

class NoteCategoryModel {
  final String id;
  final String name;
  final int order;
  final int createdAt;

  const NoteCategoryModel({
    required this.id,
    required this.name,
    required this.order,
    required this.createdAt,
  });

  factory NoteCategoryModel.create({
    required String id,
    required String name,
    required int order,
  }) {
    return NoteCategoryModel(
      id: id,
      name: name,
      order: order,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'createdAt': createdAt,
    };
  }

  factory NoteCategoryModel.fromMap(Map<String, dynamic> map) {
    return NoteCategoryModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      order: NoteModel._asInt(map['order']),
      createdAt: NoteModel._asInt(map['createdAt']),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory NoteCategoryModel.fromJson(String source) {
    return NoteCategoryModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }

  NoteCategoryModel copyWith({
    String? id,
    String? name,
    int? order,
    int? createdAt,
  }) {
    return NoteCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class NoteKeyLineModel {
  final String id;
  final String noteId;
  final String noteTitle;
  final String text;
  final String category;
  final String sourceType;
  final int createdAt;

  const NoteKeyLineModel({
    required this.id,
    required this.noteId,
    required this.noteTitle,
    required this.text,
    required this.category,
    required this.sourceType,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'noteId': noteId,
      'noteTitle': noteTitle,
      'text': text,
      'category': category,
      'sourceType': sourceType,
      'createdAt': createdAt,
    };
  }

  factory NoteKeyLineModel.fromMap(Map<String, dynamic> map) {
    return NoteKeyLineModel(
      id: (map['id'] ?? '').toString(),
      noteId: (map['noteId'] ?? '').toString(),
      noteTitle: (map['noteTitle'] ?? '').toString(),
      text: (map['text'] ?? '').toString(),
      category: (map['category'] ?? 'General').toString(),
      sourceType: (map['sourceType'] ?? 'note').toString(),
      createdAt: NoteModel._asInt(map['createdAt']),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory NoteKeyLineModel.fromJson(String source) {
    return NoteKeyLineModel.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }
}
