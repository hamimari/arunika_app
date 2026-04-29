import 'package:arunika_app/data/api/ar_api.dart';
import 'package:arunika_app/data/api/auth_api.dart';
import 'package:arunika_app/data/api/fairy_tales_api.dart';
import 'package:arunika_app/data/api/user_api.dart';
import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/data/repositories/auth_repository.dart';
import 'package:arunika_app/data/repositories/fairy_tales_repository.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';


final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton(() => Dio());

  locator.registerLazySingleton(
        () => AuthRepository(AuthApi()));

  locator.registerLazySingleton(
          () => UserRepository(UserApi()));

  locator.registerLazySingleton(
        () => FairyTalesRepository(FairyTalesApi()));

  locator.registerLazySingleton(() => AuthNotifier());
  locator.registerLazySingleton(() => ArRepository(ArApi()));
}
