import 'package:flutter/material.dart';

class DxmDesignData {
  final String backgroundMode;
  final String cardFormat;
  final String fontFamily;
  final String textScaleMode;

  final Color textColor;
  final Color backgroundColor;
  final Color backgroundColor2;
  final Color accentColor;
  final Color sourceColor;
  final Color highlightColor;

  final double mainFontSize;
  final double supportFontSize;
  final FontWeight fontWeight;
  final FontWeight sourceWeight;
  final FontWeight highlightWeight;
  final TextAlign textAlign;
  final DxmVerticalAlign verticalAlign;

  final double overlayStrength;
  final double contentWidthPercent;
  final double cardPadding;
  final double cardPaddingX;
  final double cardPaddingY;
  final double lineHeight;
  final double highlightScale;
  final bool showQuoteMark;
  final String highlightPhrases;
  final String textShadowMode;
  final double offsetX;
  final double offsetY;
  final double quoteMarkSize;
  final double quoteMarkOpacity;
  final String quoteMarkPosition;
  final String backgroundFit;
  final String backgroundPosition;
  final String overlayStyle;
  final double borderRadiusValue;
  final double letterSpacing;
  final double sourceSpacing;

  final String imageUrl;
  final String fallbackAsset;

  const DxmDesignData({
    required this.backgroundMode,
    required this.cardFormat,
    required this.fontFamily,
    required this.textScaleMode,
    required this.textColor,
    required this.backgroundColor,
    required this.backgroundColor2,
    required this.accentColor,
    required this.sourceColor,
    required this.highlightColor,
    required this.mainFontSize,
    required this.supportFontSize,
    required this.fontWeight,
    required this.sourceWeight,
    required this.highlightWeight,
    required this.textAlign,
    required this.verticalAlign,
    required this.overlayStrength,
    required this.contentWidthPercent,
    required this.cardPadding,
    required this.cardPaddingX,
    required this.cardPaddingY,
    required this.lineHeight,
    required this.highlightScale,
    required this.showQuoteMark,
    required this.highlightPhrases,
    required this.textShadowMode,
    required this.offsetX,
    required this.offsetY,
    required this.quoteMarkSize,
    required this.quoteMarkOpacity,
    required this.quoteMarkPosition,
    required this.backgroundFit,
    required this.backgroundPosition,
    required this.overlayStyle,
    required this.borderRadiusValue,
    required this.letterSpacing,
    required this.sourceSpacing,
    required this.imageUrl,
    required this.fallbackAsset,
  });

