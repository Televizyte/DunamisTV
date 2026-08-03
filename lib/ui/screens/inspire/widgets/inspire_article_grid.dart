import 'package:flutter/material.dart';

class InspireArticleGrid extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String emptyTitle;
  final String emptySubtitle;
  final void Function(Map<String, dynamic> item) onTapItem;

  const InspireArticleGrid({
    super.key,
    required this.items,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyGridCard(title: emptyTitle, subtitle: emptySubtitle);
    }

    final preview = items.length > 4 ? items.take(4).toList() : items;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: preview.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, i) {
        final item = preview[i];
        return _ArticleThumbCard(item: item, onTap: () => onTapItem(item));
      },
    );
  }
}

class _EmptyGridCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyGridCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        color: const Color(0xFF0D1228),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4B1D8A), Color(0xFFE4007C)],
              ),
            ),
            child: const Icon(Icons.library_books_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleThumbCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _ArticleThumbCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = (item['title'] ?? 'Inside Dunamis').toString().trim();
    final category = (item['category'] ?? 'Teaching').toString().trim();
    final image = (item['image'] ?? '').toString().trim();

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
          image: image.isNotEmpty
              ? DecorationImage(image: NetworkImage(image), fit: BoxFit.cover, onError: (_, __) {})
              : null,
          gradient: image.isEmpty
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0B1020), Color(0xFF4B1D8A)],
                )
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.12),
                Colors.black.withOpacity(0.78),
              ],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withOpacity(0.12),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11.5),
                ),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.85)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
