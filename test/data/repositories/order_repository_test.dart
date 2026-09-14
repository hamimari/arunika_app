// ignore_for_file: inference_failure_on_function_invocation

import 'package:arunika_app/data/api/order_api.dart';
import 'package:arunika_app/data/models/response/order_response.dart';
import 'package:arunika_app/data/repositories/order_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockOrderApi extends Mock implements OrderApi {}

Map<String, dynamic> _orderJson(String id, String status) => {
  'id': id,
  'status': status,
};

void main() {
  late MockOrderApi mockApi;
  late OrderRepository repo;

  setUp(() {
    mockApi = MockOrderApi();
    repo = OrderRepository(mockApi);
  });

  group('OrderRepository', () {
    test('fetchOrderStatus returns mapped OrderResponse on success', () async {
      when(
        () => mockApi.fetchOrderStatus('order-1'),
      ).thenAnswer((_) async => _orderJson('order-1', 'PAID'));

      final result = await repo.fetchOrderStatus('order-1');

      expect(result.id, 'order-1');
      expect(result.status, OrderStatus.paid);
    });

    test('fetchOrderStatus maps PENDING/FAILED/EXPIRED statuses', () async {
      when(
        () => mockApi.fetchOrderStatus('order-2'),
      ).thenAnswer((_) async => _orderJson('order-2', 'PENDING'));
      expect(
        (await repo.fetchOrderStatus('order-2')).status,
        OrderStatus.pending,
      );

      when(
        () => mockApi.fetchOrderStatus('order-3'),
      ).thenAnswer((_) async => _orderJson('order-3', 'FAILED'));
      expect(
        (await repo.fetchOrderStatus('order-3')).status,
        OrderStatus.failed,
      );

      when(
        () => mockApi.fetchOrderStatus('order-4'),
      ).thenAnswer((_) async => _orderJson('order-4', 'EXPIRED'));
      expect(
        (await repo.fetchOrderStatus('order-4')).status,
        OrderStatus.expired,
      );
    });

    test('fetchOrderStatus propagates exception on failure', () async {
      when(
        () => mockApi.fetchOrderStatus(any()),
      ).thenThrow(Exception('network error'));

      expect(() => repo.fetchOrderStatus('bad-id'), throwsException);
    });
  });
}
