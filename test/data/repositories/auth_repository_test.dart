// ignore_for_file: inference_failure_on_function_invocation

import 'package:arunika_app/data/api/auth_api.dart';
import 'package:arunika_app/data/models/request/signin_request.dart';
import 'package:arunika_app/data/models/request/signup_request.dart';
import 'package:arunika_app/data/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthApi extends Mock implements AuthApi {}

Map<String, dynamic> _signInJson() => {
  'access_token': 'tok',
  'refresh_token': 'ref',
  'user_id': 'u1',
};

Map<String, dynamic> _signUpJson() => {
  'data': {
    'id': 'u1',
    'name': 'Test',
    'phone_number': '081',
    'email': 'test@example.com',
    'address': 'Jl.',
    'city': 'Jkt',
    'token': 'tok',
    'refresh_token': 'ref',
    'child': <dynamic>[],
  },
};

Map<String, dynamic> _forgotPasswordJson() => {'message': 'ok'};

void main() {
  late MockAuthApi mockApi;
  late AuthRepository repo;

  setUp(() {
    mockApi = MockAuthApi();
    repo = AuthRepository(mockApi);
    registerFallbackValue(<String, dynamic>{});
  });

  group('AuthRepository', () {
    test('signin returns SignInResponse on success', () async {
      when(() => mockApi.signin(any())).thenAnswer((_) async => _signInJson());

      final result = await repo.signin(
        SignInRequest(email: 'e@e.com', password: 'p'),
      );

      expect(result.token, 'tok');
      expect(result.userId, 'u1');
    });

    test('signin propagates exception on failure', () async {
      when(() => mockApi.signin(any())).thenThrow(Exception('401'));

      expect(
        () => repo.signin(SignInRequest(email: 'e@e.com', password: 'bad')),
        throwsException,
      );
    });

    test('signup returns SignUpResponse on success', () async {
      when(() => mockApi.signup(any())).thenAnswer((_) async => _signUpJson());

      final result = await repo.signup(
        SignUpRequest(
          name: 'Test',
          phoneNumber: '081',
          email: 'test@example.com',
          address: 'Jl.',
          city: 'Jkt',
          password: 'pass',
          child: ChildRequest(
            name: 'Kid',
            gender: 'male',
            dateOfBirth: '2020-01-01',
          ),
        ),
      );

      expect(result.name, 'Test');
    });

    test('signup propagates exception on failure', () async {
      when(() => mockApi.signup(any())).thenThrow(Exception('error'));

      expect(
        () => repo.signup(
          SignUpRequest(
            name: '',
            phoneNumber: '',
            email: '',
            address: '',
            city: '',
            password: '',
            child: ChildRequest(name: '', gender: '', dateOfBirth: ''),
          ),
        ),
        throwsException,
      );
    });

    test('forgotPassword returns ForgotPasswordResponse on success', () async {
      when(
        () => mockApi.forgotPassword(any()),
      ).thenAnswer((_) async => _forgotPasswordJson());

      final result = await repo.forgotPassword('user@example.com');

      expect(result.message, 'ok');
    });

    test('forgotPassword propagates exception on failure', () async {
      when(() => mockApi.forgotPassword(any())).thenThrow(Exception('404'));

      expect(() => repo.forgotPassword('bad@example.com'), throwsException);
    });
  });
}
