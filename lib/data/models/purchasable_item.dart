import 'package:arunika_app/core/utils/price_format.dart';
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
  // Subscription length — set for subscription packages, so the payment
  // screen can show the renewed end date.
  final int? durationDays;
  // Package presentation, for the payment screen's option list.
  final String? badgeLabel;
  final bool isBestValue;
  // Display-only promotional strike price; null when no promo is running.
  // Never charged — payments always use [priceIdr].
  final int? strikePriceIdr;
  final int? discountPercent;
  final DateTime? promoEndsAt;

  const PurchasableItem({
    required this.kind,
    required this.id,
    required this.name,
    required this.subtitle,
    required this.priceIdr,
    this.contentType,
    this.packageType,
    this.playProductId,
    this.durationDays,
    this.badgeLabel,
    this.isBestValue = false,
    this.strikePriceIdr,
    this.discountPercent,
    this.promoEndsAt,
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
      durationDays: pack.durationDays,
      badgeLabel: pack.badgeLabel,
      isBestValue: pack.isBestValue,
      strikePriceIdr: pack.strikePriceIdr,
      discountPercent: pack.discountPercent,
      promoEndsAt: pack.promoEndsAt,
    );
  }

  factory PurchasableItem.fromProduct({
    required String productId,
    required String title,
    required int priceIdr,
    required PurchasedContentType contentType,
    String? subtitle,
    String? playProductId,
    int? strikePriceIdr,
    int? discountPercent,
    DateTime? promoEndsAt,
  }) {
    return PurchasableItem(
      kind: PurchaseKind.product,
      id: productId,
      name: title,
      subtitle: subtitle ?? 'Konten tunggal',
      priceIdr: priceIdr,
      contentType: contentType,
      playProductId: playProductId,
      strikePriceIdr: strikePriceIdr,
      discountPercent: discountPercent,
      promoEndsAt: promoEndsAt,
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

  String get formattedPrice => formatIdr(priceIdr);

  /// Strike price minus the real price, when a promo is running.
  int? get savingsIdr =>
      strikePriceIdr != null && strikePriceIdr! > priceIdr
          ? strikePriceIdr! - priceIdr
          : null;

  /// Alias used by payment screen.
  String get priceLabel => formattedPrice;

  /// Amount in IDR as int for the payment API.
  int get priceRaw => priceIdr;
}
