class ArCardCategory {
  final String id;
  final String name;
  final String emoji;
  final String imageUrl;
  final String? parentId;
  final int sortOrder;
  final List<ArCardCategory> children;

  const ArCardCategory({
    required this.id,
    required this.name,
    required this.emoji,
    this.imageUrl = '',
    this.parentId,
    this.sortOrder = 0,
    this.children = const [],
  });

  factory ArCardCategory.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'] as List<dynamic>? ?? [];
    return ArCardCategory(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      parentId: json['parent_id'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      children: rawChildren
          .map((e) => ArCardCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
