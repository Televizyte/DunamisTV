import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme_controller.dart';

class DxmTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final bool showMenu;
  final bool showThemeToggle;
  final VoidCallback? onBack;
  final VoidCallback? onRefresh;
  final VoidCallback? onNotificationsTap;
  final List<DxmTopBarMenuEntry> extraMenuItems;

  /// Visible page-specific actions that should remain in the top bar.
  /// Example:
  /// - Quote Creator reset
  /// - Notes special action buttons
  /// - Any custom page action that should not be hidden inside the menu
  final List<Widget> actions;

  const DxmTopBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.showMenu = false,
    this.showThemeToggle = true,
    this.onBack,
    this.onRefresh,
    this.onNotificationsTap,
    this.extraMenuItems = const [],
    this.actions = const [],
  });

  static const LinearGradient topGradient = LinearGradient(
    colors: [
      Color(0xFF1A1F5A),
      Color(0xFF5B1FA8),
      Color(0xFFB70E7C),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final isLight = ThemeController.instance.isLightMode;

        return Container(
          decoration: const BoxDecoration(gradient: topGradient),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal:
                    showBack || showMenu || actions.isNotEmpty ? 8 : 16,
              ),
              child: Row(
                children: [
                  if (showBack)
                    IconButton(
                      tooltip: 'Back',
                      onPressed: onBack ??
                          () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/');
                            }
                          },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  ...actions,
                  if (showThemeToggle)
                    IconButton(
                      tooltip:
                          isLight ? 'Switch to dark mode' : 'Switch to light mode',
                      onPressed: () =>
                          ThemeController.instance.toggleTheme(),
                      icon: Icon(
                        isLight
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: Colors.white,
                      ),
                    ),
                  if (showMenu)
                    IconButton(
                      tooltip: 'More',
                      onPressed: () => showDxmTopBarMenu(
                        context,
                        isLight: isLight,
                        onRefresh: onRefresh,
                        onNotificationsTap: onNotificationsTap,
                        extraItems: extraMenuItems,
                      ),
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class DxmTopBarMenuEntry {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const DxmTopBarMenuEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

Future<void> showDxmTopBarMenu(
  BuildContext context, {
  required bool isLight,
  VoidCallback? onRefresh,
  VoidCallback? onNotificationsTap,
  List<DxmTopBarMenuEntry> extraItems = const [],
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor:
        isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0D1228),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) {
      final titleColor = isLight ? const Color(0xFF1E1B16) : Colors.white;
      final subtitleColor = isLight
          ? const Color(0xFF6B6256)
          : Colors.white.withOpacity(0.68);
      final itemBg = isLight
          ? const Color(0xFFF2E8D8)
          : Colors.white.withOpacity(0.04);

      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: isLight
                      ? const Color(0xFFD2C2AC)
                      : Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              _DxmTopMenuItem(
                icon: isLight
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                title: isLight ? 'Dark Mode' : 'Light Mode',
                subtitle: 'Switch app appearance',
                titleColor: titleColor,
                subtitleColor: subtitleColor,
                backgroundColor: itemBg,
                onTap: () {
                  Navigator.pop(sheetContext);
                  ThemeController.instance.toggleTheme();
                },
              ),
              const SizedBox(height: 10),
              _DxmTopMenuItem(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Open notification inbox',
                titleColor: titleColor,
                subtitleColor: subtitleColor,
                backgroundColor: itemBg,
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (onNotificationsTap != null) {
                    onNotificationsTap();
                  } else {
                    context.push('/notifications');
                  }
                },
              ),
              if (onRefresh != null) ...[
                const SizedBox(height: 10),
                _DxmTopMenuItem(
                  icon: Icons.refresh_rounded,
                  title: 'Refresh',
                  subtitle: 'Reload this page',
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                  backgroundColor: itemBg,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onRefresh();
                  },
                ),
              ],
              for (final item in extraItems) ...[
                const SizedBox(height: 10),
                _DxmTopMenuItem(
                  icon: item.icon,
                  title: item.title,
                  subtitle: item.subtitle,
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                  backgroundColor: itemBg,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    item.onTap();
                  },
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _DxmTopMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color subtitleColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _DxmTopMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.subtitleColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: titleColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: subtitleColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
