import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Modular Race of Faith audio service.
///
/// The game engine calls this service only through intent-based methods
/// (move/jump/collect/hit/etc). That keeps the runner reusable for other apps:
/// each app can later swap the assets or sound profile without changing the
/// gameplay controller.
class RaceSoundService {
  static const String _base = 'audio/race_of_faith';

  final AudioPlayer _musicPlayer = AudioPlayer(playerId: 'race_faith_music');
  final AudioPlayer _effectPlayer = AudioPlayer(playerId: 'race_faith_effects');
  final AudioPlayer _effectPlayerAlt =
      AudioPlayer(playerId: 'race_faith_effects_alt');

  bool musicEnabled = true;
  bool effectsEnabled = true;
  bool _musicReady = false;
  bool _useAlt = false;

  Future<void> apply({required bool music, required bool effects}) async {
    musicEnabled = music;
    effectsEnabled = effects;
    if (!musicEnabled) {
      await stopMusic();
    }
  }

  Future<void> _ensureMusicReady() async {
    if (_musicReady) return;
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(0.28);
    _musicReady = true;
  }

  Future<void> startMusic() async {
    if (!musicEnabled) return;
    try {
      await _ensureMusicReady();
      await _musicPlayer.play(AssetSource('$_base/race_adventure_loop.wav'));
    } catch (_) {
      // Audio may be blocked on some browsers until a user gesture is fully
      // accepted. The game should keep running even if audio is unavailable.
    }
  }

  Future<void> stopMusic() async {
    try {
      await _musicPlayer.stop();
    } catch (_) {}
  }

  Future<void> move() => _playEffect(
        'race_move.wav',
        fallback: () => HapticFeedback.selectionClick(),
        volume: 0.44,
      );

  Future<void> jump() => _playEffect(
        'race_jump.wav',
        fallback: () => HapticFeedback.lightImpact(),
        volume: 0.52,
      );

  Future<void> slide() => _playEffect(
        'race_slide.wav',
        fallback: () => HapticFeedback.selectionClick(),
        volume: 0.48,
      );

  Future<void> collect() => _playEffect(
        'race_collect.wav',
        fallback: () => HapticFeedback.selectionClick(),
        volume: 0.55,
      );

  Future<void> startRun() => _playEffect(
        'race_start.wav',
        fallback: () => HapticFeedback.mediumImpact(),
        volume: 0.50,
      );

  Future<void> hit() => _playEffect(
        'race_hit.wav',
        fallback: () => HapticFeedback.heavyImpact(),
        volume: 0.46,
      );

  Future<void> reward() => _playEffect(
        'race_level_complete.wav',
        fallback: () => HapticFeedback.lightImpact(),
        volume: 0.68,
      );

  Future<void> gameOver() => _playEffect(
        'race_game_over.wav',
        fallback: () => HapticFeedback.mediumImpact(),
        volume: 0.44,
      );

  Future<void> _playEffect(
    String fileName, {
    required FutureOr<void> Function() fallback,
    double volume = 0.5,
  }) async {
    if (!effectsEnabled) return;
    try {
      final player = _useAlt ? _effectPlayerAlt : _effectPlayer;
      _useAlt = !_useAlt;
      await player.stop();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(volume);
      await player.play(AssetSource('$_base/$fileName'));
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.click);
        await fallback();
      } catch (_) {}
    }
  }

  void dispose() {
    unawaited(_musicPlayer.dispose());
    unawaited(_effectPlayer.dispose());
    unawaited(_effectPlayerAlt.dispose());
  }
}
