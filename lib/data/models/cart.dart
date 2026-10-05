/// Keranjang Belanja: the server-side cart and the order a checkout makes.
/// Prices always come from the server; the app never sends one.
library;

enum CartItemType { arCard, dongeng }

CartItemType _itemType(String? v) =>
    v == 'dongeng' ? CartItemType.dongeng : CartItemType.arCard;

String _itemTypeJson(CartItemType t) =>
    t == CartItemType.dongeng ? 'dongeng' : 'ar_card';

class CartItem {
  final String productId;
  final CartItemType type;
  final String contentId;
  final String title;
  final String imageUrl;
  final int priceIdr;
  final int? strikePriceIdr;

  /// The price the parent last saw, when the price has gone up since.
  final int? priceChangedFrom;
  final bool unavailable;

  const CartItem({
    required this.productId,
    required this.type,
    required this.title,
    required this.priceIdr,
    this.contentId = '',
    this.imageUrl = '',
    this.strikePriceIdr,
    this.priceChangedFrom,
    this.unavailable = false,
  });

  /// The normal (crossed-out) price when a promo is running, else the price.
  int get normalIdr => strikePriceIdr != null && strikePriceIdr! > priceIdr
      ? strikePriceIdr!
      : priceIdr;

  bool get onPromo => normalIdr > priceIdr;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    productId: json['product_id'] as String,
    type: _itemType(json['item_type'] as String?),
    contentId: json['content_id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    imageUrl: json['image_url'] as String? ?? '',
    priceIdr: (json['price_idr'] as num).toInt(),
    strikePriceIdr: (json['strike_price_idr'] as num?)?.toInt(),
    priceChangedFrom: (json['price_changed_from'] as num?)?.toInt(),
    unavailable: json['unavailable'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'item_type': _itemTypeJson(type),
    'content_id': contentId,
    'title': title,
    'image_url': imageUrl,
    'price_idr': priceIdr,
    'strike_price_idr': strikePriceIdr,
    'price_changed_from': priceChangedFrom,
    'unavailable': unavailable,
  };
}

/// Why the server changed the cart.
enum CartNoticeCode {
  alreadyOwned,
  becameFree,
  subscriptionActive,
  notForSale,
  other,
}

class CartNotice {
  final CartNoticeCode code;
  final String productId;
  final String title;

  const CartNotice({
    required this.code,
    required this.productId,
    this.title = '',
  });

  factory CartNotice.fromJson(Map<String, dynamic> json) => CartNotice(
    code: switch (json['code']) {
      'ALREADY_OWNED' => CartNoticeCode.alreadyOwned,
      'BECAME_FREE' => CartNoticeCode.becameFree,
      'SUBSCRIPTION_ACTIVE' => CartNoticeCode.subscriptionActive,
      'NOT_FOR_SALE' => CartNoticeCode.notForSale,
      _ => CartNoticeCode.other,
    },
    productId: json['product_id'] as String? ?? '',
    title: json['title'] as String? ?? '',
  );
}

class Cart {
  final List<CartItem> items;
  final List<CartNotice> notices;

  const Cart({this.items = const [], this.notices = const []});

  static const empty = Cart();

  List<CartItem> get payable => items.where((i) => !i.unavailable).toList();
  int get itemCount => payable.length;
  int get subtotalIdr => payable.fold(0, (sum, i) => sum + i.normalIdr);
  int get totalIdr => payable.fold(0, (sum, i) => sum + i.priceIdr);
  int get promoSavingIdr => subtotalIdr - totalIdr;
  bool get isEmpty => items.isEmpty;

  /// True when the parent must look again before paying ("Ada perubahan").
  bool get hasChanges =>
      notices.isNotEmpty || items.any((i) => i.priceChangedFrom != null);

  bool contains(String productId) => items.any((i) => i.productId == productId);

  Cart copyWith({List<CartItem>? items, List<CartNotice>? notices}) =>
      Cart(items: items ?? this.items, notices: notices ?? this.notices);

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
    items: (json['items'] as List<dynamic>? ?? [])
        .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    notices: (json['notices'] as List<dynamic>? ?? [])
        .map((e) => CartNotice.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// One item of an order, with its locked price.
class OrderLine {
  final String productId;
  final String title;
  final CartItemType type;
  final int normalIdr;
  final int priceIdr;

  const OrderLine({
    required this.productId,
    required this.title,
    required this.type,
    required this.normalIdr,
    required this.priceIdr,
  });

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
    productId: json['product_id'] as String,
    title: json['title'] as String? ?? '',
    type: _itemType(json['item_type'] as String?),
    normalIdr: (json['normal_idr'] as num).toInt(),
    priceIdr: (json['price_idr'] as num).toInt(),
  );
}

/// The order POST /orders froze the cart into, and the store product to
/// buy for it.
class CheckoutOrder {
  final String orderId;
  final String playProductId;
  final int subtotalIdr;
  final int promoSavingIdr;
  final int totalIdr;
  final int chargeIdr;
  final List<OrderLine> items;

  const CheckoutOrder({
    required this.orderId,
    required this.playProductId,
    required this.subtotalIdr,
    required this.promoSavingIdr,
    required this.totalIdr,
    required this.chargeIdr,
    required this.items,
  });

  factory CheckoutOrder.fromJson(Map<String, dynamic> json) => CheckoutOrder(
    orderId: json['order_id'] as String,
    playProductId: json['play_product_id'] as String,
    subtotalIdr: (json['subtotal_idr'] as num? ?? 0).toInt(),
    promoSavingIdr: (json['promo_saving_idr'] as num? ?? 0).toInt(),
    totalIdr: (json['total_idr'] as num).toInt(),
    chargeIdr: (json['charge_idr'] as num? ?? json['total_idr'] as num).toInt(),
    items: (json['items'] as List<dynamic>? ?? [])
        .map((e) => OrderLine.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// Where an order is (GET /orders/:id `phase`).
enum OrderPhase { waiting, processing, granted, failed, expired, refunded }

OrderPhase orderPhaseFromJson(String? v) => switch (v) {
  'diproses' => OrderPhase.processing,
  'diberikan' => OrderPhase.granted,
  'gagal' => OrderPhase.failed,
  'kedaluwarsa' => OrderPhase.expired,
  'dikembalikan' => OrderPhase.refunded,
  _ => OrderPhase.waiting,
};
