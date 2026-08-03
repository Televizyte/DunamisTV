import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/race_run_result.dart';

class RaceStorageService {
  static const _bestScoreKey = 'race_of_faith_best_score';
  static const _bestDistanceKey = 'race_of_faith_best_distance';
  static const _lastRunKey = 'race_of_faith_last_run';
  static const _musicKey = 'race_of_faith_music_enabled';
  static const _effectsKey = 'race_of_faith_effects_enabled';
  static const _unlockedLevelKey = 'race_of_faith_unlocked_level';
  static const _totalLightKey = 'race_of_faith_total_light';
  static const _totalCrownsKey = 'race_of_faith_total_crowns';
  static const _lastSelectedLevelKey = 'race_of_faith_last_selected_level';
  static const _completedLevelsKey = 'race_of_faith_completed_levels';
  static const _bestScoreByLevelKey = 'race_of_faith_best_score_by_level';

  Future<int> readBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestScoreKey) ?? 0;
  }

  Future<double> readBestDistance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_bestDistanceKey) ?? 0;
  }

  Future<int> readUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_unlockedLevelKey) ?? 1;
    return value < 1 ? 1 : value;
  }

  Future<void> saveUnlockedLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_unlockedLevelKey) ?? 1;
    if (level > current) {
      await prefs.setInt(_unlockedLevelKey, level);
    }
  }

  Future<int> readLastSelectedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastSelectedLevelKey) ?? 1;
  }

  Future<void> saveLastSelectedLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSelectedLevelKey, level < 1 ? 1 : level);
  }

  Future<int> readTotalLight() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalLightKey) ?? 0;
  }

  Future<int> readTotalCrowns() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalCrownsKey) ?? 0;
  }

  Future<Set<int>> readCompletedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_completedLevelsKey) ?? <String>[];
    return values.map(int.tryParse).whereType<int>().toSet();
  }

  Future<Map<int, int>> readBestScoreByLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_bestScoreByLevelKey);
    if (raw == null || raw.trim().isEmpty) return <int, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map<int, int>((key, value) {
          final parsedKey = int.tryParse(key.toString()) ?? 0;
          final parsedValue = value is num
              ? value.toInt()
              : int.tryParse(value.toString()) ?? 0;
          return MapEntry(parsedKey, parsedValue);
        })
          ..removeWhere((key, value) => key <= 0);
      }
    } catch (_) {}
    return <int, int>{};
  }

  Future<RaceRunResult?> readLastRun() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastRunKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return RaceRunResult.fromJson(decoded.cast<String, Object?>());
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveRunResult(RaceRunResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final currentBestScore = prefs.getInt(_bestScoreKey) ?? 0;
    final currentBestDistance = prefs.getDouble(_bestDistanceKey) ?? 0;
    final totalLight = prefs.getInt(_totalLightKey) ?? 0;
    final totalCrowns = prefs.getInt(_totalCrownsKey) ?? 0;
    final completed = prefs.getStringList(_completedLevelsKey) ?? <String>[];
    final bestByLevel = await readBestScoreByLevel();

    if (result.score > currentBestScore) {
      await prefs.setInt(_bestScoreKey, result.score);
    }
    if (result.distanceMeters > currentBestDistance) {
      await prefs.setDouble(_bestDistanceKey, result.distanceMeters);
    }
    await prefs.setInt(_totalLightKey, totalLight + result.lightCollected);
    await prefs.setInt(_totalCrownsKey, totalCrowns + result.crownsCollected);
    await prefs.setString(_lastRunKey, jsonEncode(result.toJson()));
    await prefs.setInt(_lastSelectedLevelKey, result.levelNumber);

    final currentLevelBest = bestByLevel[result.levelNumber] ?? 0;
    if (result.score > currentLevelBest) {
      bestByLevel[result.levelNumber] = result.score;
      await prefs.setString(
          _bestScoreByLevelKey,
          jsonEncode(
            bestByLevel.map((key, value) => MapEntry(key.toString(), value)),
          ));
    }

    if (result.completedLevel) {
      final levelText = result.levelNumber.toString();
      if (!completed.contains(levelText)) {
        completed.add(levelText);
        completed.sort(
            (a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
        await prefs.setStringList(_completedLevelsKey, completed);
      }
    }
  }

  Future<bool> readMusicEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_musicKey) ?? true;
  }

  Future<bool> readEffectsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_effectsKey) ?? true;
  }

  Future<void> saveMusicEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicKey, value);
  }

  Future<void> saveEffectsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_effectsKey, value);
  }
}
