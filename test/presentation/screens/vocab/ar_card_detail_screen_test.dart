import 'package:arunika_app/data/models/response/ar_card_response.dart';
import 'package:arunika_app/presentation/screens/vocab/ar_card_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

Widget _buildScreen(ArCardResponse card, {NavigatorObserver? observer}) {
  return MaterialApp(
    navigatorObservers: [if (observer != null) observer],
    home: ArCardDetailScreen(card: card),
  );
}

final _fullCard = ArCardResponse(
  id: 'test-1',
  title: 'Sapi',
  imageUrl: '',
  description: 'Sapi menghasilkan susu setiap hari.',
  audioUrl: 'https://example.com/sapi.mp3',
  fileUrl: 'https://example.com/sapi.glb',
  isUnlocked: true,
  emoji: '🐄',
);

final _noDescriptionCard = ArCardResponse(
  id: 'test-2',
  title: 'Harimau',
  imageUrl: '',
  description: '',
  audioUrl: '',
  fileUrl: 'https://example.com/harimau.glb',
  isUnlocked: true,
  emoji: '🐯',
);

void main() {
  testWidgets(
    'renders card title, Fun Fact, description, Putar Suara and Lihat AR buttons',
    (tester) async {
      await tester.pumpWidget(_buildScreen(_fullCard));

      expect(find.text('Sapi'), findsOneWidget);
      expect(find.text('Fun Fact'), findsOneWidget);
      expect(find.text('Sapi menghasilkan susu setiap hari.'), findsOneWidget);
      expect(find.text('Putar Suara'), findsOneWidget);
      expect(find.text('Lihat AR'), findsOneWidget);
    },
  );

  testWidgets('shows placeholder text when description is empty', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen(_noDescriptionCard));

    expect(
      find.text('Deskripsi belum tersedia untuk kartu ini.'),
      findsOneWidget,
    );
  });

  testWidgets('emoji placeholder is shown when imageUrl is empty', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen(_fullCard));
    await tester.pump();

    expect(find.text('🐄'), findsOneWidget);
  });

  testWidgets('Lihat AR button triggers route push via navigator', (
    tester,
  ) async {
    final observer = MockNavigatorObserver();
    registerFallbackValue(
      MaterialPageRoute<void>(builder: (_) => const SizedBox()),
    );

    await tester.pumpWidget(_buildScreen(_fullCard, observer: observer));

    await tester.tap(find.text('Lihat AR'));
    await tester.pump();

    verify(
      () => observer.didPush(any(), any()),
    ).called(greaterThanOrEqualTo(1));
  });
}
