import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/race_game_config.dart';
import '../../models/race_track_object.dart';
import '../../state/race_game_controller.dart';

class RaceGameCanvas extends StatelessWidget {
  final RaceGameController controller;
  final RaceThemeConfig theme;

  const RaceGameCanvas({
    super.key,
    required this.controller,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasHeight = math.max(
          460.0,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 540.0,
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            if (!controller.isRunning) return;
            final width =
                constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
            final laneWidth = width / 3;
            final lane =
                (details.localPosition.dx / laneWidth).floor().clamp(0, 2);
            controller.moveToLane(lane);
          },
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity > 65) {
              controller.moveRight();
            } else if (velocity < -65) {
              controller.moveLeft();
            }
          },
          onVerticalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -65) {
              controller.jump();
            } else if (velocity > 65) {
              controller.slide();
            }
          },
          child: Container(
            height: canvasHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.midnight,
                  theme.deepBlue.withOpacity(0.92),
                  const Color(0xFF160A2C),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: theme.royalPurple.withOpacity(0.26),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: CustomPaint(
                painter: _RaceTrackPainter(
                  theme: theme,
                  worldOffset: controller.worldOffset,
                  runnerLanePosition: controller.lanePosition,
                  speedLevel: controller.speedLevel,
                  distanceMeters: controller.distanceMeters,
                  trackObjects: controller.trackObjects,
                  level: controller.currentLevel,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 14,
                      left: 14,
                      right: 14,
                      child: _RaceHud(controller: controller),
                    ),
                    Positioned(
                      top: 76,
                      left: 18,
                      right: 18,
                      child: _LevelProgressBar(
                          controller: controller, theme: theme),
                    ),
                    Positioned(
                      top: 104,
                      left: 16,
                      right: 16,
                      child:
                          _SpeedStageChip(controller: controller, theme: theme),
                    ),
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 70),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment(controller.laneAlignment, 0.55),
                      child: Transform.translate(
                        offset: Offset(0, controller.runnerLift),
                        child: Transform.rotate(
                          angle: controller.laneLean,
                          child: Transform.scale(
                            scaleX: controller.isSliding ? 1.12 : 1,
                            scaleY: controller.isSliding ? 0.66 : 1,
                            child: SizedBox(
                              width: 96,
                              height: 122,
                              child: CustomPaint(
                                painter: _RunnerPainter(
                                  theme: theme,
                                  gaitPhase: controller.gaitPhase,
                                  action: controller.runnerAction,
                                  collectPulse: controller.collectPulse,
                                  lean: controller.laneLean,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (controller.feedbackPulse > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 132,
                        child: _FeedbackBubble(
                            controller: controller, theme: theme),
                      ),
                    if (controller.mode == RaceScreenMode.running)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.16),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: controller.pause,
                          icon: const Icon(Icons.pause_rounded),
                          label: const Text('Pause'),
                        ),
                      ),
                    if (controller.mode == RaceScreenMode.paused)
                      _OverlayAction(
                        title: 'Paused',
                        subtitle: 'Your run is waiting.',
                        primary: 'Resume',
                        secondary: 'End Run',
                        onPrimary: controller.resume,
                        onSecondary: controller.endRun,
                      ),
                    if (controller.mode == RaceScreenMode.reward)
                      _LevelCompleteOverlay(
                          controller: controller, theme: theme),
                    if (controller.mode == RaceScreenMode.gameOver)
                      _GameOverOverlay(controller: controller, theme: theme),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RaceHud extends StatelessWidget {
  final RaceGameController controller;

  const _RaceHud({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HudChip(label: 'Level', value: controller.selectedLevel.toString()),
        const SizedBox(width: 7),
        _HudChip(label: 'Score', value: controller.score.toString()),
        const SizedBox(width: 7),
        _HudChip(
            label: 'Distance', value: '${controller.distanceMeters.round()}m'),
        const SizedBox(width: 7),
        Expanded(
          child: _LifeMeter(lives: controller.lives),
        ),
      ],
    );
  }
}

class _LifeMeter extends StatelessWidget {
  final int lives;

  const _LifeMeter({required this.lives});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Life',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.58), fontSize: 10)),
          const SizedBox(height: 2),
          FittedBox(
            alignment: Alignment.centerLeft,
            child: Row(
              children: List.generate(RaceGameController.maxLives, (index) {
                final active = index < lives;
                return Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(
                    active
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: active ? const Color(0xFFFF4F93) : Colors.white38,
                    size: 16,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  final String label;
  final String value;

  const _HudChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.58), fontSize: 10)),
            const SizedBox(height: 2),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _LevelProgressBar extends StatelessWidget {
  final RaceGameController controller;
  final RaceThemeConfig theme;

  const _LevelProgressBar({required this.controller, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: controller.levelProgress,
            backgroundColor: Colors.white.withOpacity(0.11),
            valueColor: AlwaysStoppedAnimation<Color>(theme.crownGold),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${controller.remainingMeters.round()}m to finish Level ${controller.selectedLevel}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.68),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SpeedStageChip extends StatelessWidget {
  final RaceGameController controller;
  final RaceThemeConfig theme;

  const _SpeedStageChip({required this.controller, required this.theme});

  @override
  Widget build(BuildContext context) {
    final label = controller.isJumping
        ? 'Jump over barriers'
        : controller.isSliding
            ? 'Slide under obstacles'
            : controller.speedStageLabel;
    final icon = controller.isJumping
        ? Icons.keyboard_double_arrow_up_rounded
        : controller.isSliding
            ? Icons.keyboard_double_arrow_down_rounded
            : Icons.bolt_rounded;

    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.28),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.lightCyan.withOpacity(0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.crownGold, size: 16),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.82),
                fontWeight: FontWeight.w900,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayAction extends StatelessWidget {
  final String title;
  final String subtitle;
  final String primary;
  final String secondary;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const _OverlayAction({
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.secondary,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.48),
        child: Center(
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF10172D),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.64))),
                const SizedBox(height: 18),
                FilledButton(onPressed: onPrimary, child: Text(primary)),
                TextButton(onPressed: onSecondary, child: Text(secondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackBubble extends StatelessWidget {
  final RaceGameController controller;
  final RaceThemeConfig theme;

  const _FeedbackBubble({required this.controller, required this.theme});

  @override
  Widget build(BuildContext context) {
    final opacity = controller.feedbackPulse.clamp(0.0, 1.0);
    return Opacity(
      opacity: opacity,
      child: Center(
        child: Transform.translate(
          offset: Offset(0, -22 * (1 - opacity)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: controller.feedbackIsBad
                  ? const Color(0xFF5C1733).withOpacity(0.88)
                  : const Color(0xFF123C2F).withOpacity(0.88),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: controller.feedbackIsBad
                    ? const Color(0xFFFF4F93)
                    : theme.crownGold,
              ),
            ),
            child: Text(
              controller.feedbackText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelCompleteOverlay extends StatelessWidget {
  final RaceGameController controller;
  final RaceThemeConfig theme;

  const _LevelCompleteOverlay({required this.controller, required this.theme});

  @override
  Widget build(BuildContext context) {
    final level = controller.currentLevel;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.58),
        child: Center(
          child: Container(
            width: 316,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF10172D),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: theme.crownGold.withOpacity(0.22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events_rounded,
                    color: theme.crownGold, size: 46),
                const SizedBox(height: 10),
                Text(
                  'Level ${level.number} Complete',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${level.rewardTitle} · ${level.scriptureReference}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.crownGold.withOpacity(0.92),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  level.rewardMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.68), height: 1.35),
                ),
                const SizedBox(height: 16),
                _ResultStats(controller: controller),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: controller.continueNextLevel,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    level.number >= controller.levels.length
                        ? 'Replay Final Level'
                        : 'Continue Level ${level.number + 1}',
                  ),
                ),
                TextButton(
                  onPressed: controller.goHome,
                  child: const Text('Back to Levels'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final RaceGameController controller;
  final RaceThemeConfig theme;

  const _GameOverOverlay({required this.controller, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.58),
        child: Center(
          child: Container(
            width: 304,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF10172D),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.heart_broken_rounded,
                    color: Color(0xFFFF4F93), size: 42),
                const SizedBox(height: 10),
                const Text(
                  'Level Failed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'You ran out of lives before the finish line.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.66)),
                ),
                const SizedBox(height: 16),
                _ResultStats(controller: controller),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: controller.retryLevel,
                  icon: const Icon(Icons.replay_rounded),
                  label: Text('Retry Level ${controller.selectedLevel}'),
                ),
                TextButton(
                  onPressed: controller.goHome,
                  child: const Text('Back to Levels'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultStats extends StatelessWidget {
  final RaceGameController controller;

  const _ResultStats({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _MiniStat('Score', controller.score.toString()),
        _MiniStat('Distance', '${controller.distanceMeters.round()}m'),
        _MiniStat('Light', controller.lightCollected.toString()),
        _MiniStat('Lives', controller.lives.toString()),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _RaceTrackPainter extends CustomPainter {
  final RaceThemeConfig theme;
  final double worldOffset;
  final double runnerLanePosition;
  final int speedLevel;
  final double distanceMeters;
  final List<RaceTrackObject> trackObjects;
  final RaceLevelConfig level;

  const _RaceTrackPainter({
    required this.theme,
    required this.worldOffset,
    required this.runnerLanePosition,
    required this.speedLevel,
    required this.distanceMeters,
    required this.trackObjects,
    required this.level,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintAtmosphere(canvas, size);
    _paintRoad(canvas, size);
    _paintRoadMarkers(canvas, size);
    _paintWorldTrackObjects(canvas, size);
    _paintSpeedLines(canvas, size);
  }

  double get _runnerScreenT => 0.88;
  double get _lookAheadMeters =>
      132.0 + speedLevel * 24.0 + level.stage.index * 8.0;

  void _paintAtmosphere(Canvas canvas, Size size) {
    final stage = level.stage;
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [stage.skyTop, stage.skyBottom],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final skyGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.65),
        radius: 0.92,
        colors: [
          stage.roadGlow.withOpacity(0.20),
          stage.accent.withOpacity(0.10),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, skyGlow);

    final particlePaint = Paint()..color = Colors.white.withOpacity(0.10);
    for (var i = 0; i < 26; i++) {
      final x =
          ((i * 47 + distanceMeters * (5.2 + level.stage.index)) % size.width)
              .toDouble();
      final y = ((i * 71 + distanceMeters * (7.8 + level.stage.index * 1.4)) %
              size.height)
          .toDouble();
      final r = 0.8 + (i % 3) * 0.45;
      canvas.drawCircle(Offset(x, y), r, particlePaint);
    }

    _paintStageEnvironment(canvas, size, stage);
  }

  void _paintStageEnvironment(Canvas canvas, Size size, RaceStageConfig stage) {
    final paint = Paint()
      ..color = stage.accent.withOpacity(0.08)
      ..strokeWidth = 1.2;
    final baseY = size.height * 0.70;
    if (stage.index == 1) {
      for (var i = 0; i < 6; i++) {
        final y = (baseY + i * 28 + distanceMeters * 0.9) % size.height;
        canvas.drawLine(
            Offset(12, y), Offset(size.width * 0.22, y + 16), paint);
        canvas.drawLine(Offset(size.width - 12, y + 8),
            Offset(size.width * 0.78, y + 24), paint);
      }
    } else if (stage.index == 2) {
      final mountain = Path()
        ..moveTo(0, size.height * 0.52)
        ..lineTo(size.width * 0.18, size.height * 0.30)
        ..lineTo(size.width * 0.36, size.height * 0.53)
        ..lineTo(size.width * 0.58, size.height * 0.33)
        ..lineTo(size.width, size.height * 0.55);
      canvas.drawPath(
          mountain, Paint()..color = Colors.white.withOpacity(0.035));
    } else if (stage.index == 3) {
      final cityPaint = Paint()..color = Colors.white.withOpacity(0.045);
      for (var i = 0; i < 7; i++) {
        final w = 14.0 + (i % 3) * 8;
        final h = 48.0 + (i % 4) * 18;
        final x = i.isEven ? i * 20.0 : size.width - i * 18.0 - w;
        canvas.drawRect(
            Rect.fromLTWH(x, size.height * 0.42 - h, w, h), cityPaint);
      }
    } else if (stage.index >= 7) {
      final lightning = Paint()
        ..color = stage.accent.withOpacity(0.12)
        ..strokeWidth = 1.4;
      for (var i = 0; i < 5; i++) {
        final x = (i + 1) * size.width / 6;
        final y = ((distanceMeters * 4 + i * 90) % size.height).toDouble();
        canvas.drawLine(Offset(x, y), Offset(x + 16, y + 42), lightning);
      }
    }
  }

  void _paintRoad(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final horizonY = size.height * 0.19;
    final bottomY = size.height;
    final roadTop = size.width * 0.22;
    final roadBottom = size.width * 0.94;

    final road = Path()
      ..moveTo(centerX - roadTop / 2, horizonY)
      ..lineTo(centerX + roadTop / 2, horizonY)
      ..lineTo(centerX + roadBottom / 2, bottomY)
      ..lineTo(centerX - roadBottom / 2, bottomY)
      ..close();

    canvas.drawPath(
      road,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.026),
          ],
        ).createShader(
          Rect.fromLTWH(0, horizonY, size.width, bottomY - horizonY),
        ),
    );

    final edgePaint = Paint()
      ..color = level.stage.roadGlow.withOpacity(0.34)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(centerX - roadTop / 2, horizonY),
        Offset(centerX - roadBottom / 2, bottomY), edgePaint);
    canvas.drawLine(Offset(centerX + roadTop / 2, horizonY),
        Offset(centerX + roadBottom / 2, bottomY), edgePaint);

    final lanePaint = Paint()
      ..color = level.stage.roadGlow.withOpacity(0.30)
      ..strokeWidth = 1.2;
    for (final ratio in [0.33, 0.66]) {
      final topX = centerX - roadTop / 2 + roadTop * ratio;
      final bottomX = centerX - roadBottom / 2 + roadBottom * ratio;
      canvas.drawLine(
          Offset(topX, horizonY), Offset(bottomX, bottomY), lanePaint);
    }

    final laneGlowPaint = Paint()
      ..color = level.stage.roadGlow.withOpacity(0.07)
      ..style = PaintingStyle.fill;
    final leftRatio = runnerLanePosition / 3;
    final rightRatio = (runnerLanePosition + 1) / 3;
    final activePath = Path()
      ..moveTo(centerX - roadTop / 2 + roadTop * leftRatio, horizonY)
      ..lineTo(centerX - roadTop / 2 + roadTop * rightRatio, horizonY)
      ..lineTo(centerX - roadBottom / 2 + roadBottom * rightRatio, bottomY)
      ..lineTo(centerX - roadBottom / 2 + roadBottom * leftRatio, bottomY)
      ..close();
    canvas.drawPath(activePath, laneGlowPaint);
  }

  void _paintRoadMarkers(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    const markerSpacingMeters = 18.0;
    final markerPaint = Paint()..color = Colors.white.withOpacity(0.15);
    final first = (distanceMeters / markerSpacingMeters).floor();
    for (var i = 0; i < 22; i++) {
      final markerDistance = (first + i) * markerSpacingMeters;
      final forward = markerDistance - distanceMeters;
      if (forward < -8 || forward > _lookAheadMeters) continue;
      final point = _project(size, lane: 1, forwardMeters: forward);
      if (point == null) continue;
      final scale = point.scale;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: point.offset,
            width: 10 + scale * 62,
            height: 4.5 + scale * 1.5,
          ),
          const Radius.circular(16),
        ),
        markerPaint,
      );
    }
  }

  void _paintWorldTrackObjects(Canvas canvas, Size size) {
    for (final object in trackObjects) {
      final forward = object.distanceMeters - distanceMeters;
      if (forward < -24 || forward > _lookAheadMeters) continue;
      final point = _project(size, lane: object.lane, forwardMeters: forward);
      if (point == null) continue;
      _drawTrackObject(canvas, object, point.offset, point.scale);
    }
  }

  _Projection? _project(Size size,
      {required int lane, required double forwardMeters}) {
    final horizonY = size.height * 0.19;
    final bottomY = size.height;
    final usableH = bottomY - horizonY;
    final runnerY = horizonY + usableH * _runnerScreenT;
    final normalized = (forwardMeters / _lookAheadMeters).clamp(0.0, 1.0);
    final t = _runnerScreenT - normalized * (_runnerScreenT - 0.04);
    final y = horizonY + usableH * t;
    if (y < horizonY - 12 || y > bottomY + 28) return null;

    final centerX = size.width / 2;
    final roadTop = size.width * 0.22;
    final roadBottom = size.width * 0.94;
    final perspective = ((y - horizonY) / usableH).clamp(0.0, 1.0);
    final roadWidth = roadTop + (roadBottom - roadTop) * perspective;
    final laneCenterRatio = (lane + 0.5) / 3.0;
    final x = centerX - roadWidth / 2 + roadWidth * laneCenterRatio;
    final scale = (0.22 + perspective * 0.9).clamp(0.22, 1.0);
    return _Projection(Offset(x, y), scale);
  }

  void _drawTrackObject(
    Canvas canvas,
    RaceTrackObject object,
    Offset center,
    double scale,
  ) {
    switch (object.type) {
      case RaceTrackObjectType.light:
        _drawLight(canvas, center, scale, object);
        break;
      case RaceTrackObjectType.wordScroll:
        _drawScroll(canvas, center, scale, object);
        break;
      case RaceTrackObjectType.cross:
        _drawCross(canvas, center, scale, object);
        break;
      case RaceTrackObjectType.crown:
        _drawCrown(canvas, center, scale, object);
        break;
      case RaceTrackObjectType.shield:
        _drawShield(canvas, center, scale, object);
        break;
      case RaceTrackObjectType.fearWall:
        _drawFaithObstacle(
          canvas,
          center,
          scale,
          object,
          const Color(0xFFFF4F93),
          Icons.warning_rounded,
        );
        break;
      case RaceTrackObjectType.doubtBlock:
        _drawFaithObstacle(
          canvas,
          center,
          scale,
          object,
          const Color(0xFF8E5BFF),
          Icons.question_mark_rounded,
        );
        break;
      case RaceTrackObjectType.distractionGate:
        _drawFaithObstacle(
          canvas,
          center,
          scale,
          object,
          const Color(0xFFFF9F45),
          Icons.visibility_off_rounded,
        );
        break;
      case RaceTrackObjectType.burdenStone:
        _drawLowObstacle(canvas, center, scale, object);
        break;
      case RaceTrackObjectType.temptationTrap:
        _drawFaithObstacle(
          canvas,
          center,
          scale,
          object,
          const Color(0xFFE84545),
          Icons.dangerous_rounded,
        );
        break;
    }
  }

  void _drawLight(
      Canvas canvas, Offset center, double scale, RaceTrackObject object) {
    final radius = 5.0 + scale * 8.0;
    final glow = Paint()
      ..color = theme.crownGold.withOpacity(0.38)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13);
    final fill = Paint()..color = theme.crownGold.withOpacity(0.96);
    canvas.drawCircle(center, radius + 8, glow);
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center.translate(-radius * 0.32, -radius * 0.35),
        radius * 0.32, Paint()..color = Colors.white.withOpacity(0.72));
    _drawItemLabels(canvas, object, center, scale, theme.crownGold);
  }

  void _drawScroll(
      Canvas canvas, Offset center, double scale, RaceTrackObject object) {
    final rect = Rect.fromCenter(
      center: center,
      width: 18 + scale * 30,
      height: 12 + scale * 20,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()..color = const Color(0xFFFFE0A3).withOpacity(0.94),
    );
    canvas.drawLine(
      rect.centerLeft,
      rect.centerRight,
      Paint()
        ..color = Colors.brown.withOpacity(0.32)
        ..strokeWidth = 1.2,
    );
    _drawItemLabels(canvas, object, center, scale, const Color(0xFFB07125));
  }

  void _drawCross(
      Canvas canvas, Offset center, double scale, RaceTrackObject object) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.94)
      ..strokeWidth = (4.0 + scale * 3).clamp(4.0, 7.0)
      ..strokeCap = StrokeCap.round;
    final glow = Paint()
      ..color = level.stage.accent.withOpacity(0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, 16 + scale * 18, glow);
    canvas.drawLine(center.translate(0, -14 * scale),
        center.translate(0, 16 * scale), paint);
    canvas.drawLine(center.translate(-12 * scale, -2 * scale),
        center.translate(12 * scale, -2 * scale), paint);
    _drawItemLabels(canvas, object, center, scale, Colors.white);
  }

  void _drawCrown(
      Canvas canvas, Offset center, double scale, RaceTrackObject object) {
    final w = 24 + scale * 32;
    final h = 16 + scale * 18;
    final path = Path()
      ..moveTo(center.dx - w / 2, center.dy + h / 3)
      ..lineTo(center.dx - w * 0.30, center.dy - h / 4)
      ..lineTo(center.dx - w * 0.08, center.dy + h / 8)
      ..lineTo(center.dx, center.dy - h / 2)
      ..lineTo(center.dx + w * 0.08, center.dy + h / 8)
      ..lineTo(center.dx + w * 0.30, center.dy - h / 4)
      ..lineTo(center.dx + w / 2, center.dy + h / 3)
      ..close();
    canvas.drawPath(path, Paint()..color = theme.crownGold.withOpacity(0.95));
    canvas.drawCircle(center.translate(0, -h / 2), 2.4 + scale * 2,
        Paint()..color = Colors.white.withOpacity(0.78));
    _drawItemLabels(canvas, object, center, scale, theme.crownGold);
  }

  void _drawShield(
      Canvas canvas, Offset center, double scale, RaceTrackObject object) {
    final r = 16 + scale * 18;
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..quadraticBezierTo(center.dx + r, center.dy - r * 0.55,
          center.dx + r * 0.72, center.dy + r * 0.28)
      ..quadraticBezierTo(
          center.dx + r * 0.34, center.dy + r, center.dx, center.dy + r * 1.18)
      ..quadraticBezierTo(center.dx - r * 0.34, center.dy + r,
          center.dx - r * 0.72, center.dy + r * 0.28)
      ..quadraticBezierTo(
          center.dx - r, center.dy - r * 0.55, center.dx, center.dy - r)
      ..close();
    canvas.drawPath(
        path, Paint()..color = const Color(0xFF32E3FF).withOpacity(0.78));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withOpacity(0.72),
    );
    _drawItemLabels(canvas, object, center, scale, const Color(0xFF32E3FF));
  }

  void _drawFaithObstacle(
    Canvas canvas,
    Offset center,
    double scale,
    RaceTrackObject object,
    Color color,
    IconData icon,
  ) {
    final rect = Rect.fromCenter(
      center: center,
      width: 24 + scale * 50,
      height: 16 + scale * 30,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(6), const Radius.circular(10)),
      Paint()
        ..color = color.withOpacity(0.24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = color.withOpacity(0.78),
    );
    _drawSmallIcon(canvas, icon, center, scale, Colors.white.withOpacity(0.82));
    _drawItemLabels(canvas, object, center, scale, color);
  }

  void _drawLowObstacle(
      Canvas canvas, Offset center, double scale, RaceTrackObject object) {
    final rect = Rect.fromCenter(
      center: center.translate(0, 6 * scale),
      width: 28 + scale * 58,
      height: 10 + scale * 18,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(999)),
      Paint()..color = const Color(0xFFB66AFF).withOpacity(0.82),
    );
    _drawSmallIcon(canvas, Icons.fitness_center_rounded, center, scale,
        Colors.white.withOpacity(0.75));
    _drawItemLabels(canvas, object, center, scale, const Color(0xFFB66AFF));
  }

  void _drawSmallIcon(
      Canvas canvas, IconData icon, Offset center, double scale, Color color) {
    if (scale < 0.42) return;
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: color,
          fontSize: (12 + scale * 11).clamp(12.0, 22.0),
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawItemLabels(
    Canvas canvas,
    RaceTrackObject object,
    Offset center,
    double scale,
    Color color,
  ) {
    if (scale < 0.30) return;
    _drawPillLabel(
        canvas, object.title, center, scale, color, -28 - scale * 12);
    if (scale >= 0.46) {
      _drawPillLabel(
        canvas,
        object.label,
        center,
        scale,
        object.isObstacle ? const Color(0xFFE84545) : color,
        object.isObstacle ? 22 + scale * 8 : 21 + scale * 7,
      );
    }
  }

  void _drawPillLabel(
    Canvas canvas,
    String label,
    Offset center,
    double scale,
    Color color,
    double dy,
  ) {
    final style = TextStyle(
      color: Colors.white.withOpacity(0.94),
      fontSize: (7.5 + scale * 3.6).clamp(7.5, 11.5),
      fontWeight: FontWeight.w900,
    );
    final tp = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final rect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + dy),
      width: tp.width + 12,
      height: tp.height + 6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(999)),
      Paint()..color = color.withOpacity(0.70),
    );
    tp.paint(canvas, Offset(rect.left + 6, rect.top + 3));
  }

  void _paintSpeedLines(Canvas canvas, Size size) {
    if (speedLevel < 2) return;
    final paint = Paint()
      ..color = Colors.white
          .withOpacity(0.07 + speedLevel * 0.014 + level.stage.index * 0.004)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 14; i++) {
      final x = (i.isEven ? 1 : -1) * (size.width * (0.18 + (i % 5) * 0.055)) +
          size.width / 2;
      final y = ((i * 63 + distanceMeters * (34.0 + level.stage.index * 3.0)) %
              size.height)
          .toDouble();
      canvas.drawLine(
          Offset(x, y), Offset(x + (i.isEven ? 12 : -12), y + 38), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RaceTrackPainter oldDelegate) {
    return oldDelegate.worldOffset != worldOffset ||
        oldDelegate.runnerLanePosition != runnerLanePosition ||
        oldDelegate.speedLevel != speedLevel ||
        oldDelegate.distanceMeters != distanceMeters ||
        oldDelegate.trackObjects != trackObjects ||
        oldDelegate.level != level;
  }
}

class _Projection {
  final Offset offset;
  final double scale;

  const _Projection(this.offset, this.scale);
}

class _RunnerPainter extends CustomPainter {
  final RaceThemeConfig theme;
  final double gaitPhase;
  final RaceRunnerAction action;
  final double collectPulse;
  final double lean;

  const _RunnerPainter({
    required this.theme,
    required this.gaitPhase,
    required this.action,
    required this.collectPulse,
    required this.lean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final groundY = size.height * 0.91;
    final running = action == RaceRunnerAction.running;
    final jumping = action == RaceRunnerAction.jumping;
    final sliding = action == RaceRunnerAction.sliding;
    final hit = action == RaceRunnerAction.hit;
    final stride = math.sin(gaitPhase);
    final counter = math.cos(gaitPhase);
    final footCycle = math.sin(gaitPhase * 1.12);
    final leanDx = lean * 18;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(sliding ? 0.38 : 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, groundY + 3),
        width: sliding ? 72 : 48,
        height: sliding ? 10 : 12,
      ),
      shadowPaint,
    );

    final auraPaint = Paint()
      ..color = (hit ? const Color(0xFFFF4F93) : theme.crownGold)
          .withOpacity(0.13 + collectPulse * 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(
        Offset(cx + leanDx * 0.25, 66), 32 + collectPulse * 9, auraPaint);

    if (sliding) {
      _paintSlidePose(canvas, size, cx, groundY);
      return;
    }

    final runBob = running ? counter * 2.2 : 0.0;
    final jumpBob = jumping ? -7.0 : 0.0;
    final hitBob = hit ? 2.8 : 0.0;
    final bob = runBob + jumpBob + hitBob;

    final head = Offset(cx + leanDx * 0.38, 27 + bob);
    final neck = Offset(cx + leanDx * 0.48, 43 + bob);
    final waist = Offset(cx + leanDx * 0.76, 82 + bob);
    final hip = Offset(cx + leanDx * 0.88, 90 + bob);

    final rearLimbPaint = Paint()
      ..color = Colors.white.withOpacity(0.62)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final limbPaint = Paint()
      ..color = Colors.white.withOpacity(0.96)
      ..strokeWidth = 4.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Rear limbs stay close to the body so the runner reads like a human, not
    // a crawling figure. The motion is a front-facing sprint cycle.
    _drawArm(canvas, neck, -stride, false, rearLimbPaint, jumping: jumping);
    _drawLeg(canvas, hip, footCycle, false, groundY, rearLimbPaint,
        jumping: jumping);

    final suitPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: hit
            ? [const Color(0xFFFFB1C6), const Color(0xFF9D164A)]
            : [theme.lightCyan, theme.dangerPink],
      ).createShader(Rect.fromLTWH(cx - 24, 42, 48, 54));

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset((neck.dx + waist.dx) / 2, (neck.dy + waist.dy) / 2 + 3),
        width: 30,
        height: 48,
      ),
      const Radius.circular(17),
    );
    canvas.drawRRect(body, suitPaint);

    canvas.drawCircle(head, 11.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(head.dx + 3.6, head.dy - 4), 2.2,
        Paint()..color = theme.crownGold.withOpacity(0.96));
    canvas.drawArc(
      Rect.fromCircle(center: head, radius: 15),
      -math.pi * 0.82,
      math.pi * 0.54,
      false,
      Paint()
        ..color = theme.crownGold.withOpacity(0.38)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );

    // Front limbs.
    _drawArm(canvas, neck, stride, true, limbPaint, jumping: jumping);
    _drawLeg(canvas, hip, -footCycle, true, groundY, limbPaint,
        jumping: jumping);

    // White chest mark for clearer character identity.
    final mark = Paint()
      ..color = Colors.white.withOpacity(0.78)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx + leanDx * 0.6, 55 + bob),
        Offset(cx + leanDx * 0.72, 72 + bob), mark);
    canvas.drawLine(Offset(cx + leanDx * 0.64, 63 + bob),
        Offset(cx + leanDx * 0.46, 67 + bob), mark);

    if (collectPulse > 0) {
      final pulsePaint = Paint()
        ..color = theme.crownGold.withOpacity(collectPulse * 0.66)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset(cx + leanDx * 0.45, 64 + bob),
          28 + collectPulse * 17, pulsePaint);
    }
  }

  void _paintSlidePose(Canvas canvas, Size size, double cx, double groundY) {
    final suitPaint = Paint()
      ..shader = LinearGradient(
        colors: [theme.lightCyan, theme.dangerPink],
      ).createShader(Rect.fromCenter(
        center: Offset(cx, groundY - 30),
        width: 82,
        height: 40,
      ));
    final limbPaint = Paint()
      ..color = Colors.white.withOpacity(0.94)
      ..strokeWidth = 4.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, groundY - 31), width: 70, height: 32),
      const Radius.circular(22),
    );
    canvas.drawRRect(body, suitPaint);
    canvas.drawCircle(
        Offset(cx - 29, groundY - 36), 10.5, Paint()..color = Colors.white);
    canvas.drawLine(
        Offset(cx - 4, groundY - 34), Offset(cx + 37, groundY - 42), limbPaint);
    canvas.drawLine(
        Offset(cx - 2, groundY - 22), Offset(cx + 40, groundY - 18), limbPaint);
    canvas.drawLine(
        Offset(cx - 32, groundY - 18), Offset(cx - 48, groundY - 8), limbPaint);
  }

  void _drawArm(
    Canvas canvas,
    Offset neck,
    double phase,
    bool front,
    Paint paint, {
    required bool jumping,
  }) {
    final side = front ? -1.0 : 1.0;
    final swing = phase.clamp(-1.0, 1.0);
    final shoulder = neck + Offset(side * 12, 8);
    final elbow = jumping
        ? shoulder + Offset(side * (9 + swing * 3), 13 + swing * 4)
        : shoulder + Offset(side * (9 + swing * 6), 19 - swing * 8);
    final hand = jumping
        ? elbow + Offset(side * (7 + swing * 2), 13 + swing * 3)
        : elbow + Offset(side * (7 - swing * 3), 16 + swing * 7);
    canvas.drawLine(shoulder, elbow, paint);
    canvas.drawLine(elbow, hand, paint);
  }

  void _drawLeg(
    Canvas canvas,
    Offset hip,
    double phase,
    bool front,
    double groundY,
    Paint paint, {
    required bool jumping,
  }) {
    final side = front ? -1.0 : 1.0;
    final swing = phase.clamp(-1.0, 1.0);
    final hipPoint = hip + Offset(side * 8, 0);
    final knee = jumping
        ? hipPoint + Offset(side * (4 + swing * 3), 21 - swing * 4)
        : hipPoint + Offset(side * (3 + swing * 4), 25 + (1 - swing.abs()) * 4);
    final footY = jumping
        ? groundY - 22 - swing.abs() * 5
        : groundY - 5 - math.max(0, swing) * 9;
    final foot = Offset(hipPoint.dx + side * (3 + swing * 6), footY);
    canvas.drawLine(hipPoint, knee, paint);
    canvas.drawLine(knee, foot, paint);
    canvas.drawLine(foot, foot + Offset(side * 10, 1.4), paint);
  }

  @override
  bool shouldRepaint(covariant _RunnerPainter oldDelegate) {
    return oldDelegate.gaitPhase != gaitPhase ||
        oldDelegate.action != action ||
        oldDelegate.collectPulse != collectPulse ||
        oldDelegate.lean != lean;
  }
}
