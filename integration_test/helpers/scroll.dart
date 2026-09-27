import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Scrolls the grid on screen until [text] is built, then returns the finder.
///
/// The collection tab is a lazy `GridView.builder`, and the shared test
/// backend accumulates cards across runs, so a card seeded a moment ago is
/// usually past the last built row. Asserting on it without scrolling fails
/// on a screen that is behaving correctly.
Future<Finder> scrollToText(WidgetTester tester, String text) async {
  final target = find.text(text);
  await tester.scrollUntilVisible(
    target,
    300,
    scrollable: find
        .descendant(
          of: find.byType(GridView),
          matching: find.byType(Scrollable),
        )
        .first,
    maxScrolls: 200,
  );
  await tester.pumpAndSettle();
  return target;
}
