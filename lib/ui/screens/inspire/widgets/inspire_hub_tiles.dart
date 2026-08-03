import 'package:flutter/material.dart';

class InspireHubTiles extends StatelessWidget {
  final int sodCount;
  final int highlightsCount;
  final int wordificationCount;
  final int motivationCount;

  final VoidCallback onOpenSod;
  final VoidCallback onOpenHighlights;
  final VoidCallback onOpenWordification;
  final VoidCallback onOpenArticles;
  final VoidCallback onOpenMotivation;

  const InspireHubTiles({
    super.key,
    required this.sodCount,
    required this.highlightsCount,
    required this.wordificationCount,
    required this.motivationCount,
    required this.onOpenSod,
    required this.onOpenHighlights,
    required this.onOpenWordification,
    required this.onOpenArticles,
    required this.onOpenMotivation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1
        Row(
          children: [
            Expanded(
              child: _Tile(
                title: 'Seed of Destiny',
                subtitle: 'Read • Watch • Key points • Quotes',
                count: sodCount,
                icon: Icons.menu_book_rounded,
                colors: const [Color(0xFF4B1D8A), Color(0xFFE4007C)],
                onTap: onOpenSod,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Tile(
                title: 'Highlights',
                subtitle: 'Quick takeaways + lessons',
                count: highlightsCount,
                icon: Icons.bolt_rounded,
                colors: const [Color(0xFF0B1020), Color(0xFF4B1D8A)],
                onTap: onOpenHighlights,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2
        Row(
          children: [
            Expanded(
              child: _Tile(
                title: 'Wordification',
                subtitle: 'Scripture breakdown + application',
                count: wordificationCount,
                icon: Icons.lightbulb_rounded,
                colors: const [Color(0xFF0B1020), Color(0xFFE4007C)],
                onTap: onOpenWordification,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Tile(
                title: 'Inside Dunamis',
                subtitle: 'Teachings, insights, updates',
                count: 0,
                icon: Icons.newspaper_rounded,
                colors: const [Color(0xFF4B1D8A), Color(0xFF0B1020)],
                onTap: onOpenArticles,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Big wide tile
        _WideTile(
          title: 'Motivation',
          subtitle: 'Short encouragement posts',
          count: motivationCount,
          icon: Icons.favorite_rounded,
          colors: const [Color(0xFFE4007C), Color(0xFF4B1D8A)],
          onTap: onOpenMotivation,
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _Tile({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        height: 128,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.14),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const Spacer(),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withOpacity(0.14),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
              ],
            ),
            const Spacer(),
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
              style: TextStyle(color: Colors.white.withOpacity(0.82), fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _WideTile({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        height: 88,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withOpacity(0.14),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Icon(icon, color: Colors.white),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(0.82), fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withOpacity(0.14),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
            ],
            const SizedBox(width: 10),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.85), size: 30),
          ],
        ),
      ),
    );
  }
}
