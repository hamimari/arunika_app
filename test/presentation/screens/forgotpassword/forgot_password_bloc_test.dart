// ignore_for_file: inference_failure_on_function_invocation

import 'package:arunika_app/data/models/response/forgot_password_response.dart';
import 'package:arunika_app/data/repositories/auth_repository.dart';
import 'package:arunika_app/presentation/screens/forgotpassword/forgot_password_bloc.dart';
import 'package:arunika_app/presentation/screens/forgotpassword/forgot_password_event.dart';
import 'package:arunika_app/presentation/screens/forgotpassword/forgot_password_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;

  setUp(() => mockRepo = MockAuthRepository());

  group('ForgotPasswordBloc', () {
    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'emits isSubmitted=true on success',
      build: () {
        when(
          () => mockRepo.forgotPassword(any()),
        ).thenAnswer((_) async => ForgotPasswordResponse(message: 'ok'));
        return ForgotPasswordBloc(repository: mockRepo);
      },
      act: (b) => b.add(ForgotPasswordSubmitted('user@example.com')),
      expect: () => [
        isA<ForgotPasswordState>().having((s) => s.isLoading, 'loading', true),
        isA<ForgotPasswordState>()
            .having((s) => s.isSubmitted, 'submitted', true)
            .having((s) => s.email, 'email', 'user@example.com')
            .having((s) => s.isLoading, 'loading', false),
      ],
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'surfaces the server error message on a DioException failure',
      build: () {
        when(() => mockRepo.forgotPassword(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/forgot-password'),
            response: Response(
              requestOptions: RequestOptions(path: '/forgot-password'),
              statusCode: 404,
              data: {'error': 'Email not found'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );
        return ForgotPasswordBloc(repository: mockRepo);
      },
      act: (b) => b.add(ForgotPasswordSubmitted('unknown@example.com')),
      expect: () => [
        isA<ForgotPasswordState>().having((s) => s.isLoading, 'loading', true),
        isA<ForgotPasswordState>()
            .having((s) => s.isLoading, 'loading', false)
            .having((s) => s.isSubmitted, 'submitted', false)
            .having((s) => s.error, 'error', 'Email not found'),
      ],
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'falls back to a generic message when the DioException has no response body',
      build: () {
        when(() => mockRepo.forgotPassword(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/forgot-password'),
            type: DioExceptionType.connectionTimeout,
          ),
        );
        return ForgotPasswordBloc(repository: mockRepo);
      },
      act: (b) => b.add(ForgotPasswordSubmitted('user@example.com')),
      expect: () => [
        isA<ForgotPasswordState>().having((s) => s.isLoading, 'loading', true),
        isA<ForgotPasswordState>()
            .having((s) => s.isLoading, 'loading', false)
            .having(
              (s) => s.error,
              'error',
              'Gagal mengirim link reset kata sandi. Coba lagi.',
            ),
      ],
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'surfaces a generic message on a non-Dio failure',
      build: () {
        when(
          () => mockRepo.forgotPassword(any()),
        ).thenThrow(Exception('server error'));
        return ForgotPasswordBloc(repository: mockRepo);
      },
      act: (b) => b.add(ForgotPasswordSubmitted('user@example.com')),
      expect: () => [
        isA<ForgotPasswordState>().having((s) => s.isLoading, 'loading', true),
        isA<ForgotPasswordState>()
            .having((s) => s.isLoading, 'loading', false)
            .having(
              (s) => s.error,
              'error',
              'Gagal mengirim link reset kata sandi. Coba lagi.',
            ),
      ],
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'a resubmission clears a previous error',
      build: () {
        var callCount = 0;
        when(() => mockRepo.forgotPassword(any())).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            throw Exception('server error');
          }
          return ForgotPasswordResponse(message: 'ok');
        });
        return ForgotPasswordBloc(repository: mockRepo);
      },
      act: (b) async {
        b.add(ForgotPasswordSubmitted('user@example.com'));
        await Future.delayed(Duration.zero);
        b.add(ForgotPasswordSubmitted('user@example.com'));
      },
      skip: 2, // [loading, error]
      expect: () => [
        isA<ForgotPasswordState>()
            .having((s) => s.isLoading, 'loading', true)
            .having((s) => s.error, 'error', isNull),
        isA<ForgotPasswordState>()
            .having((s) => s.isSubmitted, 'submitted', true)
            .having((s) => s.error, 'error', isNull),
      ],
    );
  });
}
