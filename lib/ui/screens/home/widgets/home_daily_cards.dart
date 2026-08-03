import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../features/hub/state/hub_scope.dart';
import '../../../shared/designers/dxm_design_parser.dart';
import '../../../shared/designers/dxm_dynamic_quote_card.dart';

typedef DxmDailyCardTap = void Function(Map<String, String> card);

class DxmDailyScriptureCarousel extends StatelessWidget {
  final List<Map<String, String>> cards;
  final String fallbackRef;
  final String fallbackVerse;
  final String fallbackNote;
  final String? imageUrl;
  final bool useSolidBackground;
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final double fontSize;
  final double referenceFontSize;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final double overlayStrength;
  final DxmDailyCardTap? onShare;
  final DxmDailyCardTap? onOpenInQuoteCreator;
  final DxmDailyCardTap onReadFullBible;

  const DxmDailyScriptureCarousel({
    super.key,
    required this.cards,
    required this.fallbackRef,
    required this.fallbackVerse,
    required this.fallbackNote,
    required this.imageUrl,
    required this.useSolidBackground,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.fontSize,
    required this.referenceFontSize,
    required this.fontWeight,
    required this.textAlign,
    required this.overlayStrength,
    required this.onShare,
    required this.onOpenInQuoteCreator,
    required this.onReadFullBible,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = _dailyCardsOrFallback(
      cards,
      fallback: {
        'ref': fallbackRef,
        'reference': fallbackRef,
        'verse': fallbackVerse,
        'note': fallbackNote,
        'image_url': (imageUrl ?? '').trim(),
      },
      textKeys: const ['verse', 'quote_text', 'text'],
    );

    if (normalized.length <= 1) {
      final card =
          normalized.isNotEmpty ? normalized.first : <String, String>{};
      return DxmDailyScripturePremiumCard(
        ref: _pickCardText(card, const ['ref', 'reference', 'quote_source']),
        verse: _pickCardText(card, const ['verse', 'quote_text', 'text']),
        note: _pickCardText(card, const ['note', 'subtitle', 'description']),
        imageUrl: _pickCardText(card, const ['image_url', 'image']),
        useSolidBackground: useSolidBackground,
        backgroundColor: backgroundColor,
        textColor: textColor,
        accentColor: accentColor,
        fontSize: fontSize,
        referenceFontSize: referenceFontSize,
        fontWeight: fontWeight,
        textAlign: textAlign,
        overlayStrength: overlayStrength,
        designSource: card,
        onShare: onShare == null ? null : () => onShare!(card),
        onOpenInQuoteCreator: onOpenInQuoteCreator == null
            ? null
            : () => onOpenInQuoteCreator!(card),
        onReadFullBible: () => onReadFullBible(card),
      );
    }

    return _DailyCarouselShell(
      cards: normalized,
      itemBuilder: (context, card) => DxmDailyScripturePremiumCard(
        ref: _pickCardText(card, const ['ref', 'reference', 'quote_source']),
        verse: _pickCardText(card, const ['verse', 'quote_text', 'text']),
        note: _pickCardText(card, const ['note', 'subtitle', 'description']),
        imageUrl: _pickCardText(card, const ['image_url', 'image']),
        useSolidBackground: useSolidBackground,
        backgroundColor: backgroundColor,
        textColor: textColor,
        accentColor: accentColor,
        fontSize: fontSize,
        referenceFontSize: referenceFontSize,
        fontWeight: fontWeight,
        textAlign: textAlign,
        overlayStrength: overlayStrength,
        designSource: card,
        onShare: onShare == null ? null : () => onShare!(card),
        onOpenInQuoteCreator: onOpenInQuoteCreator == null
            ? null
            : () => onOpenInQuoteCreator!(card),
        onReadFullBible: () => onReadFullBible(card),
      ),
    );
  }
}

class DxmDailyQuoteCarousel extends StatelessWidget {
  final List<Map<String, String>> cards;
  final String fallbackQuote;
  final String fallbackSource;
  final String? imageUrl;
  final bool useSolidBackground;
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final double fontSize;
  final double brandFontSize;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final double overlayStrength;
  final DxmDailyCardTap? onShare;
  final DxmDailyCardTap? onOpenInQuoteCreator;
  final DxmDailyCardTap onAddToNotes;

