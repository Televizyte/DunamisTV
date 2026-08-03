import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:dunamis_tv/services/ads_service.dart';
import 'package:dunamis_tv/ui/widgets/ads/native_inline_ad_tile.dart';
import 'package:dunamis_tv/ui/widgets/banner_ad_widget.dart';

import '../../config/race_game_config.dart';
import '../../state/race_game_controller.dart';
import '../widgets/race_game_canvas.dart';
import '../widgets/race_home_panel.dart';
import '../widgets/race_level_selector_sheet.dart';
import '../widgets/race_settings_sheet.dart';

class RaceOfFaithScreen extends StatefulWidget {
  final RaceGameConfig config;

  const RaceOfFaithScreen({super.key, this.config = const RaceGameConfig()});

  @override
  State<RaceOfFaithScreen> createState() => _RaceOfFaithScreenState();
}

class _RaceOfFaithScreenState extends State<RaceOfFaithScreen> {
  late final RaceGameController _controller;

  RaceGameConfig get _config => widget.config;

  @override
  void initState() {
    super.initState();
    _controller = RaceGameController(config: _config);
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = _config.theme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: theme.midnight,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: theme.midnight,
            foregroundColor: Colors.white,
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _config.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  'Premium Runner Engine',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.58),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Race Settings',
                onPressed: () => RaceSettingsSheet.show(
                  context,
                  controller: _controller,
                  theme: theme,
                ),
                icon: const Icon(Icons.settings_rounded),
              ),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: theme.heroGradient),
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned.fill(
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Expanded(child: _buildBody(context)),
                      if (!_controller.isRunning)
                        _BottomRaceAd(tabKey: _config.adsTabKey),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    final isHome = _controller.mode == RaceScreenMode.home ||
        _controller.mode == RaceScreenMode.gameOver;

    if (!isHome) {
      return Column(
        children: [
          if (_controller.isRunning)
            _RaceBanner(
              tabKey: _config.adsTabKey,
              fallbackTabKeys: const ['game', 'games', 'explore'],
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              bottomBorder: true,
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child:
                  RaceGameCanvas(controller: _controller, theme: _config.theme),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
      children: [
        _RaceBanner(
          tabKey: _config.adsTabKey,
          fallbackTabKeys: const ['game', 'games', 'explore'],
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
        ),
        RaceHomePanel(
          config: _config,
          controller: _controller,
          onStart: () => _controller.startRun(),
          onChooseLevels: () => RaceLevelSelectorSheet.show(
            context,
            controller: _controller,
            theme: _config.theme,
            adsTabKey: _config.adsTabKey,
          ),
        ),
        const SizedBox(height: 14),
        if (kIsWeb ||
            AdsService.instance.nativeAllowedForTab(_config.adsTabKey))
          NativeInlineAdTile(
            tabKey: _config.adsTabKey,
            label: 'Race of Faith Sponsored',
            minHeight: 112,
          ),
      ],
    );
  }
}

class _RaceBanner extends StatelessWidget {
  final String tabKey;
  final List<String> fallbackTabKeys;
  final EdgeInsetsGeometry padding;
  final bool topBorder;
  final bool bottomBorder;

  const _RaceBanner({
    required this.tabKey,
    this.fallbackTabKeys = const [],
    this.padding = const EdgeInsets.fromLTRB(10, 6, 10, 6),
    this.topBorder = false,
    this.bottomBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveKey = _allowedBannerKey();
    if (effectiveKey == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        border: Border(
          top: topBorder
              ? BorderSide(color: Colors.white.withOpacity(0.08))
              : BorderSide.none,
          bottom: bottomBorder
              ? BorderSide(color: Colors.white.withOpacity(0.08))
              : BorderSide.none,
        ),
      ),
      child: BannerAdWidget(
        tabKey: effectiveKey,
        padding: padding,
      ),
    );
  }

  String? _allowedBannerKey() {
    final keys = <String>[
      tabKey,
      ...fallbackTabKeys,
    ];

    for (final key in keys) {
      final normalized = key.trim();
      if (normalized.isEmpty) continue;
      try {
        if (AdsService.instance.bannerAllowedForTab(normalized)) {
          return normalized;
        }
      } catch (_) {}
    }

    return null;
  }
}

class _BottomRaceAd extends StatelessWidget {
  final String tabKey;

  const _BottomRaceAd({required this.tabKey});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: _RaceBanner(
        tabKey: tabKey,
        fallbackTabKeys: const ['game', 'games', 'explore'],
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 7),
        topBorder: true,
      ),
    );
  }
}
