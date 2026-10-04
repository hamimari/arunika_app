import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/storage/LocalProfileStorage.dart';
import 'package:arunika_app/core/storage/SecureStorageToken.dart';
import 'package:arunika_app/data/models/request/signin_request.dart';
import 'package:arunika_app/data/models/response/signin_response.dart';
import 'package:arunika_app/data/models/response/user_response.dart';
import 'package:arunika_app/data/repositories/auth_repository.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/signin/signin_event.dart';
import 'package:arunika_app/presentation/screens/signin/signin_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SigninBloc extends Bloc<SigninEvent, SigninState> {
  final AuthRepository repository;
  final UserRepository userRepository;

  SigninBloc({required this.repository, required this.userRepository})
    : super(SigninInitial()) {
    on<EmailChanged>((event, emit) {
      emit(state.copyWith(email: event.email, emailError: null));
    });
    on<PasswordChanged>((event, emit) {
      emit(state.copyWith(password: event.password, passwordError: null));
    });
    on<ObscurePasswordToggled>((event, emit) {
      emit(state.copyWith(obscurePassword: event.obscure));
    });

    on<SigninSubmitted>((event, emit) async {
      final emailError = state.email.isEmpty
          ? 'Email tidak boleh kosong'
          : !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(state.email)
          ? 'Format email tidak valid'
          : null;
      final passwordError = state.password.isEmpty
          ? 'Kata sandi tidak boleh kosong'
          : null;

      final hasError = [
        emailError,
        passwordError,
      ].any((error) => error != null);

      if (hasError) {
        emit(
          state.copyWith(emailError: emailError, passwordError: passwordError),
        );
      } else {
        emit(state.copyWith(isLoading: true));
        final request = SignInRequest(
          email: state.email,
          password: state.password,
        );
        try {
          final SignInResponse response = await repository.signin(request);

          await SecureTokenStorage.saveToken(response.token);
          await SecureTokenStorage.saveRefreshToken(response.refreshToken);
          await SecureTokenStorage.saveUserId(response.userId);
          locator<AuthNotifier>().checkAuth();
          final UserResponse userResponse = await userRepository.findById(
            response.userId,
          );
          if (userResponse.name.isEmpty) {
            emit(
              state.copyWith(
                isLoading: false,
                error:
                    'Sedang terjadi kesalahan, silakan coba beberapa saat lagi',
                isSuccess: false,
              ),
            );
            return;
          }
          await LocalProfileStorage.save(userResponse);

          emit(state.copyWith(isLoading: false, isSuccess: true));
        } on DioException catch (e) {
          if (e.response != null &&
              e.response!.statusCode != null &&
              e.response!.statusCode! >= 400 &&
              e.response!.statusCode! < 500) {
            emit(
              state.copyWith(
                isLoading: false,
                passwordError: 'Email atau kata sandi salah',
                isSuccess: false,
              ),
            );
          } else {
            emit(
              state.copyWith(
                isLoading: false,
                error:
                    e.response!.data['error'] ??
                    'Sedang terjadi kesalahan, silakan coba beberapa saat lagi',
                isSuccess: false,
              ),
            );
          }
          rethrow;
        }
      }
    });
  }
}
