import 'package:arunika_app/data/models/response/order_response.dart';
import 'package:equatable/equatable.dart';

enum PaymentItemType { arCard, dongeng, package, unknown }

/// One row of GET /orders — an order the user placed, in any status.
class PaymentHistoryItem extends Equatable {
  final String orderId;
  final PaymentItemType itemType;
  final String itemName;

  /// `content` or `subscription`, only set for [PaymentItemType.package].
  final String? packageType;
  final int amountIdr;
  final OrderStatus status;

  /// Human-readable method (e.g. "BCA Virtual Account"); empty until the
  /// user has picked a method on the payment page.
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentHistoryItem({
    required this.orderId,
    required this.itemType,
    required this.itemName,
    this.packageType,
    required this.amountIdr,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      orderId: json['id'] as String,
      itemType: _parseItemType(json['item_type'] as String?),
      itemName: json['item_name'] as String? ?? '',
      packageType: json['package_type'] as String?,
      amountIdr: (json['amount_idr'] as num?)?.toInt() ?? 0,
      status: OrderResponse.parseStatus(json['status'] as String?),
      paymentMethod: json['payment_method'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  @override
  List<Object?> get props => [
    orderId,
    itemType,
    itemName,
    packageType,
    amountIdr,
    status,
    paymentMethod,
    createdAt,
    updatedAt,
  ];

  static PaymentItemType _parseItemType(String? raw) {
    switch (raw) {
      case 'AR_CARD':
        return PaymentItemType.arCard;
      case 'DONGENG':
        return PaymentItemType.dongeng;
      case 'PACKAGE':
        return PaymentItemType.package;
      default:
        return PaymentItemType.unknown;
    }
  }
}

class PaymentHistoryPage {
  final List<PaymentHistoryItem> items;
  final int total;

  const PaymentHistoryPage({required this.items, required this.total});
}
