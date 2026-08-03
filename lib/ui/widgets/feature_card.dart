import 'package:flutter/material.dart';
import '../../theme/theme_controller.dart';

enum FeatureCardVariant { list, grid, wide }

class FeatureCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final FeatureCardVariant variant;
  final bool enabled;

  const FeatureCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.variant = FeatureCardVariant.list,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final tap = enabled ? onTap : null;

    switch (variant) {
      case FeatureCardVariant.grid:
        return _GridCard(title: title, icon: icon, onTap: tap, enabled: enabled);
      case FeatureCardVariant.wide:
        return _WideCard(title: title, icon: icon, onTap: tap, enabled: enabled);
      case FeatureCardVariant.list:
      default:
        return _ListCard(
          title: title,
          subtitle: subtitle,
          icon: icon,
          onTap: tap,
          enabled: enabled,
        );
    }
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  const _CardShell({
    required this.child,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = ThemeController.instance.isLightMode;

    final base = Container(
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF0D1228),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isLight
              ? Colors.black.withOpacity(0.06)
              : Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? Colors.black.withOpacity(0.08)
                : Colors.black.withOpacity(0.22),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: base,
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  const _IconBubble({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5B1FA8),
            Color(0xFFB70E7C),
          ],
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _ListCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const _ListCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = ThemeController.instance.isLightMode;

    return _CardShell(
      onTap: onTap,
      enabled: enabled,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            _IconBubble(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isLight ? Colors.black : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if ((subtitle ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isLight
                            ? Colors.black.withOpacity(0.65)
                            : Colors.white.withOpacity(0.75),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.chevron_right_rounded,
              color: isLight
                  ? Colors.black.withOpacity(0.5)
                  : Colors.white.withOpacity(0.70),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const _GridCard({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = ThemeController.instance.isLightMode;

    return _CardShell(
      onTap: onTap,
      enabled: enabled,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconBubble(icon: icon),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isLight ? Colors.black : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const _WideCard({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = ThemeController.instance.isLightMode;

    return _CardShell(
      onTap: onTap,
      enabled: enabled,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: Row(
          children: [
            _IconBubble(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isLight ? Colors.black : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
