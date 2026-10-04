import 'package:arunika_app/constants/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens a Belajar destination ([AppStrings.navCollection] or
/// [AppStrings.navDongeng]) the way a parent does: Belajar tab, then the card.
///
/// Belajar is tapped twice: the first tap switches to the tab, which may still
/// show the screen it was left on; tapping it again while open returns to the
/// hub, so the card is always there to tap.
Future<void> openBelajar(WidgetTester tester, String card) async {
  for (var i = 0; i < 2; i++) {
    await tester.tap(find.text(AppStrings.navBelajar));
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }
  await tester.tap(find.text(card));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}
