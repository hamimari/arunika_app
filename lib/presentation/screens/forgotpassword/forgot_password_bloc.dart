import 'package:arunika_app/data/repositories/auth_repository.dart';
import 'package:arunika_app/presentation/screens/forgotpassword/forgot_password_event.dart';
import 'package:arunika_app/presentation/screens/forgotpassword/forgot_password_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final AuthRepository repository;
  ForgotPasswordBloc({required this.repository})
    : super(ForgotPasswordState()) {
    on<ForgotPasswordSubmitted>((event, emit) async {
      try {
        await repository.forgotPassword(event.email);
        emit(state.copyWith(email: event.email, isSubmitted: true));
      } on DioException {
        rethrow;
      }
    });
  }
}
