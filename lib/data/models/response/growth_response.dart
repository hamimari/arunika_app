import 'package:arunika_app/core/growth/growth_engine.dart';
import 'package:equatable/equatable.dart';

/// One measurement as returned by `/children/:childId/growth`. Z-scores are
/// deliberately not parsed: parents only ever see categories.
class GrowthMeasurement extends Equatable {
  final String id;
  final String? clientId;
  final DateTime measuredOn;
  final double? heightCm;
  final double? weightKg;
  final Position position;
  final int ageDays;
  final String? hfaCategory;
  final String? wfaCategory;
  final bool flagged;

  const GrowthMeasurement({
    required this.id,
    this.clientId,
    required this.measuredOn,
    this.heightCm,
    this.weightKg,
    required this.position,
    required this.ageDays,
    this.hfaCategory,
    this.wfaCategory,
    this.flagged = false,
  });

  factory GrowthMeasurement.fromJson(Map<String, dynamic> json) {
    String? category(String key) =>
        (json[key] as Map<String, dynamic>?)?['category'] as String?;
    return GrowthMeasurement(
      id: json['id'] as String,
      clientId: json['client_id'] as String?,
      measuredOn: DateTime.parse(json['measured_on'] as String),
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      position: json['position'] == 'recumbent'
          ? Position.recumbent
          : Position.standing,
      ageDays: (json['age_days'] as num?)?.toInt() ?? 0,
      hfaCategory: category('hfa'),
      wfaCategory: category('wfa'),
      flagged: json['flagged'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    measuredOn,
    heightCm,
    weightKg,
    position,
    ageDays,
    hfaCategory,
    wfaCategory,
    flagged,
  ];
}

class GrowthChild extends Equatable {
  final String id;
  final String name;
  final Sex? sex;
  final DateTime? birthDate;
  final bool over60Months;

  const GrowthChild({
    required this.id,
    required this.name,
    this.sex,
    this.birthDate,
    this.over60Months = false,
  });

  factory GrowthChild.fromJson(Map<String, dynamic> json) {
    final birth = json['birth_date'] as String?;
    return GrowthChild(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sex: normalizeSex(json['sex'] as String?),
      birthDate: birth == null || birth.isEmpty ? null : DateTime.parse(birth),
      over60Months: json['over_60_months'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, name, sex, birthDate, over60Months];
}

class GrowthSummary extends Equatable {
  final bool profileComplete;
  final GrowthChild child;

  /// Newest first.
  final List<GrowthMeasurement> measurements;

  const GrowthSummary({
    required this.profileComplete,
    required this.child,
    required this.measurements,
  });

  factory GrowthSummary.fromJson(Map<String, dynamic> json) => GrowthSummary(
    profileComplete: json['profile_complete'] as bool? ?? false,
    child: GrowthChild.fromJson(json['child'] as Map<String, dynamic>? ?? {}),
    measurements: (json['measurements'] as List<dynamic>? ?? [])
        .map((e) => GrowthMeasurement.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  @override
  List<Object?> get props => [profileComplete, child, measurements];
}
