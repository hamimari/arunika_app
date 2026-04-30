class BannerItem {
  final String id;
  final String title;
  final String imageUrl;
  final String linkUrl;
  final String description;

  const BannerItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.linkUrl,
    required this.description,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) => BannerItem(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    imageUrl: json['image_url'] as String? ?? '',
    linkUrl: json['link_url'] as String? ?? '',
    description: json['description'] as String? ?? '',
  );

  static List<BannerItem> fromJsonList(List<dynamic> list) =>
      list.map((e) => BannerItem.fromJson(e as Map<String, dynamic>)).toList();
}
