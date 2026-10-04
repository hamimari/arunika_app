import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/feature_flags/feature_flags_notifier.dart';
import 'package:arunika_app/data/api/feature_flag_api.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/navigation/main_shell.dart';
import 'package:arunika_app/presentation/screens/belajar/belajar_tab.dart';
import 'package:arunika_app/services/push_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFeatureFlagApi extends Mock implements FeatureFlagApi {}

class MockPushNotificationService extends Mock
    implements PushNotificationService {}

class _Auth extends AuthNotifier {
  bool loggedIn = false;
  @override
  bool get isLoggedIn => loggedIn;
  void set(bool v) {
    loggedIn = v;
    notifyListeners();
  }
}

void main() {
  late MockFeatureFlagApi api;
  late FeatureFlagsNotifier flags;
  late _Auth auth;
  late GlobalKey<MainShellState> shellKey;
  late List<int> tabChanges;

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    api = MockFeatureFlagApi();
    flags = FeatureFlagsNotifier(api);
    auth = _Auth();
    shellKey = GlobalKey<MainShellState>();
    tabChanges = [];
    locator.registerSingleton<AuthNotifier>(auth);
    locator.registerSingleton<FeatureFlagsNotifier>(flags);
    locator.registerSingleton<PushNotificationService>(
      MockPushNotificationService(),
    );
  });

  tearDown(() => locator.reset());

  Future<void> enableGrowth() async {
    when(
      () => api.fetchFlags(),
    ).thenAnswer((_) async => {'growth_tracking': true});
    await flags.refresh();
  }

  Widget buildShell() => MaterialApp(
    home: MainShell(
      key: shellKey,
      homeScreen: const Text('home-screen'),
      kartuArBuilder: (context, categoryId) => Scaffold(
        body: Column(
          children: [
            Text('kartu-ar-screen ${categoryId ?? 'all'}'),
            BackButton(onPressed: () => Navigator.of(context).maybePop()),
          ],
        ),
      ),
      dongengBuilder: (_, highlight) =>
          Text('dongeng-screen ${highlight ?? 'none'}'),
      growthScreen: const Text('growth-screen'),
      profileScreen: const Text('profile-screen'),
      onTabChanged: tabChanges.add,
    ),
  );

  testWidgets('a guest sees only Beranda and Belajar', (tester) async {
    await enableGrowth();
    await tester.pumpWidget(buildShell());

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Belajar'), findsOneWidget);
    expect(find.text('Tumbuh'), findsNothing);
    expect(find.text('Profil'), findsNothing);
    // The old tabs are gone.
    expect(find.text('Scan'), findsNothing);
    expect(find.text('Orang Tua'), findsNothing);
  });

  testWidgets('a logged-in parent sees Tumbuh only while the flag is on', (
    tester,
  ) async {
    auth.loggedIn = true;
    await tester.pumpWidget(buildShell());

    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Tumbuh'), findsNothing, reason: 'fail-closed flag');

    await enableGrowth();
    await tester.pump();
    expect(find.text('Tumbuh'), findsOneWidget);

    await tester.tap(find.text('Tumbuh'));
    await tester.pump();
    expect(find.text('growth-screen').hitTestable(), findsOneWidget);
    expect(tabChanges, [MainShellTab.tumbuh]);

    // Switching the feature off returns to home.
    when(() => api.fetchFlags()).thenAnswer((_) async => {});
    await flags.refresh();
    await tester.pump();
    expect(find.text('Tumbuh'), findsNothing);
    expect(find.text('home-screen').hitTestable(), findsOneWidget);
  });

  testWidgets('logging out on Tumbuh returns to Beranda', (tester) async {
    auth.loggedIn = true;
    await enableGrowth();
    await tester.pumpWidget(buildShell());
    await tester.tap(find.text('Tumbuh'));
    await tester.pump();

    auth.set(false);
    await tester.pump();

    expect(find.text('Tumbuh'), findsNothing);
    expect(find.text('Profil'), findsNothing);
    expect(find.text('home-screen').hitTestable(), findsOneWidget);
  });

  testWidgets('Belajar opens Kartu AR and Dongeng inside the tab', (
    tester,
  ) async {
    await tester.pumpWidget(buildShell());
    await tester.tap(find.text('Belajar'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih petualangan belajar hari ini!'), findsOneWidget);

    await tester.tap(find.text('Kartu AR'));
    await tester.pumpAndSettle();
    expect(find.text('kartu-ar-screen all'), findsOneWidget);
    // The bottom navigation stays visible.
    expect(find.text('Beranda'), findsOneWidget);

    // Back returns to the hub.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Pilih petualangan belajar hari ini!'), findsOneWidget);

    await tester.tap(find.text('Dongeng'));
    await tester.pumpAndSettle();
    expect(find.text('dongeng-screen none'), findsOneWidget);
  });

  testWidgets('system back pops Belajar before leaving', (tester) async {
    await tester.pumpWidget(buildShell());
    shellKey.currentState!.openBelajar(BelajarDestination.dongeng);
    await tester.pumpAndSettle();
    expect(find.text('dongeng-screen none'), findsOneWidget);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(find.text('dongeng-screen none'), findsNothing);
    expect(find.text('Pilih petualangan belajar hari ini!'), findsOneWidget);
  });

  testWidgets('tapping Belajar again returns to the hub', (tester) async {
    await tester.pumpWidget(buildShell());
    shellKey.currentState!.openBelajar(BelajarDestination.kartuAr);
    await tester.pumpAndSettle();
    expect(find.text('kartu-ar-screen all'), findsOneWidget);

    await tester.tap(find.text('Belajar'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih petualangan belajar hari ini!'), findsOneWidget);
  });

  testWidgets('shortcuts land on the right Belajar destination', (
    tester,
  ) async {
    await tester.pumpWidget(buildShell());

    shellKey.currentState!.openBelajar(
      BelajarDestination.kartuAr,
      categoryId: 'cat-1',
    );
    await tester.pumpAndSettle();
    expect(find.text('kartu-ar-screen cat-1').hitTestable(), findsOneWidget);

    shellKey.currentState!.switchTab(MainShellTab.home);
    await tester.pump();
    shellKey.currentState!.openBelajar(
      BelajarDestination.dongeng,
      highlightProductId: 'p-9',
    );
    await tester.pumpAndSettle();
    expect(find.text('dongeng-screen p-9').hitTestable(), findsOneWidget);
    expect(
      find.text('kartu-ar-screen cat-1'),
      findsNothing,
      reason: 'each shortcut starts from the hub',
    );
  });

  testWidgets('Belajar keeps its screen across tab switches', (tester) async {
    await tester.pumpWidget(buildShell());
    shellKey.currentState!.openBelajar(BelajarDestination.kartuAr);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beranda'));
    await tester.pump();
    await tester.tap(find.text('Belajar'));
    await tester.pumpAndSettle();

    // Re-selecting Belajar from another tab does not reset it.
    expect(find.text('kartu-ar-screen all').hitTestable(), findsOneWidget);
  });
}
