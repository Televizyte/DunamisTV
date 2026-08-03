import 'package:flutter/material.dart';

class HeroCarousel extends StatefulWidget {
  /// For now: pass asset paths if you have them.
  /// If empty, it renders colorful placeholders.
  final List<String> assetImages;
  final double height;

  const HeroCarousel({
    super.key,
    required this.assetImages,
    this.height = 150,
  });

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  int _index = 0;

  int get _count => (widget.assetImages.isEmpty) ? 5 : widget.assetImages.length;

  void _go(int next) {
    if (_count <= 1) return;
    final clamped = next.clamp(0, _count - 1);
    _controller.animateToPage(
      clamped,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height + 26,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _count,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final hasAssets = widget.assetImages.isNotEmpty;
              final asset = hasAssets ? widget.assetImages[i] : null;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: !hasAssets
                        ? const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFF5B1E9B),
                              Color(0xFFB1007A),
                            ],
                          )
                        : null,
                    color: hasAssets ? Colors.white.withOpacity(0.06) : null,
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasAssets
                      ? Image.asset(asset!, fit: BoxFit.cover)
                      : const SizedBox.expand(),
                ),
              );
            },
          ),

          // Left Arrow
          Positioned(
            left: 6,
            top: (widget.height / 2) - 18,
            child: _ArrowButton(
              icon: Icons.chevron_left_rounded,
              onTap: _index <= 0 ? null : () => _go(_index - 1),
            ),
          ),

          // Right Arrow
          Positioned(
            right: 6,
            top: (widget.height / 2) - 18,
            child: _ArrowButton(
              icon: Icons.chevron_right_rounded,
              onTap: _index >= _count - 1 ? null : () => _go(_index + 1),
            ),
          ),

          // Dots
          Positioned(
            left: 0,
            right: 0,
            bottom: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_count, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: active ? 18 : 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: active
                        ? const Color(0xFFFF2D95)
                        : Colors.white.withOpacity(0.22),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Icon(
            icon,
            color: onTap == null ? Colors.white.withOpacity(0.35) : Colors.white,
          ),
        ),
      ),
    );
  }
}
