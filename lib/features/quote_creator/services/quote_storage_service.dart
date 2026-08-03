import 'package:shared_preferences/shared_preferences.dart';

import '../models/quote_design.dart';

class QuoteStorageService {
  static const _key = 'quote_designs_v2';

  static Future<List<QuoteDesign>> getDesigns() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? <String>[];
    final designs = data.map(QuoteDesign.fromJson).toList();

    designs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return designs;
  }

  static Future<void> saveDesign(QuoteDesign design) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];

    final updated = <String>[
      design.toJson(),
      ...list.where((raw) {
        final existing = QuoteDesign.fromJson(raw);
        return existing.id != design.id;
      }),
    ];

    await prefs.setStringList(_key, updated);
  }

  static Future<void> deleteDesign(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];

    final updated = list.where((raw) {
      final existing = QuoteDesign.fromJson(raw);
      return existing.id != id;
    }).toList();

    await prefs.setStringList(_key, updated);
  }
}
