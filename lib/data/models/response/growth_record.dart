class GrowthRecord {
  final String id;
  final String childId;
  final DateTime recordedAt;
  final double weightKg;
  final double heightCm;

  const GrowthRecord({
    required this.id,
    required this.childId,
    required this.recordedAt,
    required this.weightKg,
    required this.heightCm,
  });

  factory GrowthRecord.fromJson(Map<String, dynamic> json) => GrowthRecord(
    id: json['id'] as String,
    childId: json['child_id'] as String,
    recordedAt:
        DateTime.tryParse(json['recorded_at'] as String? ?? '') ??
        DateTime.now(),
    weightKg: (json['weight_kg'] as num).toDouble(),
    heightCm: (json['height_cm'] as num).toDouble(),
  );

  static List<GrowthRecord> fromJsonList(List<dynamic> list) => list
      .map((e) => GrowthRecord.fromJson(e as Map<String, dynamic>))
      .toList();
}
