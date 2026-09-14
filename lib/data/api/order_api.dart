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
}
