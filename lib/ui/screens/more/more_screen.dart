import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/app_profile_service.dart';
import '../../../services/ads_service.dart';
import '../../../theme/theme_controller.dart';
import '../../shell/bottom_shell.dart';
import '../../widgets/ads/native_inline_ad_tile.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/gradient_page_background.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _openSafeRoute(
    BuildContext context, {
    required String actionKey,
    required String route,
  }) async {
    await AdsService.instance.maybeShowInterstitialOnSafeNav(
      context,
      tabKey: actionKey,
    );
    if (!context.mounted) return;
    context.push(route);
  }

  void _openWeb(
    BuildContext context, {
    required String title,
    required String url,
  }) {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title is not available yet.')),
      );
      return;
    }

    context.push('/web', extra: {
      'title': title,
      'url': cleanUrl,
    });
  }

  Future<void> _openExternal(BuildContext context, String value) async {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This destination could not be opened.')),
      );
    }
  }

  void _handleLinkTap(
    BuildContext context, {
    required String title,
    required String value,
    required String type,
  }) {
    final cleanValue = value.trim();
    final cleanType = type.trim().toLowerCase();

    if (cleanValue.isEmpty) return;

    if (cleanType == 'internal_route' && cleanValue.startsWith('/')) {
      context.push(cleanValue);
      return;
    }
    if (cleanType == 'email') {
      _openExternal(context, 'mailto:$cleanValue');
      return;
    }
    if (cleanType == 'phone' || cleanType == 'tel') {
      _openExternal(context, 'tel:$cleanValue');
      return;
    }

    final looksLikeUrl = cleanValue.startsWith('http://') ||
        cleanValue.startsWith('https://') ||
        cleanValue.startsWith('www.');

    if (looksLikeUrl || cleanType == 'url' || cleanType == 'web') {
      _openWeb(context, title: title, url: cleanValue);
      return;
    }

    Share.share(cleanValue);
  }

  void _showInfoSheet(
    BuildContext context,
    AppPublicProfile profile,
    bool isLight,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0D1228),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.86,
          minChildSize: 0.35,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              children: [
                Text(
                  'About ${profile.displayName}',
                  style: TextStyle(
                    color: isLight ? const Color(0xFF1E1B16) : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  profile.tagline,
                  style: TextStyle(
                    color: isLight
                        ? const Color(0xFF6B6256)
                        : Colors.white.withOpacity(0.72),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  profile.about,
                  style: TextStyle(
                    color: isLight
                        ? const Color(0xFF3E382F)
                        : Colors.white.withOpacity(0.86),
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSupportSheet(
    BuildContext context,
    AppPublicProfile profile,
    bool isLight,
  ) {
    _showDynamicLinksSheet(
      context,
      title: 'Contact / Support',
      emptyText:
          'Support channels are managed from AppsHub App Settings. Add church support, technical support, prayer line, or any custom contact there.',
      links: profile.enabledSupportChannels,
      isLight: isLight,
    );
  }

  void _showOfficialLinksSheet(
    BuildContext context,
    AppPublicProfile profile,
    bool isLight,
  ) {
    _showDynamicLinksSheet(
      context,
      title: 'Official Links',
      emptyText:
          'Official links are managed from AppsHub App Settings. Add YouTube, Facebook, Instagram, X, WhatsApp Channel, TikTok, or any custom link there.',
      links: profile.enabledOfficialLinks,
      isLight: isLight,
    );
  }

  void _showCustomSettingsSheet(
    BuildContext context,
    AppPublicProfile profile,
    bool isLight,
  ) {
    final settings = profile.enabledCustomSettings;

    final titleColor = isLight ? const Color(0xFF1E1B16) : Colors.white;
    final bodyColor =
        isLight ? const Color(0xFF6B6256) : Colors.white.withOpacity(0.76);
    final itemBg =
        isLight ? const Color(0xFFF2E8D8) : Colors.white.withOpacity(0.05);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0D1228),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Public Information',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  settings.isEmpty
                      ? 'Custom public settings will appear here when added in AppsHub.'
                      : 'Extra public information managed from AppsHub.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: bodyColor,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                for (final item in settings)
                  _SheetAction(
                    icon: _iconForKey(item.icon, fallback: item.key),
                    title: item.label,
                    subtitle: item.description.trim().isNotEmpty
                        ? '${item.description}\n${item.value}'
                        : item.value,
                    backgroundColor: itemBg,
                    titleColor: titleColor,
                    bodyColor: bodyColor,
                    onTap: () {
                      Navigator.of(context).pop();
                      _handleLinkTap(
                        context,
                        title: item.label,
                        value: item.value,
                        type: item.type,
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

  void _showDynamicLinksSheet(
    BuildContext context, {
    required String title,
    required String emptyText,
    required List<AppPublicLink> links,
    required bool isLight,
  }) {
    final titleColor = isLight ? const Color(0xFF1E1B16) : Colors.white;
    final bodyColor =
        isLight ? const Color(0xFF6B6256) : Colors.white.withOpacity(0.76);
    final itemBg =
        isLight ? const Color(0xFFF2E8D8) : Colors.white.withOpacity(0.05);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0D1228),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  links.isEmpty ? emptyText : 'Open official app information.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: bodyColor,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                for (final item in links)
                  _SheetAction(
                    icon: _iconForKey(item.icon, fallback: item.key),
                    title: item.label,
                    subtitle: item.description.trim().isNotEmpty
                        ? '${item.description}\n${item.value}'
                        : item.value,
                    backgroundColor: itemBg,
                    titleColor: titleColor,
                    bodyColor: bodyColor,
                    onTap: () {
                      Navigator.of(context).pop();
                      _handleLinkTap(
                        context,
                        title: item.label,
                        value: item.value,
                        type: item.type,
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

  void _openDeveloperCard(BuildContext context, bool isLight) {
    final titleColor = isLight ? const Color(0xFF1E1B16) : Colors.white;
    final bodyColor =
        isLight ? const Color(0xFF6B6256) : Colors.white.withOpacity(0.76);
    final itemBg =
        isLight ? const Color(0xFFF2E8D8) : Colors.white.withOpacity(0.05);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0D1228),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Build an app like this',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'DigitXtra Media builds mobile apps, TV platforms, websites, and digital media systems.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: bodyColor,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _SheetAction(
                  icon: Icons.public_rounded,
                  title: 'DigitXtra Media',
                  subtitle: 'https://digitxtramedia.com',
                  backgroundColor: itemBg,
                  titleColor: titleColor,
                  bodyColor: bodyColor,
                  onTap: () {
                    Navigator.of(context).pop();
                    _openWeb(
                      context,
                      title: 'DigitXtra Media',
                      url: 'https://digitxtramedia.com',
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

  Widget _sectionTitle(String title, bool isLight) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: isLight
              ? const Color(0xFF1E1B16)
              : Colors.white.withOpacity(0.92),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool signedIn = false;

    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final isLight = ThemeController.instance.isLightMode;

        return FutureBuilder<AppPublicProfile>(
          future: AppProfileService.instance.getProfile(),
          builder: (context, snapshot) {
            final profile = snapshot.data ?? AppPublicProfile.fallback();

            return Scaffold(
              backgroundColor:
                  isLight ? const Color(0xFFF7F1E6) : Colors.transparent,
              appBar: const DxmTopBar(
                title: 'More',
                showMenu: true,
              ),
              body: GradientPageBackground(
                child: Container(
                  color: isLight ? const Color(0xFFF7F1E6) : Colors.transparent,
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await AppProfileService.instance
                          .getProfile(refresh: true);
                    },
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        14,
                        8,
                        14,
                        BottomShellInsets.of(context) + 12,
                      ),
                      children: [
                        _ProfileHeaderCard(profile: profile),
                        _sectionTitle('Account & Community', isLight),
                        FeatureCard(
                          title: signedIn ? 'Profile' : 'Login / Register',
                          subtitle: signedIn
                              ? 'Manage your account'
                              : 'Sign in to like, comment and follow',
                          icon: signedIn
                              ? Icons.person_rounded
                              : Icons.login_rounded,
                          onTap: () => context.push('/account'),
                        ),
                        const SizedBox(height: 12),
                        FeatureCard(
                          title: 'Saved',
                          subtitle: 'Bookmarks and saved Bible verses',
                          icon: Icons.bookmark_rounded,
                          onTap: () => _openSafeRoute(context,
                              actionKey: 'more.saved.open', route: '/saved'),
                        ),
                        const SizedBox(height: 12),
                        FeatureCard(
                          title: 'Downloads',
                          subtitle: 'Offline items saved on this device',
                          icon: Icons.download_rounded,
                          onTap: () => _openSafeRoute(context,
                              actionKey: 'more.downloads.open',
                              route: '/downloads'),
                        ),
                        const SizedBox(height: 12),
                        FeatureCard(
                          title: 'Notifications',
                          subtitle: 'Announcements and app updates',
                          icon: Icons.notifications_rounded,
                          onTap: () => _openSafeRoute(context,
                              actionKey: 'more.notifications.open',
                              route: '/notifications'),
                        ),
                        const SizedBox(height: 14),
                        const NativeInlineAdTile(
                            tabKey: 'more', label: 'Sponsored', minHeight: 120),
                        _sectionTitle('Help & Information', isLight),
                        FeatureCard(
                          title: 'Technical Support',
                          subtitle: 'Help, knowledge base and support requests',
                          icon: Icons.support_agent_rounded,
                          onTap: () => context.push('/more/technical-support'),
                        ),
                        const SizedBox(height: 12),
                        FeatureCard(
                          title: 'About the Ministry',
                          subtitle:
                              'Ministry profile, contacts and official links',
                          icon: Icons.church_rounded,
                          onTap: () => context.push('/more/about-ministry'),
                        ),
                        const SizedBox(height: 12),
                        FeatureCard(
                          title: 'About ${profile.displayName}',
                          subtitle: 'App information, operator and version',
                          icon: Icons.info_outline_rounded,
                          onTap: () => context.push('/more/about-app'),
                        ),
                        const SizedBox(height: 12),
                        FeatureCard(
                          title: 'Legal & Policies',
                          subtitle:
                              'Privacy, terms, account deletion and policies',
                          icon: Icons.gavel_rounded,
                          onTap: () => context.push('/more/legal'),
                        ),
                        _sectionTitle('App Controls', isLight),
                        FeatureCard(
                          title: 'Settings',
                          subtitle: 'Theme, notifications and playback',
                          icon: Icons.settings_rounded,
                          onTap: () => _openSafeRoute(context,
                              actionKey: 'more.settings.open',
                              route: '/settings'),
                        ),
                        const SizedBox(height: 12),
                        FeatureCard(
                          title: 'Share App',
                          subtitle: 'Share ${profile.displayName}',
                          icon: Icons.share_rounded,
                          onTap: () => Share.share(
                            'Download ${profile.displayName} and be blessed.\n${profile.bestShareLink}',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FeatureCard(
                          title: 'Rate App',
                          subtitle: profile.hasPlayStore
                              ? 'Open Play Store rating page'
                              : 'Share this app with others',
                          icon: Icons.star_rate_rounded,
                          onTap: () async {
                            await AdsService.instance
                                .maybeShowInterstitialOnSafeNav(
                              context,
                              tabKey: 'more.rate.open',
                            );
                            if (!context.mounted) return;
                            if (profile.hasPlayStore) {
                              await _openExternal(
                                  context, profile.playStoreUrl);
                            } else {
                              Share.share(
                                  'Download ${profile.displayName} and be blessed.\n${profile.bestShareLink}');
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        _DeveloperPromoCard(
                          onTap: () => context.push('/more/build-with-dxm'),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: Text(
                            profile.versionName.trim().isEmpty
                                ? ''
                                : 'v${profile.versionName}${profile.versionCode.trim().isEmpty ? '' : ' (${profile.versionCode})'}',
                            style: TextStyle(
                              color: isLight
                                  ? const Color(0xFF6B6256)
                                  : Colors.white.withOpacity(0.65),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static IconData _iconForKey(String icon, {String fallback = ''}) {
    final key = icon.trim().toLowerCase().isNotEmpty
        ? icon.trim().toLowerCase()
        : fallback.trim().toLowerCase();

    switch (key) {
      case 'facebook':
        return Icons.facebook_rounded;
      case 'youtube':
      case 'video':
      case 'play':
        return Icons.play_circle_fill_rounded;
      case 'instagram':
      case 'camera':
        return Icons.camera_alt_rounded;
      case 'x':
      case 'twitter':
        return Icons.alternate_email_rounded;
      case 'whatsapp':
      case 'chat':
        return Icons.chat_rounded;
      case 'telegram':
      case 'send':
        return Icons.send_rounded;
      case 'tiktok':
      case 'music':
        return Icons.music_note_rounded;
      case 'website':
      case 'web':
      case 'public':
        return Icons.public_rounded;
      case 'email':
      case 'mail':
        return Icons.email_rounded;
      case 'phone':
      case 'call':
        return Icons.phone_rounded;
      case 'support':
      case 'technical_support':
        return Icons.support_agent_rounded;
      case 'church':
      case 'ministry':
        return Icons.church_rounded;
      case 'prayer':
        return Icons.volunteer_activism_rounded;
      case 'testimony':
        return Icons.record_voice_over_rounded;
      case 'address':
      case 'location':
        return Icons.location_on_rounded;
      case 'store':
      case 'play_store':
        return Icons.shop_rounded;
      case 'privacy':
        return Icons.privacy_tip_rounded;
      case 'terms':
      case 'legal':
        return Icons.gavel_rounded;
      case 'info':
        return Icons.info_outline_rounded;
      default:
        return Icons.link_rounded;
    }
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final AppPublicProfile profile;

  const _ProfileHeaderCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isLight = ThemeController.instance.isLightMode;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F5A), Color(0xFF5B1FA8), Color(0xFFB70E7C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(isLight ? 0.16 : 0.22),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.live_tv_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile.tagline,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.86),
                    fontSize: 12.8,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color titleColor;
  final Color bodyColor;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.titleColor,
    required this.bodyColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
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
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
                      if (subtitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: bodyColor,
                            fontSize: 12,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: titleColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeveloperPromoCard extends StatelessWidget {
  final VoidCallback onTap;

  const _DeveloperPromoCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1F5A), Color(0xFFB70E7C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.18),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Build an app like this',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Powered by DigitXtra Media.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.88),
                          fontSize: 12.6,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
