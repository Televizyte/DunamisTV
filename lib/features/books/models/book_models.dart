class BookCategory {
  final int? id;
  final String name;
  final String slug;
  final String description;

  const BookCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
  });

  factory BookCategory.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    return BookCategory(
      id: _intValue(map['id']),
      name: _stringValue(map, const ['name', 'title'], fallback: 'Category'),
      slug: _stringValue(map, const ['slug', 'key']),
      description: _stringValue(map, const ['description', 'summary']),
    );
  }
}

class BookChapter {
  final int? id;
  final String type;
  final String title;
  final String subtitle;
  final String slug;
  final String summary;
  final String keyThought;
  final String reflectionQuestions;
  final String prayerPoints;
  final String actionSteps;
  final String memoryVerse;
  final String status;
  final int sortOrder;
  final int wordCount;
  final int estimatedPages;
  final int estimatedReadingMinutes;
  final String bodyHtml;
  final Map<String, dynamic> payload;

  const BookChapter({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.slug,
    required this.summary,
    required this.keyThought,
    required this.reflectionQuestions,
    required this.prayerPoints,
    required this.actionSteps,
    required this.memoryVerse,
    required this.status,
    required this.sortOrder,
    required this.wordCount,
    required this.estimatedPages,
    required this.estimatedReadingMinutes,
    required this.bodyHtml,
    required this.payload,
  });

  factory BookChapter.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    return BookChapter(
      id: _intValue(map['id']),
      type: _stringValue(map, const ['type'], fallback: 'book_chapter'),
      title: _stringValue(map, const ['title', 'name'], fallback: 'Chapter'),
      subtitle: _stringValue(map, const ['subtitle', 'caption']),
      slug: _stringValue(map, const ['slug']),
      summary: _stringValue(map, const ['summary']),
      keyThought: _stringValue(map, const ['key_thought', 'keyThought']),
      reflectionQuestions: _stringValue(map, const [
        'reflection_questions',
        'reflectionQuestions',
      ]),
      prayerPoints: _stringValue(map, const ['prayer_points', 'prayerPoints']),
      actionSteps: _stringValue(map, const ['action_steps', 'actionSteps']),
      memoryVerse: _stringValue(map, const ['memory_verse', 'memoryVerse']),
      status: _stringValue(map, const ['status'], fallback: 'published'),
      sortOrder: _intValue(map['sort_order']) ?? 0,
      wordCount: _intValue(map['word_count']) ?? 0,
      estimatedPages: _intValue(map['estimated_pages']) ?? 1,
      estimatedReadingMinutes: _intValue(map['estimated_reading_minutes']) ?? 1,
      bodyHtml: _stringValue(map, const ['body_html', 'bodyHtml', 'html']),
      payload: _mapValue(map['payload']),
    );
  }

  String get identifier => slug.trim().isNotEmpty ? slug.trim() : '${id ?? ''}';
}

class CoverDesignerData {
  final bool enabled;
  final String bgImageUrl;
  final String bgColor;
  final String gradientColor;
  final int overlay;
  final String title;
  final String subtitle;
  final String author;
  final String badge;
  final String textColor;
  final String textPosition;
  final int titleSize;
  final int subtitleSize;
  final int authorSize;
  final int badgeSize;
  final String fontFamily;
  final String textAlign;
  final String textShadow;
  final String bgFit;
  final String bgPosition;
  final String layoutStyle;
  final int textWidth;
  final int panelOpacity;

  const CoverDesignerData({
    required this.enabled,
    required this.bgImageUrl,
    required this.bgColor,
    required this.gradientColor,
    required this.overlay,
    required this.title,
    required this.subtitle,
    required this.author,
    required this.badge,
    required this.textColor,
    required this.textPosition,
    required this.titleSize,
    required this.subtitleSize,
    required this.authorSize,
    required this.badgeSize,
    required this.fontFamily,
    required this.textAlign,
    required this.textShadow,
    required this.bgFit,
    required this.bgPosition,
    required this.layoutStyle,
    required this.textWidth,
    required this.panelOpacity,
  });

