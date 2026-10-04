import 'package:arunika_app/presentation/widgets/in_app_notification_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final navigatorKey = GlobalKey<NavigatorState>();

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Center(child: Text('page'))),
      ),
    );
  }

  void show({VoidCallback? onTap, String title = 'Dongeng baru!'}) {
    InAppNotificationBanner.show(
      navigatorKey.currentState!.overlay!,
      title: title,
      body: 'Kancil dan Buaya sudah bisa didengarkan',
      onTap: onTap,
    );
  }

  testWidgets('slides in at the top of the screen with a Lihat action', (
    tester,
  ) async {
    await pumpApp(tester);
    show(onTap: () {});
    await tester.pumpAndSettle();

    expect(find.text('Dongeng baru!'), findsOneWidget);
    expect(find.text('Lihat'), findsOneWidget);
    final bannerTop = tester.getTopLeft(find.text('Dongeng baru!')).dy;
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(
      bannerTop,
      lessThan(screenHeight / 4),
      reason: 'banner should sit at the top',
    );

    InAppNotificationBanner.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('tapping runs onTap and dismisses the banner', (tester) async {
    await pumpApp(tester);
    var taps = 0;
    show(onTap: () => taps++);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dongeng baru!'));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(find.text('Dongeng baru!'), findsNothing);
  });

  testWidgets(
    'without a link there is no Lihat action; close button dismisses',
    (tester) async {
      await pumpApp(tester);
      show();
      await tester.pumpAndSettle();

      expect(find.text('Lihat'), findsNothing);
      await tester.tap(find.byTooltip('Tutup'));
      await tester.pumpAndSettle();
      expect(find.text('Dongeng baru!'), findsNothing);
    },
  );

  testWidgets('auto-dismisses after the display duration', (tester) async {
    await pumpApp(tester);
    show();
    await tester.pumpAndSettle();
    expect(find.text('Dongeng baru!'), findsOneWidget);

    await tester.pump(InAppNotificationBanner.duration);
    await tester.pumpAndSettle();
    expect(find.text('Dongeng baru!'), findsNothing);
  });

  testWidgets('a new notification replaces the visible one', (tester) async {
    await pumpApp(tester);
    show(title: 'Pertama');
    await tester.pumpAndSettle();
    show(title: 'Kedua');
    await tester.pumpAndSettle();

    expect(find.text('Pertama'), findsNothing);
    expect(find.text('Kedua'), findsOneWidget);

    InAppNotificationBanner.dismiss();
    await tester.pumpAndSettle();
  });
}
