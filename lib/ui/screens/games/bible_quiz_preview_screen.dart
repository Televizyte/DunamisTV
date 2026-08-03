import 'package:flutter/material.dart';

import 'game_preview_shell.dart';

class BibleQuizPreviewScreen extends StatelessWidget {
  const BibleQuizPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GamePreviewShell(
      title: 'Bible Quiz',
      subtitle:
          'A structured quiz entry screen prepared for the AppsHub Quiz Engine with levels, XP, medals, and leaderboard support.',
      badge: 'Quiz Engine',
      comingSoonText: 'Preview Build',
      heroIcon: Icons.quiz_rounded,
      routeKey: '/games/bible-quiz',
      gradientColors: [
        Color(0xFF101C54),
        Color(0xFF4C2EA8),
        Color(0xFF0AA6C2),
      ],
      stats: [
        GamePreviewStat(
            label: 'Levels', value: '3', icon: Icons.layers_rounded),
        GamePreviewStat(
            label: 'Questions', value: '15', icon: Icons.help_rounded),
        GamePreviewStat(
            label: 'Rewards', value: 'XP', icon: Icons.bolt_rounded),
        GamePreviewStat(
            label: 'Medals', value: 'Ready', icon: Icons.military_tech_rounded),
      ],
      previewWidgets: [
        QuizStartPreview(),
      ],
      highlights: [
        'Prepared for Easy, Medium, and Hard levels.',
        'Future questions will come from the AppsHub Content Intelligent AI Quiz Engine.',
        'XP, medals, and leaderboard structure are ready for later backend alignment.',
        'Ads stay backend-controlled and must not interrupt active question answering.',
      ],
    );
  }
}
