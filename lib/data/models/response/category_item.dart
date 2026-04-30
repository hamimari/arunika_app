class CategoryItem {
  final String id;
  final String name;
  final String imageUrl;
  final bool hidden;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.hidden = false,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    imageUrl: json['image_url']?.toString() ?? '',
    hidden: json['hidden'] == true,
  );

  static List<CategoryItem> fromJsonList(List<dynamic> list) => list
      .map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
      .toList();
}