  factory CoverDesignerData.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    return CoverDesignerData(
      enabled: _boolValue(map['enabled']) ?? false,
      bgImageUrl: _stringValue(map, const ['bg_image_url', 'bgImageUrl']),
      bgColor:
          _stringValue(map, const ['bg_color', 'bgColor'], fallback: '#0B1F4D'),
      gradientColor: _stringValue(
        map,
        const ['gradient_color', 'gradientColor'],
        fallback: '#E2388A',
      ),
      overlay: (_intValue(map['overlay']) ?? 42).clamp(0, 90).toInt(),
      title: _stringValue(map, const ['title']),
      subtitle: _stringValue(map, const ['subtitle']),
      author: _stringValue(map, const ['author']),
      badge: _stringValue(map, const ['badge']),
      textColor: _stringValue(
        map,
        const ['text_color', 'textColor'],
        fallback: '#FFFFFF',
      ),
      textPosition: _stringValue(
        map,
        const ['text_position', 'textPosition'],
        fallback: 'bottom',
      ),
      titleSize: (_intValue(map['title_size']) ?? 34).clamp(12, 90).toInt(),
      subtitleSize:
          (_intValue(map['subtitle_size']) ?? 15).clamp(8, 50).toInt(),
      authorSize: (_intValue(map['author_size']) ?? 13).clamp(8, 40).toInt(),
      badgeSize: (_intValue(map['badge_size']) ?? 10).clamp(6, 28).toInt(),
      fontFamily: _stringValue(
        map,
        const ['font_family', 'fontFamily'],
        fallback: 'display',
      ),
      textAlign: _stringValue(
        map,
        const ['text_align', 'textAlign'],
        fallback: 'left',
      ),
      textShadow: _stringValue(
        map,
        const ['text_shadow', 'textShadow'],
        fallback: 'soft',
      ),
      bgFit: _stringValue(map, const ['bg_fit', 'bgFit'], fallback: 'cover'),
      bgPosition: _stringValue(
        map,
        const ['bg_position', 'bgPosition'],
        fallback: 'center',
      ),
      layoutStyle: _stringValue(
        map,
        const ['layout_style', 'layoutStyle'],
        fallback: 'bold',
      ),
      textWidth: (_intValue(map['text_width']) ?? 88).clamp(35, 100).toInt(),
      panelOpacity: (_intValue(map['panel_opacity']) ?? 0).clamp(0, 80).toInt(),
    );
  }

  bool get hasBackground => bgImageUrl.trim().isNotEmpty;
}

class BookItem {
  final int? id;
  final String type;
  final String title;
  final String subtitle;
  final String slug;
  final String authorName;
  final String description;
  final String bookType;
  final String status;
  final String accessType;
  final bool isFeatured;
  final bool isDownloadable;
  final String coverImageUrl;
  final String rawCoverImageUrl;
  final String finalCoverImageUrl;
  final String renderedCoverUrl;
  final String thumbnailUrl;
  final String imageUrl;
  final String coverRatio;
  final String displayStyle;
  final String frontendCardStyle;
  final String bookPageSize;
  final int? targetPages;
  final String readerFont;
  final String pageTheme;
  final String fileUrl;
  final String externalUrl;
  final String publishedAt;
  final BookCategory? category;
  final int chapterCount;
  final int estimatedPages;
  final int estimatedReadingMinutes;
  final int wordCount;
  final List<BookChapter> toc;
  final List<BookChapter>? chapters;
  final Map<String, dynamic> payload;
  final CoverDesignerData coverDesigner;

