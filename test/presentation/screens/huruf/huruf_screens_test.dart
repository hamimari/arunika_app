import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/feature_flags/feature_flags_notifier.dart';
import 'package:arunika_app/core/utils/parental_gate_session.dart';
import 'package:arunika_app/data/api/feature_flag_api.dart';
import 'package:arunika_app/data/repositories/huruf_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/belajar/belajar_hub_screen.dart';
import 'package:arunika_app/presentation/screens/home/home_continue_learning.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_audio.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_cubit.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_detail_screen.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_list_screen.dart';
import 'package:arunika_app/presentation/screens/widgets/parental_gate_guard.dart';
import 'package:arunika_app/presentation/screens/widgets/parental_gate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_huruf_api.dart';

class _FlagApi extends Mock implements FeatureFlagApi {}

class _Auth extends AuthNotifier {
  bool loggedIn = true;
  @override
  bool get isLoggedIn => loggedIn;
}

class _FakeAudio implements HurufAudio {
  final List<String> played = [];
  bool works = true;

  @override
  Future<bool> play(String url) async {
    played.add(url);
    return works;
  }

  @override
  void dispose() {}
}

void main() {
  late FakeHurufApi api;
  late HurufCubit cubit;
  late _FakeAudio audio;
  late _FlagApi flagApi;
  late FeatureFlagsNotifier flags;
  late _Auth auth;

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    ParentalGateSession.passed = false;
    api = FakeHurufApi();
    audio = _FakeAudio();
    flagApi = _FlagApi();
    when(
      () => flagApi.fetchFlags(),
    ).thenAnswer((_) async => {'belajar_huruf': true});
    flags = FeatureFlagsNotifier(flagApi);
    await flags.refresh();
    auth = _Auth();
    locator.registerSingleton<AuthNotifier>(auth);
    locator.registerSingleton<FeatureFlagsNotifier>(flags);
    cubit = HurufCubit(
      repository: HurufRepository(api, sleep: (_) async {}),
      enabled: () => true,
      childId: () async => 'c1',
    );
  });

  tearDown(() async {
    await cubit.close();
    await locator.reset();
  });

  Widget app() {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => HurufListScreen(
            detailBuilder: (l, start) => HurufDetailScreen(
              letter: l,
              initialActivity: start,
              audioFactory: () => audio,
            ),
          ),
        ),
        GoRoute(
          path: '/premium',
          builder: (context, __) => ParentalGateGuard(
            child: Scaffold(
              body: TextButton(
                onPressed: () => context.pop(),
                child: const Text('paywall'),
              ),
            ),
          ),
        ),
      ],
    );
    return BlocProvider.value(
      value: cubit,
      child: MaterialApp.router(routerConfig: router),
    );
  }

  Future<void> openLetter(WidgetTester tester, String upper) async {
    await tester.tap(find.byKey(ValueKey('huruf-tile-$upper')));
    await tester.pumpAndSettle();
  }

  Future<void> traceAcross(WidgetTester tester, {double to = 260}) async {
    final canvas = find.byKey(const ValueKey('tracing-canvas'));
    await tester.ensureVisible(canvas);
    await tester.pumpAndSettle();
    final origin = tester.getTopLeft(canvas);
    final scale = tester.getSize(canvas).width / 300;
    Offset at(double x) => origin + Offset(x * scale, 150 * scale);
    final g = await tester.startGesture(at(40));
    for (var x = 45.0; x <= to; x += 5) {
      await g.moveTo(at(x));
    }
    await g.up();
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a non-subscriber sees the free letter open and the rest locked',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.text('Belajar Huruf'), findsOneWidget);
      expect(find.text('0 dari 3 selesai'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Huruf A, belum dimulai, gratis'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Huruf B, terkunci'), findsOneWidget);
      expect(find.text('Gratis'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsNWidgets(2));
      expect(find.text('Lanjutkan belajar'), findsNothing);
    },
  );

  testWidgets('a subscriber sees every letter open', (tester) async {
    api.premium = true;
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
    expect(find.text('Gratis'), findsNothing);
  });

  testWidgets('a locked tap goes through the parental gate', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openLetter(tester, 'B');
    expect(find.byType(ParentalGateScreen), findsOneWidget);
    expect(find.text('paywall'), findsNothing);
  });

  testWidgets('the grid unlocks in place after subscribing', (tester) async {
    ParentalGateSession.passed = true;
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openLetter(tester, 'B');
    expect(find.text('paywall'), findsOneWidget);

    api.premium = true; // the purchase went through
    await tester.tap(find.text('paywall'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
    expect(find.bySemanticsLabel('Huruf B, belum dimulai'), findsOneWidget);
  });

  testWidgets(
    'Kenali shows the picture and sounds; opening it completes Kenali',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await openLetter(tester, 'A');

      expect(find.text('Huruf A'), findsOneWidget);
      expect(find.byKey(const ValueKey('huruf-tab-dengar')), findsNothing);
      expect(api.progressBodies.first, {
        'kenali_done': true,
        'dengar_done': true,
      });
      expect(find.text('Kenali ✓'), findsOneWidget);
      expect(find.text('A a'), findsOneWidget);
      expect(find.byKey(const ValueKey('huruf-kenali-picture')), findsOne);

      await tester.tap(find.byKey(const ValueKey('huruf-letter-sound')));
      await tester.pumpAndSettle();
      expect(audio.played, ['https://media.test/A.mp3']);

      await tester.tap(find.byKey(const ValueKey('huruf-kenali-picture')));
      await tester.pumpAndSettle();
      expect(audio.played.last, 'https://media.test/A-word.mp3');

      await tester.ensureVisible(
        find.byKey(const ValueKey('huruf-kenali-next')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('huruf-kenali-next')));
      await tester.pumpAndSettle();
      expect(find.text('Tebalkan huruf A'), findsOneWidget);
    },
  );

  testWidgets('an audio failure shows a retry', (tester) async {
    audio.works = false;
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openLetter(tester, 'A');
    await tester.tap(find.byKey(const ValueKey('huruf-letter-sound')));
    await tester.pumpAndSettle();
    expect(find.text('Putar ulang'), findsOneWidget);
  });

  testWidgets('tracing the letter shows the success pop-up with the upsell', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openLetter(tester, 'A');
    await tester.tap(find.byKey(const ValueKey('huruf-tab-tebalkan')));
    await tester.pumpAndSettle();
    expect(find.text('Tebalkan huruf A'), findsOneWidget);

    await traceAcross(tester);
    expect(find.text('Keren! Huruf A rapi!'), findsOneWidget);
    expect(find.text('Kamu berhasil menebalkan huruf A.'), findsOneWidget);
    expect(find.text('Lanjut ke huruf B'), findsOneWidget);
    expect(find.text('Buka semua huruf'), findsOneWidget);
    final last = api.progressBodies.last;
    expect(last['tebalkan_done'], isTrue);
    expect(last['attempt'], isTrue);
    expect(last['score'], greaterThan(0.8));

    // The next letter is locked: the paywall opens behind the gate.
    await tester.tap(find.text('Lanjut ke huruf B'));
    await tester.pumpAndSettle();
    expect(find.byType(ParentalGateScreen), findsOneWidget);
  });

  testWidgets('subscribers get no upsell, and move on to the next letter', (
    tester,
  ) async {
    api.premium = true;
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openLetter(tester, 'A');
    await tester.tap(find.byKey(const ValueKey('huruf-tab-tebalkan')));
    await tester.pumpAndSettle();
    await traceAcross(tester);
    expect(find.text('Buka semua huruf'), findsNothing);
    await tester.tap(find.text('Lanjut ke huruf B'));
    await tester.pumpAndSettle();
    expect(find.text('Huruf B'), findsOneWidget);
  });

  testWidgets('three short attempts show the retry pop-up', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openLetter(tester, 'A');
    await tester.tap(find.byKey(const ValueKey('huruf-tab-tebalkan')));
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await traceAcross(tester, to: 120);
    }
    expect(find.text('Belum pas, ayo lagi!'), findsOneWidget);
    expect(find.text('Garisnya belum sampai ujung.'), findsOneWidget);
    expect(
      find.textContaining('Mulai dari angka 1', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Lihat contoh'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Belum pas, ayo lagi!'), findsNothing);
  });

  testWidgets('Selesai before finishing explains what is missing', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openLetter(tester, 'A');
    await tester.tap(find.byKey(const ValueKey('huruf-tab-tebalkan')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Selesai'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();
    expect(find.text('Garisnya belum sampai ujung.'), findsOneWidget);
  });

  testWidgets('the continue card opens the letter at its next activity', (
    tester,
  ) async {
    api.progressRows['id-A'] = {
      'letter_id': 'id-A',
      'kenali_done': true,
      'dengar_done': true,
      'tebalkan_done': false,
    };
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Lanjutkan belajar'), findsOneWidget);
    await tester.tap(find.byType(ContinueLetterCard));
    await tester.pumpAndSettle();
    expect(find.text('Tebalkan huruf A'), findsOneWidget);
  });

  testWidgets('fits a 360 dp phone with 140% text', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    api.progressRows['id-A'] = {
      'letter_id': 'id-A',
      'kenali_done': true,
      'dengar_done': false,
      'tebalkan_done': false,
    };
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 640),
          textScaler: TextScaler.linear(1.4),
        ),
        child: app(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(ContinueLetterCard));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('huruf-tab-tebalkan')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await traceAcross(tester);
    expect(find.text('Keren! Huruf A rapi!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('Belajar hub card', () {
    Widget hub({HurufCubit? withCubit}) {
      final screen = BelajarHubScreen(onOpen: (_) {});
      return MaterialApp(
        home: withCubit == null
            ? screen
            : BlocProvider.value(value: withCubit, child: screen),
      );
    }

    testWidgets('shows a Premium badge for non-subscribers', (tester) async {
      await cubit.load();
      await tester.pumpWidget(hub(withCubit: cubit));
      await tester.pumpAndSettle();
      expect(find.text('Huruf'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
    });

    testWidgets('no badge for subscribers', (tester) async {
      api.premium = true;
      await cubit.load(force: true);
      await tester.pumpWidget(hub(withCubit: cubit));
      await tester.pumpAndSettle();
      expect(find.text('Huruf'), findsOneWidget);
      expect(find.text('Premium'), findsNothing);
    });

    testWidgets('hidden while belajar_huruf is off', (tester) async {
      when(
        () => flagApi.fetchFlags(),
      ).thenAnswer((_) async => {'belajar_huruf': false});
      await flags.refresh();
      await tester.pumpWidget(hub());
      await tester.pumpAndSettle();
      expect(find.text('Huruf'), findsNothing);
      expect(find.text('Kartu AR'), findsOneWidget);
    });

    testWidgets('a guest is asked to sign in', (tester) async {
      auth.loggedIn = false;
      var opened = false;
      await tester.pumpWidget(
        MaterialApp(home: BelajarHubScreen(onOpen: (_) => opened = true)),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Huruf'));
      await tester.tap(find.text('Huruf'));
      await tester.pumpAndSettle();
      expect(opened, isFalse);
      expect(find.textContaining('Belajar Huruf'), findsWidgets);
    });
  });

  group('Beranda Lanjutkan belajar', () {
    Widget home() => MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: const HomeContinueLearning(),
        ),
      ),
    );

    testWidgets('shows the letter in progress', (tester) async {
      api.progressRows['id-A'] = {
        'letter_id': 'id-A',
        'kenali_done': true,
        'dengar_done': false,
        'tebalkan_done': false,
      };
      await cubit.load();
      await tester.pumpWidget(home());
      await tester.pumpAndSettle();
      expect(find.text('Huruf A'), findsOneWidget);
      expect(find.text('Tebalkan · 1/2'), findsOneWidget);
    });

    testWidgets('hidden with no letter in progress', (tester) async {
      await cubit.load();
      await tester.pumpWidget(home());
      await tester.pumpAndSettle();
      expect(find.text('Lanjutkan belajar'), findsNothing);
    });
  });
}
