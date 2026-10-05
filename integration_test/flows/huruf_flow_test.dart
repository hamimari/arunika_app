import 'package:arunika_app/core/feature_flags/feature_flags_notifier.dart';
import 'package:arunika_app/data/repositories/huruf_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/navigation/app_router.dart';
import 'package:arunika_app/presentation/screens/growth/growth_cubit.dart';
import 'package:arunika_app/presentation/screens/widgets/parental_gate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/belajar.dart';
import '../helpers/boot_app.dart';
import '../helpers/signed_in_session.dart';
import '../helpers/test_backend.dart';

/// Belajar Huruf end to end against the e2e backend, where letter A is
/// published and free (db/seeds/test/seed.sql): play the free letter —
/// Kenali (with its sounds) and Tebalkan — see the progress stored on the server, and
/// find the next letter behind the parental gate and paywall.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final backend = TestBackend();

  /// Traces the seeded A: two diagonals from the apex, then the bar.
  Future<void> traceA(WidgetTester tester) async {
    final canvas = find.byKey(const ValueKey('tracing-canvas'));
    await tester.ensureVisible(canvas);
    await tester.pumpAndSettle();
    final origin = tester.getTopLeft(canvas);
    final scale = tester.getSize(canvas).width / 300;
    Future<void> stroke(Offset from, Offset to) async {
      final g = await tester.startGesture(origin + from * scale);
      for (var t = 0.05; t <= 1.0001; t += 0.05) {
        await g.moveTo(origin + Offset.lerp(from, to, t)! * scale);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pumpAndSettle();
    }

    await stroke(const Offset(150, 30), const Offset(70, 260));
    await stroke(const Offset(150, 30), const Offset(230, 260));
    await stroke(const Offset(99, 170), const Offset(201, 170));
  }

  testWidgets(
    'should_play_the_free_letter_and_lock_the_rest',
    (tester) async {
      await backend.setFeatureFlag('belajar_huruf', enabled: true);
      final b = await backend.publishHurufLetter('B', word: 'Bola');
      addTearDown(() => backend.hideHurufLetter(b));

      await bootApp(tester);
      await registerAndSignIn();
      await locator<FeatureFlagsNotifier>().refresh();
      AppRouter.router.go('/');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await openBelajar(tester, 'Huruf');
      expect(find.text('Belajar Huruf'), findsOneWidget);
      expect(find.text('Gratis'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('huruf-tile-A')));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Huruf A'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('huruf-letter-sound')));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byKey(const ValueKey('huruf-tab-tebalkan')));
      await tester.pumpAndSettle();
      await traceA(tester);

      expect(find.text('Keren! Huruf A rapi!'), findsOneWidget);
      expect(find.text('Buka semua huruf'), findsOneWidget);

      // The server stored the completed letter.
      final childId = await GrowthCubit.firstChildId();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
      final rows = await tester.runAsync(
        () => locator<HurufRepository>().progress(childId!),
      );
      final a = rows!.firstWhere((p) => p.done);
      expect(a.bestScore, greaterThan(0.8));

      // B is published but locked: the next-letter button opens the gate.
      await tester.tap(find.text('Lanjut ke huruf B'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(ParentalGateScreen), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