  factory DxmDesignData.fromMap(
    Map<String, dynamic>? source, {
    String imageUrl = '',
    String fallbackAsset = 'assets/images/home_5.jpg',
    double fallbackMainFontSize = 24,
    double fallbackSupportFontSize = 14,
  }) {
    final map = _flattenDesignMap(source);

    final pickedImageUrl = _pickString(
      map,
      const [
        'image_url',
        'imageUrl',
        'background_image_url',
        'backgroundImageUrl',
        'cover_image_url',
        'coverImageUrl',
        'thumbnail_url',
        'thumbnailUrl',
      ],
      fallback: imageUrl,
    );

    final hasImage = pickedImageUrl.trim().isNotEmpty;
    final explicitBackgroundMode = _pickString(
      map,
      const [
        'background_mode',
        'backgroundMode',
        'bg_mode',
        'mode_background',
      ],
      fallback: '',
    );

    final fallbackBackgroundMode = explicitBackgroundMode.isNotEmpty
        ? explicitBackgroundMode
        : (_boolValue(
            _pickDynamic(map, const ['use_solid_background', 'use_solid_bg']),
          )
            ? 'solid'
            : (hasImage ? 'image' : 'gradient'));

    final baseCardPadding = _doubleValue(
      _pickDynamic(map, const ['card_padding', 'cardPadding', 'padding']),
      fallback: 34,
      min: 0,
      max: 220,
    );

    return DxmDesignData(
      backgroundMode: fallbackBackgroundMode,
      cardFormat: _pickString(
        map,
        const ['card_format', 'format', 'canvas', 'ratio'],
        fallback: 'portrait',
      ),
      fontFamily: _pickString(
        map,
        const [
          'font_key',
          'fontKey',
          'font_family',
          'fontFamily',
          'family',
          'font'
        ],
        fallback: 'system',
      ),
      textScaleMode: _pickString(
        map,
        const ['text_scale_mode', 'textScaleMode'],
        fallback: 'auto',
      ),
      textColor: _colorValue(
        _pickDynamic(map, const ['text_color', 'textColor', 'color']),
        fallback: Colors.white,
      ),
      backgroundColor: _colorValue(
        _pickDynamic(
          map,
          const [
            'bg_color',
            'background_color',
            'backgroundColor',
            'bg',
          ],
        ),
        fallback: const Color(0xFF160042),
      ),
      backgroundColor2: _colorValue(
        _pickDynamic(
          map,
          const [
            'bg_color_2',
            'background_color_2',
            'backgroundColor2',
            'bg2',
          ],
        ),
        fallback: const Color(0xFFE2388A),
      ),
      accentColor: _colorValue(
        _pickDynamic(map, const ['accent_color', 'accentColor', 'accent']),
        fallback: const Color(0xFF38BDF8),
      ),
      sourceColor: _colorValue(
        _pickDynamic(map, const [
          'source_color',
          'sourceColor',
          'reference_color',
          'referenceColor'
        ]),
        fallback: _colorValue(
          _pickDynamic(map, const ['text_color', 'textColor', 'color']),
          fallback: Colors.white,
        ).withOpacity(0.92),
      ),
      highlightColor: _colorValue(
        _pickDynamic(map, const ['highlight_color', 'highlightColor']),
        fallback: const Color(0xFFFFD54A),
      ),
      mainFontSize: _doubleValue(
        _pickDynamic(
          map,
          const [
            'quote_size',
            'main_font_size',
            'mainFontSize',
            'title_size',
            'titleSize',
            'font_size',
            'fontSize',
          ],
        ),
        fallback: fallbackMainFontSize,
        min: 8,
        max: 96,
      ),
      supportFontSize: _doubleValue(
        _pickDynamic(
          map,
          const [
            'source_size',
            'sourceSize',
            'support_font_size',
            'supportFontSize',
            'author_font_size',
            'authorFontSize',
            'brand_font_size',
            'brandFontSize',
            'reference_size',
            'referenceSize',
          ],
        ),
        fallback: fallbackSupportFontSize,
        min: 8,
        max: 48,
      ),
      fontWeight: _fontWeightValue(
        _pickDynamic(map, const ['font_weight', 'fontWeight', 'weight']),
        fallback: FontWeight.w700,
      ),
      sourceWeight: _fontWeightValue(
        _pickDynamic(map, const [
          'source_weight',
          'sourceWeight',
          'reference_weight',
          'referenceWeight'
        ]),
        fallback: FontWeight.w700,
      ),
      highlightWeight: _fontWeightValue(
        _pickDynamic(map, const ['highlight_weight', 'highlightWeight']),
        fallback: FontWeight.w900,
      ),
      textAlign: _textAlignValue(
        _pickDynamic(map, const ['text_align', 'textAlign', 'align']),
        fallback: TextAlign.center,
      ),
      verticalAlign: _verticalAlignValue(
        _pickDynamic(
          map,
          const ['vertical_align', 'verticalAlign', 'content_position'],
        ),
        fallback: DxmVerticalAlign.center,
      ),
      overlayStrength: _overlayValue(
        _pickDynamic(map, const ['overlay_strength', 'overlayStrength']),
        fallback: 0.58,
      ),
      contentWidthPercent: _doubleValue(
        _pickDynamic(map, const ['content_width', 'contentWidth']),
        fallback: 86,
        min: 30,
        max: 100,
      ),
      cardPadding: baseCardPadding,
      cardPaddingX: _doubleValue(
        _pickDynamic(
          map,
          const ['card_padding_x', 'cardPaddingX', 'padding_x', 'paddingX'],
        ),
        fallback: baseCardPadding,
        min: 0,
        max: 220,
      ),
      cardPaddingY: _doubleValue(
        _pickDynamic(
          map,
          const ['card_padding_y', 'cardPaddingY', 'padding_y', 'paddingY'],
        ),
        fallback: baseCardPadding,
        min: 0,
        max: 220,
      ),
      lineHeight: _doubleValue(
        _pickDynamic(map, const ['line_height', 'lineHeight']),
        fallback: 1.35,
        min: 1,
        max: 2.2,
      ),
      highlightScale: _doubleValue(
        _pickDynamic(map, const [
          'highlight_scale',
          'highlightScale',
          'highlight_size_boost',
          'highlightSizeBoost'
        ]),
        fallback: 1.08,
        min: 0.7,
        max: 2.4,
      ),
      showQuoteMark: _boolValue(
        _pickDynamic(map, const ['show_quote_mark', 'showQuoteMark']),
        fallback: true,
      ),
      highlightPhrases: _pickString(
        map,
        const [
          'highlight_phrases',
          'highlightPhrases',
          'highlight_words',
          'highlightWords'
        ],
        fallback: '',
      ),
      textShadowMode: _pickString(
        map,
        const [
          'text_shadow',
          'textShadow',
          'shadow',
          'shadow_mode',
          'shadowMode'
        ],
        fallback: 'soft',
      ),
      offsetX: _doubleValue(
        _pickDynamic(
            map, const ['offset_x', 'offsetX', 'text_offset_x', 'textOffsetX']),
        fallback: 0,
        min: -220,
        max: 220,
      ),
      offsetY: _doubleValue(
        _pickDynamic(
            map, const ['offset_y', 'offsetY', 'text_offset_y', 'textOffsetY']),
        fallback: 0,
        min: -260,
        max: 260,
      ),
      quoteMarkSize: _doubleValue(
        _pickDynamic(map, const ['quote_mark_size', 'quoteMarkSize']),
        fallback: 84,
        min: 24,
        max: 220,
      ),
      quoteMarkOpacity: _opacityValue(
        _pickDynamic(map, const ['quote_mark_opacity', 'quoteMarkOpacity']),
        fallback: 0.16,
      ),
      quoteMarkPosition: _pickString(
        map,
        const ['quote_mark_position', 'quoteMarkPosition'],
        fallback: 'top_left',
      ),
      backgroundFit: _pickString(
        map,
        const ['background_fit', 'backgroundFit', 'image_fit', 'imageFit'],
        fallback: 'cover',
      ),
      backgroundPosition: _pickString(
        map,
        const [
          'background_position',
          'backgroundPosition',
          'image_position',
          'imagePosition'
        ],
        fallback: 'center',
      ),
      overlayStyle: _pickString(
        map,
        const ['overlay_style', 'overlayStyle'],
        fallback: 'bottom',
      ),
      borderRadiusValue: _doubleValue(
        _pickDynamic(map, const [
          'border_radius',
          'borderRadius',
          'card_radius',
          'cardRadius'
        ]),
        fallback: 24,
        min: 0,
        max: 80,
      ),
      letterSpacing: _doubleValue(
        _pickDynamic(map, const ['letter_spacing', 'letterSpacing']),
        fallback: 0,
        min: -2,
        max: 12,
      ),
      sourceSpacing: _doubleValue(
        _pickDynamic(map, const ['source_spacing', 'sourceSpacing']),
        fallback: 16,
        min: 0,
        max: 80,
      ),
      imageUrl: pickedImageUrl,
      fallbackAsset: fallbackAsset,
    );
  }

