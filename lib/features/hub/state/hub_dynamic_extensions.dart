import '../models/dynamic_section.dart';
import '../registry/renderer_registry.dart';
import 'hub_store.dart';

extension HubDynamicExtensions on HubStore {
  List<HubDynamicSection> get allDynamicSections {
    final sections = <dynamic>[];

    sections.addAll(_listAt(raw, const ['home', 'sections']));
    sections.addAll(_listAt(raw, const ['home', 'cards']));
    sections.addAll(_listAt(raw, const ['home', 'items']));
    sections.addAll(_listAt(raw, const ['sections']));
    sections.addAll(_listAt(raw, const ['pages', 'home', 'sections']));

    return _cleanHomeSections(
      HubRendererRegistry.normalizeSections(sections),
    );
  }

  List<HubDynamicSection> get homeDynamicSections {
    final sections = <dynamic>[];

    sections.addAll(_listAt(raw, const ['home', 'sections']));
    sections.addAll(_listAt(raw, const ['home', 'dynamic_sections']));
    sections.addAll(_listAt(raw, const ['home', 'builder_sections']));
    sections.addAll(_listAt(raw, const ['pages', 'home', 'sections']));
    sections.addAll(_listAt(raw, const ['pages', 'home', 'dynamic_sections']));
    sections.addAll(_listAt(raw, const ['builder', 'home', 'sections']));

    final normalized = HubRendererRegistry.normalizeSections(sections);
    final cleaned = HubRendererRegistry.removeEmpty(normalized);

    return _cleanHomeSections(cleaned);
  }

  List<HubDynamicSection> get exploreDynamicSections {
    final sections = <dynamic>[];

    sections.addAll(_listAt(raw, const ['explore', 'sections']));
    sections.addAll(_listAt(raw, const ['explore', 'dynamic_sections']));
    sections.addAll(_listAt(raw, const ['explore', 'cards']));
    sections.addAll(_listAt(raw, const ['explore', 'items']));
    sections.addAll(_listAt(raw, const ['pages', 'explore', 'sections']));
    sections.addAll(_listAt(raw, const ['builder', 'explore', 'sections']));

    final normalized = HubRendererRegistry.normalizeSections(sections);
    final cleaned = HubRendererRegistry.removeEmpty(normalized);

    return cleaned;
  }

  List<HubDynamicSection> get watchDynamicSections {
    final sections = <dynamic>[];

    sections.addAll(_listAt(raw, const ['watch', 'sections']));
    sections.addAll(_listAt(raw, const ['watch', 'dynamic_sections']));
    sections.addAll(_listAt(raw, const ['watch', 'cards']));
    sections.addAll(_listAt(raw, const ['watch', 'items']));
    sections.addAll(_listAt(raw, const ['pages', 'watch', 'sections']));
    sections.addAll(_listAt(raw, const ['builder', 'watch', 'sections']));

    final normalized = HubRendererRegistry.normalizeSections(sections);
    final cleaned = HubRendererRegistry.removeEmpty(normalized);

    return cleaned;
  }

  List<HubDynamicSection> get inspireDynamicSections {
    final sections = <dynamic>[];

    sections.addAll(_listAt(raw, const ['inspire', 'sections']));
    sections.addAll(_listAt(raw, const ['inspire', 'dynamic_sections']));
    sections.addAll(_listAt(raw, const ['inspire', 'cards']));
    sections.addAll(_listAt(raw, const ['inspire', 'items']));
    sections.addAll(_listAt(raw, const ['inspire', 'hub_cards']));
    sections.addAll(_listAt(raw, const ['pages', 'inspire', 'sections']));
    sections.addAll(_listAt(raw, const ['builder', 'inspire', 'sections']));

    final normalized = HubRendererRegistry.normalizeSections(sections);
    final cleaned = HubRendererRegistry.removeEmpty(normalized);

    return cleaned;
  }

  bool get hasHomeDynamicSections => homeDynamicSections.isNotEmpty;

  bool get hasExploreDynamicSections => exploreDynamicSections.isNotEmpty;

  bool get hasWatchDynamicSections => watchDynamicSections.isNotEmpty;

  bool get hasInspireDynamicSections => inspireDynamicSections.isNotEmpty;
}

List<HubDynamicSection> _cleanHomeSections(
  List<HubDynamicSection> sections,
) {
  final protectedKeys = <String>{
    'hero',
    'home_hero',
    'daily_scripture',
    'scripture',
    'today_scripture',
    'daily_quote',
    'quote',
    'quick_tools',
    'tools',
    'quick_access',
    'shortcuts',
    'prayer_broadcast',
    'prayer',
  };

  return sections.where((section) {
    final key = section.key.trim().toLowerCase();
    final title = section.title.trim().toLowerCase();
    final type = section.type.trim().toLowerCase();

    final combined = '$key $title $type ${section.layout.name}'.toLowerCase();

    if (protectedKeys.contains(key)) {
      return false;
    }

    if (combined.contains('daily_scripture')) {
      return false;
    }

    if (combined.contains('today_scripture')) {
      return false;
    }

    if (combined.contains('daily_quote')) {
      return false;
    }

    if (combined.contains('quick_access')) {
      return false;
    }

    if (combined.contains('quick tools')) {
      return false;
    }

    if (combined.contains('prayer_broadcast')) {
      return false;
    }

    if (combined.contains('home_hero')) {
      return false;
    }

    return true;
  }).toList(growable: false);
}

List<dynamic> _listAt(
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
