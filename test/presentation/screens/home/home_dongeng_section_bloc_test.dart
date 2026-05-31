import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/data/repositories/dongeng_history_repository.dart';
import 'package:arunika_app/data/repositories/fairy_tales_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/home/home_dongeng_section_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockFairyTalesRepository extends Mock implements FairyTalesRepository {}

class MockDongengHistoryRepository extends Mock
    implements DongengHistoryRepository {}

class MockAuthNotifier extends Mock implements AuthNotifier {}

// ─── Helpers ──────────────────────────────────────────────────────────────────

DongengResponse _story(String id) => DongengResponse(
  id: id,
  title: 'Story $id',
  ageStart: 3,
  ageEnd: 6,
  isFree: true,
  imageUrl: 'https://img/$id.png',
  audioUrl: '',
  duration: '5 min',
  pages: [],
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  isDeleted: false,
);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFairyTalesRepository mockTalesRepo;
  late MockDongengHistoryRepository mockHistoryRepo;
  late MockAuthNotifier mockAuth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    if (locator.isRegistered<FairyTalesRepository>()) {
      await locator.unregister<FairyTalesRepository>();
    }
    if (locator.isRegistered<DongengHistoryRepository>()) {
      await locator.unregister<DongengHistoryRepository>();
    }
    if (locator.isRegistered<AuthNotifier>()) {
      await locator.unregister<AuthNotifier>();
    }

    mockTalesRepo = MockFairyTalesRepository();
    mockHistoryRepo = MockDongengHistoryRepository();
    mockAuth = MockAuthNotifier();

    locator.registerSingleton<FairyTalesRepository>(mockTalesRepo);
    locator.registerSingleton<DongengHistoryRepository>(mockHistoryRepo);
    locator.registerSingleton<AuthNotifier>(mockAuth);
  });

  tearDown(() async {
    if (locator.isRegistered<FairyTalesRepository>()) {
      await locator.unregister<FairyTalesRepository>();
    }
    if (locator.isRegistered<DongengHistoryRepository>()) {
      await locator.unregister<DongengHistoryRepository>();
    }
    if (locator.isRegistered<AuthNotifier>()) {
      await locator.unregister<AuthNotifier>();
    }
  });

  group('HomeDongengSectionBloc', () {
    blocTest<HomeDongengSectionBloc, HomeDongengState>(
      'emits HomeDongengLoaded with items when repository succeeds (guest)',
      build: () {
        when(() => mockAuth.isLoggedIn).thenReturn(false);
        when(() => mockTalesRepo.findAll()).thenAnswer(
          (_) async => DongengListResult(
            items: [_story('1'), _story('2'), _story('3')],
            total: 3,
            page: 1,
          ),
        );
        return HomeDongengSectionBloc();
      },
      expect: () => [
        isA<HomeDongengLoaded>().having(
          (s) => s.items.length,
          'items count',
          3,
        ),
      ],
    );

    blocTest<HomeDongengSectionBloc, HomeDongengState>(
      'emits HomeDongengLoaded with at most 6 items',
      build: () {
        when(() => mockAuth.isLoggedIn).thenReturn(false);
        when(() => mockTalesRepo.findAll()).thenAnswer(
          (_) async => DongengListResult(
            items: List.generate(10, (i) => _story('$i')),
            total: 10,
            page: 1,
          ),
        );
        return HomeDongengSectionBloc();
      },
      expect: () => [
        isA<HomeDongengLoaded>().having(
          (s) => s.items.length,
          'capped at 6',
          6,
        ),
      ],
    );

    blocTest<HomeDongengSectionBloc, HomeDongengState>(
      'emits HomeDongengError when repository throws',
      build: () {
        when(() => mockAuth.isLoggedIn).thenReturn(false);
        when(
          () => mockTalesRepo.findAll(),
        ).thenAnswer((_) async => throw Exception('network error'));
        return HomeDongengSectionBloc();
      },
      expect: () => [isA<HomeDongengError>()],
    );
  });
}
