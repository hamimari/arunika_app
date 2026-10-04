// ignore_for_file: inference_failure_on_function_invocation

import 'package:arunika_app/data/models/response/order_response.dart';
import 'package:arunika_app/data/repositories/order_repository.dart';
import 'package:arunika_app/presentation/screens/payment/payment_polling_cubit.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late MockOrderRepository mockRepo;

  setUp(() {
    mockRepo = MockOrderRepository();
  });

  group('PaymentPollingCubit', () {
    test('emits waiting immediately, then paid once the order settles', () {
      fakeAsync((async) {
        var callCount = 0;
        when(() => mockRepo.fetchOrderStatus('order-1')).thenAnswer((_) async {
          callCount++;
          return OrderResponse(
            id: 'order-1',
            status: callCount < 2 ? OrderStatus.pending : OrderStatus.paid,
          );
        });

        final cubit = PaymentPollingCubit(
          mockRepo,
          pollInterval: const Duration(seconds: 2),
        );

        cubit.start('order-1');
        expect(cubit.state, isA<PaymentPollingWaiting>());

        async.elapse(const Duration(seconds: 2));
        expect(cubit.state, isA<PaymentPollingWaiting>());

        async.elapse(const Duration(seconds: 2));
        expect(cubit.state, isA<PaymentPollingPaid>());

        cubit.close();
      });
    });

    test('emits failed as soon as the order comes back FAILED', () {
      fakeAsync((async) {
        when(
          () => mockRepo.fetchOrderStatus('order-2'),
        ).thenAnswer((_) async => const OrderResponse(
              id: 'order-2',
              status: OrderStatus.failed,
            ));

        final cubit = PaymentPollingCubit(
          mockRepo,
          pollInterval: const Duration(seconds: 2),
        );

        cubit.start('order-2');
        async.elapse(const Duration(seconds: 2));

        expect(cubit.state, isA<PaymentPollingFailed>());

        cubit.close();
      });
    });

    test('emits failed after maxAttempts of a still-pending order (timeout)', () {
      fakeAsync((async) {
        when(
          () => mockRepo.fetchOrderStatus('order-3'),
        ).thenAnswer((_) async => const OrderResponse(
              id: 'order-3',
              status: OrderStatus.pending,
            ));

        final cubit = PaymentPollingCubit(
          mockRepo,
          pollInterval: const Duration(seconds: 2),
          maxAttempts: 3,
        );

        cubit.start('order-3');
        async.elapse(const Duration(seconds: 4));
        expect(cubit.state, isA<PaymentPollingWaiting>());

        async.elapse(const Duration(seconds: 2));
        expect(cubit.state, isA<PaymentPollingFailed>());
        verify(() => mockRepo.fetchOrderStatus('order-3')).called(3);

        cubit.close();
      });
    });

    test('reset returns the cubit to idle and stops polling', () {
      fakeAsync((async) {
        when(
          () => mockRepo.fetchOrderStatus('order-4'),
        ).thenAnswer((_) async => const OrderResponse(
              id: 'order-4',
              status: OrderStatus.pending,
            ));

        final cubit = PaymentPollingCubit(
          mockRepo,
          pollInterval: const Duration(seconds: 2),
        );

        cubit.start('order-4');
        cubit.reset();
        expect(cubit.state, isA<PaymentPollingIdle>());

        // Timer should be cancelled — no further calls after reset.
        async.elapse(const Duration(seconds: 10));
        verifyNever(() => mockRepo.fetchOrderStatus('order-4'));

        cubit.close();
      });
    });
  });
}
