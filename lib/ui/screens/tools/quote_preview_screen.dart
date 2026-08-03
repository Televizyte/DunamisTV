import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../features/quote_creator/models/quote_design.dart';
import '../../../features/quote_creator/services/quote_storage_service.dart';
import '../../../features/quote_creator/state/quote_creator_store.dart';
import '../../../theme/theme_controller.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';

class QuotePreviewScreen extends StatefulWidget {
  const QuotePreviewScreen({super.key});

  @override
  State<QuotePreviewScreen> createState() => _QuotePreviewScreenState();
}

class _QuotePreviewScreenState extends State<QuotePreviewScreen> {
  final GlobalKey _previewBoundaryKey = GlobalKey();

  bool _isSavingImage = false;
  bool _isSharingImage = false;
  bool _isSavingDesign = false;

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    final data =
        extra is Map ? Map<String, dynamic>.from(extra) : <String, dynamic>{};

    final designId = (data['designId'] ?? '').toString().trim();
    final quote = (data['quote'] ?? '').toString().trim();
    final author = (data['author'] ?? '').toString().trim();

    final segmentsData = data['segments'];
    final segments = segmentsData is List
        ? segmentsData
            .whereType<Map>()
            .map((e) => QuoteTextSegment.fromJson(Map<String, dynamic>.from(e)))
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

    final textAlign =
        _textAlignFromValue((data['textAlign'] ?? 'center').toString());

    final textColor = Color(_asInt(data['textColor'], 0xFFFFFFFF));
    final highlightColor = Color(_asInt(data['highlightColor'], 0xFFFFE1B8));
    final authorColor = Color(_asInt(data['authorColor'], 0xFFE7E7F1));
    final backgroundColor = Color(_asInt(data['backgroundColor'], 0xFF1A1F5A));
    final showWatermark = data['showWatermark'] == true;
    final backgroundImage = (data['backgroundImage'] ?? '').toString().trim();
    final fontFamily = (data['fontFamily'] ?? 'Montserrat').toString();

    final textOffset = Offset(
      (data['textOffsetX'] is num)
          ? (data['textOffsetX'] as num).toDouble()
          : 0.0,
      (data['textOffsetY'] is num)
          ? (data['textOffsetY'] as num).toDouble()
          : 0.0,
    );

    final gradientData = data['gradient'];
    final backgroundGradient = gradientData is List && gradientData.length >= 2
        ? LinearGradient(
            colors:
                gradientData.map((e) => Color(_asInt(e, 0xFF1A1F5A))).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    final quoteBaseStyle = _resolveFontStyle(
      fontFamily: fontFamily,
      color: textColor,
      fontSize: fontSize,
      height: 1.28,
      fontWeight: FontWeight.w700,
    );

    final authorStyle = _resolveFontStyle(
      fontFamily: fontFamily,
      color: authorColor,
      fontSize: authorFontSize,
      height: 1.25,
      fontWeight: FontWeight.w600,
    );

    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final isLight = ThemeController.instance.isLightMode;
        final helperTextColor =
            isLight ? const Color(0xFF6B6256) : Colors.white.withOpacity(0.68);
        final panelColor =
            isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430);
        final borderColor = isLight
            ? const Color(0xFFE6D8C3)
            : Colors.white.withOpacity(0.08);
        final outlineFg =
            isLight ? const Color(0xFF1E1B16) : Colors.white;

