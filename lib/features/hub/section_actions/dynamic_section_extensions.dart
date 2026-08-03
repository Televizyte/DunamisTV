import '../models/dynamic_section.dart';
import 'dynamic_section_action_builder.dart';

extension DynamicSectionActionExtensions on HubDynamicSection {
  List<Map<String, dynamic>> get fallbackActions {
    return DynamicSectionActionBuilder.buildFallbackActions(this);
  }

  bool get hasFallbackActions {
    return fallbackActions.isNotEmpty;
  }
}
