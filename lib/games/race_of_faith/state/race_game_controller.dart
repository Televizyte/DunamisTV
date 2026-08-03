import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../config/race_game_config.dart';
import '../models/race_run_result.dart';
import '../models/race_track_object.dart';
import '../services/race_sound_service.dart';
import '../services/race_storage_service.dart';

enum RaceScreenMode { home, ready, running, paused, gameOver, reward }

enum RaceRunnerAction { running, jumping, sliding, hit }

class RaceGameController extends ChangeNotifier {
  RaceGameController({
    RaceStorageService? storage,
    RaceSoundService? sound,
    RaceGameConfig config = const RaceGameConfig(),
  })  : _storage = storage ?? RaceStorageService(),
        _sound = sound ?? RaceSoundService(),
        _config = config;

  static const int minLane = 0;
  static const int maxLane = 2;
  static const int centerLane = 1;
  static const int maxLives = 3;
  static const double _tickSeconds = 1 / 30;
  static const double _paceDivisor = 8.2;

  final RaceStorageService _storage;
  final RaceSoundService _sound;
  final RaceGameConfig _config;
  Timer? _timer;

  RaceScreenMode mode = RaceScreenMode.home;
  RaceRunnerAction runnerAction = RaceRunnerAction.running;

  bool musicEnabled = true;
  bool effectsEnabled = true;
  int bestScore = 0;
  double bestDistance = 0;
  int unlockedLevel = 1;
  int selectedLevel = 1;
  int totalLight = 0;
  int totalCrowns = 0;
  Set<int> completedLevels = <int>{};
  Map<int, int> bestScoreByLevel = <int, int>{};
  RaceRunResult? lastRun;

  int score = 0;
  double distanceMeters = 0;
  int lightCollected = 0;
  int crownsCollected = 0;
  int lives = maxLives;
  int combo = 0;

  int currentLane = centerLane;
  int targetLane = centerLane;
  double lanePosition = centerLane.toDouble();
  double worldOffset = 0;
  double speed = 210;
  double jumpProgress = 0;
  double slideProgress = 0;
  double hitProgress = 0;
  double gaitPhase = 0;
  double laneLean = 0;
  double collectPulse = 0;
  double damagePulse = 0;
  double feedbackPulse = 0;
  String feedbackText = '';
  bool feedbackIsBad = false;

  final List<RaceTrackObject> _trackObjects = <RaceTrackObject>[];
  final Set<int> _resolvedObjectIds = <int>{};

  List<RaceTrackObject> get trackObjects => List<RaceTrackObject>.unmodifiable(
        _trackObjects
            .where((object) => !_resolvedObjectIds.contains(object.id)),
      );

  bool get isRunning => mode == RaceScreenMode.running;
  bool get isPaused => mode == RaceScreenMode.paused;
  bool get isJumping => runnerAction == RaceRunnerAction.jumping;
  bool get isSliding => runnerAction == RaceRunnerAction.sliding;
  bool get isHit => runnerAction == RaceRunnerAction.hit;

  List<RaceLevelConfig> get levels =>
      RaceLevelConfig.generateLevels(_config.maxGeneratedLevel);

  int get maxAvailableLevel => levels.length;

  RaceLevelConfig get currentLevel {
    return levels.firstWhere(
      (level) => level.number == selectedLevel,
      orElse: () => levels.first,
    );
  }

  bool isLevelUnlocked(int level) => level <= unlockedLevel;
  bool isLevelCompleted(int level) => completedLevels.contains(level);
  int bestScoreForLevel(int level) => bestScoreByLevel[level] ?? 0;

  double get levelProgress =>
      (distanceMeters / currentLevel.targetMeters).clamp(0.0, 1.0);

  double get remainingMeters =>
      math.max(0, currentLevel.targetMeters - distanceMeters);

  double get laneAlignment => ((lanePosition - 1) * 0.72).clamp(-0.72, 0.72);

  double get runnerLift {
    if (!isJumping) return 0;
    final arc = math.sin(jumpProgress * math.pi);
    return -102 * arc;
  }

  double get slideSquash {
    if (!isSliding) return 0;
    final half =
        slideProgress <= 0.5 ? slideProgress * 2 : (1 - slideProgress) * 2;
    return half.clamp(0.0, 1.0);
  }

  double get laneMoveAmount =>
      (targetLane - lanePosition).abs().clamp(0.0, 1.0);

