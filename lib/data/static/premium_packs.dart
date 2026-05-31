import 'package:flutter/foundation.dart';

@immutable
class PremiumPack {
  final String id;
  final String name;
  final String subtitle;
  final int priceIdr;
  final bool isBestValue;
  final String? badgeLabel;

  const PremiumPack({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.priceIdr,
    this.isBestValue = false,
    this.badgeLabel,
  });

  factory PremiumPack.fromJson(Map<String, dynamic> json) {
    return PremiumPack(
      id: json['id'] as String,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String,
      priceIdr: json['price_idr'] as int,
      isBestValue: (json['is_best_value'] as bool?) ?? false,
      badgeLabel: json['badge_label'] as String?,
    );
  }

  String get formattedPrice {
    final formatted = priceIdr.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $formatted';
  }

  /// Alias used by payment screen.
  String get priceLabel => formattedPrice;

  /// Amount in IDR as int64 for the payment API.
  int get priceRaw => priceIdr;
}

/// @deprecated Use `PremiumPackRepository` from `lib/data/repositories/premium_pack_repository.dart`
/// instead. This static class is kept only as a fallback for the repository's error path
/// and will be removed once the API is confirmed stable.
// ignore: deprecated_member_use_from_same_package
class PremiumPacks {
  static const List<PremiumPack> contentPacks = [
    PremiumPack(
      id: 'pack_hutan',
      name: 'Paket Hutan',
      subtitle: '8 Hewan Hutan + 2 Dongeng',
      priceIdr: 29000,
    ),
    PremiumPack(
      id: 'pack_laut',
      name: 'Paket Lautan',
      subtitle: '8 Hewan Laut + 2 Dongeng',
      priceIdr: 29000,
    ),
    PremiumPack(
      id: 'pack_ternak',
      name: 'Paket Ternak',
      subtitle: '8 Hewan Ternak + 2 Dongeng',
      priceIdr: 29000,
    ),
    PremiumPack(
      id: 'pack_all',
      name: 'ALL ACCESS PASS',
      subtitle: 'Semua hewan, semua dongeng, akses offline',
      priceIdr: 79000,
      isBestValue: true,
      badgeLabel: 'BEST VALUE',
    ),
  ];

  static const List<PremiumPack> subscriptionPacks = [
    PremiumPack(
      id: 'sub_monthly',
      name: 'Bulanan',
      subtitle: 'Akses penuh selama 1 bulan',
      priceIdr: 39000,
    ),
    PremiumPack(
      id: 'sub_annual',
      name: 'Tahunan',
      subtitle: 'Akses penuh selama 12 bulan',
      priceIdr: 299000,
      isBestValue: true,
      badgeLabel: 'HEMAT 36%',
    ),
  ];
}
