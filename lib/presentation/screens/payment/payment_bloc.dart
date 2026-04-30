import 'package:arunika_app/data/repositories/payment_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();
  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentSnapReady extends PaymentState {
  final String redirectUrl;
  const PaymentSnapReady(this.redirectUrl);
  @override
  List<Object?> get props => [redirectUrl];
}

class PaymentError extends PaymentState {
  final String message;
  const PaymentError(this.message);
  @override
  List<Object?> get props => [message];
}

class PaymentCubit extends Cubit<PaymentState> {
  final PaymentRepository repository;
  PaymentCubit({required this.repository}) : super(PaymentInitial());

  Future<void> createTransaction() async {
    emit(PaymentLoading());
    try {
      final result = await repository.createTransaction();
      emit(PaymentSnapReady(result.redirectUrl));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }
}
