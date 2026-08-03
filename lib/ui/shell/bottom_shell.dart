import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_config.dart';
import '../../features/hub/models/dynamic_tab.dart';
import '../../features/hub/state/hub_scope.dart';
import '../../features/hub/state/hub_tab_registry.dart';
import '../../services/ads_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/gradient_page_background.dart';

class BottomShellInsets extends InheritedWidget {
  final double bottomInset;

  const BottomShellInsets({
    super.key,
    required super.child,
    required this.bottomInset,
  });

  static double of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<BottomShellInsets>();
    return w?.bottomInset ?? 0;
  }

  @override
  bool updateShouldNotify(covariant BottomShellInsets oldWidget) =>
      bottomInset != oldWidget.bottomInset;
}

class BottomShell extends StatefulWidget {
  final Widget child;

  const BottomShell({
    super.key,
    required this.child,
  });

  @override
  State<BottomShell> createState() => _BottomShellState();
}

class _BottomShellState extends State<BottomShell> {
  List<HubDynamicTab> _tabs(BuildContext context) {
    final hub = HubScope.of(context);
    final resolved = HubTabRegistry.resolveTabs(hub)
        .where((tab) => tab.enabled && tab.visible && tab.showInBottomNav)
        .toList(growable: false);

    if (resolved.isNotEmpty) {
      return resolved.take(5).toList(growable: false);
    }

    return _defaultTabs;
  }

  int _indexFromLocation(String loc, List<HubDynamicTab> tabs) {
    final cleanLoc = loc.split('?').first.trim();

    for (var i = 0; i < tabs.length; i++) {
      final route = tabs[i].route.trim();

      if (route == '/') {
        if (cleanLoc == '/') return i;
        continue;
      }

      if (route.isNotEmpty && cleanLoc.startsWith(route)) {
        return i;
      }
    }

    if (cleanLoc.startsWith('/watch')) return _indexOfKey(tabs, 'watch');
    if (cleanLoc.startsWith('/inspire')) return _indexOfKey(tabs, 'inspire');
    if (cleanLoc.startsWith('/explore')) return _indexOfKey(tabs, 'explore');
    if (cleanLoc.startsWith('/more')) return _indexOfKey(tabs, 'more');

    return 0;
  }

  int _indexOfKey(List<HubDynamicTab> tabs, String key) {
    final index = tabs.indexWhere(
      (tab) => tab.key.trim().toLowerCase() == key.trim().toLowerCase(),
    );

    return index < 0 ? 0 : index;
  }

  String _tabKeyFromIndex(List<HubDynamicTab> tabs, int index) {
    if (index < 0 || index >= tabs.length) {
      return 'home';
    }

    final key = tabs[index].key.trim().toLowerCase();
    return key.isNotEmpty ? key : 'home';
  }

  void _goToIndex(BuildContext context, List<HubDynamicTab> tabs, int index) {
    if (index < 0 || index >= tabs.length) return;

    final tab = tabs[index];
    final route = tab.route.trim();

    if (route.isNotEmpty) {
      context.go(route);
      return;
    }

    final key = tab.key.trim().toLowerCase();

    switch (key) {
      case 'home':
        context.go('/');
        break;
      case 'watch':
        context.go('/watch');
        break;
      case 'inspire':
        context.go('/inspire');
        break;
      case 'explore':
        context.go('/explore');
        break;
      case 'more':
        context.go('/more');
        break;
      default:
        context.go('/tab/$key');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs(context);
    final loc = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFromLocation(loc, tabs);
    final tabKey = _tabKeyFromIndex(tabs, currentIndex);

    final bannerAllowed = AdsService.instance.bannerAllowedForTab(tabKey);

    const navH = kBottomNavigationBarHeight;
    final bannerH = bannerAllowed ? 66.0 : 0.0;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final reserved = navH + bannerH + safeBottom;

    return BottomShellInsets(
      bottomInset: reserved,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GradientPageBackground(
          child: widget.child,
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BottomNav(
              tabs: tabs,
              currentIndex: currentIndex,
              onTap: (i) => _goToIndex(context, tabs, i),
            ),
            BannerAdWidget(
              tabKey: tabKey,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final List<HubDynamicTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeTabs = tabs.isNotEmpty ? tabs : _defaultTabs;
    final safeIndex = currentIndex.clamp(0, safeTabs.length - 1);

    return BottomNavigationBar(
      currentIndex: safeIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF070B17),
      selectedItemColor: const Color(0xFFFF4DB8),
      unselectedItemColor: Colors.white.withOpacity(0.55),
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w800,
      ),
      items: safeTabs
          .map(
            (tab) => BottomNavigationBarItem(
              icon: Icon(tab.iconData),
              label: _safeLabel(tab),
            ),
          )
          .toList(growable: false),
    );
  }

  String _safeLabel(HubDynamicTab tab) {
    final label = tab.label.trim();
    if (label.isNotEmpty) return label;

    final title = tab.title.trim();
    if (title.isNotEmpty) return title;

    return 'Tab';
  }
}

final List<HubDynamicTab> _defaultTabs = [
  HubDynamicTab(
    key: 'home',
    label: AppConfig.tabHomeLabel,
    title: AppConfig.tabHomeLabel,
    subtitle: '',
    icon: 'home',
    route: '/',
    type: 'native',
    enabled: true,
    visible: true,
    showInBottomNav: true,
    startup: true,
    order: 0,
    sections: const [],
    settings: const {},
  ),
  HubDynamicTab(
    key: 'watch',
    label: AppConfig.tabWatchLabel,
    title: AppConfig.tabWatchLabel,
    subtitle: '',
    icon: 'watch',
    route: '/watch',
    type: 'native',
    enabled: true,
    visible: true,
    showInBottomNav: true,
    startup: false,
    order: 1,
    sections: const [],
    settings: const {},
  ),
  HubDynamicTab(
    key: 'inspire',
    label: AppConfig.tabInspireLabel,
    title: AppConfig.tabInspireLabel,
    subtitle: '',
    icon: 'inspire',
    route: '/inspire',
    type: 'native',
    enabled: true,
    visible: true,
    showInBottomNav: true,
    startup: false,
    order: 2,
    sections: const [],
    settings: const {},
  ),
  HubDynamicTab(
    key: 'explore',
    label: AppConfig.tabExploreLabel,
    title: AppConfig.tabExploreLabel,
    subtitle: '',
    icon: 'explore',
    route: '/explore',
    type: 'native',
    enabled: true,
    visible: true,
    showInBottomNav: true,
    startup: false,
    order: 3,
    sections: const [],
    settings: const {},
  ),
  HubDynamicTab(
    key: 'more',
    label: AppConfig.tabMoreLabel,
    title: AppConfig.tabMoreLabel,
    subtitle: '',
    icon: 'more',
    route: '/more',
    type: 'native',
    enabled: true,
    visible: true,
    showInBottomNav: true,
    startup: false,
    order: 4,
    sections: const [],
    settings: const {},
  ),
];
