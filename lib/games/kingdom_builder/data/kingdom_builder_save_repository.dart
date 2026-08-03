import 'package:shared_preferences/shared_preferences.dart';

import '../domain/kingdom_builder_state.dart';

class KingdomBuilderSaveRepository {
  static const _saveKey = 'kingdom_builder.save.v1';
  static const _backupKey = 'kingdom_builder.save.backup.v1';

  Future<KingdomBuilderState> load() async {
    final preferences = await SharedPreferences.getInstance();
    final primary = preferences.getString(_saveKey);
    if (primary != null && primary.isNotEmpty) {
      try {
        return KingdomBuilderState.fromJson(primary);
      } catch (_) {}
    }

    final backup = preferences.getString(_backupKey);
    if (backup != null && backup.isNotEmpty) {
      try {
        final restored = KingdomBuilderState.fromJson(backup);
        await preferences.setString(_saveKey, restored.toJson());
        return restored;
      } catch (_) {}
    }

    final initial = KingdomBuilderState.initial();
    await save(initial);
    return initial;
  }

  Future<void> save(KingdomBuilderState state) async {
    final preferences = await SharedPreferences.getInstance();
    final current = preferences.getString(_saveKey);
    if (current != null && current.isNotEmpty) {
      await preferences.setString(_backupKey, current);
    }
    await preferences.setString(_saveKey, state.toJson());
  }

  Future<void> reset() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_saveKey);
    await preferences.remove(_backupKey);
  }
}
