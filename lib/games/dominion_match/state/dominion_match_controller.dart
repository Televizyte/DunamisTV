import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/dominion_level.dart';
import '../core/dominion_scripture.dart';
import '../core/dominion_tile.dart';
import '../core/dominion_tile_type.dart';
import '../engine/dominion_board_engine.dart';
import '../services/dominion_sound_service.dart';

enum DominionGameStage { intro, playing, result }

class DominionMatchController extends ChangeNotifier {
  final DominionBoardEngine engine;
  final DominionSoundService sound;

  DominionMatchController({
    DominionBoardEngine? engine,
    DominionSoundService? sound,
  })  : engine = engine ?? DominionBoardEngine(),
        sound = sound ?? DominionSoundService() {
    board = this.engine.generateBoard(level);
    scripture = DominionScriptureBank.opening(level);
    unawaited(this.sound.init());
  }

  DominionGameStage stage = DominionGameStage.intro;
  int currentStageNumber = 1;
  DominionLevel level = DominionLevel.forStage(1);
  late List<List<DominionTile>> board;
  DominionPoint? selectedPoint;
  DominionScripture scripture = DominionScriptureBank.opening(
    DominionLevel.forStage(1),
  );

  int score = 0;
  int movesLeft = DominionLevel.forStage(1).moves;
  int combo = 0;
  int bestCombo = 0;
  int stars = 0;
  int bestUnlockedStage = 1;
  int powerActivations = 0;
  int scriptureGems = 0;
  int missionProgress = 0;
  int feedbackSeed = 0;
  int boardShakeSeed = 0;
  int boardFlashSeed = 0;

  bool lowTimeScriptureShown = false;
  bool lowTimePulse = false;
  bool isBusy = false;
  bool isVictory = false;
  bool resultDialogShown = false;

  String feedbackText = '';
  String feedbackKind = 'info';
  String status =
      'Choose a stage, match tiles, and receive scripture encouragement.';

  Timer? _timer;
  Timer? _feedbackTimer;
  Duration? timeLeft;

  double get progress => (score / level.targetScore).clamp(0.0, 1.0).toDouble();
  double get missionPercent => level.missionTarget <= 0
      ? 1
      : (missionProgress / level.missionTarget).clamp(0.0, 1.0).toDouble();
  bool get isTimed => level.isTimed;
  bool get isGameOver => stage == DominionGameStage.result;
  bool get canPlay =>
      stage == DominionGameStage.playing && !isBusy && !isGameOver;
  bool get soundEnabled => sound.enabled;
  bool get musicEnabled => sound.musicEnabled;
  bool get hapticsEnabled => sound.hapticsEnabled;

  String get objectiveSummary {
    final parts = <String>[
      '${level.targetScore} score',
      if (level.requiredCombo > 1) 'combo x${level.requiredCombo}',
      if (level.requiredPowerActivations > 0)
        '${level.requiredPowerActivations} power tile${level.requiredPowerActivations == 1 ? '' : 's'}',
      '${level.theme.meterLabel} ${missionPercent >= 1 ? 100 : (missionPercent * 100).round()}%',
    ];
    return parts.join(' • ');
  }

  bool get objectivesMet => level.objectivesMet(
        score: score,
        bestCombo: bestCombo,
        powerActivations: powerActivations,
        missionProgress: missionProgress,
      );

  void toggleSound() {
    unawaited(sound.toggleSound());
    notifyListeners();
  }

  void toggleMusic() {
    unawaited(sound.toggleMusic());
    notifyListeners();
  }

  void toggleHaptics() {
    unawaited(sound.toggleHaptics());
    notifyListeners();
  }

  void chooseStage(int stageNumber) {
    if (stage == DominionGameStage.playing) return;
    _applyLevel(DominionLevel.forStage(stageNumber));
  }

  void chooseLevel(DominionLevel nextLevel) {
    if (stage == DominionGameStage.playing) return;
    _applyLevel(nextLevel);
  }

  void startStage(DominionLevel nextLevel) {
    _timer?.cancel();
    stage = DominionGameStage.intro;
    _applyLevel(nextLevel);
    startGame();
  }

