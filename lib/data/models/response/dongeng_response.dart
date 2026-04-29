import 'package:arunika_app/data/models/response/dongeng_page.dart';

class DongengResponse {
  final String id;
  final String title;
  final double ageStart;
  final double ageEnd;
  final String imageUrl;
  final bool isFree;
  final String audioUrl;
  final String duration;
  final List<DongengPage> pages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  const DongengResponse({
    required this.id,
    required this.title,
    required this.ageStart,
    required this.ageEnd,
    required this.isFree,
    required this.imageUrl,
    required this.audioUrl,
    required this.duration,
    this.pages = const [],
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory DongengResponse.fromJson(Map<String, dynamic> json) {
    return DongengResponse(
      id: json['id'] as String,
      title: json['title'] as String,
      ageStart: (json['age_start'] as num).toDouble(),
      ageEnd: (json['age_end'] as num).toDouble(),
      isFree: json['is_free'] as bool,
      imageUrl: json['image_url'] as String,
      audioUrl: (json['audio_url'] as String?) ?? '',
      duration: (json['duration'] as String?) ?? '',
      pages: json['pages'] != null
          ? (json['pages'] as List<dynamic>)
                .map((p) => DongengPage.fromJson(p as Map<String, dynamic>))
                .toList()
          : const [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isDeleted: json['is_deleted'] as bool,
    );
  }

  static List<DongengResponse> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => DongengResponse.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'age_start': ageStart,
      'age_end': ageEnd,
      'is_free': isFree,
      'image_url': imageUrl,
      'audio_url': audioUrl,
      'duration': duration,
      'pages': pages.map((p) => p.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }
}
