import 'package:flutter/foundation.dart';

@immutable
class RaceRunResult {
  final int score;
  final double distanceMeters;
  final int lightCollected;
  final int crownsCollected;
  final int levelNumber;
  final bool completedLevel;
  final int livesRemaining;
  final DateTime endedAt;

  const RaceRunResult({
    required this.score,
    required this.distanceMeters,
    required this.lightCollected,
    required this.crownsCollected,
    this.levelNumber = 1,
    this.completedLevel = false,
    this.livesRemaining = 0,
    required this.endedAt,
  });

  factory RaceRunResult.empty() => RaceRunResult(
        score: 0,
        distanceMeters: 0,
        lightCollected: 0,
        crownsCollected: 0,
        levelNumber: 1,
        completedLevel: false,
        livesRemaining: 0,
        endedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  Map<String, Object?> toJson() => {
        'score': score,
        'distance_meters': distanceMeters,
        'light_collected': lightCollected,
        'crowns_collected': crownsCollected,
        'level_number': levelNumber,
        'completed_level': completedLevel,
        'lives_remaining': livesRemaining,
        'ended_at': endedAt.toIso8601String(),
      };

  static RaceRunResult fromJson(Map<String, Object?> json) {
    return RaceRunResult(
      score: _readInt(json['score']),
      distanceMeters: _readDouble(json['distance_meters']),
      lightCollected: _readInt(json['light_collected']),
      crownsCollected: _readInt(json['crowns_collected']),
      levelNumber: _readInt(json['level_number'], fallback: 1),
      completedLevel: _readBool(json['completed_level']),
      livesRemaining: _readInt(json['lives_remaining']),
      endedAt: DateTime.tryParse(json['ended_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _readDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _readBool(Object? value) {
    if (value is bool) return value;
    final raw = value?.toString().toLowerCase();
    return raw == 'true' || raw == '1' || raw == 'yes';
  }
}