  void _applyLevel(DominionLevel nextLevel) {
    currentStageNumber = nextLevel.stage;
    level = nextLevel;
    scripture = DominionScriptureBank.opening(level);
    board = engine.generateBoard(level);
    movesLeft = level.moves;
    score = 0;
    combo = 0;
    bestCombo = 0;
    stars = 0;
    powerActivations = 0;
    scriptureGems = 0;
    missionProgress = _initialMissionProgress(nextLevel);
    lowTimeScriptureShown = false;
    lowTimePulse = false;
    timeLeft = level.timeLimit;
    feedbackText = '';
    feedbackKind = 'info';
    status = '${level.theme.missionTitle}: ${level.description}';
    notifyListeners();
  }

  int _initialMissionProgress(DominionLevel level) {
    return switch (level.missionType) {
      DominionMissionType.hazard || DominionMissionType.stronghold => 100,
      _ => 0,
    };
  }

  void startGame() {
    _timer?.cancel();
    board = engine.generateBoard(level);
    selectedPoint = null;
    score = 0;
    movesLeft = level.moves;
    combo = 0;
    bestCombo = 0;
    stars = 0;
    powerActivations = 0;
    scriptureGems = 0;
    missionProgress = _initialMissionProgress(level);
    lowTimeScriptureShown = false;
    lowTimePulse = false;
    isBusy = false;
    isVictory = false;
    resultDialogShown = false;
    timeLeft = level.timeLimit;
    scripture = DominionScriptureBank.opening(level);
    stage = DominionGameStage.playing;
    unawaited(sound.stageTransition());
    unawaited(sound.playBackgroundForLevel(
      stage: level.stage,
      worldKey: level.worldType.name,
    ));
    status = level.isTimed
        ? '${level.theme.missionTitle}: ${level.theme.missionVerb}'
        : '${level.theme.missionTitle}: reach ${level.targetScore} before your moves finish.';
    _showFeedback(
      'Stage ${level.stage}: ${level.theme.missionTitle}',
      kind: 'stage',
      flash: true,
      duration: const Duration(milliseconds: 1600),
    );
    _startTimerIfNeeded();
    notifyListeners();
  }

  void restart() => startGame();

  void backToIntro() {
    _timer?.cancel();
    unawaited(sound.stopBackground());
    selectedPoint = null;
    stage = DominionGameStage.intro;
    resultDialogShown = false;
    scripture = DominionScriptureBank.opening(level);
    feedbackText = '';
    lowTimePulse = false;
    notifyListeners();
  }

  void continueAfterResult() {
    if (isVictory) {
      final nextStage = currentStageNumber + 1;
      if (nextStage > bestUnlockedStage) bestUnlockedStage = nextStage;
      _applyLevel(DominionLevel.forStage(nextStage));
      startGame();
      return;
    }

    restart();
  }

  Future<void> tapTile(int row, int col) async {
    if (!canPlay) return;

    final point = DominionPoint(row, col);
    final current = selectedPoint;
    final tile = board[row][col];

    if (tile.type.isPower) {
      await _activatePower(point, tile.type);
      return;
    }

    if (current == null) {
      selectedPoint = point;
      status = 'Select an adjacent tile to swap.';
      unawaited(sound.select());
      notifyListeners();
      return;
    }

    if (current == point) {
      selectedPoint = null;
      status = 'Selection cleared.';
      notifyListeners();
      return;
    }

    if (!engine.isAdjacent(current, point)) {
      selectedPoint = point;
      status = 'Choose a tile beside the selected tile.';
      _showFeedback('Adjacent tiles only', kind: 'warning', shake: true);
      unawaited(sound.invalid());
      notifyListeners();
      return;
    }

    await _attemptSwap(current, point);
  }

