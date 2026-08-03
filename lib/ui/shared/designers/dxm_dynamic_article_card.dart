import 'package:flutter/material.dart';

import 'dxm_design_parser.dart';
import 'dxm_font_mapper.dart';

class DxmDynamicArticleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String fallbackAsset;
  final String pillText;
  final IconData icon;
  final VoidCallback onTap;
  final Map<String, dynamic>? designPayload;
  final bool featured;
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const DxmDynamicArticleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.imageUrl,
    this.fallbackAsset = 'assets/images/home_4.jpg',
    this.pillText = '',
    this.icon = Icons.auto_awesome_rounded,
    this.designPayload,
    this.featured = false,
    this.width,
    this.height = 176,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
  });

  @override
  Widget build(BuildContext context) {
    final design = DxmDesignData.fromMap(
      _mergeArticleFallbackDesign(designPayload ?? const <String, dynamic>{}),
      imageUrl: (imageUrl ?? '').trim(),
      fallbackAsset: fallbackAsset,
      fallbackMainFontSize: featured ? 18 : 14,
      fallbackSupportFontSize: featured ? 12.8 : 12,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _ArticleBackground(
                  design: design,
                  imageUrl: (imageUrl ?? '').trim(),
                  fallbackAsset: fallbackAsset,
                ),
                _ArticleOverlay(design: design),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      border: Border.all(
                        color: design.accentColor.withOpacity(0.18),
                      ),
                    ),
                  ),
                ),
                if (featured)
                  _FeaturedLayout(
                    title: title,
                    subtitle: subtitle,
                    pillText: pillText,
                    icon: icon,
                    design: design,
                  )
                else
                  _GridLayout(
                    title: title,
                    subtitle: subtitle,
                    pillText: pillText,
                    icon: icon,
                    design: design,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _mergeArticleFallbackDesign(
      Map<String, dynamic> source) {
    final output = Map<String, dynamic>.from(source);

    void putIfBlank(String key, dynamic value) {
      final current = output[key];
      if (current == null) {
        output[key] = value;
        return;
      }
      if (current is String && current.trim().isEmpty) {
        output[key] = value;
      }
    }

    putIfBlank('background_mode',
        (imageUrl ?? '').trim().isNotEmpty ? 'image' : 'gradient');
    putIfBlank('image_url', (imageUrl ?? '').trim());
    putIfBlank('card_format', featured ? 'landscape' : 'square');
    putIfBlank('font_family', 'system');
    putIfBlank('text_scale_mode', 'auto');
    putIfBlank('text_color', '#ffffff');
    putIfBlank('bg_color', '#1B2350');
    putIfBlank('bg_color_2', '#B70E7C');
    putIfBlank('accent_color', '#38BDF8');
    putIfBlank('title_size', featured ? '18' : '14');
    putIfBlank('font_size', featured ? '12.8' : '12');
    putIfBlank('font_weight', '800');
    putIfBlank('text_align', 'left');
    putIfBlank('vertical_align', 'end');
    putIfBlank('overlay_strength', '72');
    putIfBlank('content_width', '100');
    putIfBlank('card_padding', featured ? '16' : '12');
    putIfBlank('line_height', '1.18');
    putIfBlank('show_quote_mark', false);

    return output;
  }
}