  const DxmDailyQuoteCarousel({
    super.key,
    required this.cards,
    required this.fallbackQuote,
    required this.fallbackSource,
    required this.imageUrl,
    required this.useSolidBackground,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.fontSize,
    required this.brandFontSize,
    required this.fontWeight,
    required this.textAlign,
    required this.overlayStrength,
    required this.onShare,
    required this.onOpenInQuoteCreator,
    required this.onAddToNotes,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = _dailyCardsOrFallback(
      cards,
      fallback: {
        'quote': fallbackQuote,
        'quote_text': fallbackQuote,
        'text': fallbackQuote,
        'source': fallbackSource,
        'quote_source': fallbackSource,
        'image_url': (imageUrl ?? '').trim(),
      },
      textKeys: const ['quote', 'quote_text', 'text'],
    );

    if (normalized.length <= 1) {
      final card =
          normalized.isNotEmpty ? normalized.first : <String, String>{};
      return DxmDailyQuotePremiumCard(
        quote: _pickCardText(card, const ['quote', 'quote_text', 'text']),
        brandText: _pickCardText(card, const ['source', 'quote_source']),
        imageUrl: _pickCardText(card, const ['image_url', 'image']),
        useSolidBackground: useSolidBackground,
        backgroundColor: backgroundColor,
        textColor: textColor,
        accentColor: accentColor,
        fontSize: fontSize,
        brandFontSize: brandFontSize,
        fontWeight: fontWeight,
        textAlign: textAlign,
        overlayStrength: overlayStrength,
        designSource: card,
        onShare: onShare == null ? null : () => onShare!(card),
        onOpenInQuoteCreator: onOpenInQuoteCreator == null
            ? null
            : () => onOpenInQuoteCreator!(card),
        onAddToNotes: () => onAddToNotes(card),
      );
    }

    return _DailyCarouselShell(
      cards: normalized,
      itemBuilder: (context, card) => DxmDailyQuotePremiumCard(
        quote: _pickCardText(card, const ['quote', 'quote_text', 'text']),
        brandText: _pickCardText(card, const ['source', 'quote_source']),
        imageUrl: _pickCardText(card, const ['image_url', 'image']),
        useSolidBackground: useSolidBackground,
        backgroundColor: backgroundColor,
        textColor: textColor,
        accentColor: accentColor,
        fontSize: fontSize,
        brandFontSize: brandFontSize,
        fontWeight: fontWeight,
        textAlign: textAlign,
        overlayStrength: overlayStrength,
        designSource: card,
        onShare: onShare == null ? null : () => onShare!(card),
        onOpenInQuoteCreator: onOpenInQuoteCreator == null
            ? null
            : () => onOpenInQuoteCreator!(card),
        onAddToNotes: () => onAddToNotes(card),
      ),
    );
  }
}

class _DailyCarouselShell extends StatefulWidget {
  final List<Map<String, String>> cards;
  final Widget Function(BuildContext context, Map<String, String> card)
      itemBuilder;

  const _DailyCarouselShell({required this.cards, required this.itemBuilder});

