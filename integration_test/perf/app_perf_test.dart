import 'dart:io';

import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/presentation/navigation/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/boot_app.dart';
import '../helpers/signed_in_session.dart';

/// Pre-release performance pass: records frame timings for the main
/// scrolling and paging flows, plus the process's resident memory between
/// them. Needs a backend seeded with enough content to scroll (see
/// scripts/perf_seed.py), and must run in profile mode through the driver:
///
///   flutter drive --profile -d DEVICE_ID \
///     --driver=test_driver/perf_driver.dart \
///     --target=integration_test/perf/app_perf_test.dart \
///     --dart-define=API_BASE_URL=http://10.0.2.2:8090
///
/// Summaries land in build/perf/. The AR scan is not covered: it needs a
/// physical card in front of the camera.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Pump real frames at the device's rate so frame timings mean something.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('performance pass', (tester) async {
    // The E2E stack's own seed rows point at unreachable image hosts. A failed
    // image load shows the placeholder in the app, but the test binding would
    // report it as a test failure, so ignore image-load errors (only those).
    final reportError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.library == 'image resource service') return;
      reportError?.call(details);
    };

    final memory = <String, int>{};
    void sampleMemory(String phase) => memory['${memory.length}_$phase'] =
        ProcessInfo.currentRss ~/ (1024 * 1024);

    await bootApp(tester);
    await registerAndSignIn();
    AppRouter.router.go('/');
    await tester.pumpAndSettle(const Duration(seconds: 3));
    sampleMemory('home_loaded');

    Future<void> flingAll(Finder scrollable, {int times = 3}) async {
      for (var i = 0; i < times; i++) {
        await tester.fling(scrollable, const Offset(0, -600), 2000);
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < times; i++) {
        await tester.fling(scrollable, const Offset(0, 600), 2000);
        await tester.pumpAndSettle();
      }
    }

    await binding.traceAction(
      () => flingAll(find.byType(Scrollable).first),
      reportKey: 'home_scroll',
    );
    sampleMemory('after_home');

    await tester.tap(find.text(AppStrings.navDongeng));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await binding.traceAction(
      () => flingAll(find.byType(Scrollable).first, times: 4),
      reportKey: 'dongeng_list_scroll',
    );
    sampleMemory('after_dongeng_list');

    final story = find.textContaining('Perf Dongeng').first;
    await tester.ensureVisible(story);
    await tester.pumpAndSettle();
    await tester.tap(story);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(
      find.byIcon(Icons.arrow_forward_ios_rounded),
      findsOneWidget,
      reason: 'the dongeng player should be open',
    );
    await binding.traceAction(() async {
      for (var i = 0; i < 8; i++) {
        await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
        await tester.pumpAndSettle();
      }
      // Swipe back through a few pages so the finger-driven curl is traced too.
      final page = tester.getCenter(find.byType(Scaffold).last);
      for (var i = 0; i < 4; i++) {
        await tester.timedDragFrom(
          page,
          const Offset(500, 0),
          const Duration(milliseconds: 700),
        );
        await tester.pumpAndSettle();
      }
    }, reportKey: 'dongeng_page_flip');
    sampleMemory('after_dongeng_pages');
    AppRouter.router.pop();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.text(AppStrings.navCollection));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await binding.traceAction(
      () => flingAll(
        find
            .descendant(
              of: find.byType(GridView),
              matching: find.byType(Scrollable),
            )
            .first,
        times: 4,
      ),
      reportKey: 'ar_collection_scroll',
    );
    sampleMemory('after_ar_collection');

    // Back and forth between tabs, to see whether memory keeps climbing.
    for (var round = 0; round < 3; round++) {
      for (final tab in [
        AppStrings.navHome,
        AppStrings.navDongeng,
        AppStrings.navCollection,
      ]) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
    }
    await tester.tap(find.text(AppStrings.navHome));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    sampleMemory('home_after_3_tab_rounds');

    binding.reportData = {...?binding.reportData, 'memory_rss_mb': memory};
    FlutterError.onError = reportError;
  }, timeout: const Timeout(Duration(minutes: 5)));
}
