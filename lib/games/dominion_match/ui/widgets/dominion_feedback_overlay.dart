import 'package:flutter/material.dart';

import '../../core/dominion_level.dart';

class DominionFeedbackOverlay extends StatelessWidget {
  final String message;
  final String kind;
  final int seed;
  final DominionWorldTheme theme;

  const DominionFeedbackOverlay({
    super.key,
    required this.message,
    required this.kind,
    required this.seed,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final visible = message.trim().isNotEmpty;
    final config = _FeedbackConfig.fromKind(kind, theme);

    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0, -0.12),
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: slide,
              child: ScaleTransition(scale: animation, child: child),
            ),
          );
        },
        child: visible
            ? Align(
                key: ValueKey('dominion_feedback_$seed'),
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [
                          config.color.withOpacity(0.96),
                          config.secondColor.withOpacity(0.86),
                        ],
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.22)),
                      boxShadow: [
                        BoxShadow(
                          color: config.color.withOpacity(0.34),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(config.icon, color: Colors.white, size: 18),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(key: ValueKey('dominion_feedback_empty')),
      ),
    );
  }
}

class _FeedbackConfig {
  final IconData icon;
  final Color color;
  final Color secondColor;

  const _FeedbackConfig({
    required this.icon,
    required this.color,
    required this.secondColor,
  });

  static _FeedbackConfig fromKind(String kind, DominionWorldTheme theme) {
    return switch (kind) {
      'combo' => _FeedbackConfig(
          icon: Icons.auto_awesome_rounded,
          color: const Color(0xFFFF2EA6),
          secondColor: theme.accentColor,
        ),
      'power' => _FeedbackConfig(
          icon: Icons.bolt_rounded,
          color: const Color(0xFFFFD84D),
          secondColor: theme.accentColor,
        ),
      'warning' => _FeedbackConfig(
          icon: Icons.warning_amber_rounded,
          color: theme.warningColor,
          secondColor: const Color(0xFFFF4D6D),
        ),
      'victory' => _FeedbackConfig(
          icon: Icons.emoji_events_rounded,
          color: const Color(0xFFFFD84D),
          secondColor: const Color(0xFFFF2EA6),
        ),
      'stage' => _FeedbackConfig(
          icon: theme.icon,
          color: theme.accentColor,
          secondColor: const Color(0xFFFF2EA6),
        ),
      _ => _FeedbackConfig(
          icon: Icons.stars_rounded,
          color: theme.accentColor,
          secondColor: const Color(0xFF8D6CFF),
        ),
    };
  }
}
