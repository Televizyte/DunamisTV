import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../media/universal_media_launcher.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';

class WatchVideoHubScreen extends StatelessWidget {
  const WatchVideoHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = (GoRouterState.of(context).extra as Map?) ?? {};
    final rawItems = (extra['items'] as List?) ?? const [];

    final items = rawItems
        .whereType<Map>()
        .map(
          (m) => _WatchVideoItem(
            title: (m['title'] ?? '').toString().trim(),
            type: (m['type'] ?? 'youtube').toString().trim(),
            url: (m['url'] ?? '').toString().trim(),
            subtitle: (m['subtitle'] ?? '').toString().trim(),
            imageUrl: (m['image_url'] ??
                    m['cover_url'] ??
                    m['thumbnail_url'] ??
                    m['banner_url'] ??
                    '')
                .toString()
                .trim(),
          ),
        )
        .where((m) => m.title.isNotEmpty && m.url.isNotEmpty)
        .toList(growable: false);

    final slides = _buildSlides(items);

    return Scaffold(
      appBar: DxmTopBar(
        title: 'Videos',
        showBack: true,
        showMenu: true,
        onBack: () => context.pop(),
      ),
      body: GradientPageBackground(
        child: items.isEmpty
            ? Center(
                child: Text(
                  'No videos yet (waiting for AppsHub).',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: _WatchVideoHeroCarousel(slides: slides),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Video Collections',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Open available broadcasts, highlights, playlists and teaching videos.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.68),
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(items.length, (index) {
                          final item = items[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == items.length - 1 ? 20 : 14,
                            ),
                            child: _WatchVideoLargeCard(
                              item: item,
                              fallbackAsset: _fallbackAssetFor(index, const [
                                'assets/images/watch_1.jpg',
                                'assets/images/watch_2.jpg',
                                'assets/images/watch_3.jpg',
                                'assets/images/watch_4.jpg',
                                'assets/images/watch_5.jpg',
                              ]),
                              onTap: () => UniversalMediaLauncher.open(
                                context,
                                title: item.title,
                                url: item.url,
                                type: item.type,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  static List<Map<String, String>> _buildSlides(List<_WatchVideoItem> items) {
    if (items.isEmpty) {
      return const [
        {
          'title': 'Videos',
          'subtitle': 'Open available broadcasts, highlights and playlists',
          'image_url': '',
        },
      ];
    }

    final slides = <Map<String, String>>[];
    for (final item in items.take(4)) {
      slides.add({
        'title': item.title,
        'subtitle':
            item.subtitle.isNotEmpty ? item.subtitle : 'Open video collection',
        'image_url': item.imageUrl,
      });
    }
    return slides;
  }

  static String _fallbackAssetFor(int index, List<String> assets) {
    return assets[index % assets.length];
  }
}

class _WatchVideoItem {
  final String title;
  final String type;
  final String url;
  final String subtitle;
  final String imageUrl;

  const _WatchVideoItem({
    required this.title,
    required this.type,
    required this.url,
    required this.subtitle,
    required this.imageUrl,
  });
}

class _WatchVideoHeroCarousel extends StatefulWidget {
  final List<Map<String, String>> slides;

  const _WatchVideoHeroCarousel({
    required this.slides,
  });

  @override
  State<_WatchVideoHeroCarousel> createState() =>
      _WatchVideoHeroCarouselState();
}

class _WatchVideoHeroCarouselState extends State<_WatchVideoHeroCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  List<Map<String, String>> get _effectiveSlides {
    if (widget.slides.isNotEmpty) return widget.slides;
    return const [
      {
        'title': 'Videos',
        'subtitle': 'Open available broadcasts, highlights and playlists',
        'image_url': '',
      },
    ];
  }

  String _fallbackAssetFor(int index) {
    const assets = [
      'assets/images/watch_1.jpg',
      'assets/images/watch_2.jpg',
      'assets/images/watch_3.jpg',
      'assets/images/watch_4.jpg',
    ];
    return assets[index % assets.length];
  }

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 1.0);
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant _WatchVideoHeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slides.length != widget.slides.length) {
      _index = 0;
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _timer?.cancel();

    final count = _effectiveSlides.length;
    if (count <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_index + 1) % count;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _goTo(int next) {
    final count = _effectiveSlides.length;
    if (count == 0) return;

    final safe = (next % count + count) % count;
    _controller.animateToPage(
      safe,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _effectiveSlides;

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: PageView.builder(
                  controller: _controller,
                  itemCount: slides.length,
                  onPageChanged: (value) {
                    if (!mounted) return;
                    setState(() => _index = value);
                  },
                  itemBuilder: (context, i) {
                    final slide = slides[i];
                    return _WatchVideoHeroSlide(
                      title: slide['title']?.trim().isNotEmpty == true
                          ? slide['title']!
                          : 'Videos',
                      subtitle: slide['subtitle']?.trim().isNotEmpty == true
                          ? slide['subtitle']!
                          : 'Open available broadcasts, highlights and playlists',
                      imageUrl: slide['image_url'],
                      fallbackAsset: _fallbackAssetFor(i),
                    );
                  },
                ),
              ),
              if (slides.length > 1)
                Positioned(
                  left: 10,
                  top: 0,
                  bottom: 0,
                  child: _WatchVideoArrowButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _goTo(_index - 1),
                  ),
                ),
              if (slides.length > 1)
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: _WatchVideoArrowButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => _goTo(_index + 1),
                  ),
                ),
            ],
          ),
        ),
        if (slides.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              slides.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 16 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _index
                      ? const Color(0xFFFF3CA6)
                      : Colors.white.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _WatchVideoHeroSlide extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String fallbackAsset;

  const _WatchVideoHeroSlide({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.fallbackAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _WatchVideoSmartImage(
          imageUrl: imageUrl,
          fallbackAsset: fallbackAsset,
          height: 190,
        ),
        Container(
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.16),
                Colors.black.withOpacity(0.28),
                Colors.black.withOpacity(0.82),
              ],
              stops: const [0.0, 0.42, 1.0],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WatchVideoArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _WatchVideoArrowButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.black.withOpacity(0.28),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _WatchVideoLargeCard extends StatelessWidget {
  final _WatchVideoItem item;
  final String fallbackAsset;
  final VoidCallback onTap;

  const _WatchVideoLargeCard({
    required this.item,
    required this.fallbackAsset,
    required this.onTap,
  });

  String _badgeForType() {
    final t = item.type.toLowerCase();
    if (t == 'hls') return 'LIVE';
    if (t == 'youtube') return 'YOUTUBE';
    if (t == 'audio') return 'AUDIO';
    return 'LINK';
  }

  String _subtitleForType() {
    if (item.subtitle.isNotEmpty) return item.subtitle;

    final t = item.type.toLowerCase();
    if (t == 'hls') return 'Watch live stream';
    if (t == 'youtube') return 'Watch in-app';
    if (t == 'audio') return 'Listen in app';
    return 'Open external link';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.18),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: _WatchVideoSmartImage(
                  imageUrl: item.imageUrl,
                  fallbackAsset: fallbackAsset,
                  height: 180,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.12),
                      Colors.black.withOpacity(0.24),
                      Colors.black.withOpacity(0.80),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WatchVideoBadge(text: _badgeForType()),
                    const Spacer(),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _subtitleForType(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.90),
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WatchVideoSmartImage extends StatelessWidget {
  final String? imageUrl;
  final String fallbackAsset;
  final double height;

  const _WatchVideoSmartImage({
    required this.imageUrl,
    required this.fallbackAsset,
    required this.height,
  });

  bool get _hasRemoteImage => (imageUrl ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_hasRemoteImage) {
      return Image.network(
        imageUrl!.trim(),
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Image.asset(
            fallbackAsset,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: height,
              width: double.infinity,
              color: const Color(0xFF1B1B2A),
            ),
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: height,
            width: double.infinity,
            color: const Color(0xFF151528),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          );
        },
      );
    }

    return Image.asset(
      fallbackAsset,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        width: double.infinity,
        color: const Color(0xFF1B1B2A),
      ),
    );
  }
}

class _WatchVideoBadge extends StatelessWidget {
  final String text;

  const _WatchVideoBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
