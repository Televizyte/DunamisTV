import 'package:flutter/material.dart';

class QuoteTextSegment {
  final String text;
  final bool isHighlight;

  const QuoteTextSegment({
    required this.text,
    required this.isHighlight,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isHighlight': isHighlight,
    };
  }

  factory QuoteTextSegment.fromJson(Map<String, dynamic> json) {
    return QuoteTextSegment(
      text: (json['text'] ?? '').toString(),
      isHighlight: json['isHighlight'] == true,
    );
  }

  QuoteTextSegment copyWith({
    String? text,
    bool? isHighlight,
  }) {
    return QuoteTextSegment(
      text: text ?? this.text,
      isHighlight: isHighlight ?? this.isHighlight,
    );
  }
}

class QuoteCreatorStore extends ChangeNotifier {
  String? designId;

  String quote = '';
  String author = '';

  List<QuoteTextSegment> segments = [];

  double fontSize = 30;
  double authorFontSize = 14;
  double textScale = 1.0;
  TextAlign alignment = TextAlign.center;

  Color textColor = Colors.white;
  Color highlightColor = const Color(0xFFFFE1B8);
  Color authorColor = const Color(0xFFE7E7F1);

  Color backgroundColor = const Color(0xFF1A1F5A);
  LinearGradient? backgroundGradient;

  bool showWatermark = true;

  String? backgroundImage;
  String fontFamily = 'Montserrat';

  Offset textOffset = Offset.zero;

  double overlayStrength = 0.34;
  double highlightFontScale = 1.08;

  final List<String> bundledBackgrounds = const [
    'assets/images/home_1.jpg',
    'assets/images/home_2.jpg',
    'assets/images/home_3.jpg',
    'assets/images/home_4.jpg',
    'assets/images/home_5.jpg',
  ];

  final List<Color> backgroundColorOptions = const [
    Color(0xFF1A1F5A),
    Color(0xFF5B1FA8),
    Color(0xFFB70E7C),
    Color(0xFF0E1430),
    Color(0xFF123B2F),
    Color(0xFF5B3A10),
    Color(0xFF1B1B2A),
    Color(0xFF222244),
    Color(0xFF3B1A5A),
    Color(0xFF0F3C55),
    Color(0xFF3F2D14),
    Color(0xFF263238),
    Color(0xFFFFFFFF),
    Color(0xFFF8F3E8),
    Color(0xFFFCE4EC),
    Color(0xFFE3F2FD),
    Color(0xFFE8F5E9),
    Color(0xFFFFF8E1),
    Color(0xFFFF1744),
    Color(0xFFE91E63),
    Color(0xFFD500F9),
    Color(0xFF651FFF),
    Color(0xFF2979FF),
    Color(0xFF00B0FF),
    Color(0xFF00E5FF),
    Color(0xFF1DE9B6),
    Color(0xFF00E676),
    Color(0xFF76FF03),
    Color(0xFFC6FF00),
    Color(0xFFFFEA00),
    Color(0xFFFFC400),
    Color(0xFFFF9100),
    Color(0xFFFF3D00),
    Color(0xFF212121),
    Color(0xFF424242),
    Color(0xFF795548),
    Color(0xFF880E4F),
    Color(0xFF4A148C),
    Color(0xFF1A237E),
    Color(0xFF004D40),
  ];

