import 'package:arunika_app/data/models/response/order_response.dart';
import 'package:arunika_app/data/models/response/payment_history_item.dart';
import 'package:arunika_app/data/repositories/order_repository.dart';
import 'package:arunika_app/presentation/screens/payment_history/payment_history_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

PaymentHistoryItem _item(String id) => PaymentHistoryItem(
  orderId: id,
  itemType: PaymentItemType.arCard,
  itemName: 'Kartu $id',
  amountIdr: 15000,
  status: OrderStatus.paid,
  paymentMethod: 'GoPay',
  createdAt: DateTime(2026, 9, 1),
  updatedAt: DateTime(2026, 9, 1),
);

void main() {
  late MockOrderRepository repo;

  setUp(() => repo = MockOrderRepository());

  blocTest<PaymentHistoryCubit, PaymentHistoryState>(
    'load emits loading then the first page',
    build: () {
      when(() => repo.fetchPaymentHistory(page: 1, perPage: 20)).thenAnswer(
        (_) async => PaymentHistoryPage(items: [_item('a')], total: 1),
      );
      return PaymentHistoryCubit(repo);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const PaymentHistoryState(isLoading: true),
      PaymentHistoryState(items: [_item('a')], total: 1, page: 1),
    ],
  );

  blocTest<PaymentHistoryCubit, PaymentHistoryState>(
    'load failure with nothing shown emits an error',
    build: () {
      when(
        () => repo.fetchPaymentHistory(page: 1, perPage: 20),
      ).thenThrow(Exception('offline'));
      return PaymentHistoryCubit(repo);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const PaymentHistoryState(isLoading: true),
      const PaymentHistoryState(error: PaymentHistoryCubit.loadError),
    ],
  );

  blocTest<PaymentHistoryCubit, PaymentHistoryState>(
    'loadMore appends the next page and skips duplicates',
    build: () {
      when(() => repo.fetchPaymentHistory(page: 2, perPage: 20)).thenAnswer(
        (_) async =>
            PaymentHistoryPage(items: [_item('b'), _item('c')], total: 3),
      );
      return PaymentHistoryCubit(repo);
    },
    seed: () =>
        PaymentHistoryState(items: [_item('a'), _item('b')], total: 3, page: 1),
    act: (cubit) => cubit.loadMore(),
    expect: () => [
      PaymentHistoryState(
        items: [_item('a'), _item('b')],
        total: 3,
        page: 1,
        isLoadingMore: true,
      ),
      PaymentHistoryState(
        items: [_item('a'), _item('b'), _item('c')],
        total: 3,
        page: 2,
      ),
    ],
  );

  blocTest<PaymentHistoryCubit, PaymentHistoryState>(
    'loadMore does nothing when every order is loaded',
    build: () => PaymentHistoryCubit(repo),
    seed: () => PaymentHistoryState(items: [_item('a')], total: 1, page: 1),
    act: (cubit) => cubit.loadMore(),
    expect: () => <PaymentHistoryState>[],
    verify: (_) => verifyNever(
      () => repo.fetchPaymentHistory(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ),
  );
}
