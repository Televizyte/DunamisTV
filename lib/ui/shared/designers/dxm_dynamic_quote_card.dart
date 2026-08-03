import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import 'dxm_design_parser.dart';
import 'dxm_font_mapper.dart';

class DxmDynamicQuoteCard extends StatelessWidget {
  final String mainText;
  final String? supportText;
  final String? referenceText;
  final DxmDesignData design;
  final EdgeInsetsGeometry? margin;
  final List<Widget> actions;
  final bool showActionsBar;
  final double? maxPreviewWidth;
  final double minHeight;
  final BorderRadius borderRadius;
  final GlobalKey? canvasKey;
  final bool enableTapPreview;

  const DxmDynamicQuoteCard({
    super.key,
    required this.mainText,
    required this.design,
    this.supportText,
    this.referenceText,
    this.margin,
    this.actions = const [],
    this.showActionsBar = false,
    this.maxPreviewWidth,
    this.minHeight = 220,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.canvasKey,
    this.enableTapPreview = true,
  });

  @override
  Widget build(BuildContext context) {
    final cleanMainText = mainText.trim();
    final cleanSupportText = (supportText ?? '').trim();
    final cleanReferenceText = (referenceText ?? '').trim();

    final effectiveBorderRadius =
        BorderRadius.all(Radius.circular(design.borderRadiusValue));

    final card = ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            key: canvasKey,
            child: ClipRect(
              child: AspectRatio(
                aspectRatio: design.aspectRatio,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final safePaddingX = design.cardPaddingX
                        .clamp(0.0, constraints.maxWidth * 0.45)
                        .toDouble();
                    final safePaddingY = design.cardPaddingY
                        .clamp(0.0, constraints.maxHeight * 0.45)
                        .toDouble();
                    final contentWidth = ((constraints.maxWidth -
                                (safePaddingX * 2)) *
                            (design.contentWidthPercent / 100).clamp(0.30, 1.0))
                        .toDouble();
                    final supportCount = [cleanSupportText, cleanReferenceText]
                        .where((value) => value.isNotEmpty)
                        .length;
                    final safeSupportFontSize = design.supportFontSize
                        .clamp(8.0, constraints.maxWidth * 0.06)
                        .toDouble();
                    final reservedSupportHeight = supportCount *
                        ((safeSupportFontSize * design.lineHeight) +
                            design.sourceSpacing);
                    final availableMainHeight = (constraints.maxHeight -
                            (safePaddingY * 2) -
                            reservedSupportHeight)
                        .clamp(56.0, constraints.maxHeight)
                        .toDouble();
                    final fittedMainSize = _fitMainFontSize(
                      cleanMainText,
                      contentWidth,
                      availableMainHeight,
                    );

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        _DxmDynamicBackground(design: design),
                        _DxmDynamicOverlay(design: design),
                        if (design.showQuoteMark)
                          Positioned(
                            top: _quoteMarkTop(
                                safePaddingY, constraints.maxHeight),
                            left: _quoteMarkLeft(
                                safePaddingX, constraints.maxWidth),
                            right: _quoteMarkRight(
                                safePaddingX, constraints.maxWidth),
                            bottom: _quoteMarkBottom(
                                safePaddingY, constraints.maxHeight),
                            child: IgnorePointer(
                              child: Text(
                                '“',
                                textAlign: _quoteMarkTextAlign,
                                style: TextStyle(
                                  color: design.textColor.withOpacity(
                                    design.quoteMarkOpacity.clamp(0.0, 1.0),
                                  ),
                                  fontSize: design.quoteMarkSize
                                      .clamp(24.0, constraints.maxWidth * 0.62)
                                      .toDouble(),
                                  height: 0.82,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: safePaddingX,
                            vertical: safePaddingY,
                          ),
                          child: Transform.translate(
                            offset: Offset(design.offsetX, design.offsetY),
                            child: Align(
                              alignment: design.contentAlignment,
                              child: SizedBox(
                                width: contentWidth,
                                height:
                                    (constraints.maxHeight - (safePaddingY * 2))
                                        .clamp(56.0, constraints.maxHeight)
                                        .toDouble(),
                                child: ClipRect(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: design.contentAlignment,
                                    child: SizedBox(
                                      width: contentWidth,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            design.mainAxisAlignment,
                                        crossAxisAlignment:
                                            design.crossAxisAlignment,
                                        children: [
                                          if (cleanMainText.isNotEmpty)
                                            _highlightedMainText(
                                              cleanMainText,
                                              DxmFontMapper.style(
                                                design.fontFamily,
                                                fontSize: fittedMainSize,
                                                fontWeight: design.fontWeight,
                                                color: design.textColor,
                                                height: design.lineHeight,
                                                shadows: _textShadows,
                                              ).copyWith(
                                                letterSpacing:
                                                    design.letterSpacing,
                                              ),
                                            ),
                                          if (cleanSupportText.isNotEmpty) ...[
                                            SizedBox(
                                                height: design.sourceSpacing),
                                            Text(
                                              cleanSupportText,
                                              textAlign: design.textAlign,
                                              softWrap: true,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: DxmFontMapper.style(
                                                design.fontFamily,
                                                fontSize: safeSupportFontSize,
                                                fontWeight: design.sourceWeight,
                                                color: design.sourceColor,
                                                height: design.lineHeight,
                                                shadows: _textShadows,
                                              ).copyWith(
                                                letterSpacing:
                                                    design.letterSpacing,
                                              ),
                                            ),
                                          ],
                                          if (cleanReferenceText
                                              .isNotEmpty) ...[
                                            SizedBox(
                                                height: design.sourceSpacing),
                                            Text(
                                              cleanReferenceText,
                                              textAlign: design.textAlign,
                                              softWrap: true,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: DxmFontMapper.style(
                                                design.fontFamily,
                                                fontSize: safeSupportFontSize,
                                                fontWeight: design.sourceWeight,
                                                color: design.sourceColor,
                                                height: design.lineHeight,
                                                shadows: _textShadows,
                                              ).copyWith(
                                                letterSpacing:
                                                    design.letterSpacing,
                                              ),
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
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          if (showActionsBar && actions.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: const Color(0xFF090F28),
                border: Border(
                  top: BorderSide(color: design.accentColor.withOpacity(0.24)),
                ),
              ),
              child: Row(children: actions),
            ),
        ],
      ),
    );

    final decorated = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFF090F28),
        borderRadius: effectiveBorderRadius,
        border: Border.all(color: design.accentColor.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.18),
          ),
        ],
      ),
      child: card,
    );

    final output = maxPreviewWidth == null
        ? decorated
        : Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxPreviewWidth!),
              child: decorated,
            ),
          );

    if (!enableTapPreview) {
      return output;
    }

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: () => _showAdaptivePreview(context),
      child: output,
    );
  }

