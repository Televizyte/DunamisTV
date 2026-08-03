import 'package:flutter/material.dart';

import '../../../../features/books/models/book_models.dart';

/// Book cover renderer used by every Flutter book surface.
///
/// Priority:
/// 1. backend frozen/final cover image via [BookItem.coverSource]
/// 2. safe local fallback using cover designer metadata
/// 3. simple generated placeholder
///
/// This keeps the app dynamic and backend-driven without trying to rebuild the
/// full cover design when AppsHub already sends a finished PNG/JPEG.
class DesignedBookCover extends StatelessWidget {
  final BookItem book;
  final BorderRadiusGeometry borderRadius;
  final BoxFit fit;
  final bool showShadow;

  const DesignedBookCover({
    super.key,
    required this.book,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.fit = BoxFit.cover,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final source = book.coverSource.trim();

    return AspectRatio(
      aspectRatio: _coverAspectRatio(book.coverRatio),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: source.isNotEmpty
              ? Image.network(
                  source,
                  fit: fit,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => _FallbackCover(book: book),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return _LoadingCover(book: book);
                  },
                )
              : _FallbackCover(book: book),
        ),
      ),
    );
  }

  double _coverAspectRatio(String rawRatio) {
    final ratio = rawRatio.trim().toLowerCase();
    switch (ratio) {
      case 'portrait_2_3':
      case '2x3':
      case 'paperback_2x3':
        return 2 / 3;
      case 'portrait_4_5':
      case '4x5':
        return 4 / 5;
      case 'square_1_1':
      case 'square':
        return 1;
      case 'landscape_16_9':
      case '16x9':
        return 16 / 9;
      case 'portrait_3_4':
      case 'cover_3x4':
      case '3x4':
      default:
        return 3 / 4;
    }
  }
}

class _LoadingCover extends StatelessWidget {
  final BookItem book;

  const _LoadingCover({required this.book});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _FallbackCover(book: book),
        Container(
          color: Colors.black.withOpacity(0.12),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ],
    );
  }
}

class _FallbackCover extends StatelessWidget {
  final BookItem book;

  const _FallbackCover({required this.book});

  @override
  Widget build(BuildContext context) {
    final designer = book.coverDesigner;
    final title =
        designer.title.trim().isNotEmpty ? designer.title : book.title;
    final subtitle =
        designer.subtitle.trim().isNotEmpty ? designer.subtitle : book.subtitle;
    final author =
        designer.author.trim().isNotEmpty ? designer.author : book.authorName;
    final badge = designer.badge.trim().isNotEmpty ? designer.badge : 'Book';
    final bg = _colorFromHex(designer.bgColor, const Color(0xFF0B1F4D));
    final accent =
        _colorFromHex(designer.gradientColor, const Color(0xFFE2388A));
    final text = _colorFromHex(designer.textColor, Colors.white);

    final bgImage = designer.bgImageUrl.trim();

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bg, accent.withOpacity(0.58)],
            ),
          ),
        ),
        if (bgImage.isNotEmpty)
          Image.network(
            bgImage,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        Container(color: Colors.black.withOpacity(designer.overlay / 100)),
        Positioned(
          left: 18,
          right: 18,
          top: 18,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withOpacity(0.14),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
              ),
              child: Text(
                badge.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: text,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 42, 18, 24),
          child: Column(
            mainAxisAlignment: _mainAxisAlignment(designer.textPosition),
            crossAxisAlignment: _crossAxisAlignment(designer.textAlign),
            children: [
              Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: _textAlign(designer.textAlign),
                style: TextStyle(
                  color: text,
                  fontSize: 26,
                  height: 0.96,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  shadows: _textShadows(designer.textShadow),
                ),
              ),
              if (subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: _textAlign(designer.textAlign),
                  style: TextStyle(
                    color: text.withOpacity(0.92),
                    fontSize: 11.5,
                    height: 1.16,
                    fontWeight: FontWeight.w800,
                    shadows: _textShadows(designer.textShadow),
                  ),
                ),
              ],
              if (author.trim().isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  author.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: _textAlign(designer.textAlign),
                  style: TextStyle(
                    color: text.withOpacity(0.68),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Color _colorFromHex(String value, Color fallback) {
    var clean = value.trim();
    if (clean.isEmpty) return fallback;
    if (clean.startsWith('#')) clean = clean.substring(1);
    if (clean.length == 6) clean = 'FF$clean';
    final parsed = int.tryParse(clean, radix: 16);
    if (parsed == null) return fallback;
    return Color(parsed);
  }

  MainAxisAlignment _mainAxisAlignment(String value) {
    switch (value.trim().toLowerCase()) {
      case 'top':
        return MainAxisAlignment.start;
      case 'center':
      case 'middle':
        return MainAxisAlignment.center;
      case 'bottom':
      default:
        return MainAxisAlignment.end;
    }
  }

  CrossAxisAlignment _crossAxisAlignment(String value) {
    switch (value.trim().toLowerCase()) {
      case 'center':
        return CrossAxisAlignment.center;
      case 'right':
      case 'end':
        return CrossAxisAlignment.end;
      case 'left':
      default:
        return CrossAxisAlignment.start;
    }
  }

  TextAlign _textAlign(String value) {
    switch (value.trim().toLowerCase()) {
      case 'center':
        return TextAlign.center;
      case 'right':
      case 'end':
        return TextAlign.right;
      case 'left':
      default:
        return TextAlign.left;
    }
  }

  List<Shadow>? _textShadows(String value) {
    final shadow = value.trim().toLowerCase();
    if (shadow == 'none' || shadow == 'off') return null;
    return [
      Shadow(
        color: Colors.black.withOpacity(shadow == 'strong' ? 0.75 : 0.45),
        blurRadius: shadow == 'strong' ? 12 : 8,
        offset: const Offset(0, 2),
      ),
    ];
  }
}
