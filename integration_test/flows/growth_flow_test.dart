import 'package:arunika_app/core/feature_flags/feature_flags_notifier.dart';
import 'package:arunika_app/data/models/request/update_user_request.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/navigation/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/boot_app.dart';
import '../helpers/signed_in_session.dart';
import '../helpers/test_backend.dart';

/// Tumbuh Kembang end to end: add a measurement, see it on Tumbuh and on the
/// Beranda card, edit it, delete it and undo — against the real growth API,
/// whose server-side classification is what the screens show.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final backend = TestBackend();

  testWidgets(
    'should_add_edit_delete_and_restore_a_measurement',
    (tester) async {
      await backend.setFeatureFlag('growth_tracking', enabled: true);
      addTearDown(
        () => backend.setFeatureFlag('growth_tracking', enabled: false),
      );

      await bootApp(tester);
      final session = await registerAndSignIn();
      // The signup child is over five; make them 3 years old for the chart.
      final users = locator<UserRepository>();
      final profile = await users.findById(session.userId);
      final child = profile.children.first;
      final birth = DateTime.now().subtract(const Duration(days: 3 * 365 + 60));
      await users.update(
        UpdateUserRequest(
          id: profile.id,
          name: profile.name,
          phoneNumber: profile.phoneNumber,
          emailAddress: profile.emailAddress,
          address: profile.address,
          city: profile.city,
          child: [
            UpdateChildRequest(
              id: child.id,
              name: child.name,
              gender: 'Laki-Laki',
              birthDate: birth.toUtc().toIso8601String(),
            ),
          ],
        ),
      );
      await locator<FeatureFlagsNotifier>().refresh();

      AppRouter.router.go('/');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Beranda shows the first-measurement prompt.
      expect(find.text('Catat pengukuran pertama'), findsOneWidget);

      await tester.tap(find.text('Tumbuh'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('Tambah Pengukuran'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '95,0');
      await tester.enterText(find.byType(TextField).last, '14,0');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.textContaining('95,0'), findsWidgets);
      expect(find.text('1 data'), findsOneWidget);

      // Edit the weight.
      final edit = find.byWidgetPredicate(
        (w) => w is IconButton && (w.tooltip ?? '').startsWith('Edit'),
      );
      await tester.scrollUntilVisible(edit, 300);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '14,4');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('14,4 kg'), findsOneWidget);

      // Delete, then undo.
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is IconButton && (w.tooltip ?? '').startsWith('Hapus'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya, hapus'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('1 data'), findsNothing);
      await tester.tap(find.text('Urungkan'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('1 data'), findsOneWidget);

      // Beranda shows the latest values.
      await tester.tap(find.text('Beranda'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.textContaining('Tumbuh kembang'), findsOneWidget);
      expect(find.text('95,0 cm'), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