        return Scaffold(
          appBar: DxmTopBar(
            title: 'Preview',
            showBack: true,
            showMenu: true,
          ),
          body: GradientPageBackground(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: panelColor,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isLight ? 0.10 : 0.16),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: RepaintBoundary(
                          key: _previewBoundaryKey,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              height: 460,
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                gradient: backgroundGradient,
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: _PreviewBackgroundImage(
                                      pathOrUrl: backgroundImage,
                                      fallbackColor: backgroundColor,
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.10),
                                            Colors.black.withOpacity(0.22),
                                            Colors.black.withOpacity(0.52),
                                          ],
                                          stops: const [0.0, 0.42, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final content = ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: constraints.maxWidth * 0.84,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _QuoteRichTextBlock(
                                              quoteText: quote.isEmpty
                                                  ? 'Your quote preview'
                                                  : quote,
                                              segments: segments,
                                              textAlign: textAlign,
                                              baseStyle: quoteBaseStyle,
                                              highlightColor: highlightColor,
                                            ),
                                            if (author.isNotEmpty) ...[
                                              const SizedBox(height: 18),
                                              Text(
                                                author,
                                                textAlign: textAlign,
                                                style: authorStyle,
                                                softWrap: true,
                                                overflow: TextOverflow.visible,
                                                maxLines: null,
                                              ),
                                            ],
                                          ],
                                        ),
                                      );

                                      return Stack(
                                        children: [
                                          Positioned.fill(
                                            child: Center(
                                              child: Transform.translate(
                                                offset: textOffset,
                                                child: Transform.scale(
                                                  scale: textScale,
                                                  child: content,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (showWatermark)
                                            Positioned(
                                              left: 24,
                                              right: 24,
                                              bottom: 18,
                                              child: Center(
                                                child: Text(
                                                  'Dunamis TV',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.82),
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
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Preview your design before saving it to your library or exporting it as an image.',
                        style: TextStyle(
                          color: helperTextColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => context.pop(),
                              icon: const Icon(Icons.edit_rounded),
                              label: const Text('Back to Edit'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: outlineFg,
                                side: BorderSide(
                                  color: isLight
                                      ? const Color(0xFFDCCDB8)
                                      : Colors.white.withOpacity(0.22),
                                ),
                                backgroundColor:
                                    isLight ? Colors.white.withOpacity(0.86) : null,
                                shadowColor: Colors.black.withOpacity(0.10),
                                elevation: isLight ? 2 : 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSavingDesign
                                  ? null
                                  : () => _saveDesignToLibrary(
                                        designId: designId,
                                        quote: quote,
                                        author: author,
                                        data: data,
                                      ),
                              icon: _isSavingDesign
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_rounded),
                              label: Text(
                                _isSavingDesign ? 'Saving...' : 'Save Design',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF2C96),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSavingImage ? null : _saveRenderedImage,
                              icon: _isSavingImage
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.download_rounded),
                              label: Text(
                                _isSavingImage ? 'Saving...' : 'Save Image',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: outlineFg,
                                side: BorderSide(
                                  color: isLight
                                      ? const Color(0xFFDCCDB8)
                                      : Colors.white.withOpacity(0.22),
                                ),
                                backgroundColor:
                                    isLight ? Colors.white.withOpacity(0.86) : null,
                                shadowColor: Colors.black.withOpacity(0.10),
                                elevation: isLight ? 2 : 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isSharingImage ? null : _shareRenderedImage,
                              icon: _isSharingImage
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.share_rounded),
                              label: Text(
                                _isSharingImage ? 'Sharing...' : 'Share Image',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A6CF0),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SafeArea(
                  top: false,
                  child: BannerAdWidget(
                    tabKey: 'explore',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveDesignToLibrary({
    required String designId,
    required String quote,
    required String author,
    required Map<String, dynamic> data,
  }) async {
    setState(() => _isSavingDesign = true);

    try {
      final resolvedId =
          designId.trim().isNotEmpty ? designId : const Uuid().v4();

      final design = QuoteDesign(
        id: resolvedId,
        quote: quote,
        author: author,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        designData: {
          ...data,
          'designId': resolvedId,
        },
      );

      await QuoteStorageService.saveDesign(design);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to library')),
      );

      context.push('/tools/quote/library');
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save design')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingDesign = false);
      }
    }
  }

  Future<void> _saveRenderedImage() async {
    setState(() => _isSavingImage = true);

    try {
      final bytes = await _renderPreviewToBytes();
      final fileName =
          'dunamis_quote_${DateTime.now().millisecondsSinceEpoch}.png';

      if (kIsWeb) {
        await Share.shareXFiles(
          [
            XFile.fromData(
              bytes,
              mimeType: 'image/png',
              name: fileName,
            ),
          ],
          fileNameOverrides: [fileName],
          text: 'Dunamis TV Quote Creator',
        );
      } else {
        final file = await _writeImageBytes(bytes, fileName);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image saved: ${file.path}')),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save image')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingImage = false);
      }
    }
  }

  Future<void> _shareRenderedImage() async {
    setState(() => _isSharingImage = true);

    try {
      final bytes = await _renderPreviewToBytes();
      final fileName =
          'dunamis_quote_${DateTime.now().millisecondsSinceEpoch}.png';

      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: fileName,
          ),
        ],
        fileNameOverrides: [fileName],
        text: 'Created with Dunamis TV Quote Creator',
        subject: 'Dunamis TV Quote Design',
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share image')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSharingImage = false);
      }
    }
  }

  Future<Uint8List> _renderPreviewToBytes() async {
    final boundaryContext = _previewBoundaryKey.currentContext;
    if (boundaryContext == null) {
      throw Exception('Preview is not ready yet.');
    }

    final renderObject = boundaryContext.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw Exception('Preview boundary is unavailable.');
    }

    final pixelRatio =
        MediaQuery.of(context).devicePixelRatio.clamp(2.0, 4.0).toDouble();

    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Could not convert preview to PNG.');
    }

    return byteData.buffer.asUint8List();
  }

  Future<File> _writeImageBytes(Uint8List bytes, String fileName) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${baseDir.path}/quote_exports');

    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final file = File('${exportDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static TextAlign _textAlignFromValue(String value) {
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

  static int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }
}

class _PreviewBackgroundImage extends StatelessWidget {
  final String pathOrUrl;
  final Color fallbackColor;

  const _PreviewBackgroundImage({
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

  const _QuoteRichTextBlock({
    required this.quoteText,
    required this.segments,
    required this.textAlign,
    required this.baseStyle,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasValidSegments = segments.isNotEmpty &&
        segments.map((e) => e.text).join() == quoteText;

    if (!hasValidSegments) {
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
