import 'package:flutter/material.dart';

class HeroSlide {
  final String? assetPath; // optional
  final String? label; // optional
  const HeroSlide({this.assetPath, this.label});
}

class HeroBanner extends StatefulWidget {
  /// Optional (prevents compile errors on old screens)
  final String title;

  final String? subtitle;
  final double height;

  /// Backward-compat:
  /// Old code uses: HeroBanner(images: [...])
  /// New code can use: HeroBanner(slides: [...])
  final List<String> images;
  final List<HeroSlide> slides;

  /// Show left/right arrows for manual navigation.
  final bool showArrows;

  const HeroBanner({
    super.key,
    this.title = '',
    this.subtitle,
    this.height = 190,
    this.images = const [],
    this.slides = const [],
    this.showArrows = true,
  });

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  final PageController _controller = PageController();
  int _index = 0;

  List<HeroSlide> get _resolvedSlides {
    if (widget.slides.isNotEmpty) return widget.slides;
    if (widget.images.isNotEmpty) {
      return widget.images.map((p) => HeroSlide(assetPath: p)).toList();
    }
    return const [HeroSlide()];
  }

  int get _count => _resolvedSlides.length;

  void _goTo(int next) {
    if (!_controller.hasClients) return;
    final clamped = next.clamp(0, _count - 1);
    _controller.animateToPage(
      clamped,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _fallbackGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF070A17),
            Color(0xFF0B1020),
            Color(0xFF140B2D),
            Color(0xFFB70E7C),
          ],
        ),
      ),
    );
  }

  Widget _slideBackground(HeroSlide slide) {
    final path = slide.assetPath;
    if (path == null || path.trim().isEmpty) return _fallbackGradient();

    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallbackGradient(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = _resolvedSlides;

    final hasOverlayText = widget.title.trim().isNotEmpty ||
        (widget.subtitle != null && widget.subtitle!.trim().isNotEmpty);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height: widget.height,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _controller,
                    itemCount: slides.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final slide = slides[i];
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          _slideBackground(slide),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.55),
                                  Colors.black.withOpacity(0.15),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // Title overlay (only shows if title/subtitle exists)
                  if (hasOverlayText)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.title.trim().isNotEmpty)
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          if (widget.subtitle != null &&
                              widget.subtitle!.trim().isNotEmpty) ...[
                            if (widget.title.trim().isNotEmpty)
                              const SizedBox(height: 4),
                            Text(
                              widget.subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.82),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Left / Right arrows (stay on image)
                  if (widget.showArrows && slides.length > 1) ...[
                    Positioned(
                      left: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _ArrowButton(
                          icon: Icons.chevron_left_rounded,
                          onTap: () => _goTo(_index - 1),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _ArrowButton(
                          icon: Icons.chevron_right_rounded,
                          onTap: () => _goTo(_index + 1),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ✅ Dots indicator moved BELOW the banner image
          if (slides.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFFF2AA3)
                        : Colors.white.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.28),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