  void _showAdaptivePreview(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.82),
      builder: (context) {
        final previewCanvasKey = GlobalKey();
        final screen = MediaQuery.sizeOf(context);
        final availableWidth = screen.width - 32;
        final availableHeight = screen.height - 128;
        const actionHeight = 46.0;
        const actionGap = 10.0;

        var previewWidth = availableWidth;
        var previewHeight = previewWidth / design.aspectRatio;
        final maxPreviewHeight = availableHeight - actionHeight - actionGap;

        if (previewHeight > maxPreviewHeight) {
          previewHeight = maxPreviewHeight;
          previewWidth = previewHeight * design.aspectRatio;
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: previewWidth,
                  height: previewHeight,
                  child: DxmDynamicQuoteCard(
                    mainText: mainText,
                    supportText: supportText,
                    referenceText: referenceText,
                    design: design,
                    showActionsBar: false,
                    borderRadius: BorderRadius.circular(28),
                    enableTapPreview: false,
                    canvasKey: previewCanvasKey,
                  ),
                ),
                const SizedBox(height: actionGap),
                SizedBox(
                  width: previewWidth,
                  height: actionHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => _savePreviewImage(
                          context,
                          previewCanvasKey,
                        ),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Save Image'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _sharePreviewImage(
                          context,
                          previewCanvasKey,
                        ),
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('Share'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _savePreviewImage(
    BuildContext context,
    GlobalKey previewCanvasKey,
  ) async {
    await _sharePreviewImage(
      context,
      previewCanvasKey,
      subject: 'Save quote image',
      text: 'Save this quote image.',
      filePrefix: 'quote_save',
    );
  }

  Future<void> _sharePreviewImage(
    BuildContext context,
    GlobalKey previewCanvasKey, {
    String subject = 'Quote image',
    String text = 'Share this quote image.',
    String filePrefix = 'quote',
  }) async {
    try {
      final bytes = await _renderPreviewToPng(previewCanvasKey);
      final fileName =
          '${filePrefix}_${DateTime.now().millisecondsSinceEpoch}.png';
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: fileName,
          ),
        ],
        fileNameOverrides: [fileName],
        subject: subject,
        text: text,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not prepare quote image')),
      );
    }
  }

  Future<Uint8List> _renderPreviewToPng(GlobalKey previewCanvasKey) async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary = previewCanvasKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('Quote preview canvas is not ready');
    }

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Unable to render quote preview image');
    }

    return byteData.buffer.asUint8List();
  }

  double? _quoteMarkTop(double paddingY, double maxHeight) {
    final pos = design.quoteMarkPosition.trim().toLowerCase();
    if (pos.contains('bottom')) return null;
    if (pos.contains('center')) return maxHeight * 0.42;
    return paddingY * 0.42;
  }

  double? _quoteMarkBottom(double paddingY, double maxHeight) {
    final pos = design.quoteMarkPosition.trim().toLowerCase();
    if (pos.contains('bottom')) return paddingY * 0.24;
    return null;
  }

  double? _quoteMarkLeft(double paddingX, double maxWidth) {
    final pos = design.quoteMarkPosition.trim().toLowerCase();
    if (pos.contains('right')) return null;
    if (pos.contains('center')) return maxWidth * 0.38;
    return paddingX * 0.42;
  }

  double? _quoteMarkRight(double paddingX, double maxWidth) {
    final pos = design.quoteMarkPosition.trim().toLowerCase();
    if (pos.contains('right')) return paddingX * 0.42;
    return null;
  }

  TextAlign get _quoteMarkTextAlign {
    final pos = design.quoteMarkPosition.trim().toLowerCase();
    return pos.contains('right') ? TextAlign.right : TextAlign.left;
  }

  double get _supportSpacing {
    if (design.cardFormat.trim().toLowerCase() == 'square' ||
        design.cardFormat.trim() == '1:1') {
      return 10;
    }
    return 16;
  }

  double _fitMainFontSize(String text, double maxWidth, double maxHeight) {
    final requested = design.autoMainFontSize(text);
    final clean = text.trim();

    if (clean.isEmpty || maxWidth <= 0 || maxHeight <= 0) {
      return requested;
    }

    final phrases = _highlightPhrases;

    bool fits(double size) {
      final style = DxmFontMapper.style(
        design.fontFamily,
        fontSize: size,
        fontWeight: design.fontWeight,
        color: design.textColor,
        height: design.lineHeight,
      );

      final span = phrases.isEmpty
          ? TextSpan(text: clean, style: style)
          : TextSpan(children: _highlightSpans(clean, style, phrases));

      final painter = TextPainter(
        text: span,
        textAlign: design.textAlign,
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
        maxLines: null,
      )..layout(maxWidth: maxWidth);

      return painter.width <= maxWidth + 0.5 &&
          painter.height <= (maxHeight - 4).clamp(42.0, maxHeight);
    }

    final minimum = 10.0;

    if (fits(requested)) {
      return requested;
    }

    var low = minimum;
    var high = requested;

    for (var i = 0; i < 14; i++) {
      final mid = (low + high) / 2;
      if (fits(mid)) {
        low = mid;
      } else {
        high = mid;
      }
    }

    return (low * 0.96).clamp(minimum, requested).toDouble();
  }

  Widget _highlightedMainText(String text, TextStyle baseStyle) {
    final phrases = _highlightPhrases;
    if (phrases.isEmpty) {
      return Text(
        text,
        textAlign: design.textAlign,
        softWrap: true,
        overflow: TextOverflow.clip,
        style: baseStyle,
      );
    }

    return Text.rich(
      TextSpan(children: _highlightSpans(text, baseStyle, phrases)),
      textAlign: design.textAlign,
      softWrap: true,
      overflow: TextOverflow.clip,
    );
  }

  List<String> get _highlightPhrases {
    final raw = design.highlightPhrases.trim();
    if (raw.isEmpty) return const [];

    final seen = <String>{};
    final out = <String>[];

    for (final part in raw.split(RegExp(r'[\n,]+'))) {
      final cleaned = part.trim();
      if (cleaned.isEmpty) continue;

      final key = cleaned.toLowerCase();
      if (seen.contains(key)) continue;

      seen.add(key);
      out.add(cleaned);
    }

    out.sort((a, b) => b.length.compareTo(a.length));
    return out;
  }

  List<TextSpan> _highlightSpans(
    String text,
    TextStyle baseStyle,
    List<String> phrases,
  ) {
    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();

    var cursor = 0;

    while (cursor < text.length) {
      int? bestIndex;
      String? bestPhrase;

      for (final phrase in phrases) {
        final index = lowerText.indexOf(phrase.toLowerCase(), cursor);
        if (index < 0) continue;

        if (bestIndex == null ||
            index < bestIndex ||
            (index == bestIndex && phrase.length > (bestPhrase?.length ?? 0))) {
          bestIndex = index;
          bestPhrase = phrase;
        }
      }

      if (bestIndex == null || bestPhrase == null) {
        spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
        break;
      }

      if (bestIndex > cursor) {
        spans.add(TextSpan(
            text: text.substring(cursor, bestIndex), style: baseStyle));
      }

      final end = (bestIndex + bestPhrase.length).clamp(0, text.length);
      spans.add(
        TextSpan(
          text: text.substring(bestIndex, end),
          style: baseStyle.copyWith(
            color: design.highlightColor,
            fontSize: (baseStyle.fontSize ?? design.mainFontSize) *
                design.highlightScale,
            fontWeight: design.highlightWeight,
          ),
        ),
      );

      cursor = end;
    }

    return spans;
  }

  List<Shadow> get _textShadows {
    final mode = design.textShadowMode.trim().toLowerCase();

    if (mode == 'off' || mode == 'none' || mode == 'clean' || mode == 'false') {
      return const [];
    }

    if (mode == 'strong') {
      return [
        Shadow(
          offset: const Offset(0, 3),
          blurRadius: 16,
          color: Colors.black.withOpacity(0.54),
        ),
      ];
    }

    if (mode == 'soft' || mode == 'on' || mode == 'true') {
      return [
        Shadow(
          offset: const Offset(0, 2),
          blurRadius: 9,
          color: Colors.black.withOpacity(0.30),
        ),
      ];
    }

    if (design.overlayStrength <= 0.05 && design.usesSolidBackground) {
      return const [];
    }

    return [
      Shadow(
        offset: const Offset(0, 2),
        blurRadius: 10,
        color: Colors.black.withOpacity(0.34),
      ),
    ];
  }
}

