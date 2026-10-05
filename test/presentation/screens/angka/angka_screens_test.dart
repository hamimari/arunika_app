import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/feature_flags/feature_flags_notifier.dart';
import 'package:arunika_app/core/utils/parental_gate_session.dart';
import 'package:arunika_app/data/api/feature_flag_api.dart';
import 'package:arunika_app/data/repositories/angka_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/angka/angka_cubit.dart';
import 'package:arunika_app/presentation/screens/angka/angka_screen.dart';
import 'package:arunika_app/presentation/screens/belajar/belajar_hub_screen.dart';
import 'package:arunika_app/presentation/screens/home/home_continue_learning.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_audio.dart';
import 'package:arunika_app/presentation/screens/widgets/parental_gate_guard.dart';
import 'package:arunika_app/presentation/screens/widgets/parental_gate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_angka_api.dart';

class _FlagApi extends Mock implements FeatureFlagApi {}

class _Auth extends AuthNotifier {
  bool loggedIn = true;
  @override
  bool get isLoggedIn => loggedIn;
}

class _FakeAudio implements HurufAudio {
  final List<String> played = [];

  @override
  Future<bool> play(String url) async {
    played.add(url);
    return true;
  }

  @override
  void dispose() {}
}

void main() {
  late FakeAngkaApi api;
  late AngkaCubit cubit;
  late _FakeAudio audio;
  late _FlagApi flagApi;
  late FeatureFlagsNotifier flags;
  late _Auth auth;

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    ParentalGateSession.passed = false;
    api = FakeAngkaApi();
    audio = _FakeAudio();
    flagApi = _FlagApi();
    when(
      () => flagApi.fetchFlags(),
    ).thenAnswer((_) async => {'belajar_angka': true});
    flags = FeatureFlagsNotifier(flagApi);
    await flags.refresh();
    auth = _Auth();
    locator.registerSingleton<AuthNotifier>(auth);
    locator.registerSingleton<FeatureFlagsNotifier>(flags);
    cubit = AngkaCubit(
      repository: AngkaRepository(api, sleep: (_) async {}),
      enabled: () => true,
      childId: () async => 'c1',
    );
  });

  tearDown(() async {
    await cubit.close();
    await locator.reset();
  });

  /// A phone-sized surface, so the number pad is on screen.
  void phone(WidgetTester tester, {Size size = const Size(400, 900)}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget app() {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => AngkaScreen(audioFactory: () => audio),
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

  Future<void> tapKey(WidgetTester tester, String key) async {
    final f = find.byKey(ValueKey(key));
    if (f.evaluate().isEmpty) {
      // Lazily built list items appear once scrolled to.
      await tester.scrollUntilVisible(
        f,
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> answer(WidgetTester tester, int n) async {
    for (final ch in '$n'.split('')) {
      await tapKey(tester, 'angka-key-$ch');
    }
    await tapKey(tester, 'angka-key-check');
  }

  int countOf(int q, [String session = 's1']) =>
      api.questionsOf(session)[q].count;

  Future<void> openLevel(WidgetTester tester, String id) =>
      tapKey(tester, 'angka-level-$id');

  testWidgets(
    'a non-subscriber sees the free sample open and the rest locked',
    (tester) async {
      phone(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.text('Belajar Angka'), findsOneWidget);
      expect(find.text('Kenal Angka'), findsOneWidget);
      expect(find.bySemanticsLabel('Angka 3, gratis'), findsOneWidget);
      expect(find.bySemanticsLabel('Angka 7, terkunci'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Level 1, Hitung 1 sampai 5, belum dimulai, gratis',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Level 2, Hitung 1 sampai 10, terkunci, perlu Akses Premium',
        ),
        findsOneWidget,
      );
      expect(find.text('Mulai'), findsOneWidget);
    },
  );

  testWidgets('a subscriber sees the prerequisite lock', (tester) async {
    api.premium = true;
    phone(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Selesaikan Level 1 untuk membuka'), findsOneWidget);
    expect(find.text('Selesaikan Level 2 untuk membuka'), findsOneWidget);
    expect(find.text('Gratis'), findsNothing);

    // Tapping a level behind its prerequisite does nothing.
    await openLevel(tester, 'l2');
    expect(find.text('Belajar Angka'), findsOneWidget);
    expect(api.calls.where((c) => c.startsWith('start')), isEmpty);
  });

  testWidgets('a locked tap goes through the parental gate', (tester) async {
    phone(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tapKey(tester, 'angka-number-7');
    expect(find.byType(ParentalGateScreen), findsOneWidget);
  });

  testWidgets('numbers and levels unlock in place after subscribing', (
    tester,
  ) async {
    ParentalGateSession.passed = true;
    phone(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openLevel(tester, 'l2');
    expect(find.text('paywall'), findsOneWidget);

    api.premium = true;
    await tester.tap(find.text('paywall'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Angka 7'), findsOneWidget);
    expect(find.text('Selesaikan Level 1 untuk membuka'), findsOneWidget);
  });

  testWidgets('a number card stays quiet until the speaker is tapped', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tapKey(tester, 'angka-number-3');

    expect(find.text('tiga'), findsOneWidget);
    expect(find.byKey(const ValueKey('angka-count-2')), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(audio.played, isEmpty, reason: 'nothing plays on open');

    await tester.tap(find.byKey(const ValueKey('angka-number-replay')));
    await tester.pump();
    expect(audio.played, ['https://media.test/n-3.mp3']);
    await tester.pump(const Duration(seconds: 4));
    expect(audio.played.skip(1), [
      'https://media.test/count-1.mp3',
      'https://media.test/count-2.mp3',
      'https://media.test/count-3.mp3',
    ]);
    await tester.pumpAndSettle();
  });

  testWidgets('a right answer shows the success pop-up with +1 bintang', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openLevel(tester, 'l1');

    expect(find.text('Level 1 · Soal 1 dari 10'), findsOneWidget);
    expect(audio.played, isEmpty, reason: 'the question plays only on tap');
    await tester.tap(find.byKey(const ValueKey('angka-question-speaker')));
    await tester.pump();
    expect(audio.played.single, startsWith('https://media.test/'));
    expect(
      tester
          .widget<Material>(
            find.descendant(
              of: find.byKey(const ValueKey('angka-key-check')),
              matching: find.byType(Material),
            ),
          )
          .color,
      isNot(const Color(0xFFC85A1A)),
      reason: 'Periksa is disabled with an empty box',
    );

    await answer(tester, countOf(0));
    expect(find.text('Hebat! Benar!'), findsOneWidget);
    expect(find.text('+1 bintang'), findsOneWidget);
    await tester.tap(find.text('Soal berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text('Level 1 · Soal 2 dari 10'), findsOneWidget);
    final star = find.byKey(const ValueKey('angka-star-count'));
    expect(find.descendant(of: star, matching: find.text('1')), findsOneWidget);
  });

  testWidgets('wrong answers show the hint until the child gets it right', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openLevel(tester, 'l1');
    final n = countOf(0);
    await answer(tester, n + 1);
    expect(find.text('Hampir benar!'), findsOneWidget);
    expect(find.textContaining('Jawabanmu ${n + 1}.'), findsOneWidget);
    expect(
      find.textContaining('satu per satu sambil menyebut'),
      findsOneWidget,
    );
    expect(find.textContaining('{benda}'), findsNothing);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    // There's no try limit and the answer is never given away.
    for (var wrong = 2; wrong <= 4; wrong++) {
      await answer(tester, n + wrong);
      expect(find.textContaining('Jawabanmu ${n + wrong}.'), findsOneWidget);
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Level 1 · Soal 1 dari 10'), findsOneWidget);
    }
    expect(audio.played.where((u) => u.contains('count-')), isEmpty);

    await answer(tester, n);
    expect(find.text('Hebat! Benar!'), findsOneWidget);
    expect(find.text('+1 bintang'), findsNothing);
    await tester.tap(find.text('Soal berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text('Level 1 · Soal 2 dari 10'), findsOneWidget);
  });

  testWidgets('tapping pictures numbers them and counts aloud', (tester) async {
    phone(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openLevel(tester, 'l1');
    audio.played.clear();
    await tester.tap(find.byKey(const ValueKey('angka-picture-0')));
    await tester.pump();
    expect(audio.played, ['https://media.test/count-1.mp3']);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('angka-picture-0')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('finishing the free level offers Buka semua level', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openLevel(tester, 'l1');
    for (var i = 0; i < 10; i++) {
      await answer(tester, countOf(i));
      await tester.tap(find.text('Soal berikutnya'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Hore, level selesai!'), findsOneWidget);
    expect(find.text('10 dari 10 benar di percobaan pertama.'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byIcon(Icons.star_rounded),
      ),
      findsNWidgets(3),
    );
    expect(find.text('Buka semua level'), findsOneWidget);
    expect(find.text('Main lagi'), findsOneWidget, reason: 'Level 2 is locked');

    await tester.tap(find.text('Kembali ke menu'));
    await tester.pumpAndSettle();
    expect(find.text('Main lagi'), findsOneWidget, reason: 'the level card');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('angka-level-l1')),
        matching: find.byIcon(Icons.star_rounded),
      ),
      findsNWidgets(3),
    );
  });

  testWidgets('subscribers move on to the level they unlocked', (tester) async {
    api.premium = true;
    phone(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openLevel(tester, 'l1');
    for (var i = 0; i < 10; i++) {
      await answer(tester, countOf(i));
      await tester.tap(find.text('Soal berikutnya'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Buka semua level'), findsNothing);
    await tester.tap(find.text('Level berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text('Level 2 · Soal 1 dari 10'), findsOneWidget);
  });

  testWidgets('closing mid-level keeps the place for Lanjut', (tester) async {
    phone(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openLevel(tester, 'l1');
    for (var i = 0; i < 3; i++) {
      await answer(tester, countOf(i));
      await tester.tap(find.text('Soal berikutnya'));
      await tester.pumpAndSettle();
    }
    await tapKey(tester, 'angka-close');
    expect(find.text('3/10 soal'), findsOneWidget);
    expect(find.text('Lanjut'), findsOneWidget);

    await openLevel(tester, 'l1');
    expect(find.text('Level 1 · Soal 4 dari 10'), findsOneWidget);
  });

  testWidgets('a complete that fails shows provisional stars', (tester) async {
    phone(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openLevel(tester, 'l1');
    for (var i = 0; i < 10; i++) {
      if (i == 9) api.failCompletes = 4;
      await answer(tester, countOf(i));
      await tester.tap(find.text('Soal berikutnya'));
      await tester.pumpAndSettle();
    }
    expect(
      find.textContaining('Bintang disimpan saat online.'),
      findsOneWidget,
    );
  });

  testWidgets('the question screen fits a 360 dp phone with 140% text', (
    tester,
  ) async {
    phone(tester, size: const Size(360, 640));
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
    await openLevel(tester, 'l1');
    expect(tester.takeException(), isNull);
    await answer(tester, countOf(0) + 1);
    expect(find.text('Hampir benar!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('Belajar hub card', () {
    Widget hub({AngkaCubit? withCubit}) {
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
      expect(find.text('Angka'), findsOneWidget);
      expect(
        find.text('Kenal angka, hitung benda, jawab soal'),
        findsOneWidget,
      );
      expect(find.text('Premium'), findsOneWidget);
    });

    testWidgets('no badge for subscribers', (tester) async {
      api.premium = true;
      await cubit.load(force: true);
      await tester.pumpWidget(hub(withCubit: cubit));
      await tester.pumpAndSettle();
      expect(find.text('Angka'), findsOneWidget);
      expect(find.text('Premium'), findsNothing);
    });

    testWidgets('hidden while belajar_angka is off', (tester) async {
      when(
        () => flagApi.fetchFlags(),
      ).thenAnswer((_) async => {'belajar_angka': false});
      await flags.refresh();
      await tester.pumpWidget(hub());
      await tester.pumpAndSettle();
      expect(find.text('Angka'), findsNothing);
      expect(find.text('Kartu AR'), findsOneWidget);
    });

    testWidgets('a guest is asked to sign in', (tester) async {
      auth.loggedIn = false;
      var opened = false;
      await tester.pumpWidget(
        MaterialApp(home: BelajarHubScreen(onOpen: (_) => opened = true)),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Angka'));
      await tester.tap(find.text('Angka'));
      await tester.pumpAndSettle();
      expect(opened, isFalse);
      expect(find.textContaining('Belajar Angka'), findsWidgets);
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

    testWidgets('shows the level in progress', (tester) async {
      final repo = AngkaRepository(api, sleep: (_) async {});
      final s = await repo.startSession('c1', 'l1');
      final qs = api.questionsOf(s.id);
      for (var i = 0; i < 3; i++) {
        await repo.recordTry(
          'c1',
          s.id,
          q: i + 1,
          attempt: 1,
          answer: qs[i].count,
        );
      }
      await cubit.load();
      await tester.pumpWidget(home());
      await tester.pumpAndSettle();
      expect(find.text('Lanjutkan belajar'), findsOneWidget);
      expect(find.text('ANGKA'), findsOneWidget);
      expect(find.text('Hitung 1 sampai 5'), findsOneWidget);
      expect(find.text('3/10 soal'), findsOneWidget);
    });

    testWidgets('hidden with no level in progress', (tester) async {
      await cubit.load();
      await tester.pumpWidget(home());
      await tester.pumpAndSettle();
      expect(find.text('Lanjutkan belajar'), findsNothing);
    });
  });
}