  String get speedStageLabel {
    final stage = currentLevel.stage.environmentName;
    if (levelProgress < 0.25) return 'Level $selectedLevel · $stage Warm-up';
    if (levelProgress < 0.55) return 'Level $selectedLevel · $stage Focus';
    if (levelProgress < 0.85) return 'Level $selectedLevel · $stage Race';
    return 'Level $selectedLevel · Finish Strong';
  }

  int get speedLevel {
    if (levelProgress < 0.25) return 1;
    if (levelProgress < 0.55) return 2;
    if (levelProgress < 0.85) return 3;
    return 4;
  }

  Future<void> init() async {
    musicEnabled = await _storage.readMusicEnabled();
    effectsEnabled = await _storage.readEffectsEnabled();
    bestScore = await _storage.readBestScore();
    bestDistance = await _storage.readBestDistance();
    totalLight = await _storage.readTotalLight();
    totalCrowns = await _storage.readTotalCrowns();
    completedLevels = await _storage.readCompletedLevels();
    bestScoreByLevel = await _storage.readBestScoreByLevel();
    unlockedLevel = (await _storage.readUnlockedLevel())
        .clamp(1, maxAvailableLevel)
        .toInt();
    selectedLevel = (await _storage.readLastSelectedLevel())
        .clamp(1, unlockedLevel)
        .toInt();
    lastRun = await _storage.readLastRun();
    unawaited(_sound.apply(music: musicEnabled, effects: effectsEnabled));
    notifyListeners();
  }

  Future<void> toggleMusic() async {
    musicEnabled = !musicEnabled;
    await _storage.saveMusicEnabled(musicEnabled);
    await _sound.apply(music: musicEnabled, effects: effectsEnabled);
    if (musicEnabled && isRunning) {
      await _sound.startMusic();
    } else {
      await _sound.stopMusic();
    }
    notifyListeners();
  }

  Future<void> toggleEffects() async {
    effectsEnabled = !effectsEnabled;
    await _storage.saveEffectsEnabled(effectsEnabled);
    await _sound.apply(music: musicEnabled, effects: effectsEnabled);
    notifyListeners();
  }

  Future<void> selectLevel(int level) async {
    if (!isLevelUnlocked(level)) return;
    selectedLevel = level.clamp(1, maxAvailableLevel).toInt();
    await _storage.saveLastSelectedLevel(selectedLevel);
    notifyListeners();
  }

  Future<void> startRun({int? level}) async {
    if (level != null) {
      if (!isLevelUnlocked(level)) return;
      selectedLevel = level.clamp(1, maxAvailableLevel).toInt();
      await _storage.saveLastSelectedLevel(selectedLevel);
    }
    score = 0;
    distanceMeters = 0;
    lightCollected = 0;
    crownsCollected = 0;
    lives = maxLives;
    combo = 0;
    currentLane = centerLane;
    targetLane = centerLane;
    lanePosition = centerLane.toDouble();
    runnerAction = RaceRunnerAction.running;
    worldOffset = 0;
    speed = currentLevel.baseSpeed;
    jumpProgress = 0;
    slideProgress = 0;
    hitProgress = 0;
    gaitPhase = 0;
    laneLean = 0;
    collectPulse = 0;
    damagePulse = 0;
    feedbackPulse = 0;
    feedbackText = '';
    feedbackIsBad = false;
    _resolvedObjectIds.clear();
    _buildLevelRoute();
    mode = RaceScreenMode.running;
    notifyListeners();
    await _sound.startRun();
    await _sound.startMusic();
    _startLoop();
  }

  Future<void> pause() async {
    if (!isRunning) return;
    _timer?.cancel();
    mode = RaceScreenMode.paused;
    await _sound.stopMusic();
    notifyListeners();
  }

  Future<void> resume() async {
    if (mode != RaceScreenMode.paused) return;
    mode = RaceScreenMode.running;
    notifyListeners();
    await _sound.startMusic();
    _startLoop();
  }

  Future<void> endRun() async {
    await _finishRun(completed: false);
  }

  Future<void> retryLevel() async {
    await startRun(level: selectedLevel);
  }

  Future<void> continueNextLevel() async {
    final next = math.min(maxAvailableLevel, selectedLevel + 1);
    if (!isLevelUnlocked(next)) {
      await _storage.saveUnlockedLevel(next);
      unlockedLevel = math.max(unlockedLevel, next);
    }
    await startRun(level: next);
  }

  Future<void> goHome() async {
    _timer?.cancel();
    await _sound.stopMusic();
    mode = RaceScreenMode.home;
    notifyListeners();
  }

