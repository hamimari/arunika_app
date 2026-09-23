import 'package:arunika_app/data/static/premium_packs.dart';

/// What PaymentScreen is charging for — a whole package (bundle/subscription)
/// or a single product (one AR card / dongeng), each hitting a different
/// backend endpoint (`/payment/create` vs `/payment/create-product`).
enum PurchaseKind { package, product }

/// For a product purchase, which content type it unlocks — determines where
/// UnlockSuccessScreen routes the user after payment succeeds.
enum PurchasedContentType { arCard, dongeng }

class PurchasableItem {
  final PurchaseKind kind;
  final String id;
  final String name;
  final String subtitle;
  final int priceIdr;
  // Set when kind == product.
  final PurchasedContentType? contentType;
  // 'content' | 'subscription' — set when kind == package.
  final String? packageType;
  // Google Play product/subscription SKU — set when the item is mapped
  // for Google Play Billing (both packages and products).
  final String? playProductId;

  const PurchasableItem({
    required this.kind,
    required this.id,
    required this.name,
    required this.subtitle,
    required this.priceIdr,
    this.contentType,
    this.packageType,
    this.playProductId,
  });

  factory PurchasableItem.fromPackage(PremiumPack pack) {
    return PurchasableItem(
      kind: PurchaseKind.package,
      id: pack.id,
      name: pack.name,
      subtitle: pack.subtitle,
      priceIdr: pack.priceIdr,
      packageType: pack.type,
      playProductId: pack.playProductId,
    );
  }

  factory PurchasableItem.fromProduct({
    required String productId,
    required String title,
    required int priceIdr,
    required PurchasedContentType contentType,
    String? subtitle,
    String? playProductId,
  }) {
    return PurchasableItem(
      kind: PurchaseKind.product,
      id: productId,
      name: title,
      subtitle: subtitle ?? 'Konten tunggal',
      priceIdr: priceIdr,
      contentType: contentType,
      playProductId: playProductId,
    );
  }

  bool get isSubscriptionPurchase =>
      kind == PurchaseKind.package && packageType == 'subscription';

  /// Whether this purchase can go through Google Play Billing instead of
  /// the Midtrans webview — packages and products the backoffice has mapped
  /// to a Play product qualify.
  bool get isPlayBillingEligible =>
      playProductId != null && playProductId!.isNotEmpty;

  bool get isDongengPurchase =>
      kind == PurchaseKind.product && contentType == PurchasedContentType.dongeng;

  String get formattedPrice {
    final formatted = priceIdr.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $formatted';
  }

  /// Alias used by payment screen.
  String get priceLabel => formattedPrice;

  /// Amount in IDR as int for the payment API.
  int get priceRaw => priceIdr;
}