class _DxmDynamicBackground extends StatelessWidget {
  final DxmDesignData design;

  const _DxmDynamicBackground({required this.design});

  @override
  Widget build(BuildContext context) {
    if (design.usesImageBackground && _hasUsableImage(design.imageUrl)) {
      final cleanUrl = design.imageUrl.trim();

      if (cleanUrl.startsWith('assets/')) {
        return Image.asset(
          cleanUrl,
          fit: _boxFitFor(design.backgroundFit),
          width: double.infinity,
          height: double.infinity,
          alignment: _alignmentFor(design.backgroundPosition),
          errorBuilder: (_, __, ___) => _fallbackBackground(),
        );
      }

      return Image.network(
        cleanUrl,
        fit: _boxFitFor(design.backgroundFit),
        width: double.infinity,
        height: double.infinity,
        alignment: _alignmentFor(design.backgroundPosition),
        errorBuilder: (_, __, ___) => _fallbackBackground(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;

          return Stack(
            fit: StackFit.expand,
            children: [
              _fallbackBackground(),
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            ],
          );
        },
      );
    }

    return _fallbackBackground();
  }

  BoxFit _boxFitFor(String value) {
    switch (value.trim().toLowerCase()) {
      case 'contain':
        return BoxFit.contain;
      case 'fill':
      case 'stretch':
        return BoxFit.fill;
      case 'fit_width':
      case 'fitwidth':
        return BoxFit.fitWidth;
      case 'fit_height':
      case 'fitheight':
        return BoxFit.fitHeight;
      case 'none':
        return BoxFit.none;
      case 'scale_down':
      case 'scaledown':
        return BoxFit.scaleDown;
      case 'cover':
      default:
        return BoxFit.cover;
    }
  }

