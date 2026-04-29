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
        isA<ForgotPasswordState>()
            .having((s) => s.isSubmitted, 'submitted', true)
            .having((s) => s.email, 'email', 'user@example.com'),
      ],
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'rethrows DioException on failure',
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
      errors: () => [isA<DioException>()],
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'rethrows generic exception on server error',
      build: () {
        when(
          () => mockRepo.forgotPassword(any()),
        ).thenThrow(Exception('server error'));
        return ForgotPasswordBloc(repository: mockRepo);
      },
      act: (b) => b.add(ForgotPasswordSubmitted('user@example.com')),
      errors: () => [isA<Exception>()],
    );
  });
}
