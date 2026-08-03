import 'package:flutter/material.dart';

import '../../../../features/books/models/book_models.dart';
import 'designed_book_cover.dart';

class BookCard extends StatelessWidget {
  final BookItem book;
  final VoidCallback onTap;
  final bool compact;
  final bool isLight;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.compact = false,
    this.isLight = false,
  });

  @override
  Widget build(BuildContext context) {
    final panel =
        isLight ? const Color(0xFFFFFBF4) : Colors.white.withOpacity(0.055);
    final border =
        isLight ? const Color(0xFFE6D8C3) : Colors.white.withOpacity(0.08);
    final titleColor = isLight ? const Color(0xFF1E1B16) : Colors.white;
    final subColor =
        isLight ? const Color(0xFF6B6256) : Colors.white.withOpacity(0.66);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
          boxShadow: isLight
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: DesignedBookCover(
                  book: book,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: titleColor,
                fontSize: 14.6,
                height: 1.12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              book.authorName.trim().isNotEmpty
                  ? book.authorName.trim()
                  : (book.subtitle.trim().isNotEmpty
                      ? book.subtitle.trim()
                      : 'Book Library'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: subColor,
                fontSize: 11.8,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Badge(text: book.accessType.toUpperCase(), isLight: isLight),
                if (book.chapterCount > 0)
                  _Badge(text: '${book.chapterCount} CH', isLight: isLight),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FeaturedBookCard extends StatelessWidget {
  final BookItem book;
  final VoidCallback onTap;
  final bool isLight;

  const FeaturedBookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.isLight = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
        width: 312,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: isLight
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFDF6EA),
                    Color(0xFFEDE5FF),
                    Color(0xFFFFD9EC),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF172A66).withOpacity(0.94),
                    const Color(0xFF5B1FA8).withOpacity(0.86),
                    const Color(0xFFB70E7C).withOpacity(0.78),
                  ],
                ),
          border: Border.all(
            color: isLight
                ? const Color(0xFFE6D8C3)
                : Colors.white.withOpacity(0.10),
          ),
          boxShadow: isLight
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 94,
              child: DesignedBookCover(
                book: book,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Badge(text: book.accessType.toUpperCase(), isLight: isLight),
                  const SizedBox(height: 10),
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isLight ? const Color(0xFF1E1B16) : Colors.white,
                      fontSize: 18,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (book.subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      book.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isLight
                            ? const Color(0xFF6B6256)
                            : Colors.white.withOpacity(0.78),
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    '${book.chapterCount} chapters • ${book.estimatedReadingMinutes} min',
                    style: TextStyle(
                      color: isLight
                          ? const Color(0xFF6B6256)
                          : Colors.white.withOpacity(0.70),
                      fontSize: 11.7,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final bool isLight;

  const _Badge({
    required this.text,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isLight
        ? const Color(0xFFFFFFFF).withOpacity(0.70)
        : Colors.white.withOpacity(0.13);
    final border =
        isLight ? const Color(0xFFE0D0BC) : Colors.white.withOpacity(0.16);
    final color = isLight ? const Color(0xFF4C453A) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: bg,
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 9.8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
