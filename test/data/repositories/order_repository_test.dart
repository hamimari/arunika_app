// ignore_for_file: inference_failure_on_function_invocation

import 'package:arunika_app/data/api/order_api.dart';
import 'package:arunika_app/data/models/response/order_response.dart';
import 'package:arunika_app/data/models/response/payment_history_item.dart';
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

  group('OrderRepository.fetchPaymentHistory', () {
    test('maps GET /orders rows into history items', () async {
      when(() => mockApi.fetchOrders(page: 1, perPage: 20)).thenAnswer(
        (_) async => {
          'data': [
            {
              'id': 'order-1',
              'item_type': 'PACKAGE',
              'item_name': 'Paket Langganan Bulanan',
              'package_type': 'subscription',
              'amount_idr': 29900,
              'status': 'PAID',
              'payment_type': 'bank_transfer',
              'payment_method': 'BCA Virtual Account',
              'created_at': '2026-09-01T10:00:00Z',
              'updated_at': '2026-09-01T10:05:00Z',
            },
            {
              'id': 'order-2',
              'item_type': 'DONGENG',
              'item_name': 'Kancil',
              'amount_idr': 10000,
              'status': 'EXPIRED',
              'payment_type': '',
              'payment_method': '',
              'created_at': '2026-08-01T10:00:00Z',
              'updated_at': '2026-08-02T10:00:00Z',
            },
          ],
          'total': 7,
        },
      );

      final page = await repo.fetchPaymentHistory();

      expect(page.total, 7);
      expect(page.items, hasLength(2));
      final first = page.items.first;
      expect(first.orderId, 'order-1');
      expect(first.itemType, PaymentItemType.package);
      expect(first.packageType, 'subscription');
      expect(first.amountIdr, 29900);
      expect(first.status, OrderStatus.paid);
      expect(first.paymentMethod, 'BCA Virtual Account');
      expect(first.createdAt.isUtc, isFalse);
      expect(page.items[1].itemType, PaymentItemType.dongeng);
      expect(page.items[1].status, OrderStatus.expired);
      expect(page.items[1].paymentMethod, isEmpty);
    });
  });
}
