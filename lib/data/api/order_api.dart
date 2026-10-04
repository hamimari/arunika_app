import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

class OrderApi {
  final Dio dio;

  OrderApi() : dio = DioClient.dio;

  /// Fetches order status from GET /orders/:id.
  Future<Map<String, dynamic>> fetchOrderStatus(String orderId) async {
    final res = await dio.get(ApiPaths.orderById(orderId));
    return res.data['data'] as Map<String, dynamic>;
  }

  /// Fetches one page of the user's own orders from GET /orders.
  Future<Map<String, dynamic>> fetchOrders({
    required int page,
    required int perPage,
  }) async {
    final res = await dio.get(
      ApiPaths.orders,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return res.data as Map<String, dynamic>;
  }
}
