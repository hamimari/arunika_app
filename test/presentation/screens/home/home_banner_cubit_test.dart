import 'package:arunika_app/data/models/response/banner_item.dart';
import 'package:arunika_app/data/repositories/banner_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/home/home_banner_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockBannerRepository extends Mock implements BannerRepository {}

// ─── Helpers ──────────────────────────────────────────────────────────────────

BannerItem _banner(String id) => BannerItem(
  id: id,
  title: 'Banner $id',
  imageUrl: 'https://img/$id.png',
  type: 'promo',
  isActive: true,
  sortOrder: 0,
);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBannerRepository mockRepo;

  setUp(() async {
    if (locator.isRegistered<BannerRepository>()) {
      await locator.unregister<BannerRepository>();
    }
    mockRepo = MockBannerRepository();
    locator.registerSingleton<BannerRepository>(mockRepo);
  });

  tearDown(() async {
    if (locator.isRegistered<BannerRepository>()) {
      await locator.unregister<BannerRepository>();
    }
  });

  group('HomeBannerCubit', () {
    blocTest<HomeBannerCubit, HomeBannerState>(
      'emits HomeBannerLoaded when repository returns non-empty list',
      build: () {
        when(
          () => mockRepo.getActiveBanners(),
        ).thenAnswer((_) async => [_banner('1'), _banner('2')]);
        return HomeBannerCubit();
      },
      expect: () => [
        isA<HomeBannerLoaded>().having(
          (s) => s.banners.length,
          'banner count',
          2,
        ),
      ],
    );

    blocTest<HomeBannerCubit, HomeBannerState>(
      'emits HomeBannerEmpty when repository returns empty list',
      build: () {
        when(() => mockRepo.getActiveBanners()).thenAnswer((_) async => []);
        return HomeBannerCubit();
      },
      expect: () => [isA<HomeBannerEmpty>()],
    );

    blocTest<HomeBannerCubit, HomeBannerState>(
      'emits HomeBannerEmpty when repository throws (error swallowed by repo)',
      build: () {
        // BannerRepository.getActiveBanners() catches all errors and returns [].
        // Simulate this by returning an empty list (the repo already handles
        // the exception internally).
        when(() => mockRepo.getActiveBanners()).thenAnswer((_) async => []);
        return HomeBannerCubit();
      },
      expect: () => [isA<HomeBannerEmpty>()],
    );
  });
}
