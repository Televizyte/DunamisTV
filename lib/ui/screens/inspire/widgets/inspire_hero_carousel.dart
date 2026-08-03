import 'package:flutter/material.dart';

class InspireHeroCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic> item) onTapItem;

  const InspireHeroCarousel({
    super.key,
    required this.items,
    required this.onTapItem,
  });

  @override
  State<InspireHeroCarousel> createState() => _InspireHeroCarouselState();
}

class _InspireHeroCarouselState extends State<InspireHeroCarousel> {
  final _controller = PageController(viewportFraction: 0.94);
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items.isEmpty ? [_fallbackItem()] : widget.items;

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final item = items[i];
              return _HeroCard(
                item: item,
                onTap: () => widget.onTapItem(item),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _Dots(count: items.length, index: _index),
      ],
    );
  }

  Map<String, dynamic> _fallbackItem() => {
        'title': 'Featured Teaching',
        'subtitle': 'FireDrive will control this soon',
        'type': 'article',
        'url': '',
        'id': '',
        'image': '',
      };
}

class _HeroCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _HeroCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = (item['title'] ?? 'Featured Teaching').toString().trim();
    final subtitle = (item['subtitle'] ?? '').toString().trim();
    final image = (item['image'] ?? '').toString().trim();

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.30),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
            image: image.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(image),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  )
                : null,
            gradient: image.isEmpty
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0B1020),
                      Color(0xFF4B1D8A),
                      Color(0xFFE4007C),
                    ],
                  )
                : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.70),
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.14),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          height: 1.1,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.80),
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.80),
                  size: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;

  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 18 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: active ? const Color(0xFFE4007C) : Colors.white.withOpacity(0.25),
          ),
        );
      }),
    );
  }
}
