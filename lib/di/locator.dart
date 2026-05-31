import 'package:arunika_app/data/api/animal_api.dart';
import 'package:arunika_app/data/api/ar_api.dart';
import 'package:arunika_app/data/api/auth_api.dart';
import 'package:arunika_app/data/api/banner_api.dart';
import 'package:arunika_app/data/api/category_api.dart';
import 'package:arunika_app/data/api/counting_api.dart';
import 'package:arunika_app/data/api/dongeng_history_api.dart';
import 'package:arunika_app/data/api/fairy_tales_api.dart';
import 'package:arunika_app/data/api/premium_pack_api.dart';
import 'package:arunika_app/data/api/tracing_api.dart';
import 'package:arunika_app/data/api/user_api.dart';
import 'package:arunika_app/data/repositories/animal_repository.dart';
import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/data/repositories/auth_repository.dart';
import 'package:arunika_app/data/repositories/banner_repository.dart';
import 'package:arunika_app/data/repositories/category_repository.dart';
import 'package:arunika_app/data/repositories/counting_repository.dart';
import 'package:arunika_app/data/repositories/dongeng_history_repository.dart';
import 'package:arunika_app/data/repositories/fairy_tales_repository.dart';
import 'package:arunika_app/data/repositories/premium_pack_repository.dart';
import 'package:arunika_app/data/repositories/tracing_repository.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton(() => Dio());

  locator.registerLazySingleton(() => AuthRepository(AuthApi()));

  locator.registerLazySingleton(() => UserRepository(UserApi()));

  locator.registerLazySingleton(() => FairyTalesRepository(FairyTalesApi()));

  locator.registerLazySingleton(() => AuthNotifier());
  locator.registerLazySingleton(() => ArRepository(ArApi()));
  locator.registerLazySingleton(() => AnimalRepository(AnimalApi()));
  locator.registerLazySingleton(() => BannerRepository(BannerApi()));
  locator.registerLazySingleton(() => CategoryRepository(CategoryApi()));
  locator.registerLazySingleton(
    () => DongengHistoryRepository(DongengHistoryApi()),
  );
  locator.registerLazySingleton(() => PremiumPackRepository(PremiumPackApi()));
  locator.registerLazySingleton(() => TracingRepository(TracingApi()));
  locator.registerLazySingleton(() => CountingRepository(CountingApi()));
}
