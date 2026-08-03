import 'package:flutter/material.dart';

import '../../config/race_game_config.dart';
import '../../state/race_game_controller.dart';

class RaceSettingsSheet extends StatelessWidget {
  final RaceGameController controller;
  final RaceThemeConfig theme;

  const RaceSettingsSheet({
    super.key,
    required this.controller,
    required this.theme,
  });

  static Future<void> show(
    BuildContext context, {
    required RaceGameController controller,
    required RaceThemeConfig theme,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return RaceSettingsSheet(controller: controller, theme: theme);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF10172D),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: theme.actionGradient,
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Race Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SettingSwitch(
              icon: Icons.music_note_rounded,
              title: 'Adventure Music',
              subtitle: 'Original adventure loop for the run.',
              value: controller.musicEnabled,
              onChanged: (_) => controller.toggleMusic(),
            ),
            const SizedBox(height: 10),
            _SettingSwitch(
              icon: Icons.graphic_eq_rounded,
              title: 'Sound Effects',
              subtitle: 'Move, jump, slide, collect, hit, and reward sounds.',
              value: controller.effectsEnabled,
              onChanged: (_) => controller.toggleEffects(),
            ),
            const SizedBox(height: 12),
            Text(
              'Race audio is modular. Apps can later replace the music/effects per theme without changing the runner engine.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.58),
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
