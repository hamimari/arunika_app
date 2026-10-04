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
      emit(state.copyWith(isLoading: true, clearError: true));
      try {
        await repository.forgotPassword(event.email);
        emit(
          state.copyWith(
            email: event.email,
            isSubmitted: true,
            isLoading: false,
          ),
        );
      } on DioException catch (e) {
        // Reset the button regardless of error type — otherwise the spinner
        // is left stuck forever — and surface a message so the user knows
        // the request actually failed instead of silently doing nothing.
        final data = e.response?.data;
        final serverMessage = data is Map ? data['error'] as String? : null;
        emit(
          state.copyWith(
            isLoading: false,
            error:
                serverMessage ??
                'Gagal mengirim link reset kata sandi. Coba lagi.',
          ),
        );
      } catch (_) {
        emit(
          state.copyWith(
            isLoading: false,
            error: 'Gagal mengirim link reset kata sandi. Coba lagi.',
          ),
        );
      }
    });
  }
}
