import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DominionSoundService {
  static const String _basePath = 'audio/dominion_match';
  static const String _soundPrefKey = 'dominion_match_sound_enabled';
  static const String _musicPrefKey = 'dominion_match_music_enabled';
  static const String _hapticsPrefKey = 'dominion_match_haptics_enabled';

  final AudioPlayer _musicPlayer = AudioPlayer(playerId: 'dominion_bg_music');

  bool enabled = true;
  bool musicEnabled = true;
  bool hapticsEnabled = true;
  bool _ready = false;
  String _activeMusic = '';

  Future<void> init() async {
    if (_ready) return;
    _ready = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool(_soundPrefKey) ?? true;
      musicEnabled = prefs.getBool(_musicPrefKey) ?? true;
      hapticsEnabled = prefs.getBool(_hapticsPrefKey) ?? true;
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(0.18);
    } catch (_) {
      // Audio preferences can fail silently on unsupported platforms.
    }
  }

  Future<void> select() => _playEffect('select.wav', SelectionClickType.light);
  Future<void> invalid() =>
      _playEffect('invalid.wav', SelectionClickType.warning);
  Future<void> swap() => _playEffect('swap.wav', SelectionClickType.light);
  Future<void> match() => _playEffect('match.wav', SelectionClickType.medium);
  Future<void> combo() => _playEffect('combo.wav', SelectionClickType.heavy);
  Future<void> power() => _playEffect('power.wav', SelectionClickType.heavy);
  Future<void> dominionBurst() =>
      _playEffect('dominion_burst.wav', SelectionClickType.heavy);
  Future<void> win() => _playEffect('win.wav', SelectionClickType.success);
  Future<void> fail() => _playEffect('fail.wav', SelectionClickType.warning);
  Future<void> reward() =>
      _playEffect('reward.wav', SelectionClickType.success);
  Future<void> timerWarning() =>
      _playEffect('timer_warning.wav', SelectionClickType.warning);
  Future<void> stageTransition() =>
      _playEffect('stage_transition.wav', SelectionClickType.medium);
  Future<void> stormWarning() =>
      _playEffect('storm_warning.wav', SelectionClickType.warning);
  Future<void> strongholdBreak() =>
      _playEffect('stronghold_break.wav', SelectionClickType.heavy);
  Future<void> rescueSuccess() =>
      _playEffect('rescue_success.wav', SelectionClickType.success);

  Future<void> toggleSound() async {
    enabled = !enabled;
    await _saveBool(_soundPrefKey, enabled);
  }

  Future<void> toggleMusic() async {
    musicEnabled = !musicEnabled;
    await _saveBool(_musicPrefKey, musicEnabled);

    if (!musicEnabled) {
      await stopBackground();
      return;
    }

    if (_activeMusic.isNotEmpty) {
      final previous = _activeMusic;
      _activeMusic = '';
      await playBackground(previous);
    }
  }

  Future<void> toggleHaptics() async {
    hapticsEnabled = !hapticsEnabled;
    await _saveBool(_hapticsPrefKey, hapticsEnabled);
  }

  Future<void> playBackgroundForLevel({
    required int stage,
    required String worldKey,
  }) async {
    final normalized = worldKey.trim().toLowerCase();
    final world = switch (normalized) {
      'garden' => 'garden',
      'rescue' => 'rescue',
      'hazard' => 'storm',
      'stronghold' => 'battle',
      'crown' => 'royal',
      'endless' => 'endless',
      _ => 'garden',
    };

    final variant = _variantForStage(stage);
    await playBackground(
        'bg_${world}_${variant.toString().padLeft(2, '0')}.wav');
  }

  Future<void> playBackgroundForWorld(String worldKey) async {
    final key = worldKey.trim().toLowerCase();
    final file = switch (key) {
      'garden' => 'bg_garden_01.wav',
      'rescue' => 'bg_rescue_01.wav',
      'hazard' => 'bg_storm_01.wav',
      'stronghold' => 'bg_battle_01.wav',
      'crown' => 'bg_royal_01.wav',
      'endless' => 'bg_endless_01.wav',
      _ => 'bg_garden_01.wav',
    };
    await playBackground(file);
  }

  int _variantForStage(int stage) {
    if (stage <= 0) return 1;
    return ((stage - 1) % 3) + 1;
  }

  Future<void> playBackground(String fileName) async {
    await init();
    if (!musicEnabled) return;
    if (_activeMusic == fileName) return;

    _activeMusic = fileName;

    try {
      await _musicPlayer.stop();
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(
        AssetSource('$_basePath/$fileName'),
        volume: _musicVolumeFor(fileName),
      );
    } catch (_) {
      // Missing assets or browser autoplay restrictions must not break gameplay.
    }
  }

  double _musicVolumeFor(String fileName) {
    if (fileName.contains('royal')) return 0.20;
    if (fileName.contains('storm') || fileName.contains('battle')) return 0.16;
    if (fileName.contains('endless')) return 0.17;
    return 0.18;
  }

  Future<void> stopBackground() async {
    try {
      await _musicPlayer.stop();
      _activeMusic = '';
    } catch (_) {
      // Ignore platform audio failures.
    }
  }

  Future<void> dispose() async {
    try {
      await _musicPlayer.dispose();
    } catch (_) {
      // Ignore platform audio failures.
    }
  }

  Future<void> _playEffect(String fileName, SelectionClickType type) async {
    await init();

    if (hapticsEnabled) {
      unawaited(_tap(type));
    }

    if (!enabled) return;

    AudioPlayer? player;
    try {
      player = AudioPlayer(
        playerId: 'dominion_sfx_${DateTime.now().microsecondsSinceEpoch}',
      );
      await player.setReleaseMode(ReleaseMode.stop);
      final completion = Completer<void>();
      StreamSubscription<void>? sub;
      sub = player.onPlayerComplete.listen((_) {
        if (!completion.isCompleted) completion.complete();
        unawaited(sub?.cancel());
      });

      await player.play(
        AssetSource('$_basePath/$fileName'),
        volume: _effectVolumeFor(fileName),
      );

      unawaited(
        completion.future
            .timeout(const Duration(seconds: 3), onTimeout: () {})
            .whenComplete(() async {
          try {
            await player?.dispose();
          } catch (_) {}
        }),
      );
    } catch (_) {
      try {
        await player?.dispose();
      } catch (_) {}
    }
  }

  double _effectVolumeFor(String fileName) {
    if (fileName.contains('fail') || fileName.contains('warning')) return 0.42;
    if (fileName.contains('win') || fileName.contains('reward')) return 0.58;
    if (fileName.contains('dominion') || fileName.contains('power'))
      return 0.62;
    if (fileName.contains('combo')) return 0.55;
    return 0.46;
  }

  Future<void> _tap(SelectionClickType type) async {
    try {
      switch (type) {
        case SelectionClickType.light:
          await HapticFeedback.selectionClick();
          break;
        case SelectionClickType.medium:
          await HapticFeedback.mediumImpact();
          break;
        case SelectionClickType.heavy:
          await HapticFeedback.heavyImpact();
          break;
        case SelectionClickType.success:
          await HapticFeedback.vibrate();
          break;
        case SelectionClickType.warning:
          await HapticFeedback.lightImpact();
          break;
      }
    } catch (_) {
      // Haptic support can fail silently on web or unsupported devices.
    }
  }

  Future<void> _saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {
      // Saving preferences should not block gameplay.
    }
  }
}

enum SelectionClickType { light, medium, heavy, success, warning }
