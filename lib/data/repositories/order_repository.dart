import 'package:arunika_app/data/api/order_api.dart';
import 'package:arunika_app/data/models/response/order_response.dart';

class OrderRepository {
  final OrderApi api;

  OrderRepository(this.api);

  Future<OrderResponse> fetchOrderStatus(String orderId) async {
    final json = await api.fetchOrderStatus(orderId);
    return OrderResponse.fromJson(json);
  }
}
