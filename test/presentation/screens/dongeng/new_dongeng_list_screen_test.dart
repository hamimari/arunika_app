import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/data/models/response/dongeng_category.dart';
import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/data/repositories/dongeng_history_repository.dart';
import 'package:arunika_app/data/repositories/fairy_tales_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_bloc.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_event.dart';
import 'package:arunika_app/presentation/screens/dongeng/new_dongeng_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFairyTalesRepository extends Mock implements FairyTalesRepository {}

class MockDongengHistoryRepository extends Mock
    implements DongengHistoryRepository {}

class MockAuthNotifier extends Mock implements AuthNotifier {}

DongengResponse _unlockedStory(String id, String title) => DongengResponse(
  id: id,
  title: title,
  ageStart: 3,
  ageEnd: 6,
  isFree: true,
  imageUrl: 'https://img/$id.png',
  audioUrl: '',
  duration: '5 min',
  pages: const [],
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  isDeleted: false,
);

DongengResponse _lockedStory(String id, String title) => DongengResponse(
  id: id,
  title: title,
  ageStart: 3,
  ageEnd: 6,
  isFree: false,
  isUnlocked: false,
  imageUrl: 'https://img/$id.png',
  audioUrl: '',
  duration: '5 min',
  pages: const [],
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  isDeleted: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFairyTalesRepository mockRepo;

  setUp(() {
    if (locator.isRegistered<DongengHistoryRepository>()) {
      locator.unregister<DongengHistoryRepository>();
    }
    if (locator.isRegistered<AuthNotifier>()) {
      locator.unregister<AuthNotifier>();
    }

    mockRepo = MockFairyTalesRepository();
    final mockHistoryRepo = MockDongengHistoryRepository();
    final mockAuth = MockAuthNotifier();
    when(() => mockAuth.isLoggedIn).thenReturn(false);
    when(
      () => mockRepo.getCategories(),
    ).thenAnswer((_) async => <DongengCategory>[]);

    locator.registerSingleton<DongengHistoryRepository>(mockHistoryRepo);
    locator.registerSingleton<AuthNotifier>(mockAuth);
  });

  tearDown(() {
    if (locator.isRegistered<DongengHistoryRepository>()) {
      locator.unregister<DongengHistoryRepository>();
    }
    if (locator.isRegistered<AuthNotifier>()) {
      locator.unregister<AuthNotifier>();
    }
  });

  Widget buildApp() {
    return MaterialApp(
      home: BlocProvider(
        create: (_) =>
            DongengListBloc(repository: mockRepo)..add(LoadDongengList()),
        child: const NewDongengListScreen(),
      ),
    );
  }

  testWidgets(
    'old "Sudah dibeli saja" chip is gone, replaced by a gear icon',
    (tester) async {
      when(() => mockRepo.findAll()).thenAnswer(
        (_) async => DongengListResult(
          items: [_unlockedStory('1', 'Story A'), _lockedStory('2', 'Story B')],
          total: 2,
          page: 1,
        ),
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
        (_) async => DongengListResult(
          items: [_unlockedStory('1', 'Story A'), _lockedStory('2', 'Story B')],
          total: 2,
          page: 1,
        ),
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
    'selecting Koleksiku and tapping Terapkan filters out locked stories',
    (tester) async {
      when(() => mockRepo.findAll()).thenAnswer(
        (_) async => DongengListResult(
          items: [_unlockedStory('1', 'Story A'), _lockedStory('2', 'Story B')],
          total: 2,
          page: 1,
        ),
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Story A'), findsOneWidget);
      expect(find.text('Story B'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Koleksiku'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();

      expect(find.text('Story A'), findsOneWidget);
      expect(find.text('Story B'), findsNothing);
    },
  );
}