  double get aspectRatio {
    switch (cardFormat.trim().toLowerCase()) {
      case 'square':
      case '1:1':
        return 1;
      case 'story':
      case '9:16':
        return 9 / 16;
      case 'landscape':
      case 'wide':
      case '16:9':
        return 16 / 9;
      case 'cinematic':
      case '21:9':
        return 21 / 9;
      case 'classic':
      case '3:4':
        return 3 / 4;
      case 'portrait':
      case '4:5':
      default:
        return 4 / 5;
    }
  }

  bool get usesImageBackground {
    final normalized = backgroundMode.trim().toLowerCase();
    return normalized == 'image' ||
        normalized == 'photo' ||
        normalized == 'media';
  }

  bool get usesSolidBackground {
    final normalized = backgroundMode.trim().toLowerCase();
    return normalized == 'solid' || normalized == 'color';
  }

  bool get usesGradientBackground {
    return !usesImageBackground && !usesSolidBackground;
  }

  Alignment get contentAlignment {
    final x = () {
      switch (textAlign) {
        case TextAlign.left:
        case TextAlign.start:
          return -1.0;
        case TextAlign.right:
        case TextAlign.end:
          return 1.0;
        case TextAlign.center:
        case TextAlign.justify:
          return 0.0;
      }
    }();

    final y = switch (verticalAlign) {
      DxmVerticalAlign.start => -1.0,
      DxmVerticalAlign.center => 0.0,
      DxmVerticalAlign.end => 1.0,
    };

    return Alignment(x, y);
  }

