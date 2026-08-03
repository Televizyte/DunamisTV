import '../models/dynamic_section.dart';

class DynamicFeedHelpers {
  const DynamicFeedHelpers._();

  static bool hasVisibleContent(
    List<HubDynamicSection> sections,
  ) {
    for (final section in sections) {
      if (!section.enabled) continue;

      if (section.isAdSection) {
        return true;
      }

      if (section.items.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  static List<HubDynamicSection> sortSections(
    List<HubDynamicSection> sections,
  ) {
    final cloned = [...sections];

    cloned.sort(
      (a, b) => a.order.compareTo(b.order),
    );

    return cloned;
  }

  static List<HubDynamicSection> enabledSections(
    List<HubDynamicSection> sections,
  ) {
    return sections
        .where((section) => section.enabled)
        .toList(growable: false);
  }

  static List<HubDynamicSection> removeEmptySections(
    List<HubDynamicSection> sections,
  ) {
    return sections.where((section) {
      if (!section.enabled) {
        return false;
      }

      if (section.isAdSection) {
        return true;
      }

      return section.items.isNotEmpty;
    }).toList(growable: false);
  }

  static List<HubDynamicSection> appendSection({
    required List<HubDynamicSection> sections,
    required HubDynamicSection section,
  }) {
    final cloned = [...sections];
    cloned.add(section);
    return cloned;
  }

  static List<HubDynamicSection> prependSection({
    required List<HubDynamicSection> sections,
    required HubDynamicSection section,
  }) {
    return [
      section,
      ...sections,
    ];
  }

  static List<HubDynamicSection> mergeSections({
    required List<HubDynamicSection> primary,
    required List<HubDynamicSection> secondary,
  }) {
    return [
      ...primary,
      ...secondary,
    ];
  }
}
