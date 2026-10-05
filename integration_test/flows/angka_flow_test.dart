import 'package:arunika_app/core/feature_flags/feature_flags_notifier.dart';
import 'package:arunika_app/data/repositories/angka_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/navigation/app_router.dart';
import 'package:arunika_app/presentation/screens/angka/angka_play_cubit.dart';
import 'package:arunika_app/presentation/screens/growth/growth_cubit.dart';
import 'package:arunika_app/presentation/screens/widgets/parental_gate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/belajar.dart';
import '../helpers/boot_app.dart';
import '../helpers/signed_in_session.dart';
import '../helpers/test_backend.dart';

/// Belajar Angka end to end against the e2e backend, where Level 1 (free,
/// 1–5) and Level 2 (1–10, after Level 1) are published
/// (db/seeds/test/seed.sql): play Level 1 with one wrong answer, see the
/// stars stored on the server, and find Level 2 behind the parental gate.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final backend = TestBackend();

  Future<void> tapKey(WidgetTester tester, String key) async {
    final f = find.byKey(ValueKey(key));
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
  }

  Future<void> answer(WidgetTester tester, int n) async {
    for (final ch in '$n'.split('')) {
      await tapKey(tester, 'angka-key-$ch');
    }
    await tapKey(tester, 'angka-key-check');
  }

  testWidgets(
    'should_play_the_free_level_and_lock_the_rest',
    (tester) async {
      await backend.setFeatureFlag('belajar_angka', enabled: true);

      await bootApp(tester);
      await registerAndSignIn();
      await locator<FeatureFlagsNotifier>().refresh();
      AppRouter.router.go('/');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await openBelajar(tester, 'Angka');
      expect(find.text('Belajar Angka'), findsOneWidget);
      expect(find.text('Gratis'), findsWidgets);

      await tapKey(tester, 'angka-level-e2e0a200-0000-0000-0000-000000000001');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Level 1 · Soal 1 dari 10'), findsOneWidget);

      // The app generated the questions from the session seed; read the
      // counts from the screen's own state.
      final play = BlocProvider.of<AngkaPlayCubit>(
        tester.element(find.byKey(const ValueKey('angka-answer'))),
      );
      for (var i = 0; i < 10; i++) {
        final count = play.state.question!.count;
        if (i == 0) {
          await answer(tester, count + 1);
          expect(find.text('Hampir benar!'), findsOneWidget);
          await tester.tap(find.text('Coba lagi'));
          await tester.pumpAndSettle();
        }
        await answer(tester, count);
        await tester.tap(find.text('Soal berikutnya'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // 9 of 10 right on the first try: three stars, from the server.
      expect(find.text('Hore, level selesai!'), findsOneWidget);
      expect(find.text('Buka semua level'), findsOneWidget);
      final childId = await GrowthCubit.firstChildId();
      final rows = await tester.runAsync(
        () => locator<AngkaRepository>().progress(childId!),
      );
      final l1 = rows!.firstWhere((p) => p.completed);
      expect(l1.bestStars, 3);

      // Level 2 is unlocked by progress but still needs Akses Premium.
      await tester.tap(find.text('Kembali ke menu'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tapKey(tester, 'angka-level-e2e0a200-0000-0000-0000-000000000002');
      expect(find.byType(ParentalGateScreen), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