  Alignment _alignmentFor(String value) {
    switch (value.trim().toLowerCase().replaceAll('-', '_')) {
      case 'top':
      case 'top_center':
        return Alignment.topCenter;
      case 'bottom':
      case 'bottom_center':
        return Alignment.bottomCenter;
      case 'left':
      case 'center_left':
        return Alignment.centerLeft;
      case 'right':
      case 'center_right':
        return Alignment.centerRight;
      case 'top_left':
        return Alignment.topLeft;
      case 'top_right':
        return Alignment.topRight;
      case 'bottom_left':
        return Alignment.bottomLeft;
      case 'bottom_right':
        return Alignment.bottomRight;
      case 'center':
      default:
        return Alignment.center;
    }
  }

  Widget _fallbackBackground() {
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

  bool _hasUsableImage(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return false;
    if (raw.startsWith('assets/')) return true;

    final uri = Uri.tryParse(raw);
    if (uri == null) return false;
    if (!(uri.scheme == 'http' || uri.scheme == 'https')) return false;
    if (uri.host.trim().isEmpty) return false;
    if (uri.host.contains('your-real-')) return false;

    return true;
  }
}

class _DxmDynamicOverlay extends StatelessWidget {
  final DxmDesignData design;

  const _DxmDynamicOverlay({required this.design});

  @override
  Widget build(BuildContext context) {
    final strength = design.overlayStrength.clamp(0.0, 1.0);

    if (strength <= 0) {
      return const SizedBox.shrink();
    }

    if (design.usesSolidBackground) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity((strength * 0.28).clamp(0.0, 0.30)),
        ),
      );
    }

    final style = design.overlayStyle.trim().toLowerCase();

    if (style == 'none' || style == 'off' || style == 'no_overlay') {
      return const SizedBox.shrink();
    }

    if (style == 'full' || style == 'full_overlay') {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity((0.70 * strength).clamp(0.0, 0.70)),
        ),
      );
    }

    if (style == 'top_bottom' || style == 'top_and_bottom') {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.58 * strength),
              Colors.black.withOpacity(0.08 * strength),
              Colors.black.withOpacity(0.72 * strength),
            ],
            stops: const [0.0, 0.48, 1.0],
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.04 * strength),
            Colors.black.withOpacity(0.30 * strength),
            Colors.black.withOpacity(0.82 * strength),
          ],
          stops: const [0.0, 0.46, 1.0],
        ),
      ),
    );
  }
}
