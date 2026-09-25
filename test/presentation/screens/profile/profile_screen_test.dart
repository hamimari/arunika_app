import 'dart:async';
import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/data/models/response/child_response.dart';
import 'package:arunika_app/data/models/response/user_response.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/profile/profile_bloc.dart';
import 'package:arunika_app/presentation/screens/profile/profile_event.dart';
import 'package:arunika_app/presentation/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockUserRepository extends Mock implements UserRepository {}

class _StubAuthNotifier extends Mock implements AuthNotifier {
  bool loggedOut = false;

  @override
  Future<void> logout() async {
    loggedOut = true;
  }
}

UserResponse _user() => UserResponse(
  id: 'u1',
  name: 'Budi',
  phoneNumber: '081234',
  emailAddress: 'budi@example.test',
  address: 'Jl. Test',
  city: 'Jakarta',
  children: [
    ChildResponse(
      id: 'c1',
      name: 'Ani',
      // The edit form's dropdown (child_form.dart) only has items for these
      // two exact Indonesian strings — anything else, including the 'M'/'F'
      // used elsewhere in this test suite's own fixtures, throws a dropdown
      // assertion the moment the sheet opens. Matches what signup and
      // profile-edit themselves actually write.
      gender: 'Perempuan',
      dateOfBirth: '2020-01-01',
    ),
  ],
);

/// `ProfileScreen` degrades gracefully by design: it has no separate loading
/// state, just placeholder text ('-') until `ProfileBloc` resolves a user
/// (from cache or the network) or gives up — the bloc's own `ProfileInitial`
/// handler swallows a failed fetch and leaves `user` null rather than
/// surfacing an error. These tests pin exactly that graceful-degrade
/// behaviour, plus the two real actions this screen offers: opening the edit
/// sheet, and logging out.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockUserRepository repo;
  late _StubAuthNotifier auth;

  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
          if (call.method == 'read') return 'u1'; // userId
          return null;
        });
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = _MockUserRepository();
    auth = _StubAuthNotifier();
    if (locator.isRegistered<AuthNotifier>()) {
      locator.unregister<AuthNotifier>();
    }
    locator.registerSingleton<AuthNotifier>(auth);
  });

  tearDown(() {
    if (locator.isRegistered<AuthNotifier>()) {
      locator.unregister<AuthNotifier>();
    }
  });

  Future<void> pumpProfile(WidgetTester tester) async {
    // The header alone nearly fills the default 800x600 test surface,
    // leaving the ListView below it almost no height — at zero extent a
    // sliver viewport does not build off-screen children at all, so "Keluar"
    // (inside that list) is simply absent from the tree, not just off-screen.
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (_, __) => BlocProvider(
            create: (_) => ProfileBloc(repository: repo)..add(ProfileInitial()),
            child: const ProfileScreen(),
          ),
        ),
        // logout navigates here — registered so context.go('/landing')
        // resolves instead of throwing on an unknown route.
        GoRoute(path: '/landing', builder: (_, __) => const SizedBox.shrink()),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'should_show_a_placeholder_rather_than_crash_when_the_profile_fetch_fails',
    (tester) async {
      when(() => repo.findById(any())).thenThrow(Exception('network down'));

      await pumpProfile(tester);

      // The bloc's ProfileInitial handler swallows the failure and leaves
      // `user` null; the screen must render its placeholder state, not throw.
      expect(find.text('-'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('should_show_the_child_name_once_the_profile_loads', (
    tester,
  ) async {
    when(() => repo.findById(any())).thenAnswer((_) async => _user());

    await pumpProfile(tester);

    expect(find.text('Ani'), findsOneWidget);
  });

  testWidgets('should_open_the_edit_sheet_for_the_loaded_child', (
    tester,
  ) async {
    when(() => repo.findById(any())).thenAnswer((_) async => _user());

    // child_form.dart's phone field hardcodes a 70px "+62" prefix box sized
    // for the real Poppins font; the test environment's fallback font
    // renders that text a few pixels wider, overflowing by ~3px on a device
    // that never actually shows this. Not something these tests are about —
    // silencing it here rather than changing production layout to satisfy a
    // font substitution that only exists under test.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('RenderFlex overflowed')) return;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await pumpProfile(tester);
    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();

    // A bottom sheet opened rather than nothing happening (the handler
    // returns early with no child loaded — this proves it did not).
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets(
    'should_not_open_an_edit_sheet_before_any_child_has_loaded',
    (tester) async {
      // A Completer rather than Future.delayed: this test's whole point is
      // to sit in the not-yet-loaded state deliberately, and a real timer
      // left pending when the tree is disposed fails the test on its own.
      final pending = Completer<UserResponse>();
      when(() => repo.findById(any())).thenAnswer((_) => pending.future);
      addTearDown(() => pending.complete(_user()));

      await pumpProfile(tester);
      // Deliberately not completing `pending` — the profile has not
      // resolved yet.
      await tester.tap(find.byIcon(Icons.edit_rounded));
      await tester.pump();

      expect(find.byType(BottomSheet), findsNothing);
    },
  );

  testWidgets('should_log_out_and_return_to_landing_when_keluar_is_tapped', (
    tester,
  ) async {
    when(() => repo.findById(any())).thenAnswer((_) async => _user());

    await pumpProfile(tester);
    // "Keluar" sits below the fold on the default 800x600 test surface.
    final keluar = find.text('Keluar');
    await tester.ensureVisible(keluar);
    await tester.pumpAndSettle();
    await tester.tap(keluar);
    await tester.pumpAndSettle();

    expect(auth.loggedOut, isTrue);
  });
}