  Future<void> moveLeft() async => _moveToLane(targetLane - 1);

  Future<void> moveRight() async => _moveToLane(targetLane + 1);

  Future<void> moveToLane(int lane) async => _moveToLane(lane);

  Future<void> jump() async {
    if (!isRunning || isJumping || isSliding || isHit) return;
    runnerAction = RaceRunnerAction.jumping;
    jumpProgress = 0;
    await _sound.jump();
    notifyListeners();
  }

  Future<void> slide() async {
    if (!isRunning || isJumping || isSliding || isHit) return;
    runnerAction = RaceRunnerAction.sliding;
    slideProgress = 0;
    await _sound.slide();
    notifyListeners();
  }

  Future<void> _moveToLane(int lane) async {
    if (!isRunning) return;
    final nextLane = lane.clamp(minLane, maxLane);
    if (nextLane == targetLane) return;
    targetLane = nextLane;
    await _sound.move();
    notifyListeners();
  }

  void _startLoop() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) => _tick());
  }

  void _tick() {
    if (!isRunning) return;

    final progressBoost =
        levelProgress * (currentLevel.maxSpeed - currentLevel.baseSpeed);
    final stageBoost = 1.0 + (speedLevel - 1) * 0.12;
    speed = math.min(
      currentLevel.maxSpeed,
      (currentLevel.baseSpeed + progressBoost) * stageBoost,
    );
    final paceMetersPerSecond = speed / _paceDivisor;
    distanceMeters += paceMetersPerSecond * _tickSeconds;
    worldOffset = distanceMeters;
    gaitPhase = (gaitPhase + _tickSeconds * (8.2 + speed / 58)) % (math.pi * 2);
    score += math.max(2, (speed / 88).round());

    _updateLane();
    _updateAction();
    _updateWorldTrackObjects();
    _updateFeedback();

    if (distanceMeters >= currentLevel.targetMeters) {
      unawaited(_finishRun(completed: true));
      return;
    }

    notifyListeners();
  }

  void _updateLane() {
    final laneDelta = targetLane - lanePosition;
    final maxStep = 7.6 * _tickSeconds;
    if (laneDelta.abs() <= maxStep) {
      lanePosition = targetLane.toDouble();
      currentLane = targetLane;
    } else {
      lanePosition += laneDelta.sign * maxStep;
      currentLane = lanePosition.round().clamp(minLane, maxLane);
    }
    laneLean = (laneDelta * 0.22).clamp(-0.22, 0.22);
  }

  void _updateAction() {
    if (isJumping) {
      jumpProgress += _tickSeconds / 0.66;
      if (jumpProgress >= 1) {
        jumpProgress = 0;
        runnerAction = RaceRunnerAction.running;
      }
    } else if (isSliding) {
      slideProgress += _tickSeconds / 0.50;
      if (slideProgress >= 1) {
        slideProgress = 0;
        runnerAction = RaceRunnerAction.running;
      }
    } else if (isHit) {
      hitProgress += _tickSeconds / 0.40;
      if (hitProgress >= 1) {
        hitProgress = 0;
        runnerAction = RaceRunnerAction.running;
      }
    }
  }

  void _buildLevelRoute() {
    _trackObjects.clear();
    final level = currentLevel;
    final stage = level.stage;
    final localLevel = ((level.number - 1) % 5) + 1;
    final difficulty = (stage.index * 0.62) + (localLevel * 0.18);
    final spacing = (42.0 / stage.densityMultiplier - difficulty * 1.8)
        .clamp(16.0, 42.0)
        .toDouble();
    var distance = 48.0;
    var id = 1;

    while (distance < level.targetMeters - 26) {
      final step = id;
      final lane = _laneForObject(step, level.number, stage.index);
      final type = _typeForObject(step, level.number, stage.index, distance);
      _trackObjects.add(RaceTrackObject(
        id: id,
        type: type,
        lane: lane,
        distanceMeters: distance,
        value: _valueForObject(type, stage.index),
      ));

      // Add a second safe collectible in later stages to make the route feel
      // richer without making the obstacle lane unreadable.
      if (stage.index >= 2 && step % 5 == 0) {
        final bonusLane = (lane + 1 + stage.index) % 3;
        _trackObjects.add(RaceTrackObject(
          id: id + 10000,
          type: stage.index >= 6
              ? RaceTrackObjectType.crown
              : RaceTrackObjectType.light,
          lane: bonusLane,
          distanceMeters: distance + 10.0,
          value: stage.index >= 6 ? 2 : 1,
        ));
      }

      final wave = ((step + stage.index) % 4) * 4.0;
      distance += spacing + wave;
      id += 1;
    }
  }

  int _valueForObject(RaceTrackObjectType type, int stageIndex) {
    switch (type) {
      case RaceTrackObjectType.crown:
        return stageIndex >= 6 ? 2 : 1;
      case RaceTrackObjectType.wordScroll:
        return 2;
      case RaceTrackObjectType.cross:
      case RaceTrackObjectType.shield:
        return 1;
      case RaceTrackObjectType.light:
        return 1;
      case RaceTrackObjectType.fearWall:
      case RaceTrackObjectType.doubtBlock:
      case RaceTrackObjectType.distractionGate:
      case RaceTrackObjectType.burdenStone:
      case RaceTrackObjectType.temptationTrap:
        return 1;
    }
  }

  int _laneForObject(int step, int level, int stageIndex) {
    // Deterministic pattern: stable per level, no random jumping/reloading.
    return ((step * 2 + level + stageIndex) % 3)
        .clamp(minLane, maxLane)
        .toInt();
  }

  RaceTrackObjectType _typeForObject(
    int step,
    int level,
    int stageIndex,
    double distance,
  ) {
    if (distance < 88) return RaceTrackObjectType.light;
    final pattern = (step + level + stageIndex * 2) % 14;

    if (stageIndex <= 0) {
      if (pattern == 0 || pattern == 6) return RaceTrackObjectType.fearWall;
      if (pattern == 3) return RaceTrackObjectType.doubtBlock;
      if (pattern == 8) return RaceTrackObjectType.wordScroll;
      return RaceTrackObjectType.light;
    }

    if (stageIndex == 1) {
      if (pattern == 0 || pattern == 7) return RaceTrackObjectType.doubtBlock;
      if (pattern == 3) return RaceTrackObjectType.fearWall;
      if (pattern == 5) return RaceTrackObjectType.cross;
      if (pattern == 9) return RaceTrackObjectType.wordScroll;
      return RaceTrackObjectType.light;
    }

    if (stageIndex == 2) {
      if (pattern == 0 || pattern == 5) return RaceTrackObjectType.fearWall;
      if (pattern == 2) return RaceTrackObjectType.burdenStone;
      if (pattern == 7) return RaceTrackObjectType.cross;
      if (pattern == 10) return RaceTrackObjectType.wordScroll;
      return RaceTrackObjectType.light;
    }

    if (stageIndex == 3) {
      if (pattern == 0 || pattern == 6)
        return RaceTrackObjectType.distractionGate;
      if (pattern == 2) return RaceTrackObjectType.doubtBlock;
      if (pattern == 4) return RaceTrackObjectType.crown;
      if (pattern == 9) return RaceTrackObjectType.wordScroll;
      return RaceTrackObjectType.light;
    }

    if (stageIndex == 4 || stageIndex == 5) {
      if (pattern == 0 || pattern == 8) return RaceTrackObjectType.burdenStone;
      if (pattern == 2) return RaceTrackObjectType.fearWall;
      if (pattern == 4) return RaceTrackObjectType.temptationTrap;
      if (pattern == 6) return RaceTrackObjectType.cross;
      if (pattern == 11) return RaceTrackObjectType.crown;
      return RaceTrackObjectType.light;
    }

    if (pattern == 0 || pattern == 5) return RaceTrackObjectType.temptationTrap;
    if (pattern == 2) return RaceTrackObjectType.fearWall;
    if (pattern == 4) return RaceTrackObjectType.distractionGate;
    if (pattern == 7) return RaceTrackObjectType.burdenStone;
    if (pattern == 9) return RaceTrackObjectType.shield;
    if (pattern == 11) return RaceTrackObjectType.crown;
    if (pattern == 12) return RaceTrackObjectType.cross;
    return RaceTrackObjectType.light;
  }

  void _updateWorldTrackObjects() {
    const collectWindow = 9.0;
    const obstacleWindow = 7.5;
    const missBehind = 18.0;

    for (final object in _trackObjects) {
      if (_resolvedObjectIds.contains(object.id)) continue;

      final forward = object.distanceMeters - distanceMeters;
      if (forward > collectWindow) continue;

      if (object.isCollectible) {
        if (forward.abs() <= collectWindow && currentLane == object.lane) {
          _resolvedObjectIds.add(object.id);
          _collectObject(object);
        } else if (forward < -missBehind) {
          _resolvedObjectIds.add(object.id);
        }
        continue;
      }

      if (forward.abs() <= obstacleWindow && currentLane == object.lane) {
        final escaped = object.requiresJump
            ? isJumping
            : object.requiresSlide
                ? isSliding
                : false;
        _resolvedObjectIds.add(object.id);
        if (escaped) {
          score += object.requiresJump ? 38 : 34;
          _showFeedback(
              '${object.actionHint} Clear +${object.requiresJump ? 38 : 34}',
              isBad: false);
        } else {
          _loseLife(object.feedbackName);
        }
      } else if (forward < -missBehind) {
        _resolvedObjectIds.add(object.id);
      }
    }
  }

  void _collectObject(RaceTrackObject object) {
    switch (object.type) {
      case RaceTrackObjectType.light:
        lightCollected += object.value;
        score += 22 * object.value;
        _showFeedback('+${object.value} Light', isBad: false);
        break;
      case RaceTrackObjectType.wordScroll:
        score += 42 * object.value;
        combo += 1;
        _showFeedback('+${object.value} Word', isBad: false);
        break;
      case RaceTrackObjectType.cross:
        lightCollected += object.value;
        score += 36 * object.value;
        _showFeedback('+Grace · Cross', isBad: false);
        break;
      case RaceTrackObjectType.crown:
        crownsCollected += object.value;
        score += 58 * object.value;
        _showFeedback('+${object.value} Crown', isBad: false);
        break;
      case RaceTrackObjectType.shield:
        score += 70 * object.value;
        if (lives < maxLives) lives += 1;
        _showFeedback(lives < maxLives ? '+Shield' : '+Shield Ready',
            isBad: false);
        break;
      case RaceTrackObjectType.fearWall:
      case RaceTrackObjectType.doubtBlock:
      case RaceTrackObjectType.distractionGate:
      case RaceTrackObjectType.burdenStone:
      case RaceTrackObjectType.temptationTrap:
        break;
    }
    combo += 1;
    collectPulse = 1;
    unawaited(_sound.collect());
  }

  void _updateFeedback() {
    collectPulse = math.max(0, collectPulse - _tickSeconds * 2.8);
    damagePulse = math.max(0, damagePulse - _tickSeconds * 2.4);
    feedbackPulse = math.max(0, feedbackPulse - _tickSeconds * 1.9);
  }

  void _showFeedback(String text, {required bool isBad}) {
    feedbackText = text;
    feedbackIsBad = isBad;
    feedbackPulse = 1;
  }

  void _loseLife(String reason) {
    if (!isRunning || damagePulse > 0.12) return;
    lives = math.max(0, lives - 1);
    combo = 0;
    damagePulse = 1;
    runnerAction = RaceRunnerAction.hit;
    hitProgress = 0;
    _showFeedback('-1 Life · $reason', isBad: true);
    unawaited(_sound.hit());
    if (lives <= 0) {
      unawaited(_finishRun(completed: false));
    }
  }

  Future<void> _finishRun({required bool completed}) async {
    _timer?.cancel();
    await _sound.stopMusic();
    final result = RaceRunResult(
      score: score,
      distanceMeters: distanceMeters,
      lightCollected: lightCollected,
      crownsCollected: crownsCollected,
      levelNumber: selectedLevel,
      completedLevel: completed,
      livesRemaining: lives,
      endedAt: DateTime.now(),
    );
    await _storage.saveRunResult(result);
    if (completed) {
      final next = math.min(maxAvailableLevel, selectedLevel + 1);
      await _storage.saveUnlockedLevel(next);
      unlockedLevel = math.max(unlockedLevel, next);
      await _sound.reward();
    } else {
      await _sound.gameOver();
    }
    bestScore = await _storage.readBestScore();
    bestDistance = await _storage.readBestDistance();
    totalLight = await _storage.readTotalLight();
    totalCrowns = await _storage.readTotalCrowns();
    completedLevels = await _storage.readCompletedLevels();
    bestScoreByLevel = await _storage.readBestScoreByLevel();
    unlockedLevel = (await _storage.readUnlockedLevel())
        .clamp(1, maxAvailableLevel)
        .toInt();
    lastRun = result;
    mode = completed ? RaceScreenMode.reward : RaceScreenMode.gameOver;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sound.stopMusic();
    _sound.dispose();
    super.dispose();
  }
}
