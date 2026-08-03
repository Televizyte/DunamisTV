import 'dart:convert';

class KingdomBuilderState {
  static const currentSaveVersion = 1;

  final int saveVersion;
  final int ministryLevel;
  final String stageName;
  final int ministryFunds;
  final int faith;
  final int impact;
  final int members;
  final int workers;
  final bool foundationStarted;
  final DateTime updatedAt;

  const KingdomBuilderState({
    required this.saveVersion,
    required this.ministryLevel,
    required this.stageName,
    required this.ministryFunds,
    required this.faith,
    required this.impact,
    required this.members,
    required this.workers,
    required this.foundationStarted,
    required this.updatedAt,
  });

  factory KingdomBuilderState.initial() => KingdomBuilderState(
        saveVersion: currentSaveVersion,
        ministryLevel: 1,
        stageName: 'Small Beginnings',
        ministryFunds: 2500,
        faith: 10,
        impact: 0,
        members: 5,
        workers: 1,
        foundationStarted: false,
        updatedAt: DateTime.now().toUtc(),
      );

  KingdomBuilderState copyWith({
    int? ministryLevel,
    String? stageName,
    int? ministryFunds,
    int? faith,
    int? impact,
    int? members,
    int? workers,
    bool? foundationStarted,
    DateTime? updatedAt,
  }) {
    return KingdomBuilderState(
      saveVersion: currentSaveVersion,
      ministryLevel: ministryLevel ?? this.ministryLevel,
      stageName: stageName ?? this.stageName,
      ministryFunds: ministryFunds ?? this.ministryFunds,
      faith: faith ?? this.faith,
      impact: impact ?? this.impact,
      members: members ?? this.members,
      workers: workers ?? this.workers,
      foundationStarted: foundationStarted ?? this.foundationStarted,
      updatedAt: updatedAt ?? DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toMap() => {
        'save_version': currentSaveVersion,
        'ministry_level': ministryLevel,
        'stage_name': stageName,
        'ministry_funds': ministryFunds,
        'faith': faith,
        'impact': impact,
        'members': members,
        'workers': workers,
        'foundation_started': foundationStarted,
        'updated_at': updatedAt.toIso8601String(),
      };

  String toJson() => jsonEncode(toMap());

  factory KingdomBuilderState.fromMap(Map<String, dynamic> map) {
    return KingdomBuilderState(
      saveVersion: map['save_version'] as int? ?? currentSaveVersion,
      ministryLevel: map['ministry_level'] as int? ?? 1,
      stageName: map['stage_name'] as String? ?? 'Small Beginnings',
      ministryFunds: map['ministry_funds'] as int? ?? 2500,
      faith: map['faith'] as int? ?? 10,
      impact: map['impact'] as int? ?? 0,
      members: map['members'] as int? ?? 5,
      workers: map['workers'] as int? ?? 1,
      foundationStarted: map['foundation_started'] as bool? ?? false,
      updatedAt:
          DateTime.tryParse(map['updated_at'] as String? ?? '')?.toUtc() ??
              DateTime.now().toUtc(),
    );
  }

  factory KingdomBuilderState.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) return KingdomBuilderState.initial();
    return KingdomBuilderState.fromMap(Map<String, dynamic>.from(decoded));
  }
}
