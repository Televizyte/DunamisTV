import 'dart:convert';

class QuoteDesign {
  final String id;
  final String quote;
  final String author;
  final int timestamp;
  final Map<String, dynamic> designData;

  QuoteDesign({
    required this.id,
    required this.quote,
    required this.author,
    required this.timestamp,
    required this.designData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quote': quote,
      'author': author,
      'timestamp': timestamp,
      'designData': designData,
    };
  }

  factory QuoteDesign.fromMap(Map<String, dynamic> map) {
    return QuoteDesign(
      id: (map['id'] ?? '').toString(),
      quote: (map['quote'] ?? '').toString(),
      author: (map['author'] ?? '').toString(),
      timestamp: map['timestamp'] is int
          ? map['timestamp'] as int
          : int.tryParse('${map['timestamp']}') ?? 0,
      designData: map['designData'] is Map
          ? Map<String, dynamic>.from(map['designData'] as Map)
          : <String, dynamic>{},
    );
  }

  String toJson() => jsonEncode(toMap());

  factory QuoteDesign.fromJson(String source) =>
      QuoteDesign.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
