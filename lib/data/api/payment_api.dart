import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

class PaymentApi {
  final Dio dio;
  PaymentApi() : dio = DioClient.dio;

  Future<Map<String, dynamic>> createTransaction() async {
    final res = await dio.post(ApiPaths.paymentCreate);
    return res.data as Map<String, dynamic>;
  }
}
