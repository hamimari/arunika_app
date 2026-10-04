class BannerItem {
  final String id;
  final String title;
  final String imageUrl;
  final String type; // 'promo', 'daily_animal', 'feature'
  final bool isActive;
  final int sortOrder;
  final String? ctaUrl;
  final String? emoji;
  final String? fact;

  const BannerItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.type,
    required this.isActive,
    required this.sortOrder,
    this.ctaUrl,
    this.emoji,
    this.fact,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      imageUrl: (json['image_url'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'promo',
      isActive: (json['is_active'] as bool?) ?? true,
      sortOrder: (json['sort_order'] as int?) ?? 0,
      ctaUrl: json['cta_url'] as String?,
      emoji: json['emoji'] as String?,
      fact: json['fact'] as String?,
    );
  }

  static List<BannerItem> fromJsonList(List<dynamic> list) {
    return list
        .map((e) => BannerItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
