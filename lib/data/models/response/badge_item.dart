class BadgeItem {
  final String id;
  final String feature;
  final String level;
  final int threshold;
  final bool earned;
  final int progress;

  const BadgeItem({
    required this.id,
    required this.feature,
    required this.level,
    required this.threshold,
    required this.earned,
    required this.progress,
  });

  factory BadgeItem.fromJson(Map<String, dynamic> json) => BadgeItem(
    id: json['id'] as String,
    feature: json['feature'] as String,
    level: json['level'] as String,
    threshold: (json['threshold'] as num).toInt(),
    earned: json['earned'] as bool? ?? false,
    progress: (json['progress'] as num?)?.toInt() ?? 0,
  );

  static List<BadgeItem> fromJsonList(List<dynamic> list) =>
      list.map((e) => BadgeItem.fromJson(e as Map<String, dynamic>)).toList();
}
