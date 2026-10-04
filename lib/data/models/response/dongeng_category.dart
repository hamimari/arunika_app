class DongengCategory {
  final String id;
  final String name;
  final String imageUrl;
  final String? parentId;
  final int sortOrder;
  final List<DongengCategory> children;

  const DongengCategory({
    required this.id,
    required this.name,
    this.imageUrl = '',
    this.parentId,
    this.sortOrder = 0,
    this.children = const [],
  });

  factory DongengCategory.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'] as List<dynamic>? ?? [];
    return DongengCategory(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      parentId: json['parent_id'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      children: rawChildren
          .map((e) => DongengCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