  @override
  State<_DailyCarouselShell> createState() => _DailyCarouselShellState();
}

class _DailyCarouselShellState extends State<_DailyCarouselShell> {
  final PageController _controller = PageController(viewportFraction: 1);
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final activeCard = widget.cards.isEmpty
            ? <String, String>{}
            : widget.cards[_index.clamp(0, widget.cards.length - 1)];
        final activeDesign = DxmDesignData.fromMap(
          Map<String, dynamic>.from(activeCard),
          fallbackAsset: '',
        );
        final previewWidth = _dailyPreviewWidth(
          context,
          activeDesign,
          availableWidth: width,
        );
        final canvasHeight = previewWidth / activeDesign.aspectRatio;
        final height = (canvasHeight + _dailyActionsHeight)
            .clamp(320.0, _dailyMaxSectionHeight(context))
            .toDouble();
        return Column(
          children: [
            SizedBox(
              height: height,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.cards.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) => widget.itemBuilder(
                  context,
                  widget.cards[index],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.cards.length, (index) {
                final active = index == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: active
                        ? const Color(0xFFE4007C)
                        : Colors.white.withOpacity(0.26),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

List<Map<String, String>> _dailyCardsOrFallback(
  List<Map<String, String>> cards, {
  required Map<String, String> fallback,
  required List<String> textKeys,
}) {
  final output = <Map<String, String>>[];
  final seen = <String>{};

  void add(Map<String, String> card) {
    final text = _pickCardText(card, textKeys);
    if (text.isEmpty) return;

    final source = _pickCardText(card, const [
      'source',
      'quote_source',
      'ref',
      'reference',
    ]);
    final signature = '${text.toLowerCase()}|${source.toLowerCase()}';
    if (seen.contains(signature)) return;
    seen.add(signature);
    output.add(card);
  }

  for (final card in cards) {
    add(card);
    if (output.length >= 10) break;
  }

  if (output.isEmpty) add(fallback);
  return output;
}

String _pickCardText(Map<String, String> card, List<String> keys) {
  for (final key in keys) {
    final value = (card[key] ?? '').trim();
    if (value.isNotEmpty) return value;
  }
  return '';
}

const double _dailyActionsHeight = 82;

double _dailyMaxSectionHeight(BuildContext context) {
  final screen = MediaQuery.sizeOf(context);
  return (screen.height * 0.72).clamp(360.0, 620.0).toDouble();
}

double _dailyPreviewWidth(
  BuildContext context,
  DxmDesignData design, {
  double? availableWidth,
}) {
  final screen = MediaQuery.sizeOf(context);
  final rawWidth = availableWidth ?? screen.width;
  final safeWidth = (rawWidth - 24).clamp(260.0, rawWidth).toDouble();

  // The backend designer can use tall/square canvases, but the Home tab must
  // keep daily cards readable without swallowing the whole mobile viewport.
  // This limits the visual canvas, while the renderer still respects the
  // backend colors, font weights, highlights, padding, and background mode.
  final maxCanvasHeight = (screen.height * 0.54).clamp(300.0, 420.0).toDouble();
  final widthByHeight = maxCanvasHeight * design.aspectRatio;

  return safeWidth.clamp(260.0, widthByHeight).toDouble();
}

class DxmDailyScripturePremiumCard extends StatelessWidget {
  final String ref;
  final String verse;
  final String note;
  final String? imageUrl;
  final bool useSolidBackground;
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final double fontSize;
  final double referenceFontSize;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final double overlayStrength;
  final VoidCallback? onShare;
  final VoidCallback? onOpenInQuoteCreator;
  final VoidCallback onReadFullBible;
  final Map<String, String>? designSource;

  const DxmDailyScripturePremiumCard({
    super.key,
    required this.ref,
    required this.verse,
    required this.note,
    required this.imageUrl,
    required this.useSolidBackground,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.fontSize,
    required this.referenceFontSize,
    required this.fontWeight,
    required this.textAlign,
    required this.overlayStrength,
    required this.onShare,
    required this.onOpenInQuoteCreator,
    required this.onReadFullBible,
    this.designSource,
  });

  @override
  Widget build(BuildContext context) {
    final shareCanvasKey = GlobalKey();
    final backend = _asDynamicMap(
      designSource ?? HubScope.of(context).homeDailyScripture,
    );

    final design = DxmDesignData.fromMap(
      _mergeFallbackDesign(
        backend,
        imageUrl: imageUrl,
        useSolidBackground: useSolidBackground,
        backgroundColor: backgroundColor,
        textColor: textColor,
        accentColor: accentColor,
        mainFontSize: fontSize,
        supportFontSize: referenceFontSize,
        fontWeight: fontWeight,
        textAlign: textAlign,
        overlayStrength: overlayStrength,
      ),
      imageUrl: (imageUrl ?? '').trim(),
      fallbackAsset: '',
      fallbackMainFontSize: fontSize,
      fallbackSupportFontSize: referenceFontSize,
    );

    return DxmDynamicQuoteCard(
      mainText: verse,
      supportText: note,
      referenceText: ref,
      design: design,
      minHeight: 180,
      maxPreviewWidth: _dailyPreviewWidth(context, design),
      canvasKey: shareCanvasKey,
      showActionsBar: true,
      actions: _buildActions(
        context,
        design: design,
        items: [
          _DailyCardAction(
            icon: Icons.auto_awesome_rounded,
            label: 'Quote Creator',
            onPressed: onOpenInQuoteCreator,
            primary: false,
          ),
          _DailyCardAction(
            icon: Icons.menu_book_rounded,
            label: 'Open Bible',
            onPressed: onReadFullBible,
            primary: false,
          ),
          _DailyCardAction(
            icon: Icons.share_rounded,
            label: 'Share',
            onPressed: () {
              unawaited(
                _shareDailyCardImage(
                  context: context,
                  canvasKey: shareCanvasKey,
                  fallbackText: _composeScriptureText(
                    verse: verse,
                    ref: ref,
                    note: note,
                  ),
                  fallbackShare: onShare,
                  fileName: 'daily-scripture.png',
                ),
              );
            },
            primary: true,
          ),
        ],
      ),
    );
  }
}

class DxmDailyQuotePremiumCard extends StatelessWidget {
  final String quote;
  final String brandText;
  final String? imageUrl;
  final bool useSolidBackground;
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final double fontSize;
  final double brandFontSize;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final double overlayStrength;
  final VoidCallback? onShare;
  final VoidCallback? onOpenInQuoteCreator;
  final VoidCallback onAddToNotes;
  final Map<String, String>? designSource;

  const DxmDailyQuotePremiumCard({
    super.key,
    required this.quote,
    required this.brandText,
    required this.imageUrl,
    required this.useSolidBackground,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.fontSize,
    required this.brandFontSize,
    required this.fontWeight,
    required this.textAlign,
    required this.overlayStrength,
    required this.onShare,
    required this.onOpenInQuoteCreator,
    required this.onAddToNotes,
    this.designSource,
  });

  @override
  Widget build(BuildContext context) {
    final shareCanvasKey = GlobalKey();
    final backend = _asDynamicMap(
      designSource ?? HubScope.of(context).homeDailyQuote,
    );

    final design = DxmDesignData.fromMap(
      _mergeFallbackDesign(
        backend,
        imageUrl: imageUrl,
        useSolidBackground: useSolidBackground,
        backgroundColor: backgroundColor,
        textColor: textColor,
        accentColor: accentColor,
        mainFontSize: fontSize,
        supportFontSize: brandFontSize,
        fontWeight: fontWeight,
        textAlign: textAlign,
        overlayStrength: overlayStrength,
      ),
      imageUrl: (imageUrl ?? '').trim(),
      fallbackAsset: '',
      fallbackMainFontSize: fontSize,
      fallbackSupportFontSize: brandFontSize,
    );

    return DxmDynamicQuoteCard(
      mainText: quote,
      supportText: brandText,
      design: design,
      minHeight: 180,
      maxPreviewWidth: _dailyPreviewWidth(context, design),
      canvasKey: shareCanvasKey,
      showActionsBar: true,
      actions: _buildActions(
        context,
        design: design,
        items: [
          _DailyCardAction(
            icon: Icons.auto_awesome_rounded,
            label: 'Quote Creator',
            onPressed: onOpenInQuoteCreator,
            primary: false,
          ),
          _DailyCardAction(
            icon: Icons.note_add_rounded,
            label: 'Add to Notes',
            onPressed: onAddToNotes,
            primary: false,
          ),
          _DailyCardAction(
            icon: Icons.share_rounded,
            label: 'Share',
            onPressed: () {
              unawaited(
                _shareDailyCardImage(
                  context: context,
                  canvasKey: shareCanvasKey,
                  fallbackText: _composeQuoteText(
                    quote: quote,
                    source: brandText,
                  ),
                  fallbackShare: onShare,
                  fileName: 'daily-quote.png',
                ),
              );
            },
            primary: true,
          ),
        ],
      ),
    );
  }
}

String _composeScriptureText({
  required String verse,
  required String ref,
  required String note,
}) {
  return [
    if (verse.trim().isNotEmpty) verse.trim(),
    if (ref.trim().isNotEmpty) ref.trim(),
    if (note.trim().isNotEmpty) note.trim(),
  ].join('\n\n');
}

String _composeQuoteText({
  required String quote,
  required String source,
}) {
  return [
    if (quote.trim().isNotEmpty) quote.trim(),
    if (source.trim().isNotEmpty) '— ${source.trim()}',
  ].join('\n\n');
}

Future<void> _shareDailyCardImage({
  required BuildContext context,
  required GlobalKey canvasKey,
  required String fallbackText,
  required VoidCallback? fallbackShare,
  required String fileName,
}) async {
  try {
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final boundary =
        canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) {
      throw StateError('Daily card canvas is not ready.');
    }

    if (boundary.debugNeedsPaint) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }

    final pixelRatio =
        MediaQuery.devicePixelRatioOf(context).clamp(2.0, 3.0).toDouble();
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw StateError('Unable to render daily card image.');
    }

    final Uint8List bytes = byteData.buffer.asUint8List();

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          mimeType: 'image/png',
          name: fileName,
        ),
      ],
      text: fallbackText.trim().isEmpty ? null : fallbackText.trim(),
      subject: 'Dunamis TV',
    );
  } catch (_) {
    if (fallbackShare != null) {
      fallbackShare();
      return;
    }

    final cleanText = fallbackText.trim();
    if (cleanText.isNotEmpty) {
      await Share.share(cleanText);
    }
  }
}

Map<String, dynamic> _asDynamicMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }

  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), item),
    );
  }

  return <String, dynamic>{};
}

