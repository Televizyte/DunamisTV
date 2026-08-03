import 'package:flutter/foundation.dart';

/// Gameplay object anchored to a real world-distance position.
///
/// Objects now carry a clear faith-game identity. Collectibles show what they
/// add, while obstacles show their danger/penalty so the player can read the
/// track quickly without guessing.
enum RaceTrackObjectType {
  light,
  wordScroll,
  cross,
  crown,
  shield,
  fearWall,
  doubtBlock,
  distractionGate,
  burdenStone,
  temptationTrap,
}

@immutable
class RaceTrackObject {
  final int id;
  final RaceTrackObjectType type;
  final int lane;
  final double distanceMeters;
  final int value;

  const RaceTrackObject({
    required this.id,
    required this.type,
    required this.lane,
    required this.distanceMeters,
    this.value = 1,
  });

  bool get isCollectible =>
      type == RaceTrackObjectType.light ||
      type == RaceTrackObjectType.wordScroll ||
      type == RaceTrackObjectType.cross ||
      type == RaceTrackObjectType.crown ||
      type == RaceTrackObjectType.shield;

  bool get isObstacle => !isCollectible;

  bool get requiresJump =>
      type == RaceTrackObjectType.fearWall ||
      type == RaceTrackObjectType.temptationTrap;

  bool get requiresSlide => type == RaceTrackObjectType.burdenStone;

  bool get requiresMove =>
      type == RaceTrackObjectType.doubtBlock ||
      type == RaceTrackObjectType.distractionGate;

  String get label {
    switch (type) {
      case RaceTrackObjectType.light:
        return '+LIGHT';
      case RaceTrackObjectType.wordScroll:
        return '+WORD';
      case RaceTrackObjectType.cross:
        return '+GRACE';
      case RaceTrackObjectType.crown:
        return '+CROWN';
      case RaceTrackObjectType.shield:
        return '+SHIELD';
      case RaceTrackObjectType.fearWall:
      case RaceTrackObjectType.doubtBlock:
      case RaceTrackObjectType.distractionGate:
      case RaceTrackObjectType.burdenStone:
      case RaceTrackObjectType.temptationTrap:
        return '-1 LIFE';
    }
  }

  String get title {
    switch (type) {
      case RaceTrackObjectType.light:
        return 'LIGHT';
      case RaceTrackObjectType.wordScroll:
        return 'WORD';
      case RaceTrackObjectType.cross:
        return 'CROSS';
      case RaceTrackObjectType.crown:
        return 'CROWN';
      case RaceTrackObjectType.shield:
        return 'SHIELD';
      case RaceTrackObjectType.fearWall:
        return 'FEAR';
      case RaceTrackObjectType.doubtBlock:
        return 'DOUBT';
      case RaceTrackObjectType.distractionGate:
        return 'DISTRACTION';
      case RaceTrackObjectType.burdenStone:
        return 'BURDEN';
      case RaceTrackObjectType.temptationTrap:
        return 'TEMPTATION';
    }
  }

  String get actionHint {
    if (isCollectible) return 'Collect';
    if (requiresJump) return 'Jump';
    if (requiresSlide) return 'Slide';
    return 'Move';
  }

  String get feedbackName {
    switch (type) {
      case RaceTrackObjectType.light:
        return 'Light';
      case RaceTrackObjectType.wordScroll:
        return 'Word';
      case RaceTrackObjectType.cross:
        return 'Grace';
      case RaceTrackObjectType.crown:
        return 'Crown';
      case RaceTrackObjectType.shield:
        return 'Shield';
      case RaceTrackObjectType.fearWall:
        return 'Fear Wall';
      case RaceTrackObjectType.doubtBlock:
        return 'Doubt Block';
      case RaceTrackObjectType.distractionGate:
        return 'Distraction Gate';
      case RaceTrackObjectType.burdenStone:
        return 'Burden Stone';
      case RaceTrackObjectType.temptationTrap:
        return 'Temptation Trap';
    }
  }
}
