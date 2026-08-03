import 'package:flutter/material.dart';

import '../../core/dominion_level.dart';

class DominionStatsBar extends StatelessWidget {
  final int score;
  final int movesLeft;
  final int combo;
  final int powerActivations;
  final DominionLevel level;
  final Duration? timeLeft;
  final double scoreProgress;
  final double missionProgress;

  const DominionStatsBar({
    super.key,
    required this.score,
    required this.movesLeft,
    required this.combo,
    required this.powerActivations,
    required this.level,
    required this.timeLeft,
    required this.scoreProgress,
    required this.missionProgress,
  });

  @override
  Widget build(BuildContext context) {
    final timerText = timeLeft == null
        ? 'No Timer'
        : '${timeLeft!.inMinutes}:${(timeLeft!.inSeconds % 60).toString().padLeft(2, '0')}';
    final theme = level.theme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatBox(
                label: 'Score',
                value: score.toString(),
                icon: Icons.stacked_line_chart_rounded,
                accent: theme.accentColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatBox(
                label: 'Moves',
                value: movesLeft.toString(),
                icon: Icons.touch_app_rounded,
                accent: theme.accentColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatBox(
                label: 'Combo',
                value: 'x${combo <= 0 ? 1 : combo}',
                icon: Icons.auto_awesome_rounded,
                accent: theme.accentColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatBox(
                label: 'Time',
                value: timerText,
                icon: Icons.timer_rounded,
                accent: theme.warningColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ProgressLine(
          label: 'Score Target',
          value: scoreProgress,
          color: theme.accentColor,
        ),
        const SizedBox(height: 7),
        _ProgressLine(
          label: theme.meterLabel,
          value: missionProgress,
          color: theme.warningColor,
        ),
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ProgressLine({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 74,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.68),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: value.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.11),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(value.clamp(0.0, 1.0) * 100).round()}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.062),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: accent.withOpacity(0.95)),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.58),
              fontWeight: FontWeight.w800,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}