  const BookItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.slug,
    required this.authorName,
    required this.description,
    required this.bookType,
    required this.status,
    required this.accessType,
    required this.isFeatured,
    required this.isDownloadable,
    required this.coverImageUrl,
    required this.rawCoverImageUrl,
    required this.finalCoverImageUrl,
    required this.renderedCoverUrl,
    required this.thumbnailUrl,
    required this.imageUrl,
    required this.coverRatio,
    required this.displayStyle,
    required this.frontendCardStyle,
    required this.bookPageSize,
    required this.targetPages,
    required this.readerFont,
    required this.pageTheme,
    required this.fileUrl,
    required this.externalUrl,
    required this.publishedAt,
    required this.category,
    required this.chapterCount,
    required this.estimatedPages,
    required this.estimatedReadingMinutes,
    required this.wordCount,
    required this.toc,
    required this.chapters,
    required this.payload,
    required this.coverDesigner,
  });

  factory BookItem.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    final payload = _mapValue(map['payload']);
    final designer = _mapValue(map['cover_designer']);
    final payloadDesigner = _mapValue(payload['cover_designer']);
    final finalDesigner = designer.isNotEmpty ? designer : payloadDesigner;

    final rawToc = map['toc'];
    final toc = rawToc is List
        ? rawToc
            .whereType<Map>()
            .map((e) => BookChapter.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false)
        : <BookChapter>[];

    final rawChapters = map['chapters'];
    final chapters = rawChapters is List
        ? rawChapters
            .whereType<Map>()
            .map((e) => BookChapter.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false)
        : null;

    final categoryMap = _mapValue(map['category']);

    return BookItem(
      id: _intValue(map['id']),
      type: _stringValue(map, const ['type'], fallback: 'book'),
      title:
          _stringValue(map, const ['title', 'name'], fallback: 'Untitled Book'),
      subtitle: _stringValue(map, const ['subtitle', 'caption']),
      slug: _stringValue(map, const ['slug']),
      authorName:
          _stringValue(map, const ['author_name', 'authorName', 'author']),
      description: _stringValue(map, const ['description', 'summary']),
      bookType: _stringValue(
        map,
        const ['book_type', 'bookType'],
        fallback: 'manual',
      ),
      status: _stringValue(map, const ['status'], fallback: 'published'),
      accessType: _stringValue(
        map,
        const ['access_type', 'accessType'],
        fallback: 'free',
      ),
      isFeatured: _boolValue(map['is_featured'] ?? map['isFeatured']) ?? false,
      isDownloadable:
          _boolValue(map['is_downloadable'] ?? map['isDownloadable']) ?? false,
      coverImageUrl: _firstNonEmpty([
        _stringValue(map, const ['cover_image_url', 'coverImageUrl']),
        _stringValue(payload, const ['cover_image_url', 'coverImageUrl']),
      ]),
      rawCoverImageUrl: _firstNonEmpty([
        _stringValue(map, const ['raw_cover_image_url', 'rawCoverImageUrl']),
        _stringValue(
            payload, const ['raw_cover_image_url', 'rawCoverImageUrl']),
      ]),
      finalCoverImageUrl: _firstNonEmpty([
        _stringValue(
            map, const ['final_cover_image_url', 'finalCoverImageUrl']),
        _stringValue(
            payload, const ['final_cover_image_url', 'finalCoverImageUrl']),
      ]),
      renderedCoverUrl: _firstNonEmpty([
        _stringValue(map, const ['rendered_cover_url', 'renderedCoverUrl']),
        _stringValue(payload, const ['rendered_cover_url', 'renderedCoverUrl']),
      ]),
      thumbnailUrl: _stringValue(map, const ['thumbnail_url', 'thumbnailUrl']),
      imageUrl: _stringValue(map, const ['image_url', 'imageUrl']),
      coverRatio: _stringValue(
        map,
        const ['cover_ratio', 'coverRatio'],
        fallback: 'portrait_3_4',
      ),
      displayStyle: _stringValue(
        map,
        const ['display_style', 'displayStyle'],
        fallback: 'book_cover',
      ),
      frontendCardStyle: _stringValue(
        map,
        const ['frontend_card_style', 'frontendCardStyle'],
        fallback: 'portrait_book_card',
      ),
      bookPageSize: _stringValue(
        map,
        const ['book_page_size', 'bookPageSize'],
        fallback: 'standard_6x9',
      ),
      targetPages: _intValue(map['target_pages'] ?? map['targetPages']),
      readerFont: _stringValue(
        map,
        const ['reader_font', 'readerFont'],
        fallback: 'serif',
      ),
      pageTheme: _stringValue(
        map,
        const ['page_theme', 'pageTheme'],
        fallback: 'classic',
      ),
      fileUrl: _stringValue(map, const ['file_url', 'fileUrl']),
      externalUrl: _stringValue(map, const ['external_url', 'externalUrl']),
      publishedAt: _stringValue(map, const ['published_at', 'publishedAt']),
      category: categoryMap.isEmpty ? null : BookCategory.fromJson(categoryMap),
      chapterCount:
          _intValue(map['chapter_count'] ?? map['chapterCount']) ?? toc.length,
      estimatedPages:
          _intValue(map['estimated_pages'] ?? map['estimatedPages']) ?? 1,
      estimatedReadingMinutes: _intValue(
            map['estimated_reading_minutes'] ?? map['estimatedReadingMinutes'],
          ) ??
          1,
      wordCount: _intValue(map['word_count'] ?? map['wordCount']) ?? 0,
      toc: toc,
      chapters: chapters,
      payload: payload,
      coverDesigner: CoverDesignerData.fromJson(finalDesigner),
    );
  }

  String get identifier => slug.trim().isNotEmpty ? slug.trim() : '${id ?? ''}';

  bool get hasFrozenCover {
    return finalCoverImageUrl.trim().isNotEmpty ||
        renderedCoverUrl.trim().isNotEmpty;
  }

  String get coverSource {
    final source = _firstNonEmpty([
      finalCoverImageUrl,
      renderedCoverUrl,
      coverImageUrl,
      thumbnailUrl,
      imageUrl,
      rawCoverImageUrl,
      coverDesigner.bgImageUrl,
    ]);
    return source.trim();
  }

  bool get isManualLike {
    final t = bookType.trim().toLowerCase();
    return t == 'manual' || t == 'compiled' || t == 'chaptered';
  }

  bool get isPdf => bookType.trim().toLowerCase() == 'pdf';

  bool get isExternal => bookType.trim().toLowerCase() == 'external';

  bool get isLocked {
    final access = accessType.trim().toLowerCase();
    return access == 'premium' ||
        access == 'token' ||
        access == 'login_required';
  }

  double get pageAspectRatio {
    return BookPageSizeSpec.fromBackend(bookPageSize).aspectRatio;
  }

  String get pageSizeLabel {
    return BookPageSizeSpec.fromBackend(bookPageSize).label;
  }

  String get resolvedReaderFont {
    final raw = readerFont.trim().toLowerCase();
    if (raw.isEmpty) return 'serif';
    return raw;
  }

  String get resolvedPageTheme {
    final raw = pageTheme.trim().toLowerCase();
    if (raw.isEmpty) return 'classic';
    return raw;
  }
}

