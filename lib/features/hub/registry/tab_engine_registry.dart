import '../models/dynamic_tab.dart';

class TabEngineRegistry {
  static bool isDynamicTab(HubDynamicTab tab) {
    return switch (tab.key.trim().toLowerCase()) {
      'home' => false,
      'watch' => false,
      'inspire' => false,
      'explore' => false,
      'more' => false,
      _ => true,
    };
  }

  static bool shouldUseDynamicRenderer(HubDynamicTab tab) {
    if (isDynamicTab(tab)) {
      return true;
    }

    return tab.sections.isNotEmpty;
  }
}