  CrossAxisAlignment get crossAxisAlignment {
    switch (textAlign) {
      case TextAlign.left:
      case TextAlign.start:
        return CrossAxisAlignment.start;
      case TextAlign.right:
      case TextAlign.end:
        return CrossAxisAlignment.end;
      case TextAlign.center:
      case TextAlign.justify:
        return CrossAxisAlignment.center;
    }
  }

  MainAxisAlignment get mainAxisAlignment {
    switch (verticalAlign) {
      case DxmVerticalAlign.start:
        return MainAxisAlignment.start;
      case DxmVerticalAlign.center:
        return MainAxisAlignment.center;
      case DxmVerticalAlign.end:
        return MainAxisAlignment.end;
    }
  }

  double autoMainFontSize(String text) {
    if (textScaleMode.trim().toLowerCase() != 'auto') {
      return mainFontSize;
    }

    final length = text.trim().length;

    if (length > 420) return (mainFontSize - 12).clamp(10, mainFontSize);
    if (length > 300) return (mainFontSize - 9).clamp(11, mainFontSize);
    if (length > 220) return (mainFontSize - 6).clamp(12, mainFontSize);
    if (length > 150) return (mainFontSize - 3).clamp(13, mainFontSize);

    return mainFontSize;
  }
}

enum DxmVerticalAlign {
  start,
  center,
  end,
}