class _FeaturedLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final String pillText;
  final IconData icon;
  final DxmDesignData design;

  const _FeaturedLayout({
    required this.title,
    required this.subtitle,
    required this.pillText,
    required this.icon,
    required this.design,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(design.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pillText.trim().isNotEmpty) _Pill(text: pillText, design: design),
          const Spacer(),
          Text(
            title.trim().isEmpty ? 'Untitled' : title.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: design.textAlign,
            style: DxmFontMapper.style(
              design.fontFamily,
              fontSize: design.autoMainFontSize(title),
              fontWeight: FontWeight.w900,
              color: design.textColor,
              height: design.lineHeight,
              shadows: _textShadows(design),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: design.textAlign,
            style: DxmFontMapper.style(
              design.fontFamily,
              fontSize: design.supportFontSize,
              fontWeight: FontWeight.w700,
              color: design.textColor.withOpacity(0.86),
              height: 1.22,
              shadows: _textShadows(design),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _IconBadge(icon: icon, design: design),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: design.textColor.withOpacity(0.78),
                size: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final String pillText;
  final IconData icon;
  final DxmDesignData design;

  const _GridLayout({
    required this.title,
    required this.subtitle,
    required this.pillText,
    required this.icon,
    required this.design,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(design.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBadge(icon: icon, design: design),
          const SizedBox(height: 10),
          if (pillText.trim().isNotEmpty) ...[
            _Pill(text: pillText, design: design),
            const SizedBox(height: 8),
          ],
          Text(
            title.trim().isEmpty ? 'Untitled' : title.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: design.textAlign,
            style: DxmFontMapper.style(
              design.fontFamily,
              fontSize: design.autoMainFontSize(title),
              fontWeight: FontWeight.w900,
              color: design.textColor,
              height: design.lineHeight,
              shadows: _textShadows(design),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              subtitle.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: design.textAlign,
              style: DxmFontMapper.style(
                design.fontFamily,
                fontSize: design.supportFontSize,
                fontWeight: FontWeight.w700,
                color: design.textColor.withOpacity(0.72),
                height: 1.2,
                shadows: _textShadows(design),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleBackground extends StatelessWidget {
  final DxmDesignData design;
  final String imageUrl;
  final String fallbackAsset;

  const _ArticleBackground({
    required this.design,
    required this.imageUrl,
    required this.fallbackAsset,
  });

  @override
  Widget build(BuildContext context) {
    if (design.usesImageBackground && imageUrl.trim().isNotEmpty) {
      return _SmartImage(
        imageUrl: imageUrl.trim(),
        fallback: _gradientFallback(),
        fallbackAsset: fallbackAsset,
      );
    }

    return _gradientFallback();
  }

  Widget _gradientFallback() {
    if (design.usesSolidBackground) {
      return DecoratedBox(
        decoration: BoxDecoration(color: design.backgroundColor),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            design.backgroundColor,
            design.backgroundColor2,
          ],
        ),
      ),
    );
  }
}

class _ArticleOverlay extends StatelessWidget {
  final DxmDesignData design;

  const _ArticleOverlay({required this.design});

  @override
  Widget build(BuildContext context) {
    final strength = design.overlayStrength.clamp(0.0, 1.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.10 * strength),
            Colors.black.withOpacity(0.34 * strength),
            Colors.black.withOpacity(0.90 * strength),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}

class _SmartImage extends StatelessWidget {
  final String imageUrl;
  final Widget fallback;
  final String fallbackAsset;

  const _SmartImage({
    required this.imageUrl,
    required this.fallback,
    required this.fallbackAsset,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _assetFallback(),
      );
    }

    final uri = Uri.tryParse(imageUrl);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _assetFallback(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return fallback;
        },
      );
    }

    return _assetFallback();
  }

  Widget _assetFallback() {
    return Image.asset(
      fallbackAsset,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final DxmDesignData design;

  const _IconBadge({
    required this.icon,
    required this.design,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: design.accentColor.withOpacity(0.26)),
      ),
      child: Icon(
        icon,
        color: design.textColor,
        size: 20,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final DxmDesignData design;

  const _Pill({
    required this.text,
    required this.design,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 34),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: design.accentColor.withOpacity(0.24)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: DxmFontMapper.style(
          design.fontFamily,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: design.textColor,
          height: 1.0,
          shadows: _textShadows(design),
        ).copyWith(
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

List<Shadow> _textShadows(DxmDesignData design) {
  if (design.overlayStrength <= 0.05 && design.usesSolidBackground) {
    return const [];
  }

  return [
    Shadow(
      blurRadius: design.usesImageBackground ? 10 : 7,
      offset: const Offset(0, 2),
      color: Colors.black.withOpacity(design.usesImageBackground ? 0.45 : 0.25),
    ),
  ];
}
