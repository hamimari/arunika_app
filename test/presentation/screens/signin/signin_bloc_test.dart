// ignore_for_file: inference_failure_on_function_invocation

import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/data/models/request/signin_request.dart';
import 'package:arunika_app/data/models/response/child_response.dart';
import 'package:arunika_app/data/models/response/signin_response.dart';
import 'package:arunika_app/data/models/response/user_response.dart';
import 'package:arunika_app/data/repositories/auth_repository.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/signin/signin_bloc.dart';
import 'package:arunika_app/presentation/screens/signin/signin_event.dart';
import 'package:arunika_app/presentation/screens/signin/signin_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockAuthNotifier extends Mock implements AuthNotifier {}

// ── Helpers ───────────────────────────────────────────────────────────────────

SignInResponse _signInResponse() => SignInResponse(
  token: 'access-token',
  refreshToken: 'refresh-token',
  userId: 'user-1',
);

UserResponse _userResponse() => UserResponse(
  id: 'user-1',
  name: 'Test User',
  phoneNumber: '08123456789',
  emailAddress: 'test@example.com',
  address: 'Jl. Test',
  city: 'Jakarta',
  children: [
    ChildResponse(
      id: 'child-1',
      name: 'Child',
      gender: 'male',
      dateOfBirth: '2020-01-01',
    ),
  ],
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock flutter_secure_storage method channel so unit tests don't need a
  // real platform implementation.
  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUpAll(() {
    registerFallbackValue(SignInRequest(email: '', password: ''));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          secureStorageChannel,
          (MethodCall call) async => null,
        );
  });

  late MockAuthRepository mockAuthRepo;
  late MockUserRepository mockUserRepo;
  late MockAuthNotifier mockAuthNotifier;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAuthRepo = MockAuthRepository();
    mockUserRepo = MockUserRepository();
    mockAuthNotifier = MockAuthNotifier();

    // Register mock AuthNotifier so SigninBloc can call locator<AuthNotifier>()
    if (locator.isRegistered<AuthNotifier>()) {
      locator.unregister<AuthNotifier>();
    }
    locator.registerSingleton<AuthNotifier>(mockAuthNotifier);
    when(() => mockAuthNotifier.checkAuth()).thenAnswer((_) async {});
  });

  tearDown(() {
    if (locator.isRegistered<AuthNotifier>()) {
      locator.unregister<AuthNotifier>();
    }
  });

  group('SigninBloc — field validation', () {
    blocTest<SigninBloc, SigninState>(
      'EmailChanged updates email and clears emailError',
      build: () =>
          SigninBloc(repository: mockAuthRepo, userRepository: mockUserRepo),
      act: (b) => b.add(EmailChanged('user@example.com')),
      expect: () => [
        isA<SigninState>().having((s) => s.email, 'email', 'user@example.com'),
      ],
    );

    blocTest<SigninBloc, SigninState>(
      'PasswordChanged updates password',
      build: () =>
          SigninBloc(repository: mockAuthRepo, userRepository: mockUserRepo),
      act: (b) => b.add(PasswordChanged('secret')),
      expect: () => [
        isA<SigninState>().having((s) => s.password, 'password', 'secret'),
      ],
    );

    blocTest<SigninBloc, SigninState>(
      'SigninSubmitted emits validation errors when fields are empty',
      build: () =>
          SigninBloc(repository: mockAuthRepo, userRepository: mockUserRepo),
      act: (b) => b.add(SigninSubmitted()),
      expect: () => [
        isA<SigninState>().having((s) => s.emailError, 'emailError', isNotNull),
      ],
    );
  });

  group('SigninBloc — sign in submitted', () {
    blocTest<SigninBloc, SigninState>(
      'emits isSuccess=true on successful sign-in',
      build: () {
        when(
          () => mockAuthRepo.signin(any()),
        ).thenAnswer((_) async => _signInResponse());
        when(
          () => mockUserRepo.findById('user-1'),
        ).thenAnswer((_) async => _userResponse());
        return SigninBloc(
          repository: mockAuthRepo,
          userRepository: mockUserRepo,
        );
      },
      seed: () => SigninState(email: 'test@example.com', password: 'pass123'),
      act: (b) => b.add(SigninSubmitted()),
      expect: () => [
        isA<SigninState>().having((s) => s.isLoading, 'loading', true),
        isA<SigninState>().having((s) => s.isSuccess, 'success', true),
      ],
    );

    blocTest<SigninBloc, SigninState>(
      'emits passwordError on 401 DioException',
      build: () {
        when(() => mockAuthRepo.signin(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/signin'),
            response: Response(
              requestOptions: RequestOptions(path: '/signin'),
              statusCode: 401,
            ),
            type: DioExceptionType.badResponse,
          ),
        );
        return SigninBloc(
          repository: mockAuthRepo,
          userRepository: mockUserRepo,
        );
      },
      seed: () => SigninState(email: 'test@example.com', password: 'wrong'),
      act: (b) => b.add(SigninSubmitted()),
      errors: () => [isA<DioException>()],
      expect: () => [
        isA<SigninState>().having((s) => s.isLoading, 'loading', true),
        isA<SigninState>().having(
          (s) => s.passwordError,
          'passwordError',
          isNotNull,
        ),
      ],
    );

    blocTest<SigninBloc, SigninState>(
      'emits error message on network DioException',
      build: () {
        when(() => mockAuthRepo.signin(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/signin'),
            response: Response(
              requestOptions: RequestOptions(path: '/signin'),
              statusCode: 500,
              data: {'error': 'Server error'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );
        return SigninBloc(
          repository: mockAuthRepo,
          userRepository: mockUserRepo,
        );
      },
      seed: () => SigninState(email: 'test@example.com', password: 'pass'),
      act: (b) => b.add(SigninSubmitted()),
      errors: () => [isA<DioException>()],
      expect: () => [
        isA<SigninState>().having((s) => s.isLoading, 'loading', true),
        isA<SigninState>().having((s) => s.isLoading, 'notLoading', false),
      ],
    );
  });
}