  Future<void> _attemptSwap(DominionPoint a, DominionPoint b) async {
    isBusy = true;
    selectedPoint = null;
    board = engine.swapped(board, a, b);
    status = 'Checking match...';
    unawaited(sound.swap());
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 120));

    final matches = engine.findMatches(board);
    if (matches.isEmpty) {
      board = engine.swapped(board, a, b);
      combo = 0;
      isBusy = false;
      status = 'No match. Try another move.';
      _showFeedback('No Match', kind: 'warning', shake: true);
      unawaited(sound.invalid());
      notifyListeners();
      return;
    }

    movesLeft--;
    await _resolveBoard(matches, powerMode: false, sourcePower: null);
  }

  Future<void> _activatePower(
    DominionPoint point,
    DominionTileType type,
  ) async {
    isBusy = true;
    selectedPoint = null;
    movesLeft--;
    powerActivations++;
    combo = combo == 0 ? 1 : combo + 1;
    bestCombo = bestCombo < combo ? combo : bestCombo;

    if (type == DominionTileType.scriptureGem) {
      scriptureGems++;
      score += 180;
      scripture = DominionScriptureBank.power(level);
    }

    final label = DominionTileSpec.fromType(type).label;
    status = '$label released!';
    _showFeedback('$label!', kind: 'power', flash: true);
    unawaited(type == DominionTileType.dominion
        ? sound.dominionBurst()
        : sound.power());
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 180));
    await _resolveBoard(
      engine.powerBlast(point, type),
      powerMode: true,
      sourcePower: type,
    );
  }

  Future<void> _resolveBoard(
    Set<DominionPoint> initialMatches, {
    required bool powerMode,
    required DominionTileType? sourcePower,
  }) async {
    var matches = initialMatches;
    var guard = 0;

    while (matches.isNotEmpty && guard < 12) {
      guard++;
      combo = powerMode && guard == 1 ? combo : combo + 1;
      bestCombo = bestCombo < combo ? combo : bestCombo;

      final scoreGain = matches.length * (powerMode ? 42 : 25) * combo;
      score += scoreGain;
      _updateMissionProgress(matches.length, powerMode: powerMode);
      status = _statusForMatch(matches.length, scoreGain, sourcePower);
      _showFeedback(
        _feedbackForMatch(matches.length, scoreGain, sourcePower),
        kind: sourcePower != null
            ? 'power'
            : combo >= 3
                ? 'combo'
                : 'match',
        flash: sourcePower != null || combo >= 4,
      );
      unawaited(combo > 1 ? sound.combo() : sound.match());
      notifyListeners();

      await Future<void>.delayed(const Duration(milliseconds: 190));
      board = engine.clearAndRefill(board, matches, level);
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 190));
      matches = engine.findMatches(board);
      powerMode = false;
      sourcePower = null;
    }

    combo = 0;
    isBusy = false;
    _checkEndState();
    notifyListeners();
  }

  String _statusForMatch(
    int matchCount,
    int scoreGain,
    DominionTileType? sourcePower,
  ) {
    if (sourcePower != null) {
      return '${DominionTileSpec.fromType(sourcePower).label}! +$scoreGain points.';
    }
    if (combo >= 4) return 'Dominion combo x$combo! +$scoreGain points.';
    if (combo > 1) return 'Combo x$combo! +$scoreGain points.';
    return 'Matched $matchCount tiles. +$scoreGain points.';
  }

  String _feedbackForMatch(
    int matchCount,
    int scoreGain,
    DominionTileType? sourcePower,
  ) {
    if (sourcePower != null) {
      return '${DominionTileSpec.fromType(sourcePower).label} +$scoreGain';
    }
    if (combo >= 5) return 'Dominion Combo x$combo!';
    if (combo >= 3) return 'Combo x$combo!';
    if (matchCount >= 5) return 'Great Match!';
    if (level.missionType == DominionMissionType.rescue) {
      return 'Rescue Progress +${matchCount * 3}%';
    }
    if (level.missionType == DominionMissionType.hazard) {
      return 'Storm Reduced!';
    }
    if (level.missionType == DominionMissionType.stronghold) {
      return 'Stronghold Hit!';
    }
    return '+$scoreGain';
  }

  void _updateMissionProgress(int matchCount, {required bool powerMode}) {
    final gain = powerMode ? 18 : (matchCount * 3);
    switch (level.missionType) {
      case DominionMissionType.score:
      case DominionMissionType.rescue:
      case DominionMissionType.crownTrial:
      case DominionMissionType.survival:
        missionProgress =
            (missionProgress + gain).clamp(0, level.missionTarget).toInt();
        break;
      case DominionMissionType.hazard:
      case DominionMissionType.stronghold:
        missionProgress =
            (missionProgress - gain).clamp(0, level.missionTarget).toInt();
        break;
    }
  }

  void _checkEndState() {
    if (objectivesMet) {
      _finish(
        victory: true,
        reason: 'Stage ${level.stage} cleared. Dominion reward unlocked.',
      );
      return;
    }

    if (movesLeft <= 0) {
      _finish(
        victory: false,
        reason: 'Moves finished. Rise again and retry Stage ${level.stage}.',
      );
      return;
    }

    if (timeLeft != null && timeLeft!.inSeconds <= 0) {
      _finish(
        victory: false,
        reason: 'Time finished. Try Stage ${level.stage} again with focus.',
      );
      return;
    }

    status = _nextObjectiveText();
  }

  String _nextObjectiveText() {
    final missing = <String>[];
    if (score < level.targetScore) {
      missing.add('${level.targetScore - score} points');
    }
    if (bestCombo < level.requiredCombo) {
      missing.add('combo x${level.requiredCombo}');
    }
    if (powerActivations < level.requiredPowerActivations) {
      missing.add('${level.requiredPowerActivations - powerActivations} power');
    }
    if (missionProgress < level.missionTarget &&
        level.missionType != DominionMissionType.hazard &&
        level.missionType != DominionMissionType.stronghold) {
      missing
          .add('${level.theme.meterLabel} ${(missionPercent * 100).round()}%');
    }
    if ((level.missionType == DominionMissionType.hazard ||
            level.missionType == DominionMissionType.stronghold) &&
        missionProgress > 0) {
      missing.add('${level.theme.meterLabel} $missionProgress% left');
    }
    return missing.isEmpty
        ? 'Almost there. Finish the stage.'
        : 'Need ${missing.join(' • ')}';
  }

  void _finish({required bool victory, required String reason}) {
    _timer?.cancel();
    lowTimePulse = false;
    isVictory = victory;
    stage = DominionGameStage.result;
    stars = victory ? level.starsForScore(score) : 0;
    scripture = victory
        ? DominionScriptureBank.victory(level)
        : DominionScriptureBank.failure(level);
    status = reason;
    if (victory && currentStageNumber >= bestUnlockedStage) {
      bestUnlockedStage = currentStageNumber + 1;
    }
    _showFeedback(
      victory ? 'Stage Cleared!' : 'Rise Again',
      kind: victory ? 'victory' : 'warning',
      flash: victory,
      duration: const Duration(milliseconds: 1900),
    );
    unawaited(sound.stopBackground());
    unawaited(victory ? sound.win() : sound.fail());
    unawaited(sound.reward());
  }

  void markResultDialogShown() {
    resultDialogShown = true;
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    if (level.timeLimit == null) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = timeLeft;
      if (stage != DominionGameStage.playing || current == null) {
        timer.cancel();
        return;
      }

      timeLeft = Duration(seconds: current.inSeconds - 1);

      if (!lowTimeScriptureShown && timeLeft!.inSeconds == 20) {
        lowTimeScriptureShown = true;
        lowTimePulse = true;
        scripture = DominionScriptureBank.lowTime(level);
        status = '20 seconds left. Stay focused.';
        _showFeedback('20 Seconds Left!', kind: 'warning', flash: true);
        unawaited(sound.timerWarning());
      }

      if (level.missionType == DominionMissionType.hazard ||
          level.missionType == DominionMissionType.stronghold) {
        missionProgress =
            (missionProgress + 1).clamp(0, level.missionTarget).toInt();
      }

      if (timeLeft!.inSeconds <= 0) {
        timeLeft = Duration.zero;
        _checkEndState();
      }
      notifyListeners();
    });
  }

  void _showFeedback(
    String text, {
    String kind = 'info',
    bool shake = false,
    bool flash = false,
    Duration duration = const Duration(milliseconds: 1200),
  }) {
    feedbackText = text;
    feedbackKind = kind;
    feedbackSeed++;
    if (shake) boardShakeSeed++;
    if (flash) boardFlashSeed++;

    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(duration, () {
      if (feedbackText == text) {
        feedbackText = '';
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _feedbackTimer?.cancel();
    unawaited(sound.dispose());
    super.dispose();
  }
}
