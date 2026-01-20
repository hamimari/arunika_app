import 'dart:ffi';

class DongengResponse {
  final String id;
  final String title;
  final int ageStart;
  final int ageEnd;
  final String imageUrl;
  final bool isFree;
  // final String audioUrl;
  // final String label;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  DongengResponse({
    required this.id,
    required this.title,
    required this.ageStart,
    required this.ageEnd,
    required this.isFree,
    required this.imageUrl,
    // required this.audioUrl,
    // required this.label,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory DongengResponse.fromJson(Map<String, dynamic> json) {
    return DongengResponse(
      id: json['id'],
      title: json['title'],
      ageStart: json['age_start'],
      ageEnd: json['age_end'],
      isFree: json['is_free'],
      imageUrl: json['image_url'],
      // audioUrl: json['audio_url'],
      // label: json['label'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'],
    );
  }

  static List<DongengResponse> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => DongengResponse.fromJson(json)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'age_start': ageStart,
      'age_end': ageEnd,
      'is_free': isFree,
      'image_url': imageUrl,
      // 'audio_url': audioUrl,
      // 'label': label,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }
}
