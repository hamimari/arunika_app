import 'package:arunika_app/data/api/payment_api.dart';

class SnapTransactionResult {
  final String token;
  final String redirectUrl;

  const SnapTransactionResult({required this.token, required this.redirectUrl});
}

class PaymentRepository {
  final PaymentApi api;
  PaymentRepository(this.api);

  Future<SnapTransactionResult> createTransaction() async {
    final json = await api.createTransaction();
    final data = json['data'] as Map<String, dynamic>;
    return SnapTransactionResult(
      token: data['token'] as String? ?? '',
      redirectUrl: data['redirect_url'] as String,
    );
  }
}
