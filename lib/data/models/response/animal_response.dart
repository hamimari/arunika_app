import 'dart:ui';

class AnimalResponse {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final String imageUrl;
  final String bgColorHex;
  final String fact;
  final bool isUnlocked;

  const AnimalResponse({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.imageUrl,
    required this.bgColorHex,
    required this.fact,
    required this.isUnlocked,
  });

  factory AnimalResponse.fromJson(Map<String, dynamic> json) {
    return AnimalResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: (json['emoji'] as String?) ?? '🐾',
      category: (json['category'] as String?) ?? 'hutan',
      imageUrl: (json['image_url'] as String?) ?? '',
      bgColorHex: (json['bg_color'] as String?) ?? '#FFF3E0',
      fact: (json['fact'] as String?) ?? '',
      isUnlocked: (json['is_unlocked'] as bool?) ?? false,
    );
  }

  static List<AnimalResponse> fromJsonList(List<dynamic> list) {
    return list
        .map((e) => AnimalResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns the bg_color hex string as a Flutter Color.
  Color get bgColor {
    final hex = bgColorHex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}
