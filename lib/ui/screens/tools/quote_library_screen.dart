import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/quote_creator/models/quote_design.dart';
import '../../../features/quote_creator/services/quote_storage_service.dart';
import '../../../features/quote_creator/state/quote_creator_store.dart';
import '../../../services/ads_service.dart';
import '../../widgets/ads/native_inline_ad_tile.dart';
import '../../widgets/ads/native_list_injection.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/gradient_page_background.dart';

class QuoteLibraryScreen extends StatefulWidget {
  const QuoteLibraryScreen({super.key});

  @override
  State<QuoteLibraryScreen> createState() => _QuoteLibraryScreenState();
}

class _QuoteLibraryScreenState extends State<QuoteLibraryScreen> {
  static const _topGradient = LinearGradient(
    colors: [
      Color(0xFF1A1F5A),
      Color(0xFF5B1FA8),
      Color(0xFFB70E7C),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  List<QuoteDesign> designs = [];

  @override
  void initState() {
    super.initState();
    load();
    AdsService.instance.preloadInterstitial(tabKey: 'explore');
  }

  Future<void> load() async {
    final data = await QuoteStorageService.getDesigns();
    if (!mounted) return;
    setState(() => designs = data);
  }

  @override
  Widget build(BuildContext context) {
    final entries = NativeListInjection.buildEntries<QuoteDesign>(
      designs,
      tabKey: 'explore.quote_library',
    );

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(gradient: _topGradient),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                ),
                const Expanded(
                  child: Text(
                    'My Designs',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: GradientPageBackground(
        child: Column(
          children: [
            Expanded(
              child: designs.isEmpty
                  ? Center(
                      child: Text(
                        'No designs yet',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        if (entry.isAd) {
                          return const NativeInlineAdTile(
                            tabKey: 'explore.quote_library',
                            label: 'Sponsored',
                            minHeight: 130,
                          );
                        }
                        final d = entry.item!;
                        final data = Map<String, dynamic>.from(d.designData);

                        final bgColor = Color(
                          (data['backgroundColor'] is int)
                              ? data['backgroundColor'] as int
                              : 0xFF1A1F5A,
                        );

                        final gradientData = data['gradient'];
                        final backgroundGradient =
                            gradientData is List && gradientData.length >= 2
                                ? LinearGradient(
                                    colors: gradientData
                                        .map((e) => Color(
                                              e is int ? e : 0xFF1A1F5A,
                                            ))
                                        .toList(),
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null;

                        final bgImage =
                            (data['backgroundImage'] ?? '').toString().trim();

                        final textColor = Color(
                          (data['textColor'] is int)
                              ? data['textColor'] as int
                              : 0xFFFFFFFF,
                        );

                        final highlightColor = Color(
                          (data['highlightColor'] is int)
                              ? data['highlightColor'] as int
                              : 0xFFFFE1B8,
                        );

                        final authorColor = Color(
                          (data['authorColor'] is int)
                              ? data['authorColor'] as int
                              : 0xFFE7E7F1,
                        );

                        final segmentsData = data['segments'];
                        final segments = segmentsData is List
                            ? segmentsData
                                .whereType<Map>()
                                .map(
                                  (e) => QuoteTextSegment.fromJson(
                                    Map<String, dynamic>.from(e),
                                  ),
                                )
                                .toList()
                            : <QuoteTextSegment>[];

                        final fontSize = (data['fontSize'] is num)
                            ? (data['fontSize'] as num).toDouble()
                            : 24.0;

                        final authorFontSize = (data['authorFontSize'] is num)
                            ? (data['authorFontSize'] as num).toDouble()
                            : ((fontSize * 0.48).clamp(8.0, 32.0)).toDouble();

                        final textScale = (data['textScale'] is num)
                            ? (data['textScale'] as num).toDouble()
                            : 1.0;

                        final textAlign = _textAlignFromValue(
                          (data['textAlign'] ?? 'center').toString(),
                        );

                        final showWatermark = data['showWatermark'] == true;
                        final fontFamily =
                            (data['fontFamily'] ?? 'Montserrat').toString();

                        final textOffset = Offset(
                          (data['textOffsetX'] is num)
                              ? (data['textOffsetX'] as num).toDouble()
                              : 0.0,
                          (data['textOffsetY'] is num)
                              ? (data['textOffsetY'] as num).toDouble()
                              : 0.0,
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E1430),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: Container(
                                  height: 220,
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    gradient: backgroundGradient,
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: _LibraryBackgroundImage(
                                          pathOrUrl: bgImage,
                                          fallbackColor: bgColor,
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.black
                                                    .withValues(alpha: 0.10),
                                                Colors.black
                                                    .withValues(alpha: 0.22),
                                                Colors.black
                                                    .withValues(alpha: 0.52),
                                              ],
                                              stops: const [0.0, 0.42, 1.0],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          child: Transform.translate(
                                            offset: textOffset,
                                            child: Transform.scale(
                                              scale: textScale,
                                              child: ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                  maxWidth: 240,
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    _QuoteRichTextBlock(
                                                      quoteText: d.quote.isEmpty
                                                          ? 'Untitled Design'
                                                          : d.quote,
                                                      segments: segments,
                                                      textAlign: textAlign,
                                                      baseStyle:
                                                          _resolveFontStyle(
                                                        fontFamily: fontFamily,
                                                        color: textColor,
                                                        fontSize: fontSize,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        height: 1.25,
                                                      ),
                                                      highlightColor:
                                                          highlightColor,
                                                      maxLines: 4,
                                                    ),
                                                    if (d
                                                        .author.isNotEmpty) ...[
                                                      const SizedBox(
                                                          height: 10),
                                                      Text(
                                                        d.author,
                                                        textAlign: textAlign,
                                                        maxLines: 3,
                                                        softWrap: true,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style:
                                                            _resolveFontStyle(
                                                          fontFamily:
                                                              fontFamily,
                                                          color: authorColor,
                                                          fontSize:
                                                              authorFontSize,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          height: 1.2,
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
                                      if (showWatermark)
                                        Positioned(
                                          left: 16,
                                          right: 16,
                                          bottom: 12,
                                          child: Center(
                                            child: Text(
                                              'Dunamis TV',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.82),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.quote,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (d.author.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          d.author,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              context.push(
                                                '/tools/quote',
                                                extra: {
                                                  'designData': {
                                                    ...data,
                                                    'designId': d.id,
                                                  },
                                                },
                                              );
                                            },
                                            icon:
                                                const Icon(Icons.edit_rounded),
                                            label: const Text('Edit'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.white,
                                              side: BorderSide(
                                                color: Colors.white
                                                    .withValues(alpha: 0.20),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_rounded,
                                            color: Colors.red,
                                          ),
                                          onPressed: () async {
                                            await QuoteStorageService
                                                .deleteDesign(
                                              d.id,
                                            );
                                            await load();
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SafeArea(
              top: false,
              child: BannerAdWidget(
                tabKey: 'explore.quote_library',
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextAlign _textAlignFromValue(String value) {
    switch (value) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'center':
      default:
        return TextAlign.center;
    }
  }
}

class _LibraryBackgroundImage extends StatelessWidget {
  final String pathOrUrl;
  final Color fallbackColor;

  const _LibraryBackgroundImage({
    required this.pathOrUrl,
    required this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    final value = pathOrUrl.trim();

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
      );
    }

    if (!kIsWeb && !value.startsWith('assets/')) {
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
}

class _QuoteRichTextBlock extends StatelessWidget {
  final String quoteText;
  final List<QuoteTextSegment> segments;
  final TextAlign textAlign;
  final TextStyle baseStyle;
  final Color highlightColor;
  final int maxLines;

  const _QuoteRichTextBlock({
    required this.quoteText,
    required this.segments,
    required this.textAlign,
    required this.baseStyle,
    required this.highlightColor,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final hasValidSegments =
        segments.isNotEmpty && segments.map((e) => e.text).join() == quoteText;

    if (!hasValidSegments) {
      return Text(
        quoteText,
        textAlign: textAlign,
        maxLines: maxLines,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    return Text.rich(
      TextSpan(
        children: segments.map((seg) {
          return TextSpan(
            text: seg.text,
            style: baseStyle.copyWith(
              color: seg.isHighlight ? highlightColor : baseStyle.color,
              fontWeight: seg.isHighlight ? FontWeight.w900 : FontWeight.w700,
            ),
          );
        }).toList(),
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      softWrap: true,
      overflow: TextOverflow.ellipsis,
    );
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
