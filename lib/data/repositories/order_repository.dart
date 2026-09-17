import 'package:arunika_app/data/api/order_api.dart';
import 'package:arunika_app/data/models/response/order_response.dart';
import 'package:arunika_app/data/models/response/payment_history_item.dart';

class OrderRepository {
  final OrderApi api;

  OrderRepository(this.api);

  Future<OrderResponse> fetchOrderStatus(String orderId) async {
    final json = await api.fetchOrderStatus(orderId);
    return OrderResponse.fromJson(json);
  }

  Future<PaymentHistoryPage> fetchPaymentHistory({
    int page = 1,
    int perPage = 20,
  }) async {
    final json = await api.fetchOrders(page: page, perPage: perPage);
    final items = (json['data'] as List<dynamic>? ?? [])
        .map((e) => PaymentHistoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaymentHistoryPage(
      items: items,
      total: (json['total'] as num?)?.toInt() ?? items.length,
    );
  }
}
