import 'package:arunika_app/data/models/response/ar_card_category.dart';

class ArCardResponse {
  final String? id;
  final String? type;
  final String? title;
  final String? fileUrl;
  final String? shortCode;
  final String? audioUrl;
  final String? printableImg;
  // Legacy free-text (fallback when category FK not set)
  final String category;
  final String subCategory;
  final String imageUrl;
  final String emoji;
  final String bgColor;
  final bool isUnlocked;
  final String description;
  final String funFact;
  // Structured category refs (from V12)
  final String? categoryId;
  final String? subCategoryId;
  final ArCardCategory? categoryRef;
  final ArCardCategory? subCategoryRef;

  ArCardResponse({
    this.id,
    this.type,
    this.title,
    this.fileUrl,
    this.shortCode,
    this.audioUrl,
    this.printableImg,
    this.category = '',
    this.subCategory = '',
    this.imageUrl = '',
    this.emoji = '',
    this.bgColor = '#FFF3E0',
    this.isUnlocked = false,
    this.description = '',
    this.funFact = '',
    this.categoryId,
    this.subCategoryId,
    this.categoryRef,
    this.subCategoryRef,
  });

  /// Resolved category name: prefers structured ref, falls back to legacy string
  String get resolvedCategoryName => categoryRef?.name ?? category;

  /// Resolved sub-category name: prefers structured ref, falls back to legacy string
  String get resolvedSubCategoryName => subCategoryRef?.name ?? subCategory;

  /// Resolved emoji: prefers category ref emoji, falls back to card emoji
  String get resolvedEmoji =>
      emoji.isNotEmpty ? emoji : (categoryRef?.emoji ?? '🃏');

  factory ArCardResponse.fromJson(Map<String, dynamic> json) {
    final catJson = json['category_ref'] as Map<String, dynamic>?;
    final subCatJson = json['sub_category_ref'] as Map<String, dynamic>?;
    return ArCardResponse(
      id: json['id'] as String?,
      type: json['type'] as String?,
      title: json['title'] as String?,
      fileUrl: json['file_url'] as String?,
      shortCode: json['short_code'] as String?,
      audioUrl: json['sound_url'] as String?,
      printableImg: json['printable_img'] as String?,
      category: json['category'] as String? ?? '',
      subCategory: json['sub_category'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '',
      bgColor: json['bg_color'] as String? ?? '#FFF3E0',
      isUnlocked: json['is_unlocked'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      funFact: json['fun_fact'] as String? ?? '',
      categoryId: json['category_id'] as String?,
      subCategoryId: json['sub_category_id'] as String?,
      categoryRef: catJson != null ? ArCardCategory.fromJson(catJson) : null,
      subCategoryRef: subCatJson != null
          ? ArCardCategory.fromJson(subCatJson)
          : null,
    );
  }
}
