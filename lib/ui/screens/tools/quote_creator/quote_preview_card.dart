import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../features/quote_creator/state/quote_creator_store.dart';

class QuotePreviewCard extends StatelessWidget {
  final QuoteCreatorStore store;
  final bool isLight;

  const QuotePreviewCard({
    required this.store,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final quoteText =
        store.quote.trim().isEmpty ? 'Your quote preview' : store.quote.trim();
    final authorText = store.author.trim();

    final quoteBaseStyle = _resolveFontStyle(
      fontFamily: store.fontFamily,
      color: store.textColor,
      fontSize: store.fontSize,
      height: 1.28,
      fontWeight: FontWeight.w700,
    );

    final authorStyle = _resolveFontStyle(
      fontFamily: store.fontFamily,
      color: store.authorColor,
      fontSize: store.authorFontSize,
      height: 1.25,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE6D8C3)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: Container(
            decoration: BoxDecoration(
              color: store.backgroundColor,
              gradient: store.backgroundGradient,
            ),
            child: Stack(
              children: [
                if ((store.backgroundImage ?? '').trim().isNotEmpty)
                  Positioned.fill(
                    child: _QuoteBackgroundImage(
                      pathOrUrl: store.backgroundImage,
                      fallbackColor: store.backgroundColor,
                    ),
                  ),
                if (store.overlayStrength > 0)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(
                        store.overlayStrength.clamp(0.0, 0.85),
                      ),
                    ),
                  ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final safeHorizontalPadding =
                        (constraints.maxWidth * 0.08).clamp(18.0, 30.0);
                    final safeVerticalPadding =
                        (constraints.maxHeight * 0.08).clamp(18.0, 28.0);
                    final contentWidth =
                        (constraints.maxWidth - (safeHorizontalPadding * 2))
                            .clamp(140.0, constraints.maxWidth);
                    final contentHeight =
                        (constraints.maxHeight - (safeVerticalPadding * 2))
                            .clamp(120.0, constraints.maxHeight);

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Center(
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                store.moveTextBy(details.delta);
                              },
                              child: Transform.translate(
                                offset: store.textOffset,
                                child: SizedBox(
                                  width: contentWidth,
                                  height: contentHeight,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: _alignmentToBoxAlignment(
                                      store.alignment,
                                    ),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: contentWidth,
                                      ),
                                      child: Transform.scale(
                                        scale: store.textScale,
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              _crossAxisFromTextAlign(
                                            store.alignment,
                                          ),
                                          children: [
                                            _QuoteRichTextBlock(
                                              quoteText: quoteText,
                                              segments: store.segments,
                                              textAlign: store.alignment,
                                              baseStyle: quoteBaseStyle,
                                              highlightColor:
                                                  store.highlightColor,
                                              highlightFontScale:
                                                  store.highlightFontScale,
                                            ),
                                            if (authorText.isNotEmpty) ...[
                                              const SizedBox(height: 16),
                                              Text(
                                                authorText,
                                                textAlign: store.alignment,
                                                style: authorStyle,
                                                softWrap: true,
                                                overflow: TextOverflow.visible,
                                                maxLines: null,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (store.showWatermark)
                          Positioned(
                            left: 24,
                            right: 24,
                            bottom: 16,
                            child: Center(
                              child: Text(
                                'Dunamis TV',
                                style: TextStyle(
                                  color: _watermarkColor(
                                    store.backgroundColor,
                                    store.textColor,
                                  ),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _watermarkColor(Color backgroundColor, Color textColor) {
    final lightBg = backgroundColor.computeLuminance() > 0.55;
    if (lightBg) {
      return Colors.black.withOpacity(0.58);
    }

    final lightText = textColor.computeLuminance() > 0.55;
    return (lightText ? Colors.white : Colors.white).withOpacity(0.82);
  }

  static Alignment _alignmentToBoxAlignment(TextAlign textAlign) {
    switch (textAlign) {
      case TextAlign.left:
      case TextAlign.start:
        return Alignment.centerLeft;
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      case TextAlign.center:
      default:
        return Alignment.center;
    }
  }

  static CrossAxisAlignment _crossAxisFromTextAlign(TextAlign textAlign) {
    switch (textAlign) {
      case TextAlign.left:
      case TextAlign.start:
        return CrossAxisAlignment.start;
      case TextAlign.right:
      case TextAlign.end:
        return CrossAxisAlignment.end;
      case TextAlign.center:
      default:
        return CrossAxisAlignment.center;
    }
  }
}

class _QuoteBackgroundImage extends StatelessWidget {
  final String? pathOrUrl;
  final Color fallbackColor;

  const _QuoteBackgroundImage({
    required this.pathOrUrl,
    required this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    final value = (pathOrUrl ?? '').trim();

    if (value.isEmpty) {
      return Container(color: fallbackColor);
    }

    if (value.startsWith('data:image/')) {
      try {
        final commaIndex = value.indexOf(',');
        if (commaIndex > -1) {
          final bytes = base64Decode(value.substring(commaIndex + 1));
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: fallbackColor),
          );
        }
      } catch (_) {
        return Container(color: fallbackColor);
      }
    }

    final lower = value.toLowerCase();
    final isRemoteLike = lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('blob:');

    if (isRemoteLike) {
      return Image.network(
        value,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: fallbackColor),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: fallbackColor,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          );
        },
      );
    }

    if (!kIsWeb && !_looksLikeAsset(value)) {
      return Image.file(
        File(value),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: fallbackColor),
      );
    }

    return Image.asset(
      value,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: fallbackColor),
    );
  }

  bool _looksLikeAsset(String value) {
    return value.startsWith('assets/');
  }
}

class _QuoteRichTextBlock extends StatelessWidget {
  final String quoteText;
  final List<QuoteTextSegment> segments;
  final TextAlign textAlign;
  final TextStyle baseStyle;
  final Color highlightColor;
  final double highlightFontScale;

  const _QuoteRichTextBlock({
    required this.quoteText,
    required this.segments,
    required this.textAlign,
    required this.baseStyle,
    required this.highlightColor,
    required this.highlightFontScale,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSegments =
        _segmentsMatchQuote(segments, quoteText) ? segments : _plain(quoteText);

    if (effectiveSegments.isEmpty) {
      return Text(
        quoteText,
        textAlign: textAlign,
        style: baseStyle,
        softWrap: true,
        overflow: TextOverflow.visible,
        maxLines: null,
      );
    }

    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        children: effectiveSegments.map((seg) {
          return TextSpan(
            text: seg.text,
            style: baseStyle.copyWith(
              color: seg.isHighlight ? highlightColor : baseStyle.color,
              fontSize: seg.isHighlight
                  ? (baseStyle.fontSize ?? 24) * highlightFontScale
                  : baseStyle.fontSize,
              fontWeight: seg.isHighlight ? FontWeight.w900 : FontWeight.w700,
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _segmentsMatchQuote(List<QuoteTextSegment> items, String quoteText) {
    if (items.isEmpty) return false;
    return items.map((e) => e.text).join() == quoteText;
  }

  List<QuoteTextSegment> _plain(String value) {
    if (value.trim().isEmpty) return const [];

    final matches = RegExp(r'\S+\s*').allMatches(value).toList();
    if (matches.isEmpty) {
      return [
        QuoteTextSegment(
          text: value,
          isHighlight: false,
        ),
      ];
    }

    return matches
        .map(
          (match) => QuoteTextSegment(
            text: match.group(0) ?? '',
            isHighlight: false,
          ),
        )
        .toList();
  }
}

TextStyle _resolveFontStyle({
  required String fontFamily,
  required Color color,
  required double fontSize,
  double? height,
  FontWeight? fontWeight,
}) {
  final base = TextStyle(
    color: color,
    fontSize: fontSize,
    height: height,
    fontWeight: fontWeight,
  );

  switch (fontFamily) {
    case 'Playfair Display':
      return GoogleFonts.playfairDisplay(textStyle: base);
    case 'Oswald':
      return GoogleFonts.oswald(textStyle: base);
    case 'Lora':
      return GoogleFonts.lora(textStyle: base);
    case 'Poppins':
      return GoogleFonts.poppins(textStyle: base);
    case 'Merriweather':
      return GoogleFonts.merriweather(textStyle: base);
    case 'Raleway':
      return GoogleFonts.raleway(textStyle: base);
    case 'Nunito':
      return GoogleFonts.nunito(textStyle: base);
    case 'Roboto Slab':
      return GoogleFonts.robotoSlab(textStyle: base);
    case 'PT Serif':
      return GoogleFonts.ptSerif(textStyle: base);
    case 'Montserrat':
    default:
      return GoogleFonts.montserrat(textStyle: base);
  }
}
