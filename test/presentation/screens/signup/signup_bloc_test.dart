// ignore_for_file: inference_failure_on_function_invocation

import 'package:arunika_app/data/models/request/signup_request.dart';
import 'package:arunika_app/data/models/response/child_response.dart';
import 'package:arunika_app/data/models/response/signup_response.dart';
import 'package:arunika_app/data/repositories/auth_repository.dart';
import 'package:arunika_app/presentation/screens/signup/signup_bloc.dart';
import 'package:arunika_app/presentation/screens/signup/signup_event.dart';
import 'package:arunika_app/presentation/screens/signup/signup_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

SignUpResponse _signUpResponse() => SignUpResponse(
  id: 'u1',
  name: 'Test',
  phoneNumber: '081',
  email: 'test@example.com',
  address: 'Jl.',
  city: 'Jkt',
  token: 'tok',
  refreshToken: 'ref',
  children: [
    ChildResponse(
      id: 'c1',
      name: 'Kid',
      gender: 'male',
      dateOfBirth: '2020-01-01',
    ),
  ],
);

SignupState _filledParentState() => SignupState(
  name: 'Parent',
  phone: '08123456789',
  email: 'parent@example.com',
  address: 'Jl. Test 1',
  city: 'Jakarta',
  password: 'Password1',
  navigateToChild: true,
  childName: 'Child',
  childGender: 'male',
  childBirthDate: DateTime(2020, 1, 1),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUpAll(() {
    registerFallbackValue(
      SignUpRequest(
        name: '',
        phoneNumber: '',
        email: '',
        address: '',
        city: '',
        password: '',
        child: ChildRequest(name: '', gender: '', dateOfBirth: ''),
      ),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          secureStorageChannel,
          (MethodCall call) async => null,
        );
  });

  late MockAuthRepository mockRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepo = MockAuthRepository();
  });

  group('SignupBloc — parent page validation', () {
    blocTest<SignupBloc, SignupState>(
      'NextButtonPressed with empty fields emits validation errors',
      build: () => SignupBloc(repository: mockRepo),
      act: (b) => b.add(NextButtonPressed()),
      expect: () => [
        isA<SignupState>().having((s) => s.nameError, 'nameError', isNotNull),
      ],
    );

    blocTest<SignupBloc, SignupState>(
      'NextButtonPressed with valid fields emits navigateToChild=true',
      build: () => SignupBloc(repository: mockRepo),
      seed: () => SignupState(
        name: 'Parent',
        phone: '08123456789',
        email: 'parent@example.com',
        address: 'Jl. Test',
        city: 'Jakarta',
        password: 'Pass1234',
      ),
      act: (b) => b.add(NextButtonPressed()),
      expect: () => [
        isA<SignupState>().having(
          (s) => s.navigateToChild,
          'navigateToChild',
          true,
        ),
      ],
    );
  });

  group('SignupBloc — submit', () {
    blocTest<SignupBloc, SignupState>(
      'SignupSubmitted succeeds and emits isSuccess=true',
      build: () {
        when(
          () => mockRepo.signup(any()),
        ).thenAnswer((_) async => _signUpResponse());
        return SignupBloc(repository: mockRepo);
      },
      seed: _filledParentState,
      act: (b) => b.add(SignupSubmitted()),
      expect: () => [
        isA<SignupState>().having((s) => s.isSubmitting, 'submitting', true),
        isA<SignupState>().having((s) => s.isSuccess, 'success', true),
      ],
    );

    blocTest<SignupBloc, SignupState>(
      'SignupSubmitted with empty child fields emits validation error',
      build: () => SignupBloc(repository: mockRepo),
      act: (b) => b.add(SignupSubmitted()),
      expect: () => [
        isA<SignupState>().having(
          (s) => s.childNameError,
          'childNameError',
          isNotNull,
        ),
      ],
    );

    blocTest<SignupBloc, SignupState>(
      'SignupSubmitted on DioException emits error message',
      build: () {
        when(() => mockRepo.signup(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/signup'),
            response: Response(
              requestOptions: RequestOptions(path: '/signup'),
              statusCode: 422,
              data: {'error': 'Email already taken'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );
        return SignupBloc(repository: mockRepo);
      },
      seed: _filledParentState,
      act: (b) => b.add(SignupSubmitted()),
      expect: () => [
        isA<SignupState>().having((s) => s.isSubmitting, 'submitting', true),
        isA<SignupState>().having((s) => s.error, 'error', isNotNull),
      ],
    );

    blocTest<SignupBloc, SignupState>(
      'SignupSubmitted on generic exception emits generic error',
      build: () {
        when(() => mockRepo.signup(any())).thenThrow(Exception('unknown'));
        return SignupBloc(repository: mockRepo);
      },
      seed: _filledParentState,
      act: (b) => b.add(SignupSubmitted()),
      expect: () => [
        isA<SignupState>().having((s) => s.isSubmitting, 'submitting', true),
        isA<SignupState>().having((s) => s.error, 'error', isNotNull),
      ],
    );
  });
}