Map<String, dynamic> _flattenDesignMap(Map<String, dynamic>? source) {
  final output = <String, dynamic>{};

  if (source == null) return output;

  void addMap(Map<dynamic, dynamic>? map) {
    if (map == null) return;
    for (final entry in map.entries) {
      output[entry.key.toString()] = entry.value;
    }
  }

  addMap(source);

  final payload = source['payload'];
  if (payload is Map) addMap(payload);

  final style = source['style'];
  if (style is Map) addMap(style);

  final renderStyle = source['render_style'];
  if (renderStyle is Map) addMap(renderStyle);

  final design = source['design'];
  if (design is Map) {
    addMap(design);
    _addQuoteDesignV21Aliases(output, design);
  }

  final quoteCard = source['quote_card'];
  if (quoteCard is Map) {
    addMap(quoteCard);
    final quoteCardColors = quoteCard['colors'];
    if (quoteCardColors is Map) addMap(quoteCardColors);
    final quoteCardLayout = quoteCard['layout'];
    if (quoteCardLayout is Map) addMap(quoteCardLayout);
    final quoteCardTypography = quoteCard['typography'];
    if (quoteCardTypography is Map) addMap(quoteCardTypography);
  }

  final designer = source['designer'];
  if (designer is Map) addMap(designer);

  final cover = source['cover'];
  if (cover is Map) addMap(cover);

  final media = source['media'];
  if (media is Map) addMap(media);

  final meta = source['meta'];
  if (meta is Map) addMap(meta);

  final metaJson = source['meta_json'];
  if (metaJson is Map) addMap(metaJson);

  final blocks = source['blocks_json'];
  if (blocks is List && blocks.isNotEmpty) {
    final first = blocks.first;
    if (first is Map) {
      addMap(first);
      final firstMeta = first['meta'];
      if (firstMeta is Map) addMap(firstMeta);
    }
  }

  return output;
}

void _addQuoteDesignV21Aliases(
  Map<String, dynamic> output,
  Map<dynamic, dynamic> design,
) {
  void put(String key, dynamic value) {
    if (value == null) return;
    if (value is String && value.trim().isEmpty) return;
    output[key] = value;
  }

  Map<dynamic, dynamic>? asMap(dynamic value) {
    if (value is Map) return value;
    return null;
  }

  final text = asMap(design['text']);
  if (text != null) {
    put('font_key', text['font_key']);
    put('font_family', text['font_family']);
    put('text_align', text['align']);
    put('text_color', text['color']);
    put('offset_x', text['offset_x']);
    put('offset_y', text['offset_y']);
    put('quote_size', text['font_size']);
    put('padding_x', text['padding_x']);
    put('padding_y', text['padding_y']);
    put('card_padding_x', text['padding_x']);
    put('card_padding_y', text['padding_y']);
    put('font_weight', text['font_weight']);
    put('line_height', text['line_height']);
    put('content_width', text['content_width']);
    put('letter_spacing', text['letter_spacing']);
    put('vertical_align', text['vertical_align']);
  }

  final source = asMap(design['source']);
  if (source != null) {
    put('source_color', source['color']);
    put('source_spacing', source['spacing']);
    put('source_size', source['font_size']);
    put('source_weight', source['font_weight']);
  }

  final highlight = asMap(design['highlight']);
  if (highlight != null) {
    put('highlight_color', highlight['color']);
    put('highlight_scale', highlight['scale']);
    put('highlight_weight', highlight['weight']);
  }

  final background = asMap(design['background']);
  if (background != null) {
    put('background_fit', background['fit']);
    put('background_mode', background['mode']);
    put('background_color', background['color']);
    put('bg_color', background['color']);
    put('background_color_2', background['color2']);
    put('bg_color_2', background['color2']);
    put('background_position', background['position']);
    put('overlay_style', background['overlay_style']);
    put('overlay_strength', background['overlay_strength']);
  }

  final decorations = asMap(design['decorations']);
  if (decorations != null) {
    put('border_radius', decorations['border_radius']);
    put('quote_mark_size', decorations['quote_mark_size']);
    put('show_quote_mark', decorations['quote_mark_enabled']);
    put('quote_mark_opacity', decorations['quote_mark_opacity']);
    put('quote_mark_position', decorations['quote_mark_position']);
  }
}

dynamic _pickDynamic(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    if (!source.containsKey(key)) continue;
    final value = source[key];
    if (value == null) continue;
    if (value is String && value.trim().isEmpty) continue;
    return value;
  }

  return null;
}

String _pickString(
  Map<String, dynamic> source,
  List<String> keys, {
  required String fallback,
}) {
  final value = _pickDynamic(source, keys);
  final raw = (value ?? '').toString().trim();
  return raw.isEmpty ? fallback : raw;
}

