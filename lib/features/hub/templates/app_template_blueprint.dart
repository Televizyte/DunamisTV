class AppTemplateBlueprint {
  final String key;
  final String name;
  final String description;
  final List<Map<String, dynamic>> sections;

  const AppTemplateBlueprint({
    required this.key,
    required this.name,
    required this.description,
    required this.sections,
  });
}
