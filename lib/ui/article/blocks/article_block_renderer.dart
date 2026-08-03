import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../../../theme/theme_controller.dart';
import '../../media/universal_media_launcher.dart';
import 'bullet_list_block.dart';
import 'divider_block.dart';
import 'heading_block.dart';
import 'image_block.dart';
import 'media_link_block.dart';
import 'paragraph_block.dart';
import 'quote_block.dart';
import 'scripture_block.dart';

class ArticleBlockRenderer extends StatelessWidget {
  final Map<String, dynamic> block;
  final String fallbackAsset;

  final ValueChanged<String>? onMakeQuote;
  final ValueChanged<String>? onAddToNotes;
  final ValueChanged<String>? onOpenInBible;

  const ArticleBlockRenderer({
    super.key,
    required this.block,
    required this.fallbackAsset,
    this.onMakeQuote,
    this.onAddToNotes,
    this.onOpenInBible,
  });

  String _resolveUrl(String input) {
    final u = input.trim();

    if (u.isEmpty) return '';
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    if (u.startsWith('//')) return 'https:$u';
    if (u.startsWith('/')) {
      return 'https://admin.apps.digitxtramedia.com$u';
    }

    return u;
  }

  @override
  Widget build(BuildContext context) {
    final type = (block['type'] ?? 'paragraph').toString().trim().toLowerCase();
    final isLight = ThemeController.instance.isLightMode;
    final colors = _ArticleBlockColors.fromBrightness(isLight);

    switch (type) {
      case 'heading':
        return HeadingBlock(text: _textValue(block, 'text'));

      case 'paragraph':
      case 'text':
        return ParagraphBlock(
          text: _textValue(block, 'text'),
          onMakeQuote: onMakeQuote,
          onAddToNotes: onAddToNotes,
          onOpenInBible: onOpenInBible,
        );

      case 'scripture':
        return ScriptureBlock(text: _textValue(block, 'text'));

      case 'quote':
        return QuoteBlock(text: _textValue(block, 'text'));

      case 'bullet_list':
      case 'list':
        return BulletListBlock(items: _listValue(block, 'items'));

      case 'image':
        return ImageBlock(
          url: _resolveUrl(
            _firstNonEmpty(block, const ['url', 'image_url', 'src', 'image']),
          ),
          fallbackAsset: fallbackAsset,
          caption: _textValue(block, 'caption'),
        );

      case 'youtube':
      case 'video':
      case 'audio':
      case 'web':
      case 'link':
      case 'hls':
        return MediaLinkBlock(
          block: block,
          fallbackAsset: fallbackAsset,
        );

      case 'html':
        final html = _firstNonEmpty(block, const ['html', 'text', 'body']);
        if (html.isEmpty) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.panelBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.panelBorder),
            boxShadow: colors.panelShadow,
          ),
          child: SelectionArea(
            child: HtmlWidget(
              html,
              textStyle: TextStyle(
                color: colors.bodyText,
                fontSize: 15,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
              onTapUrl: (url) {
                final resolved = _resolveUrl(url);
                if (resolved.isEmpty) return false;

                UniversalMediaLauncher.open(
                  context,
                  title: 'Open Link',
                  url: resolved,
                );
                return true;
              },
              customStylesBuilder: (element) {
                switch (element.localName) {
                  case 'body':
                  case 'div':
                    return {
                      'color': colors.cssBodyText,
                    };

                  case 'img':
                    return {
                      'display': 'block',
                      'margin': '12px 0',
                      'border-radius': '14px',
                    };

                  case 'p':
                    return {
                      'margin': '0 0 14px 0',
                      'line-height': '1.6',
                      'color': colors.cssBodyText,
                    };

                  case 'span':
                  case 'strong':
                  case 'b':
                  case 'em':
                  case 'i':
                    return {
                      'color': colors.cssBodyText,
                    };

                  case 'h1':
                  case 'h2':
                  case 'h3':
                  case 'h4':
                    return {
                      'margin': '0 0 12px 0',
                      'line-height': '1.25',
                      'color': colors.cssHeadingText,
                    };

                  case 'ul':
                  case 'ol':
                    return {
                      'margin': '0 0 14px 0',
                      'padding-left': '18px',
                      'color': colors.cssBodyText,
                    };

                  case 'li':
                    return {
                      'margin': '0 0 8px 0',
                      'color': colors.cssBodyText,
                    };

                  case 'blockquote':
                    return {
                      'margin': '10px 0',
                      'padding': '10px 12px',
                      'border-left': '3px solid #B70E7C',
                      'background-color': colors.cssQuoteBg,
                      'border-radius': '12px',
                      'color': colors.cssBodyText,
                    };

                  case 'a':
                    return {
                      'color': colors.cssLinkText,
                      'text-decoration': 'underline',
                    };
                }
                return null;
              },
              customWidgetBuilder: (element) {
                if (element.localName == 'img') {
                  final raw = (element.attributes['src'] ?? '').trim();
                  final src = _resolveUrl(raw);

                  if (src.isEmpty) return null;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        src,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Image.asset(
                            fallbackAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 180,
                              color: colors.imageFallback,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 180,
                            color: colors.imageLoading,
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(strokeWidth: 2.2),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }

                return null;
              },
            ),
          ),
        );

      case 'divider':
        return const DividerBlock();

      default:
        final fallbackText = _firstNonEmpty(
          block,
          const ['text', 'body', 'content'],
        );

        if (fallbackText.isNotEmpty) {
          return ParagraphBlock(
            text: fallbackText,
            onMakeQuote: onMakeQuote,
            onAddToNotes: onAddToNotes,
            onOpenInBible: onOpenInBible,
          );
        }

        return const SizedBox.shrink();
    }
  }

  static String _textValue(Map<String, dynamic> map, String key) {
    return (map[key] ?? '').toString().trim();
  }

  static List<String> _listValue(Map<String, dynamic> map, String key) {
    final raw = map[key];
    if (raw is List) {
      return raw
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }
    return const [];
  }

  static String _firstNonEmpty(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      final s = value?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }
    return '';
  }
}

