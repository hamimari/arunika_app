class CategoryItem {
  final String id;
  final String name;
  final String emoji;
  final String slug;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.slug,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      emoji: (json['emoji'] as String?) ?? '🐾',
      slug: (json['slug'] as String?) ?? '',
    );
  }

  static List<CategoryItem> fromJsonList(List<dynamic> list) {
    return list
        .map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
