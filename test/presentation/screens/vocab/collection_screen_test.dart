import 'package:arunika_app/data/models/response/ar_card_response.dart';
import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/vocab/collection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockArRepository extends Mock implements ArRepository {}

ArCardResponse _unlockedCard(String id, String title) => ArCardResponse(
  id: id,
  title: title,
  emoji: '🐄',
  imageUrl: '',
  bgColor: '#FFF8E1',
  isUnlocked: true,
);

ArCardResponse _lockedCard(String id, String title) => ArCardResponse(
  id: id,
  title: title,
  emoji: '🐯',
  imageUrl: '',
  bgColor: '#FFF3E0',
  isUnlocked: false,
);

void main() {
  late MockArRepository mockRepo;

  setUp(() {
    mockRepo = MockArRepository();
    when(() => mockRepo.getCategories()).thenAnswer((_) async => []);
    if (locator.isRegistered<ArRepository>()) {
      locator.unregister<ArRepository>();
    }
    locator.registerSingleton<ArRepository>(mockRepo);
  });

  tearDown(() {
    if (locator.isRegistered<ArRepository>()) {
      locator.unregister<ArRepository>();
    }
  });

  Widget buildApp() {
    return const MaterialApp(home: CollectionScreen());
  }

  testWidgets(
    'old "Sudah dibeli saja" chip is gone, replaced by a gear icon',
    (tester) async {
      when(() => mockRepo.findAll()).thenAnswer(
        (_) async => [_unlockedCard('1', 'Card A'), _lockedCard('2', 'Card B')],
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Sudah dibeli saja'), findsNothing);
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'tapping the gear icon opens the Filter sheet with Kepemilikan options',
    (tester) async {
      when(() => mockRepo.findAll()).thenAnswer(
        (_) async => [_unlockedCard('1', 'Card A'), _lockedCard('2', 'Card B')],
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('Kepemilikan'), findsOneWidget);
      expect(
        find.widgetWithText(RadioListTile<bool>, 'Semua'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(RadioListTile<bool>, 'Koleksiku'),
        findsOneWidget,
      );
      expect(find.text('Terapkan'), findsOneWidget);
    },
  );

  testWidgets(
    'selecting Koleksiku and tapping Terapkan filters out locked cards',
    (tester) async {
      when(() => mockRepo.findAll()).thenAnswer(
        (_) async => [_unlockedCard('1', 'Card A'), _lockedCard('2', 'Card B')],
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Card A'), findsOneWidget);
      expect(find.text('Card B'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Koleksiku'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();

      expect(find.text('Card A'), findsOneWidget);
      expect(find.text('Card B'), findsNothing);
    },
  );
}
