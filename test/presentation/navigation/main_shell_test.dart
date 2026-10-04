import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/feature_flags/feature_flags_notifier.dart';
import 'package:arunika_app/data/api/feature_flag_api.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/navigation/main_shell.dart';
import 'package:arunika_app/services/push_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFeatureFlagApi extends Mock implements FeatureFlagApi {}

class MockPushNotificationService extends Mock
    implements PushNotificationService {}

void main() {
  late MockFeatureFlagApi api;
  late FeatureFlagsNotifier flags;

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    api = MockFeatureFlagApi();
    flags = FeatureFlagsNotifier(api);
    locator.registerSingleton<AuthNotifier>(AuthNotifier());
    locator.registerSingleton<FeatureFlagsNotifier>(flags);
    locator.registerSingleton<PushNotificationService>(
      MockPushNotificationService(),
    );
  });

  tearDown(() => locator.reset());

  Widget buildShell() => MaterialApp(
    home: MainShell(
      key: GlobalKey<MainShellState>(),
      homeScreen: const Text('home-screen'),
      scanScreen: const Text('scan-screen'),
      collectionScreen: const Text('collection-screen'),
      dongengScreen: const Text('dongeng-screen'),
      parentScreen: const Text('parent-screen'),
    ),
  );

  testWidgets('shows the Scan tab while QR scan is enabled', (tester) async {
    await tester.pumpWidget(buildShell());

    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Kartu AR'), findsOneWidget);
    expect(find.text('Dongeng'), findsOneWidget);
  });

  testWidgets(
    'hiding QR scan removes the tab and keeps tab switching correct',
    (tester) async {
      when(() => api.fetchFlags()).thenAnswer((_) async => {'qr_scan': false});
      await tester.pumpWidget(buildShell());

      // Open the Scan tab, then switch the feature off from the "backoffice".
      await tester.tap(find.text('Scan'));
      await tester.pump();
      expect(find.text('scan-screen').hitTestable(), findsOneWidget);

      await flags.refresh();
      await tester.pump();

      expect(find.text('Scan'), findsNothing);
      expect(find.text('scan-screen'), findsNothing);
      // Falls back to home since the open tab disappeared.
      expect(find.text('home-screen').hitTestable(), findsOneWidget);

      // Remaining tabs still open their own screens (no index shift).
      await tester.tap(find.text('Kartu AR'));
      await tester.pump();
      expect(find.text('collection-screen').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Dongeng'));
      await tester.pump();
      expect(find.text('dongeng-screen').hitTestable(), findsOneWidget);
    },
  );
}
