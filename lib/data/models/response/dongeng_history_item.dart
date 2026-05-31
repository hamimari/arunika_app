class DongengHistoryItem {
  final String dongengId;
  final int progressSeconds;
  final int totalSeconds;
  final String startedAt;

  const DongengHistoryItem({
    required this.dongengId,
    required this.progressSeconds,
    required this.totalSeconds,
    required this.startedAt,
  });

  factory DongengHistoryItem.fromJson(Map<String, dynamic> json) {
    return DongengHistoryItem(
      dongengId: json['dongeng_id'] as String,
      progressSeconds: (json['progress_seconds'] as int?) ?? 0,
      totalSeconds: (json['total_seconds'] as int?) ?? 0,
      startedAt: (json['started_at'] as String?) ?? '',
    );
  }

  static List<DongengHistoryItem> fromJsonList(List<dynamic> list) {
    return list
        .map((e) => DongengHistoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  double get progress =>
      totalSeconds > 0 ? progressSeconds / totalSeconds : 0.0;
}
