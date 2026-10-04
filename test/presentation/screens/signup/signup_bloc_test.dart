// ignore_for_file: inference_failure_on_function_invocation

import 'package:arunika_app/core/legal/legal_versions.dart';
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
  tncAccepted: true,
  parentalConsentAccepted: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Records what the bloc persisted to secure storage.
  final secureWrites = <String, String?>{};

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
        .setMockMethodCallHandler(secureStorageChannel, (
          MethodCall call,
        ) async {
          if (call.method == 'write') {
            final args = Map<String, dynamic>.from(call.arguments as Map);
            secureWrites[args['key'] as String] = args['value'] as String?;
          }
          return null;
        });
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
      'NextButtonPressed with valid fields checks availability then emits navigateToChild=true',
      build: () {
        when(
          () => mockRepo.checkAvailability(
            email: any(named: 'email'),
            phone: any(named: 'phone'),
          ),
        ).thenAnswer((_) async => (false, false));
        return SignupBloc(repository: mockRepo);
      },
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
          (s) => s.isCheckingAvailability,
          'checking',
          true,
        ),
        isA<SignupState>()
            .having((s) => s.isCheckingAvailability, 'checking', false)
            .having((s) => s.navigateToChild, 'navigateToChild', true),
      ],
    );

    blocTest<SignupBloc, SignupState>(
      'NextButtonPressed with a taken email emits emailError and does not navigate',
      build: () {
        when(
          () => mockRepo.checkAvailability(
            email: any(named: 'email'),
            phone: any(named: 'phone'),
          ),
        ).thenAnswer((_) async => (true, false));
        return SignupBloc(repository: mockRepo);
      },
      seed: () => SignupState(
        name: 'Parent',
        phone: '08123456789',
        email: 'taken@example.com',
        address: 'Jl. Test',
        city: 'Jakarta',
        password: 'Pass1234',
      ),
      act: (b) => b.add(NextButtonPressed()),
      expect: () => [
        isA<SignupState>().having(
          (s) => s.isCheckingAvailability,
          'checking',
          true,
        ),
        isA<SignupState>()
            .having((s) => s.isCheckingAvailability, 'checking', false)
            .having((s) => s.emailError, 'emailError', isNotNull)
            .having((s) => s.navigateToChild, 'navigateToChild', false),
      ],
    );

    blocTest<SignupBloc, SignupState>(
      'NextButtonPressed with a taken phone emits phoneError and does not navigate',
      build: () {
        when(
          () => mockRepo.checkAvailability(
            email: any(named: 'email'),
            phone: any(named: 'phone'),
          ),
        ).thenAnswer((_) async => (false, true));
        return SignupBloc(repository: mockRepo);
      },
      seed: () => SignupState(
        name: 'Parent',
        phone: '08199999999',
        email: 'parent@example.com',
        address: 'Jl. Test',
        city: 'Jakarta',
        password: 'Pass1234',
      ),
      act: (b) => b.add(NextButtonPressed()),
      expect: () => [
        isA<SignupState>().having(
          (s) => s.isCheckingAvailability,
          'checking',
          true,
        ),
        isA<SignupState>()
            .having((s) => s.isCheckingAvailability, 'checking', false)
            .having((s) => s.phoneError, 'phoneError', isNotNull)
            .having((s) => s.navigateToChild, 'navigateToChild', false),
      ],
    );

    blocTest<SignupBloc, SignupState>(
      'NextButtonPressed still navigates when the availability check itself fails',
      build: () {
        when(
          () => mockRepo.checkAvailability(
            email: any(named: 'email'),
            phone: any(named: 'phone'),
          ),
        ).thenThrow(Exception('network error'));
        return SignupBloc(repository: mockRepo);
      },
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
          (s) => s.isCheckingAvailability,
          'checking',
          true,
        ),
        isA<SignupState>()
            .having((s) => s.isCheckingAvailability, 'checking', false)
            .having((s) => s.navigateToChild, 'navigateToChild', true),
      ],
    );
  });

  group('SignupBloc — consent', () {
    test('consent is given only when both boxes are ticked', () {
      expect(SignupState().consentGiven, isFalse);
      expect(SignupState(tncAccepted: true).consentGiven, isFalse);
      expect(SignupState(parentalConsentAccepted: true).consentGiven, isFalse);
      expect(
        SignupState(
          tncAccepted: true,
          parentalConsentAccepted: true,
        ).consentGiven,
        isTrue,
      );
    });

    blocTest<SignupBloc, SignupState>(
      'ParentalConsentToggled flips only the parental box',
      build: () => SignupBloc(repository: mockRepo),
      act: (b) => b.add(ParentalConsentToggled(true)),
      expect: () => [
        isA<SignupState>()
            .having((s) => s.parentalConsentAccepted, 'parental', true)
            .having((s) => s.tncAccepted, 'tnc', false),
      ],
    );

    blocTest<SignupBloc, SignupState>(
      'SignupSubmitted without the parental declaration does nothing',
      build: () => SignupBloc(repository: mockRepo),
      seed: () => _filledParentState().copyWith(parentalConsentAccepted: false),
      act: (b) => b.add(SignupSubmitted()),
      expect: () => <SignupState>[],
      verify: (_) => verifyNever(() => mockRepo.signup(any())),
    );

    blocTest<SignupBloc, SignupState>(
      'SignupSubmitted without the terms box does nothing',
      build: () => SignupBloc(repository: mockRepo),
      seed: () => _filledParentState().copyWith(tncAccepted: false),
      act: (b) => b.add(SignupSubmitted()),
      expect: () => <SignupState>[],
      verify: (_) => verifyNever(() => mockRepo.signup(any())),
    );

    blocTest<SignupBloc, SignupState>(
      'SignupSubmitted sends the legal versions the app shows',
      build: () {
        when(
          () => mockRepo.signup(any()),
        ).thenAnswer((_) async => _signUpResponse());
        return SignupBloc(repository: mockRepo);
      },
      seed: _filledParentState,
      act: (b) => b.add(SignupSubmitted()),
      verify: (_) {
        final request =
            verify(() => mockRepo.signup(captureAny())).captured.single
                as SignUpRequest;
        expect(request.toJson()['consent'], {
          'terms_version': LegalVersions.terms,
          'privacy_version': LegalVersions.privacy,
          'parental_version': LegalVersions.parental,
        });
      },
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
      'SignupSubmitted stores the new user id, as sign-in does',
      setUp: secureWrites.clear,
      build: () {
        when(
          () => mockRepo.signup(any()),
        ).thenAnswer((_) async => _signUpResponse());
        return SignupBloc(repository: mockRepo);
      },
      seed: _filledParentState,
      act: (b) => b.add(SignupSubmitted()),
      verify: (_) {
        expect(secureWrites['user_id'], 'u1');
        expect(secureWrites['auth_token'], 'tok');
      },
    );

    blocTest<SignupBloc, SignupState>(
      'SignupSubmitted with empty child fields emits validation error',
      build: () => SignupBloc(repository: mockRepo),
      seed: () => SignupState(tncAccepted: true, parentalConsentAccepted: true),
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
