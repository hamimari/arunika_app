import 'package:arunika_app/data/repositories/payment_repository.dart';
import 'package:arunika_app/presentation/screens/payment/payment_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPaymentRepository extends Mock implements PaymentRepository {}

void main() {
  late MockPaymentRepository repo;

  setUp(() {
    repo = MockPaymentRepository();
  });

  group('PaymentCubit', () {
    blocTest<PaymentCubit, PaymentState>(
      'emits PaymentSnapReady on createTransaction success',
      build: () => PaymentCubit(repository: repo),
      setUp: () {
        when(() => repo.createTransaction()).thenAnswer(
          (_) async => const SnapTransactionResult(
            token: 'tok-123',
            redirectUrl: 'https://app.midtrans.com/snap/v2/vtweb/tok-123',
          ),
        );
      },
      act: (cubit) => cubit.createTransaction(),
      expect: () => [
        PaymentLoading(),
        const PaymentSnapReady(
          'https://app.midtrans.com/snap/v2/vtweb/tok-123',
        ),
      ],
    );

    blocTest<PaymentCubit, PaymentState>(
      'emits PaymentError on createTransaction failure',
      build: () => PaymentCubit(repository: repo),
      setUp: () {
        when(
          () => repo.createTransaction(),
        ).thenThrow(Exception('payment failed'));
      },
      act: (cubit) => cubit.createTransaction(),
      expect: () => [PaymentLoading(), isA<PaymentError>()],
    );
  });
}
