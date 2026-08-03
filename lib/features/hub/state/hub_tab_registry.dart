import '../models/dynamic_section.dart';
import '../models/dynamic_tab.dart';
import '../registry/renderer_registry.dart';
import 'hub_store.dart';

class HubTabRegistry {
  static List<HubDynamicTab> resolveTabs(HubStore store) {
    final raw = store.raw;

    final backendTabs = _extractBackendTabs(raw)
        .map(
          (tab) => tab.sections.isNotEmpty
              ? tab
              : tab.copyWith(
                  sections: _sectionsFor(store, tab.key),
                ),
        )
        .where((tab) => tab.enabled)
        .where((tab) => _tabAllowedByCapabilities(store, tab.key))
        .toList(growable: false);

    if (backendTabs.isNotEmpty) {
      final sorted = [...backendTabs]
        ..sort((a, b) => a.order.compareTo(b.order));

      return sorted;
    }

    return _fallbackTabs(store);
  }

  static List<HubDynamicTab> _extractBackendTabs(
    Map<String, dynamic> raw,
  ) {
    final candidates = <dynamic>[
      raw['tabs'],
      raw['bottom_tabs'],
      raw['bottom_navigation'],
      raw['tab_navigation'],
      raw['app_tabs'],
      _tabsInsideMap(raw['navigation']),
      _tabsInsideMap(raw['nav']),
      _tabsInsideMap(raw['menu']),
      _tabsInsideMap(raw['app']),
      _tabsInsideMap(raw['bootstrap']),
      _tabsInsideMap(raw['data']),
    ];

    for (final candidate in candidates) {
      final tabs = hubDynamicTabsFromRaw(candidate);

      if (tabs.isNotEmpty) {
        return tabs;
      }
    }

    return const [];
  }

  static dynamic _tabsInsideMap(dynamic value) {
    if (value is! Map) {
      return null;
    }

    return value['tabs'] ??
        value['items'] ??
        value['bottom_tabs'] ??
        value['bottom_navigation'] ??
        value['tab_navigation'] ??
        value['app_tabs'];
  }

  static List<HubDynamicTab> _fallbackTabs(
    HubStore store,
  ) {
    final tabs = [
      HubDynamicTab(
        key: 'home',
        label: 'Home',
        title: 'Home',
        subtitle: '',
        icon: 'home',
        route: '/',
        type: 'native',
        enabled: true,
        visible: true,
        showInBottomNav: true,
        startup: true,
        order: 0,
        sections: _sectionsFor(store, 'home'),
        settings: const {},
      ),
      HubDynamicTab(
        key: 'watch',
        label: 'Watch',
        title: 'Watch',
        subtitle: '',
        icon: 'live_tv',
        route: '/watch',
        type: 'native',
        enabled: true,
        visible: true,
        showInBottomNav: true,
        startup: false,
        order: 1,
        sections: _sectionsFor(store, 'watch'),
        settings: const {},
      ),
      HubDynamicTab(
        key: 'inspire',
        label: 'Inspire',
        title: 'Inspire',
        subtitle: '',
        icon: 'auto_awesome',
        route: '/inspire',
        type: 'native',
        enabled: true,
        visible: true,
        showInBottomNav: true,
        startup: false,
        order: 2,
        sections: _sectionsFor(store, 'inspire'),
        settings: const {},
      ),
      HubDynamicTab(
        key: 'explore',
        label: 'Explore',
        title: 'Explore',
        subtitle: '',
        icon: 'explore',
        route: '/explore',
        type: 'native',
        enabled: true,
        visible: true,
        showInBottomNav: true,
        startup: false,
        order: 3,
        sections: _sectionsFor(store, 'explore'),
        settings: const {},
      ),
      const HubDynamicTab(
        key: 'more',
        label: 'More',
        title: 'More',
        subtitle: '',
        icon: 'more_horiz',
        route: '/more',
        type: 'native',
        enabled: true,
        visible: true,
        showInBottomNav: true,
        startup: false,
        order: 4,
        sections: [],
        settings: {},
      ),
    ];

    return tabs
        .where((tab) => _tabAllowedByCapabilities(store, tab.key))
        .toList(growable: false);
  }

  static bool _tabAllowedByCapabilities(
    HubStore store,
    String tabKey,
  ) {
    final key = tabKey.trim().toLowerCase();

    switch (key) {
      case 'watch':
        return store.capabilityEnabled(
          'watch_manager',
          aliases: const ['watch_links', 'enable_watch'],
        );
      case 'inspire':
        return store.capabilityEnabled('inspire_manager');
      case 'explore':
        return store.capabilityEnabled('explore_manager');
      case 'home':
        return store.capabilityEnabled('home_manager');
      case 'more':
        return true;
      default:
        return true;
    }
  }

  static List<HubDynamicSection> _sectionsFor(
    HubStore store,
    String tabKey,
  ) {
    final raw = store.raw;
    final key = tabKey.trim().toLowerCase();

    final sections = <dynamic>[];

    sections.addAll(_listAt(raw, [key, 'sections']));
    sections.addAll(_listAt(raw, [key, 'dynamic_sections']));
    sections.addAll(_listAt(raw, [key, 'builder_sections']));
    sections.addAll(_listAt(raw, [key, 'cards']));
    sections.addAll(_listAt(raw, [key, 'items']));
    sections.addAll(_listAt(raw, ['pages', key, 'sections']));
    sections.addAll(_listAt(raw, ['pages', key, 'dynamic_sections']));
    sections.addAll(_listAt(raw, ['pages', key, 'builder_sections']));
    sections.addAll(_listAt(raw, ['builder', key, 'sections']));
    sections.addAll(_listAt(raw, ['builder', key, 'dynamic_sections']));
    sections.addAll(_listAt(raw, ['sections_by_tab', key]));
    sections.addAll(_listAt(raw, ['tab_sections', key]));

    final normalized = HubRendererRegistry.normalizeSections(sections);

    final cleaned = HubRendererRegistry.removeEmpty(normalized);

    return cleaned;
  }

  static List<dynamic> _listAt(
    Map<String, dynamic> source,
    List<String> path,
  ) {
    dynamic current = source;

    for (final key in path) {
      if (current is Map<String, dynamic>) {
        current = current[key];
        continue;
      }

      if (current is Map) {
        current = current[key];
        continue;
      }

      return const [];
    }

    if (current is List) {
      return current;
    }

    return const [];
  }
}
