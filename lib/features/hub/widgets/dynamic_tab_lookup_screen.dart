import 'package:flutter/material.dart';

import '../models/dynamic_tab.dart';
import '../renderer/dynamic_tab_renderer.dart';
import '../state/hub_scope.dart';
import '../state/hub_tab_registry.dart';

class DynamicTabLookupScreen extends StatelessWidget {
  final String tabKey;

  const DynamicTabLookupScreen({
    super.key,
    required this.tabKey,
  });

  @override
  Widget build(BuildContext context) {
    final hub = HubScope.of(context);
    final tabs = HubTabRegistry.resolveTabs(hub);

    final normalizedKey = tabKey.trim().toLowerCase();

    final tab = tabs.firstWhere(
      (item) => item.key.trim().toLowerCase() == normalizedKey,
      orElse: () => HubDynamicTab(
        key: normalizedKey.isNotEmpty ? normalizedKey : 'dynamic',
        label: normalizedKey.isNotEmpty ? normalizedKey : 'Dynamic',
        title: normalizedKey.isNotEmpty ? normalizedKey : 'Dynamic',
        subtitle: '',
        icon: 'apps',
        route: normalizedKey.isNotEmpty ? '/tab/$normalizedKey' : '/tab/dynamic',
        type: 'dynamic',
        enabled: true,
        visible: true,
        showInBottomNav: false,
        startup: false,
        order: 999,
        sections: const [],
        settings: const {},
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: SafeArea(
        child: DynamicTabRenderer(
          tab: tab,
          emptyState: DynamicTabEmptyState(
            title: tab.title.isNotEmpty ? tab.title : tab.label,
            message:
                'This dynamic tab is ready. Add sections from AppsHub to display content here.',
          ),
        ),
      ),
    );
  }
}