Map<String, dynamic> _mergeFallbackDesign(
  Map<String, dynamic> source, {
  required String? imageUrl,
  required bool useSolidBackground,
  required Color backgroundColor,
  required Color textColor,
  required Color accentColor,
  required double mainFontSize,
  required double supportFontSize,
  required FontWeight fontWeight,
  required TextAlign textAlign,
  required double overlayStrength,
}) {
  final output = Map<String, dynamic>.from(source);

  void putIfBlank(String key, dynamic value) {
    final existing = output[key];

    if (existing == null) {
      output[key] = value;
      return;
    }

    if (existing is String && existing.trim().isEmpty) {
      output[key] = value;
    }
  }

  final hasBackgroundMode =
      (output['background_mode'] ?? output['backgroundMode'] ?? '')
          .toString()
          .trim()
          .isNotEmpty;

  if (!hasBackgroundMode) {
    putIfBlank(
      'background_mode',
      useSolidBackground
          ? 'solid'
          : ((imageUrl ?? '').trim().isNotEmpty ? 'image' : 'gradient'),
    );
  }

  putIfBlank('image_url', (imageUrl ?? '').trim());
  putIfBlank('bg_color', _colorToBackendHex(backgroundColor));
  putIfBlank('background_color', _colorToBackendHex(backgroundColor));
  putIfBlank('text_color', _colorToBackendHex(textColor));
  putIfBlank('accent_color', _colorToBackendHex(accentColor));

  putIfBlank('font_size', supportFontSize.toStringAsFixed(1));
  putIfBlank('title_size', mainFontSize.toStringAsFixed(1));
  putIfBlank('font_weight', _fontWeightToBackendValue(fontWeight));
  putIfBlank('text_align', _textAlignToBackendValue(textAlign));
  putIfBlank(
      'overlay_strength',
      overlayStrength <= 1
          ? overlayStrength.toStringAsFixed(2)
          : overlayStrength.toStringAsFixed(0));

  putIfBlank('card_format', 'portrait');
  putIfBlank('font_family', 'system');
  putIfBlank('text_scale_mode', 'auto');
  putIfBlank('content_width', '86');
  putIfBlank('card_padding', '34');
  putIfBlank('card_padding_x', output['card_padding']?.toString() ?? '34');
  putIfBlank('card_padding_y', output['card_padding']?.toString() ?? '34');
  putIfBlank('text_shadow', 'soft');
  putIfBlank('line_height', '1.35');
  putIfBlank('show_quote_mark', true);

  return output;
}