bool _boolValue(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;

  final raw = value.toString().trim().toLowerCase();
  if (raw.isEmpty) return fallback;

  return raw == '1' ||
      raw == 'true' ||
      raw == 'yes' ||
      raw == 'on' ||
      raw == 'enabled';
}

double _doubleValue(
  dynamic value, {
  required double fallback,
  double? min,
  double? max,
}) {
  final raw = (value ?? '').toString().trim();
  final parsed = double.tryParse(raw);
  if (parsed == null) return fallback;

  var output = parsed;
  if (min != null && output < min) output = min;
  if (max != null && output > max) output = max;
  return output;
}

double _opacityValue(dynamic value, {required double fallback}) {
  final parsed = _doubleValue(value, fallback: fallback, min: 0, max: 100);

  if (parsed > 1) {
    return (parsed / 100).clamp(0.0, 1.0);
  }

  return parsed.clamp(0.0, 1.0);
}

double _overlayValue(dynamic value, {required double fallback}) {
  final parsed = _doubleValue(value, fallback: fallback, min: 0, max: 100);

  if (parsed > 1) {
    return (parsed / 100).clamp(0.0, 1.0);
  }

  return parsed.clamp(0.0, 1.0);
}

Color _colorValue(dynamic value, {required Color fallback}) {
  final raw = (value ?? '').toString().trim();
  if (raw.isEmpty) return fallback;

  if (value is int) return Color(value);

  var hex = raw;
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.startsWith('0x')) hex = hex.substring(2);
  if (hex.length == 6) hex = 'FF$hex';

  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return fallback;

  return Color(parsed);
}

FontWeight _fontWeightValue(dynamic value, {required FontWeight fallback}) {
  final raw = (value ?? '')
      .toString()
      .trim()
      .toLowerCase()
      .replaceAll('-', '_')
      .replaceAll(' ', '_');

  switch (raw) {
    case 'thin':
      return FontWeight.w100;
    case 'extra_light':
      return FontWeight.w200;
    case 'light':
      return FontWeight.w300;
    case 'normal':
    case 'regular':
      return FontWeight.w400;
    case 'medium':
      return FontWeight.w500;
    case 'semi_bold':
    case 'semibold':
      return FontWeight.w600;
    case 'bold':
      return FontWeight.w700;
    case 'extra_bold':
    case 'extrabold':
      return FontWeight.w800;
    case 'black':
    case 'heavy':
      return FontWeight.w900;
  }

  final parsed = int.tryParse(raw);

  if (parsed == null) return fallback;
  if (parsed <= 100) return FontWeight.w100;
  if (parsed <= 200) return FontWeight.w200;
  if (parsed <= 300) return FontWeight.w300;
  if (parsed <= 400) return FontWeight.w400;
  if (parsed <= 500) return FontWeight.w500;
  if (parsed <= 600) return FontWeight.w600;
  if (parsed <= 700) return FontWeight.w700;
  if (parsed <= 800) return FontWeight.w800;

  return FontWeight.w900;
}

TextAlign _textAlignValue(dynamic value, {required TextAlign fallback}) {
  switch ((value ?? '').toString().trim().toLowerCase()) {
    case 'left':
    case 'start':
      return TextAlign.left;
    case 'right':
    case 'end':
      return TextAlign.right;
    case 'justify':
      return TextAlign.justify;
    case 'center':
      return TextAlign.center;
    default:
      return fallback;
  }
}

DxmVerticalAlign _verticalAlignValue(
  dynamic value, {
  required DxmVerticalAlign fallback,
}) {
  switch ((value ?? '').toString().trim().toLowerCase()) {
    case 'top':
    case 'start':
      return DxmVerticalAlign.start;
    case 'bottom':
    case 'end':
      return DxmVerticalAlign.end;
    case 'center':
      return DxmVerticalAlign.center;
    default:
      return fallback;
  }
}
