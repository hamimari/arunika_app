import 'dart:async';

import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/data/models/request/signin_request.dart';
import 'package:arunika_app/data/models/response/child_response.dart';
import 'package:arunika_app/data/models/response/signin_response.dart';
import 'package:arunika_app/data/models/response/user_response.dart';
import 'package:arunika_app/data/repositories/auth_repository.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/signin/signin_bloc.dart';
import 'package:arunika_app/presentation/screens/signin/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockAuthNotifier extends Mock implements AuthNotifier {}

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  Widget buildApp() {
    final router = GoRouter(
      initialLocation: '/signin',
      routes: [
        GoRoute(
          path: '/signin',
          builder: (_, __) => BlocProvider(
            create: (_) => SigninBloc(
              repository: mockAuthRepo,
              userRepository: mockUserRepo,
            ),
            child: const SignInScreen(),
          ),
        ),
        GoRoute(
          path: '/shell',
          builder: (_, __) => const Scaffold(body: Text('Shell')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets(
    'shows a spinner and ignores extra taps while signing in',
    (tester) async {
      final completer = Completer<SignInResponse>();
      when(
        () => mockAuthRepo.signin(any()),
      ).thenAnswer((_) => completer.future);
      when(
        () => mockUserRepo.findById(any()),
      ).thenAnswer((_) async => _userResponse());

      await tester.pumpWidget(buildApp());

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'user@example.com');
      await tester.enterText(fields.at(1), 'password123');

      expect(find.text('Masuk'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text('Masuk'));
      await tester.pump();

      // Spinner replaces the label while the request is in flight.
      expect(find.text('Masuk'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Tapping again while loading must not fire a second signin() call.
      await tester.tap(find.byType(CircularProgressIndicator), warnIfMissed: false);
      await tester.pump();
      verify(() => mockAuthRepo.signin(any())).called(1);

      completer.complete(
        SignInResponse(
          token: 'tok',
          refreshToken: 'ref',
          userId: 'user-1',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Shell'), findsOneWidget);
    },
  );
}