class _ArticleBlockColors {
  final Color panelBg;
  final Color panelBorder;
  final List<BoxShadow>? panelShadow;
  final Color bodyText;
  final Color headingText;
  final Color linkText;
  final Color imageLoading;
  final Color imageFallback;
  final Color quoteBg;

  const _ArticleBlockColors({
    required this.panelBg,
    required this.panelBorder,
    required this.panelShadow,
    required this.bodyText,
    required this.headingText,
    required this.linkText,
    required this.imageLoading,
    required this.imageFallback,
    required this.quoteBg,
  });

  factory _ArticleBlockColors.fromBrightness(bool isLight) {
    if (isLight) {
      return _ArticleBlockColors(
        panelBg: const Color(0xFFFCFCFE),
        panelBorder: const Color(0xFFE6E8F0),
        panelShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
        bodyText: const Color(0xFF202532),
        headingText: const Color(0xFF111827),
        linkText: const Color(0xFF2563EB),
        imageLoading: const Color(0xFFE9ECF5),
        imageFallback: const Color(0xFFD9DEEA),
        quoteBg: const Color(0xFFF3F4F8),
      );
    }

    return _ArticleBlockColors(
      panelBg: const Color(0xFF0D1228),
      panelBorder: Colors.white.withOpacity(0.08),
      panelShadow: null,
      bodyText: Colors.white,
      headingText: Colors.white,
      linkText: const Color(0xFF9CC9FF),
      imageLoading: const Color(0xFF151528),
      imageFallback: const Color(0xFF151528),
      quoteBg: const Color(0xFF111735),
    );
  }

  String get cssBodyText => _toCssHex(bodyText);
  String get cssHeadingText => _toCssHex(headingText);
  String get cssLinkText => _toCssHex(linkText);
  String get cssQuoteBg => _toCssHex(quoteBg);

  static String _toCssHex(Color color) {
    final r = color.red.toRadixString(16).padLeft(2, '0');
    final g = color.green.toRadixString(16).padLeft(2, '0');
    final b = color.blue.toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }
}