class BookPageSizeSpec {
  final String key;
  final String label;
  final double width;
  final double height;
  final int baseWords;

  const BookPageSizeSpec({
    required this.key,
    required this.label,
    required this.width,
    required this.height,
    required this.baseWords,
  });

  double get aspectRatio => width / height;

  static BookPageSizeSpec fromBackend(String value) {
    final key = value.trim().toLowerCase();
    switch (key) {
      case 'portrait_3_4':
      case 'cover_3x4':
      case '3x4':
        return const BookPageSizeSpec(
          key: 'portrait_3_4',
          label: 'Portrait 3:4',
          width: 3,
          height: 4,
          baseWords: 130,
        );
      case 'portrait_4_5':
      case '4x5':
        return const BookPageSizeSpec(
          key: 'portrait_4_5',
          label: 'Portrait 4:5',
          width: 4,
          height: 5,
          baseWords: 145,
        );
      case 'portrait_2_3':
      case 'paperback_2x3':
      case '2x3':
        return const BookPageSizeSpec(
          key: 'portrait_2_3',
          label: 'Paperback 2:3',
          width: 2,
          height: 3,
          baseWords: 118,
        );
      case 'square_1_1':
      case 'square':
        return const BookPageSizeSpec(
          key: 'square_1_1',
          label: 'Square 1:1',
          width: 1,
          height: 1,
          baseWords: 105,
        );
      case 'landscape_16_9':
      case '16x9':
      case 'landscape':
        return const BookPageSizeSpec(
          key: 'landscape_16_9',
          label: 'Landscape 16:9',
          width: 16,
          height: 9,
          baseWords: 120,
        );
      case 'standard_6x9':
      case 'book_6x9':
      case '6x9':
      default:
        return const BookPageSizeSpec(
          key: 'standard_6x9',
          label: 'Standard Book 6×9',
          width: 6,
          height: 9,
          baseWords: 135,
        );
    }
  }
}

class BooksListResponse {
  final List<BookItem> items;
  final Map<String, dynamic> meta;

  const BooksListResponse({required this.items, required this.meta});

  factory BooksListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['data'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => BookItem.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false)
        : <BookItem>[];

    return BooksListResponse(
      items: items,
      meta: _mapValue(json['meta']),
    );
  }
}

Map<String, dynamic> _mapValue(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

String _stringValue(
  Map<String, dynamic> map,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = map[key];
    final clean = value?.toString().trim() ?? '';
    if (clean.isNotEmpty && clean.toLowerCase() != 'null') return clean;
  }
  return fallback;
}

String _firstNonEmpty(List<String> values) {
  for (final value in values) {
    final clean = value.trim();
    if (clean.isNotEmpty && clean.toLowerCase() != 'null') return clean;
  }
  return '';
}

int? _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString().trim());
}

bool? _boolValue(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value == 1;
  final clean = (value ?? '').toString().trim().toLowerCase();
  if (['1', 'true', 'yes', 'on'].contains(clean)) return true;
  if (['0', 'false', 'no', 'off'].contains(clean)) return false;
  return null;
}
