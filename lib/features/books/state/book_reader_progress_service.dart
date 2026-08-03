import 'package:shared_preferences/shared_preferences.dart';

class BookReaderProgressService {
  BookReaderProgressService._();

  static final BookReaderProgressService instance =
      BookReaderProgressService._();

  static const String _prefix = 'book_reader_progress_v1';
  static const String _settingsKey = 'book_reader_settings_v2';
  static const String _legacySettingsKey = 'book_reader_settings_v1';

  Future<void> saveProgress({
    required String bookId,
    required String chapterId,
    int pageIndex = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix.$bookId', '$chapterId|$pageIndex');
  }

  Future<BookProgress?> loadProgress(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix.$bookId') ?? '';
    if (raw.trim().isEmpty) return null;

    final parts = raw.split('|');
    return BookProgress(
      chapterId: parts.isNotEmpty ? parts[0] : '',
      pageIndex: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  Future<BookReaderSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey) ??
        prefs.getString(_legacySettingsKey) ??
        '';
    return BookReaderSettings.fromStorage(raw);
  }

  Future<void> saveSettings(BookReaderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, settings.toStorage());
  }
}

class BookProgress {
  final String chapterId;
  final int pageIndex;

  const BookProgress({required this.chapterId, required this.pageIndex});
}

enum BookReadingMode { scroll, pages }

enum BookPageAnimation { off, slide, softFlip }

class BookReaderSettings {
  final BookReadingMode readingMode;
  final BookPageAnimation pageAnimation;
  final double fontSize;
  final double lineHeight;
  final String fontFamily;
  final String pageTheme;
  final double speechRate;
  final double speechPitch;

  const BookReaderSettings({
    this.readingMode = BookReadingMode.scroll,
    this.pageAnimation = BookPageAnimation.slide,
    this.fontSize = 16.0,
    this.lineHeight = 1.55,
    this.fontFamily = 'backend',
    this.pageTheme = 'backend',
    this.speechRate = 0.45,
    this.speechPitch = 1.0,
  });

  BookReaderSettings copyWith({
    BookReadingMode? readingMode,
    BookPageAnimation? pageAnimation,
    double? fontSize,
    double? lineHeight,
    String? fontFamily,
    String? pageTheme,
    double? speechRate,
    double? speechPitch,
  }) {
    return BookReaderSettings(
      readingMode: readingMode ?? this.readingMode,
      pageAnimation: pageAnimation ?? this.pageAnimation,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      fontFamily: fontFamily ?? this.fontFamily,
      pageTheme: pageTheme ?? this.pageTheme,
      speechRate: speechRate ?? this.speechRate,
      speechPitch: speechPitch ?? this.speechPitch,
    );
  }

  String toStorage() {
    return [
      readingMode.name,
      pageAnimation.name,
      fontSize.toStringAsFixed(1),
      lineHeight.toStringAsFixed(2),
      fontFamily,
      pageTheme,
      speechRate.toStringAsFixed(2),
      speechPitch.toStringAsFixed(2),
    ].join('|');
  }

  factory BookReaderSettings.fromStorage(String raw) {
    final parts = raw.split('|');
    BookReadingMode mode = BookReadingMode.scroll;
    BookPageAnimation animation = BookPageAnimation.slide;

    if (parts.isNotEmpty) {
      mode = BookReadingMode.values.firstWhere(
        (e) => e.name == parts[0],
        orElse: () => BookReadingMode.scroll,
      );
    }
    if (parts.length > 1) {
      animation = BookPageAnimation.values.firstWhere(
        (e) => e.name == parts[1],
        orElse: () => BookPageAnimation.slide,
      );
    }

    final storedFont = parts.length > 4 && parts[4].trim().isNotEmpty
        ? parts[4].trim()
        : 'backend';
    final storedTheme = parts.length > 5 && parts[5].trim().isNotEmpty
        ? parts[5].trim()
        : 'backend';

    return BookReaderSettings(
      readingMode: mode,
      pageAnimation: animation,
      fontSize: parts.length > 2 ? double.tryParse(parts[2]) ?? 16.0 : 16.0,
      lineHeight: parts.length > 3 ? double.tryParse(parts[3]) ?? 1.55 : 1.55,
      fontFamily: storedFont,
      pageTheme: storedTheme,
      speechRate: parts.length > 6 ? double.tryParse(parts[6]) ?? 0.45 : 0.45,
      speechPitch: parts.length > 7 ? double.tryParse(parts[7]) ?? 1.0 : 1.0,
    );
  }
}