  final List<LinearGradient> gradientOptions = const [
    LinearGradient(colors: [Color(0xFF1A1F5A), Color(0xFF5B1FA8)]),
    LinearGradient(colors: [Color(0xFF5B1FA8), Color(0xFFB70E7C)]),
    LinearGradient(colors: [Color(0xFF0E1430), Color(0xFF123B2F)]),
    LinearGradient(colors: [Color(0xFF3B1A5A), Color(0xFF0F3C55)]),
    LinearGradient(colors: [Color(0xFFB70E7C), Color(0xFF5B3A10)]),
    LinearGradient(colors: [Color(0xFF222244), Color(0xFF3F2D14)]),
    LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFE3F2FD)]),
    LinearGradient(colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)]),
    LinearGradient(colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)]),
    LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]),
    LinearGradient(colors: [Color(0xFFFF1744), Color(0xFFFF9100)]),
    LinearGradient(colors: [Color(0xFFE91E63), Color(0xFF651FFF)]),
    LinearGradient(colors: [Color(0xFF2979FF), Color(0xFF00E5FF)]),
    LinearGradient(colors: [Color(0xFF00E676), Color(0xFFC6FF00)]),
    LinearGradient(colors: [Color(0xFFFFEA00), Color(0xFFFF3D00)]),
    LinearGradient(colors: [Color(0xFF000000), Color(0xFF434343)]),
    LinearGradient(colors: [Color(0xFF141E30), Color(0xFF243B55)]),
    LinearGradient(colors: [Color(0xFF4A148C), Color(0xFF880E4F)]),
    LinearGradient(colors: [Color(0xFF004D40), Color(0xFF1B5E20)]),
    LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF00B0FF)]),
  ];

  final List<String> fontOptions = const [
    'Montserrat',
    'Playfair Display',
    'Oswald',
    'Lora',
    'Poppins',
    'Merriweather',
    'Raleway',
    'Nunito',
    'Roboto Slab',
    'PT Serif',
  ];

  final List<Color> textColorOptions = const [
    Colors.white,
    Color(0xFFFFF1C1),
    Color(0xFFFFD6E8),
    Color(0xFFCFE8FF),
    Color(0xFFD8FFD6),
    Color(0xFFFFCFCF),
    Color(0xFFFAF7FF),
    Color(0xFFFFE1B8),
    Color(0xFFD8F3FF),
    Color(0xFFE8FFD8),
    Color(0xFFFFB8D6),
    Color(0xFFFFEAEA),
    Color(0xFF111111),
    Color(0xFF1B1B2A),
    Color(0xFF263238),
    Color(0xFF3E2723),
    Color(0xFF0D47A1),
    Color(0xFF1B5E20),
    Color(0xFFFF1744),
    Color(0xFFE91E63),
    Color(0xFFD500F9),
    Color(0xFF651FFF),
    Color(0xFF2979FF),
    Color(0xFF00B0FF),
    Color(0xFF00E5FF),
    Color(0xFF1DE9B6),
    Color(0xFF00E676),
    Color(0xFF76FF03),
    Color(0xFFC6FF00),
    Color(0xFFFFEA00),
    Color(0xFFFFC400),
    Color(0xFFFF9100),
    Color(0xFFFF3D00),
  ];

  void setQuote(String value) {
    quote = value;
    _syncSegmentsPreservingHighlights();
    notifyListeners();
  }

  void setAuthor(String value) {
    author = value;
    notifyListeners();
  }

  void setSegments(List<QuoteTextSegment> value) {
    segments = value;
    notifyListeners();
  }

  void clearSegments() {
    segments = _buildPlainSegments(quote);
    notifyListeners();
  }

  void applySegmentsFromText(
    String value, {
    Set<int> highlightedIndexes = const {},
  }) {
    quote = value;

    final matches = RegExp(r'\S+\s*').allMatches(value).toList();
    if (matches.isEmpty) {
      segments = value.isEmpty
          ? []
          : [
              QuoteTextSegment(
                text: value,
                isHighlight: false,
              ),
            ];
      notifyListeners();
      return;
    }

    segments = List<QuoteTextSegment>.generate(matches.length, (index) {
      final text = matches[index].group(0) ?? '';
      return QuoteTextSegment(
        text: text,
        isHighlight: highlightedIndexes.contains(index),
      );
    });

    notifyListeners();
  }

  void toggleSegmentHighlight(int index) {
    _syncSegmentsPreservingHighlights(notify: false);

    if (index < 0 || index >= segments.length) return;

    segments = List<QuoteTextSegment>.from(segments);
    segments[index] = segments[index].copyWith(
      isHighlight: !segments[index].isHighlight,
    );
    notifyListeners();
  }

  void setHighlightColor(Color color) {
    highlightColor = color;
    notifyListeners();
  }

  void setHighlightFontScale(double value) {
    highlightFontScale = value.clamp(0.7, 2.6);
    notifyListeners();
  }

  void setFontSize(double value) {
    fontSize = value.clamp(12.0, 96.0);
    notifyListeners();
  }

  void setAuthorFontSize(double value) {
    authorFontSize = value.clamp(8.0, 48.0);
    notifyListeners();
  }

  void setTextScale(double value) {
    textScale = value.clamp(0.45, 3.5);
    notifyListeners();
  }

  void setOverlayStrength(double value) {
    overlayStrength = value.clamp(0.0, 0.85);
    notifyListeners();
  }

  void setAlignment(TextAlign value) {
    alignment = value;
    notifyListeners();
  }

  void setTextColor(Color color) {
    textColor = color;
    notifyListeners();
  }

  void setAuthorColor(Color color) {
    authorColor = color;
    notifyListeners();
  }

  void setBackgroundColor(Color color) {
    backgroundColor = color;
    backgroundImage = null;
    backgroundGradient = null;
    overlayStrength = 0.0;
    notifyListeners();
  }

  void setBackgroundGradient(LinearGradient gradient) {
    backgroundGradient = gradient;
    backgroundImage = null;
    overlayStrength = 0.0;
    notifyListeners();
  }

  void setBackgroundImage(String path) {
    backgroundImage = path;
    backgroundGradient = null;
    overlayStrength = overlayStrength == 0 ? 0.24 : overlayStrength;
    notifyListeners();
  }

  void clearBackgroundImage() {
    backgroundImage = null;
    notifyListeners();
  }

  void moveTextBy(Offset delta) {
    textOffset = Offset(textOffset.dx + delta.dx, textOffset.dy + delta.dy);
    notifyListeners();
  }

  void resetTextPosition() {
    textOffset = Offset.zero;
    notifyListeners();
  }

  void toggleWatermark() {
    showWatermark = !showWatermark;
    notifyListeners();
  }

  void setFontFamily(String value) {
    fontFamily = value;
    notifyListeners();
  }

  void applyTemplate(String template) {
    switch (template.toLowerCase()) {
      case 'faith':
        fontFamily = 'Playfair Display';
        textColor = Colors.white;
        highlightColor = const Color(0xFFFFE1B8);
        authorColor = const Color(0xFFE7E7F1);
        fontSize = 24;
        authorFontSize = 11.5;
        highlightFontScale = 1.10;
        setBackgroundGradient(
          const LinearGradient(colors: [Color(0xFF1A1F5A), Color(0xFF5B1FA8)]),
        );
        break;
      case 'motivation':
        fontFamily = 'Oswald';
        textColor = Colors.white;
        highlightColor = const Color(0xFFFFE1B8);
        authorColor = const Color(0xFFFFE1B8);
        fontSize = 26;
        authorFontSize = 12.5;
        highlightFontScale = 1.16;
        setBackgroundGradient(
          const LinearGradient(colors: [Color(0xFFB70E7C), Color(0xFF5B3A10)]),
        );
        break;
      case 'prayer':
        fontFamily = 'Lora';
        textColor = Colors.white;
        highlightColor = const Color(0xFFD8FFD6);
        authorColor = const Color(0xFFD8FFD6);
        fontSize = 24;
        authorFontSize = 11.5;
        highlightFontScale = 1.10;
        setBackgroundGradient(
          const LinearGradient(colors: [Color(0xFF0E1430), Color(0xFF123B2F)]),
        );
        break;
      case 'wisdom':
        fontFamily = 'Poppins';
        textColor = Colors.white;
        highlightColor = const Color(0xFFCFE8FF);
        authorColor = const Color(0xFFCFE8FF);
        fontSize = 24;
        authorFontSize = 11.5;
        highlightFontScale = 1.12;
        setBackgroundGradient(
          const LinearGradient(colors: [Color(0xFF3B1A5A), Color(0xFF0F3C55)]),
        );
        break;
      case 'scripture':
        fontFamily = 'Montserrat';
        textColor = const Color(0xFF111111);
        highlightColor = const Color(0xFFB70E7C);
        authorColor = const Color(0xFF263238);
        fontSize = 24;
        authorFontSize = 11.5;
        highlightFontScale = 1.12;
        setBackgroundGradient(
          const LinearGradient(colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)]),
        );
        break;
      case 'bold pink':
        fontFamily = 'Montserrat';
        textColor = Colors.white;
        highlightColor = const Color(0xFFFFEA00);
        authorColor = const Color(0xFFFFD6E8);
        fontSize = 28;
        authorFontSize = 12.5;
        highlightFontScale = 1.18;
        setBackgroundGradient(
          const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFF651FFF)]),
        );
        break;
      case 'clean white':
        fontFamily = 'Poppins';
        textColor = const Color(0xFF111111);
        highlightColor = const Color(0xFFE91E63);
        authorColor = const Color(0xFF424242);
        fontSize = 24;
        authorFontSize = 11.5;
        highlightFontScale = 1.12;
        setBackgroundColor(Colors.white);
        break;
      case 'royal blue':
        fontFamily = 'Merriweather';
        textColor = Colors.white;
        highlightColor = const Color(0xFFFFC400);
        authorColor = const Color(0xFFCFE8FF);
        fontSize = 25;
        authorFontSize = 12.0;
        highlightFontScale = 1.14;
        setBackgroundGradient(
          const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF00B0FF)]),
        );
        break;
    }
  }

  void loadFromPayload(
    Map<String, dynamic> data, {
    bool notify = true,
  }) {
    designId = (data['designId'] ?? '').toString().trim().isEmpty
        ? null
        : (data['designId'] ?? '').toString().trim();

    quote = (data['quote'] ?? '').toString();
    author = (data['author'] ?? '').toString();

    final segmentsData = data['segments'];
    if (segmentsData is List) {
      segments = segmentsData
          .whereType<Map>()
          .map((e) => QuoteTextSegment.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      segments = [];
    }

    fontSize = (data['fontSize'] is num)
        ? (data['fontSize'] as num).toDouble().clamp(12.0, 96.0)
        : 24.0;

    authorFontSize = (data['authorFontSize'] is num)
        ? (data['authorFontSize'] as num).toDouble().clamp(8.0, 48.0)
        : ((fontSize * 0.48).clamp(8.0, 48.0)).toDouble();

    textScale = (data['textScale'] is num)
        ? (data['textScale'] as num).toDouble().clamp(0.45, 3.5)
        : 1.0;

    highlightFontScale = (data['highlightFontScale'] is num)
        ? (data['highlightFontScale'] as num).toDouble().clamp(0.7, 2.6)
        : ((data['highlight_font_scale'] is num)
            ? (data['highlight_font_scale'] as num).toDouble().clamp(0.7, 2.6)
            : highlightFontScale);

    overlayStrength = (data['overlayStrength'] is num)
        ? (data['overlayStrength'] as num).toDouble().clamp(0.0, 0.85)
        : ((data['overlay_strength'] is num)
            ? (data['overlay_strength'] as num).toDouble().clamp(0.0, 0.85)
            : overlayStrength);

    alignment = _textAlignFromValue((data['textAlign'] ?? 'center').toString());

    textColor = Color(_asInt(data['textColor'], Colors.white.value));
    highlightColor =
        Color(_asInt(data['highlightColor'], const Color(0xFFFFE1B8).value));
    authorColor =
        Color(_asInt(data['authorColor'], const Color(0xFFE7E7F1).value));
    backgroundColor =
        Color(_asInt(data['backgroundColor'], const Color(0xFF1A1F5A).value));

    final gradientData = data['gradient'];
    if (gradientData is List && gradientData.length >= 2) {
      final colors = gradientData
          .map((e) => Color(_asInt(e, const Color(0xFF1A1F5A).value)))
          .toList();

      backgroundGradient = LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      backgroundGradient = null;
    }

    final bgImage = data['backgroundImage'];
    backgroundImage = (bgImage is String && bgImage.trim().isNotEmpty)
        ? bgImage.trim()
        : null;

    fontFamily = (data['fontFamily'] ?? 'Montserrat').toString();

    final dx = data['textOffsetX'];
    final dy = data['textOffsetY'];
    textOffset = Offset(
      dx is num ? dx.toDouble() : 0.0,
      dy is num ? dy.toDouble() : 0.0,
    );

    showWatermark = data['showWatermark'] == true;

    if (!_segmentsMatchQuote()) {
      segments = _buildPlainSegments(quote);
    }

    if (notify) {
      notifyListeners();
    }
  }

  Map<String, dynamic> toPayload() {
    return {
      'designId': designId,
      'quote': quote,
      'author': author,
      'segments': segments.map((e) => e.toJson()).toList(),
      'fontSize': fontSize,
      'authorFontSize': authorFontSize,
      'textScale': textScale,
      'highlightFontScale': highlightFontScale,
      'highlight_font_scale': highlightFontScale,
      'textAlign': alignment.name,
      'textColor': textColor.value,
      'highlightColor': highlightColor.value,
      'authorColor': authorColor.value,
      'backgroundColor': backgroundColor.value,
      'gradient': backgroundGradient?.colors.map((e) => e.value).toList(),
      'overlayStrength': overlayStrength,
      'overlay_strength': overlayStrength,
      'showWatermark': showWatermark,
      'backgroundImage': backgroundImage,
      'fontFamily': fontFamily,
      'textOffsetX': textOffset.dx,
      'textOffsetY': textOffset.dy,
    };
  }

  void reset() {
    designId = null;
    quote = '';
    author = '';
    segments = [];
    fontSize = 24;
    authorFontSize = 11.5;
    textScale = 1.0;
    highlightFontScale = 1.08;
    overlayStrength = 0.34;
    alignment = TextAlign.center;
    textColor = Colors.white;
    highlightColor = const Color(0xFFFFE1B8);
    authorColor = const Color(0xFFE7E7F1);
    backgroundColor = const Color(0xFF1A1F5A);
    backgroundGradient = null;
    backgroundImage = null;
    showWatermark = true;
    fontFamily = 'Montserrat';
    textOffset = Offset.zero;
    notifyListeners();
  }

  bool _segmentsMatchQuote() {
    if (quote.isEmpty && segments.isEmpty) return true;
    if (segments.isEmpty) return false;
    return segments.map((e) => e.text).join() == quote;
  }

  List<QuoteTextSegment> _buildPlainSegments(String value) {
    if (value.trim().isEmpty) return [];

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
        .map((match) => QuoteTextSegment(
              text: match.group(0) ?? '',
              isHighlight: false,
            ))
        .toList();
  }

  void _syncSegmentsPreservingHighlights({bool notify = false}) {
    final matches = RegExp(r'\S+\s*').allMatches(quote).toList();

    if (matches.isEmpty) {
      segments = [];
      if (notify) notifyListeners();
      return;
    }

    final oldSegments = List<QuoteTextSegment>.from(segments);

    segments = List<QuoteTextSegment>.generate(matches.length, (index) {
      final text = matches[index].group(0) ?? '';
      final highlighted =
          index < oldSegments.length ? oldSegments[index].isHighlight : false;

      return QuoteTextSegment(
        text: text,
        isHighlight: highlighted,
      );
    });

    if (notify) notifyListeners();
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
