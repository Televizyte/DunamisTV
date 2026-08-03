import 'package:flutter/material.dart';

import '../../shared/designers/dxm_dynamic_article_card.dart';

class InspireItem {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback onTap;
  final Map<String, dynamic>? designPayload;
  final String? pillText;
  final IconData? icon;

  InspireItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.imageUrl,
    this.designPayload,
    this.pillText,
    this.icon,
  });
}

class InspireFeaturedGrid extends StatelessWidget {
  final List<InspireItem> featured;
  final List<InspireItem> items;
  final String emptyTitle;
  final String emptySubtitle;

  const InspireFeaturedGrid({
    super.key,
    required this.featured,
    required this.items,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 18),
      children: [
        if (featured.isNotEmpty) ...[
          const _SectionTitle(title: 'Featured'),
          const SizedBox(height: 10),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: featured.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => DxmDynamicArticleCard(
                title: featured[index].title,
                subtitle: featured[index].subtitle,
                imageUrl: featured[index].imageUrl,
                fallbackAsset: _fallbackAssetFor(index),
                pillText: featured[index].pillText ?? 'FEATURED',
                icon: featured[index].icon ?? Icons.auto_awesome_rounded,
                onTap: featured[index].onTap,
                designPayload: featured[index].designPayload,
                featured: true,
                width: 260,
                height: 170,
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
        const _SectionTitle(title: 'Browse'),
        const SizedBox(height: 10),
        if (items.isEmpty)
          _EmptyState(title: emptyTitle, subtitle: emptySubtitle)
        else
          _Grid(items: items),
      ],
    );
  }

  static String _fallbackAssetFor(int index) {
    const assets = [
      'assets/images/home_4.jpg',
      'assets/images/home_3.jpg',
      'assets/images/home_5.jpg',
      'assets/images/home_2.jpg',
      'assets/images/home_1.jpg',
    ];

    return assets[index % assets.length];
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final List<InspireItem> items;

  const _Grid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.22,
      ),
      itemBuilder: (context, i) => DxmDynamicArticleCard(
        title: items[i].title,
        subtitle: items[i].subtitle,
        imageUrl: items[i].imageUrl,
        fallbackAsset: InspireFeaturedGrid._fallbackAssetFor(i),
        pillText: items[i].pillText ?? '',
        icon: items[i].icon ?? Icons.auto_awesome_rounded,
        onTap: items[i].onTap,
        designPayload: items[i].designPayload,
        featured: false,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1228),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.70),
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
