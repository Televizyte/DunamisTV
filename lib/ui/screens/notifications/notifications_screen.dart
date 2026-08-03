import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../services/ads_service.dart';
import '../../../services/notification_bootstrap_service.dart';
import '../../../theme/theme_controller.dart';
import '../../shell/bottom_shell.dart';
import '../../widgets/ads/native_inline_ad_tile.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  bool _openedInitialMessage = false;
  List<Map<String, dynamic>> _messages = const [];

  @override
  void initState() {
    super.initState();
    AdsService.instance.preloadInterstitial(tabKey: 'notification.open');
    _loadInbox();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSilently());
  }

  Future<void> _syncSilently() async {
    try {
      await NotificationBootstrapService.instance.retryTokenSync();
      await _loadInbox();
    } catch (_) {}
  }

  Future<void> _loadInbox() async {
    if (mounted) setState(() => _loading = true);
    final messages =
        await NotificationBootstrapService.instance.readStoredMessages();
    if (!mounted) return;
    setState(() {
      _messages = messages;
      _loading = false;
    });
    _maybeOpenLatestFromQuery();
  }

  Future<void> _clearInbox() async {
    await NotificationBootstrapService.instance.clearStoredMessages();
    await _loadInbox();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications cleared.')),
    );
  }

  Future<void> _openMessage(Map<String, dynamic> item) async {
    await AdsService.instance.maybeShowInterstitialOnSafeNav(
      context,
      tabKey: 'notification.open',
    );
    if (!mounted) return;
    context.push('/notifications/message', extra: item);
  }

  void _maybeOpenLatestFromQuery() {
    if (_openedInitialMessage || _messages.isEmpty || !mounted) return;
    final uri = GoRouterState.of(context).uri;
    if (uri.queryParameters['open'] == 'latest') {
      _openedInitialMessage = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _messages.isNotEmpty) _openMessage(_messages.first);
      });
    }
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
        final nativeAllowed =
            AdsService.instance.nativeInListAllowedForTab('more.notifications');

        return Scaffold(
          appBar: DxmTopBar(
            title: 'Notifications',
            showBack: true,
            showMenu: true,
            onRefresh: _loadInbox,
            extraMenuItems: [
              DxmTopBarMenuEntry(
                icon: Icons.delete_outline_rounded,
                title: 'Clear Notifications',
                subtitle: 'Remove messages saved on this device',
                onTap: _clearInbox,
              ),
            ],
          ),
          bottomNavigationBar:
              const BannerAdWidget(tabKey: 'more.notifications'),
          body: GradientPageBackground(
            child: RefreshIndicator(
              onRefresh: _loadInbox,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                    14, 8, 14, BottomShellInsets.of(context) + 12),
                children: [
                  _InboxIntroCard(
                    total: _messages.length,
                    panelBg: panelBg,
                    border: border,
                    titleColor: titleColor,
                    bodyColor: bodyColor,
                  ),
                  const SizedBox(height: 14),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_messages.isEmpty)
                    _EmptyInboxCard(
                      panelBg: panelBg,
                      border: border,
                      titleColor: titleColor,
                      bodyColor: bodyColor,
                    )
                  else
                    for (var index = 0; index < _messages.length; index++) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _NotificationCard(
                          item: _messages[index],
                          panelBg: panelBg,
                          border: border,
                          titleColor: titleColor,
                          bodyColor: bodyColor,
                          onTap: () => _openMessage(_messages[index]),
                        ),
                      ),
                      if (nativeAllowed &&
                          (AdsService.instance.shouldInsertNativeAfterItem(
                                tabKey: 'more.notifications',
                                itemIndex: index,
                              ) ||
                              (_messages.length <= 4 && index == 1)))
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: NativeInlineAdTile(
                            tabKey: 'more.notifications',
                            label: 'Sponsored',
                            minHeight: 120,
                          ),
                        ),
                    ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InboxIntroCard extends StatelessWidget {
  final int total;
  final Color panelBg, border, titleColor, bodyColor;
  const _InboxIntroCard(
      {required this.total,
      required this.panelBg,
      required this.border,
      required this.titleColor,
      required this.bodyColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: panelBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border)),
      child: Row(children: [
        Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                    colors: [Color(0xFF1A1F5A), Color(0xFFB70E7C)])),
            child: const Icon(Icons.notifications_active_rounded,
                color: Colors.white, size: 26)),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(total > 0 ? 'Latest Updates' : 'Notification Inbox',
              style: TextStyle(
                  color: titleColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
              total > 0
                  ? '$total saved notification${total == 1 ? '' : 's'} with media and message previews.'
                  : 'Announcements, devotionals, programs, and important updates will appear here.',
              style: TextStyle(
                  color: bodyColor,
                  fontSize: 12.8,
                  height: 1.35,
                  fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }
}

class _EmptyInboxCard extends StatelessWidget {
  final Color panelBg, border, titleColor, bodyColor;
  const _EmptyInboxCard(
      {required this.panelBg,
      required this.border,
      required this.titleColor,
      required this.bodyColor});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
            color: panelBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border)),
        child: Column(children: [
          Icon(Icons.notifications_none_rounded, color: titleColor, size: 38),
          const SizedBox(height: 12),
          Text('No notifications yet',
              style: TextStyle(
                  color: titleColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
              'Ministry announcements, live program reminders, devotionals, and updates will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: bodyColor,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color panelBg, border, titleColor, bodyColor;
  final VoidCallback onTap;
  const _NotificationCard(
      {required this.item,
      required this.panelBg,
      required this.border,
      required this.titleColor,
      required this.bodyColor,
      required this.onTap});

  String _first(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final data = item['data'] is Map ? item['data'] as Map : const {};
    final title = _first([item['title'], 'Notification']);
    final body = _first([item['body'], item['message']]);
    final imageUrl = _first([
      item['image_url'],
      item['image'],
      data['image_url'],
      data['image'],
      data['thumbnail_url'],
      data['thumbnail']
    ]);
    final sentTime = _formatSentTime(
        _first([item['sent_time'], item['created_at'], item['received_at']]));

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
              color: panelBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border)),
          child: SizedBox(
              height: 132,
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                SizedBox(
                  width: 108,
                  height: 132,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(19)),
                    child: imageUrl.isEmpty
                        ? const _MediaFallback()
                        : Image.network(imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _MediaFallback()),
                  ),
                ),
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 12, 12, 11),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: titleColor,
                                fontSize: 13.8,
                                height: 1.2,
                                fontWeight: FontWeight.w900)),
                        if (body.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: bodyColor,
                                  fontSize: 12.2,
                                  height: 1.34,
                                  fontWeight: FontWeight.w600)),
                        ],
                        const Spacer(),
                        Row(children: [
                          if (sentTime.isNotEmpty)
                            Expanded(
                                child: Text(sentTime,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: bodyColor.withOpacity(0.72),
                                        fontSize: 10.8,
                                        fontWeight: FontWeight.w700))),
                          Icon(Icons.chevron_right_rounded,
                              color: titleColor.withOpacity(0.72), size: 20),
                        ]),
                      ]),
                )),
              ])),
        ),
      ),
    );
  }

  String _formatSentTime(String value) {
    if (value.isEmpty) return '';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final local = parsed.toLocal();
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} • ${local.hour}:$minute';
  }
}

class _MediaFallback extends StatelessWidget {
  const _MediaFallback();
  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF171D45),
        alignment: Alignment.center,
        child: const Icon(Icons.notifications_active_rounded,
            color: Color(0xFFFF4DB8), size: 34),
      );
}
