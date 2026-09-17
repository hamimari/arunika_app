enum OrderStatus { pending, paid, failed, expired, unknown }

class OrderResponse {
  final String id;
  final OrderStatus status;

  const OrderResponse({required this.id, required this.status});

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      id: json['id'] as String,
      status: parseStatus(json['status'] as String?),
    );
  }

  static OrderStatus parseStatus(String? raw) {
    switch (raw) {
      case 'PAID':
        return OrderStatus.paid;
      case 'FAILED':
        return OrderStatus.failed;
      case 'EXPIRED':
        return OrderStatus.expired;
      case 'PENDING':
        return OrderStatus.pending;
      default:
        return OrderStatus.unknown;
    }
  }
}
