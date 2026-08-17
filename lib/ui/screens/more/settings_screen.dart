import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/ad_consent_service.dart';
import '../../../theme/theme_controller.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _notifyKey = 'dxm_user_notification_updates_enabled';
  static const String _wifiOnlyKey = 'dxm_user_playback_wifi_only';
  static const String _autoPlayKey = 'dxm_user_playback_auto_play';

  bool _notifications = true;
  bool _wifiOnly = false;
  bool _autoPlay = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifications = prefs.getBool(_notifyKey) ?? true;
      _wifiOnly = prefs.getBool(_wifiOnlyKey) ?? false;
      _autoPlay = prefs.getBool(_autoPlayKey) ?? true;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final isLight = ThemeController.instance.isLightMode;
        final panelBg =
            isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430);
        final border =
            isLight ? const Color(0xFFE6D8C3) : Colors.white.withOpacity(0.08);
        final titleColor =
            isLight ? const Color(0xFF1E1B16) : Colors.white.withOpacity(0.94);
        final bodyColor =
            isLight ? const Color(0xFF6B6256) : Colors.white.withOpacity(0.72);

        return Scaffold(
          appBar: const DxmTopBar(
              title: 'Settings', showBack: true, showMenu: true),
          body: GradientPageBackground(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
              children: [
                _SettingsTile(
                    panelBg: panelBg,
                    border: border,
                    titleColor: titleColor,
                    bodyColor: bodyColor,
                    title: 'Theme Mode',
                    subtitle: ThemeController.instance.isLightMode
                        ? 'Currently using Light Mode'
                        : 'Currently using Dark Mode',
                    icon: ThemeController.instance.isLightMode
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    trailing: Switch(
                        value: ThemeController.instance.isLightMode,
                        onChanged: (_) =>
                            ThemeController.instance.toggleTheme())),
                const SizedBox(height: 12),
                _SettingsTile(
                    panelBg: panelBg,
                    border: border,
                    titleColor: titleColor,
                    bodyColor: bodyColor,
                    title: 'Notification Updates',
                    subtitle:
                        'Receive ministry announcements, devotionals, and important app updates.',
                    icon: Icons.notifications_active_rounded,
                    trailing: Switch(
                        value: _notifications,
                        onChanged: (value) {
                          setState(() => _notifications = value);
                          _saveBool(_notifyKey, value);
                        })),
                const SizedBox(height: 12),
                _SettingsTile(
                    panelBg: panelBg,
                    border: border,
                    titleColor: titleColor,
                    bodyColor: bodyColor,
                    title: 'Auto-play Videos',
                    subtitle:
                        'Allow supported video pages to begin playback automatically when possible.',
                    icon: Icons.play_circle_outline_rounded,
                    trailing: Switch(
                        value: _autoPlay,
                        onChanged: (value) {
                          setState(() => _autoPlay = value);
                          _saveBool(_autoPlayKey, value);
                        })),
                const SizedBox(height: 12),
                _SettingsTile(
                    panelBg: panelBg,
                    border: border,
                    titleColor: titleColor,
                    bodyColor: bodyColor,
                    title: 'Wi-Fi Friendly Playback',
                    subtitle:
                        'Prefer stable playback behavior for heavier videos and live streams.',
                    icon: Icons.wifi_rounded,
                    trailing: Switch(
                        value: _wifiOnly,
                        onChanged: (value) {
                          setState(() => _wifiOnly = value);
                          _saveBool(_wifiOnlyKey, value);
                        })),
                AnimatedBuilder(
                  animation: AdConsentService.instance,
                  builder: (context, _) {
                    if (!AdConsentService.instance.privacyOptionsRequired) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        const SizedBox(height: 12),
                        _SettingsTile(
                          panelBg: panelBg,
                          border: border,
                          titleColor: titleColor,
                          bodyColor: bodyColor,
                          title: 'Ad privacy choices',
                          subtitle:
                              'Review or update your advertising privacy choices.',
                          icon: Icons.privacy_tip_outlined,
                          onTap: _showAdPrivacyChoices,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAdPrivacyChoices() async {
    final shown = await AdConsentService.instance.showPrivacyOptions();
    if (!mounted || shown) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ad privacy choices are unavailable.')),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final Color panelBg, border, titleColor, bodyColor;
  final String title, subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsTile(
      {required this.panelBg,
      required this.border,
      required this.titleColor,
      required this.bodyColor,
      required this.title,
      required this.subtitle,
      required this.icon,
      this.trailing,
      this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: panelBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border)),
          child: Row(children: [
            Icon(icon, color: titleColor, size: 24),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: TextStyle(
                          color: titleColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: TextStyle(
                          color: bodyColor,
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600)),
                ])),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ]),
        ),
      ),
    );
  }
}
