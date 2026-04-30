import 'dart:convert';

class TracingItem {
  final String id;
  final String type;
  final String label;
  final String guidePathJson;
  final int difficulty;

  const TracingItem({
    required this.id,
    required this.type,
    required this.label,
    required this.guidePathJson,
    required this.difficulty,
  });

  factory TracingItem.fromJson(Map<String, dynamic> json) => TracingItem(
    id: json['id'] as String,
    type: json['type'] as String,
    label: json['label'] as String,
    guidePathJson: json['guide_path_json'] as String? ?? '[]',
    difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
  );

  List<Map<String, double>> get guidePoints {
    final raw = jsonDecode(guidePathJson) as List<dynamic>;
    return raw
        .map(
          (e) => {
            'x': (e['x'] as num).toDouble(),
            'y': (e['y'] as num).toDouble(),
          },
        )
        .toList();
  }

  static List<TracingItem> fromJsonList(List<dynamic> list) =>
      list.map((e) => TracingItem.fromJson(e as Map<String, dynamic>)).toList();
}