String _colorToBackendHex(Color color) {
  final value = color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
  return '#${value.substring(2)}';
}

String _fontWeightToBackendValue(FontWeight weight) {
  if (weight == FontWeight.w100) return '100';
  if (weight == FontWeight.w200) return '200';
  if (weight == FontWeight.w300) return '300';
  if (weight == FontWeight.w400) return '400';
  if (weight == FontWeight.w500) return '500';
  if (weight == FontWeight.w600) return '600';
  if (weight == FontWeight.w700) return '700';
  if (weight == FontWeight.w800) return '800';
  return '900';
}

String _textAlignToBackendValue(TextAlign align) {
  switch (align) {
    case TextAlign.left:
    case TextAlign.start:
      return 'left';
    case TextAlign.right:
    case TextAlign.end:
      return 'right';
    case TextAlign.justify:
      return 'justify';
    case TextAlign.center:
      return 'center';
  }
}

List<Widget> _buildActions(
  BuildContext context, {
  required DxmDesignData design,
  required List<_DailyCardAction> items,
}) {
  final children = <Widget>[];

  for (var index = 0; index < items.length; index++) {
    if (index > 0) {
      children.add(const SizedBox(width: 10));
    }

    final item = items[index];

    children.add(
      Expanded(
        child: item.primary
            ? _PrimaryDailyActionButton(
                icon: item.icon,
                label: item.label,
                onPressed: item.onPressed,
                design: design,
              )
            : _GlassDailyActionButton(
                icon: item.icon,
                label: item.label,
                onPressed: item.onPressed,
                design: design,
              ),
      ),
    );
  }

  return children;
}

class _DailyCardAction {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  const _DailyCardAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.primary,
  });
}

class _GlassDailyActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final DxmDesignData design;

  const _GlassDailyActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.design,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: design.accentColor.withOpacity(0.42)),
        backgroundColor: Colors.white.withOpacity(0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _PrimaryDailyActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final DxmDesignData design;

  const _PrimaryDailyActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.design,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF141225),
        disabledBackgroundColor: Colors.white.withOpacity(0.55),
        disabledForegroundColor: const Color(0xFF141225).withOpacity(0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12.5,
        ),
      ),
    );
  }
}
