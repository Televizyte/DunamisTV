import 'dart:convert';

class BibleVerse {
  const BibleVerse({
    required this.book,
    required this.abbreviation,
    required this.testament,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.translation,
  });

  final String book;
  final String abbreviation;
  final String testament;
  final int chapter;
  final int verse;
  final String text;
  final String translation;

  String get reference => '$book $chapter:$verse';

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'book': book,
      'abbreviation': abbreviation,
      'testament': testament,
      'chapter': chapter,
      'verse': verse,
      'text': text,
      'translation': translation,
    };
  }

  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    return BibleVerse(
      book: (json['book'] ?? '').toString(),
      abbreviation: (json['abbreviation'] ?? '').toString(),
      testament: (json['testament'] ?? '').toString(),
      chapter: (json['chapter'] as num?)?.toInt() ?? 0,
      verse: (json['verse'] as num?)?.toInt() ?? 0,
      text: (json['text'] ?? '').toString(),
      translation: (json['translation'] ?? 'KJV').toString(),
    );
  }

  String encode() => jsonEncode(toJson());

  factory BibleVerse.decode(String source) {
    return BibleVerse.fromJson(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BibleVerse &&
        other.book == book &&
        other.chapter == chapter &&
        other.verse == verse &&
        other.translation == translation;
  }

  @override
  int get hashCode => Object.hash(book, chapter, verse, translation);
}

class BibleBook {
  const BibleBook({
    required this.name,
    required this.abbreviation,
    required this.testament,
    required this.chapters,
  });

  final String name;
  final String abbreviation;
  final String testament;
  final List<List<String>> chapters;

  int get chapterCount => chapters.length;

  int verseCountForChapter(int chapter) {
    if (chapter < 1 || chapter > chapters.length) return 0;
    return chapters[chapter - 1].length;
  }

  List<BibleVerse> versesForChapter({
    required int chapter,
    required String translation,
  }) {
    if (chapter < 1 || chapter > chapters.length) {
      return const <BibleVerse>[];
    }

    final verses = chapters[chapter - 1];
    return List<BibleVerse>.generate(
      verses.length,
      (index) => BibleVerse(
        book: name,
        abbreviation: abbreviation,
        testament: testament,
        chapter: chapter,
        verse: index + 1,
        text: verses[index],
        translation: translation,
      ),
      growable: false,
    );
  }

  factory BibleBook.fromJson(Map<String, dynamic> json) {
    final rawChapters = (json['chapters'] as List<dynamic>? ?? <dynamic>[]);
    final parsedChapters = rawChapters.map((chapter) {
      final verses = chapter as List<dynamic>? ?? <dynamic>[];
      return verses.map((verse) => verse.toString()).toList(growable: false);
    }).toList(growable: false);

    return BibleBook(
      name: (json['name'] ?? '').toString(),
      abbreviation: (json['abbreviation'] ?? '').toString(),
      testament: (json['testament'] ?? '').toString(),
      chapters: parsedChapters,
    );
  }
}

class BibleSearchResult {
  const BibleSearchResult({
    required this.verse,
    required this.matchIndex,
  });

  final BibleVerse verse;
  final int matchIndex;
}

class BibleReadingPosition {
  const BibleReadingPosition({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.translation,
  });

  final String book;
  final int chapter;
  final int verse;
  final String translation;

  String get label {
    if (book.trim().isEmpty || chapter <= 0) return 'Start reading';
    if (verse > 0) return '$book $chapter:$verse';
    return '$book $chapter';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'translation': translation,
    };
  }

  factory BibleReadingPosition.fromJson(Map<String, dynamic> json) {
    return BibleReadingPosition(
      book: (json['book'] ?? '').toString(),
      chapter: (json['chapter'] as num?)?.toInt() ?? 0,
      verse: (json['verse'] as num?)?.toInt() ?? 0,
      translation: (json['translation'] ?? 'KJV').toString(),
    );
  }

  factory BibleReadingPosition.fromVerse(BibleVerse verse) {
    return BibleReadingPosition(
      book: verse.book,
      chapter: verse.chapter,
      verse: verse.verse,
      translation: verse.translation,
    );
  }
}
