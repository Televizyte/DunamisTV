import 'package:flutter/material.dart';

import 'game_preview_shell.dart';

class DominionGrowthScreen extends StatelessWidget {
  const DominionGrowthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GamePreviewShell(
      title: 'Dominion Growth',
      subtitle:
          'Tap, gain Faith, upgrade your growth engine, and progress from Seed to Dominion over time.',
      badge: 'Tap / Idle Growth',
      comingSoonText: 'Preview Build',
      heroIcon: Icons.local_florist_rounded,
      routeKey: '/games/dominion-growth',
      gradientColors: [
        Color(0xFF102A43),
        Color(0xFF3B247A),
        Color(0xFFAF1E8D),
      ],
      stats: [
        GamePreviewStat(
            label: 'Resource',
            value: 'Faith',
            icon: Icons.auto_awesome_rounded),
        GamePreviewStat(
            label: 'Stages',
            value: '5',
            icon: Icons.stacked_line_chart_rounded),
        GamePreviewStat(
            label: 'Offline', value: 'Capped', icon: Icons.schedule_rounded),
        GamePreviewStat(
            label: 'Growth', value: 'Idle', icon: Icons.trending_up_rounded),
      ],
      previewWidgets: [
        GrowthCorePreview(),
      ],
      highlights: [
        'Tap to gain Faith and grow from small beginnings.',
        'Buy upgrades for tap strength and passive growth.',
        'Future engine will calculate capped offline progress.',
        'Milestone rewards will connect to scripture, Notes, and Quote Creator.',
      ],
    );
  }
}
